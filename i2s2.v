//
//		i2s2.v - serializer/deserializer for 2-channel 24-bit audio CODEC
//
//					(C) Copyright 2004-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This logic module is a serializer/deserializer for an Alesis AL1101 ADC
// and AL1201 DAC. The word length is 24 bits and data is shifted MSB first
// into and out of the CODEC. 0-14 kHz audio is supported.
//
// 24-bit words are sent to the DAC by writing the least significant byte into
// the even output port and then writing the most significant word into the odd
// output port. Ports 0-1 are for the right channel and ports 2-3 are for the
// left channel. For 16-bit data, write a 0 to one even port and then use only
// the odd ports.
//
// 24-bit words are read from the ADC by reading the least significant byte from
// the even port and then the most significant byte from the odd port. For 16-bit
// data read only the odd port.
//
// Output Ports:
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |       Right Channel LSB       |                               |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                       Right Channel MSW                       |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |       Left Channel LSB        |                               |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |                       Left Channel MSW                        |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// Input Ports:
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |       Right Channel LSB       |                               |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                       Right Channel MSW                       |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |       Left Channel LSB        |                               |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |                       Left Channel MSW                        |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |                               |TXE|TXR|RXF|RXR|TXE|TXR|RXF|RXR|
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	                                   |<----LEFT----->|<----RIGHT---->|
//
// RXR - receiver ready with data
// RXF - receiver full (overflow)
// TXR - transmitter ready for data
// TXE - transmitter empty (underflow)
//
// 294 LUT6 and 208 registers used.  Maximum clock rates are 181 MHz for ACLK and 191 MHz for MCLK.
//
// Normal Warnings:
//
// Revision History:
//		M001	2009-2-2	modify for use as I/O port
//		M002	3-3-09	sync. output for 2-cycle read
//		M003	eliminated trucation warnings in increment by one for Spartan-6
//		M004	modify for 72 MHz clock
//		M005	modify for 2 independent channels with 80 MHz ACLK (was 203 LUT, 174 reg)
//		M006	2013-3-30 add data out register (was 310 LUT, 304 reg, 155M ACLK, 216M MCLK)
//
module i2s2 (
    input [2:0] ioaddr,	// register address
	 input iocs,			// device select
    input [15:0] din,	// parallel data input
	 input iowr,			// write data
    output [15:0] dout,	// parallel data output
	 input iord,			// read data
    input mclk,			// CPU clock (48-72 MHz)
	 input mrst,			// synchronous reset of enable register
	 input aclk,			// audio clock (80 MHz)
    input sdi,				// serial data input
    output sdo,			// seial data output
    output sfs				// serial frame synchronization pulse
	 );
// internal data paths
reg [7:0] txlsb;				// least significant byte of transmitted word
wire wr02,wr1,wr3;			// data writes
wire rd1,rd3;					// data reads
wire [23:0] pdo1,pdo2;		// multiplexed parallel data output from FIFO
wire sdi0;						// buffered data input
reg sdo0;						// buffered data output
reg sfs0;						// frame sync.
reg [31:0] rsr;				// receive shift register
reg [23:0] rhr;				// receive holding register
reg [23:0] tsr,thr1,thr2;	// transmit holding and shift registers
wire [23:0] tin1,tin2;		// TSR parallel input
wire rxe1,rxf1,txe1,txf1;	// FIFO flags
wire rxe2,rxf2,txe2,txf2;
reg [10:0] wdiv;				// divide by 1250 for word clock (ACLK)
reg [5:0] bdiv;				// divide by 39 for bit clock
wire wtc,btc;					// terminal counts for dividers
wire istb,ostb;				// bit input and output strobes
wire wstb;						// delay to generate word clock
wire sw1,sw2;					// synchronized word strobes (MCLK)
reg [15:0] omux;				// data output multiplexer
// I/O port address decoding
assign wr02 = iocs & (ioaddr == 0)|(ioaddr == 2) & iowr;	// right or left LSB
assign wr1 = iocs & (ioaddr == 1) & iowr;						// right MSW
assign wr3 = iocs & (ioaddr == 3) & iowr;						// left MSW
assign rd1 = iocs & (ioaddr == 1) & iord;						// right MSW
assign rd3 = iocs & (ioaddr == 3) & iord;						// left MSW
// synchronize reset to internal audio clock
FDPE synrst (
	.PRE(mrst),	// asynchronous set
	.D(1'b0),	// synchronous clear
	.Q(arst),	// synchronized reset output
	.CE(1'b1),
	.C(aclk)
	);
// generate clocks to unload words from FIFO and shift into CODEC
// and to reads bits shifted out of CODEC and write to FIFO
// Word clock = 80 MHz / 1250 = 64 kHz
// Bit clock = 80 MHz / 39 = 2.051 MHz (sync. to 64 kHz for 2.048 MHz)
assign wtc = (wdiv == 1249);
assign btc = (bdiv == 38);
always @ (posedge aclk)
begin
	if (arst|wtc) wdiv <= 0;
	else wdiv <= wdiv + 1'b1;
	if (arst|wtc|btc) bdiv <= 0;
	else bdiv <= bdiv + 1'b1;
end
// generate word strobe for FIFO read and write
assign wstb = (wdiv == 10);
// generate bit clocks for shift registers - offset prevent extra strobe
assign ostb = (bdiv == 10);	// beginning of bit cell on transmit
assign istb = (bdiv == 30);	// middle of bit cell on receive
// serial I/O for I2S audio CODEC
// transmit data shifted out MSB first - 24 bit shift register used as last 8 bits are zero
// received data shifted in MSB first - 32 bit shift register with least significant 8 bits ignored
always @ (posedge aclk)
begin
	if (arst) sfs0 <= 0;							// generate frame sync. (TIG)
	else if (wstb) sfs0 <= ~sfs0;
	if (wstb) tsr <= sfs0 ? thr2 : thr1;	// parallel load to get bit 0 - WSTB and OSB are coincident
	else if (ostb) tsr <= {tsr[22:0],1'b0};
	sdo0 <= tsr[23];								// buffer data output (TIG)
	if (arst) rsr[31:8] <= 0;					// first sample is zero - next sample is previous 32 bits on SDI
	else if (istb) rsr <= {rsr[30:0],sdi0};
	if (wstb) rhr <= rsr[31:8];				// save received word
end
// synchronize FIFO controls to MCLK
syn2clk synt1 (
	.a(wstb & ~sfs0),	// frame sync. about to go high
	.aclk(aclk),
	.arst(arst),
	.b(sw1),
	.bclk(mclk),
	.brst(mrst)
	);
syn2clk synt2 (
	.a(wstb & sfs0),	// frame sync. about to go low
	.aclk(aclk),
	.arst(arst),
	.b(sw2),
	.bclk(mclk),
	.brst(mrst)
	);
// transmit FIFOs - save LSB and write to FIFO when MSW present
always @ (posedge mclk)
begin
	if (mrst) txlsb <= 0;
	else if (wr02) txlsb <= din [15:8];
end
// ports 0-1 for left and ports 2-3 for right channel
fifo16x24s txfifo1 (
	.pdi({din,txlsb}),	// load when all 24-bits available
	.iv(wr1),
	.pdo(tin1),
	.ov(),
	.oe(sw1),				// get next entry
	.clk(mclk),
	.rst(mrst),
	.empty(txe1),
	.full(txf1)
	);
fifo16x24s txfifo2 (
	.pdi({din,txlsb}),	// load when all 24-bits available
	.iv(wr3),
	.pdo(tin2),
	.ov(),
	.oe(sw2),				// get next entry
	.clk(mclk),
	.rst(mrst),
	.empty(txe2),
	.full(txf2)
	);
// transmit holding registers - need TIG
always @ (posedge mclk)
begin
	thr1 <= tin1;
	thr2 <= tin2;
end
// receive FIFOs - need TIG for RHR
fifo16x24s rxfifo1 (
	.pdi(rhr),
	.iv(sw1),			// save accumulated bits just before MSB sampled
	.pdo(pdo1),
	.ov(),
	.oe(rd1),			// discard after MSW read
	.clk(mclk),
	.rst(mrst),
	.empty(rxe1),
	.full(rxf1)
	);
fifo16x24s rxfifo2 (
	.pdi(rhr),
	.iv(sw2),			// save accumulated bits just before MSB sampled
	.pdo(pdo2),
	.ov(),
	.oe(rd3),			// discard after MSW read
	.clk(mclk),
	.rst(mrst),
	.empty(rxe2),
	.full(rxf2)
	);
// output multiplexer - 4 words for incoming data plus 1 status word
always @ (posedge mclk)
begin
	case (ioaddr)
	0: omux <= {pdo1[7:0],8'h00};	// right LSB
	1: omux <= {pdo1[23:8]};		// right MSW
	2: omux <= {pdo2[7:0],8'h00};	// left LSB
	3: omux <= {pdo2[23:8]};		// left MSW
	4: omux <= {8'h00,txe2,~txf2,rxf2,~rxe2,txe1,~txf1,rxf1,~rxe1}; // status
	5: omux <= 16'h0000;	// unused input ports
	6: omux <= 16'h0000;
	7: omux <= 16'h0000;
	default: omux <= 16'hxxxx;
	endcase
end
assign dout = omux;
// connect I2S Bus
OBUF sckbuf (.I(sfs0), .O(sfs));	// frame sync.
OBUF sdobuf (.I(sdo0), .O(sdo));	// data output
IBUF sdibuf (.I(sdi), .O(sdi0));	// data input (TIG)
endmodule

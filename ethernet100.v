//
//				ethernet100.v - Full-duplex Ethernet RMII Interface
//
//					(C) Copyright 2008-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements the full-duplex 100 Mbps IEEE 802.3 MAC sublayer. It
// contains a 2 kB transmit buffer RAM and a receive FIFO with four 2 kB buffers.
// The transmit and receive buffers are accessible through 1 kW memory windows.
//
// To transmit, the CPU formats a frame into memory starting at 0. The length
// register is then set to the length of the frame and the frame is transmitted.
// The CPU must wait for the transmit empty flag before loading and sending
// another frame.
//
// The receiver stores incoming bytes in the current buffer in the receive FIFO.
// When the frame is complete, the receiver continues by storing the next frame
// in the next buffer unless all four have been used. The CPU may read frames
// from the FIFO through the memory window when the receiver ready flag is set.
// Writing to I/O port 0 discrds the current buffer and loads the next buffer
// if there is another waiting. If 4 buffers are unread, the receiver ignores
// incoming frames.
//
// Command Registers:
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 0 |                                                               | Receive Done
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 1 |                   |             TX Length (bytes)             | TX Length
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 2 |                                                   |DIR|CLK|DAT| MDI
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 3 |                                                           |ENA| Control
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//   DAT: MDIO data output
//   CLK: MDC clock bit
//   DIR: 0 = receive, 1 = transmit
//   ENA: 0 = disable, 1 = enable MAC & PHY
//
// Status Register:
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//   |MDI|INT|TXE|RXR|RXE|           RX Length (bytes)               |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// Status of Current received Frame:
//   RXE: receiver error (from runt dibits)
// Overall Status:
//   RXR: receiver ready
//   TXE: transmitter buffer empty
//   INT: management interrupt
//   MDI: MDIO data input
//
// S6: 85 LUT6s, 117 registers and 5 BRAMs used. RCLK 134 MHz & MCLK 204 MHz. 
//
// Normal Warnings:
//		Input <din<15:11>> is never used.
//		Input <ioaddr<2>> is never used.
//
// TIG required for status, saddr, sdata, synsof/t, synrxce/t, syneof/t and synwr/t.
//
// Revision History:
//		4-10-10	created from FIFO-based Ethernet interface (38 fewer slices)
//		12-8-10	eliminated truncation and unused port warnings for Spartan-6
//		12-16-10	add reset output buffer
//		9-25-11	added explicit RMII buffers
//		10-3-11	4-entry receive FIFO
//		10-9-11	process words MSB first (flip bytes at 16-bit wide memory interface)
//		10-10-11	add read port for transmit buffer
//		10-19-11	use 50 MHz clock for xmt/rcv logic & shorten clock sync. time
//
module ethernet100(
	 input mcs0,mcs1,			// memory select for transmit and receive
    input [9:0] maddr,		// memory address (common)
	 input mwr0,				// write to memory (tansmit)
    input [15:0] min0,		// memory data input for transmit
    output [15:0] mout0,	// memory data output for transmit
	 output [15:0] mout1,	// memory data output for receive
	 input iocs,				// select this module for I/O
    input [2:0] ioaddr,		// I/O port address
    input [15:0] din,		// data input
    output [15:0] dout,		// data output
	 input iowr,				// write to port
	 input iord,				// read from port
    input mclk,				// I/O and memory clock
    input mrst,				// I/O reset
    input [1:0] rxd,			// RMII received data
    input rxv,					// RMII carrier sense and received data valid
    output [1:0] txd,		// RMII transmit data
    output txv,				// RMII transmit data valid
    input rclk,				// 50 MHz internal transmit and receive clock
	 output rstn,				// reset external PHY when 0
	 output mdc,				// SMI clock
	 inout mdio,				// SMI data
	 input mint					// SMI interrupt
	 ,output [4:0] test		// test
    );
// internal signals
reg phyen;				// PHY enable (off state resets external PHY)
wire reset;				// MAC and PHY reset
wire txce;				// transmitter dibit count enable
wire [1:0] txd1;		// transmit RAM output
reg [1:0] txd2;		// synchronized RAM output
reg txv1,txv2;			// transmit RAM output valid
reg [12:0] toaddr;	// transmitter output address (dibits)
reg [12:0] tcount;	// transmitter limit register (dibits)
reg [10:0] riaddr;	// receiver input address counter (bytes)
wire [11:0] rsize;	// received frame size (bytes)
reg fwe;					// FIFO write enable
wire fstart,fwr;		// FIFO read and write strobes
wire fend,fdone;
wire [1:0] raddr,waddr;	// receiver FIFO buffer addresses
wire full,empty;		// FIFO flags
wire [1:0] rxdi;		// input buffers
wire rxvi;
reg rxvs;				// received data valid
reg [1:0] rxctr;		// received bit counter
reg [3:0] rxd0,rxd1;	// receiver shift register
reg [7:0] rxd8;		// receiver data register
wire sync;				// sync byte received
reg rxen;				// receiver enable
wire rxce;				// receiver dibit count enable
reg sof;					// start of received frame
reg eof;					// end of received frame
reg mdd;					// management data direction (0=in, 1=out)
reg mdo,mco;			// management output bit and clock bit
wire mdi,mint0;		// management data and interrupt inputs
wire s0,s1,s2,s3;		// port selects
wire w1;					// write enables
wire swr;				// synchronized write enable, data and address
reg [1:0] saddr;
reg [10:0] sdata;
wire txe;				// transmitter empty
reg [15:0] status;	// status register for 2-cycle input instruction
// I/O port selects
assign s0 = iocs & (ioaddr[1:0] == 0);	// receive done
assign s1 = iocs & (ioaddr[1:0] == 1);	// start transmission
assign s2 = iocs & (ioaddr[1:0] == 2);	// management port
assign s3 = iocs & (ioaddr[1:0] == 3);	// configuration port
// TEST
assign test[0] = 0;
assign test[1] = rxvi;		// data valid
assign test[2] = phyen;		// ~reset
assign test[3] = rxdi[0];	// data in
assign test[4] = rxdi[1];	// data in
// configuration register
always @ (posedge mclk)
begin
	if (mrst) phyen <= 0;		// default is PHY disabled
	else if (s3 & iowr) phyen <= din[0];
end
OBUF rstbuf (.I(phyen), .O(rstn));
// synchronize reset
FDPE syncrst (
	.PRE(mrst),	// asynchronous set
	.D(1'b0),	// synchronous clear with rclk
	.Q(reset),	// synchronized reset
	.CE(1'b1),
	.C(rclk)
	);
// I/O write synchronization
always @ (posedge mclk)
begin
	if (s1 & iowr) sdata <= din[10:0];		// needs TIG
end
syn2clk synwr (
	.a(s1 & iowr),
	.aclk(mclk),
	.arst(mrst),
	.b(w1),
	.bclk(rclk),
	.brst(reset)
	);
//
// Ethernet Transmit Logic
//
// transmit frame when tcount > 0
// transmit output address counter and data dibit counter
always @ (posedge rclk)
begin
	if (reset) tcount <= 0;		// number of dibits to transmit
	else if (w1) tcount <= {sdata,2'b00};
	else if (txce) tcount <= tcount - 1'b1;
	if (reset|w1) toaddr <= 0;	// transmitter buffer address for reads
	else if (txce) toaddr <= toaddr + 1'b1;
	txv1 <= txce;
end
assign txce = |tcount;	// count until length counter is zero
// Transmit FIFO - 1-bit output and 16-bit input
RAMB16_S2_S18 txram (
	.ADDRA(toaddr),	// transmit data output port
	.DIA(2'b11),
	.DOA(txd1),
	.CLKA(rclk),
	.WEA(1'b0),			// read bits
	.ENA(1'b1),
	.SSRA(1'b0),
	.ADDRB(maddr),		// transmitter data input port
	.DIB({min0[7:0],min0[15:8]}),
	.DIPB(2'b11),		// transmitter output for CRC
	.DOB({mout0[7:0],mout0[15:8]}),
	.DOPB(),
	.CLKB(mclk),
	.WEB(mwr0),			// write words
	.ENB(mcs0),
	.SSRB(1'b0)
	);
// change data on negative edge of REFCLK
always @ (negedge rclk)
begin
	txd2 <= txd1;
	txv2 <= txv1;
end
// connect outputs
OBUF txd0buf (.I(txd2[0]), .O(txd[0]));
OBUF txd1buf (.I(txd2[1]), .O(txd[1]));
OBUF txvbuf (.I(txv2), .O(txv));
//
// Ethernet Receive Logic
//
// buffer inputs
IBUF rxd0buf (.I(rxd[0]), .O(rxdi[0]));
IBUF rxd1buf (.I(rxd[1]), .O(rxdi[1]));
IBUF rxvbuf (.I(rxv), .O(rxvi));
// synchronize dibits (LSD first) to internal clock then assemble bytes from bits
always @ (posedge rclk)
begin
	rxvs <= rxvi;						// synchronize data valid to shift register output
	rxd0 <= {rxdi[0],rxd0[3:1]};	// shift incoming dibits
	rxd1 <= {rxdi[1],rxd1[3:1]};	// latch bytes
	if (bit8) rxd8 <= {rxd1[3],rxd0[3],rxd1[2],rxd0[2],rxd1[1],rxd0[1],rxd1[0],rxd0[0]};
	if (~rxen) rxctr <= 0;			// hold reset until sync. detect
	else rxctr <= rxctr + 1'b1;	// count incoming bits
end
// detect sync byte
assign sync = ({rxd1[3],rxd0[3],rxd1[2],rxd0[2],rxd1[1],rxd0[1],rxd1[0],rxd0[0]} == 8'b11010101) & rxvs;
assign bit8 = &rxctr;	// detect last dibit of byte
// enable receiver when sync. byte detected and disable when RXV false
// the RXV signal is valid only during odd dibits at the end of the frame
always @ (posedge rclk)
begin
	if (reset) rxen <= 0;									// enable when sync. detect
	else rxen <= (rxen|sync) & (rxvs|(~rxctr[1]));	// disable when no data valid
	sof <= sync & ~rxen;										// start of frame
	eof <= rxen & (~rxvs) & rxctr[1];					// end of frame
end
assign rxce = rxen & bit8;	// count bytes after sync detect
// synchronize to MCLK
syn2clk synsof (
	.a(sof),		// start of frame
	.aclk(rclk),
	.arst(reset),
	.b(fstart),	// reset receiver input address
	.bclk(mclk),
	.brst(mrst)
	);
syn2clk synrxce (
	.a(rxce),	// new byte available
	.aclk(rclk),
	.arst(reset),
	.b(fwr),		// write to current buffer and increment receiver input address
	.bclk(mclk),
	.brst(mrst)
	);
syn2clk syneof (
	.a(eof),		// end of frame delayed until after last rxce
	.aclk(rclk),
	.arst(reset),
	.b(fend),	// done with current FIFO buffer
	.bclk(mclk),
	.brst(mrst)
	);
// receiver input address counter and write enable register
always @ (posedge mclk)
begin
	if (fstart) riaddr <= 0;	// reset receiver buffer address at start of frame
	else if (fwr) riaddr <= riaddr + 1'b1;	// increment after write
	if (mrst) fwe <= 0;			// enable writes if FIFO not full at start of frame
	else fwe <= ((fstart & ~full)|fwe) & ~fend;
end
// 4-entry receive FIFO - 2048x8 input and 1024x16 output
assign fdone = s0 & iowr;	// CPU finished with current FIFO entry
fifo4 rwl (
	.wr(fend),		// read & write strobes to change buffers
	.rd(fdone),
	.wa(waddr),		// top 2 bits of read and write addresses
	.ra(raddr),
	.full(full),	// status flags
	.empty(empty),
	.clk(mclk),		// in CPU clock domain
	.rst(mrst)
	);
// size FIFO
RAM32X12SDP sizebuf (
	.WADDR({3'b000,waddr}),	// use only lower 4 locations
	.RADDR({3'b000,raddr}),
	.DI({1'b0,riaddr}),		// accumulated frame length
	.DO(rsize),					// length for current read buffer
	.WE(fend),					// write after end of frame
	.WCLK(mclk)
	);
// Data FIFO
RAMB16_S2_S4 rxram0 (
	.ADDRA({waddr,riaddr}),	// received data input port
	.DIA(rxd8[1:0]),			// lower bits
	.DOA(),						// unused
	.CLKA(mclk),
	.WEA(fwr), 					// write dibit
	.ENA(fwe),
	.SSRA(1'b0),
	.ADDRB({raddr,maddr}),	// received data output port
	.DIB(4'hF),
	.DOB({mout1[1:0],mout1[9:8]}),
	.CLKB(mclk),
	.WEB(1'b0),					// read-only
	.ENB(mcs1),
	.SSRB(1'b0)
	);
RAMB16_S2_S4 rxram1 (
	.ADDRA({waddr,riaddr}),	// received data input port
	.DIA(rxd8[3:2]),			// upper bits
	.DOA(),						// unused
	.CLKA(mclk),
	.WEA(fwr), 					// write dibit
	.ENA(fwe),
	.SSRA(1'b0),
	.ADDRB({raddr,maddr}),	// received data output port
	.DIB(4'hF),
	.DOB({mout1[3:2],mout1[11:10]}),
	.CLKB(mclk),
	.WEB(1'b0),					// read-only
	.ENB(mcs1),
	.SSRB(1'b0)
	);
RAMB16_S2_S4 rxram2 (
	.ADDRA({waddr,riaddr}),	// received data input port
	.DIA(rxd8[5:4]),			// lower bits
	.DOA(),						// unused
	.CLKA(mclk),
	.WEA(fwr), 					// write dibit
	.ENA(fwe),
	.SSRA(1'b0),
	.ADDRB({raddr,maddr}),	// received data output port
	.DIB(4'hF),
	.DOB({mout1[5:4],mout1[13:12]}),
	.CLKB(mclk),
	.WEB(1'b0),					// read-only
	.ENB(mcs1),
	.SSRB(1'b0)
	);
RAMB16_S2_S4 rxram3 (
	.ADDRA({waddr,riaddr}),	// received data input port
	.DIA(rxd8[7:6]),			// upper bits
	.DOA(),						// unused
	.CLKA(mclk),
	.WEA(fwr), 					// write dibit
	.ENA(fwe),
	.SSRA(1'b0),
	.ADDRB({raddr,maddr}),	// received data output port
	.DIB(4'hF),
	.DOB({mout1[7:6],mout1[15:14]}),
	.CLKB(mclk),
	.WEB(1'b0),					// read-only
	.ENB(mcs1),
	.SSRB(1'b0)
	);
// construct status register
// the number of dibits accepted is always odd due to CRS/DV multiplexing in RMII
assign txe = ~txv1;	// needs TIG
always @ (posedge mclk) if (iord) status <= {mdi,mint0,txe,~empty,rsize};
assign dout = status;
// connect management I/O
always @ (posedge mclk)
begin
	if (mrst) mco <= 0;	// clock
	else if (iowr & s2) mco <= din[1];
	if (mrst) mdo <= 0;	// data
	else if (iowr & s2) mdo <= din[0];
	if (mrst) mdd <= 0;	// 0 = receive, 1 = transmit
	else if (iowr & s2) mdd <= din[2];
end
// tristate I/O buffer and clock buffer
IOBUF mdiobuf (
	.I(mdo),		// data to outside world
	.O(mdi),		// data from outside world
	.IO(mdio),	// FPGA pin
	.T(mdd)		// enable output (I -> IO)
	);
OBUF mdcbuf (
	.I(mco),	// clock
	.O(mdc)
	);
IBUF intbuf (
	.I(mint),	// clock
	.O(mint0)
	);
endmodule

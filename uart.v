//
//								uart.v - 8-bit UART
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a UART with 1 start bit, 8 data bits and 1 stop bit.
// Register 0 id used for data I/O. Register 1 is used for status and to set
// the baud rate. CLK is divided by baud+1.
//
// Command Registers:
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 0 |                               |             Data              |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 1 |                           Baud Rate                           |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// Status Registers:
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 0 |                           |FE |             Data              |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 1 |                                               |TXE|TXR|RXF|RXR|
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		FE = framing error
//		TXR = transmitter FIFO not full
//		TXE = transmitter FIFO empty
//		RXF = receiver FIFO full (oveflow)
//		RXR = receiver FIFO not empty
//
// 141 LUTs and 87 registers used. 173 MHz maximum clock rate.
//
// Normal warnings:
//		<ioaddr<2:1>> is never used.
//
// Revision History:
//		3-3-09	sync. output for 2-cycle input inst.
//		12-8-10	eliminated truncation warning in increment by 1 for Spartan-6
//		2-7-12	disable receiver when transmitting
//		3-24-13	register on enable signal (was 219 LUT, 83 reg, 154 MHz)
//		3-30-13	explicit I/O buffers and FF on transmit data to allow TIG
//
module uart(
    input iocs,			// select this module
    input [2:0] ioaddr,	// internal register addresses
    input [15:0] din,	// parallel data input port
    input iowr,
    output [15:0] dout,	// parallel data output port
    input iord,
	 input rxd,				// receved data input
	 output txd,			// transmit data output
	 output txen,			// transmit enable
    input clk,				// master clock
    input rst
    );
// internal signals
reg [15:0] baud,brg;		// 16x baud rate select
wire tc;						// baud rate divider terminal count
reg en;						// enable UART logic at 16x baud rate
wire rxe,rxf,txe,txf;	// FIFO status
reg [8:0] rxsr;			// receiver shift register
reg [8:0] txsr;			// transmitter shift register
wire rxd0;					// received data when not transmitting
reg rxd1,rxd2,rxd3;		// delay RXD to detect beginning of start bit
reg txd0;					// buffer output
reg [8:1] sdly;			// start delay logic (shift register)
wire start;
reg [7:0] rctr,tctr;		// sample period counters
wire rnz,rxc,tnz,txc;	// clocks
wire rstop,tstop;			// terminal count at stop bit position
wire [8:0] rx;				// receiver FIFO output data
reg [8:0] omux;			// receiver output multiplexer
wire [7:0] tx;				// transmitter FIFO output
// address decoding - upper 3 bits ignored
wire r0,r1;
assign r0 = iocs & (ioaddr[0] == 1'b0);
assign r1 = iocs & (ioaddr[0] == 1'b1);
// baud rate generator - divide clock by 16-bit constant
always @ (posedge clk)
begin
	if (iowr & r1) baud <= din;	// set divisor
	if (rst|tc) brg <= 0;			// reset if divisor reached on previous cycle
	else brg <= brg + 1'b1;			// else count up
	en <= tc;							// beffer clock enable
end
assign tc = (brg == baud);			// reset when modulus - 1
// buffer input
IBUF rxdbuf (.I(rxd), .O(rxd0));	// TIG rxd0
// receiver logic to detect start bit, generate data sampling clock (RXC)
// and de-serialize data
always @ (posedge clk)
begin
	rxd1 <= rxd0 | txen;				// unstable
	rxd2 <= rxd1;						// stable
	if (en) rxd3 <= rxd2;			// detect start bit leading edge
	if (en) sdly <= {sdly[7:1],rxd3 & ~rxd2};	// and apply 1/2-bit delay
	if (rst | (en & rstop)) rctr <= 0;			// generate clock
	else if (en & (rnz | start)) rctr <= rctr + 8'h01;
	if (en & rxc) rxsr <= {rxd2,rxsr[8:1]};	// sample data
end
assign rnz = |rctr;					// receiver sample counter non-zero
assign rxc = (rctr[3:0] == 15);	// sample at bit cell centers
assign start = sdly[8] & ~rxd2;	// start sampling in middle of start bit
assign rstop = (rctr == 144);		// stop sampling in middle of stop bit
// receive FIFO
fifo32x9s rxfifo (
	.pdi({~rxsr[8],rxsr[7:0]}),	// receiver shift register (invert stop bit)
	.iv(en & rstop),					// stop bit detected
	.oe(iord & r0),					// read command
	.pdo(rx),							// received byte out
	.ov(),
	.empty(rxe),						// no data to read
	.full(rxf),							// receiver overflow
	.clk(clk),
	.rst(rst)
	);
// connect output
always @ (posedge clk)
	if (iord) omux <= ioaddr[0] ? {5'b00000,txe,~txf,rxf,~rxe} : rx;
assign dout = {7'b0000000,omux};
// transmit FIFO
fifo32x8s txfifo (
	.pdi(din[7:0]),			// data bus
	.iv(iocs & iowr & r0),	// write data byte
	.oe(en & tstop),			// get new byte to transmit
	.pdo(tx),					// byte to transmit
	.ov(),
	.empty(txe),				// no data to send
	.full(txf),					// transmitter overflow
	.clk(clk),
	.rst(rst)
	);
// tranmitter shift register - shift MSB to LSB
always @ (posedge clk)
begin
	if (rst | (en & tstop)) tctr <= 0;					// generate clock
	else if (en & (tnz | ~txe)) tctr <= tctr + 8'h01;
	if (en & txc & ~tnz & ~txe) txsr <= {tx,1'b0};	// load data and start bit
	else if (en & txc) txsr <= {1'b1,txsr[8:1]};		// fill with one's
	txd0 <= txsr[0];											// output buffer for TIG
end
assign txen = tnz | ~txe;			// enable when FIFO not empty or still shifting
assign tnz = |tctr;					// receiver sample counter non-zero
assign txc = (tctr[3:0] == 0);	// shift every 16th clock
assign tstop = (tctr == 159);		// stop on 10th (stop) bit
OBUF txdbuf (.I(txd0), .O(txd));
endmodule

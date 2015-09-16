//
//						viterbi8.v - 8-State Viterbi Decoder
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// The Viterbi decoder is preconfigured for BICM8 with gray coding. Received symbols
// (5 bits of phase) written to the data input port are decoded and the most likely
// previous states are placed in traceback memory. The start port must be written
// before the first symbol to reset metrics. The traceback port must be written after
// the last symbol to start traceback. Decoded words (2 bits per symbol) may be read
// from the data port in 16-bit increments. The first read provides 2-14 residue bits
// if the number of symbols input is not an integer multiple of 8.
//
// Three output ports is used to configure and use the decoder:
// 
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |                               |       Signal      |           | Data Input
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                                                               | Start
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |                                                               | Traceback
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |                            (unused)                           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// Two input ports are provided to read decoded words from traceback memory and to
// read the number of symbols remaining. Reading port 1 causes the next 8 symbols to be
// decoded in the next 8 clock cycles. The first data word presented after EOF is the
// residue that doesn't fit in an integral nmumber of 8 symbol words. This is normally
// the symbols transmitted after a data frame to reset the convolutional coder and
// provide a known state (0) from which to start decoding.
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |                           Data Word                           | Data Output
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                            (unused)                           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |                            (unused)                           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 | V |                   |                Symbols                | Status
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		V = output data word valid (symbol counter modulo 8 is 0)
//
// 1393 (9% XC6SLX25) LUT6, 250 registers and 1 RAM used. 109 (-2) or 128 MHz (-3)
// maximum clock rate.
//
// Normal Warnings:
//		<ioaddr<2:2>>, <din<15:8>, <din<2:0>> and <rst> never used.
// 
module viterbi8(
	 input iocs,			// select this module
	 input [2:0] ioaddr,	// I/O address within this module
	 input [15:0] din,	// data input to this module from CPU
	 output [15:0] dout,	// data output from this module to CPU
	 input iowr,iord,		// I/O read and write enables
	 input clk,rst			// master clock and reset
	 );
// internal signals
wire first,last;		// first and last symbols
wire [1:0] p0,p1,p2,p3,p4,p5,p6,p7;	// ACS outputs
wire acsv,tbmv;		// ACS and traceback outputs valid
wire [9:0] symbols;	// number of symbols in traceback memory
wire [7:0] d0,d1;		// data output bytes from decoder
reg readsym;			// symbol counter read
wire [15:0] data,status;	// data and status ports
reg [15:0] omux;		// output multiplexer
// address decode
wire r0,w0,w1,w2;
assign r0 = iocs & (ioaddr[1:0] == 0) & iord;
assign w0 = iocs & (ioaddr[1:0] == 0) & iowr;
assign w1 = iocs & (ioaddr[1:0] == 1) & iowr;
assign w2 = iocs & (ioaddr[1:0] == 2) & iowr;
assign first = w1;	// reset metrics before first symbol
assign last = w2;		// pulse after last symbol received
// Viterbi decoder
acs8x4x16 acs (
	.r(din[7:3]),	// signal input
	.iv(w0),
	.p0(p0),			// path outputs
	.p1(p1),
	.p2(p2),
	.p3(p3),
	.p4(p4),
	.p5(p5),
	.p6(p6),
	.p7(p7),
	.ov(acsv),
	.clk(clk),		// master clock
	.rst(first)		// reset metrics (acts 1 clock before input) 
	);
// Detect data read and start next shift cycle
always @ (posedge clk)
begin
	readsym <= r0;
end
// Viterbi decoder traceback - 24 slices
tbm1024x8 tbm (
	.p0(p0),			// path inputs
	.p1(p1),
	.p2(p2),
	.p3(p3),
	.p4(p4),
	.p5(p5),
	.p6(p6),
	.p7(p7),
	.iv(acsv), 		// above inputs valid
	.eof(last),		// start traceback
	.do0(d0),		// data outputs
	.do1(d1),
	.sym(symbols), // symbols stored in traceback memory
	.ov(tbmv), 
	.oe(readsym),	// get next 8 symbols after counter read 
	.clk(clk), 
	.rst(first)		// reset symbol counter
	);
// output multiplexer allows one or two bits per symbol and count of symbols
assign data = {d1[7],d0[7],d1[6],d0[6],d1[5],d0[5],d1[4],d0[4],d1[3],d0[3],d1[2],d0[2],d1[1],d0[1],d1[0],d0[0]};
assign status = {tbmv,5'b00000,symbols};
always @ (posedge clk) omux <= ioaddr[1] ? status : data;
assign dout = omux;
endmodule

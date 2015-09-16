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
// are retreived directly from the FFT output buffer using a spiral scan, decoded and
// the most likely previous states are placed in traceback memory.
//
// One output port is used to configure the decoder:
// 
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |               |  Null Subcar. |     Number of Subcarriers     |
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
//  0 |                            (unused)                           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                           Data Word                           | 2 bits per symbol
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |                            (unused)                           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 | V |                   |                Symbols                | Status
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		V = output data byte/word valid (symbol counter modulo 8 is 0)
//
// 1411 (9% XC6SLX25) LUT6, 276 registers and 1 RAM used. 128 MHz (-3) maximum clock rate.
//
// Normal Warnings:
//		<phs<2:0>>, <din>, <iowr> and <rst> never used.
// 
module viterbi8p(
	 input start,			// start decoding
	 output rfd,			// ready for input data
	 input [7:0] phs,		// subcarrier phase (differential)
	 input iv,				// input data valid
	 input iocs,			// select this module
	 input [2:0] ioaddr,	// I/O address within this module
	 input [15:0] din,	// data input to this module from CPU
	 output [15:0] dout,	// data output from this module to CPU
	 input iowr,iord,		// I/O read and write enables
	 input clk,rst			// master clock and reset
	 );
// internal signals
wire first,last;		// first and last symbols
reg [3:0] z;			// null SC counter
reg [7:0] n;			// total SC counter
wire zce,nce;			// count enables
reg dzce,dnce;			// delayed count enables
wire [1:0] p0,p1,p2,p3,p4,p5,p6,p7;	// ACS outputs
wire acsv,tbmv;		// ACS and traceback outputs valid
wire [9:0] symbols;	// number of symbols in traceback memory
wire [7:0] d0,d1;		// data output bytes from decoder
reg readsym;			// symbol counter read
wire [15:0] data,status;	// data and status ports
reg [15:0] omux;		// output multiplexer
reg [3:0] zsc;			// null subcarriers
reg [7:0] nsc;			// total subcarriers
// address decode
wire s1;
assign s1 = iocs & (ioaddr[2:0] == 1);
// Configuration registers
always @ (posedge clk)
begin
	if (rst) nsc <= 0;	// number of subcarriers
	else if (iowr & iocs) nsc <= din[7:0];
	if (rst) zsc <= 0;	// null subcarriers
	else if (iowr & iocs) zsc <= din[11:8];
end
// Count subcarriers and issue control signals
// Configuration registers
always @ (posedge clk)
begin
	if (rst) z <= 0;			// count subcarriers
	else if (start) z <= zsc;
	else if (iv & zce) z <= z - 1'b1;
	if (iv) dzce <= zce;		// delay counter enable
	if (rst) n <= 0;			// count subcarriers
	else if (start) n <= nsc;
	else if (iv & nce) n <= n - 1'b1;
	dnce <= nce;				// delay counter enable
end
assign zce = |z;	// Or all bits to detect non-zero state
assign nce = |n;
assign first = iv & dzce;	// ignore first Z subcarriers
assign last = dnce & ~nce;	// pulse after last symbol received
assign rfd = nce;				// ready for data
// Viterbi decoder
acs8x4x16 acs (
	.r(phs[7:3]),	// signal input
	.iv(iv & ~zce),
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
	readsym <= iord & s1;
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

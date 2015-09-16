//
//							8-state 8PSK Encoder
//
//				(C) Copyright 2005-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module encodes OFDM symbols using differential 8-PSK trellis coded modulation.
// It also encodes a reference symbol using direct 16-PSK modulation. It is controlled
// via 4 output ports:
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |   D7  |   D6  |   D5  |   D4  |   D3  |   D2  |   D1  |   D0  | Encode 1-8 SC
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |       P3      |       P2      |       P1      |       P0      | Transmit 1-4 SC
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |                           |REF| Number of SC  | SC Magnitude  | SC characteristics
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |                                                               | Reset to SC zero
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//    REF: 0 = encode dibits into D8PSK, 1 = transmit 16PSK directly
//
// There is also one status port:
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//    |                                                           |RDY|
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		RDY = ready for data
//
// When REF = 1, the input word generates 1-4 4-bit symbols. When REF = 0, the input
// word is converted to a sequence of 1-8 dibits that are encoded as 8 tribits. The
// BICM encoder has 8 states (v=3) where S stores the encoder state. The two uncoded
// inputs (U) are convolutionally encoded into 3 bits (C) per the specification from
// Zihavi. The encoder output is then converted to a Gray code 8-ary PSK signal.
//
// h(2) h(1) h(0)
//	 4    2    6 
//	 1    4    7
//
// 46 LUT6 and 50 registers used. 436 MHz max. 2 clock delay from load to start of output.
//
// Normal Warnings:
//		<iord> is never used.
// 
module encbicm8w(
	input iocs,					// I/O select
	input [2:0] ioaddr,		// I/O address
	input [15:0] din,			// data input
	input iowr,					// output strobe
	output [15:0] dout,		// data output
	input iord,					// input strobe
	output trst,				// transmit subcarrier address reset
	output [3:0] tmag,tphs,	// encoded magnitude and 16-PSK outputs
	output tov,					// transmit output valid
	output refsym,				// 0 = incremental phase, 1 = absolute phase
	input clk,					// master clock
	input rst					// master reset
	);
// internal signals
reg [3:0] mag;			// magnitude od subcarriers
reg [3:0] nsc;			// number of subcarriers
reg ref;					// reference symbol
reg rdy;					// ready for data
reg [3:0] n;			// subcarrier counter
wire z;					// subcarrier counter is zero
reg [15:0] u;			// uncoded data register
reg [15:0] p;			// PSK symbol register
reg [2:0] s;			// encoder state
wire [2:0] c;			// coded data
wire [2:0] g;			// gray-code signal constellation
reg [3:0] d;			// output register
reg v;					// output valid
// address decode
wire wr0,wr1,wr2,wr3;	// output port selects
assign wr0 = iocs & iowr & (ioaddr == 0);
assign wr1 = iocs & iowr & (ioaddr == 1);
assign wr2 = iocs & iowr & (ioaddr == 2);
assign wr3 = iocs & iowr & (ioaddr == 3);
assign trst = wr3;
// configuration registers
always @ (posedge clk)
begin
	if (rst) mag <= 0;								// default to no signal
	else if (wr2) mag <= din[3:0];				// set subcarrier magnitude
	if (rst) nsc <= 0;								// default to no subcarriers
	else if (wr2) nsc <= din[7:4];				// set number of subcarriers
	if (rst) ref <= 0;								// default to 8PSK TCM
	else if (wr2) ref <= din[8];					// set symbol type
end
// data input shift registers and subcarrier counter
always @ (posedge clk)
begin
	if (rst) n <= 0;					// reset on power up
	else if (wr0|wr1) n <= nsc;	// set subcarriers to output
	else if (~z) n <= n - 1'b1;	// count down
	if (wr0) u <= din;				// load uncoded data register
	else u <= {2'b00,u[15:2]};		// then shift right 2 bits
	if (wr1) p <= din;				// load PSK register
	else p <= {4'h0,p[15:4]};		// then shift right 4 bits
end
assign z = ~|n;	// zero detect
// 3-bit encoder state has 2-symbol delay
always @ (posedge clk)
begin
	if (trst) s[0] <= 0; else s[0] <= u[0];	// 1-bit shift register for uncoded bit 0
	if (trst) s[1] <= 0; else s[1] <= s[2];	// 2-bit shift register for uncoded bit 1
	if (trst) s[2] <= 0; else s[2] <= u[1];
end
// encode bits by combining unencoded data with encoder state
assign c[2] = u[0] ^ u[1] ^ s[0] ^ s[1] ^ s[2];
assign c[1] = u[1] ^ s[0];
assign c[0] = u[0] ^ s[1];
// use Gray code mapping to 8-PSK signal constellation
assign g[0] = c[0] ^ c[1];
assign g[1] = c[1] ^ c[2];
assign g[2] = c[2];
// select output
always @ (posedge clk)
begin
	d <= ref ? p[3:0] : {g,1'b0};
	v <= ~z;
end
// status register
always @ (posedge clk) rdy <= z;	// ready for data input
// connect outputs
assign tphs = d;
assign tmag = mag;
assign tov = v;
assign refsym = ref;
assign dout = {15'b000000000000000,rdy};
endmodule

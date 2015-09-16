//
//			comp16a.v - Compressor with 16-bit X & Y I/O & serial mult.	
//
//					(C) Copyright 2008-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a compressor for rectangular signals. The input
// magnitude is estimated and the required gain is obtained from a ROM and
// applied to multipliers for the X and Y paths. The ROM is loaded via the
// CIN input and consists of 128 8-bit entries formatted as follows:
//
//     7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+
//   |    Integer    |   Fraction    | gain entry
//   +---+---+---+---+---+---+---+---+
//
// Entries are loaded serially with the entry for the largest magnitude first.
// The absence of compression is selected by loading all entries with 16. Note
// that the magnitude estimate has a range of 0.87-0.98 of the actual value.
//
// 134 LUT6s and 116 registers are used. 303 MHz maximum clock rate.
// There is a 10 clock delay.
//
// History:
//		6-8-09	created
//		5-3-10	8-bit magnitude (was 72 slices 105 MHz)
//		8-17-11	serial multiplier (was 78 slices and 2 mult.)
//		3-21-12	128-entry gain table (was 117 LUT, 113 reg., 303 MHz)
//
module comp16a (
    input [15:0] dix,diy,	// 16-bit data in
    input iv,					// input valid
    output [15:0] dox,doy,	// 16-bit data out
    output ov,					// output valid
    input clk,
	 input [7:0] cin,			// configuration input
	 input cwe
    );
// internal signals
wire [19:0] x,y;	// multiplied input signal
wire [7:0] gain;	// gain control
wire [7:0] mag;	// magnitude of input (0-1.4)
wire [6:0] mag1;	// magnitude limited to 0-1
wire mv;				// magnitude valid
// calculate magnitude of input - limit max. value to 127
mag8 magdet (
	.x(dix[15:8]),
	.y(diy[15:8]),
	.iv(iv),
	.mag(mag),
	.ov(mv),
	.clk(clk)
	);
assign mag1 = mag[7] ? 7'b1111111 : mag[6:0];
// look up gain (async.)
srl128x8e gm (
	.d(cin[7:0]),
	.ce(cwe),
	.clk(clk),
	.a(mag1),
	.y(gain)
	);
// multiply input signal by AGC value
mul16c8u20c mul (
	.dix(dix),
	.diy(diy),
	.diz(gain),
	.iv(mv),
	.dox(x),
	.doy(y),
	.ov(ov),
	.clk(clk)
	);
// connect outputs - use bottom 16 bits for gain of 0-16
assign dox = x[15:0];
assign doy = y[15:0];
endmodule

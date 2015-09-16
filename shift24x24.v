//
//								shift24x24.v - 24-bit Shifter
//
//					  (C) Copyright 2007-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// Shift 24-bit signed integer right by 0-23 bits.
//
// History:
//	2-12-10	Modified for 24 bits.
//
module shift24x24(
    input [23:0] D,
    output [23:0] Y,
    input [4:0] S
    );
// internal signals
wire [23:0] i,j;
// shift by 0, 1, 2 or 3
MUX4X24 mux1 (
	.D0(D),
	.D1({D[23],D[23:1]}),					// shift 1
	.D2({D[23],D[23],D[23:2]}),			// shift 2
	.D3({D[23],D[23],D[23],D[23:3]}),	// shift 3
	.S(S[1:0]),
	.Y(i)
	);
// shift by 0, 4, 8 or 12
MUX4X24 mux4 (
	.D0(i),
	.D1({i[23],i[23],i[23],i[23],i[23:4]}),																	// shift 4
	.D2({i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23:8]}),									// shift 8
	.D3({i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23],i[23:12]}),	// shift 12
	.S(S[3:2]),
	.Y(j)
	);
// shift by 0 or 16
assign Y = S[4] ? {j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23],j[23:16]} : {j};
endmodule

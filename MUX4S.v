//
//							4-Input Multiplexer with Latch
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// LUT6 forms 4-input multiplexer:
//
//		I5	I4	I3	I2	I1	I0	O	INIT
//		0	0	x	x	x	0	0	AAAA
//		0	0	x	x	x	1	1
//		0	1	x	x	0	x	0	CCCC
//		0	1	x	x	1	x	1
//		1	0	x	0	x	x	0	F0F0
//		1	0	x	1	x	x	1
//		1	1	0	x	x	x	0	FF00
//		1	1	1	x	x	x	1
//
module MUX4S(D, S, Q, CE, CLK, RST);
    input [3:0] D;	// data inputs
    input [1:0] S;	// select
    output Q;			// data output
	 input CE;			// clock enable
	 input CLK;			// master clock
	 input RST;			// synchronous reset
// internal signals
wire y;	// outputs of LUTs and multiplexer
// internal logic - use LUT local outputs and MUX local inputs
LUT6_L #(.INIT(64'hFF00F0F0CCCCAAAA)) lut (.I0(D[0]), .I1(D[1]), .I2(D[2]), .I3(D[3]), .I4(S[0]), .I5(S[1]), .LO(y));
FDRE ff (.D(y), .C(CLK), .CE(CE), .R(RST), .Q(Q));
endmodule

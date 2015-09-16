//
//						2-Input 2-bit Multiplxer with Latch
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 2 LUT5s form a 2-input 2-bit multiplexer:
//
//		S			B	A
//		I4	I3	I2	I1	I0	O	
//		0	x	x	0	0	0	A
//		0	x	x	0	1	1	A
//		0	x	x	1	0	0	A
//		0	x	x	1	1	1	A
//		1	x	x	0	0	0	B
//		1	x	x	0	1	0	B
//		1	x	x	1	0	1	B
//		1	x	x	1	1	1	B
//
//		S	B	A
//		I4	I3	I2	I1	I0	O	
//		0	0	0	x	x	0	A
//		0	0	1	x	x	1	A
//		0	1	0	x	x	0	A
//		0	1	1	x	x	1	A
//		1	0	0	x	x	0	B
//		1	0	1	x	x	0	B
//		1	1	0	x	x	1	B
//		1	1	1	x	x	1	B
//
module MUX2X2S (
    input [1:0] D0,D1,	// data inputs
    input S,				// select
    output [1:0] Q,		// data output
	 input CE,				// clock enable
	 input CLK,				// master clock
	 input RST				// synchronous reset
	 );
// internal signals
wire y0,y1;	// outputs of LUTs
// internal logic - use LUT local outputs and MUX local inputs
LUT5_L #(.INIT(32'hCCCCAAAA)) lut0 (.I0(D0[0]), .I1(D1[0]), .I2(D0[1]), .I3(D1[1]), .I4(S), .LO(y0));
FDRE ff0 (.D(y0), .C(CLK), .CE(CE), .R(RST), .Q(Q[0]));
LUT5_L #(.INIT(32'hFF00F0F0)) lut1 (.I0(D0[0]), .I1(D1[0]), .I2(D0[1]), .I3(D1[1]), .I4(S), .LO(y1));
FDRE ff1 (.D(y1), .C(CLK), .CE(CE), .R(RST), .Q(Q[1]));
endmodule

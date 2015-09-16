//
//							lu1a.v - 1-bit Logic Unit
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module combines one LUT for operations using the A and B inputs
// with another LUT for manipulation of input A using a mask at input C. 
//
// Multibit LUT:
//		2	1	0	C	B	A
//		I5	I4	I3	I2	I1	I0	O	Op.
//		0	0	0	x	0	0	1	NOT B
//		0	0	0	x	0	1	1	
//		0	0	0	x	1	0	0	33
//		0	0	0	x	1	1	0	
//		0	0	1	x	0	0	0	A AND B
//		0	0	1	x	0	1	0	
//		0	0	1	x	1	0	0	88
//		0	0	1	x	1	1	1	
//		0	1	0	x	0	0	0	A OR B
//		0	1	0	x	0	1	1	
//		0	1	0	x	1	0	1	EE
//		0	1	0	x	1	1	1	
//		0	1	1	x	0	0	0	A XOR B
//		0	1	1	x	0	1	1	
//		0	1	1	x	1	0	1	66
//		0	1	1	x	1	1	0	
//
// Single bit LUT:
//		2	1	0	C	B	A
//		I5	I4	I3	I2	I1	I0	O	Op.
//		1	0	0	0	x	0	0	MASK (AND)
//		1	0	0	0	x	1	0	0
//		1	0	0	1	x	0	0	A
//		1	0	0	1	x	1	1	
//		1	0	1	0	x	0	0	RESET (ANDN)
//		1	0	1	0	x	1	1	A
//		1	0	1	1	x	0	0	0
//		1	0	1	1	x	1	0	
//		1	1	0	0	x	0	0	SET (OR)
//		1	1	0	0	x	1	1	A
//		1	1	0	1	x	0	1	F
//		1	1	0	1	x	1	1	
//		1	1	1	0	x	0	0	INVERT (XOR)
//		1	1	1	0	x	1	1	A
//		1	1	1	1	x	0	1	5
//		1	1	1	1	x	1	0	
//
// 16 slices used.
//
module lu1a (
    input A,			// register A
    input B,			// register B
    input C,			// constant C
    input [2:0] OP,	// operation select
    output Y			// output
    );
// one LUT6 for multiple and single bit manipulation
LUT6 #(.INIT(64'h5AFA0AA066EE8833)) lut (.I0(A), .I1(B), .I2(C), .I3(OP[0]), .I4(OP[1]), .I5(OP[2]), .O(Y));
endmodule

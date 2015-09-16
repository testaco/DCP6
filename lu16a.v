//
//							lu16a.v - 16-bit Logic Unit
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// Sixteen lu1a 1-bit logic units provide the following operations:
//
//		OP	Desription
//		--	----------
//		0	NOT B
//		1	A AND B
//		2	A OR B
//		3	A XOR B
//		4	SELECT A[C:0]
//		5	SET A[C]
//		6	RESET A[C]
//		7	INVERT A[C]
//
// 29 slices used.
//
module lu16a(
    input [15:0] a,	// first operand input
    input [15:0] b,	// second operand input
    input [3:0] c,	// bit select input
    input [2:0] op,	// select operation
    output [15:0] y	// output
    );
// 1 of 16 decoder to generate mask for bit selection
wire [15:0] d;
mask16 mask (
	.c(c),				// bit select input
	.s(op[1]|op[0]),	// 4 = select multiple bits, 5-7 = select one bit
	.m(d)					// bit mask
	);
// use 16 bit-wide logic units to process 16 bits in parallel
lu1a lu0 (.A(a[0]), .B(b[0]), .C(d[0]), .OP(op), .Y(y[0]));
lu1a lu1 (.A(a[1]), .B(b[1]), .C(d[1]), .OP(op), .Y(y[1]));
lu1a lu2 (.A(a[2]), .B(b[2]), .C(d[2]), .OP(op), .Y(y[2]));
lu1a lu3 (.A(a[3]), .B(b[3]), .C(d[3]), .OP(op), .Y(y[3]));
lu1a lu4 (.A(a[4]), .B(b[4]), .C(d[4]), .OP(op), .Y(y[4]));
lu1a lu5 (.A(a[5]), .B(b[5]), .C(d[5]), .OP(op), .Y(y[5]));
lu1a lu6 (.A(a[6]), .B(b[6]), .C(d[6]), .OP(op), .Y(y[6]));
lu1a lu7 (.A(a[7]), .B(b[7]), .C(d[7]), .OP(op), .Y(y[7]));
lu1a lu8 (.A(a[8]), .B(b[8]), .C(d[8]), .OP(op), .Y(y[8]));
lu1a lu9 (.A(a[9]), .B(b[9]), .C(d[9]), .OP(op), .Y(y[9]));
lu1a lu10 (.A(a[10]), .B(b[10]), .C(d[10]), .OP(op), .Y(y[10]));
lu1a lu11 (.A(a[11]), .B(b[11]), .C(d[11]), .OP(op), .Y(y[11]));
lu1a lu12 (.A(a[12]), .B(b[12]), .C(d[12]), .OP(op), .Y(y[12]));
lu1a lu13 (.A(a[13]), .B(b[13]), .C(d[13]), .OP(op), .Y(y[13]));
lu1a lu14 (.A(a[14]), .B(b[14]), .C(d[14]), .OP(op), .Y(y[14]));
lu1a lu15 (.A(a[15]), .B(b[15]), .C(d[15]), .OP(op), .Y(y[15]));
endmodule

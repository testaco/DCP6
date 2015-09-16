//
//					addsubmovneg16a.v - 16-bit adder/subtracter
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	ENA SUB Desc.
//  0   0  Y = B + CI
//	 0   1  Y = ~B + CI
//	 1   0  Y = A + B + CI
//	 1   1  Y = A + ~B + CI
//
// 32 LUT5s used.
//
module addsubmovneg16a(
    input SUB,
    input ENA,
    input [15:0] A,
    input [15:0] B,
    input CI,
    output CO,
    output [15:0] Y
    );
// internal signals
wire c1,c2,c3;	// carry propogation
// use 4 4-bit adders
addsubmovneg4a a3 (.SUB(SUB), .ENA(ENA), .A(A[15:12]), .B(B[15:12]), .CI(c3), .CO(CO), .Y(Y[15:12]));
addsubmovneg4a a2 (.SUB(SUB), .ENA(ENA), .A(A[11:8]), .B(B[11:8]), .CI(c2), .CO(c3), .Y(Y[11:8]));
addsubmovneg4a a1 (.SUB(SUB), .ENA(ENA), .A(A[7:4]), .B(B[7:4]), .CI(c1), .CO(c2), .Y(Y[7:4]));
addsubmovneg4a a0 (.SUB(SUB), .ENA(ENA), .A(A[3:0]), .B(B[3:0]), .CI(CI), .CO(c1), .Y(Y[3:0]));
endmodule

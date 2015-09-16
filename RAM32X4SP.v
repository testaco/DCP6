//
//							32-word X 4-bit Single Port RAM
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 32-word memory with asynchronous read and synchronous write.
//
module RAM32X4SP (A, D, O, WE, WCLK);
    input [4:0] A;
    input [3:0] D;
    output [3:0] O;
    input WE;
    input WCLK;
// 4 RAM32X1S primitives
RAM32X1S r0 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .D(D[0]), .O(O[0]), .WE(WE), .WCLK(WCLK));
RAM32X1S r1 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .D(D[1]), .O(O[1]), .WE(WE), .WCLK(WCLK));
RAM32X1S r2 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .D(D[2]), .O(O[2]), .WE(WE), .WCLK(WCLK));
RAM32X1S r3 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .D(D[3]), .O(O[3]), .WE(WE), .WCLK(WCLK));
endmodule

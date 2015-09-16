//
//							16-word X 8-bit Single Port RAM
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module RAM16X8SP(A, D, O, WE, WCLK);
    input [3:0] A;
    input [7:0] D;
    output [7:0] O;
    input WE;
    input WCLK;
// 8 RAM16X1S primitives
RAM16X1S ram0 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[0]), .O(O[0]), .WE(WE), .WCLK(WCLK));
RAM16X1S ram1 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[1]), .O(O[1]), .WE(WE), .WCLK(WCLK));
RAM16X1S ram2 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[2]), .O(O[2]), .WE(WE), .WCLK(WCLK));
RAM16X1S ram3 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[3]), .O(O[3]), .WE(WE), .WCLK(WCLK));
RAM16X1S ram4 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[4]), .O(O[4]), .WE(WE), .WCLK(WCLK));
RAM16X1S ram5 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[5]), .O(O[5]), .WE(WE), .WCLK(WCLK));
RAM16X1S ram6 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[6]), .O(O[6]), .WE(WE), .WCLK(WCLK));
RAM16X1S ram7 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .D(D[7]), .O(O[7]), .WE(WE), .WCLK(WCLK));
endmodule

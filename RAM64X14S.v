//
//							64-word X 14-bit Single Port RAM
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 64-word memory with asynchronous read and synchronous write.
//
module RAM64X14S (A, D, O, WE, WCLK);
    input [5:0] A;
    input [13:0] D;
    output [13:0] O;
    input WE;
    input WCLK;
// 14 RAM64X1S primitives
RAM64X1S r0 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[0]), .O(O[0]), .WE(WE), .WCLK(WCLK));
RAM64X1S r1 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[1]), .O(O[1]), .WE(WE), .WCLK(WCLK));
RAM64X1S r2 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[2]), .O(O[2]), .WE(WE), .WCLK(WCLK));
RAM64X1S r3 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[3]), .O(O[3]), .WE(WE), .WCLK(WCLK));
RAM64X1S r4 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[4]), .O(O[4]), .WE(WE), .WCLK(WCLK));
RAM64X1S r5 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[5]), .O(O[5]), .WE(WE), .WCLK(WCLK));
RAM64X1S r6 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[6]), .O(O[6]), .WE(WE), .WCLK(WCLK));
RAM64X1S r7 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[7]), .O(O[7]), .WE(WE), .WCLK(WCLK));
RAM64X1S r8 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[8]), .O(O[8]), .WE(WE), .WCLK(WCLK));
RAM64X1S r9 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[9]), .O(O[9]), .WE(WE), .WCLK(WCLK));
RAM64X1S r10 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[10]), .O(O[10]), .WE(WE), .WCLK(WCLK));
RAM64X1S r11 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[11]), .O(O[11]), .WE(WE), .WCLK(WCLK));
RAM64X1S r12 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[12]), .O(O[12]), .WE(WE), .WCLK(WCLK));
RAM64X1S r13 (.A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .D(D[13]), .O(O[13]), .WE(WE), .WCLK(WCLK));
endmodule

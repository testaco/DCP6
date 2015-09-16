//
//						256-word X 8-bit Single Port RAM
//
//					(C) Copyright 2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 256-byte memory with asynchronous read and synchronous write.
//
module RAM256X8S(A, D, O, WE, WCLK);
    input [7:0] A;
    input [7:0] D;
    output [7:0] O;
    input WE;
    input WCLK;
// 8 RAM256X1S primitives
RAM256X1S ram0 (.A(A), .D(D[0]), .O(O[0]), .WE(WE), .WCLK(WCLK));
RAM256X1S ram1 (.A(A), .D(D[1]), .O(O[1]), .WE(WE), .WCLK(WCLK));
RAM256X1S ram2 (.A(A), .D(D[2]), .O(O[2]), .WE(WE), .WCLK(WCLK));
RAM256X1S ram3 (.A(A), .D(D[3]), .O(O[3]), .WE(WE), .WCLK(WCLK));
RAM256X1S ram4 (.A(A), .D(D[4]), .O(O[4]), .WE(WE), .WCLK(WCLK));
RAM256X1S ram5 (.A(A), .D(D[5]), .O(O[5]), .WE(WE), .WCLK(WCLK));
RAM256X1S ram6 (.A(A), .D(D[6]), .O(O[6]), .WE(WE), .WCLK(WCLK));
RAM256X1S ram7 (.A(A), .D(D[7]), .O(O[7]), .WE(WE), .WCLK(WCLK));
endmodule

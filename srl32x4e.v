//
//			32 word x 4 bit Adjustable-length Shift register
//
//				(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module srl32x4e(y,d,a,ce,clk);
    output [3:0] y;	// output selected by address
    input [3:0] d;	// input	word
	 input [4:0] a;	// address of output word
    input ce;			// enable input
    input clk;			// clock input
// 4 32-bit shift registers
SRLC32E sr0 (.D(d[0]), .A(a), .CLK(clk), .CE(ce), .Q(y[0]), .Q31());
SRLC32E sr1 (.D(d[1]), .A(a), .CLK(clk), .CE(ce), .Q(y[1]), .Q31());
SRLC32E sr2 (.D(d[2]), .A(a), .CLK(clk), .CE(ce), .Q(y[2]), .Q31());
SRLC32E sr3 (.D(d[3]), .A(a), .CLK(clk), .CE(ce), .Q(y[3]), .Q31());
endmodule

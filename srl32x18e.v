//
//			32 word x 18 bit Adjustable-length Shift register
//
//				(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module srl32x18e(y,d,a,ce,clk);
    output [17:0] y;	// output selected by address
    input [17:0] d;	// input	word
	 input [4:0] a;	// address of output word
    input ce;			// enable input
    input clk;			// clock input
// 18 32-bit shift registers
SRLC32E sr0 (.D(d[0]), .A(a), .CLK(clk), .CE(ce), .Q(y[0]), .Q31());
SRLC32E sr1 (.D(d[1]), .A(a), .CLK(clk), .CE(ce), .Q(y[1]), .Q31());
SRLC32E sr2 (.D(d[2]), .A(a), .CLK(clk), .CE(ce), .Q(y[2]), .Q31());
SRLC32E sr3 (.D(d[3]), .A(a), .CLK(clk), .CE(ce), .Q(y[3]), .Q31());
SRLC32E sr4 (.D(d[4]), .A(a), .CLK(clk), .CE(ce), .Q(y[4]), .Q31());
SRLC32E sr5 (.D(d[5]), .A(a), .CLK(clk), .CE(ce), .Q(y[5]), .Q31());
SRLC32E sr6 (.D(d[6]), .A(a), .CLK(clk), .CE(ce), .Q(y[6]), .Q31());
SRLC32E sr7 (.D(d[7]), .A(a), .CLK(clk), .CE(ce), .Q(y[7]), .Q31());
SRLC32E sr8 (.D(d[8]), .A(a), .CLK(clk), .CE(ce), .Q(y[8]), .Q31());
SRLC32E sr9 (.D(d[9]), .A(a), .CLK(clk), .CE(ce), .Q(y[9]), .Q31());
SRLC32E sr10 (.D(d[10]), .A(a), .CLK(clk), .CE(ce), .Q(y[10]), .Q31());
SRLC32E sr11 (.D(d[11]), .A(a), .CLK(clk), .CE(ce), .Q(y[11]), .Q31());
SRLC32E sr12 (.D(d[12]), .A(a), .CLK(clk), .CE(ce), .Q(y[12]), .Q31());
SRLC32E sr13 (.D(d[13]), .A(a), .CLK(clk), .CE(ce), .Q(y[13]), .Q31());
SRLC32E sr14 (.D(d[14]), .A(a), .CLK(clk), .CE(ce), .Q(y[14]), .Q31());
SRLC32E sr15 (.D(d[15]), .A(a), .CLK(clk), .CE(ce), .Q(y[15]), .Q31());
SRLC32E sr16 (.D(d[16]), .A(a), .CLK(clk), .CE(ce), .Q(y[16]), .Q31());
SRLC32E sr17 (.D(d[17]), .A(a), .CLK(clk), .CE(ce), .Q(y[17]), .Q31());
endmodule

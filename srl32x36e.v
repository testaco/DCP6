//
//			32 word x 36 bit Adjustable-length Shift register
//
//				(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module srl32x36e(y,d,a,ce,clk);
    output [35:0] y;	// output selected by address
    input [35:0] d;	// input	word
	 input [4:0] a;	// address of output word
    input ce;			// enable input
    input clk;			// clock input
// 36 32-bit shift registers
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
SRLC32E sr18 (.D(d[18]), .A(a), .CLK(clk), .CE(ce), .Q(y[18]), .Q31());
SRLC32E sr19 (.D(d[19]), .A(a), .CLK(clk), .CE(ce), .Q(y[19]), .Q31());
SRLC32E sr20 (.D(d[20]), .A(a), .CLK(clk), .CE(ce), .Q(y[20]), .Q31());
SRLC32E sr21 (.D(d[21]), .A(a), .CLK(clk), .CE(ce), .Q(y[21]), .Q31());
SRLC32E sr22 (.D(d[22]), .A(a), .CLK(clk), .CE(ce), .Q(y[22]), .Q31());
SRLC32E sr23 (.D(d[23]), .A(a), .CLK(clk), .CE(ce), .Q(y[23]), .Q31());
SRLC32E sr24 (.D(d[24]), .A(a), .CLK(clk), .CE(ce), .Q(y[24]), .Q31());
SRLC32E sr25 (.D(d[25]), .A(a), .CLK(clk), .CE(ce), .Q(y[25]), .Q31());
SRLC32E sr26 (.D(d[26]), .A(a), .CLK(clk), .CE(ce), .Q(y[26]), .Q31());
SRLC32E sr27 (.D(d[27]), .A(a), .CLK(clk), .CE(ce), .Q(y[27]), .Q31());
SRLC32E sr28 (.D(d[28]), .A(a), .CLK(clk), .CE(ce), .Q(y[28]), .Q31());
SRLC32E sr29 (.D(d[29]), .A(a), .CLK(clk), .CE(ce), .Q(y[29]), .Q31());
SRLC32E sr30 (.D(d[30]), .A(a), .CLK(clk), .CE(ce), .Q(y[30]), .Q31());
SRLC32E sr31 (.D(d[31]), .A(a), .CLK(clk), .CE(ce), .Q(y[31]), .Q31());
SRLC32E sr32 (.D(d[32]), .A(a), .CLK(clk), .CE(ce), .Q(y[32]), .Q31());
SRLC32E sr33 (.D(d[33]), .A(a), .CLK(clk), .CE(ce), .Q(y[33]), .Q31());
SRLC32E sr34 (.D(d[34]), .A(a), .CLK(clk), .CE(ce), .Q(y[34]), .Q31());
SRLC32E sr35 (.D(d[35]), .A(a), .CLK(clk), .CE(ce), .Q(y[35]), .Q31());
endmodule

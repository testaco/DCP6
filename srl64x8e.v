//
//	srl64x8e - 64 stage by 8 bit shift register with addressable output
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	D is the input to the shift register and is clocked by CLK when CE is true.
// The output, Y, is slected by A. 
// 
module srl64x8e(y,d,a,ce,clk);
    output [7:0] y;	// output
    input [7:0] d;	// input
    input [5:0] a;	// address of register to output
    input ce;			// clock enable for input
    input clk;			// clock input
// 8 shift registers
SRL64E sr0 (.D(d[0]), .A(a), .CLK(clk), .CE(ce), .Q(y[0]));
SRL64E sr1 (.D(d[1]), .A(a), .CLK(clk), .CE(ce), .Q(y[1]));
SRL64E sr2 (.D(d[2]), .A(a), .CLK(clk), .CE(ce), .Q(y[2]));
SRL64E sr3 (.D(d[3]), .A(a), .CLK(clk), .CE(ce), .Q(y[3]));
SRL64E sr4 (.D(d[4]), .A(a), .CLK(clk), .CE(ce), .Q(y[4]));
SRL64E sr5 (.D(d[5]), .A(a), .CLK(clk), .CE(ce), .Q(y[5]));
SRL64E sr6 (.D(d[6]), .A(a), .CLK(clk), .CE(ce), .Q(y[6]));
SRL64E sr7 (.D(d[7]), .A(a), .CLK(clk), .CE(ce), .Q(y[7]));
endmodule

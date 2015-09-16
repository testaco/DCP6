//
//	srl16x6e - 16 stage by 6 bit shift register with addressable output
//
//					(C) Copyright 2004 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	D is the input to the shift register and is clocked by CLK when CE is true.
// The output, Y, is slected by A. 5 slices are used. 
// 
module srl16x6e(y,d,a,ce,clk);
    output [5:0] y;	// output
    input [5:0] d;	// input
    input [3:0] a;	// address of register to output
    input ce;			// clock enable for input
    input clk;			// clock input
// 16 shift registers
SRL16E sr0 (.D(d[0]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[0]));
SRL16E sr1 (.D(d[1]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[1]));
SRL16E sr2 (.D(d[2]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[2]));
SRL16E sr3 (.D(d[3]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[3]));
SRL16E sr4 (.D(d[4]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[4]));
SRL16E sr5 (.D(d[5]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[5]));
endmodule

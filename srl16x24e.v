//
//	srl16x25e - 16 stage by 24 bit shift register with addressable output
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
// The output, Y, is slected by A. 13 slices are used. 
// 
module srl16x24e(y,d,a,ce,clk);
    output [23:0] y;	// output
    input [23:0] d;	// input
    input [3:0] a;	// address of register to output
    input ce;			// clock enable for input
    input clk;			// clock input
// 32 shift registers
SRL16E sr0 (.D(d[0]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[0]));
SRL16E sr1 (.D(d[1]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[1]));
SRL16E sr2 (.D(d[2]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[2]));
SRL16E sr3 (.D(d[3]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[3]));
SRL16E sr4 (.D(d[4]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[4]));
SRL16E sr5 (.D(d[5]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[5]));
SRL16E sr6 (.D(d[6]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[6]));
SRL16E sr7 (.D(d[7]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[7]));
SRL16E sr8 (.D(d[8]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[8]));
SRL16E sr9 (.D(d[9]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[9]));
SRL16E sr10 (.D(d[10]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[10]));
SRL16E sr11 (.D(d[11]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[11]));
SRL16E sr12 (.D(d[12]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[12]));
SRL16E sr13 (.D(d[13]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[13]));
SRL16E sr14 (.D(d[14]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[14]));
SRL16E sr15 (.D(d[15]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[15]));
SRL16E sr16 (.D(d[16]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[16]));
SRL16E sr17 (.D(d[17]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[17]));
SRL16E sr18 (.D(d[18]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[18]));
SRL16E sr19 (.D(d[19]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[19]));
SRL16E sr20 (.D(d[20]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[20]));
SRL16E sr21 (.D(d[21]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[21]));
SRL16E sr22 (.D(d[22]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[22]));
SRL16E sr23 (.D(d[23]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .CLK(clk), .CE(ce), .Q(y[23]));
endmodule

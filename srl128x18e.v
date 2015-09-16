//
//	srl128x18e - 128 stage by 18 bit shift register with addressable output
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
module srl128x18e(y,d,a,ce,clk);
    output [17:0] y;	// output
    input [17:0] d;	// input
    input [6:0] a;	// address of register to output
    input ce;			// clock enable for input
    input clk;			// clock input
// 18 shift registers
SRL128E sr0 (.D(d[0]), .A(a), .CLK(clk), .CE(ce), .Q(y[0]));
SRL128E sr1 (.D(d[1]), .A(a), .CLK(clk), .CE(ce), .Q(y[1]));
SRL128E sr2 (.D(d[2]), .A(a), .CLK(clk), .CE(ce), .Q(y[2]));
SRL128E sr3 (.D(d[3]), .A(a), .CLK(clk), .CE(ce), .Q(y[3]));
SRL128E sr4 (.D(d[4]), .A(a), .CLK(clk), .CE(ce), .Q(y[4]));
SRL128E sr5 (.D(d[5]), .A(a), .CLK(clk), .CE(ce), .Q(y[5]));
SRL128E sr6 (.D(d[6]), .A(a), .CLK(clk), .CE(ce), .Q(y[6]));
SRL128E sr7 (.D(d[7]), .A(a), .CLK(clk), .CE(ce), .Q(y[7]));
SRL128E sr8 (.D(d[8]), .A(a), .CLK(clk), .CE(ce), .Q(y[8]));
SRL128E sr9 (.D(d[9]), .A(a), .CLK(clk), .CE(ce), .Q(y[9]));
SRL128E sr10 (.D(d[10]), .A(a), .CLK(clk), .CE(ce), .Q(y[10]));
SRL128E sr11 (.D(d[11]), .A(a), .CLK(clk), .CE(ce), .Q(y[11]));
SRL128E sr12 (.D(d[12]), .A(a), .CLK(clk), .CE(ce), .Q(y[12]));
SRL128E sr13 (.D(d[13]), .A(a), .CLK(clk), .CE(ce), .Q(y[13]));
SRL128E sr14 (.D(d[14]), .A(a), .CLK(clk), .CE(ce), .Q(y[14]));
SRL128E sr15 (.D(d[15]), .A(a), .CLK(clk), .CE(ce), .Q(y[15]));
SRL128E sr16 (.D(d[16]), .A(a), .CLK(clk), .CE(ce), .Q(y[16]));
SRL128E sr17 (.D(d[17]), .A(a), .CLK(clk), .CE(ce), .Q(y[17]));
endmodule

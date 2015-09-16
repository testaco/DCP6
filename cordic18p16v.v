//
//		cordic18p16v.v - 18-bit Input/16-bit Output Pipelined CORDIC Processing Engine
//
//					  	(C) Copyright 2010-2013 John B. Stephensen
// 
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements the CORDIC algorithm with 24-bit internal resolution. It is
// operated in vector mode for use in measuring the magnitude and phase of the input.
// Coarse rotation is used if the input phase is outside +/-90 degrees. Side effects
// during rotation multiply the accumulated X and Y values by a factor of 1.64676
// which is patially corrected with multiplication by 1.125 on the X output. X and Y
// are rotated until Y is zero. 18 micro-rotations are used for 16-bit accuracy.
// Coarse rotation, micro-rotation and correction takes 20 clock cycles. 
//
// 1371 LUT6s (9%) and 1244 registers are used. 276 MHz maximum clock rate (-3).
//
// History:
//		2013-2-21	created from cordic16p8
//		2013-10-5	modified for vector mode (was 1779 LUT, 1692 reg, 231 MHz)
//
module cordic18p16v(
    input [17:0] xi,yi,		// 18-bit rectangular input
	 input iv,					// load input data
    output [15:0] xo,		// 16-bit magnitude
	 output [15:0] zo,		// 16-bit phase
	 output ov,					// output data ready
    input clk					// master clock
    );
// internal signals
wire cmpx,cmpy;				// coarse rotation controls
wire [17:0] xx,yy;			// input coarse rotation complementors
reg [17:0] x0,y0;				// coarse rotation output
reg [23:0] z0;
reg [18:0] xs,ys;				// sign bits
wire [23:0] x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23;
wire [23:0] y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15,y16,y17,y18,y19,y20,y21,y22,y23;
wire [23:0] z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17,z18,z19,z20,z21,z22,z23;
reg [20:1] v;					// data valid delay
reg [23:0] xc;					// corrected X output
reg [23:8] zc;					// corrected Z output
// vector mode: exchange and invert X and Y inputs to move inputs into 1st and 4th quadrants
// Q X Y X0 Y0 Cor.
// 1 + +  X  Y  0
// 2 - +  Y -X +90
// 3 - - -Y  X -90
// 4 + -  X  Y  0
// true/complement logic inverts inputs when necessary
assign cmpx = xi[17] & ~yi[17];
assign cmpy = xi[17] & yi[17];
tc18a tcix (
	.D(xi),
	.CMP(cmpx),	// -90
	.Y(xx)
	);
tc18a tciy (
	.D(yi),
	.CMP(cmpy),	// +90
	.Y(yy)
	);
// save mode and sign bits for output correction
// swap X and Y axis when necessary
// Z input is zero
assign swap = xi[17];
always @ (posedge clk)
begin
	xs <= {xs[17:0],xi[17]};		// save signs
	ys <= {ys[17:0],yi[17]};
	x0 <= swap ? yy : xx;		// 0 or +/-90 rotation
	y0 <= swap ? xx : yy;
end
// vector mode drives Y towards zero by watching sign bit.
// inp add/sub mode
//  Y   X   Y   Z 
//  +  ADD SUB ADD
//  -  SUB ADD SUB
// X = X +/- Y/2^1
// Y = Y +/- X/2^1
// Z = Z +/- atan(1)
// maximum value of X and Y outputs are +/-1.6468 so add 1 MS guard bit and 5 LS guard bits
addsub24s accx1 (.A({x0[17],x0,5'b00000}), .B({y0[17],y0,5'b00000}), .Q(x1), .SUB(y0[17]), .CE(1'b1), 
	.CLK(clk), .RST(1'b0));
addsub24s accy1 (.A({y0[17],y0,5'b00000}), .B({x0[17],x0,5'b00000}), .Q(y1), .SUB(~y0[17]), .CE(1'b1), 
	.CLK(clk), .RST(1'b0));
addsub24s accz1 (.A(24'h000000), .B(24'h200000), .Q(z1), .SUB(y0[17]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx2 (.A(x1), .B({y1[23],y1[23:1]}), .Q(x2), .SUB(y1[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy2 (.A(y1), .B({x1[23],x1[23:1]}), .Q(y2), .SUB(~y1[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz2 (.A(z1), .B(24'h12E405), .Q(z2), .SUB(y1[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx3 (.A(x2), .B({y2[23],y2[23],y2[23:2]}), .Q(x3), .SUB(y2[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy3 (.A(y2), .B({x2[23],x2[23],x2[23:2]}), .Q(y3), .SUB(~y2[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz3 (.A(z2), .B(24'h09FB38), .Q(z3), .SUB(y2[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx4 (.A(x3), .B({y3[23],y3[23],y3[23],y3[23:3]}), .Q(x4), .SUB(y3[23]), .CE(1'b1), .CLK(clk), 
	.RST(1'b0));
addsub24s accy4 (.A(y3), .B({x3[23],x3[23],x3[23],x3[23:3]}), .Q(y4), .SUB(~y3[23]), .CE(1'b1), .CLK(clk), 
	.RST(1'b0));
addsub24s accz4 (.A(z3), .B(24'h051112), .Q(z4), .SUB(y3[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx5 (.A(x4), .B({y4[23],y4[23],y4[23],y4[23],y4[23:4]}), .Q(x5), .SUB(y4[23]), .CE(1'b1), 
	.CLK(clk), .RST(1'b0));
addsub24s accy5 (.A(y4), .B({x4[23],x4[23],x4[23],x4[23],x4[23:4]}), .Q(y5), .SUB(~y4[23]), .CE(1'b1), 
	.CLK(clk), .RST(1'b0));
addsub24s accz5 (.A(z4), .B(24'h028B0D), .Q(z5), .SUB(y4[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx6 (.A(x5), .B({y5[23],y5[23],y5[23],y5[23],y5[23],y5[23:5]}), .Q(x6), .SUB(y5[23]), .CE(1'b1), 
	.CLK(clk), .RST(1'b0));
addsub24s accy6 (.A(y5), .B({x5[23],x5[23],x5[23],x5[23],x5[23],x5[23:5]}), .Q(y6), .SUB(~y5[23]), .CE(1'b1), 
	.CLK(clk), .RST(1'b0));
addsub24s accz6 (.A(z5), .B(24'h0145D8), .Q(z6), .SUB(y5[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx7 (.A(x6), .B({y6[23],y6[23],y6[23],y6[23],y6[23],y6[23],y6[23:6]}), .Q(x7), .SUB(y6[23]), 
	.CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy7 (.A(y6), .B({x6[23],x6[23],x6[23],x6[23],x6[23],x6[23],x6[23:6]}), .Q(y7), .SUB(~y6[23]), 
	.CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz7 (.A(z6), .B(24'h00A2F6), .Q(z7), .SUB(y6[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx8 (.A(x7), .B({y7[23],y7[23],y7[23],y7[23],y7[23],y7[23],y7[23],y7[23:7]}), .Q(x8), 
	.SUB(y7[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy8 (.A(y7), .B({x7[23],x7[23],x7[23],x7[23],x7[23],x7[23],x7[23],x7[23:7]}), .Q(y8), 
	.SUB(~y7[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz8 (.A(z7), .B(24'h00517C), .Q(z8), .SUB(y7[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx9 (.A(x8), .B({y8[23],y8[23],y8[23],y8[23],y8[23],y8[23],y8[23],y8[23],y8[23:8]}), .Q(x9), 
	.SUB(y8[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy9 (.A(y8), .B({x8[23],x8[23],x8[23],x8[23],x8[23],x8[23],x8[23],x8[23],x8[23:8]}), .Q(y9), 
	.SUB(~y8[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz9 (.A(z8), .B(24'h0028BE), .Q(z9), .SUB(y8[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx10 (.A(x9), .B({y9[23],y9[23],y9[23],y9[23],y9[23],y9[23],y9[23],y9[23],y9[23],y9[23:9]}), 
	.Q(x10), .SUB(y9[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy10 (.A(y9), .B({x9[23],x9[23],x9[23],x9[23],x9[23],x9[23],x9[23],x9[23],x9[23],x9[23:9]}), 
	.Q(y10), .SUB(~y9[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz10 (.A(z9), .B(24'h00145F), .Q(z10), .SUB(y9[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx11 (.A(x10), .B({y10[23],y10[23],y10[23],y10[23],y10[23],y10[23],y10[23],y10[23],y10[23],y10[23],
	y10[23:10]}), .Q(x11), .SUB(y10[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy11 (.A(y10), .B({x10[23],x10[23],x10[23],x10[23],x10[23],x10[23],x10[23],x10[23],x10[23],x10[23],
	x10[23:10]}), .Q(y11), .SUB(~y10[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz11 (.A(z10), .B(24'h000A30), .Q(z11), .SUB(y10[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx12 (.A(x11), .B({y11[23],y11[23],y11[23],y11[23],y11[23],y11[23],y11[23],y11[23],y11[23],y11[23],
	y11[23],y11[23:11]}), .Q(x12), .SUB(y11[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy12 (.A(y11), .B({x11[23],x11[23],x11[23],x11[23],x11[23],x11[23],x11[23],x11[23],x11[23],x11[23],
	x11[23],x11[23:11]}), .Q(y12), .SUB(~y11[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz12 (.A(z11), .B(24'h000518), .Q(z12), .SUB(y11[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx13 (.A(x12), .B({y12[23],y12[23],y12[23],y12[23],y12[23],y12[23],y12[23],y12[23],y12[23],y12[23],
	y12[23],y12[23],y12[23:12]}), .Q(x13), .SUB(y12[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy13 (.A(y12), .B({x12[23],x12[23],x12[23],x12[23],x12[23],x12[23],x12[23],x12[23],x12[23],x12[23],
	x12[23],x12[23],x12[23:12]}), .Q(y13), .SUB(~y12[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz13 (.A(z12), .B(24'h00028C), .Q(z13), .SUB(y12[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx14 (.A(x13), .B({y13[23],y13[23],y13[23],y13[23],y13[23],y13[23],y13[23],y13[23],y13[23],y13[23],
	y13[23],y13[23],y13[23],y13[23:13]}), .Q(x14), .SUB(y13[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy14 (.A(y13), .B({x13[23],x13[23],x13[23],x13[23],x13[23],x13[23],x13[23],x13[23],x13[23],x13[23],
	x13[23],x13[23],x13[23],x13[23:13]}), .Q(y14), .SUB(~y13[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz14 (.A(z13), .B(24'h000146), .Q(z14), .SUB(y13[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx15 (.A(x14), .B({y14[23],y14[23],y14[23],y14[23],y14[23],y14[23],y14[23],y14[23],y14[23],y14[23],
	y14[23],y14[23],y14[23],y14[23],y14[23:14]}), .Q(x15), .SUB(y14[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accy15 (.A(y14), .B({x14[23],x14[23],x14[23],x14[23],x14[23],x14[23],x14[23],x14[23],x14[23],x14[23],
	x14[23],x14[23],x14[23],x14[23],x14[23:14]}), .Q(y15), .SUB(~y14[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accz15 (.A(z14), .B(24'h0000A3), .Q(z15), .SUB(y14[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx16 (.A(x15), .B({y15[23],y15[23],y15[23],y15[23],y15[23],y15[23],y15[23],y15[23],y15[23],y15[23],
	y15[23],y15[23],y15[23],y15[23],y15[23],y15[23:15]}), .Q(x16), .SUB(y15[23]), .CE(1'b1), .CLK(clk), 
	.RST(1'b0));
addsub24s accy16 (.A(y15), .B({x15[23],x15[23],x15[23],x15[23],x15[23],x15[23],x15[23],x15[23],x15[23],x15[23],
	x15[23],x15[23],x15[23],x15[23],x15[23],x15[23:15]}), .Q(y16), .SUB(~y15[23]), .CE(1'b1), .CLK(clk), 
	.RST(1'b0));
addsub24s accz16 (.A(z15), .B(24'h000051), .Q(z16), .SUB(y15[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx17 (.A(x16), .B({y16[23],y16[23],y16[23],y16[23],y16[23],y16[23],y16[23],y16[23],y16[23],y16[23],
	y16[23],y16[23],y16[23],y16[23],y16[23],y16[23],y16[23:16]}), .Q(x17), .SUB(y16[23]), .CE(1'b1), .CLK(clk), 
	.RST(1'b0));
addsub24s accy17 (.A(y16), .B({x16[23],x16[23],x16[23],x16[23],x16[23],x16[23],x16[23],x16[23],x16[23],x16[23],
	x16[23],x16[23],x16[23],x16[23],x16[23],x16[23],x16[23:16]}), .Q(y17), .SUB(~y16[23]), .CE(1'b1), .CLK(clk), 
	.RST(1'b0));
addsub24s accz17 (.A(z16), .B(24'h000029), .Q(z17), .SUB(y16[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub24s accx18 (.A(x17), .B({y17[23],y17[23],y17[23],y17[23],y17[23],y17[23],y17[23],y17[23],y17[23],y17[23],
	y17[23],y17[23],y17[23],y17[23],y17[23],y17[23],y17[23],y17[23:17]}), .Q(x18), .SUB(y17[23]), .CE(1'b1), 
	.CLK(clk), .RST(1'b0));
//addsub24s accy18 (.A(y17), .B({x17[23],x17[23],x17[23],x17[23],x17[23],x17[23],x17[23],x17[23],x17[23],x17[23],
//	x17[23],x17[23],x17[23],x17[23],x17[23],x17[23],x17[23],x17[23:17]}), .Q(y18), .SUB(~y17[23]), .CE(1'b1), 
//	.CLK(clk), .RST(1'b0));
addsub24s accz18 (.A(z17), .B(24'h000014), .Q(z18), .SUB(y17[23]), .CE(1'b1), .CLK(clk), .RST(1'b0));
// multiply magnitude (X) by 1.125/4 to partially correct magnitude growth then truncate to 16 bits
// correct phase (Z) output with +/-Pi/2 adjustment then trim to 16 bits and round up
// Q X Y X0 Y0 Cor.
// 1 + +  X  Y  00
// 2 - +  Y -X  01 (+90)
// 3 - - -Y  X  11 (-90)
// 4 + -  X  Y  00
always @ (posedge clk)
begin
	xc <= x18 + {x18[23],x18[23],x18[23],x18[23:3]};
	zc <= {(z18[23:22] + {(xs[18]&ys[18]),xs[18]}),z18[21:8]} + z18[7];
	v <= {v[19:1],iv};
end
// connect outputs
assign xo = xc[22:7];
assign zo = zc[23:8];
assign ov = v[20];		// output ready 20 clock cycles after input
endmodule

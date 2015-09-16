//
//		cordic16p8.v - 16-bit Input/8-bit Output Pipelined CORDIC Processing Engine
//
//					  	(C) Copyright 2010 John B. Stephensen
// 
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements the CORDIC algorithm with 24-bit internal resolution. The X
// and Y inputs are rotated into the first and fourth quadrants before microrotations.
// Side effects during rotation multiply the accumulated X and Y values by a factor of
// 1.64676 which is corrected with multipliers on the X and Y outputs. The accumulated
// Z value is also corrected by a factor of +/-Pi radians using a 2-bit adder on the
// output.
//
// The CORDIC engine is operated in vector mode for polar to rectangular conversion.
// Vector mode rotates X and Y until Y is zero. 8 rotations are used for 7-bit accuracy.
// Accuracy will decrease when both the X and Y inputs are less than 1/64 of full scale.
// Rotation and correction takes 10 clock cycles. 
//
// Truncate angle: 409 LUTs, 357 registers and 1 DSP48A1 are used. 199 MHz maximum clock rate.
// Round angle: 418 LUTs, 358 registers and 1 DSP48A1 are used. 199 MHz maximum clock rate.
//
// History:
//		12-27-10	created from cordic16 (serial)
//
module cordic16p8(
    input [15:0] xi,yi,	// 16-bit X and Y inputs
	 input iv,				// load input data
    output [7:0] xo,zo,	// 8-bit X and Z outputs
	 output ov,				// output data ready
    input clk				// master clock
    );
// internal signals
wire cmpx,cmpy,swap;						// coarse rotation controls
wire [15:0] xx,yy;						// input coarse rotation complementors
reg [15:0] x0,y0;							// coarse rotation output
reg [8:0] xs,ys;							// sign bits
wire [15:0] x1,x2,x3,x4,x5,x6,x7,x8;// adder/subtractor I/O
wire [15:0] y1,y2,y3,y4,y5,y6,y7,y8;
wire [11:0] z1,z2,z3,z4,z5,z6,z7,z8;
wire s0,s1,s2,s3,s4,s5,s6,s7;			// 0 = add, 1 = subtract
reg [10:1] v;								// data valid delay
wire [35:0] xc,yc;						// corrected X and Y outputs
reg [7:0] zc;								// corrected phase output
// vector mode: exchange and invert X and Y inputs to move inputs into 1st and 4th quadrants
// Q X Y X0 Y0 Cor.
// 1 + +  X  Y  0
// 2 - +  Y -X +90
// 3 - - -Y  X -90
// 4 + -  X  Y  0
// true/complement logic inverts inputs when necessary
assign cmpx = xi[15] & ~yi[15];
assign cmpy = xi[15] & yi[15];
tc16a tcix (
	.D(xi),
	.CMP(cmpx),	// -90
	.Y(xx)
	);
tc16a tciy (
	.D(yi),
	.CMP(cmpy),	// +90
	.Y(yy)
	);
// save mode and sign bits for output correction
// swap X and Y axis when necessary
// Z input is zero
assign swap = xi[15];
always @ (posedge clk)
begin
	xs <= {xs[7:0],xi[15]};		// save signs
	ys <= {ys[7:0],yi[15]};
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
addsub16s accx1 (.A(x0), .B(y0), .Q(x1), .SUB(y0[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accy1 (.A(y0), .B(x0), .Q(y1), .SUB(~y0[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz1 (.A(12'h000), .B(12'h200), .Q(z1), .SUB(y0[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accx2 (.A(x1), .B({y1[15],y1[15:1]}), .Q(x2), .SUB(y1[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accy2 (.A(y1), .B({x1[15],x1[15:1]}), .Q(y2), .SUB(~y1[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz2 (.A(z1), .B(12'h12E), .Q(z2), .SUB(y1[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accx3 (.A(x2), .B({y2[15],y2[15],y2[15:2]}), .Q(x3), .SUB(y2[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accy3 (.A(y2), .B({x2[15],x2[15],x2[15:2]}), .Q(y3), .SUB(~y2[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz3 (.A(z2), .B(12'h0A0), .Q(z3), .SUB(y2[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accx4 (.A(x3), .B({y3[15],y3[15],y3[15],y3[15:3]}), .Q(x4), .SUB(y3[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accy4 (.A(y3), .B({x3[15],x3[15],x3[15],x3[15:3]}), .Q(y4), .SUB(~y3[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz4 (.A(z3), .B(12'h051), .Q(z4), .SUB(y3[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accx5 (.A(x4), .B({y4[15],y4[15],y4[15],y4[15],y4[15:4]}), .Q(x5), .SUB(y4[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accy5 (.A(y4), .B({x4[15],x4[15],x4[15],x4[15],x4[15:4]}), .Q(y5), .SUB(~y4[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz5 (.A(z4), .B(12'h029), .Q(z5), .SUB(y4[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accx6 (.A(x5), .B({y5[15],y5[15],y5[15],y5[15],y5[15],y5[15:5]}), .Q(x6), .SUB(y5[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accy6 (.A(y5), .B({x5[15],x5[15],x5[15],x5[15],x5[15],x5[15:5]}), .Q(y6), .SUB(~y5[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz6 (.A(z5), .B(12'h014), .Q(z6), .SUB(y5[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accx7 (.A(x6), .B({y6[15],y6[15],y6[15],y6[15],y6[15],y6[15],y6[15:6]}), .Q(x7), .SUB(y6[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accy7 (.A(y6), .B({x6[15],x6[15],x6[15],x6[15],x6[15],x6[15],x6[15:6]}), .Q(y7), .SUB(~y6[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz7 (.A(z6), .B(12'h00A), .Q(z7), .SUB(y6[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub16s accx8 (.A(x7), .B({y7[15],y7[15],y7[15],y7[15],y7[15],y7[15],y7[15],y7[15:7]}), .Q(x8), .SUB(y7[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
//addsub16s accy8 (.A(y7), .B({x7[15],x7[15],x7[15],x7[15],x7[15],x7[15],x7[15],x7[15:7]}), .Q(y8), .SUB(~y7[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
addsub12s accz8 (.A(z7), .B(12'h005), .Q(z8), .SUB(y7[15]), .CE(1'b1), .CLK(clk), .RST(1'b0));
// correct magnitude growth in CORDIC algorithm
// multiply by 0.6072530 = 79593.86/131072 = 136E9.D/40000
MULT18X18SIO #(
	.AREG(0),		// 1 clock delay
	.BREG(0),
	.PREG(1)
	) xadj (
	.A({x8,2'b00}),// 18-bit signed input
	.B(18'h136E7),	// must be less than 1
	.BCIN(),
	.BCOUT(),
	.P(xc),			// 36-bit output
	.CEA(1'b1),
	.CEB(1'b1),
	.CEP(1'b1),
	.CLK(clk),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTP(1'b0)
	);
// trim X output to 8 bits and correct phase output with +/-Pi/2 adjustment
// Q X Y X0 Y0 Cor.
// 1 + +  X  Y  00
// 2 - +  Y -X  01 (+90)
// 3 - - -Y  X  11 (-90)
// 4 + -  X  Y  00
// then trim to 8 bits and round up
always @ (posedge clk)
begin
	zc <= {(z8[11:10] + {(xs[8]&ys[8]),xs[8]}),z8[9:4]} + z8[3];
	v <= {v[9:1],iv};
end
// connect outputs - 8-bit X-axis/magnitude and phase angle outputs
// Corrected X output drops one bit due to multiplication by 0.6072530 and
// maximum value of 1.4142 * 1.6468 = 2.3289 and one bit due to replicated sign on
// multiplier output. A third bit is dropped by assuming the output is positive.
// Two more bits are dropped by assuming that all subcarriers are less than -12 dBFS.
// The output saturates at 255 if the subcarrier is greater than -12 dBFS.
assign xo = (|xc[35:32]) ? 8'hFF : xc[31:24];
assign zo = zc;
assign ov = v[10];		// output ready 10 clock cycles after TC
endmodule

//
//		cordic16s16.v - 16-bit Input/16-bit Output Serial CORDIC Processing Engine
//
//					  	(C) Copyright 2009-2013 John B. Stephensen
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
// The CORDIC engine may be operated in vector or rotation mode for polar to rectangular
// or rectangular to polar conversion, respectively. The selection is made using the
// rotation input and must be maintained throughout the conversion process. Vector mode
// rotates X and Y until Y is zero. Rotate mode rotates X and Y until Z is zero. 20
// rotations are used for 16-bit accuracy. Accuracy will decrease when both the X and Y
// inputs are less than 1/4 of full scale. Accuracy is 14 bits at -48 dBFS, 11-bits at
// -48 dBFS and 7 bits at -72 dBFS. 20 clock cycles are required for each conversion.
//
// S6: 439 LUTs and 288 registers are used. 107 MHz maximum clock rate.
//
// Normal Warnings:
//		Signal <z0_14> is unconnected.
//		Signals <xr_0>, <xr_1>, <xr_2>, <xr_3>, <yr_0>, <yr_1>, <yr_2> & <yr_3> are unconnected.
//
// History:
//		4-22-09	moved input left by 1 bit as only two X and Y overflow bits are needed.
//		4-23-09	altered coarse rotation logic and shrunk correction factor to prevent overflow
//		4-24-09	use input coarse rotation for rotate mode (mi=1)
//		5-18-10	18->16-bit X and Y inputs (was 232 slices)
//		8-18-11	use serial multipliers to correct magnitude growth (was 212 slices and 2 mult.)
//		11-7-11	use 24-bit acc. and 20 iterations for reduced distortion (was 353 LUT 231 reg 118 MHz)
//		11-16-11	use 22x18=22 bit multiplier and round 20 to 16 bits (was 376 LUT 239 reg 107 MHz)
//		2-24-13	change angle accumulator and ROM to 24Q23 format, adding 1 bit of precision
//
module cordic16s16(
    input [15:0] xi,		// 16-bit X input
    input [15:0] yi,		// 16-bit Y input
    input [15:0] zi,		// 16-bit Z input
	 input mi,				// 0 = vector mode, 1 = rotation mode
	 input load,			// load X, Y and Z input data
    output [15:0] xo,	// 16-bit X output
    output [15:0] yo,	// 16-bit Y output
    output [15:0] zo,	// 16-bit Z output
	 output mo,				// 0 = vector mode, 1 = rotation mode
	 output rdy,			// X, Y and Z output data ready
    input clk,				// master clock
    input rst				// reset X, Y and Z accumulators
    );
// internal signals
wire cmpx,cmpy,swap;	// coarse rotation controls
reg start,rotate;		// start interpolation and vector/rotate mode
wire [15:0] xx,yy;	// input coarse rotation complementors
reg [15:0] x0,y0;		// coarse rotation output
reg [15:0] z0;			// angle
reg xs,ys;				// sign bits
wire [23:0] xa,xb,x,ya,yb,y,za,zb,z;// adder/subtractor I/O
wire subxz;				// 0 = add, 1 = subtract
reg [4:0] i;			// iteration number
wire ce,nz,tc;			// counter enable, non-zero and terminal count
reg v;					// microrotaion engine data valid signal
wire vc;					// correction multiplier data valid signal
wire [21:0] xc,yc;	// corrected X and Y outputs
reg [15:0] zc;			// corrected phase output (rounded up)
reg [19:0] xr,yr;		// rounded X and Y outputs
reg vr;					// rounded output valid signal
// vector mode: exchange and invert X and Y inputs to move inputs into 1st and 4th quadrants
// Q X Y X0 Y0 Cor.
// 1 + +  X  Y  0
// 2 - +  Y -X +90
// 3 - - -Y  X -90
// 4 + -  X  Y  0
// rotate mode: exchange and invert X and Y inputs to implement first +/-90 degrees of rotation
//   Range  Xo Yo Cor. z15 z14
// +90/+180  Y -X +90   1   0
// -90/-180 -Y  X -90   0   1
// true/complement logic inverts inputs when necessary
assign cmpx = mi ? zi[15] & ~zi[14] : xi[15] & ~yi[15];
assign cmpy = mi ? zi[14] & ~zi[15] : xi[15] & yi[15];
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
// delay Z input and start signal
assign swap = mi ? zi[15] ^ zi[14] : xi[15];
always @ (posedge clk)
begin
	if (load) xs <= xi[15];				// save signs
	if (load) ys <= yi[15];
	if (load) x0 <= swap ? yy : xx;	// 0 or +/-90 rotation
	if (load) y0 <= swap ? xx : yy;
	if (load) z0 <= zi;					// delay
	if (load) rotate <= mi;
	start <= load;
end
// Output accuracy is 16 bits.
// The accumulators have 3 overflow bits and 5 underflow bits.
// This results in increased accuracy at low signal levels.
// X = X +/- Y/2^1
assign xa = start ? {x0[15],x0[15],x0[15],x0,5'b00000} : x;
shift24x24 shiftyz (
	.D(ya),
	.Y(xb),
	.S(i)
	);
addsub24s accx (
	.A(xa),
	.B(xb),
	.Q(x),
	.SUB(subxz),
	.CE(ce),
	.CLK(clk),
	.RST(rst)
	);
// Y = Y +/- X/2^1
assign ya = start ? {y0[15],y0[15],y0[15],y0,5'b00000} : y;
shift24x24 shiftzy (
	.D(xa),
	.Y(yb),
	.S(i)
	);
addsub24s accy (
	.A(ya),
	.B(yb),
	.Q(y),
	.SUB(~subxz),
	.CE(ce),
	.CLK(clk),
	.RST(rst)
	);
// Z = Z +/- atan(1)
// drop bit 14 so input is between +Pi/2 and -Pi/2
assign za = start ? {z0[15],z0[15],z0[13:0],8'h00} : z;
addsub24s accz (
	.A(za),
	.B(zb),			// add/subtract this amount
	.Q(z),			// accumulator output
	.SUB(subxz),	// 0 = add, 1 = subtract
	.CE(ce),			// clock enable
	.CLK(clk),
	.RST(rst)
	);
// ROM containing arctan(2^-i)/360 * 2^24
rom32x24cordic rom (
	.a(i),
	.spo(zb)
	);
// iteration counter counts up until terminal count reached
always @ (posedge clk)
begin
	if (rst) i <= 0;
	else if (ce) i <= i + 1'b1;
	v <= tc;
end
assign ce = start | nz;	// enable clock when loading or not zero
assign nz = |i;			// counter not zero
assign tc = (i == 19);	// terminal count
// select rotation (0) or vector (1) mode:
// rotate mode drives Z towards zero by watching sign bit.
// vector mode drives Y towards zero by watching sign bit.
// vec accumulator rot
//  Y   X   Y   Z   Z
//  +  ADD SUB ADD  -
//  -  SUB ADD SUB  +
// Vector mode (0) is used for rectangular to polar coordinate conversion.
// Rotate mode (1) is used to rotate the X and Y inputs for frequency
// translation or for polar to rectangular conversion.
assign subxz = rotate ? ~za[23] : ya[23];
// correct magnitude growth in CORDIC algorithm
// multiply by 0.6072530 = 79593.86/131072 = 136E9.D/40000
mul22c17u22c xyadj (
	.dix(x[22:1]),	// 22-bit signed CORDIC outputs
	.diy(y[22:1]),
	.diz(17'h136E9),
	.iv(v),
	.dox(xc),
	.doy(yc),
	.ov(vc),
	.clk(clk)
	);
// round outputs from 20 bits to 16 bits using unbiased rounding
// add 7 if negative or 8 if positive and drop bottom 4 bits of sum
always @ (posedge clk)
begin
	if (vc) xr <= xc[19:0] + {16'h0000,~xc[21],xc[21],xc[21],xc[21]};
	if (vc) yr <= yc[19:0] + {16'h0000,~yc[21],yc[21],yc[21],yc[21]};
	vr <= vc;
end
// correct phase output with +/-Pi/2 adjustment, drop bottom 8 bits and round up
// Q X Y X0 Y0 Cor.
// 1 + +  X  Y  00
// 2 - +  Y -X  01 (+90)
// 3 - - -Y  X  11 (-90)
// 4 + -  X  Y  00
always @ (posedge clk) if (v) zc <= {(z[23:22] + (rotate ? 2'b00 : {(xs&ys),xs})),z[21:8]} + z[7];
// connect outputs - 16-bit X-axis/magnitude, Y-axis and phase angle outputs
// Corrected X and Y outputs drop one bit due to multiplication by 0.6072530 and
// maximum value of 1.4142 * 1.6468 = 2.3289 and one bit due to replicated sign on
// multiplier output. A third bit may be dropped if inputs stay in the unit circle.
assign xo = xr[19:4];
assign yo = yr[19:4];
assign zo = zc;
assign mo = rotate;
assign rdy = vr;
endmodule

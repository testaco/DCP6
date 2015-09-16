//
//						logmul20s16a.v - Lograthimic multiplier
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This multiplier uses a shift register to adjust the 20-bit input signal by 0 to 90 dB in
// 6 dB steps. Fine amplitude control is linear, using a serial multiplier with 12 bits of
// precision, to keep amplitude modulation below -78 dBc at the 16-bit output. The gain
// control input contains a binary exponent in the upper 4 bits and a mantissa in the lower
// 12 bits. The lower 12 bits vary the gain of the multiplier from 0.5 to 0.99975. The input
// to output delay is 15-30 clocks.
//
// 146 LUT6 and 198 registers used. The maximum clock frequency is 225 MHz. 
//
// History:
//		2010-4-24	rewrite logmul20p16 for serial shift and multiply
//		2010-12-8	fix truncation warning for Spartan-6 by specifying length of zeroes and ones
//		2013-11-20	modify to save shifted signal to allow 16 clocks between samples
//
module logmul20s16a(
    input [19:0] dix,diy,	// data input
	 input iv,
    output [15:0] dox,doy,	// data output
	 output ov,
    input clk,					// master clock
	 input rst,					// master reset
    input [15:0] gain		// gain set
	 );
// internal busses
reg [19:0] srx,sry;	// shift registers
reg [15:0] sdx,sdy;	// shifted X and Y-axis samples
wire sx,sy;				// input sign
reg [28:0] ax,ay;		// accumulators for multiplication
reg [15:0] g;			// gain
reg [12:0] m;			// multiplier shift register
wire add;				// add to product
wire lsd;				// load shift data registers
reg [15:0] dx,dy;		// data output registers
reg satsrx,satsry;	// shift saturated
reg satx,saty;			// output saturated
reg [14:0] v;			// output valid delay (multiplier plus output register)
// shift inputs by gain exponent bits then multiply by adding top 16 bits of
// shift registers to shifted accumulator once for each 1 in gain mantissa
always @ (posedge clk)
begin
	if (iv) srx[19] <= dix[19];	// latch sign
	srx[18:0] <= iv ? dix[18:0] : {srx[17:0],1'b0};	// shift rest
	if (iv) sry[19] <= diy[19];	// latch sign
	sry[18:0] <= iv ? diy[18:0] : {sry[17:0],1'b0};	// shift rest
	if (iv) satsrx <= 0;	// reset when new inputs loaded into shift registers
	else satsrx <= (srx[19]^srx[18])|satsrx;	// detect saturation of X
	if (iv) satsry <= 0;	// reset when new inputs loaded into shift registers
	else satsry <= (sry[19]^sry[18])|satsry;	// detect saturation of Y
	if (lsd) sdx <= srx[19:4];	// latch shifted data
	if (lsd) sdy <= sry[19:4];
	if (lsd) satx <= satsrx;	// latch saturation flags
	if (lsd) saty <= satsry;
	if (iv) g <= gain;			// save gain in case it changes after IV
	if (rst) m <= 0;
	else m <= lsd ? {1'b1,g[11:0]} : {m[11:0],1'b0};	// load or shift multiplier
	if (lsd) ax <= 0;
	else ax <= {ax[27:0],1'b0} + (add ? {sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,sdx} : 29'd0);
	if (lsd) ay <= 0;
	else ay <= {ay[27:0],1'b0} + (add ? {sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sdy} : 29'd0);
	if (v[13]) dx <= (satx|(ax[27]^ax[28])) ? {sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,1'b1} : ax[27:12];
	if (v[13]) dy <= (saty|(ay[27]^ay[28])) ? {sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,1'b1} : ay[27:12];
end
assign sx = sdx[15];	// shifted data sign bits
assign sy = sdy[15];
assign add = m[12];	// MSB of shifted multiplier is add signal
// delay iv by shift count to trigger shifted data latch
SRL16E vd (
	.D(iv),
	.A0(g[12]), .A1(g[13]), .A2(g[14]), .A3(g[15]),
	.CLK(clk), .CE(1'b1),
	.Q(lsd)
	);
// delay 15 more clock cycles for multiplier and output register delays
always @ (posedge clk)
begin
	v <= {v[13:0],lsd};
end
// connect output port
assign dox = dx;
assign doy = dy;
assign ov = v[14];
endmodule

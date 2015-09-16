//
//						logmul20s16.v - Lograthimic multiplier
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This multiplier uses a shift register to adjust the 20-bit input signal by 0 to 90 dB
// in 6 dB steps. Fine amplitude control is linear, using a serial multiplier with 12 bits
// of precision, to keep amplitude modulation below -78 dBc at the 16-bit output. The gain
// control input contains a binary exponent in the upper 4 bits and a mantissa in the lower
// 12 bits. The lower 12 bits vary the gain of the multiplier from 0.5 to 0.99975.
//
// The maximum clock frequency is 187 MHz, the delay is 15-30 clocks and 103 slices are used. 
//
// History:
//		4-24-10	rewrite logmul20p16 for serial shift and multiply
//		12-8-10	fixed truncation warning for Spartan-6 by specifying length of zeroes and ones
//
module logmul20s16(dix,diy,iv,dox,doy,ov,clk,rst,gain);
    input [19:0] dix,diy;	// data input
	 input iv;
    output [15:0] dox,doy;	// data output
	 output ov;
    input clk;					// master clock
	 input rst;					// master reset
    input [15:0] gain;		// gain set
// internal busses
reg [19:0] srx,sry;	// shift registers
reg [3:0] sc;			// shift count
wire shift;				// shift enable
reg [28:0] ax,ay;		// accumulators for multiplication
reg [11:0] gm;			// gain mantissa
reg [12:0] m;			// multiplier shift register
wire add;				// add to product
wire load;				// load multiplier
reg [15:0] dx,dy;		// data output registers
reg satx,saty;			// output saturated
wire sx,sy;				// input sign
reg [14:0] v;			// output valid delay (multiplier plus output register)
// shift inputs by gain exponent bits then multiply by adding top 16 bits of
// shift registers to shifted accumulator once for each 1 in gain mantissa
always @ (posedge clk)
begin
	if (iv) srx[19] <= dix[19];		// latch sign
	if (iv|shift) srx[18:0] <= iv ? dix[18:0] : {srx[17:0],1'b0};	// shift rest
	if (iv) sry[19] <= diy[19];		// latch sign
	if (iv|shift) sry[18:0] <= iv ? diy[18:0] : {sry[17:0],1'b0};	// shift rest
	if (rst) sc <= 0;
	else if (iv) sc <= gain[15:12];	// load counter when shift registers loaded
	else if (shift) sc <= sc - 4'h1;	// then count down until zero
	if (rst) ax <= 0;
	else ax <= {ax[27:0],1'b0} + (add ? {sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,sx,srx[19:4]} : 29'd0);
	if (rst) ay <= 0;
	else ay <= {ay[27:0],1'b0} + (add ? {sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sy,sry[19:4]} : 29'd0);
	if (iv) gm <= gain[11:0];	// save gain mantissa in case it changes after IV
	if (rst) m <= 0;
	else m <= load ? {1'b1,gm} : {m[11:0],1'b0};	// load or shift multiplier
	if (iv) satx <= 0;	// reset when new inputs loaded into shift registers
	else if (shift) satx <= (srx[19]^srx[18])|satx;	// detect saturation of X or Y
	if (iv) saty <= 0;	// reset when new inputs loaded into shift registers
	else if (shift) saty <= (sry[19]^sry[18])|saty;	// detect saturation of X or Y
	if (v[13]) dx <= (satx|(ax[27]^ax[28])) ? {sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,~sx,1'b1} : ax[27:12];
	if (v[13]) dy <= (saty|(ay[27]^ay[28])) ? {sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,~sy,1'b1} : ay[27:12];
end
assign sx = srx[19];
assign sy = sry[19];
assign shift = |sc;	// shift when counter non-zero
assign add = m[12];	// MSB of shifted multiplier is add signal
// delay iv by shift count to trigger multiplier
SRL16E vd (
	.D(iv),
	.A0(gain[12]), .A1(gain[13]), .A2(gain[14]), .A3(gain[15]),
	.CLK(clk), .CE(1'b1),
	.Q(load)
	);
// delay 14 more clock cycles for multiplier and output register delays
always @ (posedge clk)
begin
	v <= {v[13:0],load};
end
// connect output port
assign dox = dx;
assign doy = dy;
assign ov = v[14];
endmodule

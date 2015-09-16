//
//							noiseblanker1.v - Noise Blanker
//
//					(C) Copyright 2009-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module processes pairs of 18-bit samples and zeroes both samples if the
// magnitude is larger than a 12-bit threshold. There is a 6 clock cycle delay
// and the output is latched. Speed is limited by the peak detector.
// 
// 129 LUT6s and 167 registers are used. The maximum clock rate is 228 MHz.
//
// History:
//		2013-3-29	create from noiseblanker.v (serial)
//
module noiseblanker1(
    input [17:0] dix,diy,	// data input
    input iv,					// input valid
    output [17:0] dox,doy,	// data output
    output ov,					// output valid
    input clk,					// sample clock
	 input [11:0] limit,		// magnitude limit before blanking
	 output [11:0] peak,		// peak value of input
    input pkrst				// reset peak value
    );
// internal signals
wire [11:0] mag;			// magnitude of upper 12 bits of input
wire mv;
reg [11:0] max;			// maximum magnitude
wire [12:0] ldif,mdif;	// fast comparators
wire pkdet;
reg [17:0] xi,yi;			// sample delay
reg blank;					// blanking signal
reg bv;						// blanking signal valid
reg [17:0] xo,yo;			// output register
reg dv;						// output data valid
// get magnitude of signal - 4 clock cycles
mag12 magdet (
	.x(dix[17:6]),	// signal
	.y(diy[17:6]),
	.iv(iv),			// signal valid
	.m(mag),			// magnitude of signal
	.ov(mv),			// magnitude valid
	.clk(clk)
	);
// detect noise pulses by comparing with threshold
// then zero samples that exceed limit
always @ (posedge clk)
begin
	if (iv) xi <= dix;	// save input
	if (iv) yi <= diy;
	blank <= ldif[12];	// detect noise pulse
	bv <= mv;
	if (bv) xo <= blank ? 18'h00000 : xi;	// blank or not
	if (bv) yo <= blank ? 18'h00000 : yi;
	dv <= bv;
	if (pkrst) max <= 0;
	else if (pkdet) max <= mag;	// save maximum
end
assign ldif = limit - mag;	// sign bit set if mag > limit
assign mdif = max - mag;	// sign bit set if mag > max
assign pkdet = mdif[12];
// connect outputs
assign dox = xo;
assign doy = yo;
assign ov = dv;
assign peak = max;
endmodule

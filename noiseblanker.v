//
//							noiseblanker.v - Noise Blanker
//
//						(C) Copyright 2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module processes pairs of samples and zeroes both samples if one sample
// is larger than a preset threshold. Samples arrive on DIXY and leave via DOXY.
// Samples are clocked by DCLK with the X sample present when SCLK = 1 and the
// Y sample present when SCLK = 0; Blanking is accomplished in 2 SCLK cycles.
// Note that four 18-bit registers must be instantiated to prevent optimization
// from altering timing.
// 
// 33 LUT6s and 36 registers are used. The maximum clock rate is 331 MHz.
//
// Normal Warnings:
//		Inputs <cin<15>> and <cin<6:0>> are never used.
//
// History:
//		12-9-11	separate clock and reset for config. info. (31 LUT, 57 reg.)
//		3-27-12	use IQ instead of SCLK (was 37 LUT, 51 reg.)
//		3-7-13	remove configuration register (was 33 LUT, 44 reg)
//
module noiseblanker(
    input [17:0] dixy,	// data input (X when SCLK = 1, Y when SCLK = 0)
    input iv,				// input valid
    output [17:0] doxy,	// data output (X when SCLK = 1, Y when SCLK = 0)
    output ov,				// output valid
    input iq,				// 0 = SCLK rising edge, 1 = SCLK falling edge
    input clk,				// double-rate sample clock
    input rst,				// master reset
	 input [7:0] limit	// amplitude limit before blanking
    );
// internal signals
wire [7:0] mag;					// magnitude of upper 9 bits of input
reg [3:1] v;						// delayed sample valid flags
reg b1,b2,b3,b4;					// greater than limit
reg [17:0] s0,s1,s2,s3,s4,s5;	// sample delay
// get absolute value of signal
tc8s absv (
	.D(dixy[16:9]),	// signal
	.CMP(dixy[17]),	// sign bit
	.Q(mag),				// magnitude of signal
	.CLK(clk),
	.CE(iv),				// sample when input valid
	.SCLR(rst)
	);
// detect noise pulses by comparing with threshold
always @ (posedge clk)
begin
	b1 <= (mag > limit);			// check limit
	b2 <= b1;						// delay result
	b3 <= b1 | b2;					// stretch result 2 clock cycles
	if (iq & v[1]) b4 <= b3;	// blank for 2 clocks if X or Y > threshold
	s0 <= dixy;						// delay data and blank last stage
	s1 <= s0;
	s2 <= s1;
	s3 <= s2;
	s4 <= s3;
	if (b4) s5 <= 0;
	else s5 <= s4;
	if (~iq) v <= {v[2:1],iv};	// delay data valid (posedge sclk)
end
// connect outputs
assign doxy = s5;
assign ov = v[3];
endmodule

//
//						agcclip.v - AGC and Clipper Module
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module contains the AGC and clipper for a transceiver. The AGC converts from 20-bit X
// and Y-axis receive inputs to 16-bit X and Y-axis outputs. The clipper may be used to reduce
// the peak to average power ratio (PAPR) of the transmitted signal by changing gain with input
// magnitude. All functions are configured by a set of 4 output ports. 
//
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |    Attack     |    Release    |        Output Setpoint        | AGC control
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  5 |           Hang Time           |         Hang Setpoint         | AGC hang time config.
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  6 |                               |           Max. Gain           | AGC manual gain
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 7 |                               |  Integer Gain |Fractional Gain| Comp. Gain (0-16)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// The current AGC gain and the resampler overflow status bit may be read via 2 input ports.
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |    Exponent   |                   Mantissa                    |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// logmul16s16: 470 LUT6s and 420 registers are used. The maximum clock rate is 123 MHz.
// logmul16s16a: 464 LUT6s and 454 registers are used. The maximum clock rate is 123 MHz.
//
// Normal Warnings:
//		Input port xmt is never used (here for compatibility with agcrsmplclip.v).
//
// History:
//	2011-5-15	use 16-bit resampler and compressor (520 slices)
//	2011-8-25	add 2nd transmit input and add gain output for testing
//	2011-8-17	serial multiplier in comp16 (was 571 slices, 1 RAM and 5 mult.)
//	2011-12-23	halve input clock rate to compensate for serial mult. in modem
//	2012-1-22	one transmit port
//	2012-2-29	fix resampler configuration input
//	2012-4-16	compressor with 128-entry LUT (was 871 LUT, 680 reg)
//	2013-3-22	latch status to ease timing requirements (was 681 reg - now 889 LUT, 699 reg)
//	2013-3-25	32-cycle baseband clock (was 868 LUT, 656 reg)
//	2013-9-19	create new module without resampler (was 867 LUT, 655 reg, 1 RAM, 3 mult.)
//	2013-11-15	mod. 22 BBCTR to allow 2 Msps with 48 MHz clock
//
module agcclip (
    output [15:0] gain,			// test signal for LSDAC
    input [19:0] rdix,rdiy,	// receiver data input
    input riv,						// receiver input valid
    output [15:0] rdox,rdoy,	// receiver data output
    output rov,					// receiver output valid
	 output final,					// final receiver output for current sample
	 output tie,					// transmit input enable (1/22 clock rate max.)
    input [15:0] tdix,tdiy,	// transmit data inputs
    input tiv,
	 input toe,						// tranmit output enable
    output [15:0] tdox,tdoy,	// transmit data output
    output tov,					// transmit output valid
    input clk,						// master clock and reset
    input rst,
	 input xmt,						// T/R switch
    input iocs,					// I/O ports for configuration
    input [2:0] ioaddr,
    input iowr,
    input [15:0] din,
    input iord,
    output [15:0] dout
    );
// internal signals
reg rse;									// resample enable bit
reg [4:0] bbctr;						// baseband clock divider
wire bbclk;								// baseband input strobe
wire w4,w5,w6,w7;						// output port selection
reg [15:0] omux;						// status multiplexer
// address decoding
assign w4 = iocs & iowr & (ioaddr == 4);	// AGC ports
assign w5 = iocs & iowr & (ioaddr == 5);
assign w6 = iocs & iowr & (ioaddr == 6);
assign w7 = iocs & iowr & (ioaddr == 7);	// compressor port
// baseband clock generator divides by 22 so that 
// modem output is never faster than 2.18 Msps at 48 MHz
always @ (posedge clk)
begin
//	if (rst) bbctr <= 0;
	if (rst|bbclk) bbctr <= 0;
	else if (toe) bbctr <= bbctr + 1'b1;
end
assign bbclk = (bbctr == 21) & toe;
//assign bbclk = (&bbctr) & toe;
// AGC subsystem level receiver output
//agc20s16 agc (
agc20s16a agc (
	.dix(rdix),
	.diy(rdiy),
	.iv(riv),
	.dox(rdox),
	.doy(rdoy),
	.ov(rov),
	.cin(din),
	.w0(w4),
	.w1(w5),
	.w2(w6),
	.cout(gain),
	.clk(clk),
	.rst(rst)
	);
// RF clipper subsystem processes transmit
// baseband input
comp16a comp (
	.dix(tdix),
	.diy(tdiy),
	.iv(tiv),
	.dox(tdox),
	.doy(tdoy),
	.ov(tov),
	.cin(din[7:0]),
	.cwe(w7),
	.clk(clk)
	);
// connect status port
always @ (posedge clk)
begin
	if (iord) omux <= gain;
end
assign dout = omux;
// connect outputs
assign tie = bbclk;
endmodule

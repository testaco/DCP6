//
//				agcrsmplclip.v - AGC, Resampler and Clipper Module
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module contains the AGC, resampler and clipper for a transceiver. The
// AGC converts from 20-bit X and Y-axis receive inputs to 16-bit X and Y-axis
// outputs. The received signal may also be resampled upwards. The transmit
// path may also use the resampler but the path is 16-bits in and out. The
// clipper may be used to reduce the peak to average power ratio (PAPR) of the
// transmitted signal by changing gain with input magnitude. All functions are
// configured by a set of 8 output ports. 
//
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 0 |             LS Output Sample Rate             |               | Sample Rate (zero on update)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 1 |    Integer    |             MS Output Sample Rate             | (update)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |               Output Phase (interpolation point)              | Rsmpl. Phase (4 words)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 3 |                                               |  INT  |RSE|VFO| Resampler Control
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
//  1 |                                                           |OVF|
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// 867 LUT6s, 655 registers, 1 RAM and 3 multipliers are used. The maximum clock rate is 105 MHz.
//
// Normal Warnings:
//		Signal <comp/magdet/mm_0> is unconnected.
//
// History:
//		5-15-10	use 16-bit resampler and compressor (520 slices)
//		8-25-10	add 2nd transmit input and add gain output for testing
//		8-17-11	serial multiplier in comp16 (was 571 slices, 1 RAM and 5 mult.)
//		12-23-11	halve input clock rate to compensate for serial mult. in modem
//		1-22-12	one transmit port
//		2-29-12	fix resampler configuration input
//		4-16-12	compressor with 128-entry LUT (was 871 LUT, 680 reg)
//		3-22-13	latch status to ease timing requirements (was 681 reg - now 889 LUT, 699 reg)
//		3-25-13	32-cycle baseband clock (was 868 LUT, 656 reg)
//
module agcrsmplclip (
    output [15:0] gain,			// test signal for LSDAC
    input [19:0] rdix,rdiy,	// receiver data input
    input riv,						// receiver input valid
    output [15:0] rdox,rdoy,	// receiver data output
    output rov,					// receiver output valid
	 output final,					// final receiver output for current sample
	 output tie,					// transmit input enable (1/32 clock rate max.)
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
wire [15:0] agcx,agcy;				// AGC output
wire agcv;
wire [15:0] rsix,rsiy,rsox,rsoy;	// resampler I/O
wire rsiv,rsov,ovf;
wire w0,w1,w2,w3,w4,w5,w6,w7;		// output port selection
reg ovff;								// overflow latch
reg [15:0] omux;						// status multiplexer
// address decoding
assign w0 = iocs & iowr & (ioaddr == 0);	// resampler ports
assign w1 = iocs & iowr & (ioaddr == 1);
assign w2 = iocs & iowr & (ioaddr == 2);
assign w3 = iocs & iowr & (ioaddr == 3);
assign w4 = iocs & iowr & (ioaddr == 4);	// AGC ports
assign w5 = iocs & iowr & (ioaddr == 5);
assign w6 = iocs & iowr & (ioaddr == 6);
assign w7 = iocs & iowr & (ioaddr == 7);	// compressor port
// resampler select
always @ (posedge clk)
	if (rst) rse <= 0;
	else if (w3) rse <= din[1];
// baseband clock generator divides by 32 so that 
// modem output is never faster than 1.5 Msps
always @ (posedge clk)
begin
	if (rst) bbctr <= 0;
	else if (toe) bbctr <= bbctr + 1'b1;
end
assign bbclk = (&bbctr) & toe;
// AGC subsystem level receiver output
agc20s16 agc (
	.dix(rdix),
	.diy(rdiy),
	.iv(riv),
	.dox(agcx),
	.doy(agcy),
	.ov(agcv),
	.cin(din),
	.w0(w4),
	.w1(w5),
	.w2(w6),
	.cout(gain),
	.clk(clk),
	.rst(rst)
	);
// resampler accepts transmit baseband input or AGC output
assign rsix = (xmt) ? tdix : agcx;
assign rsiy = (xmt) ? tdiy : agcy;
assign rsiv = (xmt) ? tiv : agcv;
resample16vf rsmpl (
	.dix(rsix),
	.diy(rsiy),
	.iv(rsiv),
	.dox(rsox),
	.doy(rsoy),
	.ov(rsov),
	.of(final),
	.ovf(ovf),
	.cin(din),
	.cwr({w3,w2,w1,w0}),
	.clk(clk),
	.rst(rst)
	);
// RF clipper subsystem processes transmit
// baseband input or resampler output
comp16a comp (
	.dix(rse ? rsox : tdix),
	.diy(rse ? rsoy : tdiy),
	.iv(rse ? rsov : tiv),
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
	if (rst) ovff <= 0;
	else ovff <= (ovff|ovf) & ~(iord & iocs);
	if (iord) omux <= ioaddr[0] ? {15'b000000000000000,ovff} : gain;
end
assign dout = omux;
// connect outputs
assign rdox = rse ? rsox : agcx;
assign rdoy = rse ? rsoy : agcy;
assign rov = rse ? rsov : agcv;
assign tie = bbclk;
endmodule

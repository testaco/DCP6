//
//						agc20s16a.v - Automatic Gain Control
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a gain control system that converts a 20-bit input to a 16-bit
// output. DIX and DIY are the input and DOX and DOY output for rectangular data. IV and
// OV indicate valid data. The module is configured via the following output ports.
//
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 0 |    Attack     |    Release    |        Output Setpoint        |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 1 |           Hang Time           |         Hang Setpoint         |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 2 |                               |           Max. Gain           |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// The attack and release values represent the loop gain for errors above and below the
// output setpoint. The loop gain is a power of two so 0 indicates 1 and 9 indicates 512.
// Hang time is the hang AGC timeout in samples * 256 and determines how long the AGC
// circuit waits after the output magnitude drops below the hang setpoint before changing
// the loop gain to the attack value. This causes the AGC gain to change slowly for the
// hang period and then rapidly increases the AGC gain to accomodate the new lower signal
// level. The maximum gain register sets an upper limit on the AGC gain. The upper 8 bits
// are specified in this register and the lower 16 bits are all ones. The current AGC
// value may be read via the input port.
//
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//   |    Exponent   |                   Mantissa                    |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// The exponent is 0-15 and indicates the gain value in steps of 6 dB from 0 to 90 dB.
// The mantissa is a linear binary value and encodes gains between 1 and 2 (0-5.999 dB)
// where 0 is 0 dB and 4095 specifies a gain of almost 6 dB. This is added to the gain
// specified by the exponent for a range of 0-96 dB in steps 0.0021-0.0042 dB. The I/O
// delay is 15-30 clocks
//
// 319 LUT6 and 327 registers are used. The maximum clock frequency is 123 MHz.
//
// Normal Errors:
//		Signal <gain<7:0>> is assigned but never used.
//
// History:
//		2010-4-26	create from agc20-16 (eliminate block multipliers in logmul)
//		2010-4-29	modify for 24-bit integrator and hang AGC (was 177 slices)
//		2010-5-3	add gain limit and use 8-bit magnitude (was 204 slices)
//		2010-5-12	remove address decoding to allow use in AGC/resampler/compressor module
//		2010-12-8	fixed truncation warning for hctr in Spartan-6
//		2013-11-20	use logmul20s16a to allow 16 clocks between samples
//
module agc20s16a(dix,diy,iv,dox,doy,ov,cin,w0,w1,w2,cout,clk,rst);
    input [19:0] dix,diy;	// data input
	 input iv;
    output [15:0] dox,doy;	// data output
	 output ov;
    input [15:0] cin;		// configuration input
	 input w0,w1,w2;			// write enables
    output [15:0] cout;		// configuration output
    input clk;					// master clock
	 input rst;					// master reset
// internal busses
reg [3:0] dng,upg;			// attack and release gain
reg [7:0] level,hlev;		// output level and hang level setpoints
reg [7:0] htime,maxg;		// hang time and maximum gain
wire [7:0] mag;				// magnitude of top 8 bits of output
wire mov,aiv;					// magnitude and shifted magnitude valid
wire [8:0] dif;				// diference between setpoint and magnitude
wire ds;							// difference sign bit
reg [23:0] error;				// error signal to integratator
wire [3:0] lg;					// loop gain select error signal gain
wire [23:0] gain;				// error accumulator output
wire hld;						// load hang timer
reg [15:0] hctr;				// hang time counter
wire hz;							// hange time counter is zero
// store configuration information
always @ (posedge clk)
begin
	if (rst) level <= 32;	// default to -12 dBFS
	else if (w0) level <= cin[7:0];
	if (rst) upg <= 5;		// default to 1 sec. release time at 16 ksps
	else if (w0) upg <= cin[11:8];
	if (rst) dng <= 10;		// default to 10 ms attack time at 16 ksps
	else if (w0) dng <= cin[15:12];
	if (rst) hlev <= 8;		// default to -24 dBFS
	else if (w1) hlev <= cin[7:0];
	if (rst) htime <= 64;	// default to 1 sec. at 16 ksps
	else if (w1) htime <= cin[15:8];
	if (rst) maxg <= 223;	// default to 84 dB
	else if (w2) maxg <= cin[7:0];
end
// dual serial logarithmic multiplier for gain control (99 slices)
logmul20s16a mul (
    .dix(dix),				// 20-bit data input
	 .diy(diy),
	 .iv(iv),
    .dox(dox),				// 16-bit data output
	 .doy(doy),
	 .ov(ov),
    .clk(clk),				// master clock
	 .rst(rst),				// master reset
    .gain(gain[23:8])	// gain set
	 );
// the output signal is converted to a magnitude
mag8 magdet (
	.x(dox[15:8]),	// use top 8 bits
	.y(doy[15:8]),
	.iv(ov),
	.mag(mag),		// 8-bit magnitude (0-1.4)
	.ov(mov),
	.clk(clk)
	);
// The output magnitude is compared to the lower setpoint (hang level) and used to load
// the hang time into the hang counter. When the output signal level drops below the
// theshold the hang counter decrements at the sample rate until it reaches zero.
assign hld = (mag > hlev);
always @ (posedge clk)
begin
	if (rst) hctr <= 0;
	else if (hld) hctr <= {htime,8'h00};			// load timeout (0 = disable)
	else if (iv & ~hz) hctr <= hctr - 16'h0001;	// decrement if non-zero
end
assign hz = ~|hctr;	// detect all bits zero
// setpoint comparison uses a subtractor to get the error signal and two shift registers
// to set the loop gain - one shifts the error signal to multiply by a power of two with
// each clock cycle and the other delays the strobe to select the multiplication factor
assign dif = {1'b0,level} - {1'b0,mag};
assign ds = dif[8];
always @ (posedge clk)
begin
	error <= mov
		? {ds,ds,ds,ds,ds,ds,ds,ds,ds,ds,ds,ds,ds,ds,ds,dif}	// load
		: {error[22:0],1'b0};											// shift
end
// loop gain varies depending on the sign of the error signal and the hang timer state
// when the output is above the desired level the attack gain multipler is used
// when the output is below the desired level the release gain multiplier is used unless
// the output is below the lower threshold (hlev) where the gain depends on the hang timer
// if the timer is counting down the gain multiplier is zero
// otherwise the the attack gain multiplier is used
assign lg = ds ? dng : (hld ? upg : (hz ? dng : 4'h0));
SRL16E sr (
	.D(mov),
	.A0(lg[0]), .A1(lg[1]), .A2(lg[2]), .A3(lg[3]),
	.CLK(clk), .CE(1'b1),
	.Q(aiv)
	);
// the error signal is integrated to generate the AGC signal (gain) which varies between
// zero and the maximum gain (maxg)
accsat24v acc (
	.d(error),
	.max(maxg),
	.q(gain),
	.ce(aiv),
	.clk(clk),
	.rst(rst)
	);
// connect output
assign cout = gain[23:8];
endmodule

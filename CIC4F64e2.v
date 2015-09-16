//
//				CIC4F64e2.v - 1/2-channel 4-stage Cascaded Integrator Comb Filter
//
//					  (C) Copyright 2007-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a switchable CIC interpolator or CIC decimator. Interpolation
// and decimation by 8-2896 is possible. RDI and TDO are the input from the mixer and
// output to the mixer for receiving and transmitting, respectively. Data is sampled
// synchronous to DCLK and 2 channels may be multiplexed. RDO and TDI are decimated data
// for receiving and input data for interpolation for transmitting, respectively. TIE
// requests new data on TDI. One sample is present on each DCLK cycle for TDO.
//
// One 64-bit integrator, three 56-bit integrators and a 4-stage 24-bit comb filter are used
// in the receive path. Filter gain is the decimation factor to the fourth power, so it is
// 4.1 x 10^3 to 3.9 x 10^13 for decimation factors from 8-2580. 46 extra bits are provided
// and full-scale output can be reached by adjusting the input gain to 2^46/(filter gain). 
//
// A 4-stage 24-bit comb filter, one 64-bit integrator and three 52-bit integrators are used
// in the transmit path. Filter gain is the decimation factor to the third power, so filter
// gain is 5.1 x 10^2 to 1.6 x 10^10 for decimation factors from 8-2580. 42 extra bits are
// provided so full-scale output can be reached by adjusting the input gain to 2^42/(filter
// gain). Note that the multiplication factor cannot exceed 4 to prevent clipping in the
// comb filter.
//
// One configuration register controls gain with 5 bits of binary exponent, 4 bits of
// integer gain and 6 bits of fractional gain. The other contains the 12-bit decimation
// or interpolation factor. The multiplier gain should be between 1 and 16 for receiving
// and be between 1 and 4 for transmitting. The shift value is 0-30 for reception and
// 8-31 for transmission. Thus, an 18-bit input can be adjusted to use the lower 18 to 51
// bits of the 64-bit accumulator input.
//
// Note that several components must be instantiated instead of inferred to prevent
// optimization that can slow operation and/or disrupt I/O timing. The upper bit of the
// receiver output is dropped as the image output of the mixer is removed by the CIC filter.
// There is an 18 clock delay for receiving and a 16 clock delay for transmitting.
// NOTE: 1) use only one of CEA or CEB when C=0
//			2) use CEA and CEB on alternate clock cycles when C=1
//
// 564 LUTs, 998 registers and 1 DSP48 are used. The maximum DCLK frequency is 212 MHz (-2).
//
// History:
//		2-24-13	create from CIC4F64 by making delay variable (was 584 LUT, 1025 reg, 220 MHz)
//		2-27-13	create from CIC4F64x2 by making counter external (was 584 LUT, 1026 reg, 213 MHz)
//		3-3-13	create from CIC4F64x1 by using dif24e2 and 2 sets of enable delays (adds 6 LUT & 12 reg)
//
//	Normal Errors:
//		<rnd_0> to <rnd_4> unconnected.
//
module CIC4F64e2(
	input [17:0] rdi,tdi,	// data inputs
	output tiea,tieb,			// get new transmitter input
	output [17:0] rdo,tdo,	// data outputs
	output rova,rovb,			// valid receiver output
	output ovfa,ovfb,			// receiver output overflow
	input cea,ceb,				// clock enables for differentiator
	input clk,					// master clock
	input rst,					// master reset (sync. to SCLK)
	input xmt,					// 0=receive (RDI->RDO), 1=transmit (TDI->TDO)
	input [4:0] ge,			// gain exponent part
	input [9:0] gf,			// gain fractional part
	input c						// number of channels
	);
// internal signals
reg [17:0] mux0;		// multiplier input multiplexer
reg [23:0] mux1;		// integrator input multiplexer
//wire [23:0] mux1;		// integrator input multiplexer
reg rstimux;			// reset signal for mux1
wire [35:0] prod;		// DSP48 M output (2 clock delay)
//wire [47:0] prod;	// DSP48 P output (3 clock delay)
//reg [25:0] shift1;	// shift 0,1,2,3 bits (24->27)
//reg [37:0] shift4;	// shift 0,4,8,12 bits (27->39)
//reg [53:0] shift16;	// shift 0,16 bits (39->55)
//reg s1,s4,s16;			// sign bits
wire [63:0] acc0,acc1;	// 64-bit integrator
wire [63:8] acc2,acc3,acc4;	// 56-bit integrators
reg [23:0] rnd;		// rounded result
reg [17:0] clp;		// clipped result
wire sr,sc;				// rounder and clipper input sign bits
//wire [23:0] dif0;		// comb filter input
reg [23:0] dif0;		// comb filter input
wire [23:0] dif1,dif2,dif3,dif4;	// comb filter subtractors
reg e1a,e2a,e3a,e4a,e5a,e6a,e7a,e8a;	// differentiator A data valid delay
reg e1b,e2b,e3b,e4b,e5b,e6b,e7b,e8b;	// differentiator B data valid delay
wire ovflo;				// receiver overflow detection logic
reg ovffa,ovffb;		// overflow latch
// Multiplier input multiplexer - multiplex transmittter input - 1 clock delay
always @ (posedge clk) mux0 <= xmt ? tdi : rdi;
// Gain control - 2 clock delay
// input and output synchronized to negative-going edges of SCLK
DSP48A1 #(
	.A0REG(0),
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(0),
	.DREG(0),
	.MREG(1),
	.PREG(1),
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(0),
	.RSTTYPE("SYNC")
	) mult (
	.OPMODE(8'b00000001),
	.A(mux0),
	.B({8'h00,gf}),
	.BCOUT(),
	.C(48'h000000),
	.D(18'b000000000000000000),
	.M(prod),
//	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(48'h000000),
	.PCOUT(),
	.P(),
//	.P(prod),
	.CLK(clk),
	.CEA(1'b1),
	.CEB(1'b1),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(1'b1),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
// Integrator input multiplexer - 1 clock delay
// zero output between samples on transmit
// select differentiator output (xmt) or multiplier output (rcv)
// output synchronized to positive-going edges of SCLK when receiving
// output synchronized to negative-going edges of SCLK when transmitting
always @ (posedge clk)
begin
	if (rstimux) mux1 <= 0;
	else mux1 <= xmt ? dif4[23:0] : prod[29:6];
end
// Instantiate instead of inferring to prevent optimization
//MUX2X24S imux (
//	.D0(prod[29:6]),	// receive mult = 0-16
//	.D1(dif4[23:0]),	// transmit
//	.S(xmt),
//	.Q(mux1),
//	.CLK(clk),
//	.CE(1'b1),
//	.RST(rstimux)
//	);
// Integrator input shifter: 24-bit input and 55-bit output with 3 clock delay
shift24i55o iis (
	.d(mux1),
	.q(acc0[54:0]),
	.n(ge),
	.clk(clk)
	);
// 4 pipelined integrators with dual accumulators
// delay provides 2nd channel in each accumulator
//assign acc0 = {s16,s16,s16,s16,s16,s16,s16,s16,s16,s16,shift16};
assign acc0[63:55] = {acc0[54],acc0[54],acc0[54],acc0[54],acc0[54],acc0[54],acc0[54],acc0[54],acc0[54]};
int64 a1 (.d(acc0), .q(acc1), .n(c), .clk(clk), .rst(rst));
int56 a2 (.d(acc1[63:8]), .q(acc2), .n(c), .clk(clk), .rst(rst));
int56 a3 (.d(acc2), .q(acc3), .n(c), .clk(clk), .rst(rst));
int56 a4 (.d(acc3), .q(acc4), .n(c), .clk(clk), .rst(rst));
// delay clock enables to enable differentiators for each channel
// also generate reset signal for integrator input multiplexer when neither channel active
always @ (posedge clk)
begin
	e1a <= cea;
	e2a <= e1a;
	e3a <= e2a;
	e4a <= e3a;
	e5a <= e4a;
	e6a <= e5a;
	e7a <= e6a;
	e8a <= e7a;
	e1b <= ceb;
	e2b <= e1b;
	e3b <= e2b;
	e4b <= e3b;
	e5b <= e4b;
	e6b <= e5b;
	e7b <= e6b;
	e8b <= e7b;
	rstimux <= xmt & ~e5a & ~e5b;	// reset unless e5a=1 or e5b=1
end
assign tiea = e2a;	// also use to request transmitter input samples
assign tieb = e2b;
// Differentiator input multiplexer
// output synchronized to IQ due to even number of registers following input port
always @ (posedge clk) dif0 <= xmt ? prod[29:6] : acc4[63:40];
// Instantiate instead of inferring to prevent delay-increasing optimization
//MUX2X24S dmux (
//	.D0(acc4[63:40]),	// receive: integrator output
//	.D1(prod[29:6]),	// transmit: multipler output
//	.S(xmt),
//	.Q(dif0),
//	.CLK(clk),
//	.CE(1'b1),
//	.RST(1'b0)
//	);
// Comb Filter is 4 differentiators
dif24e2 d1 (.d(dif0), .q(dif1), .ce0(e2a), .ce1(e2b), .clk(clk), .rst(rst));
dif24e2 d2 (.d(dif1), .q(dif2), .ce0(e3a), .ce1(e3b), .clk(clk), .rst(rst));
dif24e2 d3 (.d(dif2), .q(dif3), .ce0(e4a), .ce1(e4b), .clk(clk), .rst(rst));
dif24e2 d4 (.d(dif3), .q(dif4), .ce0(e5a), .ce1(e5b), .clk(clk), .rst(rst));
// truncate transmitter output
assign tdo = acc4[59:42];	// drop upper 4 and lower 42 bits
// round receiver output to 19 bits by adding 0.100000000 for positive numbers
// or 0.011111111 for negative numbers and dropping lower 5 bits
assign sr = dif4[23];
always @ (posedge clk)
	rnd <= dif4 + {19'b0000000000000000000,~sr,sr,sr,sr,sr};
// drop MSB, detect positive or negative overflow beyond 18 bits and saturate output
assign sc = rnd[23];	// most significant or sign bit
assign ovflo = (rnd[23] ^ rnd[22]);	// overflow
always @ (posedge clk)
	clp <= ovflo ?
	{sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,1'b1}
	: rnd[22:5];	// drop MSB as image frequency has been filtered out
// check for overflow
always @ (posedge clk)
begin
	if (rst) ovffa <= 0;
	else if (e7a) ovffa <= ovflo;
	if (rst) ovffb <= 0;
	else if (e7b) ovffb <= ovflo;
end
// connect receiver output
assign rdo = clp;
assign rova = e8a;
assign rovb = e8b;
assign ovfa = ovffa;
assign ovfb = ovffb;
endmodule

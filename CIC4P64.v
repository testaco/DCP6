//
//					CIC4P64.v - 4-stage Cascaded Integrator Comb Filter
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
// synchronous to SCLK and multiplexed at the DCLK rate. RDO and TDI are decimated data
// for receiving and input data for interpolation for transmitting, respectively. TIE
// requests new data on TDI. One X or Y sample is present on each DCLK cycle for TDO.
// SCLK high indicates X and SCLK low indicates Y.
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
// One configuration input controls gain with 5 bits of binary exponent, 4 bits of
// integer gain and 6 bits of fractional gain. Another contains the 12-bit decimation
// or interpolation factor. The multiplier gain should be between 1 and 16 for receiving
// and be between 1 and 4 for transmitting. The shift value is 0-30 for reception and
// 8-31 for transmission. Thus, an 18-bit input can be adjusted to use the lower 18 to 51
// bits of the 64-bit accumulator input.
//
// Note that several components must be instantiated instead of inferred to prevent
// optimization that can slow operation and/or disrupt I/O timing. The upper bit of the
// receiver output is dropped as the image output of the mixer is removed by the CIC filter.
// There is an 19 clock delay for receiving and a 16 clock delay for transmitting.
//
// 588 LUTs, 1017 registers and 1 DSP48 are used. The maximum clock frequency is 220 MHz.
//
// History:
//		3-7-13	create from CIC4H64 by removing configuration registers (was 1024 reg)
//		3-12-13	parallel receive data output using 2 clipper registers (was 584 LUT, 998 reg)
//		3-23-13	shorten TIE to 1 clock cycle (587 LUT, 1018 reg)
//
module CIC4P64(
	input [17:0] rdi,				// receive data input - serial X and Y
	input [17:0] tdix,tdiy,		// tranmit data input - parallel X and Y
	output tie,						// get new transmitter input
	output [17:0] tdo,			// transmit data output - serial X and Y
	output [17:0] rdox,rdoy,	// receive data output - parallel X and Y
	output rov,						// valid receiver output
	output ovf,						// receiver output overflow
	input clk,						// master clock
	input iq,						// data tag (I=1, Q=0)
	input rst,						// master reset (sync. to SCLK)
	input xmt,						// 0=receive (RDI->RDO), 1=transmit (TDI->TDO)
	input [4:0] ge,				// gain exponent
	input [9:0] gf,				// gain fraction
	input [11:0] n					// int./dec. factor
	);
// internal signals
wire [17:0] mux0;			// multiplier input multiplexer
wire [23:0] mux1;			// integrator input multiplexer
reg rstimux;				// reset signal for mux1
wire [35:0] prod;			// DSP48 M output (2 clock delay)
//wire [47:0] prod;		// DSP48 P output (3 clock delay)
reg [25:0] shift1;		// shift 0,1,2,3 bits (24->27)
reg [37:0] shift4;		// shift 0,4,8,12 bits (27->39)
reg [53:0] shift16;		// shift 0,16 bits (39->55)
reg s1,s4,s16;				// sign bits
reg [63:0] acc1a,acc1b;	// 64-bit integrators
reg [63:8] acc2a,acc3a,acc4a,acc2b,acc3b,acc4b;	// 56-bit integrators
wire [23:0] dif0;			// comb filter input
reg [23:0] dly1a,dly1b,dly2a,dly2b,dly3a,dly3b,dly4a,dly4b;	// comb filter storage
reg [23:0] dif1,dif2,dif3,dif4;										// comb filter subtractors
reg [11:0] i;				// sample counter
wire tc;						// terminal count
reg e1,e2,e3,e4,e5,e6,e7,e8;	// differentiator data valid delay
reg [23:0] rnd;			// rounded result
wire [17:0] clp;			// clipped result
reg [17:0] clpx,clpy;	// latched outputs
wire sr,sc;					// rounder and clipper input sign bits
wire ovflo;					// receiver overflow detection logic
reg ovfx,ovfy;				// overflow latches
// Multiplier input multiplexer - multiplex transmittter input - 1 clock delay
MUX4X18S mmux (
	.D0(rdi),		// already multiplexed with X/Y while SCLK high/low
	.D1(rdi),
	.D2(tdiy),		// data following negative-going edge of SCLK (IQ=0)
	.D3(tdix),		// data following positive-going edge of SCLK (IQ=1)
	.S({xmt,iq}),	// IQ same phase as SCLK
	.Q(mux0),
	.CE(1'b1),
	.CLK(clk),
	.RST(rst)
	);
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
// Instantiate instead of inferring to prevent optimization
MUX2X24S imux (
	.D0(prod[29:6]),	// receive mult = 0-16
	.D1(dif4[23:0]),	// transmit
	.S(xmt),
	.Q(mux1),
	.CLK(clk),
	.CE(1'b1),
	.RST(rstimux)
	);
// Integrator input shifter: 24-bit input and 48-bit output with 3 clock delay
// The first multiplexer shifts in 1 bit increments, the second in 4 bit increments
// and the third in 16-bit increments. The most significant bit is not shifted.
always @ (posedge clk)
begin
	case (ge[1:0])
	2'b00: shift1 <= {mux1[23],mux1[23],mux1[23],mux1[22:0]};
	2'b01: shift1 <= {mux1[23],mux1[23],mux1[22:0],1'b0};
	2'b10: shift1 <= {mux1[23],mux1[22:0],2'b00};
	2'b11: shift1 <= {mux1[22:0],3'b00};
	default: shift1 <= 26'hxxxxxxx;
	endcase
	s1 <= mux1[23];
	case (ge[3:2])
	2'b00: shift4 <= {s1,s1,s1,s1,s1,s1,s1,s1,s1,s1,s1,s1,shift1};
	2'b01: shift4 <= {s1,s1,s1,s1,s1,s1,s1,s1,shift1,4'h0};
	2'b10: shift4 <= {s1,s1,s1,s1,shift1,8'h00};
	2'b11: shift4 <= {shift1,12'h000};
	default: shift4 <= 38'hxxxxxxxxxx;
	endcase
	s4 <= s1;
	case (ge[4])
	1'b0: shift16 <= {s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,shift4};
	1'b1: shift16 <= {shift4,16'h0000};
	default: shift16 <= 54'hxxxxxxxxxxxxxx;
	endcase
	s16 <= s4;
end
// 4 pipelined integrators with dual accumulators
// delay provides 2nd channel in each accumulator
always @ (posedge clk)
begin
	if (rst) acc1a <= 0;	// 64-bit integrator
	else acc1a <= acc1b + {s16,s16,s16,s16,s16,s16,s16,s16,s16,s16,shift16};
	if (rst) acc2a <= 0;	// 56-bit integrator
	else acc2a <= acc2b + acc1a[63:8];
	if (rst) acc3a <= 0;	// 56-bit integrator
	else acc3a <= acc3b + acc2a;
	if (rst) acc4a <= 0;	// 56-bit integrator
	else acc4a <= acc4b + acc3a;
	acc1b <= acc1a;
	acc2b <= acc2a;
	acc3b <= acc3a;
	acc4b <= acc4a;
end
// sample counter increments when IQ=0 (equiv. to positive edge of SCLK)
always @ (posedge clk)
begin
	if (rst|(tc & ~iq)) i <= n;	// interpolation/decimation counter
	else if (~iq) i <= i - 1'b1;
end
assign tc = (i == 0);	// i is zero
// delay terminal count to enable differentiators
// even-numbered taps synchronized to SCLK positive-going edge
// odd-numbered taps synchronized to SCLK negative-going edge
// also generates reset signal for integrator input multiplexer
always @ (posedge clk)
begin
	e1 <= tc;	// dmux input
	e2 <= e1;	// enable dif1
	e3 <= e2;	// enable dif2
	e4 <= e3;	// enable dif3
	e5 <= e4;	// enable dif4
	e6 <= e5;	// enable imux (tx) or round (rx)
	rstimux <= xmt & ~e5;	// same timing as e6
	e7 <= e6;	// enable clipper
	e8 <= e7;	// output valid
end
assign tie = e2 & e1;	// also use to request transmitter input samples
// Differentiator input multiplexer
// Instantiate instead of inferring to prevent delay-increasing optimization
// output synchronized to SCLK due to even number of registers following input port
MUX2X24S dmux (
	.D0(acc4a[63:40]),// receive: integrator output
	.D1(prod[29:6]),	// transmit: multipler output
	.S(xmt),
	.Q(dif0),
	.CLK(clk),
	.CE(1'b1),
	.RST(1'b0)
	);
// Comb Filter
// 4 differentiators with 2 clock delay on negative input to support 2 channels
always @ (posedge clk)
begin
	if (rst) dif1 <= 0;
	else if (e2) dif1 <= dif0 - dly1b;
	if (rst) dly1a <= 0;
	else if (e2) dly1a <= dif0;
	if (rst) dly1b <= 0;
	else if (e2) dly1b <= dly1a;
	if (rst) dif2 <= 0;
	else if (e3) dif2 <= dif1 - dly2b;
	if (rst) dly2a <= 0;
	else if (e3) dly2a <= dif1;
	if (rst) dly2b <= 0;
	else if (e3) dly2b <= dly2a;
	if (rst) dif3 <= 0;
	else if (e4) dif3 <= dif2 - dly3b;
	if (rst) dly3a <= 0;
	else if (e4) dly3a <= dif2;
	if (rst) dly3b <= 0;
	else if (e4) dly3b <= dly3a;
	if (rst) dif4 <= 0;
	else if (e5) dif4 <= dif3 - dly4b;
	if (rst) dly4a <= 0;
	else if (e5) dly4a <= dif3;
	if (rst) dly4b <= 0;
	else if (e5) dly4b <= dly4a;
end
// truncate transmitter output
assign tdo = acc4a[59:42];	// drop upper 4 and lower 42 bits
// round receiver output to 19 bits by adding 0.100000000 for positive numbers
// or 0.011111111 for negative numbers and dropping lower 5 bits
assign sr = dif4[23];
always @ (posedge clk)
	rnd <= dif4 + {19'b0000000000000000000,~sr,sr,sr,sr,sr};
// detect positive or negative overflow beyond 18 bits and saturate output
// drop MSB as image frequency has been filtered out
assign sc = rnd[23];	// most significant or sign bit
assign ovflo = (rnd[23] ^ rnd[22]);	// overflow
assign clp = ovflo ?
	{sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,~sc,1'b1}
	: rnd[22:5];
// latch results
always @ (posedge clk)
begin
	if (e7 & e6) clpx <= clp;	// first sample
	if (e7 & e6) ovfx <= ovflo;
	if (e7 & ~e6) clpy <= clp;	// second sample
	if (e7 & ~e6) ovfy <= ovflo;
end
// connect receiver output
assign rdox = clpx;
assign rdoy = clpy;
assign rov = e8 & ~e7;	// last sample latched
assign ovf = ovfx|ovfy;
endmodule

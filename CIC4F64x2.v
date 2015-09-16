//
//		CIC4F64x2.v - Dual 1/2-channel 4-stage Cascaded Integrator Comb Filter
//
//					  (C) Copyright 2007-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a CIC interpolator or two CIC decimators. Interpolation
// and decimation by 8-2896 is possible. RDI and TDO are the input from the mixer and
// output to the mixer for receiving and transmitting, respectively. Data is sampled
// synchronous to DCLK and 2 channels may be multiplexed. RDO and TDI are decimated data
// for receiving and input data for interpolation for transmitting, respectively. TIE
// requests new data on TDI. One sample is present on each DCLK cycle for TDO.
// There is an 18 DCLK delay for receiving and a 16 DCLK delay for transmitting.
//
// 1178 LUT6s, 2031 registers and 2 DSP48 are used. The maximum DCLK frequency is 213 MHz.
//
// History:
//		3-3-13	two CIC4F64e2 with separate interpolation/decimation factors
//
// Normal Errors:
//		output ports <rov> and <tie> of <cicy> are unconnected.
//		<rnd_0> to <rnd_4> of <cicy> and <cicy> are unconnected.
//
module CIC4F64x2(
	input [17:0] rdix,rdiy,		// receiver data inputs
	input [17:0] tdix,tdiy,		// transmitterdata inputs
	output tiea,tieb,				// get new transmitter input
	output [17:0] rdox,rdoy,	// receiver data outputs
	output [17:0] tdox,tdoy,	// transmitter data outputs
	output rova,rovb,				// valid receiver output
	output ovfa,ovfb,				// receiver output overflow
	input clk,						// master clock
	input ab,						// channel select (1=A/0=B)
	input rst,						// master reset (sync. to SCLK)
	input xmt,						// 0=receive (RDI->RDO), 1=transmit (TDI->TDO)
	input [11:0] na,nb,			// interpolation/decimation factors - 1 
	input [4:0] gea,geb,			// gain exponent
	input [9:0] gfa,gfb,			// gain fraction
	input c							// no. chan.
	);
// internal signals
reg [4:0] ge;			// multiplexed gain exponent
reg [9:0] gf;			// multiplexed gain fraction
reg [11:0] a,b;		// sample counters
wire rsta,rstb;		// counter reset
reg tca,tcb;			// terminal count
wire ovfx,ovfy;		// overflow flags
// sample counter decrements when count for each channel alternately
// count is half actual value when only one channel active (C=0)
// CIC gain compensation is multiplexed 
// fraction to exponent delay is 3 for receive and 8 for transmit
assign rsta = rst|tca;
assign rstb = rst|tcb|~c;
always @ (posedge clk)
begin
	if (rsta) a <= 0;							// reset on terminal count
	else if (ab) a <= a + 1'b1;			// count up on alternate clocks
	tca <= (a == na) & ~ab;					// TC output when AB=1
	if (rstb) b <= 0;							// always reset if one channel
	else if (~ab) b <= b + 1'b1;			// always count up on alternate clocks
	tcb <= (b == nb) & ab;					// TC output when AB=0
	ge <= ((~xmt^ab) | ~c) ? gea : geb;	// change exponent phase for receive and transmit
	gf <= (ab | ~c) ? gfa : gfb;			// constant delay to multiplier (1 clock)
end
// X-axis CIC
CIC4F64e2 cicx (
	.rdi(rdix),
	.tdi(tdix),
	.tiea(tiea),
	.tieb(tieb),
	.rdo(rdox),
	.tdo(tdox),
	.rova(rova),
	.rovb(rovb),
	.ovfa(ovfax),
	.ovfb(ovfbx),
	.cea(tca),
	.ceb(tcb),
	.clk(clk),
	.rst(rst),
	.xmt(xmt),
	.ge(ge),
	.gf(gf),
	.c(c)
	);
// Y-axis CIC
CIC4F64e2 cicy (
	.rdi(rdiy),
	.tdi(tdiy),
	.tiea(),
	.tieb(),
	.rdo(rdoy),
	.tdo(tdoy),
	.rova(),
	.rovb(),
	.ovfa(ovfay),
	.ovfb(ovfby),
	.cea(tca),
	.ceb(tcb),
	.clk(clk),
	.rst(rst),
	.xmt(xmt),
	.ge(ge),
	.gf(gf),
	.c(c)
	);
// connect outputs
assign ovfa = ovfax|ovfay;
assign ovfb = ovfbx|ovfby;
endmodule

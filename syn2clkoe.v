//
//		syn2clkoe.v - transfer pulses from one clock domain to another
//
// 				(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	This module is designed for asynchronous clocks and transfers a one clock
// period long pulse from one clock domain to another. The maximum delay is
// one clock domain A period plus two clock domain B periods. This version
// has an enable for the output clock.
//
module syn2clkoe(
	 input a,		// input
	 input aclk,	// input clock
	 input arst,	// reset input
	 output b,		// output
	 input boe,		// output enable
	 input bclk,	// output clock
	 input brst		// reset output
	 );
// registers
reg t;			// clock domain A
reg s0,s1,s2;	// clock domain B
// flip-flop toggles when input logic one
always @ (posedge aclk)
begin
	if (arst) t <= 1'b0;	// reset for simulation
	else if (a) t <= ~t;	// toggle when enabled
//	else t <= t^a;
end
// output logic synchronizes transition to output clock
// first flip-flop can enter meta-stable states
// second flip-flop waits for instablity to end
// third flip-flop and exclusive-or convert transition to logic one for one clock period
always @ (posedge bclk)
begin
	if (brst) s0 <= 0;
	else s0 <= t;				// unstable
	if (brst) s1 <= 0;
	else if (boe) s1 <= s0;	// absorbs instability
	if (brst) s2 <= 0;
	else if (boe) s2 <= s1;	// for transition detection
end
assign b = s1 ^ s2;	// create pulse
endmodule

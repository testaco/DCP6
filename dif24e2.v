//
//					24-bit 1 or 2 Channel Differentiator with 2 Enables
//
//					  		(C) Copyright 2013 John B. Stephensen
// 
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a differentiator with 2 multiplexed inputs.
//
// 25 LUT6s and 72 registers used. 306 MHz maximum clock rate. 
//
module dif24e2(
    input [23:0] d,		// input
    output [23:0] q,		// output
	 input ce0,ce1,		// clock enables
	 input clk,				// clock
    input rst				// reset
    );
// internal signals
reg [23:0] a,b,c;	// registers
wire [23:0] f;		// feedback multiplexer
// intergrator
always @ (posedge clk)
begin
	if (rst) a <= 0; else if (ce0) a <= d;				// input 0 delay
	if (rst) b <= 0; else if (ce1) b <= d;				// input 1 delay
	if (rst) c <= 0; else if (ce0|ce1) c <= d - f;	// subtract old value
end
assign f = ce1 ? b : a;	// select 1 or 0 clock delay
// connect outputs
assign q = c;
endmodule

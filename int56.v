//
//								56-bit 1 or 2 Channel Integrator
//
//					  		(C) Copyright 2013 John B. Stephensen
// 
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements an accumulator with a 1-2 clock delay in the 
// feedback loop.
//
// 56 LUT6s and 112 registers used. 220 MHz maximum clock rate. 
//
module int56(
    input [55:0] d,	// input
    output [55:0] q,	// output
    input n,			// delay
	 input clk,			// clock
    input rst			// reset
    );
// internal signals
reg [55:0] a,b;	// registers
wire [55:0] f;		// feedback multiplexer
// intergrator
always @ (posedge clk)
begin
	if (rst) a <=0; else a <= d + f;	// adder
	if (rst) b <=0; else b <= a;		// optional delay
end
assign f = n ? b : a;	// select 1 or 0 clock delay
// connect output
assign q = a;
endmodule

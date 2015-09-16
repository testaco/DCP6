//
//					max12.v - Calculate Maximum Magnitude of Signed Input
//
//							(C) Copyright 2012 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-6 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
// 23 LUT6s and 22 registers used. 231 MHz maximum clock rate.
//
module max12 (
    input [11:0] sig,	// signed input
    output [10:0] max,	// unsigned output
    input clk,				// master clock
    input rst				// reset maximum to zero
    );
// Internal Logic
reg [10:0] a,m;
wire [11:0] d;
// negate input if sign bit is one
// replace maximum value if input greater
always @ (posedge clk)
begin
	a <= sig[11] ? -sig[10:0] : sig[10:0];	// absolute value of input
	if (rst) m <= 0;								// start at zero
	else if (d[11]) m <= a;						// save maximum value
end
// subtract absolute value from current maximum to get carry output
// (Verilog comparison operation generates cascaded LUTs)
assign d = m - a;
// connect output
assign max = m;
endmodule

//
//							mag8.v - Magnitude Estimator
//
//					(C) Copyright 2007-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module uses the (max + min/2)*7/8 algorithm to estimate the magnitude
// of a vector in cartesian space. Note that the magnitude estimate has a
// range of 0.87-0.98 of the actual value.
//
// S3E: 40 slices used. 124 MHz maximum clock rate. 2 clock delay.
// S6: 57 LUTs and 25 registers used. 105 MHz max. clock rate.
//
// History:
//		5-3-10	allow magnitude output up to 1.414
//		12-27-10	modify for Spartan-6
//
module mag8 (
    input [7:0] x,
    input [7:0] y,
    input iv,
    output [7:0] mag,
    output ov,
    input clk
    );
// internal signals
wire [7:0] mx,my;	// absolute value of X and Y
wire xgty;			// X greater than Y
wire [7:0] mxy;	// max + min/2
reg [7:0] mm;		// magnitude multiplied by 7/8
reg [2:1] v;		// data valid delay
// get magnitude of X and Y
tc8s tcx (
	.D(x),
	.CMP(x[7]),
	.Q(mx),
	.CE(iv),
	.CLK(clk),
	.SCLR(1'b0)
	);
tc8s tcy (
	.D(y),
	.CMP(y[7]),
	.Q(my),
	.CE(iv),
	.CLK(clk),
	.SCLR(1'b0)
	);
// max + min/2
assign xgty = (mx > my);
assign mxy = (xgty ? mx : {1'b0,mx[7:1]}) + (xgty ? {1'b0,my[7:1]} : my);
// - 1/8
always @ (posedge clk)
begin
	mm <= mxy - {3'b000,mxy[7:3]};
	v <= {v[1],iv};
end
// connect output
assign mag = mm;
assign ov = v[2];
endmodule

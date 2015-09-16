//
//							mag12.v - Magnitude Estimator
//
//					(C) Copyright 2007-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module uses the (max + min/2) algorithm to estimate the magnitude
// of a vector in cartesian space. There is a 4 clock cycle delay. Note
// that the magnitude estimate has a range of 1-1.12 of the actual value.
//
// S6: 68 LUTs and 81 registers used. 324 MHz max. clock rate.
//
// History:
//		2013-2-28	create from mag8.v (del 7/8 term)
//
module mag12 (
    input [11:0] x,
    input [11:0] y,
    input iv,
    output [11:0] m,
    output ov,
    input clk
    );
// internal signals
reg [10:0] mx,my,dx,dy;	// absolute value of X and Y
reg xgty;					// X greater than Y
reg [10:0] hx,hy;			// full or half of absolute value
reg [11:0] mxy;			// max + min/2
reg [4:1] v;				// data valid delay
// get absolute value of X and Y by inverting negative values
// then select maximum and halve minimum and add
always @ (posedge clk)
begin
	v <= {v[3:1],iv};	// delay data valid input
	mx <= (x[11] ? ~x[10:0] : x[10:0]) + x[11];
	my <= (y[11] ? ~y[10:0] : y[10:0]) + y[11];
	dx <= mx;	// delay to match comparator output
	dy <= my;
	xgty <= (mx > my);
	hx <= xgty ? dx : {1'b0,dx[10:1]};	// halve minmum
	hy <= xgty ? {1'b0,dy[10:1]} : dy;
	if (v[3]) mxy <= {1'b0,hx} + {1'b0,hy};	// add
end
// connect output
assign m = mxy;
assign ov = v[4];
endmodule

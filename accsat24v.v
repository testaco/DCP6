//
//	accsat24v.v - 24-bit Unsigned Accumulator with Variable Saturation Logic
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module adds a 24-bit signed input to a 24-bit unsigned register.
// The register saturates at zero or the maximum positive value.
//
// 36 slices are used and the maximum clock frequency is 111 MHz.
//
module accsat24v(d,max,q,ce,clk,rst);
    input [23:0] d;	// data input
	 input [7:0] max;	// maximum
    output [23:0] q;	// data output
	 input ce;			// clock enable
    input clk;			// master clock
	 input rst;			// master reset
// internal busses
wire s;				// sign
wire [24:0] new;	// next value for accumulator
reg [23:0] acc;	// accumulator
wire sat;			// accumulator at upper or lower limit
// check input sign and adder output for overflow and for result that would exceed maximum
// saturate at zero if input negative
// saturate at maximum if input positive
assign s = d[23];											// get sign of input
assign new = {1'b0,acc} + {1'b0,d};					// add input to output and generate carry out
assign sat = (new[24] ^ s)|(new[23:16] > max);	// saturate if overflow or maximum exceeded
always @ (posedge clk)
begin
	if (rst) acc <= 0;
	else if (ce) acc <= sat 
		? {(s ? 8'h00 : max),~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s}
		: new[23:0];
end
assign q = acc;
endmodule

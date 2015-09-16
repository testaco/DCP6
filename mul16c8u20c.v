//
//		mul16c8u20c.v - Multiply Complex Number by Positive Scalar Value
//
//					  (C) Copyright 2007-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a serial multplier with two signed inputs and
// one common unsigned input. The inputs are all lached by IV and the
// output appears when OV is active 10 clock periods later. The output
// is signed with one sign bit and is not latched.
//
// 46 slices used. 213 MHz maximum clock rate.
//
// Normal Warnings:
//		Signals <px<0>> and <py<0>> are assigned but never used.
//
module mul16c8u20c(
    input [15:0] dix,	// signed multiplicands
    input [15:0] diy,
    input [7:0] diz,		// unsigned multiplier
    input iv,				// input valid
    output [19:0] dox,	// signed products
    output [19:0] doy,
    output ov,				// output valid
    input clk
    );
// internal signals
reg [9:1] v;		// delayed iv
reg [15:0] x,y;	// multiplicand latches
reg [7:0] z;		// multiplier shift register
reg [20:0] px,py;	// product shift registers (with carry bit)
// multiplier logic
always @ (posedge clk)
begin
	v <= {v[8:1],iv};		// delay data valid strobe
	if (iv) x <= dix;		// latch complex input
	if (iv) y <= diy;
	z <= iv ? diz : {1'b0,z[7:1]};	// load multiplier then shift right
	if (iv) px <= 0;		// zero products when inputs loaded
	else px <= {px[20],px[20:1]} + (z[0] ? {x[15],x,4'h0} : 21'h000000);
	if (iv) py <= 0;		// shift right and add if multiiplier bit one
	else py <= {py[20],py[20:1]} + (z[0] ? {y[15],y,4'h0} : 21'h000000);
end
// connect outputs			
assign dox = px[20:1];	// products
assign doy = py[20:1];
assign ov = v[9];		// output valid after 18 clock cycles
endmodule

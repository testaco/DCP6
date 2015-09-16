//
//		mul22c17u22c.v - Multiply Complex Number by Positive Scalar Value
//
//					  (C) Copyright 2007-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a serial multplier with two signed inputs and
// one common unsigned input. The inputs are all lached by IV and the
// output appears when OV is active 18 clock periods later. The output
// is signed with one sign bit and is not latched.
//
// 64 LUT6 and 108 registers used. 287 MHz maximum clock rate.
//
// History:
//		2011-11-16	create from mul18c17u18c
//
// Normal Warnings:
//		Signals <px<0>> and <py<0>> are assigned but never used.
//
module mul22c17u22c(
    input [21:0] dix,	// signed multiplicands
    input [21:0] diy,
    input [16:0] diz,	// unsigned multiplier
    input iv,				// input valid
    output [21:0] dox,	// signed products
    output [21:0] doy,
    output ov,				// output valid
    input clk
    );
// internal signals
reg [18:1] v;		// delayed iv
reg [21:0] x,y;	// multiplicand latches
reg [16:0] z;		// multiplier shift register
reg [22:0] px,py;	// product shift registers (with carry bit)
// multiplier logic
always @ (posedge clk)
begin
	v <= {v[17:1],iv};		// delay data valid strobe
	if (iv) x <= dix;			// latch complex input
	if (iv) y <= diy;
	z <= iv ? diz : {1'b0,z[16:1]};	// load multiplier then shift right
	if (iv) px <= 0;			// zero products when inputs loaded
	else px <= {px[22],px[22:1]} + (z[0] ? {x[21],x} : 23'h00000);
	if (iv) py <= 0;			// shift right and add if multiiplier bit one
	else py <= {py[22],py[22:1]} + (z[0] ? {y[21],y} : 23'h00000);
end
// connect outputs			
assign dox = px[22:1];	// products
assign doy = py[22:1];
assign ov = v[18];		// output valid after 18 clock cycles
endmodule

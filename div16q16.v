//
//			div16q16.v - Divide unsigned number by unsigned number
//
// 				(C) Copyright 2006-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// The dividend and divisor are loaded when IV and MOD are true. On each
// successive clock after IV is asserted, the divisor (B) is subtracted
// from the upper half of the dividend shift register (A) if the result
// will be positive. The result is shifted left by one bit and a one
// shifted into the quotient register (Q) if the subtraction succeeded.
// When the calculation is complete, Q contains the integer quotient
// and the most significant 16 bits of A contain the integer remainder.
// If IV is asserted with MOD low, the calculation continuues and 16
// fractional quotient bits are generated in Q. 
//
// Multiplexers are explicitly instantated to reduce the number of slices used.
//
// 49 LUTs and 64 registers used. 217 MHz maximum clock speed. 25 clock delay.
//
// Normal Warnings:
//		none
//
// Revision History:
//		12-8-10	eliminated truncation warning for bit counter in Spartan-6
//		12-23-10	use inferred adder/subtractor
//		3-22-12	modify for use outside CPU (CPU version is div16a)
//
module div16q16 (
    input [15:0] ain,bin,	// dividend and divisor input
    input iv,					// inputs valid
    output [15:0] qout,		// quotient
    output ov,					// quotient and remainder valid
	 input clk					// master clock
	 );
// Internal signals
wire[15:0] d;		// dividend less divisor
wire s;				// sign of above
reg [15:0] a;		// dividend shift register
reg [15:0] r;		// remainder shift register
reg [15:0] b;		// divisor register
reg [15:0] q;		// quotient register
reg [25:1] v;		// data valid delay
// control logic
always @ (posedge clk)
begin
	v <= {v[24:1],iv};	// data valid delay
	if (iv) b <= bin;		// load divisor register
end
// subtract divisor from shifted dividend
assign {s,d} = {r[15:0],a[15]} - {1'b0,b};
always @ (posedge clk)
begin
	if (iv) r <= 0;							// reset when dividend loaded
	else r <= s ? {r[14:0],a[15]} : d;	// ignore subtraction if result negative
	if (iv) a <= ain;							// load dividend register
	else a <= {a[14:0],1'b0};				// shift on every clock after load
	q <= {q[14:0],~s};						// shift in quotient bits on every clock
end
// connect output
assign qout = q;	// quotient
assign ov = v[25];
endmodule

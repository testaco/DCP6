//
//				div16a.v - Divide unsigned number by unsigned number
//
// 				(C) Copyright 2006-2008 John B. Stephensen
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
// S3E: 41 slices used. 160 MHz maximum clock speed. 17 clock delay.
// S6: 63 LUTs and 54 registers used. 165 MHz maximum clock speed. 17 clock delay. (MUX2X16S)
// S6: 62 LUTs and 59 registers used. 215 MHz maximum clock speed. 17 clock delay.
//
// Normal Warnings:
//		none
//
// Revision History:
//		12-8-10	eliminated truncation warning for bit counter in Spartan-6
//		12-23-10	use inferred adder/subtractor.
//
module div16a(ain, bin, mod, iv, qout, rout, ov, clk, rst);
    input [15:0] ain,bin;	// dividend and divisor input
	 input mod;					// 1=integer remainder, 0=fractional remainder
    input iv;					// inputs valid
    output [15:0] qout;		// quotient
    output [15:0] rout;		// remainder
    output ov;					// quotient and remainder valid
	 input clk;					// master clock
	 input rst;					// master reset
// Internal signals
wire[15:0] d;			// dividend less divisor
wire s;					// sign of above
reg [15:0] a;			// dividend shift register
reg [15:0] r;			// remainder shift register
//wire [15:0] a;			// dividend shift register
//wire [15:0] r;			// remainder shift register
reg [15:0] b;			// divisor register
reg [5:0] c;			// bit counter
wire nz;					// bit counter not zero
// control logic
always @ (posedge clk)
begin
	// bit counter 
	if (rst) c <= 0;
	else if (iv) c <= 16;				// set to word length
	else if (nz) c <= c - 6'b000001;	// then count down to 0
	// load divisor register
	if (iv & mod) b <= bin;
end
assign nz = |c;
// subtract divisor from shifted dividend
assign {s,d} = {r[14:0],a[15]} - b;
always @ (posedge clk)
begin
	if (iv & mod) r <= 0;	// reset when dividend loaded
	else if (nz) r <= s ? {r[14:0],a[15]} : d;	// ignore subtraction if result negative
	if (iv & ~mod) a <= 0;	// reset when dividend loaded
	else if (nz|iv) a <= nz ? {a[14:0],~s} : ain;	// select load or shift
end
// connect output
assign qout = a;	// quotient
assign rout = r;	// remainder
assign ov = ~nz;
endmodule

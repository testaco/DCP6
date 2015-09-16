//
//					sqrt16i16o.v - Square-Root Calulator with 16-bit I/O
//
//							(C) Copyright 2012 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-6 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
// This module computes the 16-bit square root of a 16-bit number in 16 clock cycles using the
// non-restoring algorithm. Every 2 bits of the input correspond to 1 bit of the output. The
// root (Q) is initialized to zero, then the remainder (R) is computed and the radicand (D) is
// shifted by two on each following clock cycle. The root (Q) is shifted by one on each clock
// cycle. A one is shifted in if there is no carry out from the add or subtract operation.
// Otherwise, a zero is shifted in. The adder/subtractor has two extra LSBs to implement logic
// using the two 2 MSBs of the radicand (D) and the current and previous values of the carry
// output. Processing takes 17 clock cycles and the output is not latched.
//
// 54 LUT6s and 50 registers are used. The maximum clock rate is 176 MHz.
//
module sqrt16i16o(
    input [15:0] din,	// radicand input
    input iv,				// input valid
    output [15:0] dout,	// root output (8-bit integer / 8-bit fraction)
	 output ov,				// output valid
    input clk				// master clock
    );
// internal signals
reg [17:1] v;	// data valid delay
reg [15:0] d;	// radicand (2n bits)
reg [15:0] q;	// root (n bits)
reg [17:0] r;	// remainder (n+2 bits)
wire [17:0] a;	// adder-subtractor
wire s;			// subtract
// logic
assign a = {r[15:0],d[15:14]} + (s ? ~{q,r[17],1'b1} : {q,r[17],1'b1}) + s;
assign s = ~r[17];
always @ (posedge clk)
begin
	v <= {v[16:1],iv};				// data valid delay
	if (iv) d <= din;					// load radicand
	else d <= {d[13:0],2'b00};		// shift left 2 bits every iteration
	if (iv) q <= 0;					// reset quotient 
	else q <= {q[14:0],~a[17]};	// add one bit every iteration
	if (iv) r <= 0;					// adder/subtractor latch
	else r <= a;
end
assign dout = q;		// root
assign ov = v[17];	// output valid
endmodule

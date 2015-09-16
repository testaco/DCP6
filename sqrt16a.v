//
//						 sqrt16a.v - Square-Root Calulator for ALU
//
//							(C) Copyright 2012 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-6 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
// This module computes the 16-bit square root of a 32-bit number in 16 clock cycles using the
// non-restoring algorithm. Every 2 bits of the input correspond to 1 bit of the output. The
// root (Q) is initialized to zero, then the remainder (R) is computed and the radicand (D) is
// shifted by two on each following clock cycle. The root (Q) is shifted by one on each clock
// cycle. A one is shifted in if there is no carry out from the add or subtract operation.
// Otherwise, a zero is shifted in. The adder/subtractor has two extra LSBs to implement logic
// using the two 2 MSBs of the radicand (D) and the current and previous values of the carry
// output.
//
// 62 LUT6s and 70 registers are used. The maximum clock rate is 176 MHz.
// 46 LUT6s and 54 registers are used if DL=0 and size=0.
//
// Normal Warnings:
//		node <r_16> is unconnected.
//
module sqrt16a(
    input [15:0] dh,dl,	// radicand inputs
	 input size,			// 0 = 16 MSB (LSB=0), 1 = 32-bit
    input iv,				// input valid
    output [15:0] qout,	// root
    output [15:0] rout,	// remainder
	 output ov,				// output valid
    input clk,				// master clock
    input rst				// master reset
    );
// internal signals
reg [4:0] c;	// counter
reg [31:0] d;	// radicand (2n bits)
reg [15:0] q;	// root (n bits)
reg [17:0] r;	// remainder (n+2 bits)
wire [17:0] a;	// adder-subtractor
wire s;			// subtract
wire nz;			// counter is zero
// logic
assign nz = |c;	// counter is zero if no bits are one
assign a = {r[15:0],d[31:30]} + (s ? ~{q,r[17],1'b1} : {q,r[17],1'b1}) + s;
assign s = ~r[17];
always @ (posedge clk)
begin
	if (rst) c <= 0;						// iteration counter
	else if (iv) c <= 16;				// initialize when radicand loaded
	else if (nz) c <= c - 1'b1;		// count down to zero
	if (iv) d <= {dh,(size ? dl : 16'h0000)};	// load radicand
	else if (nz) d <= {d[29:0],2'b00};	// shift left 2 bits every iteration
	if (iv) q <= 0;						// reset quotient 
	else if (nz) q <= {q[14:0],~a[17]};	// add one bit every iteration
	if (iv) r <= 0;						// adder/subtractor latch
	else if (nz) r <= a;
end
assign qout = q;			// root
assign rout = r[15:0];	// remainder
assign ov = ~nz;			// zero while busy computing
endmodule

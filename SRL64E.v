//
//					64-bit Adjustable-length Shift register
//
//					(C) Copyright 2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module SRL64E(Q,D,A,CE,CLK);
    output Q;
    input D;
    input [5:0] A;
    input CE;
    input CLK;
// 2 shift registers and 1 multiplexer
wire q31;	// inter-SRLC32E	bit
wire qa,qb;	// SRLC32E outputs
SRLC32E sr0 (.D(D), .A(A[4:0]), .Q(qa), .Q31(q31), .CE(CE), .CLK(CLK));
SRLC32E sr1 (.D(q31), .A(A[4:0]), .Q(qb), .Q31(), .CE(CE), .CLK(CLK));
MUXF7 mux (.I0(qa), .I1(qb), .S(A[5]), .O(Q));
endmodule

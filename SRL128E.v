//
//					128-bit Adjustable-length Shift register
//
//					(C) Copyright 2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module SRL128E(Q,D,A,CE,CLK);
    output Q;
    input D;
    input [6:0] A;
    input CE;
    input CLK;
// 4 shift registers and 3 multiplexers
wire q31,q63,q95;	// inter-SRLC32E	bits
wire qa,qb,qc,qd;	// SRLC32E outputs
SRLC32E sr0 (.D(D), .A(A[4:0]), .Q(qa), .Q31(q31), .CE(CE), .CLK(CLK));
SRLC32E sr1 (.D(q31), .A(A[4:0]), .Q(qb), .Q31(q63), .CE(CE), .CLK(CLK));
SRLC32E sr2 (.D(q63), .A(A[4:0]), .Q(qc), .Q31(q95), .CE(CE), .CLK(CLK));
SRLC32E sr3 (.D(q95), .A(A[4:0]), .Q(qd), .Q31(), .CE(CE), .CLK(CLK));
wire qab,qcd;	// inter-MUX bits
MUXF7_L mux0 (.I0(qa), .I1(qb), .S(A[5]), .LO(qab));
MUXF7_L mux1 (.I0(qc), .I1(qd), .S(A[5]), .LO(qcd));
MUXF8 mux2 (.I0(qab), .I1(qcd), .S(A[6]), .O(Q));
endmodule

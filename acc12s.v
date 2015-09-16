//
//							acc12s.v - 12-bit accumulator
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This accumulator support loading the input, loading the 2's complement
// of the input, adding to or subtracting from the current value.
//
//		ACC	SUB	Operation
//		 0		 0		A = B
//		 0		 1		A = -B
//		 1		 0		A = A - B
//		 1		 1		A = A + B
//
// Inference is used as instantiation produces an extra level of logic in Spartan-6.
//
module acc12s (
    input SUB,
	 input ACC,
    input [11:0] B,
    output [11:0] Q,
	 output CO,
    input CLK,
	 input CE,
	 input SCLR
    );
// internal signals
reg [12:0] S;	// 12-bit sum plus carry out
// infer adder/subtractors with AND gates on A inputs
always @ (posedge CLK)
begin
	if (SCLR) S <= 0;
	if (CE) S <= (ACC ? S : 12'h0000) + (SUB ? ~B : B) + SUB;
end
// connect outputs
assign Q = S[11:0];
assign CO = S[12];
endmodule

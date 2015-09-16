//
//						addsub24s.v - 24-bit adder/subtracter
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This implementation uses a LUT2 as a half adder followed by MUXCY to
// implement ripple carry and XORCY to complete a full adder.
//
// 24 LUTs and 24 registers used.
//
// History:
//		12-27-10	infer add/sub for Spartan-6
//
module addsub24s(
    input SUB,
    input [23:0] A,
    input [23:0] B,
    output [23:0] Q,
	 input CE,
	 input CLK,
	 input RST
    );
// internal signals
reg [23:0] s;	// sum or difference
// logic
always @ (posedge CLK)
begin
	if (RST) s <= 0;
	else if (CE) s <= A + (SUB ? ~B : B) + SUB;
end
assign Q = s;
endmodule

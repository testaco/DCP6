//
//						tc16a.v - 16-bit true/complement logic
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 16 LUTs used. Infer adder/subtractor for Spartan-6.
//
module tc16a (
    input [15:0] D,
    input CMP,
    output [15:0] Y
    );
// internal signals
assign Y = (CMP ? ~D : D) + CMP;
endmodule

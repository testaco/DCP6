//
//						tc8s.v - 16-bit true/complement logic
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 8 LUTs and 8 registers used. Infer adder/subtractor for Spartan-6.
//
module tc8s (
    input [7:0] D,
    input CMP,
    output [7:0] Q,
	 input CE,
	 input CLK,
	 input SCLR
    );
// internal signals
reg [7:0] s;
always @ (posedge CLK)
begin
	if (SCLR) s <= 0;
	else if (CE) s <= (CMP ? ~D : D) + CMP;
end
assign Q = s;
endmodule

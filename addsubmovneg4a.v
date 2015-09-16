//
//					 addsubmovneg4a.v - 4-bit adder-subtractor
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 8 LUT5s are used. The H LUT implements the XOR gate for the half adder
// and the G LUT implements the AND gate for the carry output.
//
//		I3	I2	I1 I0	O	O
//		EA	SU	B	A	g	h
//		0	0	0	0	0	0	MOV B
//		0	0	0	1	0	0
//		0	0	1	0	0	1
//		0	0	1	1	0	1
//		0	1	0	0	0	1	NEG B
//		0	1	0	1	0	1
//		0	1	1	0	0	0
//		0	1	1	1	0	0
//		1	0	0	0	0	0	ADD A+B
//		1	0	0	1	0	1
//		1	0	1	0	0	1
//		1	0	1	1	1	0
//		1	1	0	0	0	1	SUB A-B
//		1	1	0	1	1	0
//		1	1	1	0	0	0
//		1	1	1	1	0	1
//
module addsubmovneg4a(
	 input SUB,
    input ENA,
	 input [3:0] A,
    input [3:0] B,
    input CI,
    output CO,
    output [3:0] Y
    );
// internal signals
wire [3:0] h;	// half-adder outputs
wire [3:0] g;	// adder carry outputs
wire [3:0] c;	// carry chain taps
// arithmetic logic
LUT5_L #(.INIT(32'hAA002800)) lutg0 (.I0(A[0]), .I1(B[0]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(g[0]));
LUT5_L #(.INIT(32'h963C963C)) luth0 (.I0(A[0]), .I1(B[0]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(h[0]));
LUT5_L #(.INIT(32'hAA002800)) lutg1 (.I0(A[1]), .I1(B[1]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(g[1]));
LUT5_L #(.INIT(32'h963C963C)) luth1 (.I0(A[1]), .I1(B[1]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(h[1]));
LUT5_L #(.INIT(32'hAA002800)) lutg2 (.I0(A[2]), .I1(B[2]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(g[2]));
LUT5_L #(.INIT(32'h963C963C)) luth2 (.I0(A[2]), .I1(B[2]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(h[2]));
LUT5_L #(.INIT(32'hAA00AA00)) lutg3 (.I0(A[3]), .I1(B[3]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(g[3]));
LUT5_L #(.INIT(32'h963C963C)) luth3 (.I0(A[3]), .I1(B[3]), .I2(SUB), .I3(ENA), .I4(1'b0), .LO(h[3]));
CARRY4 cy (.S(h), .DI(g), .CYINIT(1'b0), .CI(CI), .CO(c), .O(Y));
assign CO = c[3];
endmodule

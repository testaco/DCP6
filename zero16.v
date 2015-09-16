//
//					zero16.v - 16-bit Fast Zero Detection Logic
//
//					(C) Copyright 2007-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This implementation uses carry multiplexers to detect a value of zero on the inpuut.
//
module zero16(
	 input [15:0] A,
    output Y
    );
// internal signals
wire [3:0] b;	// carry logic inputs are LUT6 outputs or one
wire [3:0] c;	// carry logic outputs
// Use each LUT as 6-bit zero-detect
LUT6_L #(.INIT(64'h0000000000000001)) lut0 (.I0(A[0]), .I1(A[1]), .I2(A[2]), .I3(A[3]), .I4(A[4]), .I5(A[5]), .LO(b[0]));
LUT6_L #(.INIT(64'h0000000000000001)) lut1 (.I0(A[6]), .I1(A[7]), .I2(A[8]), .I3(A[9]), .I4(A[10]), .I5(A[11]), .LO(b[1]));
LUT6_L #(.INIT(64'h0000000000000001)) lut2 (.I0(A[12]), .I1(A[13]), .I2(A[14]), .I3(A[15]), .I4(1'b0), .I5(1'b0), .LO(b[2]));
// carry logic - selects DI when S=0 and carry chain when S=1
// propagate 1 to CO if all select inputs 1
assign b[3] = 1'b1;	// unused input must propagate carry
CARRY4 cy (.S(b), .DI(4'h0), .CYINIT(1'b1), .CI(), .CO(c), .O());
assign Y = c[2];		// third carry output is result
endmodule

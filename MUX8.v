//
//						8-Input Multiplxer using 2 LUT6s
//
//					(C) Copyright 2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 2 LUT6s form 2 4-input multiplexers and are combined with a dedicated multiplexer. 
//
module MUX8(D, S, Y);
    input [7:0] D;	// data inputs
    input [2:0] S;	// select
    output Y;			// data output
// internal signals
wire y0,y1;	// outputs of LUTs
// internal logic - use LUT local outputs and MUX local inputs
LUT6_L #(.INIT(64'hFF00F0F0CCCCAAAA)) lut0 (.I0(D[0]), .I1(D[1]), .I2(D[2]), .I3(D[3]), .I4(S[0]), .I5(S[1]), .LO(y0));
LUT6_L #(.INIT(64'hFF00F0F0CCCCAAAA)) lut1 (.I0(D[4]), .I1(D[5]), .I2(D[6]), .I3(D[7]), .I4(S[0]), .I5(S[1]), .LO(y1));
MUXF7 mux (.I0(y0), .I1(y1), .S(S[2]), .O(Y));
endmodule

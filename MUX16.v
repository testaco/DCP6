//
//						16-Input Multiplxer using 4 LUT6s
//
//					(C) Copyright 2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// 4 LUT6s form 4 4-input multiplexers and are combined with 3 dedicated multiplexers. 
//
module MUX16(D, S, Y);
    input [15:0] D;	// data inputs
    input [3:0] S;	// select
    output Y;			// data output
// internal signals
wire y0,y1,y2,y3,y01,y23;	// outputs of LUTs
// internal logic - use LUT local outputs and MUX local inputs
LUT6_L #(.INIT(64'hFF00F0F0CCCCAAAA)) lut0 (.I0(D[0]), .I1(D[1]), .I2(D[2]), .I3(D[3]), .I4(S[0]), .I5(S[1]), .LO(y0));
LUT6_L #(.INIT(64'hFF00F0F0CCCCAAAA)) lut1 (.I0(D[4]), .I1(D[5]), .I2(D[6]), .I3(D[7]), .I4(S[0]), .I5(S[1]), .LO(y1));
LUT6_L #(.INIT(64'hFF00F0F0CCCCAAAA)) lut2 (.I0(D[8]), .I1(D[9]), .I2(D[10]), .I3(D[11]), .I4(S[0]), .I5(S[1]), .LO(y2));
LUT6_L #(.INIT(64'hFF00F0F0CCCCAAAA)) lut3 (.I0(D[12]), .I1(D[13]), .I2(D[14]), .I3(D[15]), .I4(S[0]), .I5(S[1]), .LO(y3));
MUXF7_L mux0 (.I0(y0), .I1(y1), .S(S[2]), .LO(y01));
MUXF7_L mux1 (.I0(y2), .I1(y3), .S(S[2]), .LO(y23));
MUXF8 mux2 (.I0(y01), .I1(y23), .S(S[3]), .O(Y));
endmodule

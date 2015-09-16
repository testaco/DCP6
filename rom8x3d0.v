//
//		rom8x3d0 - 3-bit 8-entry ROM with Distance Squared for 8PSK
//
//					(C) Copyright 2006-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//		A2	A1	A0	Q2	Q1	Q0
//		0	0	0	0	0	0
//		0	0	1	0	0	1
//		0	1	0	0	1	1
//		0	1	1	1	0	1
//		1	0	0	1	1	0
//		1	0	1	1	0	1
//		1	1	0	0	1	1
//		1	1	1	0	0	1
//
// This ROM contains the distance squared for 8 phase offsets from 0 degrees.
//
module rom8x3d0(
    input [2:0] a,	// phase, in 45-degree increments
    output [2:0] q,	// distance from 0 degrees
    input clk,			// clock for output register
	 input ce,			// enable output register
	 input rst			// reset output register
    );
// internal signals
wire y0,y1,y2;	// LUT outputs
// Define LUT contents
LUT5_L #(.INIT(32'h000000EE)) lut0 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(1'b0), .I4(1'b0), .LO(y0));
LUT5_L #(.INIT(32'h00000054)) lut1 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(1'b0), .I4(1'b0), .LO(y1));
LUT5_L #(.INIT(32'h00000038)) lut2 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(1'b0), .I4(1'b0), .LO(y2));
// hook up output registers
FDCE ff0 (.D(y0), .C(clk), .CE(ce), .CLR(rst), .Q(q[0]));
FDCE ff1 (.D(y1), .C(clk), .CE(ce), .CLR(rst), .Q(q[1]));
FDCE ff2 (.D(y2), .C(clk), .CE(ce), .CLR(rst), .Q(q[2]));
endmodule

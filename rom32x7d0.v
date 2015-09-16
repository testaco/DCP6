//
//							rom32x7d0 - 7-bit 32-entry ROM  
//
//					(C) Copyright 2006-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This ROM stores the distance from the received signal to zero. The input is the
// phase of the incoming signal relative to the desired constellation point. The
// distance is proportional to power required to shift the signal from zero to the
// received phase (assuming constant magnitude) as follows:
//	PSK offset 0 11 22 34 45 56 68 79 90 101 113 124 135 146 158 169 180 (+/- degrees)
//	  distance 0  1  4  9 15 23 32 42 52  62  72  81  89  95 100 103 104
//           00 01 04 09 0F 17 20 2A 34  3E  48  51  59 	5F  64  67  68
//
// The contents of the 7 32-bit ROMs are:
//
//    3 3 2 2  2 2 2 2  2 2 2 2  1 1 1 1  1 1 1 1  1 1
//    1 0 9 8  7 6 5 4  3 2 1 0  9 8 7 6  5 4 3 2  1 0 9 8  7 6 5 4  3 2 1 0
//
// 6  0 0 0 0  0 0 0 0  0 1 1 1  1 1 1 1  1 1 1 1  1 1 0 0  0 0 0 0  0 0 0 0
// 5  0 0 0 0  0 1 1 1  1 0 0 0  0 1 1 1  1 1 0 0  0 0 1 1  1 1 0 0  0 0 0 0
// 4  0 0 0 0  1 0 0 1  1 0 1 1  1 0 0 0  0 0 1 1  1 0 1 1  0 0 1 0  0 0 0 0
// 3  0 0 1 1  0 0 1 0  1 1 0 1  1 0 0 1  0 0 1 1  0 1 1 0  1 0 0 1  1 0 0 0
// 2  0 1 0 1  1 0 0 1  1 0 0 0  1 1 1 0  1 1 1 0  0 0 1 1  0 0 1 1  0 1 0 0
// 1  0 0 0 1  1 0 1 0  1 0 0 0  1 0 1 0  1 0 1 0  0 0 1 0  1 0 1 1  0 0 0 0
// 0  1 0 1 1  1 0 0 0  0 0 1 1  1 0 1 0  1 0 1 1  1 0 0 0  0 0 1 1  1 0 1 0
//
// 7 slices are used.
//
module rom32x7d0(
    input [4:0] a,
    output [6:0] q,
    input clk,
    input ce,
    input rst
    );
// internal signals
wire [6:0] d;
// Seven 32-bit ROMs are used
LUT5_L #(.INIT(32'h007FFC00)) rom6 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(a[3]), .I4(a[4]), .LO(d[6]));
LUT5_L #(.INIT(32'h0787C3C0)) rom5 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(a[3]), .I4(a[4]), .LO(d[5]));
LUT5_L #(.INIT(32'h09B83B20)) rom4 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(a[3]), .I4(a[4]), .LO(d[4]));
LUT5_L #(.INIT(32'h32D93698)) rom3 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(a[3]), .I4(a[4]), .LO(d[3]));
LUT5_L #(.INIT(32'h598EE334)) rom2 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(a[3]), .I4(a[4]), .LO(d[2]));
LUT5_L #(.INIT(32'h1A8AA2B0)) rom1 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(a[3]), .I4(a[4]), .LO(d[1]));
LUT5_L #(.INIT(32'hB83AB83A)) rom0 (.I0(a[0]), .I1(a[1]), .I2(a[2]), .I3(a[3]), .I4(a[4]), .LO(d[0]));
// hook up output registers
FDCE ff0 (.D(d[0]), .C(clk), .CE(ce), .CLR(rst), .Q(q[0]));
FDCE ff1 (.D(d[1]), .C(clk), .CE(ce), .CLR(rst), .Q(q[1]));
FDCE ff2 (.D(d[2]), .C(clk), .CE(ce), .CLR(rst), .Q(q[2]));
FDCE ff3 (.D(d[3]), .C(clk), .CE(ce), .CLR(rst), .Q(q[3]));
FDCE ff4 (.D(d[4]), .C(clk), .CE(ce), .CLR(rst), .Q(q[4]));
FDCE ff5 (.D(d[5]), .C(clk), .CE(ce), .CLR(rst), .Q(q[5]));
FDCE ff6 (.D(d[6]), .C(clk), .CE(ce), .CLR(rst), .Q(q[6]));
endmodule

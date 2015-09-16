//
//			acs8x4x16.v - 8-State 4-Path 16-Bit Add-Compare-Select Module
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module contains takes distances from the actual signal to possible signal
// constellation points, adds then to accumulated distances corresponding to possible
// previous states and selects the path with the shortest accumulated distance.
//
// Note: Can eliminate seven 5-bit adders by making ROM for each constellation point.
//
// 1355 LUT6 (9%) and 202 registers used. Maximum clock rate is 109 MHz. 2 clock delay.
// 
module acs8x4x16(
    input [4:0] r,	// received signal
	 input iv,			// input valid
    output [1:0] p0,	// p0[2]=0 most likely previous states
	 output [1:0] p1,	// p1[2]=0 for each possible new state
	 output [1:0] p2,	// p2[2]=1
	 output [1:0] p3,	// p3[2]=1
	 output [1:0] p4,	// p4[2]=0
	 output [1:0] p5,	// p5[2]=0
	 output [1:0] p6,	// p6[2]=1
	 output [1:0] p7,	// p7[2]=1
    output ov,			// output valid
	 input clk,
	 input rst
    );
// Internal Signals
wire [6:0] r0,r1,r2,r3,r4,r5,r6,r7;		// distances from constellation points
wire [15:0] m0,m1,m2,m3,m4,m5,m6,m7;	// accumulated path metrics
reg [2:1] v;									// data valid
// delay clock enable
always @ (posedge clk) v <= {v[1],iv};
// Compute signal distances from each possible constellation point
rom32x7d0 rom0 (r,r0,clk,iv,1'b0);	// don't reset ROM outputs
rom32x7d0 rom1 (r-5'd4,r1,clk,iv,1'b0);
rom32x7d0 rom2 (r-5'd8,r2,clk,iv,1'b0);
rom32x7d0 rom3 (r-5'd12,r3,clk,iv,1'b0);
rom32x7d0 rom4 (r-5'd16,r4,clk,iv,1'b0);
rom32x7d0 rom5 (r-5'd20,r5,clk,iv,1'b0);
rom32x7d0 rom6 (r-5'd24,r6,clk,iv,1'b0);
rom32x7d0 rom7 (r-5'd28,r7,clk,iv,1'b0);
// Compute shortest paths to each new state using BICM8 with gray encoding
acs4x16 acs0 (r0,m0,r4,m1,r6,m2,r2,m3,p0,m0,v[1],clk,rst);
acs4x16 acs1 (r6,m0,r2,m1,r0,m2,r4,m3,p1,m1,v[1],clk,rst);
acs4x16 acs2 (r7,m4,r3,m5,r1,m6,r5,m7,p2,m2,v[1],clk,rst);
acs4x16 acs3 (r1,m4,r5,m5,r7,m6,r3,m7,p3,m3,v[1],clk,rst);
acs4x16 acs4 (r4,m0,r0,m1,r2,m2,r6,m3,p4,m4,v[1],clk,rst);
acs4x16 acs5 (r2,m0,r6,m1,r4,m2,r0,m3,p5,m5,v[1],clk,rst);
acs4x16 acs6 (r3,m4,r7,m5,r5,m6,r1,m7,p6,m6,v[1],clk,rst);
acs4x16 acs7 (r5,m4,r1,m5,r3,m6,r7,m7,p7,m7,v[1],clk,rst);
// connect output valid
assign ov = v[2];
endmodule

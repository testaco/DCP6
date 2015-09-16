//
//				acs4x16.v - 4-Path 16-Bit Add-Compare-Select Module
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module contains takes 4 distances from the actual signal to possible signal
// constellation points, adds then to accumulated distances corresponding to possible
// previous states and selects the path with the shortes accumulated distance.
//
// 153 LUT6 and 18 registers used.
// 
module acs4x16(
    input [6:0] s0,	// actual signal distance from expected signal
    input [15:0] d0,	// accumulated distance for previous state
    input [6:0] s1,
    input [15:0] d1,
    input [6:0] s2,
    input [15:0] d2,
    input [6:0] s3,
    input [15:0] d3,
    output [1:0] s,	// most likely previous state
    output [15:0] d,	// accumulated distance to that state
	 input ce,
	 input clk,
	 input rst
    );
// Internal Signals
wire [15:0] pd0,pd1,pd2,pd3;	// distances for each path
wire [15:0] pd01,pd23;			// multiplexed distances
reg [15:0] pd;						// selected path distance
wire ps1,ps3,ps23;				// path select lines
reg [1:0] pst;						// selected previous state
// Calculate possible path distances
assign pd0 = d0 + {9'b000000000,s0};
assign pd1 = d1 + {9'b000000000,s1};
assign pd2 = d2 + {9'b000000000,s2};
assign pd3 = d3 + {9'b000000000,s3};
// Compare distances
assign ps1 = pd1 < pd0;
assign ps3 = pd3 < pd2;
assign ps23 = pd23 < pd01;
// Intermediate selections
assign pd01 = ps1 ? pd1 : pd0;
assign pd23 = ps3 ? pd3 : pd2;
// Select path
always @ (posedge clk)
begin
	if (rst) pd <= 0;
	else if (ce) pd <= ps23 ? pd23 : pd01;
	if (rst) pst <= 0;
	else if (ce) pst <= {ps23,ps23 ? ps3 : ps1};
end
// connect outputs
assign d = pd;		// distance for new state
assign s = pst;	// previous state
endmodule

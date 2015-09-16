//
//				bp437enc4.v - (4,3,7) Berlekamp-Preparata Encoder
//
//						(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements encoding for a (4,3,7) Berlekamp-Preparata code
// with 4-way interleaving that is able to detect and correct phased bursts
// of 16 errors releative to a guard space of 112 bits. It is a rate 3/4
// convolutional code. There is no delay in the encoding process. 
//
// 7 slices used. 249 MHz max.
//
module bp437enc4 (
	input [2:0] u,		// uncoded data input
	output [3:0] v,	// encoded output
	input ce,			// clock enable
	input clk			// master clock
	);
// internal signals
reg [27:0] s;	// encoder state
// generate parity
always @ (posedge clk)
begin
	if (ce) s[3:0] <= {s[2:0],u[0]^u[1]^u[2]};
	if (ce) s[7:4] <= {s[6:4],s[3]^u[0]^u[1]};
	if (ce) s[11:8] <= {s[10:8],s[7]^u[0]};
	if (ce) s[15:12] <= {s[14:12],s[11]};
	if (ce) s[19:16] <= {s[18:16],s[15]^u[0]};
	if (ce) s[23:20] <= {s[22:20],s[19]^u[1]};
	if (ce) s[27:24] <= {s[26:24],(s[23]^u[2])};
end
assign v = {s[27],u};
endmodule

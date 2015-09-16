//
//				bp437dec4.v - (4,3,7) Berlekamp-Preparata Decoder
//
//						(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements decoding for a (4,3,7) Berlekamp-Preparata code
// with 4-way interleaving that is able to detect and correct phased bursts
// of 16 errors releative to a guard space of 112 bits. It is a rate 3/4
// convolutional code. There is a 28 clock delay in the decoding process. 
//
// 26 slices used. 242 MHz max.
//
module bp437dec4 (
	input [3:0] r,		// received data and parity input
	output [2:0] d,	// data output
	input ce,			// clock enable
	input clk			// master clock
	);
// internal signals
reg [28:1] r0,r1,r2;	// received data bits
wire s0;					// XOR of received data bits and parity bit
reg [24:1] s;			// syndrome
wire f;					// feedback for syndrome generation
wire e0,e1,e2;			// error flags
// decode data
assign s0 = r[3]^r2[4]^r1[8]^r0[12]^r0[20]^r0[24]^r1[24]^r0[28]^r1[28]^r2[28];
always @ (posedge clk)
begin
	if (ce) r0 <= {r0[27:1],r[0]};			// buffer data
	if (ce) r1 <= {r1[27:1],r[1]};
	if (ce) r2 <= {r2[27:1],r[2]};
	if (ce) s[4:1] <= {s[3:1],s0 & f};		// generate syndrome and
	if (ce) s[8:5] <= {s[7:5],s[4] & f};	// reset when error detected
	if (ce) s[12:9] <= {s[11:9],s[8] & f};
	if (ce) s[16:13] <= {s[15:13],s[12] & f};
	if (ce) s[20:17] <= {s[19:17],s[16] & f};
	if (ce) s[24:21] <= {s[23:21],s[20] & f};
end
// reset syndrome when error corrected
assign f = (s[8]^s[16])|s[12]|(s[4]^s[16]^s[20])|(s0^s[16]^s[20]^s[24]);
// generate error signals for each data bit
assign e0 = s[16] & ~f;	
assign e1 = s[20] & ~f;
assign e2 = s[24] & ~f;
// correct received data at output of shift register
assign d[0] = r0[28] ^ e0;
assign d[1] = r1[28] ^ e1;
assign d[2] = r2[28] ^ e2;
endmodule

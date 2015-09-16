//
//				shift24i55o.v - Shift 24-bit Input Left by 0 to 31 Bits
//
//					  (C) Copyright 2007-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements a shifter to multiply the input by 1 to 2^31.
//
// 158 LUTs and 78 registers are used. The maximum clock frequency is 454 MHz.
//
module shift24i55o(
	input [23:0] d,	// data input
	output [54:0] q,	// data output
	input [4:0] n,		// number of bits to shift left
	input clk			// master clock
	);
// internal signals
reg [4:2] n1;			// delayed shift value
reg n4;
reg [25:0] shift1;	// shift 0,1,2,3 bits (24->27)
reg [37:0] shift4;	// shift 0,4,8,12 bits (27->39)
reg [53:0] shift16;	// shift 0,16 bits (39->55)
reg s1,s4,s16;			// sign bits
// Shift a 24-bit input left by 0 to 31 bits for a 55-bit output with 3 clock delay.
// The first multiplexer shifts in 1 bit increments, the second in 4 bit increments
// and the third in 16-bit increments. The most significant bit is not shifted.
always @ (posedge clk)
begin
	case (n[1:0])
	2'b00: shift1 <= {d[23],d[23],d[23],d[22:0]};
	2'b01: shift1 <= {d[23],d[23],d[22:0],1'b0};
	2'b10: shift1 <= {d[23],d[22:0],2'b00};
	2'b11: shift1 <= {d[22:0],3'b00};
	default: shift1 <= 26'hxxxxxxx;
	endcase
	s1 <= d[23];
	n1 <= n[4:2];
end
always @ (posedge clk)
begin
	case (n1[3:2])
	2'b00: shift4 <= {s1,s1,s1,s1,s1,s1,s1,s1,s1,s1,s1,s1,shift1};
	2'b01: shift4 <= {s1,s1,s1,s1,s1,s1,s1,s1,shift1,4'h0};
	2'b10: shift4 <= {s1,s1,s1,s1,shift1,8'h00};
	2'b11: shift4 <= {shift1,12'h000};
	default: shift4 <= 38'hxxxxxxxxxx;
	endcase
	s4 <= s1;
	n4 <= n1[4];
end
always @ (posedge clk)
begin
	case (n4)
	1'b0: shift16 <= {s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,s4,shift4};
	1'b1: shift16 <= {shift4,16'h0000};
	default: shift16 <= 54'hxxxxxxxxxxxxxx;
	endcase
	s16 <= s4;
end
// connect output
assign q = {s16,shift16};
endmodule

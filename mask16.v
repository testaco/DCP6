//
//							mask16.v - Create 16 Bit Mask
//
//					(C) Copyright 2007-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module selects the 0-15 rightmost bits out of 16 bits. 16-1 of the
// leftmost bits are zeroed. Bit 15 is to the left and bit 0 to the right.
//
// 14 slices used.
//
module mask16(
    input [3:0] c,	// select bit C or C bits
	 input s,			// 1 = select bit, 0 = mask bits
    output [15:0] m	// bit mask
    );
// generate mask
assign m[0] = s ? (c == 0) : (c > 0);
assign m[1] = s ? (c == 1) : (c > 1);
assign m[2] = s ? (c == 2) : (c > 2);
assign m[3] = s ? (c == 3) : (c > 3);
assign m[4] = s ? (c == 4) : (c > 4);
assign m[5] = s ? (c == 5) : (c > 5);
assign m[6] = s ? (c == 6) : (c > 6);
assign m[7] = s ? (c == 7) : (c > 7);
assign m[8] = s ? (c == 8) : (c > 8);
assign m[9] = s ? (c == 9) : (c > 9);
assign m[10] = s ? (c == 10) : (c > 10);
assign m[11] = s ? (c == 11) : (c > 11);
assign m[12] = s ? (c == 12) : (c > 12);
assign m[13] = s ? (c == 13) : (c > 13);
assign m[14] = s ? (c == 14) : (c > 14);
assign m[15] = s ? (c == 15) : 1'b0;
endmodule

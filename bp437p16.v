//
//						bp437p16.v - 16 Berlekamp-Preparata CODECs
//
//						(C) Copyright 2011-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements encoding and decoding for a (4,3,7) Berlekamp-Preparata code
// that is able to detect and correct phased bursts of 4 errors releative to a guard
// space of 28 bits. It is a rate 3/4 convolutional code. 4-way interleaving is then
// used to allow for 16-bit bursts.
//
// There are 2 output ports to write bytes to be encoded or words to be decoded:
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |               |                 Uncoded Data                  | 
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                         Received Data                         | 
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// There are 2 input ports to read encoded bits for transmission or corrected bits
// on reception:
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |                          Encoded Data                         |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |               |                 Decoded Data                  | 
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// When transmitting, use one write to supply 12 bits of uncoded data and then one read
// to retreive four 4-bit encoded symbols. The least significant 3 data bits plus parity
// are in the lower bits and the most significant 3 bits and parity in the upper bits.
//	The state may be reset by writing 28 zero-valued data words.
//
// When receiving, write 16 bits (four 4-bit symbols) and then read the decoded 12 bits
// of data. Bits 2-0 contain the first symbol and bits 11-9 contain the last symbol.
// There is a 28 word delay. The state may be reset by writing 28 zero-valued words.
//
// 174 LUT6s and 285 registers used. 401 MHz max. (bp437p4 +54% LUT6s & +29% regs.)
//
// Normal Warnings:
//		Input <ioaddr<2:1>> is never used.
//
module bp437p16 (
	input iocs,				// select this module
	input [2:0] ioaddr,	// address registers in this module
	input [15:0] din,		// uncoded data input
	output [15:0] dout,	// encoded output
	input iord,				// read register
	input iowr,				// write register
	input clk				// master clock
	);
// internal signals
wire w0,w1;			// write enables
wire [15:0] c0;	// encoded data
reg [15:0] c;		// encoded data register
wire [11:0] d0;	// decoded data
reg [11:0] d;		// decoded data register
reg [15:0] omux;	// output multiplexer
// decode addresses
assign w0 = iocs & iowr & ~ioaddr[0];	// transmit data
assign w1 = iocs & iowr & ioaddr[0];	// received data
// write 12 bits for encoding then read 16-bit encoded symbols
bp437enc4 enc0 (.u(din[2:0]), .v(c0[3:0]), .ce(w0), .clk(clk));
bp437enc4 enc1 (.u(din[5:3]), .v(c0[7:4]), .ce(w0), .clk(clk));
bp437enc4 enc2 (.u(din[8:6]), .v(c0[11:8]), .ce(w0), .clk(clk));
bp437enc4 enc3 (.u(din[11:9]), .v(c0[15:12]), .ce(w0), .clk(clk));
// write 16 bits and then read 12-bit result with 28 clock cycle delay
bp437dec4 dec0 ( .r(din[3:0]), .d(d0[2:0]), .ce(w1), .clk(clk));
bp437dec4 dec1 ( .r(din[7:4]), .d(d0[5:3]), .ce(w1), .clk(clk));
bp437dec4 dec2 ( .r(din[11:8]), .d(d0[8:6]), .ce(w1), .clk(clk));
bp437dec4 dec3 ( .r(din[15:12]), .d(d0[11:9]), .ce(w1), .clk(clk));
always @ (posedge clk)
begin
	if (w0) c <= c0;	// latch encoder output
	if (w1) d <= d0;	// latch decoder output
	if (iord) omux <= ioaddr[0] ? {4'h0,d} : c;
end
// connect outputs
assign dout = omux;
endmodule

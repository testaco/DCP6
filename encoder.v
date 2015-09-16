//
//							Convolutional Encoder 		
//
//				(C) Copyright 2005-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module provides a convolutional encoder as an I/O device. Writes to
// port 0 cause the 1-2 bits of the input to be encoded into 1 or 2 words.
// The output may be read from port 0 or 1 and consists of magnitude in the
// upper byte and phase in the lower byte. Port 0 may contain 8PSK, QPSK, or
// BPSK, depending on configuration. Port 1 contains BPSK.
//
// The encoder has 0-16 states. State register S0 has 4 bits to allow 16
// states for a 1-bit unencoded data input. State register S1 has 2 bits that
// may be combined with the first 2 bits from S0 to provide 16 states for a
// 2-bit unencoded data input. The state registers may be reset by inputting
// 1-4 zero-valued bits or 1-2 zero-valued dibits.
//
// The 4 coded output bits, C0-C3, that are formed by exclsive-OR'ing the
// unencoded input bits and state bits in any combination selected by the
// configuration bytes previously written to ports 4, 5, 6 and 7 for coded
// output bits C[0], C[1], C[2] and C[3], respectively. The configuration
// bytes are formatted as follows:
//
//		  7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+
// 	|U1 |S10|S11|U0 |S00|S01|S02|S03|
//		+---+---+---+---+---+---+---+---+
//
// U0 and U1 enable use of the unencoded data bits in the encoding process
// for the specified output bit. S00, S01, S02 and S03 select the preceeding
// stored values of data bit 0 and S10 and S11 select the stored values of
// data bit 1. All are exclusive-OR'ed together.
//
// There are 6 output ports with 1 for data and 1 each for specifying the encoding
// of each output bit:
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |                                                       |U1 |U0 | Data
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                               |   Magnitude   |               | Magnitude
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |                               |U1 |S10|S11|U0 |S00|S01|S02|S03| 8PSK
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  5 |                               |U1 |S10|S11|U0 |S00|S01|S02|S03| QPSK
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  6 |                               |U1 |S10|S11|U0 |S00|S01|S02|S03| BPSK1
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  7 |                               |U1 |S10|S11|U0 |S00|S01|S02|S03| BPSK2
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// There are 4 input ports to read the encoded data for channels 1 and 2 in binary
// or gray-coded form:
//
//     15  14  13  12  11  10   9   8    7    6    5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+----+----+----+---+---+---+---+---+
//  0 |    Mag.   | 0   0   0   0   0 |     8PSK     | 0   0   0   0   0 | Binary 1
//    +---+---+---+---+---+---+---+---+----+----+----+---+---+---+---+---+
//  1 |    Mag.   | 0   0   0   0   0 |BPSK|  0    0   0   0   0   0   0 | Binary 2
//    +---+---+---+---+---+---+---+---+----+----+----+---+---+---+---+---+
//  2 |    Mag.   | 0   0   0   0   0 |  Gray 8PSK   | 0   0   0   0   0 | Gray 1
//    +---+---+---+---+---+---+---+---+----+----+----+---+---+---+---+---+
//  3 |    Mag.   | 0   0   0   0   0 |BPSK|  0    0   0   0   0   0   0 | Gray 2
//    +---+---+---+---+---+---+---+---+----+----+----+---+---+---+---+---+
//
// The 8PSK outputs may be converted to QPSK or BPSK by not encoding bit 0 or bits
// 0 and 1. These bits will default to 0.
//
// 46 slices used. 440 MHz max.
// 
//	Normal warnings:
//		Input <din<15:8>> is never used.
//
// History:
//		2-22-09	add configurable signal constellation map (gray or natural mapping)
//		5-29-09	change from 2 to 3-bit magnitude
//		1-10-10	4-bit magnitude and latched output for 2-cycle read
//
module encoder(iocs, ioaddr, din, dout, iord, iowr, clk, rst);
	input iocs;				// select this module
	input [2:0] ioaddr;	// address registers in this module
	input [15:0] din;		// uncoded data and configuration input
	output [15:0] dout;	// encoded PSK output
	input iord;				// read register
	input iowr;				// write register
	input clk;				// master clock
	input rst;				// reset
// internal signals
reg [3:0] mag;				// output magnitude
wire [1:0] u;				// unencoded data
wire iv;						// data input valid
reg [3:0] s0;				// encoder state for bit 0
reg [1:0] s1;				// encoder state for bit 1
reg [7:0] e0,e1,e2,e3;	// configuration bits enable XOR when 1
reg [3:0] c;				// encoded data
wire [1:0] g;				// gray-encoded data
wire [2:0] d;				// binary or gray coded data
reg [15:0] e;				// output multiplexer
// load configuration
always @ (posedge clk)
begin
	if (rst) mag <= 4'h0;	// magnitude defaults to zero
	else if (iocs & iowr & (ioaddr == 1)) mag <= din[7:4];
	if (iocs & iowr & (ioaddr == 4)) e0 <= din[7:0];
	if (iocs & iowr & (ioaddr == 5)) e1 <= din[7:0];
	if (iocs & iowr & (ioaddr == 6)) e2 <= din[7:0];
	if (iocs & iowr & (ioaddr == 7)) e3 <= din[7:0];
end
// Store encoder state (delayed unencoded data) in shift register.
// Shift from LSB to MSB so index is time-ordered and corresponds for both bits.
assign u = din[1:0];
assign iv = iocs & iowr & (ioaddr == 0);
always @ (posedge clk)
begin
	if (rst) s0 <= 0; else if (iv) s0 <= {s0[2:0],u[0]};
	if (rst) s1 <= 0; else if (iv) s1 <= {s1[0],u[1]};
end
// encode bits by combining unencoded data with encoder state
always @ (posedge clk)
begin
	if (iv) c[0] <= (u[1]&e0[7])^(s1[0]&e0[6])^(s1[1]&e0[5])^(u[0]&e0[4])^(s0[0]&e0[3])^(s0[1]&e0[2])^(s0[2]&e0[1])^(s0[3]&e0[0]);
	if (iv) c[1] <= (u[1]&e1[7])^(s1[0]&e1[6])^(s1[1]&e1[5])^(u[0]&e1[4])^(s0[0]&e1[3])^(s0[1]&e1[2])^(s0[2]&e1[1])^(s0[3]&e1[0]);
	if (iv) c[2] <= (u[1]&e2[7])^(s1[0]&e2[6])^(s1[1]&e2[5])^(u[0]&e2[4])^(s0[0]&e2[3])^(s0[1]&e2[2])^(s0[2]&e2[1])^(s0[3]&e2[0]);
	if (iv) c[3] <= (u[1]&e3[7])^(s1[0]&e3[6])^(s1[1]&e3[5])^(u[0]&e3[4])^(s0[0]&e3[3])^(s0[1]&e3[2])^(s0[2]&e3[1])^(s0[3]&e3[0]);
end
// gray encoding (MSB unchanged)
assign g[1] = c[2] ^ c[1];
assign g[0] = c[0] ^ g[1];
// select natural or gray encoding
assign d[2] = c[2];
assign d[1:0] = ioaddr[1] ? g[1:0] : c[1:0];
// connect output
always @ (posedge clk)
begin
	if (iord) e <= {mag,4'h0,(ioaddr[0] ? {c[3],2'b00} : d[2:0]),5'b00000};
end
assign dout = e;
endmodule

//
//				crc1632p8a.v - FCS Calculation for AX.25 and IEEE 802.3
//
//						(C) Copyright 2009-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
// 
// This module calculates the FCS for AX.25 and IEEE 802.3 using the polynomials
// X^16 + X^12 + X^5 + 1 specified for HDLC and X^32 + X^26 + X^23 + X^22 + X^16
// + X^12 + X^11 + X^10 + X^8 + X^7 + X^5 + X^4 + x^2 + x + 1 as described in
// appendix C of the DIX Ethernet "Blue Book". The data input is 8 or 16 bits
// wide as specified by the port to which data is written. Internally, one byte
// is processed at a time. CRC processing takes one clock cycle per byte or two
// clock cycles per word. See Xilinx Application Note 209 for a discussion of
// the method used to process 8 bits in parallel.
//
// There are 3 input ports to allow writing bytes or words for CRC calculation
// and for initializing the CRCs to all ones. In addition, there are 2 ports to
// set the timer clock dividers:
//
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 0 |                               |             Data              | Byte In
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 1 |                              Data                             | Word In
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 3 |                                                               | Reset CRC
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 5 |                     Timer 0 Clock Divider                     |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 6 |                     Timer 1 Clock Divider                     |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// There are 3 output ports to read accumulated CRCs plus 2 ports to read the
// current time in 1 millisecond increments and 2 ports to read the timers:
//
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 0 |                           LSW CRC-32                          |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 1 |                           MSW CRC-32                          |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 2 |                             CRC-16                            |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 3 |                            LSW Time                           |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 4 |                            MSW Time                           |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 5 |                            Timer 0                            |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 6 |                            Timer 1                            |
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// Note that the LSW time must be read first as this latches the MSW for a
// later read. The 32-bit time is from reset and counts up every millisecond.
// The two 16-bit timers count up every microsecond but can be changed by
// writing the desired interval minus one to the divider port (1-65,536 us).
//
// S6: 291 LUT6s and 219 registers used. 204 MHz maximum CLK rate.
//
// Normal Warnings:
//		Input <iord> is never used.
//
// Revision History:
//		2011-10-3	created 8-bit version from serial implementation
//						(1 bit was 71 LUT6, 105 registrers & 291/366 MHz clocks)
//		2011-10-9	process words MSB first
//		2011-10-24	add clock (29 LUTs and 52 regs.)
//		2012-4-13	32-bit clock (was 135 LUT, 191 reg)
//		2012-4-26	dual timer (was 224 LUT, 121 reg., 159 MHz)
//		2012-5-10	latch MSW time when LSW read (was 247 LUT & 171 reg.)
//		2013-8-16	separate clock dividers for timers and don't stop on zero
//						(was 248 LUT, 187 reg, 174 MHz)
//
module crc1632p8a (
    input iocs,			// select this modeul
	 input [2:0] ioaddr,	// I/O address
	 input [15:0] din,	// input ports
	 input iowr,
	 output [15:0] dout,	// output ports
	 input iord,		
    input clk,				// master clock
	 input rst
    );
// internal signals
wire r3,w5,w6;			// read and write enables
wire iv;					// input valid
reg v;
wire init;				// initialize CRCs
reg s;					// select bit for CRC calculation
reg [7:0] d1;			// MSB input register
wire [7:0] d; 			// input multiplexer
reg [0:31] crc32;		// CRC-32 shift register
wire [0:31] next_crc32;
reg [0:15] crc16;		// CRC-16 shift register
wire [0:15] next_crc16;
reg [31:0] rtc;		// elapsed time (49.7 days in 1 ms inc.)
reg [15:0] msw;		// sync. MSW & LSW of RTC for read
wire q0,q1,q2,q3,q4;	// shift register outputs
wire e1,e2,e3,e4,e5;	// shift register enables
reg e2s,e5s;			// enables for binary counters
reg [15:0] mod0,mod1,div0,div1,timer0,timer1;	// divider & timers
wire tc0,tc1;			// divided clocks
reg [15:0] omux;		// output multiplexer
// decode register addresses
assign init = iocs & iowr & ~ioaddr[2] & ioaddr[1] & ioaddr[0];	// software reset
assign iv = iocs & iowr & ~ioaddr[2] & ~ioaddr[1];	// one cycle for registers 0 and 1
always @ (posedge clk) v <= iv & ioaddr[0];	// extra cycle for register 1
assign r3 = iocs & iord & (ioaddr == 3);	// LSW RTC
assign w5 = iocs & iowr & (ioaddr == 5);	// timer 0 clock divider
assign w6 = iocs & iowr & (ioaddr == 6);	// timer 1 clock divider
// save LSB input word and shift out MSB first
assign d = iv ? din[15:8] : d1;	// convert words to bytes, LSB first
always @ (posedge clk) if (iv) d1 <= din[7:0];
// calculate CRC16
assign next_crc16[0] = d[7] ^ d[3] ^ crc16[12] ^ crc16[8];
assign next_crc16[1] = crc16[13] ^ crc16[9] ^ d[6] ^ d[2];
assign next_crc16[2] = d[5] ^ d[1] ^ crc16[14] ^ crc16[10];
assign next_crc16[3] = d[4] ^ d[0] ^ crc16[15] ^ crc16[11];
assign next_crc16[4] = d[3] ^ crc16[12];
assign next_crc16[5] = crc16[13] ^ d[2] ^ d[7] ^ d[3] ^ crc16[12] ^ crc16[8];
assign next_crc16[6] = crc16[13] ^ crc16[9] ^ d[1] ^ crc16[14] ^ d[6] ^ d[2];
assign next_crc16[7] = d[0] ^ d[5] ^ d[1] ^ crc16[14] ^ crc16[10] ^ crc16[15];
assign next_crc16[8] = d[4] ^ d[0] ^ crc16[15] ^ crc16[11] ^ crc16[0];
assign next_crc16[9] = d[3] ^ crc16[12] ^ crc16[1];
assign next_crc16[10] = crc16[13] ^ crc16[2] ^ d[2];
assign next_crc16[11] = d[1] ^ crc16[14] ^ crc16[3];
assign next_crc16[12] = d[0] ^ crc16[15] ^ d[7] ^ d[3] ^ crc16[12] ^ crc16[8]
							 ^ crc16[4];
assign next_crc16[13] = crc16[13] ^ crc16[9] ^ crc16[5] ^ d[6] ^ d[2];
assign next_crc16[14] = d[5] ^ d[1] ^ crc16[14] ^ crc16[10] ^ crc16[6];
assign next_crc16[15] = d[4] ^ d[0] ^ crc16[15] ^ crc16[11] ^ crc16[7];
always @ (posedge clk)
begin
	if (rst|init) crc16 <= 16'hFFFF;
	else if (iv|v) crc16 <= next_crc16;
end
// calculate CRC32
assign next_crc32[0] = crc32[30] ^ d[1] ^ crc32[24] ^ d[7];
assign next_crc32[1] = d[6] ^ d[7] ^ d[0] ^ crc32[30] ^ crc32[31] ^ d[1] ^ crc32[24]
							^ crc32[25];
assign next_crc32[2] = crc32[26] ^ d[5] ^ d[6] ^ d[7] ^ crc32[30] ^ d[0] ^ d[1]
							^ crc32[31] ^ crc32[24] ^ crc32[25];
assign next_crc32[3] = d[4] ^ crc32[26] ^ d[5] ^ crc32[27] ^ d[6] ^ d[0] ^ crc32[31]
							^ crc32[25];
assign next_crc32[4] = d[4] ^ crc32[26] ^ d[5] ^ crc32[27] ^ crc32[28] ^ d[7]
							^ crc32[30] ^ d[1] ^ crc32[24] ^ d[3];
assign next_crc32[5] = d[4] ^ crc32[27] ^ d[6] ^ crc32[28] ^ d[7] ^ crc32[29]
							^ crc32[30] ^ d[0] ^ d[1] ^ crc32[31] ^ d[2] ^ crc32[24] ^ d[3]
							^ crc32[25];
assign next_crc32[6] = crc32[26] ^ d[5] ^ d[6] ^ crc32[28] ^ crc32[29] ^ d[0]
							^ crc32[30] ^ crc32[31] ^ d[1] ^ d[2] ^ d[3] ^ crc32[25];
assign next_crc32[7] = d[4] ^ crc32[26] ^ d[5] ^ crc32[27] ^ d[7] ^ crc32[29] ^ d[0]
							^ crc32[31]	^ d[2] ^ crc32[24];
assign next_crc32[8] = d[4] ^ crc32[27] ^ d[6] ^ crc32[28] ^ d[7] ^ crc32[24]
							^ crc32[0] ^ d[3]	^ crc32[25];
assign next_crc32[9] = crc32[26] ^ d[5] ^ d[6] ^ crc32[28] ^ crc32[29] ^ d[2] ^ d[3]
							^ crc32[25]	^ crc32[1];
assign next_crc32[10] = d[4] ^ crc32[26] ^ crc32[2] ^ d[5] ^ crc32[27] ^ d[7]
							 ^ crc32[29] ^ d[2] ^ crc32[24];
assign next_crc32[11] = d[4] ^ crc32[27] ^ d[6] ^ crc32[3] ^ crc32[28] ^ d[7]
							 ^ crc32[24] ^ d[3] ^ crc32[25];
assign next_crc32[12] = crc32[26] ^ d[5] ^ d[6] ^ crc32[28] ^ d[7] ^ crc32[4]
							 ^ crc32[29] ^ crc32[30] ^ d[1] ^ d[2] ^ crc32[24] ^ d[3]
							 ^ crc32[25];
assign next_crc32[13] = d[4] ^ crc32[26] ^ d[5] ^ crc32[27] ^ d[6] ^ crc32[29]
							 ^ d[0] ^ crc32[30] ^ crc32[5] ^ crc32[31] ^ d[1] ^ d[2]
							 ^ crc32[25];
assign next_crc32[14] = d[4] ^ crc32[26] ^ d[5] ^ crc32[27] ^ crc32[28] ^ crc32[30]
							 ^ d[0] ^ d[1] ^ crc32[31] ^ crc32[6] ^ d[3];
assign next_crc32[15] = d[4] ^ crc32[27] ^ crc32[28] ^ crc32[29] ^ d[0] ^ crc32[31]
							 ^ d[2] ^ crc32[7] ^ d[3];
assign next_crc32[16] = crc32[28] ^ d[7] ^ crc32[29] ^ d[2] ^ crc32[24] ^ d[3]
							 ^ crc32[8];
assign next_crc32[17] = crc32[9] ^ d[6] ^ crc32[29] ^ crc32[30] ^ d[1] ^ d[2]
							 ^ crc32[25];
assign next_crc32[18] = crc32[26] ^ d[5] ^ crc32[10] ^ crc32[30] ^ d[0] ^ d[1]
							 ^ crc32[31];
assign next_crc32[19] = d[4] ^ crc32[27] ^ crc32[11] ^ d[0] ^ crc32[31];
assign next_crc32[20] = crc32[28] ^ crc32[12] ^ d[3];
assign next_crc32[21] = crc32[29] ^ crc32[13] ^ d[2];
assign next_crc32[22] = d[7] ^ crc32[14] ^ crc32[24];
assign next_crc32[23] = d[6] ^ d[7] ^ crc32[30] ^ d[1] ^ crc32[15] ^ crc32[24]
							 ^ crc32[25];
assign next_crc32[24] = crc32[26] ^ d[5] ^ d[6] ^ d[0] ^ crc32[31] ^ crc32[16]
							 ^ crc32[25];
assign next_crc32[25] = d[4] ^ crc32[17] ^ crc32[26] ^ d[5] ^ crc32[27];
assign next_crc32[26] = d[4] ^ crc32[18] ^ crc32[27] ^ crc32[28] ^ d[7] ^ crc32[30]
							 ^ d[1] ^ crc32[24] ^ d[3];
assign next_crc32[27] = d[6] ^ crc32[19] ^ crc32[28] ^ crc32[29] ^ d[0] ^ crc32[31]
							 ^ d[2] ^ d[3] ^ crc32[25];
assign next_crc32[28] = crc32[26] ^ d[5] ^ crc32[20] ^ crc32[29] ^ crc32[30] ^ d[1]
							 ^ d[2];
assign next_crc32[29] = d[4] ^ crc32[27] ^ crc32[21] ^ crc32[30] ^ d[0] ^ d[1]
							 ^ crc32[31];
assign next_crc32[30] = crc32[28] ^ d[0] ^ crc32[22] ^ crc32[31] ^ d[3];
assign next_crc32[31] = crc32[29] ^ crc32[23] ^ d[2];
always @ (posedge clk)
begin
	if (rst|init) crc32 <= 32'hFFFFFFFF;
	else if (iv|v) crc32 <= next_crc32;
end
// clock divider generates count enable every 1 ms with 72 MHz master clock
// shift register dividers use less resources than binary counters
SRL16E #(
	.INIT(16'h0001)
	) sr0 (	// divide by 8
	.A3(1'b0), .A2(1'b1), .A1(1'b1), .A0(1'b1),
	.D(q0),
	.Q(q0),
	.CE(1'b1),
	.CLK(clk)
	);
assign e1 = q0;	// 9 MHz
SRL16E #(
	.INIT(16'h0001)
	) sr1 (	// divide by 9
	.A3(1'b1), .A2(1'b0), .A1(1'b0), .A0(1'b0),
	.D(q1),
	.Q(q1),
	.CE(e1),
	.CLK(clk)
	);
assign e2 = q0 & q1;	// 1 MHz
SRL16E #(
	.INIT(16'h0001)
	) sr2 (	// divide by 10
	.A3(1'b1), .A2(1'b0), .A1(1'b0), .A0(1'b1),
	.D(q2),
	.Q(q2),
	.CE(e2),
	.CLK(clk)
	);
assign e3 = q0 & q1 & q2;	// 100 kHz
SRL16E #(
	.INIT(16'h0001)
	) sr3 (	// divide by 10
	.A3(1'b1), .A2(1'b0), .A1(1'b0), .A0(1'b1),
	.D(q3),
	.Q(q3),
	.CE(e3),
	.CLK(clk)
	);
assign e4 = q0 & q1 & q2 & q3;	// 10 kHz
SRL16E #(
	.INIT(16'h0001)
	) sr4 (	// divide by 10
	.A3(1'b1), .A2(1'b0), .A1(1'b0), .A0(1'b1),
	.D(q4),
	.Q(q4),
	.CE(e4),
	.CLK(clk)
	);
assign e5 = q0 & q1 & q2 & q3 & q4;	// 1 kHz
// real-time clock (0-49.7 days)
always @ (posedge clk)
begin
	e5s <= e5;								// buffer enable
	if (rst) rtc <= 0;					// start at zero
	else if (e5s) rtc <= rtc + 1'b1;	// count up
end
// clock divider and timers (0-1.19 hours)
always @ (posedge clk)
begin
	e2s <= e2;										// buffer enable
	if (rst) mod0 <= 0;							// divider default is 1 us
	else if (w5) mod0 <= din;					// set divider modulus
	if (rst) mod1 <= 0;							// divider default is 1 us
	else if (w6) mod1 <= din;					// set divider modulus
	if (rst|tc0) div0 <= 0;						// for simulation
	else if (e2s) div0 <= div0 + 1'b1;		// count microseconds
	if (rst|tc1) div1 <= 0;						// for simulation
	else if (e2s) div1 <= div1 + 1'b1;		// count microseconds
	if (rst) timer0 <= 0;						// reset
	else if (tc0) timer0 <= timer0 + 1'b1;	// count up
	if (rst) timer1 <= 0;						// reset
	else if (tc1) timer1 <= timer1 + 1'b1;	// count up
end
assign tc0 = e2s & (div0 == mod0);	// reset window every microsecond
assign tc1 = e2s & (div1 == mod1);
// output multiplexer
always @ (posedge clk)
begin
	if (r3) msw <= rtc[31:16];	// latch MSW when LSW read
	case (ioaddr)
	0: omux <= {~crc32[24:31],~crc32[16:23]};	// CRC32 MSW
	1: omux <= {~crc32[8:15],~crc32[0:7]};		// CRC32 LSW
	2: omux <= {~crc16[8:15],~crc16[0:7]};		// CRC16
	3: omux <= rtc[15:0];							// LSW time
	4: omux <= msw;									// MSW time
	5: omux <= timer0;								// first timer
	6: omux <= timer1;								// second timer
	7: omux <= 16'h0000;								// unused
	default: omux <= 16'hxxxx;
	endcase
end
// connect output
assign dout = omux;
endmodule

//
//			dds2k19.v - 32-bit Direct Digital Frequency Synthesizer
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// The 32-bit DDS frequency is set by FI. DOXY is the 19-bit sequential cosine and sine waveform
// with the cosine present while IQ is 1 and the sine present when IQ is 0. 
//
// The DDS uses a 1024-entry ROM with 18-bit unsigned magnitude samples of a sine wave over 180
// degrees of phase that is expanded to a 19-bit signed amplitude. Spurious signals due to trunc-
// ation of the amplitude to 19 bits are -6*b - 13 = -127 dBc. Spurs due to phase truncation would
// be -6*b = -66 dBc but the table entries are are linearly interpolated to produce an output with
// about -124 dBc worst-case spurs. Calculations use a 10-stage pipeline:
// 
//	Phase	Action
//	  -1	Increment lower phase accumulator
//		0	Increment upper phase accumulator
//		1	Add 0 or 90 degrees
//		2	Generate addresses for adjacent entries
//		3	Look up sine wave in ROM
//		4  Latch ROM output
//		5	Invert ROM output if 2nd half of sine wave
//		6	Subtract next from current entry
//		7	Multiply by phase difference
//		8  (continued)
//		9	Add base entry
// 
// S6: 140 LUT6, 221 registers, 1 DSP48A and 1 RAM. Maximum clock rate is 265 MHz.
// Longest delay is phase accumulator.
//
// Normal Warnings:
//		<eb5_18> unconnected 
// 
// History:
//		M001	6-15-08	adapt to ISE 10.1 and sync. cosine/sine output to half-freq. clock
//		M002	1-22-10	use -cos to eliminate inversion on receive path (adder in transmit path)
//		M003	12-8-10	fixed unused multiplier cascade port warnings and added IQ input to
//							eliminate timing problems for Spartan-6
//		M004	11-18-11	unbiased rounding for amplitude interpolation using DSP48A (118 LUT 199 reg)
//		M005	11-18-11	2048x18 DP ROM to lower spurs by 12dB
//		M006	11-18-11	2048x24 DP ROM (was 119 LUT, 203 reg., 2 RAM 265MHz DCLK, 295MHz SCLK)
//		M007	3-27-12	use IQ instead of SCLK (was 131 LUT)
//		M008	4-1-13	modify for 2048x18 ROM with 1/2 sine wave
//		M009	4-7-13	use external registers in sine ROM (was 185 reg, 236 MHz)
//
module dds2k19 (
	output [18:0] doxy,	// DDS sequential I and Q amplitude output
	input dclk,				// master clock
	input iq,				// data tag (0 when sclk rising, 1 when sclk falling)
	input rst,				// reset accumulator
	input [31:0] frq		// frequency input - must be synchronized to SCLK
	);
// internal signals
reg [31:0] phase;			// phase accumulator
reg [31:4] p0;				// delayed phase
reg [20:4] p1b;			// delay lower phase accumulator output
reg [29:21] p1m;			// delayed phase accumulator output
reg [31:30] p1t;			// adjusted phase accumulator output
reg [31:21] p2a,p2b;		// ROM address and address+1 input
reg [20:4] p2,p3,p4,p5,p6;
reg sa3,sb3,sa4,sb4;		// upper address bit delay
wire [17:0] ea4,eb4;		// unsigned ROM entries: base and next
reg [18:0] ea5,eb5;		// signed ROM entries
reg [18:0] ea6,ea7;		// delayed base ROM entry
reg [18:0] dif6;			// difference between ROM entries
reg s6,s7;					// delayed sign of difference
wire [47:0] lo9;			// LO output (9 clock delay)
// increment phase accumulator at half data output rate
always @ (posedge dclk)
begin
	if (rst) phase <= 0;
	else if (~iq) phase <= phase + frq;	// posedge sclk
end
// 10-bit incrementer addresses next ROM entry
// 2-bit incrementer adjusts phase by 90 degrees
always @ (posedge dclk)
begin
	// delayed phase until negative edge of SCLK
	if (iq) p0[31:4] <= phase[31:4];	// M003
	// adjust phase by 0 or Pi/2
	p1b <= p0[20:4];						// bottom 17 bits
	p1m <= p0[29:21];						// middle 9 bits
	p1t <= p0[31:30] + {~iq,~iq}; 	// top 2 bits used to select sin/-cos (M003)
	// add 1 to upper 11 bits to form 2 addresses
	p2a <= {p1t,p1m};							// port A addrerss
	p2b <= {p1t,p1m} + 11'b00000000001;	// port B addrerss
	// delay lower bits by 3 clocks to match subtractor output
	p2 <= p1b;	// ROM address
	p3 <= p2;	// ROM output
	p4 <= p3;	// ROM latch output
	p5 <= p4;	// inverter output
	p6 <= p5;	// subtractor output
end
// sine ROM - 11-bit phase input, 18-bit amplitude output
// port A is base entry and port B is next entry
// ROM consists of two 2Kx9 block RAM - 2 clock delay
Sine1k2h ddsrom (
	.aa(p2a[30:21]),	// address in phase 2
	.ab(p2b[30:21]),
	.clk(dclk),			// master clock
	.rst(1'b0),
	.da(ea4),			// data output in phase 4
	.db(eb4)
	);
// invert ROM output if 2nd half of sinwe wave
// generate difference between entries
always @ (posedge dclk)
begin
	sa3 <= p2a[31];				// delay MSB address
	sb3 <= p2b[31];
	sa4 <= sa3;						// and use as sign bit
	sb4 <= sb3;
	ea5 <= (sa4 ? ~ea4 : ea4) + sa4;	// invert ROM output
	eb5 <= (sb4 ? ~eb4 : eb4) + sb4;
	dif6 <= eb5 - ea5;
	ea6 <= ea5;						// delay base entry
	ea7 <= ea6; 
end
// multiply low-order phase bits by difference between entries - 2 clocks
// difference is constrained to 16 bits with 2048 table entries
// then add base entry - 1 additional clock
assign s = ea7[18];	// extend sign by 12 bits
DSP48A1 #(
	.A0REG(0),			// 1 input register (fastest)
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CARRYINREG(0),
	.CARRYINSEL("OPMODE5"),
	.CARRYOUTREG(0),
	.CREG(1),			// buffer input to interpolation adder
	.DREG(0),
	.MREG(1),
	.OPMODEREG(1),
	.PREG(1),
	.RSTTYPE("SYNC")
) mul (
	.A({dif6[17:0]}),	// lower 18 bits of difference between adjacent entries
	.B({1'b0,p6}),		// 17 bits of phase (bits 20-4)
	.BCOUT(),			// no cascading
	.C({s,s,s,s,s,s,s,s,s,s,s,s,ea7,17'h00000}),	// align with top of product
	.D(18'h00000),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.M(),
	.P(lo9),			// fastest output
	.PCIN(48'h000000),
	.PCOUT(),
	.CLK(dclk),
	.CEA(1'b1),		// enable all clocks
	.CEB(1'b1),
	.CEC(1'b1),
	.CECARRYIN(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEOPMODE(1'b1),
	.CEP(1'b1),
	.RSTA(1'b0),	// registers never reset
	.RSTB(1'b0),
	.RSTC(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTOPMODE(1'b0),
	.OPMODE({8'h0D})	// multiply and add
);
// delay lower entry to account for subtractor and multiplier
// interpolate ROM output by adding difference between entries
// scaled by fractional address bits to base entry
always @ (posedge dclk)
begin
end
// connect outputs
assign doxy = lo9[35:17];
endmodule

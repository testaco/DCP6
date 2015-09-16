//
//			dds32.v - 32-bit Direct Digital Frequency Synthesizer
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// The 32-bit DDS frequency is set by FI. DOXY is the 18-bit sequential cosine and
// sine waveform with cosine present while SCLK is 1 and sine when SCLK is 0. 
//
// The DDS uses a 1024-entry ROM with 18-bit amplitude samples of a sine wave over 360
// degrees of phase. Spurious signals due to truncation of the amplitude to 18 bits
// are -6*b - 20 = -128 dBc. Spurs due to phase truncation would be -6*b = -60 dBc but
// the table entries are are linearly interpolated to produce an output with about
// -112 dBc worst-case spurs. Calculations use a 10-stage pipeline:
// 
//	Phase	Action
//	  -1	Increment lower phase accumulator
//		0	Increment upper phase accumulator
//		1	Add 0 or 90 degrees
//		2	Generate addresses for adjacent entries
//		3	Look up sine wave in ROM
//		4  Latch ROM output
//		5	Subtract next from current entry
//		6	Multiply by phase difference
//		7  (continued)
//		8	Round product (offset from lower entry)
//	   9	Interpolate between entries by adding offset	
// 
// S6: 118 LUT6, 199 registers, 1 DSP48A and 1 RAM. 268 MHz DCLK and 295 MHz SCLK.
// Longest delay is phase accumulator. 
// 
// History:
//		M001	6-15-08	adapt to ISE 10.1 and sync. cosine/sine output to half-freq. clock
//		M002	1-22-10	use -cos to eliminate inversion on receive path (adder in transmit path)
//		M003	12-8-10	fixed unused multiplier cascade port warnings and added IQ input to
//							eliminate timing problems for Spartan-6
//		M004	11-18-11	unbiased rounding for amplitude interpolation using DSP48A accumulator
//
module dds32 (
    output [17:0] doxy,	// DDS sequential I and Q amplitude output
    input sclk,			// sample clock
	 input dclk,			// master clock
	 input iq,				// data tag (I=1, Q=0)
	 input rst,				// reset accumulator
    input [31:0] frq		// frequency input - must be synchronized to SCLK
	 );
// internal signals
reg [17:0] lo9;			// LO output (9 clock delay)
reg [31:0] phase;			// phase accumulator
reg [31:5] p0;				// delayed phase
reg [21:5] p1b;			// delay lower phase accumulator output
reg [29:22] p1m;			// delayed phase accumulator output
reg [31:30] p1t;			// adjusted phase accumulator output
reg [31:22] p2a,p2b;		// ROM address and address+1 input
reg [21:5] p2,p3,p4,p5;
wire [17:0] ea4,eb4;		// ROM entries: base and next
reg [17:0] ea5,ea6,ea7,ea8;	// delayed base ROM entry
reg [17:0] dif5;			// difference between ROM entries
reg s6,s7;					// delayed sign of difference
wire [47:0] adj8;			// rounded adjustment
// increment phase accumulator at half data output rate
always @ (posedge sclk)
begin
	if (rst) phase <= 0;
	else phase <= phase + frq;
end
// 10-bit incrementer addresses next ROM entry
// 2-bit incrementer adjusts phase by 90 degrees
always @ (posedge dclk)
begin
	// delayed phase until negative edge of SCLK
	if (iq) p0[31:5] <= phase[31:5];	// M003
	// adjust phase by 0 or Pi/2
	p1b <= p0[21:5];						// bottom 17 bits
	p1m <= p0[29:22];						// middle 8 bits
	p1t <= p0[31:30] + {~iq,~iq}; 	// top 2 bits used to select sin/-cos (M003)
	// add 1 to upper 11 bits to form 2 addresses
	p2a <= {p1t,p1m};							// port A addrerss
	p2b <= {p1t,p1m} + 10'b0000000001;	// port B addrerss
	// delay lower bits by 3 clocks to match subtractor output
	p2 <= p1b;	// ROM address
	p3 <= p2;	// ROM output
	p4 <= p3;	// ROM latch output
	p5 <= p4;	// subtractor output
end
// sine ROM - 10-bit phase input, 18-bit amplitude output
// port A is base entry and port B is next entry
// ROM consists of one 1Kx18 block RAM - 2 clock delay
Sine1k2 ddsrom (
	.aa(p2a),	// address in phase 2
	.ab(p2b),
	.clk(dclk),	// master clock
	.rst(1'b0),
	.da(ea4),	// data output in phase 3
	.db(eb4)
	);
// latch outputs and generate difference between entries - sync with p4
always @ (posedge dclk)
begin
	dif5 <= eb4 - ea4;
	s6 <= dif5[17];		// delay sign bit to match multiplier output (M)
	s7 <= s6;
end
// multiply low-order phase bits by difference between entries and round
DSP48A1 #(
	.A0REG(0),	// 1 input register
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CARRYINREG(0),
	.CARRYINSEL("OPMODE5"),
	.CARRYOUTREG(0),
	.CREG(1),	// buffer input to rounding adder
	.DREG(0),
	.MREG(1),
	.OPMODEREG(1),
	.PREG(1),
	.RSTTYPE("SYNC")
) mul (
	.A(dif5),		// difference between adjacent entries
	.B({1'b0,p5}),	// lower phase bits
	.BCOUT(),		// no cascading
	.C({31'h00000000,~s7,s7,s7,s7,s7,s7,s7,s7,s7,s7,s7,s7,s7,s7,s7,s7,s7}),
	.D(18'h00000),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.M(),
	.P(adj8),		// fastest output
	.PCIN(48'h000000),
	.PCOUT(),
	.CLK(dclk),
	.CEA(1'b1),		// enable A, B and M clocks
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
// round result towards zero (truncate positive result and increment negative results)
always @ (posedge dclk)
begin
	ea5 <= ea4;	// sync with dif5 (difference between entries)
	ea6 <= ea5;	//  
	ea7 <= ea6;	// sync with adj7 (multiplier output)
	ea8 <= ea7; // sync with adj8 (rounded)
	lo9 <= ea8 + adj8[34:17];	// add interpolation adjustment to lower entry
end
// connect outputs
assign doxy = lo9;
endmodule

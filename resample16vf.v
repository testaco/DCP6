//
//					resample16vf.v - Arbitrary resampling module
//
//					(C) Copyright 2008-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module processes two 16-bit wide channels of information with a
// passband of 0-0.4 Fs. The outputs are decimated by a factor greater than 1.
// Coefficients are the lower 18 bits out of a 24-bit word calculated for a
// 1023-tap low-pass filter at 64 Fs. Since the input data is interpolated by
// 64 (there are 63 zeros for each non-zero data sample), the data output is
// multiplied by 64 by shortening the accumulator to 36 bits. Coefficients
// are linerly-interpolated to increase the resolution and reduce spurs for
// arbitrary decimation values. 15-16 coefficients are used to calculate each
// output value and are spaced every 64 taps on the original coefficient set.
// Note that data memory is 32 samples long so that the output can be adjusted
// backwards in time by as many as 16 samples or up to 16 additional samples can
// be accumulated during calculations. The most significant 4 bits of the phase
// adder output select the starting sample for the calculations. The middle 6
// bits select the starting point in the coefficient ROM. The least significant
// 6 bits are used to interpolate between stored coefficients in order to reduce
// distortion in the output. The output sample rate is a 24-bit word with an
// extra 12 LSBs to increase the accuracy of the output sample rate to 60 PPB.
//
// DIX and DIY are the inputs with IV indicating valid data. DOX and DOY are the
// outputs, with  OV indicating valid data. OVF is 1 if the accumulator has
// overflowed. CIN is used to write configuration information. CWR[0] (LSW) and
// CWR[1] (MSW) select the 32-bit output frequency and CWR[2] selects a 16-bit
// output phase (time delay) in the range 0-15.9999 samples in 0.00024 sample
// increments. CWR[3] sets the number of output samples.
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 0 |                  LS Fraction                  |               | N
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 1 |    Integer    |                  MS Fraction                  | N
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |                   Output Phase (Time Delay)                   | (4 words)
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 3 |                                               |  INT  |   |VFO|
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		Output sample rate is input sample rate / N, where N = 0-16 in 1/16M increments
//		Output phase is 0-16 samples in 1/4096 sample inrements
//		VFO: enable (1) or disable (0) variable frequency output
//
// Multiple clock cycles are required to process each tap of the filter:
//
//   Phs	Description
//		0	Carry out from phase accumulator
//		1	Add phase offset
//		2	Look up coefficients					Calculate data offset
//		3	Subtract adjacent entries			delay
//		4	Multiply difference by LS phase	delay
//		5	Add adjustment to base entry		Subtract offset from SCTR
//		6	Multiply data by coefficient
//		7	Product available
//		8	Accumulate sum of products
//
// 97 MHz maximum clock frequency with 1 RAM, 3 multipliers and 225 slices used.
// Maximum propagation delay is in 36-bit data accumulator. Calculation of output
// values requires 16 clock cycles each plus an additional 9 clock cycles for
// pipeline delays. Coefficient ROM must be initialized by resample.ucf.
//
// Normal warnings:
//		<cadj4<35>> and <cadj4<16:0>>> are assigned but never used. 
//		<xacc8<18:0>> and <yacc8<18:0>> are assigned but never used.
//
// History:
//		1-10-10	Modify filter for 0-0.4 Fs passband (16 taps, 64 phases).
//		5-25-10	Modify to allow decimation by 0-7
//		12-8-10	fixed tctr initialization and increment length and unused multipler
//					cascade ports to eliminate warnings for Spartan-6
//
module resample16vf (
    input [15:0] dix,diy,	// input data
    input iv,					// input data valid
    output [15:0] dox,doy,	// output data
    output ov,					// output data valid
    output of,					// final output flag
	 output ovf,				// data accumulator overflow
    input [15:0] cin,		// configuration data
    input [3:0] cwr,			// write frequency and phase offset
    input clk,					// master clock
    input rst					// master reset
    );
// internal signals
reg vfo;								// set if variable frequency output
reg [1:0] intrp;					// interpolation factor
reg [27:0] frq;					// frequency configuration register
reg [11:0] frq0;					// temporary register for LSB frequency
wire [15:0] phsofs;				// phase offset
reg [5:0] tctr;					// filter tap counter (inc. phase offset select)
wire tnz;							// tap counter not zero
reg [3:0] tctr1;					// delayed tap counter value
reg [4:0] sctr; 					// sample counter and delayed versions
wire empty;							// more data required
wire start;							// tap counter is zero and data present
wire dec;							// decrement sample counter
wire z,tc;							// tap counter zero, terminal count
reg [23:1] v;						// first tap delay
reg [8:1] f;						// final tap of final filter delay
reg ovff;							// overflow signal delay
reg [27:0] phsacc;				// phase accumulator
wire [3:0] co;						// phase accumulator carry out (samples)
wire [15:0] phs1;					// phase adder output
reg [5:0] phs2,phs3;				// delay LS bits
wire [9:0] caddr1a,caddr1b;	// coefficient addresses
wire [17:0] coef2a,coef2b;		// coefficients from ROM
reg [17:0] cdif3,coef3a,coef4a; // multiplier A input path
wire [35:0] cadj4;				// interpolation multiplier output
reg [17:0] coef5;					// multiplier A input
reg [4:0] dofs2,dofs3,dofs4,dofs5; // data offfset delay
wire [4:0] daddr5;				// data address in shift register
wire [15:0] xdata5,ydata5;		// multiplier B inputs
wire [35:0] xprod7,yprod7;		// multiplier output
reg [35:0] xacc8,yacc8;			// data accumulator
wire load;							// load accumulator
// configuration registers
always @ (posedge clk)
begin
	if (rst|cwr[1]) frq0 <= 0;				// output sample rate in 2 registers
	else if (cwr[0]) frq0 <= cin[15:4];
	if (rst) frq <= 28'h1000000;			// default is Fin = Fout
	else if (cwr[1]) frq <= {cin,frq0};	// upper register causes transfer
	if (rst) vfo <= 0;						// default to fixed output rate
	else if (cwr[3]) vfo <= cin[0];
	if (rst) intrp <= 0;						// default to 1 output sample
	else if (cwr[3]) intrp <= cin[3:2];
end
// count samples input after filter start for data output offset
// start tap counter when phase accumulator overflows
// output strobe delayed to account for coef. RAM, multiplier and accumulator
always @ (posedge clk)
begin
	if (rst) sctr <= 5'b11111;							// increment for new and decrement for requested samples
	else if (iv|dec) sctr <= sctr + {4'h0,iv} - {1'b0,(dec ? co : 4'h0)};
	if (rst|(tc & ~empty)) tctr <= 6'b000000;		// filter tap counter plus phase offset selector
	else if (~empty) tctr <= tctr + 6'b000001;	// convolve when data is present
	if (~empty) v <= {v[22:1],z};						// accumulator load and data valid delay
	if (~empty) f <= {f[7:1],tc};						// delay from last tap in last output
end
assign empty = sctr[4];						// halt processing if number of samples is negative
assign tnz = |tctr;							// tap counter not zero
assign start = (~tnz) & (~empty);		// start when tap counter is zero and data is present
assign dec = f[5];							// decrement sctr when last tap of last filter processed
assign z = ~|tctr[3:0];						// first tap in each filter
assign load = v[7];							// first sample reaches accumulator
assign tc = (tctr == {intrp,4'b1111});	// last tap in last filter
// 28-bit phase accumulator
// increment before first tap of first filter processed
// wait for new sample(s) if top 4 bits not zero
always @ (posedge clk)
begin
	if (rst) phsacc <= 0;
	else if (start) phsacc <= {4'h0,phsacc[23:0]} + frq;
end
assign co = phsacc[27:24];					// top 4 bits are integer samples
// add phase offset for timing synchronization and early/late sampling
// only use phase accumulator if variable frequency output selected
// (register here increases max. clock rate from 97 to 137 MHz)
// phase offset memory - shift register stores 4 phases that are to be output
srl16x16e phsmem (
	.d(cin),						// input
	.ce(cwr[2]),				// port 2
	.a({2'b00,tctr[5:4]}),	// phase offset select
	.y(phsofs),					// output
	.clk(clk)
	);
assign phs1 = phsofs + {4'h0,(vfo ? phsacc[23:12] : 12'h000)};
// delay tap number to match phase 
always @ (posedge clk)
begin
	if (~empty) tctr1 <= tctr[3:0];	// delay tap number for coefficient address calculation
end
// coefficient ROM - access adjacent entries to allow interpolation
// tap counter is upper 4 bits of address and output phase is the lower 6 bits
// use same coefficients for both X and Y channels -  1 clock delay
// zero output when counting inhibited
assign caddr1a = {tctr1,phs1[11:6]};
assign caddr1b = caddr1a + 10'b0000000001;
resample18vfrom rom (
	.aa(caddr1a), 
	.ab(caddr1b), 
	.da(coef2a), 
	.db(coef2b),
	.ce(~empty),	
	.clk(clk), 
	.rst(rst)
	);
// coefficient interpolation - 3 clock delay
always @ (posedge clk)
begin
	if (~empty) phs2 <= phs1[5:0];			// delay LS phase bits
	if (~empty) phs3 <= phs2;
	if (~empty) cdif3 <= coef2b - coef2a;	// calculate slope of coefficients
	if (~empty) coef3a <= coef2a;				// compensate for cdif delay
	if (~empty) coef4a <= coef3a;				// compenstate for mult delay
end
MULT18X18SIO #(
	.AREG(0),	// enable output register
	.BREG(0),
	.PREG(1)
	) cmul (
	.A(cdif3),	// difference between ROM entries
	.B({1'b0,phs3,11'b00000000000}),	// fractional phase offset
	.BCIN(),
	.BCOUT(),
	.P(cadj4),	// add to first entry
	.CEA(),
	.CEB(),
	.CEP(~empty),
	.CLK(clk),
	.RSTA(),
	.RSTB(),
	.RSTP(1'b0)
	);
always @ (posedge clk)
begin
	if (~empty) coef5 <= coef4a + cadj4[34:17];	// adjust ROM entry
end
// data address is filter tap number plus offset due to output phase
always @ (posedge clk)
begin
	if (~empty) dofs2 <= {1'b0,tctr1} + {1'b0,phs1[15:12]};
	if (~empty) dofs3 <= dofs2;
	if (~empty) dofs4 <= dofs3;
	if (~empty) dofs5 <= dofs4;
end
// add offset due to new samples arriving
assign daddr5 = dofs5 + sctr;
// data in shift register read with no delay
srl32x16e srx (
	.d(dix),
	.a(daddr5),
	.y(xdata5),
	.ce(iv),
	.clk(clk)
	);
srl32x16e sry (
	.d(diy),
	.a(daddr5),
	.y(ydata5),
	.ce(iv),
	.clk(clk)
	);
// multiply 16-bit data by 18-bit coefficient -  2 clock delay
MULT18X18SIO xmul (
	.A({xdata5,2'b00}),
	.B(coef5),
	.BCIN(),
	.BCOUT(),
	.P(xprod7),
	.CEA(~empty),
	.CEB(~empty),
	.CEP(~empty),
	.CLK(clk),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTP(1'b0)
	);
MULT18X18SIO ymul (
	.A({ydata5,2'b00}),
	.B(coef5),
	.BCIN(),
	.BCOUT(),
	.P(yprod7),
	.CEA(~empty),
	.CEB(~empty),
	.CEP(~empty),
	.CLK(clk),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTP(1'b0)
	);
// load output registers on first tap then accumulate results
always @ (posedge clk)
begin
	if (rst) xacc8 <= 0;
	else if (~empty) xacc8 <= xprod7 + (load ? 0 : xacc8);
	if (rst) yacc8 <= 0;
	else if (~empty) yacc8 <= yprod7 + (load ? 0 : yacc8);
	ovff <= (xacc8[35] ^ xacc8[34]) | (yacc8[35] ^ yacc8[34]);
end
// connect outputs
assign dox = xacc8[34:19];	// data outputs
assign doy = yacc8[34:19];
assign ovf = ovff;			// overflow
assign ov = v[23];			// output valid
assign of = f[8];				// final value
endmodule

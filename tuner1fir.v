// 
//			tuner1fir.v - DDC/DUC and 2-stage Quadrature Low-Pass Filter with
//			serial CIC at 2x sample rate and parallel FIR at 1x sample rate
//
//						(C) Copyright 2006-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for personal
// non-profit educational use in the Amateur Radio Service and the license is not
// transferrable. The information is provided as-is for experimental purposes and
// the author does not warranty its freedom from defects or its suitability for any
// specific application.
//
//	This module contains a direct digital synthesizer (DDS), a quadrature mixer and three
// 2-channel low-pass filters (LPFs). It is used to convert ADC data at the DDS output
// frequency to baseband or translate baseband data to the DDS frequency for the DAC.
// NOTE: ADC data changes on SCLK negative-going edge.
//
// The ADC and DAC ports both use 16-bit signed fractional numbers and are synchronized
// with SCLK. The baseband I/O is synchronized to MCLK and uses complex numbers with
// parallel X and Y axis samples. The input consumes 16-bit X and Y samples and the output
// provides 20-bit X and Y samples. Internal operations are synchronized to DCLK. X-axis
// samples are present when SCLK is 1 and Y-axis samples are present when SCLK is 0. In
// receive mode, ADC is a real data input centered on frequency FRQ that is downconverted
// to baseband centered around DC. DOX and DOY are the baseband outputs with OV signalling
// that the data is valid. In transmit mode, DIX and DIY are the baseband inputs with IV
// indicating valid data. DAC is a real data output centered on frequency FRQ. 
//
// The 2 stages of filtering are cascaded with the CIC filter first on receive and last on
// on transmit. The CIC filter has 4 stages and can decimate or interpolate by 10-256. The
// FIR filter has variable coefficients with up to 1023 taps and can interpolate or decimate
// by 1-64. The usable decimation and interpolation range for the two cascaded filters is
// 80-10,000 allowing 500-1,000,000 baseband sample rates with an 80 Msps ADC and DAC. A
// noise blanker is located between the two FIR filters. Receive mode is selected when XMT
// is 0 and transmit mode is selected when XMT is 1.
//
// Filter coefficients and other configuration data are loaded via the 16-bit port DIN
// when IOCS and IOWR are both active. IOADDR specifies one of 8 registers:
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 0 |                         LSW Frequency                         |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 1 |                         MSW Frequency                         |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |   |     Exponent      |    Integer    |       Fraction        | CIC Gain
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 3 |               |         CIC Interpolation/Decimation          |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |   |       Blanker Threshold       |                           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 5 |    FIR Decimation     |        Number of Coefficients         | (reset)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 6 |                           |    FIR Filter 1/4 Instruction     | Coefficient Load
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 7 |                                                           |RST| Reset
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		CIC Gain = integer.fraction x 2^exponent
//		RST - reset FIR filter
//
// The CIC decimation/interpolation factor may be set to 8-2580 (by loading 7-2579). Transmit
// gain is the interpolation factor to the fourth power and receive gain is the decimation
// factor to the fourth power. When receiving, 46 extra bits are provided to allow for a CIC
// gain up to 7 x 10^13 while retaining 18-bit resolution. When transmitting, 34 extra bits
// are provided to allow for a CIC gain up to 1.7 x 10^10. Unity overall gain is acheived by
// multiplying the input by a factor set by 3 fields and is an integer between 0 and 15 plus
// a fraction between 0 and 63/64 times a binary exponent between 2^0 and 2^31. On transmit
// the value of the integer field is limited to 64 to reserve 4 bits in the comb filter for
// bit growth.
//
//	Blanker Threshold sets the signal X and Y magnitude above with samples are zeroed.
//
// The FIR decimation factor may be set to 1-64 by loading the values 0-63. The FIR inter-
// polation factor is determined by the number of writes in the instructions loaded into
// each filter. They are loaded sequentially in 9-bit quarter-instructions and 512 must be
// loaded. Unused location may be written with 0 (NOP). Writing register 5 resets the FIR
// instruction counter.
//
// There is one status port containing the 7-bit maximum recorded signal magnitude plus 4 bits
// indicating ADC, mixer, CIC filter and/or FIR filter overflow. They are all reset when read.
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//    |ADC|MIX|CIC|FIR|                   |          MAXMAG           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		MAXMAG = maximum signal magnitude
//
// 1323 LUT6s, 1920 registers, 8 DSP48A1s and 7 block RAMs are used. Maximum clock speeds are:
// SCLK: 404 MHz, DCLK: 193 MHz (-2) or 224 MHz (-3) and MCLK: 357 MHz. 
//
//	TIG statements are required for the clock synchronization logic and address and the data
// bits that cross the MCLK to SCLK/DCLK clock boundary. TIGs may also be used to relax timing
// constraints on the configuration registers dec and ncoef.
//
// Normal Warnings:
//		Signal <cin<15>> and <cin<6:0>> are assigned but never used.
//
// History:
//		4-28-09	inverted DAC MSB in rounder to equalize propagation delays
//		1-13-10	change to 56-bit CIC filter
//		1-22-10	change to cos/-sin DDS and adder at quadrature mixer transmit output
//		4-26-10	20-bit output on last FIR filter (sfir18x24x20x2) 197->190 MHz DCLK
//		4-27-10	add 1 in X and Y registers to offset truncation error in mixer and CIC
//					DCLK 190->194 MHz (+17 slices)
//		8-31-10	add CIC overflow (+11 slices)
//		12-8-10	eliminated unused cascade port warning for Spartan-6 and added IQ input
//		12-9-10	use DSP48A1 as multiplier for receive or multiplier-accumulator for transmit
//		12-21-10	15->31-entry FIFO (+1 LUT, +1 reg.), restrict local reset to FIR filters
//		12-30-10	add data I/O synchronization to support separate tuner clock domain
//		8-23-11	remove one FIR filter and convert other to 1024 taps
//		9-17-11	use DCLK on FIR outputs to eliminate clock skew
//		9-18-11	latch CPU address and data on MCLK to allow 75 MHz MCLK
//		9-18-11	move conversion to/from offset binary to this module for better timing
//		10-25-11	use new clock sync. circuit to reduce delays (was 1120 LUT6 & 1941 reg.)
//		11-17-11	new IQ generation logic
//		11-18-11	round mixer output (was 1153 LUT & 1991 reg.)
//		11-20-11	faster noise blanker (was 1172 LUT, 1993 reg, 144MHz SCLK, 187 MHz DCLK)
//		11-20-11	DDS32 (was 1199 LUT, 1952 reg., 192MHz SCLK, 192MHz DCLK)
//		11-20-11	register on FIFO RFD (was 1183 LUT, 1935 reg., 192MHz SCLK, 192MHz DCLK)
//		11-20-11	DDS32A (was 1185 LUT, 1936 reg., 5 RAM, 193 MHz SCLK & 192 MHz DCLK)
//		11-22-11	ext. mix. module (was 1188 LUT6, 1938 reg.))
//		11-22-11	dds2l24 & mul18x24x18p (was 1206 LUT6, 1957 reg., 7 DSP, 6 RAM))
//		12-6-11	use pfir1024x18x28x20x2 (was 1224 LUT, 1931 reg., 193M SCLK, 192M DCLK)
//		12-9-11	clock config. regs with MCLK (was 1239 LUT, 1900 reg.)
//		12-11-11	change dctr3 in pfir1024x18x28x20x2 to reduce delays (was 1240 LUT, 1907 reg.)
//		12-21-11	fix FIFO strobe and synchronize rfd with 2 flip-flops (was 1234 LUT, 1901 reg.)
//		1-27-12	move inversion of ADC MSB to mixer input multiplexer to minimize setup time
//		3-16-12	add vo2 to minimize dclk->sclk delay (was 1284 LUT, 1871 reg.)
//		3-17-12	add register to improve FIFO-CIC timing and pttin to enable/disable DAC
//		3-27-12	use IQ in DDS & NB, del. frq reg. reset to improve timing (was 1285 LUT, 1908 reg.)
//		4-12-12	add maximum input signal magnitude to status
//		4-28-12	run FIFO at DCLK rate (was 1288 LUT, 1920 reg., SCLK=206, DCLK=194 & MCLK=357 MHz)
//		2-19-13	rename xmt to xmtin and synchronize to DCLK (was 1320 LUt6, 1918 reg)
//		3-7-13	remove PTT (was 1292 LUT, 1907 reg)
//
module tuner1fir (
	 input iocs,				// select this module
//	 input iocs1,				// select doppler simulator
	 input [2:0] ioaddr,		// wselect configuration register
	 input [15:0] din,		// configuration data
	 input iowr,				// write program data
	 output [15:0] dout,		// status
	 input iord,				// read status
	 input mclk,mrst,			// master clock and reset (64-80 MHz)
	 input [15:0] adc,		// offset binary input (transitions on SCLK high->low)
	 input ovf,					// ADC overflow
	 output [15:0] dac,		// offset binary output (transitions on SCLK high->low)
	 input sclk,				// sample clock (80 MHz)
	 input dclk,				// double rate clock (160 MHz)
	 output rfd,				// ready for baseband data
    input [15:0] dix,diy,	// complex data input synchronized to MCLK
    input iv,					// input valid
    output [19:0] dox,doy,	// complex data output synchronized to MCLK
    output ov,					// valid output
	 input xmtin				// 0=receive, 1=transmit
//	 output full,				// FIFO signals for TEST
//	 output rdy
	);
// TEST
//assign rdy = frdy;
// offset to cancel truncation errors (mixer only)
wire [19:0] offset;			// DC offset
assign offset = 1;
// internal signals
wire xmt;						// 0=receive, 1=transmit
wire iq;							// I/Q flag generation (I=1, Q=0)
reg [4:0] ge;					// gain exponent
reg [9:0] gf;					// gain fraction
reg [11:0] n;					// decimation/interpolation factor
reg [7:0] limit;				// blanker threshold
reg [5:0] dec;					// configuration registers
reg [9:0] ncoef;
reg crst;						// internal reset configuration register
wire srst;						// synchronized internal reset (sync. to SCLK)
reg [15:0] frq0,frq1;		// frequency register and LSW delay
reg [31:0] frq;
wire swr1;
//wire [31:0] frq2;				// frequency with doppler spread
reg [17:0] lpf1d;				// noise blanker input
reg lpf1v;
wire [17:0] nbd;				// noise blanker output
wire nbv;
reg [17:0] nbx;				// delayed X sample from noise blanker
wire [17:0] lpf2x,lpf2y;	// FIR LPF input
wire lpfrdy,lpf2v;
wire [19:0] lpf3x,lpf3y;	// FIR LPF  output (20 bits)
wire lpf3v;
wire ce;
reg [17:0] ctdix,ctdiy;		// CIC input latch
wire [17:0] crdo;				// CIC output
wire crov;
reg [17:0] crdo1;				// CIC output latc
reg crov1;
reg [15:0] rfin,rfout,dacout;	// input from ADC and output to DAC
wire [17:0] mixi;				// mixer input from CIC
wire [23:0] lo;				// mixer input from LO
reg [17:0] mixmux;			// mixer RF/IF input multiplexer
reg [23:0] lod;				// mixer LO delay
wire [17:0] mixout;			// mixer output (odd number clocks)
reg [17:0] mixo;				// mixer output (even number clocks)
wire acc;						// enable accumulation on next clock cycle
reg los,s;						// LO and multiplier output signs
reg [15:0] xi,yi,xyi;		// latched baseband data input
wire siv;						// IV synchronized to SCLK
reg xyv;							// delayed SIV
reg [19:0] xo,yo;				// sync. FIR output to SCLK (20 bits)
reg vo;
wire [17:0] fx,fy;			// FIFO output
wire frdy;						// FIFO ready for more data
reg adcovf;						// ADC overflow latch
wire mixovf;					// quadrature mixer overflow register
wire cicovf,firovf;			// filter overflow bits
reg adcovff,mixovff,cicovff,firovff;	// status flags
wire [6:0] maxsig;
// IQ is used for multiplexing and demultiplexing in-phase and quadrature samples
// it tracks SCLK but changes state after the positive-going edge of DCLK
iqgen iqg (
	.sclk(sclk),
	.dclk(dclk),
	.iq(iq)
	);
// decode addresses for configuration registers
wire wr0,wr1,wr2,wr3,wr4,wr5,wr6,wr7;
assign wr0 = iocs & iowr & (ioaddr == 0);
assign wr1 = iocs & iowr & (ioaddr == 1);
assign wr2 = iocs & iowr & (ioaddr == 2);
assign wr3 = iocs & iowr & (ioaddr == 3);
assign wr4 = iocs & iowr & (ioaddr == 4);
assign wr5 = iocs & iowr & (ioaddr == 5);
assign wr6 = iocs & iowr & (ioaddr == 6);
assign wr7 = iocs & iowr & (ioaddr == 7);
// configuration registers
always @ (posedge mclk)
begin
	if (mrst) frq0 <= 0;
	else if (wr0) frq0 <= din;			// two 16-bit transfers to write 32-bit frequency
	if (mrst) frq1 <= 0;
	else if (wr1) frq1 <= din;
	if (mrst) ge <= 0;
	else if (wr2) ge <= din[14:10];	// gain binary exponent
	if (mrst) gf <= 0;
	else if (wr2) gf <= din[9:0];		// gain binary fraction
	if (mrst) n <= 0;
	else if (wr3) n <= din[11:0];		// decimation/interpolation factor
	if (mrst) limit <= 8'hFF;
	else if (wr4) limit <= din[14:7];	// amplitude limit
	if (mrst) ncoef <= 0;
	else if (wr5) ncoef <= din[9:0];	// number of coefficients for FIR filter
	if (mrst) dec <= 0;
	else if (wr5) dec <= din[15:10];	// decimation for FIR filter
	if (mrst) crst <= 1;
	else if (wr7) crst <= din[0];		// reset when powered up - clear when programmed
end
// synchronize reset
FDPE syncrst (
	.PRE(crst),	// asynchronous set
	.D(1'b0),	// synchronous clear
	.Q(srst),	// synchronized reset output
	.CE(1'b1),
	.C(dclk)
	);
// synchronize transmit enable
syn2clk synxmt (
	.a(xmtin),
	.aclk(mclk),	// external clock and reset
	.arst(mrst),
	.b(xmt),
	.bclk(dclk),	// internal clock and reset
	.brst(srst)
	);
// generate delayed write enable synchronized to SCLK
syn2clkoe syniowr (
	.a(wr1),
	.aclk(mclk),	// external clock and reset
	.arst(mrst),
	.b(swr1),
	.boe(~iq),		// enable on rising edge of SCLK
	.bclk(dclk),	// internal clock and reset
	.brst(srst)
	);
// Doppler simulator dithers LO frequency
//dopplersim dsim (
//	.fi(frq1),
//	.fo(frq2),
//	.cin(cin[2:0]),
//	.cwe(cwe1),
//	.clk(sclk),
//	.rst(srst)
//	);
// DDS with 32-bit frequency input sets the ADC and DAC center
// frequencies. Resolution is SCLK/4G = 0.02 Hz at 80 Msps.
// Cosine/sine sequence starts after falling edge of SCLK and
// completes in one SCLK cycle.
// change frequency synchronous to SCLK
always @ (posedge dclk) if (swr1 & ~iq) frq <= {frq1,frq0};
dds2k24 dds (
	.doxy(lo),		// cosine and sine output
	.dclk(dclk),	// 2X SCLK
	.iq(iq),			// I/Q enable (I=1, Q=0)
	.rst(srst),		// global reset
	.frq(frq)		// frequency
);
// latch RF input to minimize timing constraints
always @ (posedge sclk)
begin
	rfin <= adc; 
	adcovf <= ovf;
end
// select CIC output or ADC output as mixer input and
// convert ADC from offset binary to two's complement
always @ (posedge dclk)
begin
	mixmux <= xmt ? mixi : {~rfin[15],rfin[14:0],2'b00};
	lod <= lo;			// delay LO to match
	mixo <= mixout;	// delay output so even number of clock cycles
end
// Mixer multiplies inputs by sine and cosine with 4 clock delay.
mul18x24x18p mix (
	.A(lod),		// LO in
	.B(mixmux),	// RF/IF in
	.P(mixout),	// RF/IF out
	.V(mixovf),	// overflow flag
	.clk(dclk),
	.rst(srst)
	);
// load when I present (negedge sclk) and add when Q present (posedge sclk)
assign acc = ~iq;
always @ (posedge dclk) if (xmt) rfout <= mixo[17:2] + (acc ? rfout : 16'h0000); 
// change RF output on negtive-going edge of SCLK to minimize timing constraints
// and convert from two's complement to offset binary
always @ (negedge sclk) dacout <= {~rfout[15],rfout[14:0]}; 
assign dac = dacout;
// CIC Filter - Converts 80 Msps mixer I/O to and from 320-8000 ksps for FIR
// filters. Decimates by 10-250 on receive or interpolates by 10-250 on transmit.
// X component present when SCLK high and Y component present when SCLK low.
// I/O is serial X and Y components of sample with data valid synchronized to SCLK
// and data synchronized to DCLK
CIC4F64 cic (
	.rdi(mixo),			// continuous input from mixer (receive)
	.tdix(fx),			// intermittant input from FIR LPF via FIFO (transmit)
	.tdiy(fy),			// (mult. clock setup time so sync. with IQ not required)
	.tie(ce),			// request new sample from FIFO
	.tdo(mixi),			// continuous interpolated output (transmit)
	.rdo(crdo),			// decimated output (receive)
	.rov(crov),			// valid output
	.ovf(cicovf),		// overflow
	.clk(dclk),			// processing clock
	.iq(iq),				// I/Q select
	.rst(srst),			// global reset
	.xmt(xmt),
	.ge(ge),				// configuration info.
	.gf(gf),
	.n(n)
	);
// latch external data input
always @ (posedge mclk)
begin
	if (iv) xi <= dix;	// X input
	if (iv) yi <= diy;	// Y input
end
// synchronize input strobe to SCLK
syn2clkoe syniv (
	.a(iv),
	.aclk(mclk),		// external clock and reset
	.arst(mrst),
	.b(siv),
	.boe(~iq),			// enable on rising edge of SCLK
	.bclk(dclk),		// local clock and reset
	.brst(srst)
	);
// Switch FIR filter input between
// CIC filter output on receive and module input on transmit
// multiplex transmitter input using same scheme as CIC filter
always @ (posedge dclk)
begin
	crdo1 <= crdo;			// delay CIC output
	crov1 <= crov;
	xyi <= iq ? xi : yi;	// multiplex transmitter input
	xyv <= siv;				// delay strobe
	lpf1d <= xmt ? {xyi,2'b00} : crdo1;	// expand transmit input to 18 bits
	lpf1v <= xmt ? xyv : crov1;
end
// noise blanker
noiseblanker nb (
	.dixy(lpf1d),	// multiplexed data input
	.iv(lpf1v),
	.doxy(nbd),		// multiplexed data output
	.ov(nbv),
	.iq(iq),			// data tag
	.clk(dclk),		// data clock
	.rst(srst),		// local reset
	.limit(limit)	// blanking threshold
	);
// delay X samples to coincide with Y samples
always @ (posedge dclk)
begin
	nbx <= nbd;
end
// X and Y valid when Y available from NB
assign lpf2x = nbx;
assign lpf2y = nbd;
assign lpf2v = nbv & ~iq;
// FIR filter
pfir1024x18x28x20x2 fir (
	.rfd(lpfrdy),
	.dix(lpf2x),
	.diy(lpf2y),
	.iv(lpf2v),
	.oe(frdy|~xmt),
	.dox(lpf3x),
	.doy(lpf3y),
	.ov(lpf3v),
	.ovf(firovf),
	.clk(dclk),
	.mrst(srst),		// local reset
	.dec(dec),			// async. config. info.
	.ncoef(ncoef),
	.pclk(mclk),
	.pdata(din[15:0]),// coefficients and first/last flags
	.pwr(wr6),			// write coefficients
	.prst(wr7)			// reset coefficient counter
	);
// add DC offset to X and Y output samples (tuner output only)
// synchronize output valid to SCLK
always @ (posedge dclk)
begin
	if (lpf3v & ~xmt) xo <= lpf3x + offset;	// save first sample of pair
	if (lpf3v & ~xmt) yo <= lpf3y + offset;	// save second sample of pair
	vo <= lpf3v;										// delay output valid
end
// buffer in FIFO for retreival by CIC (xmt)
reg oe;
always @ (posedge dclk) oe <= xmt & ce & iq;	// one clock period only
fifo32x36sro fifo (
	.pdi({lpf3y[19:2],lpf3x[19:2]}),	// truncate samples to 18 bits (transmit only)
	.iv(lpf3v),								// load from filter Y output and delayed X sample
	.oe(oe),									// unload when decimation counter overflows
	.pdo({fy,fx}),
	.ov(),
	.empty(),
	.full(),
//	.full(full),							// TEST
	.rfd(frdy),								// false when zero or one entry left
	.clk(dclk),
	.rst(srst)
	);
// synchronize ready for input to MCLK
reg ardy,srdy;	// use two flip-flops
always @ (posedge mclk)
begin
	if (mrst) ardy <= 0;
	else ardy <= lpfrdy;	// unstable output
	if (mrst) srdy <= 0;
	else srdy <= ardy;	// stabilized output
end
assign rfd = srdy;		// connect to output
// synchronize output strobe to MCLK
syn2clk synov (
	.a(vo & ~xmt),	// only present on receive
	.aclk(dclk),
	.arst(srst),	// local reset
	.b(ov),
	.bclk(mclk),
	.brst(mrst)		// external reset
	);
// generate delayed read enable synchronized to DCLK
syn2clk syniord (
	.a(iocs & iord),
	.aclk(mclk),	// external clock and reset
	.arst(mrst),
	.b(crd),
	.bclk(dclk),	// internal clock and reset
	.brst(srst)
	);
// Collect status information
always @ (posedge dclk)
begin
	if (srst) adcovff <= 0; else adcovff <= (adcovff|adcovf) & ~crd;
	if (srst) mixovff <= 0; else mixovff <= (mixovff|mixovf) & ~crd;
	if (srst) cicovff <= 0; else cicovff <= (cicovff|(cicovf & ~xmt)) & ~crd;
	if (srst) firovff <= 0; else firovff <= (firovff|firovf) & ~crd;
end
// measure maximum ADC output
max8 max (
	.sig({~rfin[15],rfin[14:8]}),	// ADC is signed magnitude
	.max(maxsig),						// 7-bit output
	.clk(dclk),							// ADC sample rate
	.rst(crd)							// reset when read
	);
//assign maxsig = 0;
// connect module outputs
assign dox = xo;
assign doy = yo;
assign dout = {adcovff,mixovff,cicovff,firovff,5'b00000,maxsig};
endmodule

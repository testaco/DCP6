// 
//				tuner4.v - DDC/DUC and 2-stage Quadrature Low-Pass Filter
//						with two parallel FIR at 4x sample rate
//
//						(C) Copyright 2006-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for personal
// non-profit educational use in the Amateur Radio Service and the license is not
// transferrable. The information is provided as-is for experimental purposes and
// the author does not warranty its freedom from defects or its suitability for any
// specific application.
//
//	This module contains a direct digital synthesizer (DDS), a quadrature mixer and two
// 2-channel low-pass filters (LPFs). It is used to convert ADC data at the DDS output
// frequency to baseband or translate baseband data to the DDS frequency for the DAC.
// NOTE: ADC data changes on SCLK negative-going edge.
//
// The ADC and DAC ports both use 16-bit signed fractional numbers and are synchronized
// with SCLK. The baseband I/O is synchronized to MCLK and uses complex numbers with
// parallel X and Y axis samples. The input consumes 16-bit X and Y samples and the output
// provides 18-bit X and Y samples. Internal operations are synchronized to DCLK. X-axis
// samples are present when SCLK is 1 and Y-axis samples are present when SCLK is 0. In
// receive mode, ADC is a real data input centered on frequency FRQ that is downconverted
// to baseband centered around DC. DOX and DOY are the baseband outputs with OV signalling
// that the data is valid. In transmit mode, DIX and DIY are the baseband inputs with IV
// indicating valid data. DAC is a real data output centered on frequency FRQ. 
//
// Two stages of low-pass filtering are cascaded finite impulse response (FIR) filters. The
// FIR filters have variable coefficients with up to 127 taps and each can interpolate or
// decimate by 2-20. The usable decimation and interpolation range for the two cascaded
// filters is 4-80 allowing 1-20 Msps baseband sample rates with an 80 Msps ADC and DAC.
// Receive mode is selected when XMT is 0 and transmit mode is selected when XMT is 1.
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
//	 2 |                           |   Coef. Addr. 1   |   |    SC1    | reset PCTR
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 3 |                   FIR Filter 1 Coefficients                   |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |                           |   Coef. Addr. 2   |   |    SC2    | reset PCTR
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 5 |                   FIR Filter 2 Coefficients                   |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 6 |                                                               |
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 7 |                                                           |RST| Reset
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		SC = filter coefficient scaling (0 = 19 bits, 1 = 20 bits, 2 = 21 bits, 3 = 22 bits)
//		RST - reset FIR filter
//
// The FIR decimation factor is determined by the number of reads and the FIR interpolation
// factor is determined by the number of writes in the instructions loaded into each filter.
// They are loaded sequentially as 16-bit half-instructions in reverse order and 128 must be
// loaded. Unused locations may be written with 0 (NOP). Writing register 5 resets the FIR
// instruction counter.
//
// There is one status port containing the 12-bit maximum recorded signal magnitude plus 3
// bits indicating mixer and FIR filter overflow. They are all reset when read.
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//    |   |MIX|FIR|FIR|                                               |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// 1412 LUT6s (9%), 1371 registers, 18 DSP48A1s and 1 block RAM are used. 
// Maximum clock speeds for -2 are DCLK = 220 MHz and MCLK = 322 MHz.
// Slowest path is FIR filter coefficient counter reset. 
//
//	TIG statements are required for the clock synchronization logic and address and the data
// bits that cross the MCLK to SCLK/DCLK clock boundary. TIGs may also be used to relax
// timing constraints on the configuration registers dec and ncoef.
//
// History:
//		2013-10-2	create from tuner1 by using 2 quad-rate FIR instead of CIC and FIR
//		2013-12-12	add coefficient start address (was 1469 LUT, 1319 reg, 246 MHz)
//
module tuner4 (
	 input iocs,				// select this module
	 input [2:0] ioaddr,		// select configuration register
	 input [15:0] din,		// configuration data
	 input iowr,				// write program data
	 output [15:0] dout,		// status
	 input iord,				// read status
	 input mclk,mrst,			// master clock and reset (64-80 MHz)
	 input [15:0] rfin,		// signed 16-bit RF input
	 output [15:0] rfout,	// signed 16-bit RF output
	 input dclk,				// double rate clock (160 MHz)
	 input iq,					// mixer data output tag
	 output rfd,				// ready for baseband data
    input [15:0] dix,diy,	// complex data input synchronized to MCLK
    input iv,					// input valid
    output [17:0] dox,doy,	// complex data output synchronized to MCLK
    output ov,					// valid output
	 input xmtin,				// 0=receive, 1=transmit
//	 output full,				// FIFO signals for TEST
	 output rdy
	);
// FIFO ready for data output (TEST)
reg qrdy;
always @ (posedge dclk) qrdy <= frdy;
assign rdy = qrdy;
// offset to cancel truncation errors (mixer only)
wire [17:0] offset;			// DC offset
assign offset = 1;
// internal signals
reg xmt;							// 0=receive, 1=transmit
reg crst;						// internal reset configuration register
wire srst;						// synchronized internal reset (sync. to SCLK)
reg [15:0] frq0,frq1;		// frequency holding registers
reg [31:0] frq;				// synchronized frequency and write enable
wire swr1;
reg [2:0] sc1,sc2;			// filter coefficient scaling
reg [4:0] ca1,ca2;			// filter coefficient start address
reg [17:0] lpfix,lpfiy;		// FIR LPF 1 input
reg lpfiv;
wire [17:0] lpfx,lpfy;		// FIR LPF 1 output & LPF 2 input
wire lpfv;
wire [17:0] lpfox,lpfoy;	// FIR LPF 2 output
wire lpfov;
wire lpf1rdy,lpf2rdy;		// LPF ready for data outputs
reg [15:0] rfacc;				// accumulator to form RF output
wire [17:0] mixi;				// mixer input from LPF
wire [18:0] lo;				// mixer input from LO
reg [17:0] mixmux;			// mixer RF/IF input multiplexer
reg [18:0] lod;				// mixer LO delay
wire [17:0] mixout;			// mixer output (odd number clocks)
reg [17:0] mixo;				// mixer output (even number clocks)
reg [17:0] mx,my;				// demultiplexed mixer outputs
reg los,s;						// LO and multiplier output signs
reg [15:0] xi,yi,xyi;		// latched baseband data input
wire siv;						// IV synchronized to SCLK
reg xyv;							// delayed SIV
reg [17:0] xo,yo;				// sync. FIR output to SCLK (18 bits)
reg vo;
wire [17:0] fx,fy;			// FIFO output
wire frdy;						// FIFO ready for more data
wire mixovf;					// quadrature mixer overflow register
wire fir1ovf,fir2ovf;		// filter overflow bits
reg mixovff,fir1ovff,fir2ovff;	// status flags
reg [15:0] plsw;				// FIR coefficient input logic
reg [5:0] pmsw;
reg pctr;
wire [21:0] pdata;			// FIR configuration word
wire prst,pwr;					// common reset and write enable
reg pwr3,pwr5;					// write enable for each FIR filter
wire swr3,swr5;				// synchronized write enable
// decode addresses for configuration registers
wire wr0,wr1,wr2,wr3,wr4,wr5,wr7;
assign wr0 = iocs & iowr & (ioaddr == 0);
assign wr1 = iocs & iowr & (ioaddr == 1);
assign wr2 = iocs & iowr & (ioaddr == 2);
assign wr3 = iocs & iowr & (ioaddr == 3);
assign wr4 = iocs & iowr & (ioaddr == 4);
assign wr5 = iocs & iowr & (ioaddr == 5);
assign wr7 = iocs & iowr & (ioaddr == 7);
// configuration registers
always @ (posedge mclk)
begin
	if (mrst) frq0 <= 0;
	else if (wr0) frq0 <= din;			// two 16-bit transfers to write 32-bit frequency
	if (mrst) frq1 <= 0;
	else if (wr1) frq1 <= din;
	if (mrst) sc1 <= 0;
	else if (wr2) sc1 <= din[2:0];	// FIR 1 scaling
	if (mrst) ca1 <= 0;
	else if (wr2) ca1 <= din[8:4];	// FIR 1 coef. start
	if (mrst) sc2 <= 0;
	else if (wr4) sc2 <= din[2:0];	// FIR 2 scaling
	if (mrst) ca2 <= 0;
	else if (wr4) ca2 <= din[8:4];	// FIR 1 coef. start
	if (mrst) crst <= 1;
	else if (wr7) crst <= din[0];		// reset when powered up - clear when programmed
end
// latch transmit enable to allow TIG for this module
always @ (posedge mclk) xmt <= xmtin;
// synchronize reset (TIG for crst)
FDPE syncrst (
	.PRE(crst),	// asynchronous set
	.D(1'b0),	// synchronous clear
	.Q(srst),	// synchronized reset output
	.CE(1'b1),
	.C(dclk)
	);
// coefficient input counter and latch for loading FIR configuration in 16-bit words
assign prst = wr2|wr4;	// share logic between 2 FIR filters
assign pwr = wr3|wr5;
always @ (posedge mclk)
begin
	if (prst) pctr <= 0;				// start with even word (LSW)
	else if (pwr) pctr <= ~pctr;	// count even/odd words
	if (pwr & ~pctr) plsw <= din;							// save LSW
	if (pwr & pctr) pmsw <= {din[15:12],din[1:0]};	// save MSW
	pwr3 <= wr3 & pctr;				// write when odd word present
	pwr5 <= wr5 & pctr;
end
assign pdata = {pmsw,plsw};		// 22-bit configuration word
// generate delayed write enables synchronized to SCLK (TIG for syniowrx/t)
syn2clk syniowr3 (
	.a(pwr3),
	.aclk(mclk),	// external clock and reset
	.arst(mrst),
	.b(swr3),
	.bclk(dclk),	// internal clock and reset
	.brst(srst)
	);
syn2clk syniowr5 (
	.a(pwr5),
	.aclk(mclk),	// external clock and reset
	.arst(mrst),
	.b(swr5),
	.bclk(dclk),	// internal clock and reset
	.brst(srst)
	);
// generate delayed write enable synchronized to SCLK (TIG for syniowr1/t)
syn2clkoe syniowr1 (
	.a(wr1),
	.aclk(mclk),	// external clock and reset
	.arst(mrst),
	.b(swr1),
	.boe(~iq),		// enable on rising edge of SCLK
	.bclk(dclk),	// internal clock and reset
	.brst(srst)
	);
// DDS with 32-bit frequency input sets the ADC and DAC center
// frequencies. Resolution is SCLK/4G = 0.02 Hz at 80 Msps.
// Cosine/sine sequence starts after falling edge of SCLK and
// completes in one SCLK cycle.
// change frequency synchronous to SCLK
always @ (posedge dclk) if (swr1) frq <= {frq1,frq0};
dds2k19 dds (
	.doxy(lo),		// cosine and sine output
	.dclk(dclk),	// 2X SCLK
	.iq(iq),			// I/Q enable (I=1, Q=0)
	.rst(srst),		// global reset
	.frq(frq)		// frequency
);
// select LPF output or ADC output as mixer input
always @ (posedge dclk)
begin
	case ({xmt,iq})
	2'b00: mixmux <= {rfin,2'b00};	// 16b ADC -> 18b mixer
	2'b01: mixmux <= {rfin,2'b00};
	2'b10: mixmux <= fx;	// iq=0,
	2'b11: mixmux <= fy;	// iq=1,
	default: mixmux <= 18'hxxxxx;
	endcase
	lod <= lo;			// delay LO to match
end
// Mixer multiplies inputs by sine and cosine with 4 clock delay.
mul18x19x18p mix (
	.A(lod),		// LO in
	.B(mixmux),	// RF/IF in
	.P(mixout),	// RF/IF out
	.V(mixovf),	// overflow flag
	.clk(dclk),
	.rst(srst)
	);
// IQ=1 when I present (negedge sclk) and IQ=0 when Q present (posedge sclk)
always @ (posedge dclk)
begin
	mixo <= mixout;	// delay mixer output so even number of clock cycles
	if (iq) mx <= mixo;
	if (~iq) my <= mixo;
	if (~iq) rfacc <= mx[17:2] + mixout[17:2]; 
end
assign rfout = rfacc;
// latch external data input - need TIG for latches
always @ (posedge mclk)
begin
	if (iv) xi <= dix;	// X input
	if (iv) yi <= diy;	// Y input
end
// synchronize input strobe to SCLK
syn2clk syniv (
	.a(iv),
	.aclk(mclk),		// external clock and reset
	.arst(mrst),
	.b(siv),
	.bclk(dclk),		// local clock and reset
	.brst(srst)
	);
// Switch FIR input between mixer output on receive and module input on transmit
// delay data valid to allow additional delay between CIC data out and FIR data in
always @ (posedge dclk)
begin
	lpfix <= xmt ? {xi,2'b00} : mx;	// expand transmit input to 18 bits
	lpfiy <= xmt ? {yi,2'b00} : my;
	lpfiv <= xmt ? siv : iq;			// demuxed mixer out on negedge sclk
end
// FIR filter 1
pfir128q18 fir1 (
	.rfd(lpf1rdy),
	.dix(lpfix),		// input
	.diy(lpfiy),
	.iv(lpfiv),
	.oe(lpf2rdy),		// output
	.dox(lpfx),
	.doy(lpfy),
	.ov(lpfv),
	.ovf(fir1ovf),
	.clk(dclk),
	.rst(srst),			// local reset
	.shift(sc1),
	.caddr(ca1),
	.pdata(pdata),		// coefficients and flags
	.pwr(swr3)			// write coefficients
	);
// FIR filter 2
pfir128q18 fir2 (
	.rfd(lpf2rdy),
	.dix(lpfx),			// input
	.diy(lpfy),
	.iv(lpfv),
	.oe(frdy|~xmt),	// output
	.dox(lpfox),
	.doy(lpfoy),
	.ov(lpfov),
	.ovf(fir2ovf),
	.clk(dclk),
	.rst(srst),			// local reset
	.shift(sc2),
	.caddr(ca2),
	.pdata(pdata),		// coefficients and flags
	.pwr(swr5)			// write coefficients
	);
// add DC offset to X and Y output samples (tuner output only)
// synchronize output valid to SCLK
always @ (posedge dclk)
begin
	if (lpfov) xo <= lpfox + offset;	// save first sample of pair
	if (lpfov) yo <= lpfoy + offset;	// save second sample of pair
	vo <= lpfov;							// delayed output valid
end
// buffer in FIFO for retreival by CIC (xmt)
fifo16x36sro fifo (
	.pdi({lpfoy,lpfox}),	// X and Y-axis samples from LPF
	.iv(lpfov),				// load LPF X and Y outputs
	.oe(iq),					// unload after posedge SCLK 
	.pdo({fy,fx}),
	.ov(),
	.empty(),
	.full(),
//	.full(full),			// TEST
	.rfd(frdy),				// false when zero or one entry left
	.clk(dclk),
	.rst(srst)
	);
// synchronize ready for input to MCLK
reg ardy,srdy;	// use two flip-flops
always @ (posedge mclk)
begin
	if (mrst) ardy <= 0;
	else ardy <= lpf1rdy;	// unstable output
	if (mrst) srdy <= 0;
	else srdy <= ardy;		// stabilized output
end
assign rfd = srdy;			// connect to output
// synchronize output strobe to MCLK
syn2clk synov (
	.a(vo),			// same time as data latched
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
	if (srst) mixovff <= 0; else mixovff <= (mixovff|mixovf) & ~crd;
	if (srst) fir1ovff <= 0; else fir1ovff <= (fir1ovff|(fir1ovf & lpfv)) & ~crd;
	if (srst) fir2ovff <= 0; else fir2ovff <= (fir2ovff|(fir2ovf & lpfov)) & ~crd;
end
// connect module outputs - need TIG for all outputs
assign dox = xo;
assign doy = yo;
assign dout = {1'b0,mixovff,fir1ovff,fir2ovff,12'h000};
endmodule

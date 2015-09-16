//
//			modem16a.v - Modulator and Demodulator with 16x16-bit I/O	
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module provides modulation and demodulation for single-carrier applications.
// 
// When receiving, the received signal is present in rectangular form with the in-phase
// component on RDIX and the quadrature component on RDIY. Both inputs are 18-bit signed
// fractions. 
//
// The received signal is then processed by the CORDIC module over the next 18 clock
// cycles. For AM and PM the module operates in vector mode and calculates the 16-bit
// phase and the 16-bit magnitude of the signal. For FM, the phase can then be
// differentiated over 1-16 samples. For SSB, CORDIC operates in the rotate mode and
// rotates the incoming signal at the BFO frequency performing a complex multiplication.
// A BFO frequency of 0 allows pass-through of the X and Y inputs for ISB or QAM
// demodulation by the CPU.
//
// The clock recovery module may be used to perform early-late timing recovery with 3
// samples per symbol. The middle sample is saved as data and the difference between the
// other two samples measures the timing error.
//
// The synchronization detection module processes the CORDIC output to detect OFDM null
// symbols and symbol timing errors. Nulls are detected by averaging the signal magnitude
// over a symbol period and detecting the minimum. Timing errors are detected by comparing
// the phase of the received signal between points one FFT interval apart and performing a
// moving average over the interval of the cyclic prefix. The error signal is minimized
// when the end of the symbol is reached. 
//
// The CORDIC module is used for all modulation tasks. For AM and PM, it is operated
// in the rotation mode and the X input is rotated by Y scaled radians so the X  input
// specifies the signal magnitude and Y the phase. For FM, the Y input is accumulated so
// it specifies the frequency. For SSB, the phase input is obtained from the BFO phase
// accumulator. A BFO frequency of 0 allows pass-through of the X and Y inputs for ISB
// or QAM. The modulator output is 16-bits wide.
//
// The modem module is configured and data tranmitted via 8 output ports:
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |                               X                               | I or magnitude
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                               Y                               | Q or phase
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |                       |SFS|NFL|  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 3 |                               |          Busy Delay           | (Ts/16)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |     CP Length - 1     |                FFT Size               | Phase Correlator
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  5 |       SOF Delay       |   |           Symbol Length           | Magnitude Filter
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  6 |                         BFO Frequency                         | BFO
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  7 |                                               |PTT|INI|RST|XMT| Command
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		FM: 0 = PM, 1 = FM (SSB must be 0)
//		SSB: put CORDIC modulator in rotate mode and enable BFO
//		TRE: enable timing recovery
//		CRE: enable carrier recovery
//		NFL: narrow frequency limit (0 = +/-Fs/16, 1 = +/-Fs/32)
//		SFS: short frequency sample (0 = 1024-sample average, 1 = 512-sample averge)
//		XMT: configure tuner and modem (0=receive, 1=transmit)
//		RST: Reset FIFO (flush contents)
//		INI: Initialize sync detect logic for new symbol
//		PTT: configure external amplifiers (0=receive, 1=transmit)
//
// There are 6 input ports to read data and status:
//
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |                 In-phase Signal or Magnitude                  | X
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |            Quadrature Signal or Phase or Frequency            | Y
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |                   Avgerage Magnitude (RSSI)                   | M
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 | E | F |DCD|FCD|               Phase Correlator                | P
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |                       Frequency Offset                        |
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  5 | E | F |DCD|FCD|BSY| 0   0   0   0   0   0   0   0   0   0   0 | 
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		OVF - modem filter overflow
//		E - FIFO empty
//		F - FIFO full
//		DCD - data carrier detect (minimum amplitude)
//		FCD - full carrier detect (minimum amplitude and acceptable offset for 1088 samples)
//    BSY - channel busy (data carrier detect plus interframe delay)
//
// The input to the modem FIFO and the output from the modem FIFO are formatted as follows:
//
//                    X                               Y
//     1 1 1 1 1 1                     1 1 1 1 1 1     
//		 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
//		+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//    |               I               |               Q               | SSB
//		+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//    |          Magnitude            |       Frequency or Phase      | AM/FM/PM & FSK/PSK xmt
//		+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//    |         Timing Error          |   Magnitude   |  Freq./Phase  | FSK/PSK rcv (TRE=1)
//		+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//    |         Timing Error          |       Costas Loop Error       | FSK/PSK rcv (TRE=1 & CRE=1)
//		+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//
// The X channel must be accessed first as writing to Y loads the current X and Y sample pair
// into the FIFO and reading Y causes the next X and Y sample pair to be loaded into the FIFO.
// Alternatively, the Y sample only may be used. The X sample is then set once on transmit and
// can be ignored on receive. 
//
// 1199 LUT6s, 855 registers, 2 multipliers and 1 RAM are used. Maximum clock speed is 125 MHz.
// 
// Normal Warnings:
//		Signals <xc<17:16>> and <yc<17:16>> are assigned but never used.
//		Signals <px<0>> and <py<0>> are assigned but never used.
//		Signal <z0<14>> is assigned but never used.
//		Signal <dlyphs<1:0>> is assigned but never used. (nulsyndet)
//		Signals <unused20a> and <unused20b> are assigned but never used.
//
// History:
//		M001	6-11-08	added clipper, resampler and streamlined configuration interface
//		M002	1-3-09	modified interface on tuner side for 18 bits and removed gain control
//		M003	1-26-09	added FIFO and clock recovery
//		M004	2-6-09	placed I/O port logic inside module
//		M005	3-3-09	latch status multiplexer output for 2-cycle input instruction
//		M006	4-6-09	new CORDIC module with vector and rotate modes for modulation and demodulation
//		M007	4-10-09	added logic for null symbol and cyclic prefix detection
//		M008	4-15-09	added BFO for LSB and USB transmit/receive
//		M009	6-8-09	put in new compressor and moved FFT switch after CORDIC
//		M010	12-22-09	new null and synchronization detector logic
//		M011	1-10-10	allow resampling on both receive and transmit paths
//		M012	2-1-10	route FM discriminator to test signal y
//		M013	3-3-10	nulsyndet modified
//		M014	3-11-10	add DCD output
//		M015	5-3-10	use compressor with 8-bit magnitude detector (was 920 slices 97 MHz)
//		M016	5-12-10	move resampler and compressor to new module (was 926 slices 95 MHz now 672 slices 97 MHz)
//		M017	10-16-10	move flags and place phase correlation in status
//		M018	8-4-11	new clock recovery circuit and internal data/clock sample discrimination at 2x/4x
//		M019	8-18-11	new CORDIC module with serial multipliers (was 610 slices, 4 multipliers and 1 RAM)
//		M020	11-9-11	CORDIC module with 20 iterations and 24-bit accumulators (was 999 LUT 733 reg 118 MHz)
//		M021	11-16-11	CORDIC module with rounding (was 1022 LUT 741 reg 107 MHz)
//		M022	1-19-12	add carrier detect logic with min. mag. and min. freq. ofs. (was 1084 LUT, 790 reg.)
//		M023	1-22-12	add transmitter empty output for Modem/FFT switching
//		M024	3-1-12	add timing & costas loop error outputs
//		M025	3-17-12	add PTT output
//		M026	4-26-12	use RSSI for CD logic and widen limits to match software imp.
//		M027	2-24-13	use cordiv16s16 with 24Q23 format angle accumulator and ROM
//		M028  6-17-13	add busy output (was 1096 LUT, 797 reg)
//		M029	9-20-13	new carrier detect logic (was 1153 LUT, 835 reg)
//		M030	11-21-13	faster CORDIC (was 1200 LUT, 839 reg, 125 MHz)
//
module modem16a (
	input iocs,						// select this module
	input [2:0] ioaddr,			// I/O port address
	input [15:0] din,				// data input bus
	output [15:0] dout,			// data output bus
	input iowr,						// write to I/O port
	input iord,						// read from I/O port
	input [15:0] rdix,rdiy,		// receiver input
	input riv,						// valid input
	input toe,						// enable transmitter output
	output [15:0] tdox,tdoy,	// transmitter data output
	output tov,						// valid output
	output pttout,					// enable PA
	output [15:0] x,y,			// test signals
	output xyv,
	output [15:0] m,				// RSSI and phase correlator
	output [11:0] p,
	output mpv,
	output [15:0] f,t,			// carrier frequency and timing errors
	output ftv,
//	output [15:0] minm,maxm,
//	output [11:0] minp,
	output start,sync,dcd,fcd,	// FFT frame and symbol synchronization
	input clk,						// sample clock
	input rst,						// master reset
	output xmtout					// 0=receive, 1=transmit
	);
// Clock recovery signals
reg ic,dc;						// input counter and data counter
wire iv2,dv;					// 2X (timing) input valid and data valid strobes
wire [15:0] frqerr,tmgerr;	// requency and timing errors
wire dtov;						// output valid
// FIFO input and output signals			
wire [1:0] fsel;				// select 1 of 4 inputs
reg [15:0] fxin,fyin;		// FIFO input
reg fvin;
wire [15:0] fxout,fyout;	// FIFO output
wire fvout;
wire rstfifo;					// reset FIFO (power on or programmed)
// CORDIC input and output signals
wire [1:0] csel;				// select 1 of 4 inputs
reg [15:0] cxin,cyin;		// CORDIC input
reg [15:0] czin;
reg cvin,rotate;
wire [15:0] cxout,cyout,czout;	// CORDIC outputs
wire cvout;
// BFO
reg [15:0] bfofrq,bfophs;	// BFO for SSB mod/demod
// sync and null detect logic
wire [15:0] rssi;				// signal strength output
wire [11:0] phscor;			// phase correlation output
wire rssiv;						// above signals valid
wire rstdet;					// initialize sync/null detector
// FM/PM conversion
reg [15:0] xin,yin,frqout,magout;
wire [15:0] dlyphs;
reg vin,fmov;
// full carrier detect
wire ftc;						// frequency lock
wire [15:0] frqofs;			// frequency offset
// receiver busy logic
reg [11:0] bsyctr;			// channel busy counter
reg [7:0] bsydly;				// channel busy delay configuration register
wire bsy;						// channel busy
// configuration data
reg xmt,ptt;			// T/R switch
reg fm,ssb,tre,cre;	// select FM/PM, SSB, timing recovery and carrier recovery
reg [3:0] dly;			// FM detector phase difference
reg nfl,sfs;			// carrier detect config.
// output multiplexer
reg [15:0] dmux;		// delay output 1 clock cycle as reads take 2 cycles
// decode address
wire w0,w1,w2,w3,w4,w5,w6,w7,r1;	// port selects
assign w0 = iocs & (ioaddr == 0) & iowr;	// write X data (X or M)
assign w1 = iocs & (ioaddr == 1) & iowr;	// write Y data (Q or P)
assign w2 = iocs & (ioaddr == 2) & iowr;	// select mode
assign w3 = iocs & (ioaddr == 3) & iowr;	// busy logic
assign w4 = iocs & (ioaddr == 4) & iowr;	// phase sync.
assign w5 = iocs & (ioaddr == 5) & iowr;	// null det.
assign w6 = iocs & (ioaddr == 6) & iowr;	// clock divider
assign w7 = iocs & (ioaddr == 7) & iowr;	// T/R switch
assign r1 = iocs & (ioaddr == 1) & iord;	// read data
//configuration registers
always @ (posedge clk)
begin
	if (rst) sfs <= 0;					// long frequency sample by default
	else if (w2) sfs <= din[9];
	if (rst) nfl <= 0;					// wide frequency limit by default
	else if (w2) nfl <= din[8];
	if (rst) dly <= 0;					// default FM rcv delay is 1 sample
	else if (w2) dly <= din[7:4];
	if (rst) cre <= 0;					// no carrier recovery by default
	else if (w2) cre <= din[3];
	if (rst) tre <= 0;					// no timing recovery by default
	else if (w2) tre <= din[2];
	if (rst) ssb <= 0;					// AM/PM or AM/FM by default
	else if (w2) ssb <= din[1];
	if (rst) fm <= 0;						// AM/PM by default
	else if (w2) fm <= din[0];
	if (rst) bfofrq <= 0;				// default to DC
	else if (w6) bfofrq <= din[15:0];
	if (rst) ptt <= 0;					// default to PA off
	else if (w7) ptt <= din[3];
	if (rst) xmt <= 0;					// default to receive
	else if (w7) xmt <= din[0];
end
// FIFO reset command
assign rstfifo = rst | (w7 & din[1]);
assign rstdet = w7 & din[2];
// phase accumulator for FSK and FM modulation
// pass-through for SSB, ISB, PSK and PM modulation
always @ (posedge clk)
begin
	if (w0) xin <= din;	// delay X to match Y
	if (rst) yin <= 0;	// for simulation
	else if (w1) yin <= din + (fm ? yin : 16'h0000);
	vin <= w1;				// delay data strobe
end
// connect demodulator, clock recovery, receiver input or transmitter input to FIFO
// XMT SSB TRE Port
//  0   1   x   0   RCV SSB/ISB
//  0   0   0   1   RCV AM/PM/FM
//  0   0   1   2   RCV PSK/FSK
//  1   x   x   3   XMT
assign fsel = ({~ssb,~ssb} & {tre,~tre}) | {xmt,xmt};
always @ (posedge clk)
begin
	case (fsel)
	0: fxin <= cxout;				// demodulator X output (SSB/ISB)
	1: fxin <= magout;			// demodulator magnitude output (AM)
	2: fxin <= tmgerr;			// recovered timing error (PSK/FSK)
	3: fxin <= xin;				// transmit X input
	default: fxin <= 16'hxxxx;
	endcase
	case (fsel)
	0: fyin <= cyout;				// demodulator Y output (SSB/ISB)
	1: fyin <= frqout;			// demodulator phase or frequency output (PM/FM)
	2: fyin <= cre ? frqerr : {magout[15:8],frqout[15:8]};	// frequency error or data sample
	3: fyin <= yin;				// transmit Y input
	default: fyin <= 16'hxxxx;
	endcase
	case (fsel)
	0: fvin <= cvout;				// demodulator output valid
	1: fvin <= fmov;				// demodulator frequency output valid
	2: fvin <= fm ? dtov : fmov;	// timing error valid later if FSK
	3: fvin <= vin;				// X and Y inputs valid (Y write)
	default: fvin <= 1'bx;
	endcase
end
// 15 entry x 32 bit FIFO
// receives 32-bit data input on transmit and multiplexer output on receive
fifo16x32s fifo (
	.pdi({fxin,fyin}),	// FIFO
	.iv(fvin),				// FIFO output valid
	.oe(xmt ? toe : r1),	// enable output (r1 = read Y)
	.pdo({fxout,fyout}),
	.ov(fvout),				// output valid (gated with OE)
	.empty(empty),
	.full(full),
	.clk(clk),
	.rst(rstfifo)			// special reset line
	);
// increment BFO phase with every input
always @ (posedge clk)
begin
	if (~ssb) bfophs <= 0;
	else if (cvin) bfophs <= bfophs + bfofrq;
end
// CORDIC input multiplexer
// XMT SSB TRE Port
//  0   X   0   0   RCV SSB/AM/PM/FM 
//  0   X   1   1   RCV PSK/FSK
//  1   1   X   2   XMT SSB
//  1   0   X   3   XMT AM/PM/FM/PSK/FSK
assign csel = {xmt,xmt ? ~ssb : tre};
always @ (posedge clk)
begin
	case (csel)
	0: cxin <= rdix;		// receiver input
	1: cxin <= rdix;
	2: cxin <= fxout;		// SSB/ISB transmit X
	3: cxin <= fxout;		// AM/PM/FM transmit amplitude
	default: cxin <= 16'hxxxx;
	endcase
	case (csel)
	0: cyin <= rdiy;		// receiver input
	1: cyin <= rdiy;
	2: cyin <= fyout;		// SSB/ISB transmit Y
	3: cyin <= 16'h0000;	// unused for AM/PM/FM transmit
	default: cyin <= 16'hxxxx;
	endcase
	case (csel)
	0: czin <= bfophs;	// receiver BFO or 0 (SSB bit selects BFO)
	1: czin <= bfophs;
	2: czin <= bfophs;	// SSB/ISB transmit BFO
	3: czin <= fyout;		// AM/PM/FM transmit phase
	default: czin <= 16'hxxxx;
	endcase
	case (csel)
	0: cvin <= riv;		// receiver input valid
	1: cvin <= fm ? riv : dv;	// process all FSK samples but only data PSK samples
	2: cvin <= fvout;		// FIFO output valid
	3: cvin <= fvout;
	default: cvin <= 1'bx;
	endcase
	//	0: vector mode for AM/PM/FM receive or rotate mode for SSB receive
	//	1: vector mode for AM/PM/FM receive or rotate mode for SSB receive
	//	2: rotate mode for AM/FM/PM transmit
	//	3: rotate mode for SSB transmit
	rotate <= xmt | ssb;
end
// CORDIC engine to convert between 18x18 rectangular and 16x16 polar signals
cordic16s16a prc (
	.xi(cxin),	// 16-bit inputs
	.yi(cyin),
	.zi(czin),
	.mi(rotate),	// 0 = calculate arctangent, 1 = rotate X and Y inputs
	.load(cvin),
	.xo(cxout),		// 16-bit outputs
	.yo(cyout),
	.zo(czout),
	.mo(),			// unused
	.rdy(cvout),
	.clk(clk),		// common clock and reset
	.rst(rst)
	);
// filter phase for sync. detect and filter magnitude for RSSI
nulsyndet nsd (
	.mag(cxout),	// magnitude and phase inputs
	.phs(czout[15:8]),
	.iv(cvout),
	.init(rstdet),	// initialize min/max and reset flags
	.rssi(rssi),	// average magnitude and phase difference outputs
	.phscor(phscor),
	.ov(rssiv),
//	.minm(minm),	// test signals
//	.maxm(maxm),
//	.minp(minp),
	.start(start),	// null symbol and CP detect outputs
	.sync(sync),
	.dcd(dcd),
	.clk(clk),		// common clock and reset
	.rst(rst),
	.cin(din),		// configuration data input
	.cwe({w5,w4})	// write configuration data strobe
	);
// channel busy logic
always @ (posedge clk)
begin
	if (rst) bsydly <= 128;									// default is 1024 sym.
	else if (w3) bsydly <= din[7:0];						// config. delay
	if (rst) bsyctr <= 0;									// not busy when reset
	else if (dcd) bsyctr <= {bsydly,4'b1111};			// preset when carrier
	else if (cvout & bsy) bsyctr <= bsyctr - 1'b1;	// else count down
end
assign bsy = |bsyctr;	// busy when not zero
// Phase memory for FM detection - 1-16 sample delay
srl16x16e phsdly (
	.d(czout),
	.a(dly),
	.y(dlyphs),
	.clk(clk),
	.ce(cvout)
	);
// latch magnitude and calculate phase difference - 1 clock delay
always @ (posedge clk)
begin
	if (cvout) magout <= cxout;	// required for serial multiplier
	if (cvout) frqout <= czout - (fm ? dlyphs[15:0] : 16'h0000);
	fmov <= cvout;			// differentiator delay
end
// detect carrier and measure frequency offset
fsyn cardet (
	.mag(magout),		// magnitude and phhase inputs
	.frq(frqout),
	.fmv(fmov),			// input valid
	.avgfrq(frqofs),	// frequency offset output
	.fcd(ftc),			// output valid
	.clk(clk),
	.nfl(nfl),			// narrow frequency limit
	.sfs(sfs)			// short frequency sample
	);
// count samples for timing recovery with samples at 2 or 4 times Baud rate
always @ (posedge clk)
begin
	if (rst) ic <= 0;	// count samples to convert 4X sampling to 2X sampling
	else if (riv) ic <= ~ic;
	if (rst) dc <= 0;	// count samples to identify data samples
	else if (iv2) dc <= ~dc;
end
assign iv2 = fm ? (fmov & ic) : riv;	// FM divides sample rate by 2
assign dv = (iv2 & dc);						// alternate samples are data samples
// calculate receiver timing error for resampler adjustment
clkrec rxclk (
	.dix(fm ? frqout[15:8] : rdix[15:8]),	// upper 8 bits of I or frequency
	.diy(fm ? 8'h00 : rdiy[15:8]),			// upper 8 bits of Q or zero
	.iv(iv2),		// input valid at 2x sample clock
	.fv(dv),			// valid data sample
	.tout(tmgerr),	// timing error
	.fout(frqerr),	// frequency error
	.ov(dtov),		// output valid
	.clk(clk),
	.rst(rst)
	);
// collect status information via synchronous multiplexer
always @ (posedge clk)
begin
	case (ioaddr[2:0])
	0: dmux <= fxout;						// modem FIFO LSW
	1: dmux <= fyout;						// modem FIFO MSW
	2: dmux <= rssi;						// received signal strength indication
	3: dmux <= {empty,full,dcd,ftc,phscor};	// flags & phase correlator
	4: dmux <= frqofs;					// average frequency offset
	5: dmux <= {empty,full,dcd,ftc,bsy,11'h000};	// all flags
	6: dmux <= 16'h0000;					// unused
	7: dmux <= 16'h0000;					// unused
	default: dmux <= 16'hxxxx;
	endcase
end
// connect outputs
assign dout = dmux;
assign tdox = cxout;
assign tdoy = cyout;
assign tov = cvout;
assign xmtout = xmt;
assign pttout = ptt;
// connect test signals
assign x = magout;
assign y = frqout;	// M012
assign xyv = fmov;	// M012
assign m = rssi;
assign p = phscor;
assign mpv = rssiv;
assign f = frqerr;
assign t = tmgerr;
assign ftv = fm ? dtov : fmov;	// matches FIFO
assign fcd = ftc;
endmodule

//
//			dem18f.v - Demodulator with 18-bit Input and 16-bit Output	
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module provides carrier detection and frequency measurement for OFDM applications.
// 
// When receiving, the received signal is present in rectangular form with the in-phase
// component on RDIX and the quadrature component on RDIY. Both inputs are 18-bit signed
// fractions. 
//
// The received signal is then processed by the CORDIC module over the next 20 clock
// cycles. It operates in vector mode and calculates the 16-bit phase and the 16-bit
// magnitude of the signal. The phase can then be differentiated over 1-16 samples to
// measure frequency. 
//
// The synchronization detection module processes the CORDIC output to detect OFDM null
// symbols and symbol timing errors. Nulls are detected by averaging the signal magnitude
// over a symbol period and detecting the minimum. Timing errors are detected by comparing
// the phase of the received signal between points one FFT interval apart and performing a
// moving average over the interval of the cyclic prefix. The error signal is minimized
// when the end of the symbol is reached. 
//
// The demodulator module is configured via 6 output ports:
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |                       |SFS|NFL|  FM Delay - 1 |           |FM | Modem Config.
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 3 |                               |          Busy Delay           | (Ts/16)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |     CP Length - 1     |                FFT Size               | Phase Correlator
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  5 |       SOF Delay       |   |           Symbol Length           | Magnitude Filter
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  6 |                     Minimum Magnitude                         |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  7 |                                               |PTT|INI|   |XMT| Command
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		FM: 0 = PM, 1 = FM
//		NFL: narrow frequency limit (0 = +/-Fs/16, 1 = +/-Fs/32)
//		SFS: short frequency sample (0 = 1024-sample average, 1 = 512-sample averge)
//		XMT: configure tuner and modem (0=receive, 1=transmit)
//		INI: Initialize sync detect logic for new symbol
//		PTT: configure external amplifiers (0=receive, 1=transmit)
//
// There are 4 input ports to read status:
//
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |                   Avgerage Magnitude (RSSI)                   | M
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |   |   |DCD|FCD|               Phase Correlator                | P
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |                       Frequency Offset                        |
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  5 |   |   |DCD|FCD|BSY| 0   0   0   0   0   0   0   0   0   0   0 | 
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		DCD - data carrier detect (minimum amplitude)
//		FCD - full carrier detect (minimum amplitude and acceptable offset for 1088 samples)
//    BSY - channel busy (data carrier detect plus interframe delay)
//
// 1824 LUT6s (12% xc6slx25) and 1632 registers are used. Maximum clock speed is 141 MHz (-2).
//
// History:
//		2013-10-5	create from modem16a (was 1200 LUT, 839 reg, 125 MHz)
//
module dem18f (
	input iocs,						// select this module
	input [2:0] ioaddr,			// I/O port address
	input [15:0] din,				// data input bus
	output [15:0] dout,			// data output bus
	input iowr,						// write to I/O port
	input iord,						// read from I/O port
	input [17:0] rdix,rdiy,		// receiver input
	input riv,						// valid input
	output pttout,					// enable PA
	output [15:0] x,y,			// test signals
	output xyv,
	output [15:0] m,				// RSSI and phase correlator
	output [11:0] p,
	output mpv,
//	output [15:0] minm,maxm,
//	output [11:0] minp,
	output start,sync,dcd,fcd,	// FFT frame and symbol synchronization
	input clk,						// sample clock
	input rst,						// master reset
	output xmtout					// 0=receive, 1=transmit
	);
// Input Latch
reg [17:0] rdix0,rdiy0;
reg riv0;
// CORDIC signals
wire [15:0] cxout,cyout,czout;	// CORDIC outputs
wire cvout;
// sync and null detect logic
wire [15:0] rssi;		// signal strength output
wire [11:0] phscor;	// phase correlation output
wire rssiv;				// above signals valid
wire init;				// initialize sync/null detector
// FM/PM conversion
reg [15:0] xin,yin,frqout,magout;
wire [15:0] dlyphs;
reg vin,fmov;
// full carrier detect
wire ftc;				// frequency lock
wire [15:0] frqofs;	// frequency offset
// receiver busy logic
reg [11:0] bsyctr;	// channel busy counter
reg [7:0] bsydly;		// channel busy delay configuration register
wire bsy;				// channel busy
// configuration data
reg xmt,ptt;			// T/R switch
reg fm;					// select FM/PM
reg [3:0] dly;			// FM detector phase difference
reg nfl,sfs;			// carrier detect config.
reg [15:0] minmag;	// magnitude limit
// output multiplexer
reg [15:0] dmux;		// delay output 1 clock cycle as reads take 2 cycles
// decode address
wire w2,w3,w4,w5,w6,w7;	// port selects
assign w2 = iocs & (ioaddr == 2) & iowr;	// select mode
assign w3 = iocs & (ioaddr == 3) & iowr;	// busy logic
assign w4 = iocs & (ioaddr == 4) & iowr;	// phase sync.
assign w5 = iocs & (ioaddr == 5) & iowr;	// null det.
assign w6 = iocs & (ioaddr == 6) & iowr;	// mag. limit
assign w7 = iocs & (ioaddr == 7) & iowr;	// T/R switch
//configuration registers
always @ (posedge clk)
begin
	if (rst) sfs <= 0;					// long frequency sample by default
	else if (w2) sfs <= din[9];
	if (rst) nfl <= 0;					// wide frequency limit by default
	else if (w2) nfl <= din[8];
	if (rst) dly <= 0;					// default FM rcv delay is 1 sample
	else if (w2) dly <= din[7:4];
	if (rst) fm <= 0;						// AM/PM by default
	else if (w2) fm <= din[0];
	if (rst) minmag <= 256;				// FS/256 default
	else if (w6) minmag <= din;
	if (rst) ptt <= 0;					// default to PA off
	else if (w7) ptt <= din[3];
	if (rst) xmt <= 0;					// default to receive
	else if (w7) xmt <= din[0];
end
assign init = w7 & din[2];	// initialize synchronization detector
// Latch Inputs
always @ (posedge clk)
begin
	rdix0 <= rdix;
	rdiy0 <= rdiy;
	riv0 <= riv;
end
// CORDIC engine to convert between 18x18 rectangular and 16x16 polar signals
cordic18p16v prc (
	.xi(rdix0),	// 18-bit inputs
	.yi(rdiy0),
	.iv(riv0),
	.xo(cxout),	// 16-bit outputs
	.zo(czout),
	.ov(cvout),
	.clk(clk)	// common clock
	);
// filter phase for sync. detect and filter magnitude for RSSI
nulsyndet nsd (
	.mag(cxout),	// magnitude and phase inputs
	.phs(czout[15:8]),
	.iv(cvout),
	.init(init),	// initialize min/max and reset flags
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
fsyna cardet (
	.mag(magout),		// magnitude and phase inputs
	.frq(frqout),
	.fmv(fmov),			// input valid
	.avgfrq(frqofs),	// frequency offset output
	.fcd(ftc),			// output valid
	.clk(clk),
	.minmag(minmag),	// minimum magnitude
	.nfl(nfl),			// narrow frequency limit
	.sfs(sfs)			// short frequency sample
	);
// collect status information via synchronous multiplexer
always @ (posedge clk)
begin
	case ({ioaddr[2],ioaddr[0]})		// map to ports 2,3,4,5
	0: dmux <= rssi;						// received signal strength indication
	1: dmux <= {2'b00,dcd,ftc,phscor};	// flags & phase correlator
	2: dmux <= frqofs;					// average frequency offset
	3: dmux <= {2'b00,dcd,ftc,bsy,11'h000};	// all flags
	default: dmux <= 16'hxxxx;
	endcase
end
// connect outputs
assign dout = dmux;
assign xmtout = xmt;
assign pttout = ptt;
// connect test signals
assign x = magout;
assign y = frqout;	// M012
assign xyv = fmov;	// M012
assign m = rssi;
assign p = phscor;
assign mpv = rssiv;
assign fcd = ftc;
endmodule

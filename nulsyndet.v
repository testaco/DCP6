//
//					nulsyndet.v - Detect Null Symbol and Cyclic Prefix
//
//						(C) Copyright 2004-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module contains a phase correlator for measuring OFDM symbol alignment by
// comparing the cyclic prefix (CP) and end of symbol phase. It also detects null
// symbols my averging signal magnitude over a symbol length including the CP.
//
// Two registers are used to configure this module.
//
//    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 0 |     CP Length - 1     |               FFT Size                | Phase Correlator
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 1 |         Delay         | H |           Symbol Length           | Magnitude Filter
//   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		H: 0 = low sensitivity (-12 dB), 1 = high sensitivity (-6 dB)
//
// FFT Size is the distance between samples for phase correlation and CP (cyclic prefix)
// Length is the number of correlator output samples to be averaged. This average is the
// difference in phase between two segments of the received signal. It is continuously
// examined and a minimum value updated. The end of a symbol is detected when the cyclic
// prefix and the end of the symbol are compared and the minimum stops decreasing. Delay
// is the delay in samples between the minmum phase difference in the input signal and
// the synchronization output. A counter is set to this value every time the minimum
// phase difference value is updated and the sync flag is pulsed when the counter reaches
// zero. Only the MS six bits of phase input are used.
//
// Symbol Length is the number of samples to be averaged to obtain the received signal
// strength indication (RSSI). The minimum and maximum magnitude values are continuously
// calculated. A null symbol is detected when the current minimum magnitude is less than
// 1/4 of the maximum magnitude. The end of a null symbol is detected when the minimum
// magnitude stops decreasing. Delay is the delay in samples between the minmum magnitude
// of the input signal and the start of frame output. A counter is set to this value
// every time the minimum magniude value is updated and the start flag is pulsed when the
// counter reaches zero. The init input resets the maximum magnitude register.
//
// The RSSI output is the average magnitude over the Symbol Length. The phase correlation
// output is the average phase difference between the previous CP Length samples and the
// same number of samples FFT Size samples earlier.
//
// S3E: 212 slices plus 1 RAM are used and the maximum clock frequency is 126 MHz.
// S6: 283 LUTs, 209 registers and 1 RAM are used and the maximum clock frequency is 138 MHz.
//
// History:
//		12-22-09	Add maximum and minimum magnitude latches plus sync. delay.
//		3-3-10	Add -6/-12 dB setting for null symbol detection (no additional LUTs)
//		3-11-10	Add DCD output
//		12-8-10	eliminated unused port and increment truncation warnings for Spartan-6
//
// Normal Warnings:
//		Signal <dlyphs<1:0>> is assigned but never used.
//
module nulsyndet (phs,mag,iv,init,start,sync,dcd,rssi,phscor,ov,clk,rst,cin,cwe);
//		,minm,maxm,minp);
	input [7:0] phs;		// input signal instantaneous phase and magnitude
	input [15:0] mag;
	input iv;				// inputs valid
	input init;				// initialize min/max magnitude registers
	output start;			// start of frame detected flag
	output sync;			// start of symbol detected flag
	output dcd;				// data carrier detect (sufficient signal magnitude)
	output [15:0] rssi;	// average magnitude of signal
	output [11:0] phscor;// phase correlation output
	output ov;				// outputs valid
	input clk;				// master clock
	input rst;				// master reset
	input [15:0] cin;		// configuration input
	input [1:0] cwe;		// write enable
//	output [15:0] minm,maxm; // test signals
//	output [11:0] minp;
// internal busses
reg [9:0] addra;			// RAM address busses
reg [8:0] addrb;
wire tca,tcb;				// terminal counts
reg [23:0] accmag;		// magnitude accumulator
wire [7:0] dlyphs;		// RAM outputs
wire [17:0] dlymag;
reg [5:0] difphs;			// phase difference
wire newmin,newmax,newminphs;
reg [17:0] min,avg,max;	// magnitude latches
wire lowmag;				// low magnitude ragion (null symbol detected)
reg [11:0] minphs,avgphs; // phase latches
wire lowphs;				// low phase error region
reg [5:0] magcnt,phscnt;// minimum mag/phs delay counters
wire zero,zerophs;		// counters equal to zero
reg zerodly,zerophsdly;	// delay zero detect
reg magff,phsff;			// flags set at min. mag. & min. phase error
wire [11:0] accphs,dlyacc; // phase difference filter
reg [5:1] v;				//	delayed data valid signal
// configuration registers
reg [9:0] fftsize;		// phase sample delay
reg [8:0] symlen;			// number of magnitude samples to average
reg [5:0] cplen;			// phase difference MAF length
reg [5:0] cpdly;			// magnitude minimum measurement delay
reg hs;						// high sensitivity mode (0=-12dB/1=-6dB)
always @ (posedge clk)
begin
	if (rst) fftsize <= 256;
	else if (cwe[0]) fftsize <= cin[9:0];	// phase correlation window spacing
	if (rst) cplen <= 63;
	else if (cwe[0]) cplen <= cin[15:10];	// pattern length for phase correlation
	if (rst) symlen <= 320;
	else if (cwe[1]) symlen <= cin[8:0];	// null symbol length
	if (rst) hs <= 0;
	else if (cwe[1]) hs <= cin[9];			// null symbol magnitude
	if (rst) cpdly <= 48;
	else if (cwe[1]) cpdly <= cin[15:10];	// delay for minimum detection
	v <= {v[4:1],iv};								// delay data valid
end
// accumulate magnitude for moving-average filter
// increment addresses as phase and magnitude samples stored in RAM
always @ (posedge clk)
begin
	if (rst) accmag <= 0;	// accumulate magnitude input
	else if (iv) accmag <= accmag + {8'h00,mag};
	if (rst | tca) addra <= 0;	// address counter A (phs)
	else if (iv) addra <= addra + 10'b0000000001;
	if (rst | tcb) addrb <= 0;	// address counter B (mag)
	else if (v[1]) addrb <= addrb + 9'b000000001;
end
assign tca = (addra == fftsize);
assign tcb = (addrb == symlen);
// buffer RAM for phase correlation time delay (port A) and magnitude
// moving-average filter (port B) - use block RAM in read first mode
RAMB16_S9_S18 #(
   .WRITE_MODE_A("READ_FIRST"),
   .WRITE_MODE_B("READ_FIRST")
	) dlyram (
	.ADDRA({1'b0,addra}),	// 1024 x 8-bit RAM for phase
	.DIPA(1'b1),
	.DIA(phs),
	.DOPA(),
	.DOA(dlyphs),
	.CLKA(clk),
	.WEA(1'b1),					// always enable write
	.ENA(iv),
	.SSRA(1'b0),
	.ADDRB({1'b1,addrb}),	// 512 x 18-bit RAM for magnitude
	.DIPB(accmag[23:22]),
	.DIB(accmag[21:6]),
	.DOPB(dlymag[17:16]),
	.DOB(dlymag[15:0]),
	.CLKB(clk),
	.WEB(1'b1),					// always enable write
	.ENB(v[1]),
	.SSRB(1'b0)
	);
// calculate difference between direct and delayed outputs
// latch min/max magnitude and count samples past last new minimum
always @ (posedge clk)
begin
	if (v[1]) difphs <= phs[7:2] - dlyphs[7:2];
	if (v[2]) avg <= accmag[23:6] - dlymag;
	if (rst|init) max <= 0;			// max = zero on reset or software initialize
	else if (newmax) max <= avg;
	if (rst|~lowmag) min <= 131071;	// min = +1/2 FS on reset or software initialize
	else if (newmin) min <= avg;
	if (rst) magcnt <= 0;
	else if (newmin & lowmag) magcnt <= cpdly;	// reset counter until minimum magnitude
	else if (v[3] & ~zero) magcnt <= magcnt - 6'b000001;
	zerodly <= zero;
	magff <= zero & ~zerodly;	// one symbol wide pulse
end
assign newmin = v[3] & (avg < min);	// detect new minimum magnitude
assign newmax = v[3] & (avg > max);	// detect new maximum magnitude
assign zero = ~|magcnt;
assign lowmag = avg < (hs ? {1'b0,max[17:1]} : {2'b00,max[17:2]});	// detect magnitude drop
// accumulate absolute value of phase differential for moving-average filter
acc12s pda (
	.SUB(difphs[5]),
	.ACC(1'b1),
	.B({difphs[5],difphs[5],difphs[5],difphs[5],difphs[5],difphs[5],difphs}),
	.Q(accphs),
	.CO(),
	.CLK(clk),
	.CE(v[2]),
	.SCLR(rst)
	);
// phase correlator MAF delay line - select averaging time by selecting shift register tap
srl64x12e phssr (
	.d(accphs),		// data input and output
	.y(dlyacc),
	.a(cplen),		// shift register length select is cyclic prefix length
	.ce(v[3]|rst),	// enable on reset to clear registers
	.clk(clk)
	);
// calculate difference between direct and delayed phase correlator MAF outputs
// latch minimum accumulated phase difference and count samples past last new minimum
always @ (posedge clk)
begin
	if (v[3]) avgphs <= accphs - dlyacc;	// calculate avergae phase error
	if (rst|~lowphs) minphs <= 1023;			// min = >1/4 FS when outside low phase error region
	else if (newminphs) minphs <= avgphs;
	if (rst) phscnt <= 0;
	else if (newminphs & lowphs) phscnt <= cpdly;	// reset counter until minimum phase error
	else if (v[4] & ~zerophs) phscnt <= phscnt - 6'b000001;
	zerophsdly <= zerophs;
	phsff <= zerophs & ~zerophsdly;	// one symbol wide pulse
end
assign newminphs = v[4] & (avgphs < minphs);	// detect point of lowest phase error
assign lowphs = avgphs < {4'h0,cplen,2'b00};	// 0-22.5 degree phase error region
assign zerophs = ~|phscnt;
// assign outputs
assign start = magff;
assign sync = phsff;
assign dcd = ~lowmag;
assign rssi = avg[17:2];
assign phscor = avgphs;
assign ov = v[5];
// test signals
//assign minm = min[17:2];
//assign maxm = max[17:2];
//assign minp = minphs;
endmodule

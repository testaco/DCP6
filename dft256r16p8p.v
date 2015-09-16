//
//		dft256r16p8p.v - 32-256 point FFT/IFFT with Buffer and Control Logic
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// The interface to the FFT/IFFT engine is via a dual-port shared RAM. The I/O address is
// incremented after each read or write. The receiver input (RDIX & RDIY) and transmitter
// output (TDOX & TDOY) are 32-bits wide and carry rectangular data. RIV initiates a write
// during reception and TOE initiates a read during transmission. TOV indicates that the data
// is valid and the buffer is not empty. Transmitter input and receiver output are bufferred
// in a second shared RAM that can be directly accessed by the CPU. 
//
// FFT configuration data is mapped onto a 16-bit data bus as 3 registers. FFT Size is the FFT
// or IFFT size in powers of two. FFT length is the number of samples-1 to process in the FFT.
// The cyclic prefix (CP) length is the size of the inter-symbol guard interval. RUN initiates
// the FFT or IFFT and RST reset the base address register to 0. The fourth register is used
// to enable transmission of each symbol. This prevents spurs if the host processor stalls. 
//
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |FWD|                                       | 0 |    FFT Size   | (Resets FFT engine)
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |   |         CP Length         |         FFT Length - 1        |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |                                           |   |SYN|SOF|   |RUN|
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |                                                               |
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   | Scaling Factors (0-3 right shifts)
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 5 |                               |       Offset Increment        | Filter Bank Offset
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		FFT Size - number of samples in FFT/IFFT as power of 2 (5=32, 6=64, 7=128, 8=256)
//		FFT Length - integer number of samples in FFT/IFFT
//		FWD - 0 = IFFT, 1 = FFT
//		SYN - enable FFT sample synchronization based on phase correlation (sync input)
//		SOF - enable FFT when start of frame arrives (SOF input)
//		RUN - enable IFFT (transmission of cyclic prefix starts when first TOE arrives)
// 
// There are 3 control signals that enter and leave the module. XMT puts the module in transmit
// mode. If enabled, SYNC sets the address of the first sample and initiates the FFT. DONE goes
// active for one clock period when the FFT or IFFT is complete and all data in unloaded.
//
// A status register provides access to the following flags:
//
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//    |RDY|BSY|EOF|RUN|SOF|       |            Sync. Phase            | Status
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		RDY - ready for transmit data (xmt=1) or received data ready (xmt=0)
//		BSY - FFT engine busy
//		EOF - end of frame (DCD off at start of sampling period)
//		RUN - sampling data
//		SOF - start of frame (first symbol after null symbol detected)
//
// Polar data (phase and magnitude bytes) may be read from or written into a 256-byte buffer. The
// buffer address is generated internally. When transmitting, TRST resets the address to zero. The
// buffer is formatted so that the DC subcarrier is at address 0. TIV indicates that the transmit
// data on TMAG and TPHS is valid, causing the data to be written to the buffer and the address to
// be incremented or decremented. Data is written in a spiral format (0,-1,+1,-2,+2...). The
// following example shows the format for a 32-point FFT with 12 LSB and 12 USB subcarriers:
//
//     1 1 1 1 1 1 1                 -   +                 1 1 1 1 1 1
//     6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 Subcarrier
//    +---------------------------------------------------------------+
//    |0 0 0 0 D D D D D D D D D D D D C D D D D D D D D D D D D 0 0 0|
//    +---------------------------------------------------------------+
//     7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 Address (base 16)
//     0 1 2 3 4 5 6 7 8 9 A B C D E F 0 1 2 3 4 5 6 7 8 9 A B C D E F
//
//		C = carrier
//		D = data subcarriers
//		0 = unused subcarriers
//
// Note that the unused subcarriers must be written with a magnitude of zero (32 total writes). The
// OFDM symbol is transmitted when the RUN flag is set. Transmission will continue with successive
// symbols until the RUN flag is reset. The buffer should be loaded before RUN is set and then
// reloaded every time the RDY status flag is set. Reading status resets the RDY flag.
//
// The transmit data stored in this buffer is formatted so that the upper nibble is the subcarrier
// magnitude and the lower nibble is the subcarrier phase. Received phase is 8 bits with 1.4 degree
// resolution and transmitted phase is 4 bits with 22.5 degree resolution. Received magnitude is
// not stored. Transmitted magnitude is 4 bits where 0-3 = no signal, 4 = -33 dBc, 5 = -30 dBc ...
// 14 = -3 dBc and 15 = 0 dBc.
//
//      7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+
//    |             Phase             | Receive
//    +---+---+---+---+---+---+---+---+
//    |   Magnitude   |     Phase     | Transmit
//    +---+---+---+---+---+---+---+---+
//
// Received phase is the current symbol phase minus the previous symbol phase (phase difference).
// Transmitted phase is absolute when REFSYM is one or relative when REFSYM is zero (previous phase
// plus current phase).
//
// When an OFDM symbol is received, RRST is active for one clock cycle and then ROV becomes active if
// the ROE input is active. 8 bits of received subcarrier phase appear on RPHS in the order (0,-1,+1,
// -2,+2...). The sequence starts when ROE becomes active and may be interrupted when ROE is inactive.
//
// 1460 LUT6s (9%), 1465 registers, 3 RAMs and 4 DSP48s used. 149 (-2) MHz maximum clock rate.
// The longest path is the FFT start signal.
//
//	History:
//		12-8-10	fixed unused port and trucation warnings for Spartan-6
//		12-28-10	increased phase accuracy from 5 to 8 bits using parallel CORDIC implementation
//		1-27-11	added offset accumulator to allow use in filter bank
//		10-28-11	use 64x8 ROMs for P->R (free 8k RAM)
//		1-18-12	add 4-entry FIFO logic to use spare 8k RAM
//		1-21-12	add sync. input for transmit (use modem for carrier gen.)
//		2-7-12	add EOF entry to FIFO
//		3-15-12	4-bit magnitude with 3dB steps with async. ROMs and sync. mux (was 1495 LUTs, 1504 regs)
//		3-22-12	add compander enable
//		2-19-13	use FFT v7.1 (was 4 RAM, 3 DSP48, 1511 LUT, 1508 reg)
//		9-27-13	use radix-2 FFT (3 mult.)
//
// Normal Warnings:
//		<status<9>> and <status<10>> have a constant value of zero.
//		<accy7<6:0>> and <accz8<3:0>> unconnected.
//		<accz1<8:0>> has a constant value of zero.
//		<accz1<9>> has a constant value of one.
//
module dft256r16p8p(
	 output [8:0] w,				// TEST
	 output [7:0] x,y,
	 input iocs,					// I/O interface
	 input [2:0] ioaddr,
	 input [15:0] din,
	 input iowr,
	 output [15:0] dout,
	 input iord,
	 input trst,					// transmitter input reset
	 input refsym,					// 0 = incremental phase, 1 = absolute phase
	 input [3:0] tmag,tphs,		// transmitter magnitude and phase inputs
	 input tiv,						// transmitter input valid
	 input toe,						// transmitter output enable
	 output [15:0] tdox,tdoy,	// transmitter rectangular data output
	 output tov,					// transmitter output valid
	 output ten,					// IFFT enable
	 output cpe,					// compander enable
    input [15:0] rdix,rdiy,	// receiver rectangular data input
    input riv,						// receiver input valid
	 output rrst,					// reset decoder
	 input roe,						// receiver output enabale
	 output [7:0] rphs,			// received phase (differential)
	 output rov,					// receiver output valid
	 output reof,					// received end of frame
    input clk,rst,				// master clock and reset
	 input xmt,						// receive = 0, transmit = 1
	 input sof,						// null symbol detected, start sampling
	 input sync,					// synchronize sample counter to symbol timing
	 input dcd,						// data carrier detect
	 output intr					// FFT/IFFT done interrupt
	 );
// configuration and status registers
reg [3:0] fftsize;				// copy for address multipexer
reg [7:0] fftlen;					// number of samples in FFT
reg [6:0] cplen;					// cyclic prefix length
reg [7:0] offset,ofsinc;		// offset accumulator and increment
reg runrx,runtx;					// FFT/IFFT enables
wire run;
reg ensof,ensyn;					// FFT receive timing mode control
reg encmp;							// enable compander
wire rstctr;						// reset to start of FFT/IFFT sample interval
reg txe;								// transmit enable flag
reg tc0;								// transmit first symbol flag
// buffer memory address busses and counter control signals
reg swapt,swapf;					// MSB of time-indexed buffer address (I/O and FFT sides)
wire ce,ld;							// sample counter clock enable and load
reg [8:0] sctr,sphs;				// port A sample counter and sync pulse position
wire [7:5] amask;					// port A address mask
wire [7:0] maddra,maddrb;		// port A and B addresses
wire tc;								// terminal count for address A
// FFT busses and control signals
reg [15:0] rx1,ry1;				// delay for time-ordered buffer memory input
wire [15:0] rx,ry;				// input from memory (R)
wire [7:0] tx0,ty0;				// ROM outputs to shifter
reg [11:0] tx,ty;					// constellation map output (T)
reg [15:0] nx,ny;					// FFT/IFFT input multiplexer
wire [15:0] kx,ky;				// FFT/IFFT output
wire [3:0] magin,phsin;			// IFFT input in polar form
wire [7:0] magout,phsout;		// FFT output in polar form
wire [7:0] phsref;				// phase reference
wire [3:0] phsinc;				// phase increment (tx)
wire [7:0] phsdif;				// phase difference (rx)
wire pmov;							// phase/magnitude output valid (RAM WE)
reg pmov1;							// delayed for data read/write completion strobe
wire ifftstart;					// FFT input data transferred
wire fftdone,ifftdone;			// FFT output data transferred
wire rcvrdy,xmtrdy;				// ready for FFT or IFFT
wire [7:0] naddr,kaddr;			// addresses from FFT logic
reg [7:0] a1,a2,a3,a4,a5,a6,a7,a8,a9;	// K index delay (to match CORDIC)
wire [7:0] a9m;					// muliplexed K and N addresses
reg [7:0] faddr;					// FFT address output delayed to match data timing
wire fftrfd,fftbusy,fftdv;		// FFT status
reg fftdv0,fftrfd0,fftrfd1;	// FFT status delayed 1 and 2 clock cycles
wire start;							// start FFT or IFFT
wire unload;						// start unloading FFT output buffer
reg [2:1] v;						// data valid delay
reg sff;								// start of frame flag
reg sf,ef,rdy;						// start/end of frame and ready status flags
wire busy;							// FFT engine busy
// Subcarrier buffer
reg [7:0] maddr,mstep;			// SC address and increment
wire mwe;							// write enable
reg [15:0] data,status;			// data and status output registers
reg [7:0] m0,p0;					// zero frequency magnitude and phase registers
reg z;								// FFT output index is zero
// decode addresses
wire wr0,wr1,wr2,wr3,wr4;
assign wr0 = iocs & (ioaddr == 0) & iowr;	// FFT size and transform type
assign wr1 = iocs & (ioaddr == 1) & iowr;	// FFT length and cyclic prefix length
assign wr2 = iocs & (ioaddr == 2) & iowr;	// enable transmission or reception
//assign wr3 = iocs & (ioaddr == 3) & iowr;	// start transmission
assign wr4 = iocs & (ioaddr == 4) & iowr;	// load scaling schedule
assign wr5 = iocs & (ioaddr == 5) & iowr;	// load offset decrement
// Configuration Registers
always @ (posedge clk)
begin
	if (wr0) fftsize <= din[3:0];		// FFT size as binary exponent
	if (wr1) fftlen <= din[7:0];		// FFT length
	if (wr1) cplen <= din[14:8];		// CP length
	if (rst) ofsinc <= 0;
	else if (wr5) ofsinc <= din[7:0];	// amount to decrement offset accumulator
	if (~ensof) runrx <= 0;				// controls FFT sampling for reception
	else runrx <= runrx | (ensof & sof);				
	if (rst) runtx <= 0;					// controls IFFT sampling for transmission
	else if (wr2) runtx <= din[0];
	if (rst) ensof <= 0;					// enables start input for FFT during reception
	else if (wr2) ensof <= din[2];
	if (rst) ensyn <= 0;					// enables external synchronization input
	else if (wr2) ensyn <= din[3];
	if (rst) encmp <= 0;					// enables compander
	else if (wr2) encmp <= din[4];
	if (~runtx) txe <= 0;				// wait for first symbol before transmitting
	else txe <= ifftdone | txe;
end
assign rstctr = ~run | (ensyn & sync);	// reset counter
assign run = runtx|runrx;					// enable FFT
// Sample counter increments when receiver input present or transmitter output requested and is used
// to create memory address. Buffer halves swapped when counter reaches maximum (fftlen) and address
// set to negative of cyclic prefix (CP) length. note that the one's complement of the CP length is
// loaded so that the increment creates the two's complement. Sample counter and swap bit are reset
// until run bit set. Offset accumulator incrmented at beginning of each FFT or IFFT.
always @ (posedge clk)
begin
	if (~run) swapt <= 1'b0;	// buffer swap bit toggles buffer halves
	else if (ce) swapt <= ld ^ swapt;
	if (rstctr) sctr <= 0; 		// sample counter
	else if (ce) sctr <= (ld ? {2'b11,~cplen} : sctr) + 9'b000000001;
	if (rst|~xmt) tc0 <= 0;		// transmit first symbol flag (loads CP addr.)
	else tc0 <= (wr2 & din[0]) | (tc0 & ~(toe & txe));	// set when transmitter started and reset when symbol sent
	v <= {v[1],xmt & toe};
	if (~|ofsinc) offset <= 0;	// no offset if increment is zero
	else if (start) offset <= offset + ofsinc;
end
assign rcvrdy = tc & riv & ~xmt;				// start FFT when input buffer filled
assign xmtrdy = ((wr2 & din[0]) | (ld & toe & txe)) & xmt;	// start IFFT immediately and each time output buffer emptied
assign ce = xmt ? (toe & txe) : riv;		// sample count enabled when output available or input valid
assign tc = (sctr == {1'b0,fftlen});		// terminal count active when FFT length reached
assign ld = tc | tc0;							// load sample counter with cyclic prefix starting address
assign start = (rcvrdy & dcd) | xmtrdy;	// start FFT or IFFT
assign tov = v[2];
// mask address to match FFT length (for transmitting CP)
//  Length:  32  64 128 256
//    Mask: 000 001 011 111
assign amask[5] = (fftsize > 5);
assign amask[6] = (fftsize > 6);
assign amask[7] = (fftsize > 7);
assign maddra = {(sctr[7:5] & amask[7:5]),sctr[4:0]};
assign maddrb = offset + (xmt ? kaddr : naddr);	// FFT side address
// signal buffer memory - 512 x 32
// port A is I/O and port B is FFT
RAMB16_S36_S36 tbuf (
	.ADDRA({swapt,maddra}),	// I/O address
	.ADDRB({~swapt,maddrb}),// internal address
	.DIA({rdix,rdiy}),		// data input
	.DIPA(4'hF),
	.DIB({kx,ky}),				// IFFT output
	.DIPB(4'hF),
	.DOA({tdox,tdoy}),		// data output
	.DOPA(),
	.DOB({rx,ry}),				// FFT input
	.DOPB(),
	.CLKA(clk),					// I/O clock
	.CLKB(clk),					// internal clock
	.WEA(riv & ~sctr[8]),	// write received data when not in CP
	.WEB(xmt & fftdv),		// write tranmitter data
	.ENA(1'b1),
	.ENB(1'b1),
	.SSRA(~txe),				// transmit enable
	.SSRB(1'b0)
	);
// FFT multiplexer and input delay - 2 clocks added to RAM delay
always @ (posedge clk)
begin
	rx1 <= rx;
	ry1 <= ry;
	nx <= xmt ? {tx,4'h0} : rx1;
	ny <= xmt ? {ty,4'h0} : ry1;
end
// Transform rectangular signal between time and frequency domains using 16-bit data
// path and 16-bit coefficient (twiddle factor) size. Start FFT or IFFT when buffer
// swap occurs.
fft256p16 fft (
	.xn_re(nx),					// data input
	.xn_im(ny),
	.xn_index(naddr),
	.xk_re(kx),					// data output
	.xk_im(ky),
	.xk_index(kaddr),
	.start(start),				// control signals
	.unload(unload),
	.rfd(fftrfd),
	.busy(fftbusy),
	.dv(fftdv),
	.edone(unload),
	.done(),
	.fwd_inv(din[15]),		// configuration and reset
	.fwd_inv_we(wr0),
	.nfft(din[4:0]),
	.nfft_we(wr0),
	.scale_sch(din),
	.scale_sch_we(wr4),
	.clk(clk)					// master clock
	);
assign busy = fftrfd | fftbusy | fftdv | fftdv0;	// FFT engine busy loading, processing or unloading
// convert input from polar to Cartesian form - 1 clock delay
// two 64x8 ROMs generate 16PSK with 4 levels of amplitude (0, -3, -6, -9 dBc)
// two 4-input multiplexers add steps of 0 dB, -12 dB, -24 dB or no signal.
rom64x8cos cos (
	.a({magin[1:0],phsin}),
	.spo(tx0)
	);
rom64x8sin sin (
	.a({magin[1:0],phsin}),
	.spo(ty0)
	);
always @ (posedge clk)	// shift 0, 2 or 4 bits right
begin
	case (magin[3:2])
	0: tx <= 12'h000;
	1: tx <= {tx0[7],tx0[7],tx0[7],tx0[7],tx0};
	2: tx <= {tx0[7],tx0[7],tx0,2'b00};
	3: tx <= {tx0,4'b0000};
	default tx <= 12'hxxx;
	endcase
	case (magin[3:2])
	0: ty <= 12'h000;
	1: ty <= {ty0[7],ty0[7],ty0[7],ty0[7],ty0};
	2: ty <= {ty0[7],ty0[7],ty0,2'b00};
	3: ty <= {ty0,4'b0000};
	default ty <= 12'hxxx;
	endcase
end
// convert output from Cartesian to polar form - 10 clock delay
cordic16p8 r2p (
	.xi(kx),				// rectangular input
	.yi(ky),
	.iv(fftdv & ~xmt),
	.xo(magout),		// polar output
	.zo(phsout),
	.ov(pmov),
	.clk(clk)
	);
// generate control signals after last subcarrier written (receive)
always @ (posedge clk)
begin
	pmov1 <= pmov;	// delay phase & magnitude valid
end
assign fftdone = pmov1 & ~pmov & ~xmt;	// generate strobe after last write
assign rov = roe & ~pmov1 & ~xmt;		// data valid when not writing buffer RAM
assign rrst = fftdone;						// reset Viterbi decoder
// delay receive subcarrier address by 9 clock cycles to compensate for CORDIC delay
always @ (posedge clk)
begin
	a1 <= kaddr;
	a2 <= a1;
	a3 <= a2;
	a4 <= a3;
	a5 <= a4;
	a6 <= a5;
	a7 <= a6;
	a8 <= a7;
	a9 <= a8;
end
// multiplex transmit and receive subcarrier addresses
// use N index when transmiting and K index when receiving
assign a9m = (xmt ? naddr : a9);
// FADDR synchronous with data on receive - 2 clock cycles ahead on transmit
// also extend subcarrier index sign to center in buffer around 0
// delay is 1 clock cycle on tranmit and 10 clock cycles on receive
always @ (posedge clk)
begin
	case (fftsize[1:0])
	0: faddr[7:5] <= {a9m[7],a9m[6],a9m[5]}; // 256 => 8
	1: faddr[7:5] <= {a9m[4],a9m[4],a9m[4]}; // 32 => 5
	2: faddr[7:5] <= {a9m[5],a9m[5],a9m[5]}; // 64 => 6 
	3: faddr[7:5] <= {a9m[6],a9m[6],a9m[5]}; // 128 => 7
	default faddr[7:5] <= 3'bxxx;
	endcase
	faddr[4:0] <= a9m[4:0];
	fftdv0 <= fftdv;		// delayed to match RAM/FIFO address input
	fftrfd0 <= fftrfd;	// delayed to match RAM/FIFO address input
	fftrfd1 <= fftrfd0;	// delayed to match FIFO data output
end
// generate strobe after last sample or subcarrier read
assign ifftstart = fftrfd1 & ~fftrfd0 & xmt;
assign ifftdone = fftdv0 & ~fftdv & xmt;
// select FFT address when FFT ready for data or data output valid
// else select memory bus address for reading or writing from CPU
// phase reference memory
// delay address to compensate for delay in RAM
RAM256X8S refphs (
//	.A(xmt ? faddr1 : faddr),			// delay address for transmit
	.A(faddr),								// FFT subcarrier address
	.D(xmt ? {phsin,4'h0} : phsout),	// use transmitted/received phase as next reference
	.O(phsref),
//	.WE(xmt ? fftrfd1 : pmov),
	.WE(xmt ? fftrfd : pmov),
	.WCLK(clk)
	);
assign phsin = phsinc + (refsym ? 4'h0 : phsref[7:4]);	// transmit accumulated phase
assign phsdif = phsout - phsref;									// receive phase difference
assign reof = rcvrdy & ~dcd;										// FFT start time & no signal
// 256 x 8 block RAM for subcarrier phase and magnitude
wire [7:0] bufaddr;
wire [7:0] bufin,bufout;
wire fftio;
assign fftio = xmt ? fftrfd0 : pmov;			// detect IFFT read or FFT write
assign bufaddr = fftio ? faddr : maddr;		// switch between FFT and I/O address
assign bufin = xmt ? {tmag,tphs} : phsdif;	// select buffer input
RAM256X8S scbuf (
	.A(bufaddr),				// read/write address 
	.D(bufin),					// write data 
	.O(bufout),					// read data
	.WE(xmt ? tiv : pmov),	// write enable
	.WCLK(clk)
	);
assign rphs = bufout;			// received phase
assign magin = bufout[7:4];	// transmit magnitude
assign phsinc = bufout[3:0];	// transmit phase
// generate buffer address sequence 0,-1,+1,-2,+2...
always @ (posedge clk)
begin
	if (xmt ? trst : rrst) maddr <= 0;	// start at pilot carrier
	else if (xmt ? tiv : roe) maddr <= maddr + (mstep[0] ? ~mstep : mstep) + mstep[0];
	if (xmt ? trst : rrst) mstep <= 1;	// then decrement by one
	else if (xmt ? tiv : roe) mstep <= mstep + 1'b1;
end
// save start of frame input until first FFT complete
// latch sample counter value when sync occurs
// latch status bits for I/O read to minimize propagation delay (IORD 1 clock long)
always @ (posedge clk)
begin
	if (~run) rdy <= 0;	// ready after buffer read before IFFT or written after FFT
	else rdy <= (rdy|ifftstart|fftdone) & ~(iord & iocs);
	if (~run) sff <= 0;	// save indication of reference symbol after null symbol
	else sff <= (ensof & sof) | (sff & ~start);
	if (~run) sf <= 0;	// start of frame flag (reference symbol)
	else if (rcvrdy) sf <= sff;
	if (~run) ef <= 0;	// end of frame flag (no signal)
	else if (rcvrdy) ef <= ~dcd;
	if (sync) sphs <= sctr;
	if (iord) status <= {rdy,busy,ef,run,sf,2'b00,sphs};
end
// Connect outputs
assign dout = status;	// connect status output
assign intr = 1'b0;		// unused
assign ten = runtx;		// enable transmitter when IFFT running
assign cpe = encmp;
// save X and Y outputs for zero frequency bin
always @ (posedge clk)
begin
	z <= ~|a9;
	if (z & pmov) m0 <= magout;
	if (z & pmov) p0 <= phsout;
end
// connect test outputs
assign w = sphs;	// sync position in sample window
assign x = m0;		// magnitude of DC bin
assign y = p0;		// phase of DC bin
endmodule

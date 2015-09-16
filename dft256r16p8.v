//
//		dft256r16p8.v - 32-256 point FFT/IFFT with Buffer and Control Logic
//
//					(C) Copyright 2004-2010 John B. Stephensen
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
//	 2 |                                           |CMP|SYN|SOF|RST|RUN|
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |                                                           |REF| Transmit Symbol
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   | Scaling Factors (0-3 right shifts)
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 5 |                               |       Offset Increment        | Filter Bank Offset
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		FFT Size - number of samples in FFT/IFFT as power of 2 (5=32, 6=64, 7=128, 8=256)
//		FFT Length - integer number of samples in FFT/IFFT
//		FWD - 0 = IFFT, 1 = FFT
//		CMP - 0 = normal operation, 1 = enable compander
//		SYN - enable FFT sample synchronization based on phase correlation (sync input)
//		SOF - enable FFT when start of frame arrives (SOF input)
//		RST - reset FIFO to discard previous data
//		RUN - enable IFFT (transmission of cyclic prefix starts when first TOE arrives)
//		REF - transmit reference symbol (phase is not additive)
// 
// There are 3 control signals that enter and leave the module. XMT puts the module in transmit
// mode. If enabled, SYNC sets the address of the first sample and initiates the FFT. DONE goes
// active for one clock period when the FFT or IFFT is complete and all data in unloaded.
//
// A status register provides access to the following flags:
//
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//    |INT|BSY|EOF|RUN|SOF| E | F |            Sync. Phase            | Status
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		INT - interrupt output set (receive and FIFO not empty or transmit and FIFO not full)
//		BSY - FFT engine busy
//		EOF - end of frame (DCD off at start of sampling period)
//		RUN - sampling data
//		SOF - start of frame (first symbol after null symbol detected)
//		E - FIFO empty
//		F - FIFO full
//
// SOF and EOF are buffered in a 4-entry FIFO and refer to the currently-available symbol.
// When EOF is set, there is no subcarrier data. BSY and RUN are real-time status bits.
//
// Polar data (phase and magnitude bytes) may be read from or written into a 512-word buffer.
// When receiving the upper and lower 256 words are identical. When transmitting the two blocks
// have different purposes as described below.
//
// The subcarrier data buffer is a 4-entry FIFO with the 256 subcarriers of one symbol accessable
// as 256 words of memory. The currently-accessible symbol is queued for transmission when port 3
// is written. Bit 0 determines whether the phase is used directly or adds to the previous phase.
// On receive, writing port 3 discards the currently-accessible symbol and replaces it with the
// next symbol. The buffer is formatted so that the DC subcarrier is in the center of the buffer
// by inverting the MSB of the address from the FFT module. The following example shows the format
// for a 32-point FFT with 12 LSB and 12 USB subcarriers used for data transmission:
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
// The data stored in this buffer is formatted so that the upper byte is the subcarrier magnitude
// and the lower byte is the subcarrier phase. Received phase is 8 bits with 1.4 degree resolution
// and transmitted phase is 4 bits with 22.5 degree resolution. Received magnitude is 8 bits with
// 255 equal to -12 dBFS. Transmitted magnitude is 4 bits where 0-3 = no signal, 4 = -33 dBc, 5 =
// -30 dBc ... 14 = -3 dBc and 15 = 0 dBc.
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//    |           Magnitude           |             Phase             | Receive
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//    |   Magnitude   |               |     Phase     |               | Transmit
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// Received phase is always the phase difference - the current symbol phase minus the previous symbol phase.
// Transmitted phase is absolute when REF set or relative when REF reset (previous phase plus current phase).
//
// The maximum clock rate is 141 MHz with 4 block RAMs, 3 DSP48s, 1511 LUT6s and 1508 registers used.
//
//	History:
//		12-8-10	fixed unused port and trucation warnings for Spartan-6
//		12-28-10	increased phase accuracy from 5 to 8 bits using parallel CORDIC implementation
//		1-27-11	added offset accumulator to allow use in filter bank
//		10-28-11	use 64x8 ROMs for P->R (free 8k RAM)
//		1-18-12	add 4-entry FIFO logic to use spare 8k RAM
//		1-21-12	add sync. input for transmit (use modem for carrier gen.)
//		2-7-12	add EOF entry to FIFO
//		3-15-12	4-bit magnitude with 3dB steps with async. ROMs and sync. mux (was 1495 LUTs & 1504 regs)
//		3-22-12	add compander enable
//		2-19-13	use FFT v7.1 (was 4 RAM, 3 DSP48, 1511 LUT, 1508 reg)
//
// Normal Warnings:
//		<status<9>> and <status<10>> have a constant value of zero.
//		<accy7<6:0>> and <accz8<3:0>> unconnected.
//		<accz1<8:0>> has a constant value of zero.
//		<accz1<9>> has a constant value of one.
//
module dft256r16p8(
	 output [8:0] w,				// TEST
	 output [7:0] x,y,
	 input iocs,					// I/O interface
	 input [2:0] ioaddr,
	 input [15:0] din,
	 input iowr,
	 output [15:0] dout,
	 input iord,
	 input mcs,						// memory interface
	 input [7:0] maddr,
	 input [15:0] min,
	 output [15:0] mout,
	 input mwr,
	 input toe,						// enable transmitter output
	 output [15:0] tdox,tdoy,	// transmitter rectangular data output
	 output tov,					// transmitter output valid
	 output ten,					// IFFT enable
	 output cpe,					// compander enable
    input [15:0] rdix,rdiy,	// receiver rectangular data input
    input riv,						// input data valid
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
reg [15:0] rx1,ry1,rx2,ry2;	// delay for time-ordered buffer memory input
wire [15:0] rx,ry;				// input from memory (R)
wire [7:0] tx0,ty0;				// ROM outputs to shifter
reg [11:0] tx,ty;					// constellation map output (T)
wire [15:0] nx,ny;				// FFT/IFFT input multiplexer
wire [15:0] kx,ky;				// FFT/IFFT output
wire [7:0] magin,phsin;			// IFFT input in polar form from FIFO
wire [1:0] mag0;					// encoded magnitude
wire [7:0] magout,phsout;		// FFT output in polar form
wire [7:0] phsref;				// phase reference
wire [7:0] phsdif,phsinc;		// phase increment (tx) and phase difference (rx)
wire refsym;						// 0 = incremental phase, 1 = absolute phase
wire pmov;							// phase.magnitude output valid (RAM WE)
reg pmov1;							// delayed for data read/write completion strobe
wire ifftstart;					// FFT input data transferred
wire fftdone,ifftdone;			// FFT output data transferred
wire rcvrdy,xmtrdy;				// ready for FFT or IFFT
wire [7:0] naddr,kaddr;			// addresses from FFT logic
reg [7:0] a1,a2,a3,a4,a5,a6,a7,a8,a9;	// K index delay (to match CORDIC)
wire [7:0] a9m;					// muliplexed K and N addresses
reg [7:0] faddr,faddr1;			// FFT address output delayed to match data timing
wire fftrfd,fftbusy,fftdv;		// FFT status
reg fftdv0,fftrfd0,fftrfd1;	// FFT status delayed 1 and 2 clock cycles
wire start;							// start FFT or IFFT
wire unload;						// start unloading FFT output buffer
reg [2:1] v;						// data valid delay
reg sff;								// start of frame flag
wire sf,ef;							// start and end of frame flags from FIFO
wire busy;							// FFT engine busy
reg [15:0] data,status;			// data and status output registers
reg [7:0] m0,p0;					// zero frequency magnitude and phase registers
reg z;								// FFT output index is zero
wire [1:0] raddr,waddr;			// FIFO buffer read and write top address bitss
wire [1:0] fsel,msel;			// FIFO buffer FFT and CPU top address bits
wire full,empty;					// FIFO flags
wire fendrd,fendwr;				// end of block read and write strobes
wire rstfifo;						// reset FIFO
// decode addresses
wire wr0,wr1,wr2,wr3,wr4;
assign wr0 = iocs & (ioaddr == 0) & iowr;	// FFT size and transform type
assign wr1 = iocs & (ioaddr == 1) & iowr;	// FFT length and cyclic prefix length
assign wr2 = iocs & (ioaddr == 2) & iowr;	// enable transmission or reception
assign wr3 = iocs & (ioaddr == 3) & iowr;	// start transmission
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
assign rstfifo = wr2 & din[1];			// reset FIFO
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
	rx2 <= rx1;
	ry2 <= ry1;
end
assign nx = xmt ? {tx,4'h0} : rx2;
assign ny = xmt ? {ty,4'h0} : ry2;
// Transform rectangular signal between time and frequency domains using 16-bit data
// path and 16-bit coefficient (twiddle factor) size. Start FFT or IFFT when buffer
// swap occurs.
fft256x16 fft (
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
assign mag0 = empty ? 2'b00 : magin[7:6];	// transmit NUL if FIFO empty
rom64x8cos cos (
	.a({magin[5:4],phsin[7:4]}),
	.spo(tx0)
	);
rom64x8sin sin (
	.a({magin[5:4],phsin[7:4]}),
	.spo(ty0)
	);
always @ (posedge clk)	// shift 0, 2 or 4 bits right
begin
	case (mag0)
	0: tx <= 12'h000;
	1: tx <= {tx0[7],tx0[7],tx0[7],tx0[7],tx0};
	2: tx <= {tx0[7],tx0[7],tx0,2'b00};
	3: tx <= {tx0,4'b0000};
	default tx <= 12'hxxx;
	endcase
	case (mag0)
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
// generate strobe after last subcarrier written (receive)
always @ (posedge clk) pmov1 <= pmov;
assign fftdone = pmov1 & ~pmov & ~xmt;
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
// also extend subcarrier index sign and invert MSB to center in buffer
// delay is 1 clock cycle on tranmit and 10 clock cycles on receive
always @ (posedge clk)
begin
	case (fftsize[1:0])
	0: faddr[7:5] <= {~a9m[7],a9m[6],a9m[5]}; // 256 => 8
	1: faddr[7:5] <= {~a9m[4],a9m[4],a9m[4]}; // 32 => 5
	2: faddr[7:5] <= {~a9m[5],a9m[5],a9m[5]}; // 64 => 6 
	3: faddr[7:5] <= {~a9m[6],a9m[6],a9m[5]}; // 128 => 7
	default faddr[7:5] <= 3'bxxx;
	endcase
	faddr[4:0] <= a9m[4:0];
	faddr1 <= faddr;		// delayed to match FIFO data output
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
	.A(xmt ? faddr1 : faddr),	// use address for FIFO output (xmt) or input (rcv)
	.O(phsref),
	.D(xmt ? phsin : phsout),	// use transmitted or received phase as next reference
	.WE(xmt ? fftrfd1 : pmov),
	.WCLK(clk)
	);
assign phsin = phsinc + (refsym ? 8'h00 : phsref);	// transmit accumulated phase
assign phsdif = phsout - phsref;							// receive phase difference
// 4-entry FIFO for receive or transmit
assign eof = rcvrdy & ~dcd;						// FFT start time but no signal
assign fendwr = xmt ? wr3 : (fftdone|eof);	// xmt. IFFT input written or rcv. FFT input written
assign fendrd = xmt ? ifftstart : wr3;			// xmt. IFFT input read or rcv. FFT output read
fifo4 rwl (
	.wr(fendwr),	// read & write strobes to change buffers
	.rd(fendrd),
	.wa(waddr),		// top 2 bits of read and write addresses
	.ra(raddr),
	.full(full),	// status flags
	.empty(empty),
	.clk(clk),		// master clock and reset
	.rst(rst|rstfifo)
	);
assign fsel = xmt ? raddr : waddr;	// FFT reads during transmit and writes during receive
assign msel = xmt ? waddr : raddr;	// CPU writes during transmit and reads during receive
// Three single-bit FIFOs use dual-port distributed RAM to store
// start of frame on transmit and start and end of frame on receive
RAM32X1D s0buf (
	.A4(1'b0), .A3(1'b0), .A2(1'b0), .A1(waddr[1]), .A0(waddr[0]), 					// write addr.
	.DPRA4(1'b0), .DPRA3(1'b0), .DPRA2(1'b0), .DPRA1(raddr[1]), .DPRA0(raddr[0]),	// read addr. 
	.D(din[0]),		// read/write port input
	.SPO(),			// read/write port output
	.DPO(refsym),	// read port output signals first (reference) symbol in transmitted frame
	.WE(wr3),		// write after transmit data loaded
	.WCLK(clk)
	);
RAM32X1D s1buf (
	.A4(1'b0), .A3(1'b0), .A2(1'b0), .A1(waddr[1]), .A0(waddr[0]), 					// write addr.
	.DPRA4(1'b0), .DPRA3(1'b0), .DPRA2(1'b0), .DPRA1(raddr[1]), .DPRA0(raddr[0]),	// read addr. 
	.D(sff),			// read/write port input
	.SPO(),			// read/write port output
	.DPO(sf),		// read port output signals first symbol in received frame
	.WE(rcvrdy),	// write at end of sampling window
	.WCLK(clk)
	);
RAM32X1D s2buf (
	.A4(1'b0), .A3(1'b0), .A2(1'b0), .A1(waddr[1]), .A0(waddr[0]), 					// write addr.
	.DPRA4(1'b0), .DPRA3(1'b0), .DPRA2(1'b0), .DPRA1(raddr[1]), .DPRA0(raddr[0]),	// read addr. 
	.D(~dcd),		// read/write port input is data carrier detect
	.SPO(),			// read/write port output
	.DPO(ef),		// read port output signals end of frame received (null symbol)
	.WE(rcvrdy),	// write at end of sampling window
	.WCLK(clk)
	);
// 4 x 256 x 16 Data FIFO is dual-port block RAM for phase and magnitude
// Port A is for FFT and port B is for CPU
RAMB16_S18_S18 sbuf (
	.ADDRA({fsel,faddr}),	// FFT address
	.ADDRB({msel,maddr}),	// I/O address
	.DIA({magout,phsdif}),	// received subcarrier magnitude & phase
	.DIPA(2'b11),
	.DIB(min),					// CPU memory data bus
	.DIPB(2'b11),
	.DOA({magin,phsinc}),	// subcarrier magnitude & phase to transmit
	.DOPA(),
	.DOB(mout),					// CPU memory data bus
	.DOPB(),
	.CLKA(clk),					// master clock
	.CLKB(clk), 
	.WEA(pmov),					// phase & magnitude output valid
	.WEB(mwr),					// CPU write enable
	.ENA(1'b1),
	.ENB(mcs),					// CPU memory select
	.SSRA(1'b0),				// don't reset
	.SSRB(1'b0)
	);
// save start of frame input until first FFT complete
// latch sample counter value when sync occurs
// latch status bits for I/O read to minimize propagation delay (IORD 1 clock long)
always @ (posedge clk)
begin
	if (rst) sff <= 0;
	else sff <= (ensof & sof) | (sff & ~start);	// start of frame
	if (sync) sphs <= sctr;
	if (iord) status <= {intr,busy,ef,run,sf,empty,full,sphs};
end
// Connect outputs
assign dout = status;
assign intr = xmt ? ~full : ~empty;	// receiver ready or transmitter ready
assign ten = runtx;
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

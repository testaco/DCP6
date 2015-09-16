//
//									Viterbi Decoder
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// The Viterbi decoder is configured by loading instructions specifying the possible previous
// state and the required signal constellation point. Evaluation of these paths starts when
// the first received symbol is written to port 0. Up to 256 symbols may be loaded and each
// will be evaluated in sequence with the most likely paths to each state written into
// traceback memory. After evaluation of all paths for all symbols, EOF is asserted and the
// results may be read from traceback memory, in reverse order, 8 symbols at a time. The last
// symbols tranmitted must return the encoder state to zero to provide a known starting point
// for decoding. Six output ports are provided for data input and decoder configuration:
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |    SC 1   |                   |        SC 0       |           | Input
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |TWO|                                   |         Paths         | Mode
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |                   |EOS|LP |FP |    S0     |S1 |   Old State   | Path List
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 |                                                       |  Data | Bit Decoding
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  4 |                                                               | Start Traceback
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  5 |                                                               | Reset for new frame
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		TWO = 0 for 1 subcarrier or 1 for 2 subcarriers
//		Old State = previous encoder state
//		S0 = expected value of subcarrier 0 for this state transition
//		S1 = expected value of subcarrier 1 for this state transition
//		FP = first potential path for current new state
//		LP = last potentisl path for current new state
//		EOS = end of symbol (last path and last state)
//		Data = data value associated with decoded state (load in reverse order of state)
//
// Only subcarrier 0 is evaluated if TWO is set to zero. The maximum number of paths is 128
// and paths are entered in the order that they will be evaluated.
//
// Three output registers are provided to read decoded bytes or words from traceback memory
// and to read the number of symbols remaining. Reading port 0 or 1 causes the next 8 symbols
// symbols to be decoded in the next 8 clock cycles. The first data byte/word presented after
// EOF is the residue that doesn't fit in an integral nmumber of 8 symbol words. This is
// normally the symbols transmitted after a data frame to reset the convolutional coder and
// provide a known state (0) from which to start decoding.
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  0 |                               |           Data Byte           | One bit per symbol
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  1 |                           Data Word                           | Two bits per symbol
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  2 |                            (unused)                           |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  3 | V | E | F |                   |            Symbols            | Status
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		V = output data byte/word valid (symbol counter modulo 8 is 0)
//		E = input buffer empty
//		F = input buffer full
//
// S3E: 141 slices and 1 BRAM used. 110 MHz max.
// Speed determined by configuration shift register/subtractor/distance ROM delay.
// S6: 200 LUT6s, 129 registers and 1 BRAM used. 159 MHz max.
// Speed determined by symbol counter.
//
// Normal Warnings:
//		<din<12:11>> is never used.
//
// Revision History:
//		3-3-09	synchronous output port for 2-cycle input
//		1-15-10	initiate traceback after data read (was status read)
//		3-4-10	shorten FIFO from 128 to 16 samples and add full status (-48 slices)
//		3-4-10	shorten instruction memory from 128 to 64 paths (-50 slices)
//		12-8-10	eliminated truncation warning for Spartan-6 (now 204 LUT6, 144 reg)
//		4-14-13	infer output multiplexer to ease placement & routing
// 
module viterbi(iocs, ioaddr, din, dout, iowr, iord, clk, rst);
    input iocs;			// select this module
	 input [2:0] ioaddr;	// I/O address within this module
	 input [15:0] din;	// data input to this module from CPU
	 output [15:0] dout;	// data output from this module to CPU
	 input iowr,iord;		// I/O read and write enables
	 input clk,rst;		// master clock and reset
// internal signals
wire [4:0] sig0;		// Viterbi decoder signal inputs
wire [2:0] sig1;
wire [5:0] pdi,pdo;	// FIFO I/O
wire empty,full;		// FIFO status
reg [5:0] paths;		// number of paths to evaluate
reg two;					// 0 = one subcarrier, 1 = two subcarriers
wire [10:0] c;			// configuration information
reg [5:0] count;		// path counter
wire nz;					// counter is not zero
reg dnz;					// delayed not zero
reg [4:1] z;			// delayed counter zero flag
wire iv;					// valid path info present
wire [3:0] oldstate;	// ACS inputs
wire [2:0] cp0;
wire cp1;
wire first,last,final;
wire [3:0] new,old;	// state information for traceback
wire acsv,tbmv;		// ACS and traceback outputs valid
wire eos,eof;			// end of symbol and end of frame flags
wire flush;				// flush FIFO
wire [7:0] symbols;	// number of symbols in traceback memory
wire [7:0] d0,d1;		// data output bytes from decoder
reg readsym;			// symbol counter read
reg [15:0] omux;		// output multiplexer
// address decode
wire s0,s1,s2,s3,s4,s5;
assign s0 = iocs & (ioaddr[2:0] == 0);
assign s1 = iocs & (ioaddr[2:0] == 1);
assign s2 = iocs & (ioaddr[2:0] == 2);
assign s3 = iocs & (ioaddr[2:0] == 3);
assign s4 = iocs & (ioaddr[2:0] == 4);
assign s5 = iocs & (ioaddr[2:0] == 5);
assign eof = iowr & s4;
assign flush = iowr & s5;
// configuration registers
always @ (posedge clk)
begin
	if (rst) paths <= 0;		// paths to evaluate
	else if (iowr & s1) paths <= din[5:0];
	if (rst) two <= 1'b0; 	// default to 1 signal
	else if (iowr & s1) two <= din[15];
end
// Viterbi decoder input - write to port 0 with 1 or 2 signals
// first symbol (in LSB) may be BPSK, QPSK or 8PSK
// second symbol (in MSB) must be BPSK
assign pdi = two ? {din[7:5],din[15:13]} : {din[7:3],1'b0};
fifo16x6s fifo (
	.pdi(pdi),				// 1 or 2 symbols per entry
	.iv(iowr & s0),
	.oe(eos),				// get next symbol when last path of last state
	.pdo(pdo),
	.ov(),
	.empty(empty),			// no symbols left
	.full(full),			// no space for more symbols
	.clk(clk),
	.rst(rst|flush)
	);
assign sig0 = pdo[5:1];
assign sig1 = pdo[2:0];
// Configuration words read out until FIFO empty
// insert 4 cycle gap between path evaluations 
always @ (posedge clk)
begin
	if (rst|flush) count <= 0;
	else if (z[4] & ~nz & ~empty) count <= paths;
	else if (nz) count <= count - 6'b000001;
	dnz <= nz;
	z <= {z[3:1],~nz};
end
assign nz = |count;	// counter not at zero
assign iv = nz|dnz;	// counter active
// Configuration memory - 12-bit configuration words shifted in serially
// read out in sequence from end to beginning of shift register
srl64x11e cmem (
	.d(din[10:0]),
	.ce(iowr & s2),
	.clk(clk),
	.a(count),
	.y(c)
	);
// Viterbi decoder ACS instruction processing - 3 clock cycle delay - 50 slices
assign oldstate = c[3:0];
assign cp1 = c[4];
assign cp0 = c[7:5];
assign first = c[8];
assign last = c[9];
assign final = c[10];
acs16s acs (
	.phs0(sig0),					// real signal inputs for comparison
	.phs1(sig1), 					// to expected signal constellation points
	.cp0(cp0),						// signal 0 (3 bits if 8PSK or QPSK)
	.cp1(cp1), 						// signal 1 if two BPSK signals
	.oldstate(oldstate), 		// next state for path being examined
	.first(first),					// first path being evaluated
	.last(last),					// last path being evaluated
	.final(final), 				// final state of symbol being evaluated
	.iv(iv), 						// above inputs valid
	.dist(),
	.new(new), 						// next state output to traceback memory
	.old(old), 						// previous state output to traceback memory
	.ov(acsv), 						// output valid (previous state for current new state)
	.next(eos),						// done with current symbol (last path to last state)
	.clk(clk), 
	.rst(rst|flush),				// reset metrics when FIFO flushed
	.two(two)						// use two signals to calculate distance
	);
// Detect data read and start next shift cycle
always @ (posedge clk)
begin
	readsym <= iord & (s0|s1);
end
// Viterbi decoder traceback - 24 slices
traceback tbm (
	.old(old), 			// most likely previous state to write into memory
	.new(new), 			// address corresponding to new state for current symbol
	.iv(acsv), 			// above inputs valid
	.eos(eos), 			// end of symbol - start evaluating paths to next symbol
	.eof(eof), 			// end of frame - start traceback of all symbols
	.do0(d0),			// data outputs
	.do1(d1),
	.sym(symbols), 	// symbols stored in traceback memory
	.ov(tbmv), 
	.oe(readsym),		// get next 8 symbols after counter read 
	.mclk(clk), 
	.mrst(rst|flush),
	.cin(din[1:0]),	// configure state to data bit translation
	.cwr(iowr & s3),
	.cclk(clk)
	);
// output multiplexer allows one or two bits per symbol and count of symbols
always @ (posedge clk)
begin
	case (ioaddr[1:0])
	0: omux <= {8'h00,d0};
	1: omux <= {d1[7],d0[7],d1[6],d0[6],d1[5],d0[5],d1[4],d0[4],d1[3],d0[3],d1[2],d0[2],d1[1],d0[1],d1[0],d0[0]};
	2: omux <= 16'hFFFF;
	3: omux <= {tbmv,empty,full,5'b00000,symbols};
	default omux <= 16'hxxxx;
	endcase
end
assign dout = omux;
endmodule

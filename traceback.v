//
//				traceback.v - 256-Symbol x 16-State Traceback Memory
//
//					 (C) Copyright 2006-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	This module stores the trellis traversed in the forward direction by a Viterbi
// decoder as an input signal is processed and decoded into 8-valued symbols. The
// stored trellis is then traversed in the reverse direction to determine the most
// likely sequence of states in the encoder at the transmitter.
//
// The data input (OLD) is the most likely previous state of the BICM encoder for
// each possible new state (NEW). OLD is written into RAM at the address specified
// by NEW plus the value of a symbol counter when IV is true. SCTR is incremented
// after the write when SYNC is true. When an entire sequence of symbols is completed,
// FSI is asserted and the user may start traceback. 
//
// Traceback starts when the RAM output (STATE) is reset by LAST and then each successive
// previous state is read out as OE is asserted. Each old state is shifted into the data
// registers and the output symbol counter is decremented to trace back along the decoded
// trellis stored in RAM. The symbol counter is decremented before each read. Reads stop
// each 8th subcarrier so the shift registers contents may be read before being overwitten.
//
// The mapping from state to data value is configured by loading the data values into a
// shift register in reverse order (highest used state to state 0).
//
//	S3E: 15 slices and 1 BRAM are used and the maximum clock speed is 158 MHz.
//	S6: 18 LUTs, 23 registers and 1 BRAM are used and the maximum clock speed is 201 MHz.
// Maximum delay in count enable logic.
//
module traceback(old, new, iv, eos, eof, do0,do1, sym, ov, oe, mclk, mrst, cin, cwr, cclk);
    input [3:0] old;			// most likely old state
    input [3:0] new;			// for possible new state
    input iv;					// inputs valid
    input eos,eof;			// end of symbol and end of frame inputs
    output [7:0] do0,do1;	// decoded data output (dibits split between ports)
	 output [7:0] sym;		// number of symbols in memory
	 output ov;					// output valid (false while bits shifted out of memory)
    input oe;					// output enable
    input mclk;				// master clock
	 input mrst;				// reset symbol counter
	 input [1:0] cin;			// configuration data (2 data bits)
	 input cwr;					// write configuration
	 input cclk;
// internal signals
reg tb;					// enable traceback
wire [3:0] state;		// selected state
wire [1:0] data;		// unencoded data for that state
reg [7:0] symctr;		// symbol counter
wire nz;					// true when osym > 0
wire mod8;				// true on 8th subcarrier
wire en;					// enable data output registers
wire ce;					// enable symbol counter
reg [7:1] d0,d1;		// recovered data shift registers
// Symbol Counter is upper 8 bits of memory address
// increment input counter (add +1) when EOS and IV true
// decrement output (add -1) during traceback
always @ (posedge mclk)
begin
	if (mrst) tb <= 0;		// latch eof signal
	else tb <= tb|eof;
	if (mrst) symctr <= 0;	// count up if tb=0, count down if tb=1
	else if (ce) symctr <= symctr + {tb,tb,tb,tb,tb,tb,tb,1'b1};
end
// stop data accumulation on every 8th subcarrier 
assign nz = |symctr;
assign mod8 = ~|symctr[2:0];			// word strobe every 8th subcarrier
assign en = (oe|~mod8) & nz;			// traceback 8 subcarriers at a time
assign ce = tb ? en : (eos & iv);	// select counter enable
// Traceback Memory - 4096x4
// stores 4096 entries with 4 bit state for up to 128 symbols
RAMB16_S4_S4 #(
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) tbm (
	.ADDRA({symctr,new}),	// A is write-only input port
	.DIA(old),					// write most-likely previous state for each new state
	.DOA(),
	.CLKA(mclk),
	.WEA(iv),					// write each nibble on input port
	.ENA(1'b1),
	.SSRA(1'b0),
	.ADDRB({symctr,state}),	// B is read-only output (traceback) port
	.DIB(),
	.DOB(state),				// read previous state for selected state
	.CLKB(mclk),
	.WEB(1'b0),
	.ENB(en),					// stop traceback on every 8th subcarrier
	.SSRB(eof)					// start traceback at state 0 on last symbol entry
	);
// translate previous state to unencoded bits
srl16x2e xlat (
	.d(cin[1:0]),	// data bit
	.ce(cwr),		// shift in state to data map
	.clk(cclk),
	.a(state),
	.y(data)
	);
// state register, word and frame sync logic, data register and logic and swap flip-flop
always @ (posedge mclk)
begin
	if (en) d0 <= {d0[6:1],data[0]};	// latch data bits which were written LSB first
	if (en) d1 <= {d1[6:1],data[1]};	// and read MSB first
end
// connect output
assign do0 = {d0,data[0]};
assign do1 = {d1,data[1]};
assign ov = tb & mod8;
assign sym = symctr;
endmodule

//
//				tbm1024x8.v - 1024-Symbol x 8-State Traceback Memory
//
//					 (C) Copyright 2006-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	This module stores the trellis traversed in the forward direction by a Viterbi
// decoder as an input signal is processed and decoded. The stored trellis is then
// traversed in the reverse direction to determine the most likely sequence of states
// in the encoder at the transmitter. The data inputs are the most likely previous state
// of the encoder for each possible new state. When an entire sequence of symbols is
// completed, EOF is asserted and the user may start traceback. 
//
// Traceback starts when the RAM path output is reset by EOF with resets the state register
// 1/2 clock period later. Each successive previous state is determined from the current
// state and the path output when OE is asserted. The path information is shifted into the
// data registers and the output symbol counter is decremented to trace back along the
// decoded trellis stored in RAM. The symbol counter is decremented before each read. Reads
// stop each 8th subcarrier so the shift registers contents may be read before being
// overwitten. Note that the upper bit of the previous state must be:
//
//   p0 p1 p2 p3 p4 p5 p6 p7
//    0  0  1  1  0  0  1  1
//
// Thus, bit 2 of the new state is bit 1 of the old state. This reduces storage requirements
// in the traceback RAM.
//
//	18 LUT6, 31 registers and 1 RAM used. 184 MHz (-3) maximum clock rate.
//
module tbm1024x8(
    input [1:0] p0,p1,p2,p3,p4,p5,p6,p7,	// most likely old state for possible new state
    input iv,					// inputs valid
    input eof,					// end of frame input
    output [7:0] do0,do1,	// decoded data output (dibits split between ports)
	 output [9:0] sym,		// number of symbols in memory
	 output ov,					// output valid (false while bits shifted out of memory)
    input oe,					// output enable
    input clk,					// master clock
	 input rst					// reset symbol counter
	 );
// internal signals
reg tb;					// enable traceback
wire [1:0] path;		// path to new state
reg [2:0] state;		// new state
wire [1:0] data;		// unencoded data for last state
reg [9:0] symctr;		// symbol counter
wire nz;					// true when osym > 0
wire mod8;				// true on 8th subcarrier
wire en;					// enable data output registers
wire ce;					// enable symbol counter
reg den;					// data SR enable
reg [7:0] d0,d1;		// recovered data shift registers
// Symbol Counter is upper 10 bits of memory address
// increment input counter (add +1) when EOS and IV true
// decrement output (add -1) during traceback
always @ (posedge clk)
begin
	if (rst) tb <= 0;			// latch eof signal
	else tb <= tb|eof;
	if (rst) symctr <= 0;	// count up if tb=0, count down if tb=1
	else if (ce) symctr <= symctr + {tb,tb,tb,tb,tb,tb,tb,tb,tb,1'b1};
end
// stop data accumulation on every 8th subcarrier 
assign nz = |symctr;
assign mod8 = ~|symctr[2:0];	// word strobe every 8th subcarrier
assign en = (oe|~mod8) & nz;	// traceback 8 subcarriers at a time
assign ce = tb ? en : iv;		// select counter enable
// Traceback Memory - 1024x16 input and 8192x2 output
// write 16-bit words containing one 2-bit path for each of 8 new states
// read 2-bit words containing path to selected state (LS 3 addr. bits)
// use negative edge for read so 1 clock delay from state to state
RAMB16_S2_S18 #(
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) tbm (
	.ADDRB(symctr),						// B is write-only port
	.DIB({p7,p6,p5,p4,p3,p2,p1,p0}),	// write previous state for each new state
	.DIPB(2'b11),
	.DOB(),
	.DOPB(),
	.CLKB(clk),
	.WEB(iv),								// write words on input port
	.ENB(1'b1),
	.SSRB(1'b0),
	.ADDRA({symctr,state}),				// A is read-only port
	.DIA(),
	.DOA(path),								// read previous state for selected state
	.CLKA(~clk),
	.WEA(1'b0),
	.ENA(1'b1),								// stop traceback on every 8th subcarrier
	.SSRA(1'b0)								// start traceback at state 0 on last symbol
	);
// determine previous state from path taken and translate state to unencoded bits
always @ (posedge clk)
begin
	if (eof) state <= 0;
	if (en) state <= {state[1],path};
end
assign data = {state[2],state[0]};
// convert dibits to words
always @ (posedge clk)
begin
	den <= en;									// delay enable to match data
	if (den) d0 <= {d0[6:0],data[0]};	// latch data bits which were written LSB first
	if (den) d1 <= {d1[6:0],data[1]};	// and read MSB first
end
// connect output
assign do0 = d0;
assign do1 = d1;
assign ov = tb & mod8;
assign sym = symctr;
endmodule

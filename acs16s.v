//
//					acs16s.v - 16-bit Serial Add-Compare-Select 	
//
//					(C) Copyright 2006-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	The ACS module sequentially compares the distance between each possible old state
// to each possible new state for each possible input signal. It selects the old
// state with the shortest distance to each possible new state. Distances between the
// potential input signal phases and the actual signal phase are stored in ROM along
// with possible transition paths. For each possible new state, the paths from
// possible previous states are examined. The input signals are a 5-bit phase from
// one subcarrier and a 3-bit phase from another subcarrier. 
//
// Distances are accumulated over the entire signal state trellis and up to 314 symbols
// may be processed before overflow. Accumulated distances are zeroed during the
// calculations for the first symbol after reset.
//
//	NOTE: This logic can be improved by zeroing MSBs of all metrics when all have MSB of one.
// This allows reduction of precision to ceil(log2((n/K)*(K-1)+1))+1.
//
// 106 LUTs and 71 registers are used. Maximum input clock speed is 208 MHz.
// Output to traceback memory is delayed by 3 clock cycles. 
//
// Revision History:
//		4-2-10	explicit metric initialization input
//		12-8-10	eliminated truncation warning for Spartan-6
//		9-16-11	modify to use RAM32X6SDP (more efficient in Spartan-6)
//
module acs16s(phs0,phs1, cp0,cp1, oldstate, first,last,final, iv, dist, new, old, ov,next, clk, rst, two);
	 input [4:0] phs0;		// phase of input signals (constant during path calculations)
	 input [2:0] phs1;
	 input [2:0] cp0;			// desired constellation point for current calulation
	 input cp1;
	 input [3:0] oldstate;	// previous state for path being examined
	 input first,last;		// first and last paths to new state
	 input final;				// final new state being examined
	 input iv;					// input valid 
    output [15:0] dist;		// minimum distance to new state via old state
    output [3:0] new,old;	// old state and new state for shortest path
	 output ov,next;			// output valid and next symbol
	 input clk;					// master clock
	 input rst;					// reset control logic for new sequence of symbols
	 input two;					// true if two subcarriers used in calculations
// data busses
reg acc;									// 0 = initialize distance, 1 = accumulate distance
wire [4:0] dif0;						// phase difference for 8PSK
wire [2:0] dif1,dif2;				// phase differences for BPSK
wire [6:0] dist0;						// distance between 32PSK input signal and constellation point being tested
wire [2:0] dist1,dist2;				// distance between 8PSK input signals and constellation points being tested
wire [3:0] dist12;					// sum of dist1 and dist2
wire [6:0] distance;					// distance between input signals and constellation points being tested
wire [15:0] oldlength;				// new and old cumulative path lengths for addressed state
reg [15:0] newlength;
reg [15:0] minlength;				// current minimum distance
reg [3:0] minstate;					// old state for minimum distance
wire replace;							// replace current minimum
reg [3:0] newstate;					// new state being examined
reg [3:0] oldstate1,oldstate2;	// path from this old state being examined
reg swap;								// swap metric RAMs
reg [2:1] firstpath;					// timing
reg [3:1] lastpath;					// timing
reg [3:1] finalstate;				// timing
wire update,finished;				// update metric RAM and finished evaluation
// delay last input valid to suit pipeline
always @ (posedge clk)
begin
	firstpath <= {firstpath[1],iv & first};
	lastpath <= {lastpath[2:1],iv & last};
	finalstate <= {finalstate[2:1],iv & last & final};
	oldstate1 <= oldstate;	// sync with distance ROM output
	oldstate2 <= oldstate1;	// sync with newlength and replace strobe
end
// old state counter increments when last path examined
// and resets when last path of last state examined
// newstate is delayed to match distance calculations
assign update = lastpath[3];
assign finished = finalstate[3]; 
always @ (posedge clk)
begin
	if (rst|finished) newstate <= 0;
	else if (update) newstate <= newstate + 4'h1;
	if (rst) swap <= 1'b0;
	else if (finished) swap <= ~swap;
	if (rst) acc <= 0;	// initialize metrics
	else if (finished) acc <= 1;
end
// calculate difference between constellation point and signal
assign dif0 = phs0 - {cp0,2'b00};
assign dif1 = phs0[4:2] - cp0;
assign dif2 = phs1 - {cp1,2'b00};
// Distance ROMs store distance from signal to selected constellation point
// The distance is proportional to relative power as follows:
//	PSK offset 0 11 22 34 45 56 68 79 90 101 113 124 135 146 158 169 180 (+/- degrees)
//	  distance 0  1  4  9 15 23 32 42 52  62  72  81  89  95 100 103 104
//           00 01 04 09 0F 17 20 2A 34  3E  48  51  59 	5F  64  67  68
rom32x7d0 rom0 (.a(dif0), .q(dist0), .clk(clk), .ce(1'b1), .rst(1'b0));
//	PSK offset 0  45  90 135 180 (+/- degrees)
//	  distance 0  1   3   5   6
rom8x3d0 rom1 (.a(dif1), .q(dist1), .clk(clk), .ce(1'b1), .rst(1'b0));
rom8x3d0 rom2 (.a(dif2), .q(dist2), .clk(clk), .ce(1'b1), .rst(1'b0));
assign dist12 = {1'b0,dist1} + {1'b0,dist2};
assign distance = two ? {3'b000,dist12} : dist0;
// Metrics RAM stores cumulative distance of shortest path to each new state.
// Half used for old path length and half for new path lengths, then swapped.
// Asynchronous read-only port for old lengths.
RAM32X16SDP metrics (
	.WADDR({swap,newstate}),	// write-only port is minimum distance to next state
	.RADDR({~swap,oldstate1}),	// read-only port is distance to previous state
	.DI(minlength),
	.DO(oldlength),
	.WE(update),				// store minmum path length after all possible paths examined
	.WCLK(clk)
	);
// Add, compare and select
// add received symbol distance from expect constellation point to 
// accumulated distance for previous state being tested
always @ (posedge clk)
begin
	newlength <= {9'b00000000,distance} + (acc ? oldlength : 16'h0000);
end
// compare length of last path with current path
assign replace = (newlength < minlength) | firstpath[2];
// replace minimum when new path shorter or first path
always @ (posedge clk)
begin
	if (replace) minstate <= oldstate2;	// minimum distance registers
	if (replace) minlength <= newlength;
end
// connect outputs
assign new = newstate;
assign old = minstate;
assign dist = minlength;
assign ov = update;
assign next = finished;
endmodule

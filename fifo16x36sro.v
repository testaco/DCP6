//
//						36-bit wide SRL32-based FIFO
//
//				(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module is a 15-entry FIFO. The FIFO is empty when reset (counter = 31),
// fills when IV is true and empties when OE is true. This FIFO has registered
// outputs, giving a 1 clock pipeline delay but a faster clock rate.
//
//	47 LUT6 and 48 registers. 268 MHz maximum clock rate.
//
// History:
//		3-23-13	create from fifo32x36sro (was 55 LUT, 56 reg)
//		3-25-13	not ready when 60% full (6 spare entries)
// 
module fifo16x36sro (
    input [35:0] pdi,	// data input
    input iv,				// input valid
    input oe,				// output enable
    output [35:0] pdo,	// data output
	 output ov,				// output valid
	 output empty,			// zero entries
	 output full,			// 15 entries
	 output rfd,			// ready for data
    input clk,				// master clock
    input rst				// flush FIFO
	 );
// internal signals
reg [3:0] addr;	// FIFO output address
wire re,we;			// read & write enables
reg rdy;				// ready for data
wire [35:0] d;		// output registers
reg [35:0] q;
reg v;
// read and write enable logic
assign we = iv & ~full;
assign re = oe & ~empty;
// address counter and almost full flag
always @ (posedge clk)
begin
	if (rst) addr <= 4'b1111;	// empty state is 15
	else if (we^re) addr <= addr + {~we,~we,~we,1'b1};
	rdy <= (&addr)|(~addr[3]);	// ready until 60% full
	q <= d;	// registers have lower output delay than shift registers
	v <= re;
end
// full and empty flag logic
assign empty = (addr == 15);
assign full = (addr == 14);
// storage elements
srl16x36e sr (
    .d(pdi), 	// serial input
    .a(addr), 	// select output register
    .y(d), 		// addressed output
    .ce(we), 	// shift enable
    .clk(clk)
	);
// connect outputs
assign rfd = rdy;	// input ready
assign pdo = q;	// data output
assign ov = v;		// output valid
endmodule

//
//						36-bit wide SRL32-based FIFO
//
//				(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module is a 31-entry FIFO. The FIFO is empty when reset (counter = 31),
// fills when IV is true and empties when OE is true. This FIFO has registered
// outputs, giving a 1 clock pipeline delay but a faster clock rate.
//
//	S6: 55 LUT6 and 56 registers. 275 MHz maximum clock rate.
// 
module fifo32x36sro (
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
reg [4:0] addr;	// FIFO output address
wire re,we;			// read & write enables
reg rdy;				// ready for data
wire [35:0] d;		// output registers
reg [35:0] q;
reg v;
// read and write enable logic
assign we = iv & ~full;
assign re = oe & ~empty;
// address counter and almost full flag
// 
always @ (posedge clk)
begin
	if (rst) addr <= 5'b11111;	// empty state is 31
	else if (we^re) addr <= addr + {~we,~we,~we,~we,1'b1};
	rdy <= ~((addr == 29)|(addr == 30));	// ready when not almost full
	q <= d;	// registers have lower output delay than shift registers
	v <= re;
end
// full and empty flag logic
assign empty = (addr == 31);
assign full = (addr == 30);
// storage elements
srl32x36e sr (
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

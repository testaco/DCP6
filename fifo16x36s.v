//
//						36-bit wide SRL16-based FIFO
//
//				(C) Copyright 2004-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module is a 15-entry FIFO. The FIFO is empty when reset (counter = 15),
// fills when IV is true and empties when OE is true. This FIFO uses asynchronous
// logic and is somewhat slower than otherwise possible, but uses the least resources.
//
//	26 slices are used and the maximum clock speed is 217 MHz.
// 
module fifo16x36s(pdi,iv,oe,pdo,ov,empty,full,rfd,clk,rst);
    input [35:0] pdi;	// data input
    input iv;				// input valid
    input oe;				// output enable
    output [35:0] pdo;	// data output
	 output ov;				// output valid
	 output empty;			// zero entries
	 output full;			// 15 entries
	 output rfd;			// ready for data
    input clk;				// master clock
    input rst;				// flush FIFO
// internal signals
reg [3:0] addr;	// FIFO output address
wire we;				// write enable
// read and write enable logic
assign we = iv & ~full;
assign ov = oe & ~empty;
// address counter
always @ (posedge clk)
begin
	if (rst) addr <= 4'b1111;
	else if (we^ov) addr <= addr + {~we,~we,~we,1'b1};
end
// full and empty flag logic
assign empty = (addr == 15);
assign full = (addr == 14);
assign rfd = ~((addr == 13)|(addr == 14));
// storage elements
srl16x36e sr (
    .y(pdo), 
    .d(pdi), 
    .a(addr), 
    .ce(we), 
    .clk(clk)
	);
endmodule

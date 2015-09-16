//
//						32-bit wide SRL16-based FIFO
//
//					(C) Copyright 2004 John B. Stephensen
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
//	23 slices are used and the maximum clock speed is 229 MHz.
// 
module fifo16x32s(pdi,iv,oe,pdo,ov,empty,full,clk,rst);
    input [31:0] pdi;
    input iv;
    input oe;
    output [31:0] pdo;
	 output ov;
	 output empty;
	 output full;
    input clk;
    input rst;
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
// storage elements
srl16x32e sr (
    .y(pdo), 
    .d(pdi), 
    .a(addr), 
    .ce(we), 
    .clk(clk)
	);
endmodule

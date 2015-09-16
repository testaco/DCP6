//
//							9-bit wide SRL32-based FIFO
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module is a 31-entry FIFO. The FIFO is empty when reset (counter = 31),
// fills when IV is true and empties when OE is true. This FIFO uses asynchronous
// logic and is somewhat slower than otherwise possible, but uses the least resources.
// 
module fifo32x9s(pdi,iv,oe,pdo,ov,empty,full,clk,rst);
    input [8:0] pdi;
    input iv;
    input oe;
    output [8:0] pdo;
	 output ov;
	 output empty;
	 output full;
    input clk;
    input rst;
// internal signals
reg [4:0] addr;	// FIFO output address
wire we;				// write enable
// read and write enable logic
assign we = iv & ~full;
assign ov = oe & ~empty;
// address counter
always @ (posedge clk)
begin
	if (rst) addr <= 5'b11111;
	else if (we^ov) addr <= addr + {~we,~we,~we,~we,1'b1};
end
// full and empty flag logic
assign empty = (addr == 31);
assign full = (addr == 30);
// storage elements
srl32x9e sr (
    .y(pdo), 
    .d(pdi), 
    .a(addr), 
    .ce(we), 
    .clk(clk)
	);
endmodule

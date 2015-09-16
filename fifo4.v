//
//										fifo4.v - 4-entry FIFO Logic
//
//								(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and
// all of their derivatives are licensed only for personal non-profit educational
// use in the Amateur Radio Service and the license is not transferrable. The
// information is provided as-is for experimental purposes and the author does not
// warranty its freedom from defects or its suitability for any specific application.
//
//	This module provides the addressing logic for a 4-entry FIFO. The ambiguity of
// being full or empty when the two address are equal is resolved by detecting the
// almost full and almost empty conditions and setting the direction flip-flop.
//
// 10 LUT6s and 5 registers synthesized. 271 MHz maximum clock rate.
//
// History:
//		2011-10-3	written
//
module fifo4(
    input wr,			// write enable
    input rd,			// read confirm
    output [1:0] wa,	// write address
    output [1:0] ra,	// read address
    output full,		// FIFO full
    output empty,		// FIFO enpty
    input clk,			// master clock
    input rst			// master reset
    );
// internal signals
reg [1:0] wc,rc;		// read and write address counters
wire [1:0] rcp,rcm;	// read counter plus and minus one
reg dir;					// direction - almost full (1) or empty (0)
wire eq,ae,af;			// direction decode logic
// address logic
always @ (posedge clk)
begin
	if (rst) wc <= 0;	// write address counter
	else if (wr & ~full) wc <= wc + 1'b1;
	if (rst) rc <= 0;	// read address counter
	else if (rd & ~empty) rc <= rc + 1'b1;
	if (rst) dir <= 0;
	else dir <= (af | dir) & ~(ae & rd);
end
// decode relative positions
assign rcp = (rc + 2'b01);	// RC+1
assign rcm = (rc + 2'b11);	// RC-1
assign eq = (wc == rc);		// either empty or full
assign ae = (wc == rcp);	// WC ahead of RC
assign af = (wc == rcm);	// WC behind RC
// generate flags
assign empty = eq & ~dir;
assign full = eq & dir;
// connect outputs
assign wa = wc;
assign ra = rc;
endmodule

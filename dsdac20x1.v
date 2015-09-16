//
//								DSDAC20X1.V - 20-bit Delta-Sigma DAC
//
//								(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-3 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
// This module is a first-order delta-sigma modulator that generates an analog output when
// averaged by an external RC filter. 
//
// 20 LUT4s and 42 registers used. 311 MHz maximum clock rate.
//
module dsdac20x1(
    input [19:0] din,	// data input
	 input we,				// write enable
    input clk,				// master clock
	 input rst,				// master reset
    output aout			// analog output
    );
// internal signals
reg [19:0] n;	// convert this to analog value
reg [20:0] a;	// accumulator
reg m;			// register near output pin
// save value to be converted
always @ (posedge clk)
begin
	if (rst) n <= 20'h80000;	// start at mid-scale
	else if (we) n <= din;		// load data
end
// accumulate unused LSBs
always @ (posedge clk)
begin
	if (rst) a <= 0;
	else a <= {1'b0,n} + {1'b0,a[19:0]};
	m <= a[20];	// output register
end
// connect output
OBUF dacbuf (.I(m), .O(aout));
endmodule

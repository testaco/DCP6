//
//					spi16o.v - SPI Write-only Interface for LS DAC
//
//					(C) Copyright 2008-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implement a 16-bit shift register and control logic to send
// 16-bit words serially, MSB first, to a low-speed DAC. The bit rate is
// 1/4 of the input clock rate. The serial clock (sclk) positive edge occurs
// 1/4 cycle after sync becomes active. Data changes 1/4 cycle after the
// falling edge of sclk.
//
// 15 slices used. Maximum clock rate is 243 MHz.
//
// History:
//		12-8-10	eliminated truncation warning for Spartan-6 (dec. by 1)
//
module spi16o(
    input iocs,			// select this port
    input iowr,			// write data
    input [15:0] din,	// parallel data input
    input clk,				// common clock and reset
    input rst,
	 output sck,			// serial clock
	 output sdo,			// serial data output
	 output sync			// active low enable
    );
// internal signals
wire ce,se,we;	// count enable, shift enable, write enable
reg [15:0] d;	// transmit shift register
reg [5:0] c;	// counter
// address decode
assign we = iocs & iowr;
// data storage
always @ (posedge clk)
begin
	if (rst) c <= 0;	// count from 63 to 0 then stop after preset
	else if (we) c <= 63;
	else if (ce) c <= c - 6'b000001;
	if (we) d <= din;	// load when WE true, else shift left
	else if (se) d <= {d[14:0],1'b0};
end
assign ce = |c;			// enable count down as long as counter is non-zero
assign se = ~|c[1:0];	// enable shifting on every 4th clock
// connect outputs
assign sdo = d[15];		// data sent MSB first
assign sck = c[1];		// clock out is 1/4 clock in
assign sync = ~(we|ce);	// sync signal is active low
endmodule

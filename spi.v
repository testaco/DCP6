//
//						spi.v - 8-bit Serial Peripheral Inteface
//
//						(C) Copyright 2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This device uses 2 8-bit shift registers to implement a byte-wide SPI PHY. The
// SPI bus operates at half the CPU clock rate. Writing to port 0 causes the byte
// on DIN to be transmitted MSB first on SDO and the serial data on SDI to be
// collected MSB first for presentation in parallel form at DOUT. SDI is sampled
// on the falling edge of SCK and SDO is clocked out on the falling edge of SCK.
//
// Output port 0 or 1 may be used to submit data for transmission. Only bits
// 7-0 are used. Received bytes are available on input port 0 or 1. Bits 7-0 are
// received data and bits 15-8 are always zero. Output ports 2 and 3 are used to
// set (3) and reset (2) the slave select line. The interface operates in SPI
// mode 0 at half the CPU clock rate. It is compatible with the Atmel Rapid-S
// interface.
//
// S3E: 14 slices are used and the maximum clock speed is 270 MHz.
// S6: 17 LUT6s and 22 registers used. The maximum clock speed is 424 MHz.
//
// Normal Warnings:
//		<din<15:8>> is never used.
//		<ioaddr<2>> is never used.
//
// Revision History:
//		12-8-10	eliminated truncation warnings in half-bit counter for Spartan-6
//		9-18-11	instantiate I/O buffers
//
module spi(
    input iocs,			// select this module for I/O
	 input [2:0] ioaddr,	// address (this module uses 4)
    input [15:0] din,	// parallel data input
    input iowr,			// input valid
    output [15:0] dout,	// parallel data output
    input sdi,				// serial data input
    output sdo,			// serial data output
    output sck,			// serial clock
    output ssn,			// slave select (active low)
    input clk,				// master clock
    input rst				// master reset
    );
// internal signals
wire wrc,wrd;			// write chip select or data byte
reg [3:0] hbc;			// half-bit counter
reg shift;				// half-bit delay
wire nz;					// counter not zero
reg [7:0] rsr,tsr;	// data I/O shift registers
wire data;				// data from SPI bus
reg ss;					// slave select
// decode address
assign wrd = iocs & iowr & (ioaddr[1] == 1'b0);	// write data
assign wrc = iocs & iowr & (ioaddr[1] == 1'b1);	// control chip select
// generate serial enable and clock signals
// The counter decrements for 16 CLK periods.
// During this time 8 SCK cycles are generated.
always @ (posedge clk)
begin
	if (rst) hbc <= 0;					// reset to 0
	else if (wrd) hbc <= 4'd15;		// set to 15 when data arrives and
	else if (nz) hbc <= hbc - 1'b1;	// decrement until 8 bits shifted in and out
	shift <= hbc[0];						// delay counter LSB to get timing pulses
end
assign nz = |hbc;		// counter not zero
// transmit shift register - shift on SCK negative-going edge
always @ (posedge clk)
begin
	if (wrd) tsr <= din[7:0];		// load from port 0 or 1
	else if (shift) tsr <= {tsr[6:0],1'b0};	// shift out continuously
	if (rst) ss <= 0;					// reset SS when port 2, set SS when port 3
	else if (wrc) ss <= ioaddr[0];
end
// receive shift register - shift on SCK negative-going edge
always @ (posedge clk)
begin
	if (rst) rsr <= 0;				// shift 8 bits in
	else if (shift) rsr <= {rsr[6:0],data};
end
// connect SPI bus
OBUF bufssn (.I(~ss), .O(ssn));		// slave select (active low)
OBUF bufsck (.I(shift), .O(sck));	// serial clock
OBUF bufsdo (.I(tsr[7]), .O(sdo));	// serial data output
IBUF bufsdi (.I(sdi), .O(data));		// serial data input
// connect parallel output	
assign dout = {8'h00,rsr};	// zero upper byte to allow ORing into words
endmodule

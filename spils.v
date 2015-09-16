//
//						spils.v - 8-bit Serial Peripheral Inteface
//
//						(C) Copyright 2008-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This device uses two 8-bit shift registers to implement a byte-wide SPI PHY. The
// SPI bus operates 1/32 of the CPU clock rate. Writing to port 0 causes the byte on
// DIN to be transmitted MSB first on SDO. Incoming data on SDI is sampled on the
// falling edge of SCK and outgoing data for SDIO is clocked out on the falling edge
// of SCK. It is compatible with Analog Devices and Texas Instruments ADCs with SPI
// ports that operate to 200 ksps.
//
//	Output Ports:
//
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 0 |                               |             Data              |
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 1 |                                                           |ADR|
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 2 |                            Reset SS                           |
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 3 |                             Set SS                            |
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//	Input Ports:
//
//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 0 |BSY| 0   0   0   0   0   0   0 |             Data              |
//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// Output port 0 is be used to submit data for transmission. Only bits 7-0 are used.
// Received bytes are available on input port 0. Bits 7-0 are received data, bits
// 14-8 are always zero and bit 15 is 1 while transmitting and receiving data. Bit
// 15 is zero when the data is valid so that received bytes can be ored together.
// Output port 1 is used to select 1 of 2 SPI devicess by enabling slave select 0
// or slave select 1. Output ports 2 and 3 are used to set (3) and reset (2) the
// appropriate slave select line. 
//
// S6: 37 LUT6s and 34 registers are used and the maximum clock speed is 246 MHz.
//
// Normal Warnings:
//		<din<15:8>> is never used.
//		<ioaddr<2>> is never used.
//
// Revision History:
//		9-18-11	created from spi.v
//
module spils(
    input iocs,			// select this module for I/O
	 input [2:0] ioaddr,	// address (this module uses 4)
    input [15:0] din,	// parallel data input
    input iowr,			// input valid
    output [15:0] dout,	// parallel data output
    input sdi,				// serial data input
    output sdo,			// serial data output
    output sck,			// serial clock
    output ss0n,ss1n,	// slave selects (active low)
    input clk,				// master clock
    input rst				// master reset
    );
// internal signals
wire wrc,wra,wrd;		// register select
reg a;					// address
reg [7:0] t;			// counter
reg clock;				// serial clock
reg shift;				// shift data
wire nz;					// counter not zero
reg [7:0] rsr,tsr;	// data I/O shift registers
reg ss;					// slave select
wire data;				// data input
reg [7:0] omux;		// output multiplexer
// decode address
assign wrd = iocs & iowr & (ioaddr[1:0] == 2'b00);	// write data
assign wra = iocs & iowr & (ioaddr[1:0] == 2'b01);	// write address
assign wrc = iocs & iowr & (ioaddr[1] == 1'b1);	// control chip select
// configuration registers
always @ (posedge clk)
begin
	if (rst) a <= 0;	// address register
	else if (wra) a <= din[0];
end
// count down 255-0 and generate shift enable and clock signals
// the shift enable signal is valid every 32nd CLK period
// during this time 8 SCK cycles are generated
always @ (posedge clk)
begin
	if (rst) t <= 0;						// reset to 0
	else if (wrd) t <= 8'd255;			// set to all ones when data arrives and
	else if (nz) t <= t - 1'b1;		// decrement until 8 bits shifted in and out
	shift <= (t[4:0] == 5'b00001);	// shift when 5 LSBs low
	clock <= nz & ~t[4];					// generate serial clock when bit 4 is 0
end
assign nz = |t;						// counter not zero
// transmit shift register - shift on SCK negative-going edge
always @ (posedge clk)
begin
	if (wrd) tsr <= din[7:0];	// load from port 0
	else if (shift) tsr <= {tsr[6:0],1'b0};	// shift out continuously
	if (rst) ss <= 0;				// reset SS when port 2, set SS when port 3
	else if (wrc) ss <= ioaddr[0];
end
// receive shift register - shift on SCK negative-going edge
always @ (posedge clk)
begin
	if (rst) rsr <= 0;				// shift 8 bits in
	else if (shift) rsr <= {rsr[6:0],data};
end
// connect to SPI bus
OBUF bufcs0n (.I(~(ss & ~a)), .O(ss0n));	// active low slave select 0
OBUF bufcs1n (.I(~(ss & a)), .O(ss1n));	// active low slave select 1
OBUF bufclk (.I(clock), .O(sck));			// clock active in 2nd half bit cell
OBUF bufsdo (.I(tsr[7]), .O(sdo));			// data output
IBUF bufsdi (.I(sdi), .O(data));				// data input
// connect input port
assign dout = {nz|shift,7'b0000000,rsr};	// zero upper byte to allow ORing into words
endmodule

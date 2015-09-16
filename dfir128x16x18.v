//
//					 dfir128x16x18.v - FIR Filter Peripheral
//
//					(C) Copyright 2008-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements two FIR filters with 1-127 18-bit coefficients. Writing to
// output port 0 loads samples into data memory. Writing the length and address of
// the filter coefficient set to port 3 starts the filter. The result can be read
// from input port 0. When interpolating filters are implemented, the filter should
// be executed more than once after each data load with different coefficient sets.
// For decimating filters, there are multiple data loads between each filtering pass.
// Filter coefficients are loaded in reverse order. 
//
//	Output Ports:
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                             Data 0                            | 0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                             Data 1                            | 1
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|   |      Number of Taps 0     |   | Coefficient Base Address  | 2
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|   |      Number of Taps 1     |   | Coefficient Base Address  | 3
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                       MSW Coefficient 0                       | 4
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|  LSB  |                                                       | 5
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                       MSW Coefficient 1                       | 6
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|  LSB  |                                                       | 7
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//	Input Ports:
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                             Data 0                            | 0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                             Data 1                            | 1
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|OVF|OVF|                                               |RDY|RDY| 2
//		| 1 | 0 |                                               | 1 | 0 |
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		RDY: calculations complete
//		OVF: accumulator overflow
//
// 111 MHz maximum clock frequency with 411 LUT6s, 64 registers and 2 DSP48A1 used.
// Calculation of output values requires one clock cycle per tap plus an additional
// clock cycle for pipeline delays.
//
module dfir128x16x18 (
    input [2:0] ioaddr,	// port address
    input iocs,			// address valid
    input [15:0] din,	// input data
    input iowr,			// data valid
	 input iord,			// get output
    output [15:0] dout,	// output data
    input clk,				// master clock
    input rst				// master reset
    );
// internal signals
wire w0,w1,w2,w3,w4,w5,w6,w7;	// port select signals
wire rdy0,rdy1;					// convolution complete
wire ovf0,ovf1;					// accumulator overflow
reg [15:14] lsb;					// latch for 2 LS bits of coefficient
wire [15:0] dout0,dout1;		// filter outputs
wire [15:0] status,data;		// 
reg [15:0] omux;					// data/status output multiplexer
// decode output port addresses
assign w0 = iocs & iowr & (ioaddr == 0);
assign w1 = iocs & iowr & (ioaddr == 1);
assign w2 = iocs & iowr & (ioaddr == 2);
assign w3 = iocs & iowr & (ioaddr == 3);
assign w4 = iocs & iowr & (ioaddr == 4);
assign w5 = iocs & iowr & (ioaddr == 5);
assign w6 = iocs & iowr & (ioaddr == 6);
assign w7 = iocs & iowr & (ioaddr == 7);
// latch coefficient LSB
always @ (posedge clk) if (w5|w7) lsb <= din[15:14];
// two filters are provided
fir128x16x18 fir0 (
	.cin({din,lsb}),
	.din(din),
	.write(w0),
	.load(w4),
	.start(w2),
	.dout(dout0),
	.rdy(rdy0),
	.ovf(ovf0),
	.clk(clk),
	.rst(rst)
	);
fir128x16x18 fir1 (
	.cin({din,lsb}),
	.din(din),
	.write(w1),
	.load(w6),
	.start(w3),
	.dout(dout1),
	.rdy(rdy1),
	.ovf(ovf1),
	.clk(clk),
	.rst(rst)
	);
// connect outputs
assign data = ioaddr[0] ? dout1 : dout0;
assign status = {ovf1,ovf0,12'h000,rdy1,rdy0};
always @ (posedge clk) if (iord) omux <= (ioaddr[1]) ? status : data;
assign dout = omux;
endmodule

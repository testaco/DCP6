//
//					 qfir128x16x18.v - Quad FIR Filter Peripheral
//
//					 (C) Copyright 2008-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements 4 FIR filters with 1-127 18-bit coefficients. Writing to
// output port 0 loads samples into data memory. Writing the length and address of
// the filter coefficient set to port 2 starts the filter. The result can be read
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
//		|   |      Number of Taps 0     |   | Coefficient Base Address  | 1
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|  LSB  |                                                       | 2
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                       MSW Coefficient 1                       | 3
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                                                       |  FIR  | 4
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//	Input Ports:
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                             Data 0                            | 0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|OVF|                                                       |RDY| 4
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		RDY: calculations complete
//		OVF: accumulator overflow
//
// 111 MHz maximum clock frequency with 814 LUT6s, 112 registers and 4 DSP48A1 used.
// Calculation of output values requires one clock cycle per tap plus an additional
// clock cycle for pipeline delays.
//
// History:
//		2013-4-13	create from dfir128x16x18 (was 411 LUT, 64 reg, 2 DSP48)
//
// Normal Warnings:
//		<iord> not used.
//
module qfir128x16x18 (
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
wire w0,w1,w2,w3,w4;				// port write
wire f0,f1,f2,f3;					// filter select
wire rdy0,rdy1,rdy2,rdy3;		// convolution complete
wire ovf0,ovf1,ovf2,ovf3;		// accumulator overflow
reg [1:0] fsel;					// filter select
reg [15:14] lsb;					// latch for 2 LS bits of coefficient
wire [15:0] dout0,dout1,dout2,dout3;	// filter outputs
reg [15:0] omux;					// data/status output multiplexer
// decode output port addresses
assign w0 = iocs & iowr & (ioaddr == 0);
assign w1 = iocs & iowr & (ioaddr == 1);
assign w2 = iocs & iowr & (ioaddr == 2);
assign w3 = iocs & iowr & (ioaddr == 3);
assign w4 = iocs & iowr & (ioaddr == 4);
// decode filter select addresses
assign f0 = (fsel == 0);
assign f1 = (fsel == 1);
assign f2 = (fsel == 2);
assign f3 = (fsel == 3);
// latch coefficient LSB
always @ (posedge clk)
begin
	if (w2) lsb <= din[15:14];	// LS 2 bits of coefficient
	if (w4) fsel <= din[1:0];	// filter select register
end
// two filters are provided
fir128x16x18 fir0 (
	.cin({din,lsb}),
	.din(din),
	.write(f0 & w0),
	.load(f0 & w3),
	.start(f0 & w1),
	.dout(dout0),
	.rdy(rdy0),
	.ovf(ovf0),
	.clk(clk),
	.rst(rst)
	);
fir128x16x18 fir1 (
	.cin({din,lsb}),
	.din(din),
	.write(f1 & w0),
	.load(f1 & w3),
	.start(f1 & w1),
	.dout(dout1),
	.rdy(rdy1),
	.ovf(ovf1),
	.clk(clk),
	.rst(rst)
	);
fir128x16x18 fir2 (
	.cin({din,lsb}),
	.din(din),
	.write(f2 & w0),
	.load(f2 & w3),
	.start(f2 & w1),
	.dout(dout2),
	.rdy(rdy2),
	.ovf(ovf2),
	.clk(clk),
	.rst(rst)
	);
fir128x16x18 fir3 (
	.cin({din,lsb}),
	.din(din),
	.write(f3 & w0),
	.load(f3 & w3),
	.start(f3 & w1),
	.dout(dout3),
	.rdy(rdy3),
	.ovf(ovf3),
	.clk(clk),
	.rst(rst)
	);
// connect outputs
always @ (posedge clk)
case ({ioaddr[2],fsel})
	0: omux <= dout0;
	1: omux <= dout1;
	2: omux <= dout2;
	3: omux <= dout3;
	4: omux <= {ovf0,14'b00000000000000,rdy0};
	5: omux <= {ovf1,14'b00000000000000,rdy1};
	6: omux <= {ovf2,14'b00000000000000,rdy2};
	7: omux <= {ovf3,14'b00000000000000,rdy3};
	default omux <= 16'hxxxx;
endcase
assign dout = omux;
endmodule

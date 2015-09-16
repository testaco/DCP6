//
//				fir128x16x18.v - Shift-Register based FIR Filter
//
//					(C) Copyright 2008-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module implements one 16-bit FIR filter with 1-127 18-bit coefficients. Filter
// coefficients are loaded in reverse order. Three enable signals control the filter:
//
//		WRITE - writes a data sample into the data shift register
//		LOAD - writes a coefficient into the coefficient shift register
//		START - starts execution of the filter
//
// When interpolating filters are implemented, the filter should be executed more than
// once after each data load with different coefficient sets. For decimating filters,
// multiple data loads occur between each filtering pass. Two status bits are provided: 
//
//		RDY: calculations complete
//		OVF: accumulator overflow
//
// 111 MHz maximum clock frequency with 203 LUT6s, 23 registers and 1 DSP48A1 used.
// Calculation of output values requires one clock cycle per tap plus an additional
// clock cycle for pipeline delays.
//
// History:
//		2012-4-13	use opmode reg instead of reset P input to bypass ISE12.4 bug
//
module fir128x16x18 (
    input [17:0] cin,			// coefficient input
    input [15:0] din,			// data input
    input write,load,start,	// load data, load coefficient and start filter signals
    output [15:0] dout,			// data output
	 output rdy,ovf,				// output ready and overflow signals
    input clk,						// master clock
    input rst						// master reset
    );
// internal signals
wire cz;						// coefficient counter is zero
wire s;						// accumulator sign bit
reg [6:0] cctr,caddr,daddr;	// coefficient and data counters
wire [17:0] coef;			// shift register coefficient output and multiplier input
wire [15:0] data;			// shift register data output and multiplier input
wire [47:0] acc;			// accumulator output
wire [19:0] rnd;			// rounded result
wire [15:0] sat;			// saturated result
// coefficient counter (CCTR) decrements after data written and stops at zero
// coefficient address counter (CADDR) increments while CCTR is non-zero
// data address counter (DADDR) is set on start and then decrements
always @ (posedge clk)
begin
	if (rst) cctr <= 0;
	else if (start) cctr <= din[14:8];		// load number of taps
	else if (~cz) cctr <= cctr - 1'b1;		// then decrement
	if (start) caddr <= din[6:0];				// load first coefficient address
	else if (~cz) caddr <= caddr + 1'b1;	// then increment
	if (start) daddr <= 0;						// data address starts at zero
	else if (~cz) daddr <= daddr + 1'b1;	// then increments
end
assign cz = ~|cctr;				// stop when 0 reached
// coefficient shift register
srl128x18e csr (
	.d(cin),
	.a(caddr),
	.y(coef),
	.ce(load),
	.clk(clk)
	);
// data shift register
srl128x16e dsr (
	.d(din),
	.a(daddr),
	.y(data),
	.ce(write),
	.clk(clk)
	);
// multiply 18-bit data by 18-bit coefficient -  1 clock delay
DSP48A1 #(
	.A0REG(0),			// no input registers
	.A1REG(0),
	.B0REG(0),
	.B1REG(0),
	.CREG(0),
	.DREG(0),
	.MREG(0),
	.PREG(1),			// latch output
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),		// use to delay start signal
	.RSTTYPE("SYNC")
	) mul (
	.OPMODE({4'b00,~start,3'b001}),	// MUL (01) or MAC (09)
	.A({data,2'b00}),	// 16-bit data
	.B(coef),			// 18-bit coefficient
	.BCOUT(),
	.C(48'h000000),
	.D(18'b000000000000000000),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(48'h000000),
	.PCOUT(),
	.P(acc),				// sum of products - bits 35-2 used
	.CLK(clk),
	.CEA(1'b1),
	.CEB(1'b1),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(~cz),			// accumulate when valid coefficients present
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
// overflow if accumulated value extends into upper bits
assign s = acc[35];
assign ovf = (s ^ acc[34]);
// round and saturate if overflow
assign rnd = acc[34:15] + {16'h0000,~s,s,s,s};
assign sat = (ovf ? {s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s,~s}: rnd[19:4]);
// connect outputs
assign dout = sat;
assign rdy = cz;
endmodule

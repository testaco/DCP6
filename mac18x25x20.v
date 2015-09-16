//
//				mac18x25x20.v - Pipelined Multiplier-Accumulator
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module is designed to process 1 channel of data serially and accumulate the results.
// It has an 18-bit data input (din), a 25-bit coefficient input (cin) and a 20-bit output
// (dout). It consists of an 18 x 25 bit multiplier, a 44-bit accumulator and a rounder. The
// accumulator has 2 extra bits for overflow during summation. The upper bits are discarded
// and the next 24 bits of the accumulator are rounded to 20 bits on the output. IFV marks
// the final valid input and a delayed version zeros the accumulator. This module has a
// 6-stage pipeline as follows.
//
// Stage	Operation
//		1	data and coefficient stored in A and B registers in DSP48s 
//		2	lower partial product in lower M register
//		3	upper partial in upper M register; lower partial product in lower P register
//		4	add partial products and place in upper P register; lower product to pl register
//		5	add product to accumulated sum
//		6	round sum of products
//
// Two configurations trade speed and size: 
// P: 72 LUTs, 77 registers and 2 DSP48s are used and the maximum clock rate is 205 MHz.
// The clock rate is limited by the DSP48 P to C delay as the C register can't be used.
// M: 79 LUTs, 79 registers and 2 DSP48s are used and the maximum clock rate is 235 MHz.
// The clock rate is limited by the 44-bit accumulator delay by connecting M to C. The
//	lower product needs an additional register for pipeline delays.
//
// Normal Warnings:
//		<rnd_17> to <rnd_20> are unconnected.
//
// History:
//		1-5-11	modify smac18x24x20x2 for 1 channel and 25-bit coefficients
//
module mac18x25x20 (
	 input [24:0] cin,	// 25-bit coefficient input (stage 1)
    input [17:0] din,	// 18-bit data input (stage 1)
	 input first,last,	// tags first and last data and coefficient inputs
    output [19:0] dout,	// 20-bit accumulated output
	 output ov,				// output valid and Y output
	 output ovf,			// overflow flag
    input clk,				// master clock
	 input rst				// reset adder/accumulator
	 );
// data paths
wire [17:0] cascade;	// path between multipler B ports
wire [35:0] pp;		// multiplier partial product (M)
//wire [47:0] pp;		// multiplier partial product (P)
wire [47:0] pu;		// multiplier upper product (M)
//reg [6:0] pl;			// lower product (P)
reg [6:0] pl1,pl2;	// lower product
wire [43:0] p;			// full product
reg [43:0] a;			// accumulator
reg [4:1] load;		// control signal delays
reg [6:1] latch;
wire sp;					// partial product sign bit
wire sa,ovflo;			// sign and overflow flags from accumulator
wire [41:18] sum;		// sum of products from accumulator truncated to 24 bits
reg [41:18] rnd;		// 24-bit rounded sum of products
reg ovff;				// overflow flag
// pipeline for control signals
always @ (posedge clk)
begin
	load <= {load[3:1],first};		// delay signal to load accumulator
	latch <= {latch[5:1],last};	// delay signal to latch output
end
// multiply 18-bit data by 25-bit coefficient - 4 clocks
// lower 6 coefficient bits (18 signed X 7 unsigned)
DSP48A1 #(
	.A0REG(0),
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(0),
	.DREG(1),
	.MREG(1),
	.PREG(1),
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),
	.RSTTYPE("SYNC")
	) mul0 (
	.OPMODE(8'b00000001),
	.A({1'b0,cin[6:0],10'b0000000000}),
	.B(din),
	.BCOUT(cascade),
	.C(48'h000000),
	.D(18'b000000000000000000),
//	.M(),		// (use P)
	.M(pp),	// (use M)
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(),
	.PCOUT(),
	.P(),		// (use M)
//	.P(pp),	// (use P)
	.CLK(clk),
	.CEA(1'b1),
	.CEB(1'b1),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(1'b1),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(rst),
	.RSTB(rst),
	.RSTC(rst),
	.RSTD(rst),
	.RSTM(rst),
	.RSTP(rst),
	.RSTCARRYIN(rst),
	.RSTOPMODE(1'b0)
	);
// upper 18 coefficient bits (18 signed X 18 signed)
// add partial product
assign sp = pp[35];	// port M
//assign sp = pp[47];	// port P
DSP48A1 #(
	.A0REG(1),
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
//	.CREG(0),	// when using port P
	.CREG(1),	// when using port M
	.DREG(1),
	.MREG(1),
	.PREG(1),
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),
	.RSTTYPE("SYNC")
	) mul1 (
	.OPMODE(8'b00001101),
	.A(cin[24:7]),
	.B(cascade),
	.BCOUT(),
	.C({sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,pp[35:17]}),	// (M)
//	.C({sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,pp[47:17]}),	// (P)
	.D(18'b000000000000000000),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(),
	.PCOUT(),
	.P(pu),
	.CLK(clk),
	.CEA(1'b1),
	.CEB(1'b1),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(1'b1),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(rst),
	.RSTB(rst),
	.RSTC(rst),
	.RSTD(rst),
	.RSTM(rst),
	.RSTP(rst),
	.RSTCARRYIN(rst),
	.RSTOPMODE(1'b0)
	);
// accumulate results
//assign p = {pu[36:0],pl[6:0]};	// (P)
assign p = {pu[36:0],pl2[6:0]};	// (M)
always @ (posedge clk)
begin
//	if (rst) pl <= 0;			// delay lower product (P)
//	else pl <= pp[16:10];
	pl1 <= pp[16:10];			// delay lower product (M)
	pl2 <= pl1;
	if (rst) a <= 0;			// load complete product or add to existing sum of products
	else a <= p + (load[4] ? 44'h00000000000 : a);
end
// detect positive or negative overflow of accumulator and saturate output
// use maximum positive value or one less than maximum negative value
// drop upper bits (extra 2 sign bits)
assign sa = a[43];	// most significant or sign bit
assign ovflo = (a[43] ^ a[42])|(a[42] ^ a[41]);	// overflow
assign sum = ovflo ?
	{sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,5'b00000}
	: a[41:18];	// sum of products
// round 24 bits symmetricly to 20 bits and save result
always @ (posedge clk)
	if (latch[5]) rnd <= sum + {20'b00000000000000000000,~sa,sa,sa,sa};
// drop lower 4 bits
assign dout = rnd[41:22];
assign ov = latch[6];
// check for overflow
always @ (posedge clk)
begin
	if (rst) ovff <= 0;
	else if (latch[5]) ovff <= ovflo;
end
assign ovf = ovff;
endmodule

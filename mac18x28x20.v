//
//				mac18x28x20.v - Pipelined Multiplier-Accumulator
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
// P36: 64 LUTs, 60 registers and 2 DSP48s are used and the maximum clock rate is 205 MHz.
// The clock rate is limited by the DSP48 P to C delay as the C register can't be used.
// The accumulator is 36-bits so the lower product is not used (allows 24-bit out. with 1024 taps).
// P40: 72 LUTs, 77 registers and 2 DSP48s are used and the maximum clock rate is 205 MHz.
// The clock rate is limited by the DSP48 P to C delay as the C register can't be used.
// M40: 79 LUTs, 79 registers and 2 DSP48s are used and the maximum clock rate is 235 MHz.
// The clock rate is limited by the 40-bit accumulator delay by connecting M to C. The
//	lower product needs an additional register for pipeline delays.
//
// Normal Warnings:
//		<rnd_15> to <rnd_18> are unconnected.
//
// History:
//		2011-11-22	modify smac18x25x20 for 28-bit coefficients
//		2013-4-2		use P register and 36-bit accumulator to ease routing with multipl copies
//
module mac18x28x20 (
	 input [27:0] cin,	// 28-bit coefficient input (stage 1)
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
//wire [35:0] pp;		// multiplier partial product (M)
wire [47:0] pp;		// multiplier partial product (P)
wire [47:0] pu;		// multiplier upper product
//reg [3:0] pl;			// lower product (P)
//reg [3:0] pl1,pl2;	// lower product (M)
//wire [39:0] p;			// full product
reg [39:4] a;			// accumulator (36b)
//reg [39:0] a;			// accumulator (40b)
reg [4:1] load;		// control signal delays
reg [6:1] latch;
wire sp;					// partial product sign bit
wire sa,ovflo;			// sign and overflow flags from accumulator
wire [38:15] sum;		// sum of products from accumulator truncated to 24 bits
reg [38:15] rnd;		// 24-bit rounded sum of products
reg ovff;				// overflow flag
// pipeline for control signals
always @ (posedge clk)
begin
	load <= {load[3:1],first};		// delay signal to load accumulator
	latch <= {latch[5:1],last};	// delay signal to latch output
end
// multiply 18-bit data by 28-bit coefficient - 4 clocks
// lower 10 coefficient bits (18 signed X 10 unsigned)
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
	.A({1'b0,cin[9:0],7'b0000000}),
	.B(din),
	.BCOUT(cascade),
	.C(48'h000000),
	.D(18'b000000000000000000),
	.M(),		// (use P)
//	.M(pp),	// (use M)
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(),
	.PCOUT(),
//	.P(),		// (use M)
	.P(pp),	// (use P)
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
//assign sp = pp[35];	// port M
assign sp = pp[47];	// port P
DSP48A1 #(
	.A0REG(1),
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(0),	// when using port P
//	.CREG(1),	// when using port M
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
	.A(cin[27:10]),
	.B(cascade),
	.BCOUT(),
//	.C({sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,pp[35:17]}),	// (M)
	.C({sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,pp[47:17]}),	// (P)
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
//assign p = {pu[35:0],pl[3:0]};	// (P) 40b acc.
//assign p = {pu[35:0],pl2[3:0]};	// (M) 40b acc
always @ (posedge clk)
begin
//	if (rst) pl <= 0;			// delay lower product (P) for 40b acc.
//	else pl <= pp[16:13];
//	pl1 <= pp[16:13];			// delay lower product (M) for 40b acc.
//	pl2 <= pl1;
	if (rst) a <= 0;			// load complete product or add to existing sum of products
	else a <= pu[35:0] + (load[4] ? 36'h000000000 : a);
//	else a <= p + (load[4] ? 40'h0000000000 : a);
end
// detect positive or negative overflow of accumulator and saturate output
// use maximum positive value or one less than maximum negative value
// drop upper bits (extra 2 sign bits)
assign sa = a[39];	// most significant or sign bit
assign ovflo = (a[39] ^ a[38]);	// overflow
assign sum = ovflo ?
	{sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,~sa,5'b00000}
	: a[38:15];	// sum of products
// round 24 bits symmetricly to 20 bits and save result
always @ (posedge clk)
	if (latch[5]) rnd <= sum + {20'b00000000000000000000,~sa,sa,sa,sa};
// drop lower 4 bits
assign dout = rnd[38:19];
assign ov = latch[6];
// check for overflow
always @ (posedge clk)
begin
	if (rst) ovff <= 0;
	else if (latch[5]) ovff <= ovflo;
end
assign ovf = ovff;
endmodule

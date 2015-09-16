//
//						mul18x24x18p.v - Pipelined Multiplier
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module multiplies a 24-bit input (A) by an 18-bit input (B) and
// produces a result rounded to 18 bits (P).
//
// 3 LUT6s, 2 registers and 2 DSP48A1. Maximum clock rate is 205 MHz.
//
module mul18x24x18p (
	 input [23:0] A,	// 24-bit LO input
    input [17:0] B,	// 18-bit RF/IF input
    output [17:0] P,	// 18-bit IF/RF output
	 output V,			// overflow
    input clk,			// master clock
	 input rst			// master reset
	 );
// data paths
wire [17:0] cascade;	// path between multipler B ports
wire [47:0] pp;		// multiplier partial product
wire [47:0] pu;		// upper product
reg s;					// sign of product
reg ovf;					// overflow
// multiply 18-bit data by 24-bit coefficient - 4 clocks
// precalculate multiplier output sign bit for rounding
always @ (posedge clk) s <= A[23] ^ B[17];
// form lower product (18 signed X 6 unsigned)
// add rounding offsets (2^33 for positive or (2^33)-1 for negative result)
DSP48A1 #(
	.A0REG(0),
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(1),
	.DREG(1),
	.MREG(1),
	.PREG(1),
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),
	.RSTTYPE("SYNC")
	) mul0 (
	.OPMODE(8'b00001101),	// multiply and add
	.A({1'b0,A[5:0],11'b00000000000}),
	.B(B),
	.BCOUT(cascade),
	.C({14'h0000,~s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s}),
	.D(18'b000000000000000000),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(),
	.PCOUT(),
	.P(pp),
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
// form upper product (18 signed X 18 signed) and add partial product
assign sp = pp[47];	// partial product sign
DSP48A1 #(
	.A0REG(1),
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
	) mul1 (
	.OPMODE(8'b00001101),	// multiply and add
	.A(A[23:6]),
	.B(cascade),
	.BCOUT(),
	.C({sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,sp,pp[47:17]}),
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
// detect overflow in multiplier or adder
always @ (posedge clk) ovf <= pu[35] ^ pu[34];
// connect output
assign P = pu[34:17];
assign V = ovf;
endmodule

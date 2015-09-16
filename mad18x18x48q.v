//
//			mad18x18x48q.v - Quad 18x18-bit Multiply with 48-bit Add
//
//					(C) Copyright 2008-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module is intended to simplify the implementation of systolic finite
// impulse response filters. There is a 3-clock cycle delay for the multipler
// inputs plus one clock for each of four stages.
//
module mad18x18x48q (
	input [17:0] A0,A1,A2,A3,	// 18-bit multiplier inputs
	input [17:0] B0,B1,B2,B3,
	input RST0,RST1,RST2,RST3,	// reset input registers
	output [47:0] P,				// 48-bit sum of products
	input CE,						// clock enable
	input CLK						// clock
	);
// internal signals
wire [47:0] pc1,pc2,pc3;	// adder cascade inputs
// first multiply-add
DSP48A1 #(
	.A0REG(0),		// one input register
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(0),
	.DREG(0),
	.MREG(1),		// latch multiplier output
	.PREG(1),		// latch accumulator output
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),	// use to delay start signal
	.RSTTYPE("SYNC")
	) mad0 (
	.OPMODE({8'b00000001}),	// CO = A*B
	.A(A0),			// 18-bit multiplier input
	.B(B0),			// 18-bit multiplier input
	.BCOUT(),
	.C(),
	.D(),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(),
	.PCOUT(pc1),		// 48-bit adder output
	.P(),
	.CLK(CLK),
	.CEA(CE),
	.CEB(CE),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(CE),
	.CEP(CE),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(RST0),	// only reset multiplier input registers
	.RSTB(RST0),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
// second multiply-add
DSP48A1 #(
	.A0REG(0),		// one input register
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(0),
	.DREG(0),
	.MREG(1),		// latch multiplier output
	.PREG(1),		// latch accumulator output
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),	// use to delay start signal
	.RSTTYPE("SYNC")
	) mad1 (
	.OPMODE({8'b00000101}),	// CO = A*B+CI
	.A(A1),			// 18-bit multiplier input
	.B(B1),			// 18-bit multiplier input
	.BCOUT(),
	.C(),
	.D(),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(pc1),		// 48-bit adder input
	.PCOUT(pc2),	// 48-bit adder output
	.P(),
	.CLK(CLK),
	.CEA(CE),
	.CEB(CE),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(CE),
	.CEP(CE),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(RST1),	// only reset multiplier input registers
	.RSTB(RST1),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
// third multiply-add
DSP48A1 #(
	.A0REG(0),		// one input register
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(0),
	.DREG(0),
	.MREG(1),		// latch multiplier output
	.PREG(1),		// latch accumulator output
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),	// use to delay start signal
	.RSTTYPE("SYNC")
	) mad2 (
	.OPMODE({8'b00000101}),	// CO = A*B+CI
	.A(A2),			// 18-bit multiplier input
	.B(B2),			// 18-bit multiplier input
	.BCOUT(),
	.C(),
	.D(),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(pc2),		// 48-bit adder input
	.PCOUT(pc3),	// 48-bit adder output
	.P(),
	.CLK(CLK),
	.CEA(CE),
	.CEB(CE),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(CE),
	.CEP(CE),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(RST2),	// only reset multiplier input registers
	.RSTB(RST2),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
// fourth multiply-add
DSP48A1 #(
	.A0REG(0),		// one input register
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(0),
	.DREG(0),
	.MREG(1),		// latch multiplier output
	.PREG(1),		// latch accumulator output
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),	// use to delay start signal
	.RSTTYPE("SYNC")
	) mad3 (
	.OPMODE({8'b00000101}),	// P = A*B+CI
	.A(A3),			// 18-bit multiplier input
	.B(B3),			// 18-bit multiplier input
	.BCOUT(),
	.C(),
	.D(),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(pc3),		// 48-bit adder input
	.PCOUT(),
	.P(P),			// 48-bit adder output
	.CLK(CLK),
	.CEA(CE),
	.CEB(CE),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(CE),
	.CEP(CE),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(RST3),		// only reset multiplier input registers
	.RSTB(RST3),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
endmodule

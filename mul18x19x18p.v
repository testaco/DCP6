//
//						mul18x19x18p.v - Pipelined Multiplier
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module multiplies a 19-bit input (A) by an 18-bit input (B) and
// produces a result rounded to 18 bits (P) in 4 clock cycles.
//
// 25 LUT6s, 38 registers and 1 DSP48A1. Maximum clock rate is 241 MHz.
//
// Normal Warnings:
//		<rnd_0> ... <rnd_5> not connected
//
module mul18x19x18p (
	 input [18:0] A,	// 19-bit LO input
    input [17:0] B,	// 18-bit RF/IF input
    output [17:0] P,	// 18-bit IF/RF output
	 output V,			// overflow
    input clk,			// master clock
	 input rst			// master reset
	 );
// data paths
reg [17:0] b0;		// B delay for lower product
reg a0;				// LSB of A input
wire s;				// sign of lower product
wire [47:0] pu;	// upper product
reg [35:12] rnd;	// 24 bits of product
reg ovf;				// overflow
// multiply 18-bit data by 19-bit coefficient - 3 clocks
// logic to extend 18x18 to 19x18 multiplier
always @ (posedge clk)
begin
	a0 <= A[0];			// delay A LSB
	b0 <= B;				// delay B input for partial product
end
// form upper product (18 signed X 18 signed) and add partial product
assign s = b0[17];	// partial product sign (extend by 31 bits)
DSP48A1 #(
	.A0REG(0),
	.A1REG(1),
	.B0REG(0),
	.B1REG(1),
	.CREG(1),
	.DREG(0),
	.MREG(1),
	.PREG(1),
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),
	.RSTTYPE("SYNC")
	) mul (
	.OPMODE({4'b0000,a0,a0,2'b01}),	// multiply only (0) or multiply and add (1)
	.A(A[18:1]),
	.B(B),
	.BCOUT(),
	.C({s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,s,b0[17:1]}),
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
// add rounding offsets then truncate output - 1 clock
// detect overflow in multiplier or adder
always @ (posedge clk)
begin
	rnd <= pu[34:11] + {18'b000000000000000000,~pu[35],pu[35],pu[35],pu[35],pu[35],pu[35]};
	ovf <= pu[35] ^ pu[34];	// bits 36 and 35 of 37-bit product
end
// connect output
assign P = rnd[35:18];	// bit 36 should be same as bit 35
assign V = ovf;			// one if bits 36 and 35 not equal
endmodule

//
//						agccliphs.v - AGC and Clipper Module
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module contains the receive gain control and clipper for a transceiver. The receive
// gain may be set between 0.0625 and 4095.9375. The clipper may be used to reduce the peak
// to average power ratio (PAPR) of the transmitted signal by changing gain from 0.0625 to
// 15.9375 with input magnitude. All functions are configured by two output ports. 
//
//     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//  6 |                 Integer Gain                  |Fractional Gain| Rcv. Gain (0-4k)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//	 7 |                               |  Integer Gain |Fractional Gain| Comp. Gain (0-16)
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// 145 LUT6s, 43 registers and 2 DSP48s are used. The maximum clock rate is 134 MHz.
//
// Normal Warnings:
//		Output <ov> of <magdet> is unconnected.
//		<iord> is never used.
//
// History:
//  2013-10-9	redo logic to share 2 dedicated multipliers (was 510 LUT6, 431 reg, 121 MHz)
//
module agccliphs (
    input iocs,					// select this module for I/O
    input [2:0] ioaddr,			// select register in this module
    input iowr,					// write register
    input [15:0] din,			// data to write
    input iord,					// read register
    output [15:0] dout,			// data in register
    input [17:0] rdix,rdiy,	// receiver data input
    input riv,						// receiver input valid
    output [15:0] rdox,rdoy,	// receiver data output
    output rov,					// receiver output valid
	 output tie,					// transmit input enable (1/32 clock rate max.)
    input [15:0] tdix,tdiy,	// transmit data inputs
    input tiv,
	 input toe,						// tranmit output enable
    output [15:0] tdox,tdoy,	// transmit data output
    output tov,					// transmit output valid
    input clk,						// master clock and reset
    input rst,
	 input xmt						// T/R switch
    );
// internal signals
reg bbctr;			// baseband clock divider
wire bbclk;			// baseband input strobe
wire iv;				// input valid
wire [7:0] mag;	// magnitude of input (0-1.4)
wire [6:0] mag1;	// magnitude limited to 0-1
wire [7:0] tgain;	// transmit gain ROM
reg [15:0] rgain;	// receive gain register
wire [15:0] gain;	// gain control
wire [47:0] x,y;	// multiplied input signal
reg [3:1] v;		// data valid delay
wire w6,w7;			// output port selection
// address decoding
assign w6 = iocs & iowr & (ioaddr == 6);	// gain register
assign w7 = iocs & iowr & (ioaddr == 7);	// compressor shift reg.
// baseband clock generator divides by 2 so that 
// modem output is never faster than 24 Msps
always @ (posedge clk)
begin
	if (rst) bbctr <= 0;
	else if (toe) bbctr <= ~bbctr;
end
assign bbclk = bbctr & toe;
// calculate magnitude of input - limit max. value to 127
mag8 magdet (
	.x(tdix[15:8]),
	.y(tdiy[15:8]),
	.iv(tiv),
	.mag(mag),
	.ov(),	// use v[1]
	.clk(clk)
	);
assign mag1 = mag[7] ? 7'b1111111 : mag[6:0];
// look up gain (async.)
srl128x8e gm (
	.d(din[7:0]),
	.ce(w7),
	.clk(clk),
	.a(mag1),
	.y(tgain)
	);
// configure receive gain
always @ (posedge clk)
begin
	if (rst) rgain <= 16;		// default to 1.0
	else if (w6) rgain <= din;	// set receiver gain
end
// select transmit or receive gain
assign gain = xmt ? {tgain,8'h00} : rgain;
assign iv = xmt ? tiv : riv;
// multiply input signal by gain value
DSP48A1 #(
	.A0REG(0),	// latch data
	.A1REG(1),
	.B0REG(0),	// don't latch gain
	.B1REG(0),
	.CREG(0),
	.DREG(0),
	.MREG(0),
	.PREG(1),	// latch output
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(0),
	.RSTTYPE("SYNC")
	) mulx (
	.OPMODE(8'b00000001),	// multiply
	.A(xmt ? {tdix,2'b00} : rdix),
	.B({2'b00,gain}),
	.BCOUT(),
	.C(48'h000000),
	.D(18'b000000000000000000),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(48'h000000),
	.PCOUT(),
	.P(x),
	.CLK(clk),
	.CEA(iv),
	.CEB(1'b1),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(v[2]),
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
DSP48A1 #(
	.A0REG(0),	// latch data
	.A1REG(1),
	.B0REG(0),	// don't latch gain
	.B1REG(0),
	.CREG(0),
	.DREG(0),
	.MREG(0),
	.PREG(1),	// latch output
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(0),
	.RSTTYPE("SYNC")
	) muly (
	.OPMODE(8'b00000001),	// multiply
	.A(xmt ? {tdiy,2'b00} : rdiy),
	.B({2'b00,gain}),
	.BCOUT(),
	.C(48'h000000),
	.D(18'b000000000000000000),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(48'h000000),
	.PCOUT(),
	.P(y),
	.CLK(),
	.CEA(iv),
	.CEB(1'b1),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(v[2]),
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
// generate data valid
always @ (posedge clk) v <= {v[2:1],iv};
// connect outputs - use bottom 16 bits for gain of 0-16
assign rdox = x[21:6];	// maximum gain is 4096
assign rdoy = y[21:6];
assign rov = v[2];		// output valid
assign tdox = x[29:14];	// maximum gain is 16
assign tdoy = y[29:14];
assign tov = v[3];		// output valid
assign tie = bbclk;
endmodule

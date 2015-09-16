//
//							clkrec.v - Clock recovery
//
//					(C) Copyright 2008-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module examines I and Q samples and generates carrier frequency
// and symbol timing error signals.
//
// Timing is recovered using the Gardener algorithm. It assumes that the
// signal is oversampled by a factor of 2 and operates the last 3 samples.
// Software must read the error signal, integrate it and adjust the timing
// delay in a resampler. The error signal is:
//
//		e = (x[t-T) - x[t]) * x[t-T/2] - (y[t-T] - y[t]) * y[t-T/2]
//
//	where T is the symbol period. The algorithm implements a zero-crossing
// detector and adjusts the magnitude and sign of the error according to
// the level of the 2 adjacent data sampling points.
//
// Carrier recovery uses a Costas loop which is appropriate for BPSK.
// Software must close the loop by integrating the error signal and
// adjusting the frequency. The error signal is:
//
//		f = x[t] * y[t]
//
// S3E: 49 slices and 2 multipliers are used and the maximum clock rate is 117 MHz.
// S6: 62 LUTs, 92 registers and 2 multipliers are used and the maximum clock rate is 158 MHz.
//
// Normal warnings:
//		<unused1> <unused19> and <unused27> are assigned but never used.
//		<e0<3:0>> is assigned but never used.
//
// History:
//		2011-8-3	new circuit
//
module clkrec (
    input [7:0] dix,diy,	// input signal
    input fv,					// final sample in symbol
    input iv,					// input valid
    output [7:0] dox,doy,	// nominal sample
	 output [15:0] fout,		// frequency error
	 output [15:0] tout,		// timing error
    output ov,					// output valid
    input clk,					// master clock and reset
	 input rst
    );
// internal signals
reg v1;							// delayed input data valid
reg t1,t2,t3,t4;				// delayed final sample flag
reg [7:0] y;					// delayed Y component
reg [7:0] d0,d1,d2,d3,d4;	// adjacent samples at 2X oversampling
wire [8:0] d;					// difference between data samples
wire [15:0] t;					// X and Y timing error components
wire [15:0] f;					// frequency error
wire [19:0] unused20a,unused20b;	// lower bits of product
reg [15:0] ex,e;				// timing error adder
// delay data valid strobe
always @ (posedge clk)
begin
	v1 <= iv;			// delay input strobe
	t1 <= iv & fv;		// delay final sample strobe
	t2 <= t1;
	t3 <= t2;
	t4 <= t3;
end
// generate frequency error signal by multiplying in-phase and quadrature components
MULT18X18SIO #(
	.AREG(1),						// 1 clock delay
	.BREG(1),
	.PREG(0)
	) fmul (
	.A({dix,10'b0000000000}),	// 8-bit inputs
	.B({diy,10'b0000000000}),
	.P({f,unused20a}),				// 16-bit output
	.CEA(iv),
	.CEB(iv),
	.CEP(1'b1),
	.CLK(clk),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTP(1'b0)
	);
// generate frequency error signal by adding two samples
acc16s accf (
	.SUB(1'b0),	// load X error then add Y error
	.ACC(t1),
	.B(f),		// X and Y inputs
	.Q(fout),
	.CLK(clk),
	.CE(v1),
	.SCLR(rst)
	);
// use 3 adjacent samples to calculate derivative of input and multiply by input
always @ (posedge clk)
begin
	if (rst) y <= 0;
	else if (iv) y <= diy;		// save Y samples
	if (rst) d0 <= 0;
	else if (iv|v1) d0 <= iv ? dix : y;	// multiplex X and Y inputs
	if (iv|v1|rst) d1 <= d0;	// shift X and Y samples
	if (iv|v1|rst) d2 <= d1;
	if (iv|v1|rst) d3 <= d2;
	if (iv|v1|rst) d4 <= d3;
end
assign d = {d4[7],d4} - {d0[7],d0};	// x[t+T]-x[t] or y[t+T]-y[t]
// generate timing error signal by multiplying signal and its derivate
MULT18X18SIO #(
	.AREG(1),						// 1 clock delay
	.BREG(1),
	.PREG(0)
	) tmul (
	.A({d,9'b000000000}),		// x[t+T]-x[t] or y[t+T]-y[t] (9-bit input)
	.B({d2,10'b0000000000}),	// *x[t+T/2] or *y[t+T/2] (8-bit input)
	.P({t,unused20b}),				// 16-bit output
	.CEA(1'b1),
	.CEB(1'b1),
	.CEP(1'b1),
	.CLK(clk),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTP(1'b0)
	);
// generate timing error signal by subtracting Q error from I error
always @ (posedge clk)
begin
	ex <= t;					// delay X error
	if (t3) e <= ex + t;	// subtract Y error
end
//acc16s acct (
//	.SUB(t3),	// load X error then subtract Y error
//	.ACC(t3),
//	.B(t),		// X and Y inputs
//	.Q(tout),
//	.CLK(clk),
//	.CE(t2|t3),
//	.SCLR(rst)
//	);
// connect outputs
assign dox = d1;	// data samples here after last shift
assign doy = d0;
assign tout = e;	// timing error
assign ov = t4;	// outputs valid
endmodule

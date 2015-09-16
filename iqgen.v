//
//						iqgen.v - Generate IQ flag from SCLK and DCLK
//
//							(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for personal
// non-profit educational use in the Amateur Radio Service and the license is not
// transferrable. The information is provided as-is for experimental purposes and
// the author does not warranty its freedom from defects or its suitability for any
// specific application.
//
//	This module contains registers that must be placed close together to minimize delays.
//
module iqgen(
    input sclk,	// sample clock
    input dclk,	// double-frequency clock
    output iq		// IQ flag - 1=I, 0=Q
    );
// internal signals
wire iq0;
//reg iq1,iq2;
wire iq1,iq2;
// IQ is used for multiplexing and demultiplexing in-phase and quadrature samples
FDCE ff0 (
	.D(1'b1),	// synchronous set
	.Q(iq0),		// next clock period should be I sample
	.CE(1'b1),
	.C(~sclk),	// use negative-going SCLK edges
	.CLR(iq1)	// asynchronous reset when FF1 is set
	);
FDCE ff1 (
	.D(iq0),		// capture 1 from FF1
	.Q(iq1),		// and pass to FF2 with proper set-up and hold times
	.CE(1'b1),
	.C(~dclk),	// use negative-going DCLK edges
	.CLR(1'b0)		// asynchronous reset unused
	);
FDCE ff2 (
	.D(iq1),		// synchronized I flag
	.Q(iq2),		// signal current DCLK period has I sample
	.CE(1'b1),
	.C(dclk),	// use positive-going DCLK edges
	.CLR(1'b0)		// asynchronous reset unused
	);
//always @ (negedge dclk) iq1 <= iq0;	// synchronize to DCLK and generate preset
//always @ (posedge dclk) iq2 <= iq1;	// synchronize to DCLK and generate preset
assign iq = iq2;
endmodule

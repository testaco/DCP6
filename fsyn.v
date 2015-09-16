//
//					fsyn.v - Carrier Frequency Synchronization
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module counts 64 consecutive frequency and magnitude samples within
// limits and then averages the frequency over 512 or 1024 samples. The
// frequency limit may be +/-Fs/16 or +/-Fs/32. 
//
// 71 LUT6 and 44 registers used. 292 MHz maximum clock rate.
//
module fsyn(
    input [15:0] mag,		// signal magnitude
    input [15:0] frq,		// signal frequency
    input fmv,					// frequency and magnitude valid
    output [15:0] avgfrq,	// average frequency
    output fcd,				// on-frequency carrier detect
	 input clk,					// master clock
	 input nfl,					// 1 = narrow frequency limit
	 input sfs					// 1 = short frequency sample
    );
// internal signals
wire maglim,frqlim,s;	// limits and terminal count
reg [5:0] vctr;			// valid sample counter
wire vtc;
reg fen;						// frequency sample enable
reg [10:0] fctr;			// frequency sample counter
wire ftc;
reg [25:0] facc;			// frequency accumulator
// use only samples greater than -24 dBFS with offset < Fs/16 or Fs/32
assign maglim = ~|mag[15:11];	// < 2048
assign frqlim = (frq[15]^frq[14])|(frq[14]^frq[13])|(frq[13]^frq[12])
					|((frq[12]^frq[11]) & nfl);
always @ (posedge clk)
begin
	if (maglim|frqlim) vctr <= 0;				// count 64 on-freq. samples
	else if (fmv & ~vtc) vctr <= vctr + 1'b1;
	if (maglim) fen <= 0;						// then enable freq. smpl.
	else if (fmv & vtc) fen <= 1'b1;
end
assign vtc = &vctr;	// terminal count
// sum 1024 frequency samples
assign s = frq[15];	// sign of frequency offset
always @ (posedge clk)
begin
	if (~fen) fctr <= 0;								// reset until 64 valid samples
	else if (fmv & ~ftc) fctr <= fctr + 1'b1;	// then count out 1024 samples
	if (~fen) facc <= 0;								// reset then accumulate frequency
	else if (fmv & ~ftc) facc <= facc + {s,s,s,s,s,s,s,s,s,s,frq}; // extend sign 
end
assign ftc = sfs ? fctr[9] : fctr[10];
assign avgfrq = sfs ? facc[24:9] : facc[25:10];	// top 16 bits
assign fcd = ftc;			// output valid when 512 or 1024 samples
endmodule

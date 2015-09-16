`timescale 1ns / 1ps
//
//				test_fsyn.v - Test Carrier Frequency Synchronization
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_fsyn;

	// Inputs
	reg [15:0] mag;
	reg [15:0] frq;
	reg fmv;
	reg clk;

	// Outputs
	wire [15:0] avgfrq;
	wire fcd;

	// Instantiate the Unit Under Test (UUT)
	fsyn uut (
		.mag(mag), 
		.frq(frq), 
		.fmv(fmv), 
		.avgfrq(avgfrq), 
		.fcd(fcd), 
		.clk(clk),
		.nfl(0),
		.sfs(0)
	);

	initial begin
		// Initialize Inputs
		mag = 0;
		frq = 0;
		fmv = 0;
		clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// no signal
		repeat (2048)
		begin
			#5 clk = 0; fmv = 1; mag = 0; frq = 0;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// on frequency low mag. signal (-30 dBFS mag., on frq.)
		repeat (2048)
		begin
			#5 clk = 0; fmv = 1; mag = 1024; frq = 0;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// off frequency signal (-18 dBFS mag., +1/4 FS frq.)
		repeat (2048)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = 16384;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// near frequency low mag. signal (-18 dBFS mag., +1/64 FS frq.)
		repeat (2048)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = 1024;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// off frequency signal (-30 dBFS mag., +1/4 FS frq.)
		repeat (64)
		begin
			#5 clk = 0; fmv = 1; mag = 1024; frq = 16384;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// near frequency signal (-18 dBFS mag., -1/64 FS frq.)
		repeat (320)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = -1024;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// exact frequency signal (-18 dBFS mag. ctr. frq.)
		repeat (512)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = 0;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// near frequency signal (-18 dBFS mag., +1/64 FS frq.)
		repeat (256)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = 1024;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// exact frequency signal (-18 dBFS mag., ctr. frq.)
		repeat (256)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = 0;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// near frequency signal (-18 dBFS mag., -1/256 FS frq.)
		repeat (256)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = -256;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// near frequency signal (-18 dBFS mag., -1/128 FS frq.)
		repeat (256)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = -512;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// near frequency signal (-18 dBFS mag., -3/256 FS frq.)
		repeat (256)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = -768;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// near frequency signal (-18 dBFS mag., -1/64 FS frq.)
		repeat (256)
		begin
			#5 clk = 0; fmv = 1; mag = 4096; frq = -1024;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end
		// no signal
		repeat (2048)
		begin
			#5 clk = 0; fmv = 1; mag = 0; frq = 0;
			#5 clk = 1;
			#5 clk = 0; fmv = 0;
			#5 clk = 1;
		end

	end
      
endmodule


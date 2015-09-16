`timescale 1ns / 1ps
//
//						test_noiseblanker1.v - Noise Blanker
//
//					(C) Copyright 2009-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_noiseblanker1;

	// Inputs
	reg [17:0] dix;
	reg [17:0] diy;
	reg iv;
	reg clk;
	reg [11:0] limit;
	reg pkrst;

	// Outputs
	wire [17:0] dox;
	wire [17:0] doy;
	wire ov;
	wire [11:0] peak;

	// Instantiate the Unit Under Test (UUT)
	noiseblanker1 uut (
		.dix(dix), 
		.diy(diy), 
		.iv(iv), 
		.dox(dox), 
		.doy(doy), 
		.ov(ov), 
		.clk(clk), 
		.limit(limit), 
		.peak(peak), 
		.pkrst(pkrst)
	);

	initial begin
		// Initialize Inputs
		dix = 0;
		diy = 0;
		iv = 0;
		clk = 0;
		limit = 10;
		pkrst = 0;

		// Wait 100 ns for global reset to finish
		#100;
		#5 clk = 0; pkrst = 0;
		#5 clk = 1;
		#5 clk = 0; pkrst = 1;
		#5 clk = 1;
		#5 clk = 0; pkrst = 0;
		#5 clk = 1;
      
		// Generate Signal
		#5 clk = 0; iv = 1; dix = 100; diy = -100;
		#5 clk = 1;
		repeat (6)
		begin
			#5 clk = 0; iv = 0; dix = 0; diy = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; dix = 1000; diy = -100;
		#5 clk = 1;
		repeat (6)
		begin
			#5 clk = 0; iv = 0; dix = 0; diy = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; dix = -100; diy = 100;
		#5 clk = 1;
		repeat (6)
		begin
			#5 clk = 0; iv = 0; dix = 0; diy = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; dix = 100; diy = -10000;
		#5 clk = 1;
		repeat (6)
		begin
			#5 clk = 0; iv = 0; dix = 0; diy = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; dix = 100; diy = -100;
		#5 clk = 1;
		repeat (6)
		begin
			#5 clk = 0; iv = 0; dix = 0; diy = 0;
			#5 clk = 1;
		end
	end
      
endmodule


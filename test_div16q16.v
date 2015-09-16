`timescale 1ns / 1ps
//
//					test_div16q16.v - Test 16-bit Divider
//
// 				(C) Copyright 2006-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_div16q16;

	// Inputs
	reg [15:0] ain;
	reg [15:0] bin;
	reg iv;
	reg clk;

	// Outputs
	wire [15:0] qout;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	div16q16 uut (
		.ain(ain), 
		.bin(bin), 
		.iv(iv), 
		.qout(qout), 
		.ov(ov), 
		.clk(clk) 
	);

	initial begin
		// Initialize Inputs
		ain = 0;
		bin = 0;
		iv = 0;
		clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// idle
		repeat (25)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// test division
		#5 clk = 0; iv = 1; ain = 16'hB504; bin = 16'hB504;
		#5 clk = 1;
		repeat (25)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; ain = 16'hB504; bin = 16'h8000;
		#5 clk = 1;
		repeat (25)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; ain = 16'hB504; bin = 16'h016A;
		#5 clk = 1;
		repeat (25)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; ain = 16'hB504; bin = 16'h0100;
		#5 clk = 1;
		repeat (25)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0;
	end
      
endmodule


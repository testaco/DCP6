`timescale 1ns / 1ps
//
//						test_mag16.v - Test Magnitude Calculator
//
//						(C) Copyright 2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_mag16;

	// Inputs
	reg [15:0] x;
	reg [15:0] y;
	reg iv;
	reg clk;

	// Outputs
	wire [15:0] m;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	mag16 uut (
		.x(x), 
		.y(y), 
		.iv(iv), 
		.m(m), 
		.ov(ov), 
		.clk(clk)
	);

	initial begin
		// Initialize Inputs
		x = 0;
		y = 0;
		iv = 0;
		clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Idle
		repeat (16)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		// Test
		#5 clk = 0; iv = 1; x = 10000; y = 0;
		#5 clk = 1;
		repeat (16)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; x = 0; y = 1000;
		#5 clk = 1;
		repeat (16)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; x = 7071; y = 7071;
		#5 clk = 1;
		repeat (16)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; x = 10000; y = 10000;
		#5 clk = 1;
		repeat (16)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; x = 3000; y = 4000;
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0;

	end
      
endmodule


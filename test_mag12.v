`timescale 1ns / 1ps
//
//					test_mag12.v - Test Magnitude Estimator
//
//					(C) Copyright 2007-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_mag12;

	// Inputs
	reg [11:0] x;
	reg [11:0] y;
	reg iv;
	reg clk;

	// Outputs
	wire [11:0] m;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	mag12 uut (
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
        
		// test
		#5 clk = 0; iv = 1; x = 14; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 10; y = 10;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = 14;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = -10; y = 10;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = -14; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = -10; y = -10;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = -14;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 10; y = -10;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 1414; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 1000; y = 1000;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = 1414;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = -1000; y = 1000;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = -1414; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = -1000; y = -1000;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = -1414;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 1000; y = -1000;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 100>>6; y = (-100)>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = (-100)>>6; y = 100>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 1000>>6; y = (-100)>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = (-1000)>>6; y = 100>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 10000>>6; y = (-100)>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = (-10000)>>6; y = 100>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 100000>>6; y = (-100)>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = (-100000)>>6; y = 100>>6;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = 0;
		#5 clk = 1;
		#5 clk = 0; iv = 1; x = 0; y = 0;
		#5 clk = 1;
	end
      
endmodule


`timescale 1ns / 1ps
//
//					test_mul18x19x18p.v - Test Pipelined Multiplier
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
module test_mul18x19x18p;

	// Inputs
	reg [18:0] A;
	reg [17:0] B;
	reg clk;
	reg rst;
	reg [18:0] i;
	reg [17:0] j;

	// Outputs
	wire [17:0] P;
	wire V;

	// Instantiate the Unit Under Test (UUT)
	mul18x19x18p uut (
		.A(A), 
		.B(B), 
		.P(P), 
		.V(V), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		A = 0;
		B = 0;
		clk = 0;
		rst = 0;
		i = -131072;
		j = 0;

		// Wait 100 ns for global reset to finish
		#100;
 		#5 clk = 0; rst = 1;
		#5 clk = 1;
		#5 clk = 0; rst = 0;
		#5 clk = 1;
       
		// Multiply 
		repeat (1024)
		begin
			#5 clk = 0; A = -4; B = i;
			#5 clk = 1;
			#5 clk = 0; A = -3; B = i;
			#5 clk = 1;
			#5 clk = 0; A = -2; B = i;
			#5 clk = 1;
			#5 clk = 0; A = -1; B = i;
			#5 clk = 1;
			#5 clk = 0; A = 0; B = i;
			#5 clk = 1;
			#5 clk = 0; A = 1; B = i;
			#5 clk = 1;
			#5 clk = 0; A = 2; B = i;
			#5 clk = 1;
			#5 clk = 0; A = 3; B = i;
			#5 clk = 1;
			#5 clk = 0; A = 4; B = i;
			#5 clk = 1;
			i = i+256;
		end
	end
      
endmodule


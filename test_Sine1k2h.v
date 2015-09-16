`timescale 1ns / 1ps
//
//					test_Sine1k2h.v - Test 1024x18 Half-sine ROM
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_Sine1k2h;

	// Inputs
	reg [9:0] aa;
	reg [9:0] ab;
	reg clk;
	reg rst;

	// Outputs
	wire [17:0] da;
	wire [17:0] db;

	// Instantiate the Unit Under Test (UUT)
	Sine1k2h uut (
		.aa(aa), 
		.ab(ab), 
		.da(da), 
		.db(db), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		aa = 512;
		ab = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
 		#5 clk = 0; rst = 1;
		#5 clk = 1;
		#5 clk = 0; rst = 0;
		#5 clk = 1;
       
		// Cycle through contents
		repeat (1024)
		begin
			#5 clk = 0; 
			#5 clk = 1;
			aa = aa + 1;
			ab = ab + 1;
		end
		repeat (4)
		begin
			#5 clk = 0; 
			#5 clk = 1;
		end
	end
      
endmodule


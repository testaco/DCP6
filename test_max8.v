`timescale 1ns / 1ps
//
//				test_max8.v - Test Circuit to Calculate Maximum Magnitude of Signed Input
//
//								(C) Copyright 2012 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-6 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
module test_max8;

	// Inputs
	reg [7:0] sig;
	reg clk;
	reg rst;

	// Outputs
	wire [6:0] max;

	// Instantiate the Unit Under Test (UUT)
	max8 uut (
		.sig(sig), 
		.max(max), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		sig = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
      // reset
		#5 clk = 0; rst = 1;
		#5 clk = 1;		
		#5 clk = 0; rst = 0;
		#5 clk = 1;		
		// test
		repeat (8)
		begin
			#5 clk = 0; sig = sig + 1;
			#5 clk = 1;	
		end		
		repeat (24)
		begin
			#5 clk = 0; sig = sig - 1;
			#5 clk = 1;	
		end		
		repeat (40)
		begin
			#5 clk = 0; sig = sig + 1;
			#5 clk = 1;	
		end		
		repeat (56)
		begin
			#5 clk = 0; sig = sig - 1;
			#5 clk = 1;	
		end		
		repeat (32)
		begin
			#5 clk = 0; sig = sig + 1;
			#5 clk = 1;	
		end		
		#5 clk = 0; rst = 1;
		#5 clk = 1;		
		#5 clk = 0; rst = 0;
		#5 clk = 1;		
		#5 clk = 0;
	end
      
endmodule


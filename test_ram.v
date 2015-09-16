`timescale 1ns / 1ps
//
//							 Test 1 kW RAM with Blink Program for CPU
//
//							(C) Copyright 2010-2011 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-3 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
// This module tests a 1024 x 16-bit dual-port memory using 1 block RAM.
//
module test_ram;

	// Inputs
	reg [9:0] aa;
	reg [9:0] ab;
	reg [15:0] dia;
	reg [15:0] dib;
	reg cea;
	reg ceb;
	reg wea;
	reg web;
	reg clk;
	reg rst;

	// Outputs
	wire [15:0] doa;
	wire [15:0] dob;

	// Instantiate the Unit Under Test (UUT)
	blink6ram uut (
		.aa(aa), 
		.ab(ab), 
		.dia(dia), 
		.dib(dib), 
		.doa(doa), 
		.dob(dob), 
		.cea(cea), 
		.ceb(ceb), 
		.wea(wea), 
		.web(web), 
		.clk(clk), 
		.rst(1'b0)
	);

	initial begin
		// Initialize Inputs
		aa = -1;
		ab = 0;
		dia = 0;
		dib = 0;
		cea = 1;
		ceb = 1;
		wea = 0;
		web = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
      // Reset
		repeat (8)
		begin
			#5 clk = 0; rst = 1;
			#5 clk = 1;
		end
		// read contents
		repeat (32)
		begin
			#5 clk = 0; rst = 0; aa = aa + 1;
			#5 clk = 1;
		end

	end
      
endmodule


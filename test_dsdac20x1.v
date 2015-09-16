`timescale 1ns / 1ps
//
//							test_dsdac20x1.v - Test 20-bit Delta-Sigma DAC
//
//								(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-3 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
// The module under test is a first-order delta-sigma modulator that generates an analog output
// when averaged by an external RC filter. 
//
module test_dsdac20x1;

	// Inputs
	reg [19:0] din;
	reg we;
	reg clk;
	reg rst;

	// Outputs
	wire aout;

	// Instantiate the Unit Under Test (UUT)
	dsdac20x1 uut (
		.din(din), 
		.we(we), 
		.clk(clk), 
		.rst(rst), 
		.aout(aout)
	);

	initial begin
		// Initialize Inputs
		din = 0;
		we = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		#5 clk = 0; rst = 1;
		#5 clk = 1;
		repeat (1000)
		begin
			#5 clk = 0; rst = 0;
			#5 clk = 1;
		end
		#5 clk = 0; we = 1; din = 20'h01000;
		#5 clk = 1;
		repeat (1000)
		begin
			#5 clk = 0; we = 0;
			#5 clk = 1;
		end
		#5 clk = 0; we = 1; din = 20'hFF000;
		#5 clk = 1;
		repeat (1000)
		begin
			#5 clk = 0; we = 0;
			#5 clk = 1;
		end

	end
      
endmodule


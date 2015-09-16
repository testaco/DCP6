`timescale 1ns / 1ps
//
//						Test 4-Input Multiplxer with Latch
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_MUX4S;

	// Inputs
	reg [3:0] D;
	reg [1:0] S;
	reg CE;
	reg CLK;
	reg RST;

	// Outputs
	wire Q;

	// Instantiate the Unit Under Test (UUT)
	MUX4S uut (
		.D(D), 
		.S(S), 
		.Q(Q), 
		.CE(CE), 
		.CLK(CLK), 
		.RST(RST)
	);

	initial begin
		// Initialize Inputs
		D = 0;
		S = 0;
		CE = 1;
		CLK = 0;
		RST = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		#5 CLK = 0; RST = 1;
		#5 CLK = 1;
		#5 CLK = 0; RST = 0;
		#5 CLK = 1;
		#5 CLK = 0; D = 1; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D = 1; S = 1;
		#5 CLK = 1;
		#5 CLK = 0; D = 1; S = 2;
		#5 CLK = 1;
		#5 CLK = 0; D = 1; S = 3;
		#5 CLK = 1;
		#5 CLK = 0; D = 2; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D = 2; S = 1;
		#5 CLK = 1;
		#5 CLK = 0; D = 2; S = 2;
		#5 CLK = 1;
		#5 CLK = 0; D = 2; S = 3;
		#5 CLK = 1;
		#5 CLK = 0; D = 4; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D = 4; S = 1;
		#5 CLK = 1;
		#5 CLK = 0; D = 4; S = 2;
		#5 CLK = 1;
		#5 CLK = 0; D = 4; S = 3;
		#5 CLK = 1;
		#5 CLK = 0; D = 8; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D = 8; S = 1;
		#5 CLK = 1;
		#5 CLK = 0; D = 8; S = 2;
		#5 CLK = 1;
		#5 CLK = 0; D = 8; S = 3;
		#5 CLK = 1;
		#5 CLK = 0;
		#5 CLK = 1;

	end
      
endmodule


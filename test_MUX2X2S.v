`timescale 1ns / 1ps
//
//					Test 2-Input 2-bit Multiplxer with Latch
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
module test_MUX2X2S;

	// Inputs
	reg [1:0] D0;
	reg [1:0] D1;
	reg S;
	reg CE;
	reg CLK;
	reg RST;

	// Outputs
	wire [1:0] Q;

	// Instantiate the Unit Under Test (UUT)
	MUX2X2S uut (
		.D0(D0), 
		.D1(D1), 
		.S(S), 
		.Q(Q), 
		.CE(CE), 
		.CLK(CLK), 
		.RST(RST)
	);

	initial begin
		// Initialize Inputs
		D0 = 0;
		D1 = 0;
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
		#5 CLK = 0; D0 = 0; D1 = 3; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D0 = 1; D1 = 2; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D0 = 2; D1 = 1; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D0 = 3; D1 = 0; S = 0;
		#5 CLK = 1;
		#5 CLK = 0; D0 = 0; D1 = 3; S = 1;
		#5 CLK = 1;
		#5 CLK = 0; D0 = 1; D1 = 2; S = 1;
		#5 CLK = 1;
		#5 CLK = 0; D0 = 2; D1 = 1; S = 1;
		#5 CLK = 1;
		#5 CLK = 0; D0 = 3; D1 = 0; S = 1;
		#5 CLK = 1;
		#5 CLK = 0;
		#5 CLK = 1;

	end
      
endmodule


`timescale 1ns / 1ps
//
//				test_addsubmovneg16a.v - Test 16-bit adder/subtracter
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_addsubmovneg16a;

	// Inputs
	reg SUB;
	reg ENA;
	reg [15:0] A;
	reg [15:0] B;
	reg CI;

	// Outputs
	wire CO;
	wire [15:0] Y;

	// Instantiate the Unit Under Test (UUT)
	addsubmovneg16a uut (
		.SUB(SUB), 
		.ENA(ENA), 
		.A(A), 
		.B(B), 
		.CI(CI), 
		.CO(CO), 
		.Y(Y)
	);

	initial begin
		// Initialize Inputs
		SUB = 0;
		ENA = 0;
		A = 0;
		B = 0;
		CI = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// MOV
		#10 A = 6666; B = 3333; CI = 0; ENA = 0; SUB = 0;
		// MVN
		#10 A = 6666; B = 3333; CI = 1; ENA = 0; SUB = 1;
		// ADD
		#10 A = 6666; B = 3333; CI = 0; ENA = 1; SUB = 0;
		// SUB
		#10 A = 6666; B = 3333; CI = 1; ENA = 1; SUB = 1;
		// MOVC
		#10 A = 6666; B = 3333; CI = 1; ENA = 0; SUB = 0;
		// MVNC
		#10 A = 6666; B = 3333; CI = 0; ENA = 0; SUB = 1;
		// ADC
		#10 A = 6666; B = 3333; CI = 1; ENA = 1; SUB = 0;
		// SBC
		#10 A = 6666; B = 3333; CI = 0; ENA = 1; SUB = 1;
		// ADD
		#10 A = 65535; B = 0; CI = 0; ENA = 1; SUB = 0;
		// ADD
		#10 A = 65535; B = 1; CI = 0; ENA = 1; SUB = 0;
		// ADD
		#10 A = 65535; B = 0; CI = 1; ENA = 1; SUB = 0;
		// ADD
		#10 A = 65535; B = 1; CI = 1; ENA = 1; SUB = 0;
		// done
		#10 A = 0; B = 0; CI = 0; ENA = 0; SUB = 0;

	end
      
endmodule


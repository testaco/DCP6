//
//		test_dds32.v - Test 32-bit Direct Digital Frequency Synthesizer
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
`timescale 1ns / 1ps
module test_dds32;

	// Inputs
	reg sclk;
	reg dclk;
	reg iq;
	reg rst;
	reg [31:0] frq;

	// Outputs
	wire [17:0] doxy;

	// Instantiate the Unit Under Test (UUT)
	dds32 uut (
		.doxy(doxy), 
		.sclk(sclk), 
		.dclk(dclk),
		.iq(iq),
		.rst(rst), 
		.frq(frq)
	);
	always @ (negedge dclk) iq <= sclk;

	initial begin
		// Initialize Inputs
		sclk = 0;
		dclk = 0;
		rst = 0;
		frq = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Clock DDS
		repeat (10)
		begin
			#5 sclk = 0; dclk = 0; rst = 0;
			#5 sclk = 1; dclk = 1;  
			#5 sclk = 1; dclk = 0;
			#5 sclk = 0; dclk = 1;
		end			
		repeat (20)
		begin
			#5 sclk = 0; dclk = 0; rst = 1; frq = 32'h00010000; // Fo = Fs * 1/65536
			#5 sclk = 1; dclk = 1;  
			#5 sclk = 1; dclk = 0;
			#5 sclk = 0; dclk = 1;
		end			
		repeat (8192)
		begin
			#5 sclk = 0; dclk = 0; rst = 0;
			#5 sclk = 1; dclk = 1;  
			#5 sclk = 1; dclk = 0;
			#5 sclk = 0; dclk = 1;
		end			
		repeat (2)
		begin
			#5 sclk = 0; dclk = 0; rst = 0; frq = 0;
			#5 sclk = 1; dclk = 1;  
			#5 sclk = 1; dclk = 0;
			#5 sclk = 0; dclk = 1;
		end			
		repeat (25000)
		begin
			#5 sclk = 0; dclk = 0; rst = 0; frq = 32'h00010000; // Fo = Fs * 1/65536
			#5 sclk = 1; dclk = 1;  
			#5 sclk = 1; dclk = 0;
			#5 sclk = 0; dclk = 1;
		end			
	end
      
endmodule


//
//		test_dds2k19.v - Test 32-bit Direct Digital Frequency Synthesizer
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
`timescale 1ns / 1ps
module test_dds2k19;

	// Inputs
	reg dclk;
	reg iq;
	reg rst;
	reg [31:0] frq;

	// Outputs
	wire [18:0] doxy;
	reg [18:0] x0,x,y;

	// Instantiate the Unit Under Test (UUT)
	dds2k19 uut (
		.doxy(doxy), 
		.dclk(dclk),
		.iq(iq),
		.rst(rst), 
		.frq(frq)
	);
	always @ (posedge dclk)
	begin
		x0 <= doxy;	// delay X
		if (~iq) x <= x0;
		if (~iq) y <= doxy;
	end

	initial begin
		// Initialize Inputs
		iq = 0;
		dclk = 0;
		rst = 0;
		frq = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Clock DDS
		repeat (16)
		begin
			#5 iq = 1; dclk = 0; rst = 1; frq = 32'h00040000; // Fo = Fs * 1/16384
			#5 iq = 1; dclk = 1;  
			#5 iq = 0; dclk = 0;
			#5 iq = 0; dclk = 1;
		end			
		repeat (16400)
		begin
			#5 iq = 1; dclk = 0; rst = 0;
			#5 iq = 1; dclk = 1;  
			#5 iq = 0; dclk = 0;
			#5 iq = 0; dclk = 1;
		end			
	end
      
endmodule


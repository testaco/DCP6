`timescale 1ns / 1ps
//
//					test_logmul20s16.v - Test Lograthimic multiplier
//
//					(C) Copyright 2004-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_logmul20s16;

	// Inputs
	reg [19:0] dix,diy;
	reg iv;
	reg clk;
	reg rst;
	reg [15:0] gain;	// 4-bit exponent and 12-bit mantissa (0.5-1)

	// Outputs
	wire [15:0] dox,doy;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	logmul20s16a uut (
		.dix(dix), 
		.diy(diy), 
		.iv(iv), 
		.dox(dox), 
		.doy(doy), 
		.ov(ov), 
		.clk(clk), 
		.rst(rst),
		.gain(gain) 
	);

	initial begin
		// Initialize Inputs
		dix = 0;
		diy = 0;
		iv = 0;
		clk = 0;
		rst = 0;
		gain = 0;

		// Wait 100 ns for global reset to finish
		#100;
      // reset
		#5 clk = 0; rst = 1;
		#5 clk = 1;
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		// test with various gains
		repeat (32)
		begin
			#5 clk = 0; iv = 1; dix = 1; diy = -1;
			#5 clk = 1; 
			repeat (15)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 16; diy = -16;
			#5 clk = 1;
			repeat (15)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 256; diy = -256;
			#5 clk = 1;
			repeat (15)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 4096; diy = -4096;
			#5 clk = 1;
			repeat (15)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 65536; diy = -65536;
			#5 clk = 1;
			repeat (15)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			gain = gain + 2048;
		end
		#5 clk = 0; iv = 0;

	end
      
endmodule


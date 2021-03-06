`timescale 1ns / 1ps
//
//					test_sqrt16.v - Test 16-bit Square Rooter
//
//						(C) Copyright 2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_sqrt16;

	// Inputs
	reg [31:0] din;
	reg iv;
	reg clk;

	// Outputs
	wire [15:0] dout;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	sqrt16 uut (
		.din(din), 
		.iv(iv), 
		.dout(dout), 
		.ov(ov), 
		.clk(clk) 
	);

	initial begin
		// Initialize Inputs
		din = 0;
		iv = 0;
		clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Test
		#5 clk = 0; iv = 1; din = 140;
		#5 clk = 1;
		repeat (17)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; din = 144;
		#5 clk = 1;
		repeat (17)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; din = 148;
		#5 clk = 1;
		repeat (17)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; din = 36864; // 144*256
		#5 clk = 1;
		repeat (17)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; din = 65025; // 255*255
		#5 clk = 1;
		repeat (17)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 1; din = 4294836225; // 65535*65535
		#5 clk = 1;
		repeat (17)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0;
	
	end
      
endmodule


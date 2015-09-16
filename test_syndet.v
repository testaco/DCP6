`timescale 1ns / 1ps
//
// test_syndet.v - Test Phase Correlator
//
module test_syndet;

	// Inputs
	reg [5:0] din;
	reg iv;
	reg [5:0] length;
	reg clk;
	reg rst;

	// Outputs
	wire [13:0] dout;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	syndet uut (
		.din(din), 
		.iv(iv), 
		.dout(dout), 
		.ov(ov), 
		.length(length), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		din = 0;
		iv = 0;
		length = 63;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// zero data
      repeat (320)
		begin
			#5 clk = 0; rst = 1;
			#5 clk = 1;
		end
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		// uncorrelated data
      repeat (320)
		begin
			#5 clk = 0; iv = 1; din = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 1; din = 21;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 1; din = 42;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		// correlated data
      repeat (80)
		begin
			#5 clk = 0; iv = 1; din = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 1; din = 16;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 1; din = 32;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 1; din = 48;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		// uncorrelated data
      repeat (320)
		begin
			#5 clk = 0; iv = 1; din = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 1; din = 21;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
			#5 clk = 0; iv = 1; din = 42;
			#5 clk = 1;
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iv = 0;
		#5 clk = 1;
	end
      
endmodule


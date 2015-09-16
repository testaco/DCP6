`timescale 1ns / 1ps
// 
//			test_cordic16p8.v - Test 16-in/8-out parallel CORDIC Processing Engine
// 
//					  (C) Copyright 2007-2008 John B. Stephensen
// 
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_cordic16p8;

	// Inputs
	reg [15:0] xi;
	reg [15:0] yi;
	reg iv;
	reg clk;

	// Outputs
	wire [7:0] xo;
	wire [7:0] zo;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	cordic16p8 uut (
		.xi(xi), 
		.yi(yi), 
		.iv(iv), 
		.xo(xo), 
		.zo(zo), 
		.ov(ov), 
		.clk(clk) 
	);

	initial begin
		// Initialize Inputs
		xi = 0;
		yi = 0;
		iv = 0;
		clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
      // idle  
		repeat (2)
		begin
			#5 clk = 1;
			#5 clk = 1; xi = 0; yi = 0; iv = 0;
			#5 clk = 0;
			#5 clk = 0;
		end
		// translate 0-360 degree angles at -7 dBFS
		#5 clk = 1;
		#5 clk = 1; xi = 14142; yi = 0; iv = 1; // 0 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 10000; yi = 10000; // 45 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = 14142; // 90 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -10000; yi = 10000; // 135 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -14142; yi = 0; // 180 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -10000; yi = -10000; // 225 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = -14142; // 270 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 10000; yi = -10000; // 315 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 14142; yi = 0; // 360 degrees
		#5 clk = 0;
		#5 clk = 0;
		repeat (4)
		begin
			#5 clk = 1;
			#5 clk = 1; xi = 0; yi = 0; iv = 0;
			#5 clk = 0;
			#5 clk = 0;
		end
		// translate 0-360 degree angles at -13 dBFS
		#5 clk = 1;
		#5 clk = 1; xi = 7071; yi = 0; iv = 1; // 0 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 5000; yi = 5000; // 45 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = 7071; // 90 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -5000; yi = 5000; // 135 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -7071; yi = 0; // 180 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -5000; yi = -5000; // 225 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = -7071; // 270 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 5000; yi = -5000; // 315 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 7071; yi = 0; // 360 degrees
		#5 clk = 0;
		#5 clk = 0;
		repeat (4)
		begin
			#5 clk = 1;
			#5 clk = 1; xi = 0; yi = 0; iv = 0;
			#5 clk = 0;
			#5 clk = 0;
		end
		// translate 0-360 degree angles at -19 dBFS
		#5 clk = 1;
		#5 clk = 1; xi = 3535; yi = 0; iv = 1; // 0 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 2500; yi = 2500; // 45 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = 3535; // 90 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -2500; yi = 2500; // 135 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -3535; yi = 0; // 180 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -2500; yi = -2500; // 225 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = -3535; // 270 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 2500; yi = -2500; // 315 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 3535; yi = 0; // 360 degrees
		#5 clk = 0;
		#5 clk = 0;
		repeat (4)
		begin
			#5 clk = 1;
			#5 clk = 1; xi = 0; yi = 0; iv = 0;
			#5 clk = 0;
			#5 clk = 0;
		end
		// translate 0-360 degree angles at -47 dBFS
		#5 clk = 1;
		#5 clk = 1; xi = 141; yi = 0; iv = 1; // 0 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 100; yi = 100; // 45 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = 141; // 90 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -100; yi = 100; // 135 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -141; yi = 0; // 180 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -100; yi = -100; // 225 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = -141; // 270 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 100; yi = -100; // 315 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 141; yi = 0; // 360 degrees
		#5 clk = 0;
		#5 clk = 0;
		repeat (4)
		begin
			#5 clk = 1;
			#5 clk = 1; xi = 0; yi = 0; iv = 0;
			#5 clk = 0;
			#5 clk = 0;
		end
		// translate 0-360 degree angles at -67 dBFS
		#5 clk = 1;
		#5 clk = 1; xi = 14; yi = 0; iv = 1; // 0 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 10; yi = 10; // 45 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = 14; // 90 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -10; yi = 10; // 135 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -14; yi = 0; // 180 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = -10; yi = -10; // 225 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 0; yi = -14; // 270 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 10; yi = -10; // 315 degrees
		#5 clk = 0;
		#5 clk = 0;
		#5 clk = 1;
		#5 clk = 1; xi = 14; yi = 0; // 360 degrees
		#5 clk = 0;
		#5 clk = 0;
		repeat (12)
		begin
			#5 clk = 1;
			#5 clk = 1; xi = 0; yi = 0; iv = 0;
			#5 clk = 0;
			#5 clk = 0;
		end
	end
      
endmodule


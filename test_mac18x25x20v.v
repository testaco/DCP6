`timescale 1ns / 1ps
//
//			test_mac18x25x20.v - Test Pipelined Multiplier-Accumulator
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_mac18x25x20;

	// Inputs
	reg [24:0] cin;
	reg [17:0] din;
	reg first;
	reg last;
	reg clk;
	reg rst;

	// Outputs
	wire [19:0] dout;
	wire ov;
	wire ovf;

	// Instantiate the Unit Under Test (UUT)
	mac18x25x20 uut (
		.cin(cin), 
		.din(din), 
		.first(first),
		.last(last),
		.dout(dout), 
		.ov(ov), 
		.ovf(ovf), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		cin = 0;
		din = 0;
		first = 0;
		last = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// reset
		#5 clk = 0; rst = 1;
		#5 clk = 1;
		repeat (15)
		begin
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		end
		
		// Test 1
		#5 clk = 0; first = 1; last = 0; cin = 262144; din = 1; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = 10; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = 100; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = 1000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = 10000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 1; cin = 262144; din = 100000; // 
		#5 clk = 1;
		#5 clk = 0; first = 1; last = 0; cin = 262144; din = -1; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = -10; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = -100; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = -1000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 262144; din = -10000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 1; cin = 262144; din = -100000; // 
		#5 clk = 1;
		#5 clk = 0; first = 1; last = 0; cin = 131072; din = 1; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 131072; din = 10; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 131072; din = 100; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 131072; din = 1000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 131072; din = 10000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 1; cin = 131072; din = 100000; // 
		#5 clk = 1;
		#5 clk = 0; first = 1; last = 0; cin = 65536; din = -1; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 65536; din = -10; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 65536; din = -100; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 65536; din = -1000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 0; cin = 65536; din = -10000; // 
		#5 clk = 1;
		#5 clk = 0; first = 0; last = 1; cin = 65536; din = -100000; // 
		#5 clk = 1;
		#5 clk = 0; first = 1; last = 1; cin = 25'h0800000; din = 18'h10000; // 1/2 x1/2 = 1/4
		#5 clk = 1;
		#5 clk = 0; first = 1; last = 1; cin = 25'h0FFFFFF; din = 18'h1FFFF; // 1 x1 = 1
		#5 clk = 1;
		#5 clk = 0; first = 1; last = 1; cin = 0; din = 0;
		#5 clk = 1;
		
		// clock out results
		repeat (16)
		begin
		#5 clk = 0; first = 0; last = 0;
		#5 clk = 1;
		end

	end
      
endmodule


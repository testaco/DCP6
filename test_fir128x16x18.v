`timescale 1ns / 1ps
//
//				test_fir128x16x18.v - Test FIR Filter Peripheral
//
//					(C) Copyright 2008-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_fir128x16x18;

	// Inputs
	reg [2:0] ioaddr;
	reg iocs;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg clk;
	reg rst;

	// Outputs
	wire [15:0] dout;

	// Instantiate the Unit Under Test (UUT)
	dfir128x16x18 uut (
		.ioaddr(ioaddr), 
		.iocs(iocs), 
		.din(din), 
		.iowr(iowr), 
		.iord(iord), 
		.dout(dout), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		ioaddr = 0;
		iocs = 0;
		din = 0;
		iowr = 0;
		iord = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
      // Reset
		#5 clk = 0; rst = 1;
		#5 clk = 1;
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		// Load Coefficients
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 5; din = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 2048;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 4096;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 8192;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 16384;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 8192;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 4096;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 2048;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// Test
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 0; din = 16384; // data
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0700; // start
		#5 clk = 1;
		repeat (7)
		begin
			#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
			#5 clk = 1;
		end
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 2; // read status
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0; // read result
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		repeat (7)
		begin
			#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 0; din = 0; // data
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0700; // start
			#5 clk = 1;
			repeat (7)
			begin
				#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iocs = 1; iord = 1; ioaddr = 2; // read status
			#5 clk = 1;
			#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0; // read result
			#5 clk = 1;
			#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
			#5 clk = 1;
		end
		#5 clk = 0;
	end
      
endmodule


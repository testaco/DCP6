`timescale 1ns / 1ps
//
//		test_crc1632p8.v - Test FCS Calculation for AX.25 and IEEE 802.3
//
//						(C) Copyright 2009-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This test compares serial and parallel implementations of CRCs.
//
module test_crc1632p8;

	// Inputs
	reg iocs;
	reg [2:0] ioaddr;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg clk;
	reg clk2x;
	reg rst;

	// Outputs
	wire [15:0] dout0,dout1;

	// Instantiate the Units Under Test (UUT)
	crc1632p8 uut0 (
		.iocs(iocs), 
		.ioaddr(ioaddr), 
		.din(din), 
		.iowr(iowr), 
		.dout(dout0), 
		.iord(iord), 
		.clk(clk), 
		.rst(rst)
	);
	crc1632 uut1 (
		.iocs(iocs), 
		.ioaddr(ioaddr), 
		.din(din), 
		.iowr(iowr), 
		.dout(dout1), 
		.iord(iord), 
		.mclk(clk), 
		.dclk(clk2x), 
		.rst(rst)
	);
	always @ (posedge clk2x) clk <= ~clk;

	initial begin
		// Initialize Inputs
		iocs = 0;
		ioaddr = 0;
		din = 0;
		iowr = 0;
		iord = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// hardware reset
		#5 clk2x = 0; rst = 1;
		#5 clk2x = 1;
		#5 clk2x = 0;
		#5 clk2x = 1;
		#5 clk2x = 0; rst = 0;
		#5 clk2x = 1;
		#5 clk2x = 0;
		#5 clk2x = 1;
		// test with 8 bit data
		#5 clk2x = 0; iocs = 1; ioaddr = 3; iowr = 1;
		#5 clk2x = 1;
		#5 clk2x = 0;
		#5 clk2x = 1;
		#5 clk2x = 0; iocs = 0; ioaddr = 0; iowr = 0;
		#5 clk2x = 1;
		#5 clk2x = 0;
		#5 clk2x = 1;
		repeat (16)
		begin
			#5 clk2x = 0; iocs = 1; ioaddr = 0; iowr = 1; din = 16'h0037;
			#5 clk2x = 1;
			#5 clk2x = 0;
			#5 clk2x = 1;
			repeat (4)
			begin
				#5 clk2x = 0; iocs = 0; iowr = 0;
				#5 clk2x = 1;
				#5 clk2x = 0;
				#5 clk2x = 1;
			end
		end
		repeat (8)
		begin
			#5 clk2x = 0; iocs = 0; ioaddr = 0; iowr = 0;
			#5 clk2x = 1;
			#5 clk2x = 0;
			#5 clk2x = 1;
		end
		// test with 16 bit data
		#5 clk2x = 0; iocs = 1; ioaddr = 3; iowr = 1;
		#5 clk2x = 1;
		#5 clk2x = 0;
		#5 clk2x = 1;
		#5 clk2x = 0; iocs = 0; ioaddr = 0; iowr = 0;
		#5 clk2x = 1;
		#5 clk2x = 0;
		#5 clk2x = 1;
		repeat (8)
		begin
			#5 clk2x = 0; iocs = 1; ioaddr = 1; iowr = 1; din = 16'h3737;
			#5 clk2x = 1;
			#5 clk2x = 0;
			#5 clk2x = 1;
			repeat (8)
			begin
				#5 clk2x = 0; iocs = 0; iowr = 0;
				#5 clk2x = 1;
				#5 clk2x = 0;
				#5 clk2x = 1;
			end
		end

	end
      
endmodule


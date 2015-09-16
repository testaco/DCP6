`timescale 1ns / 1ps
//
//					test_spils.v - Test 8-bit Serial Peripheral Inteface
//
//						(C) Copyright 2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_spils;

	// Inputs
	reg iocs;
	reg [2:0] ioaddr;
	reg [15:0] din;
	reg iowr;
	reg sdi;
	reg clk;
	reg rst;

	// Outputs
	wire [15:0] dout;
	wire sdo;
	wire sck;
	wire ss0n,ss1n;

	// Instantiate the Unit Under Test (UUT)
	spils uut (
		.iocs(iocs), 
		.ioaddr(ioaddr), 
		.din(din), 
		.iowr(iowr), 
		.dout(dout), 
		.sdi(sdi), 
		.sdo(sdo), 
		.sck(sck), 
		.ss0n(ss0n), 
		.ss1n(ss1n), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		iocs = 0;
		ioaddr = 0;
		din = 0;
		iowr = 0;
		sdi = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Reset
		#5 clk = 0; rst = 1;
		#5 clk = 1;
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		// SS on
		#5 clk = 0; iocs = 1; ioaddr = 3; iowr = 1; din = 0;
		#5 clk = 1;
		// output byte 1
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 1; din = 8'hFF;
		#5 clk = 1;
		// SDI = 0
		repeat (256)
		begin
			#5 clk = 0; iocs = 0; ioaddr = 0; iowr = 0; din = 0; sdi = 0;	// 00
			#5 clk = 1;
		end
		// input byte
		#5 clk = 0; iocs = 1; ioaddr = 0; sdi = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 0;
		#5 clk = 1;
		// output byte 2
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 1; din = 8'hAA;
		#5 clk = 1;
		// generate data on SDI
		repeat (4)
		begin
			repeat (32)
			begin
				#5 clk = 0; iocs = 0; ioaddr = 0; iowr = 0; din = 0; sdi = 0;	// 55
				#5 clk = 1;
			end
			repeat (32)
			begin
				#5 clk = 0; iocs = 0; ioaddr = 0; iowr = 0; din = 0; sdi = 1;
				#5 clk = 1;
			end
		end
		// input byte
		#5 clk = 0; iocs = 1; ioaddr = 0; sdi = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 0;
		#5 clk = 1;
		// SS off
		#5 clk = 0; iocs = 1; ioaddr = 2; iowr = 1; din = 0;
		#5 clk = 1;
		// change address
		#5 clk = 0; iocs = 1; ioaddr = 1; iowr = 1; din = 1;
		#5 clk = 1;
		// SS on
		#5 clk = 0; iocs = 1; ioaddr = 3; iowr = 1; din = 0;
		#5 clk = 1;
		// output byte 3
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 1; din = 8'h55;
		#5 clk = 1;
		// generate data on SDI
		repeat (4)
		begin
			repeat (32)
			begin
				#5 clk = 0; iocs = 0; ioaddr = 0; iowr = 0; din = 0; sdi = 1;	// AA
				#5 clk = 1;
			end
			repeat (32)
			begin
				#5 clk = 0; iocs = 0; ioaddr = 0; iowr = 0; din = 0; sdi = 0;
				#5 clk = 1;
			end
		end
		// input byte
		#5 clk = 0; iocs = 1; ioaddr = 0; sdi = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 0;
		#5 clk = 1;
		// output byte 4
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 1; din = 8'h00;
		#5 clk = 1;
		// SDI = FF
		repeat (256)
		begin
			#5 clk = 0; iocs = 0; ioaddr = 0; iowr = 0; din = 0; sdi = 1;	// FF
			#5 clk = 1;
		end
		// SS off
		#5 clk = 0; iocs = 1; ioaddr = 2; iowr = 1; din = 0;
		#5 clk = 1;
		// input byte
		#5 clk = 0; iocs = 1; ioaddr = 0; sdi = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; ioaddr = 0; iowr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; ioaddr = 0; iowr = 0;
	end
      
endmodule


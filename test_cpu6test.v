`timescale 1ns / 10ps
//
//								test_cpu6test.v - Test DCP-6 CPU
//
//							(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-3 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
module test_cpu6test;

	// Inputs
	reg mclk;
	reg mrst;
	reg [15:0] din;

	// Outputs
	wire [7:0] ioaddr;
	wire [15:0] dout;
	wire iord;
	wire iowr;

	// Instantiate the Unit Under Test (UUT)
	cpu6test uut (
		.mclk(mclk), 
		.mrst(mrst), 
		.ioaddr(ioaddr), 
		.din(din), 
		.dout(dout), 
		.iord(iord), 
		.iowr(iowr)
	);

	initial begin
		// Initialize Inputs
		mclk = 0;
		mrst = 0;
		din = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Reset
		repeat (32)
		begin
			#6.67 mclk = 0; mrst = 1;
			#6.67 mclk = 1;
		end
		// Run
		repeat (75000000)
		begin
			#6.67 mclk = 0; mrst = 0;
			#6.67 mclk = 1;
		end
		#6.67 mclk = 0;

	end
      
endmodule


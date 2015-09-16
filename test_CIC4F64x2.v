`timescale 1ns / 1ps
//
//					Test Cascaded Integrator Comb Filter Logic
//
//					(C) Copyright 2007-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_CIC4F64x2;

	// Inputs
	reg [17:0] rdi;
	reg [17:0] tdi;
	reg ce;
	reg dclk;
	reg cclk;
	reg rst;
	reg xmt;
	reg [15:0] cin;
	reg [1:0] cwr;
	reg [17:0] rdox,rdoy,tdox,tdoy;

	// Outputs
	wire tie;
	wire [17:0] rdo;
	wire [17:0] tdo;
	wire rov;
	wire ovf;

	// Instantiate the Unit Under Test (UUT)
	CIC4F64x2 uut (
		.rdi(rdi), 
		.tdi(tdi), 
		.tie(tie), 
		.rdo(rdo), 
		.tdo(tdo), 
		.rov(rov),
		.ovf(ovf),
		.dclk(dclk), 
		.ce(ce),
		.rst(rst), 
		.xmt(xmt), 
		.cin(cin), 
		.cwr(cwr),
		.cclk(cclk)
	);
	always @ (posedge dclk) if (rov & ~ce) rdox <= rdo;
	always @ (posedge dclk) if (rov & ce) rdoy <= rdo;
	always @ (posedge dclk) if (~ce) tdox <= tdo;
	always @ (posedge dclk) if (ce) tdoy <= tdo;

	initial begin
		// Initialize Inputs
		rdi = 0;
		tdi = 0;
		ce = 0;
		dclk = 0;
		cclk = 0;
		rst = 0;
		xmt = 0;
		cin = 0;
		cwr = 0;
		rdox = 0;
		rdoy = 0;
		tdox = 0;
		tdoy = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		// register 1: bits 15-10 = gain exponent, bits 10-6 = integer gain, bits 5-0 = fractional gain
		// register 2: bit 15 = no. chan. bits 11-0 = interpolation/decimation factor - 1
		// configure to interpolate 2 channels by 16 - Gain = 2^42/2^12 = 2^30 = 4 x 2^28
		// exp=28, int=4, frac=0 => 011100 0100 000000 = 7100
		#5 cclk = 0; xmt = 1; rst = 1; cwr = 1; cin = 16'h7100;
		#5 cclk = 1;
		#5 cclk = 0; xmt = 1; rst = 1; cwr = 2; cin = 16'h800F;
		#5 cclk = 1;
		#5 cclk = 0; cwr = 0; cin = 0;
      // reset
		repeat (40)
		begin
			#5 dclk = 0; rst = 1;
			#5 dclk = 1;
		end
		#5 dclk = 0; rst = 0;
		#5 dclk = 1;
		// Test transmit path
		repeat (20)
		begin
			#5 dclk = 0; ce = 0; tdi = 0;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1;
			#5 dclk = 1; ce = 1;
		end
		repeat (80)
		begin
			#5 dclk = 0; ce = 0; tdi = 100000;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1; tdi = -100000;
			#5 dclk = 1; ce = 1;
		end
		repeat (80)
		begin
			#5 dclk = 0; ce = 0; tdi = -100000;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1; tdi = 100000;
			#5 dclk = 1; ce = 1;
		end
		repeat (80)
		begin
			#5 dclk = 0; ce = 0; tdi = 0;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1;
			#5 dclk = 1; ce = 1;
		end
		#5 dclk = 0; ce = 0;
		
		// register 1: bits 15-10 = gain exponent, bits 10-6 = integer gain, bits 5-0 = fractional gain
		// register 2: bits 11-0 = interpolation/decimation factor - 1
		// configure to decimate 2 channels by 16 - Gain = 2^46/2^16 = 2^30 = 4 x 2^28
		// exp=28, int=4, frac=0 => 011100 0100 000000 = 7100
		#5 cclk = 0; xmt = 0; rst = 1; cwr = 1; cin = 16'h7100;
		#5 cclk = 1;
		#5 cclk = 0; xmt = 0; rst = 1; cwr = 2; cin = 16'h800F;
		#5 cclk = 1;
		#5 cclk = 0; cwr = 0; cin = 0;
      // reset
		repeat (40)
		begin
			#5 dclk = 0; rst = 1;
			#5 dclk = 1;
		end
		#5 dclk = 0; rst = 0;
		#5 dclk = 1;
		// Test transmit path
		repeat (120)
		begin
			#5 dclk = 0; ce = 0; rdi = 0;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1;
			#5 dclk = 1; ce = 1;
		end
		repeat (120)
		begin
			#5 dclk = 0; ce = 0; rdi = 50000;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1; rdi = -50000;
			#5 dclk = 1; ce = 1;
		end
		repeat (120)
		begin
			#5 dclk = 0; ce = 0; rdi = -50000;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1; rdi = 50000;
			#5 dclk = 1; ce = 1;
		end
		repeat (120)
		begin
			#5 dclk = 0; ce = 0; rdi = 0;
			#5 dclk = 1; ce = 0;
			#5 dclk = 0; ce = 1;
			#5 dclk = 1; ce = 1;
		end
		#5 dclk = 0; ce = 0;
	end
      
endmodule


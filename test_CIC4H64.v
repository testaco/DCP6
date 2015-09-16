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

module test_CIC4H64;

	// Inputs
	reg [17:0] rdi;
	reg [17:0] tdix,tdiy;
	reg sclk;
	reg dclk;
	reg rst;
	reg xmt;
	reg [15:0] cin;
	reg [1:0] cwr;
	reg [17:0] x,y;
	reg [17:0] sig;

	// Outputs
	wire tie;
	wire [17:0] rdo;
	wire [17:0] tdo;
	wire rov;
	wire ovf;

	// Instantiate the Unit Under Test (UUT)
	CIC4H64 uut (
		.rdi(rdi), 
		.tdix(tdix), 
		.tdiy(tdiy), 
		.tie(tie), 
		.rdo(rdo), 
		.tdo(tdo), 
		.rov(rov),
		.ovf(ovf),
		.dclk(dclk), 
		.iq(sclk),
		.rst(rst), 
		.xmt(xmt), 
		.cin(cin), 
		.cwr(cwr)
	);
	always @ (posedge dclk) if (xmt|rov) sig <= xmt ? tdo : rdo;
	always @ (posedge sclk) if (xmt|rov) x <= sig;
	always @ (posedge sclk) if (xmt|rov) y <= xmt ? tdo : rdo;

	initial begin
		// Initialize Inputs
		rdi = 0;
		tdix = 0; tdiy = 0;
		sclk = 0;
		dclk = 0;
		rst = 0;
		xmt = 0;
		cin = 0;
		cwr = 0;
		sig = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		// register 1: bits 15-10 = gain exponent, bits 10-6 = integer gain, bits 5-0 = fractional gain
		// register 2: bits 11-0 = interpolation/decimation factor - 1
		// configure to interpolate by 16 - Gain = 2^42/2^12 = 2^30 = 4 x 2^28
		// exp=28, int=4, frac=0 => 011100 0100 000000 = 7100
		#5 dclk = 1; sclk = 1;
		#5 dclk = 0; sclk = 1;
		#5 dclk = 1; sclk = 0; xmt = 1; rst = 1; cwr = 1; cin = 16'h7100;
		#5 dclk = 0; sclk = 0;
		#5 dclk = 1; sclk = 1;
		#5 dclk = 0; sclk = 1;
		#5 dclk = 1; sclk = 0; xmt = 1; rst = 1; cwr = 2; cin = 16'h000F;
		#5 dclk = 0; sclk = 0;
      // reset
		repeat (20)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1;
			#5 dclk = 1; sclk = 0; rst = 1; cwr = 0; cin = 0;
			#5 dclk = 0; sclk = 0;
		end
		#5 dclk = 1; sclk = 1;
		#5 dclk = 0; sclk = 1;
		#5 dclk = 1; sclk = 0; rst = 0;
		#5 dclk = 0; sclk = 0;
		// Test transmit path
		repeat (20)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; tdix = 0; tdiy = 0;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0;
		end
		repeat (80)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; tdix = 100000; tdiy = -100000;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0;
		end
		repeat (80)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; tdix = -100000; tdiy = 100000;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0;
		end
		repeat (80)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; tdix = 0; tdiy = 0;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0;
		end
		
		// register 1: bits 15-10 = gain exponent, bits 10-6 = integer gain, bits 5-0 = fractional gain
		// register 2: bits 11-0 = interpolation/decimation factor - 1
		// configure to decimate by 16 - Gain = 2^46/2^16 = 2^30 = 4 x 2^28
		// exp=28, int=4, frac=0 => 011100 0100 000000 = 7100
		#5 dclk = 1; sclk = 1;
		#5 dclk = 0; sclk = 1;
		#5 dclk = 1; sclk = 0; xmt = 0; rst = 1; cwr = 1; cin = 16'h7100;
		#5 dclk = 0; sclk = 0;
		#5 dclk = 1; sclk = 1;
		#5 dclk = 0; sclk = 1;
		#5 dclk = 1; sclk = 0; xmt = 0; rst = 1; cwr = 2; cin = 16'h000F;
		#5 dclk = 0; sclk = 0;
      // reset
		repeat (20)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1;
			#5 dclk = 1; sclk = 0; rst = 1; cwr = 0; cin = 0;
			#5 dclk = 0; sclk = 0;
		end
		#5 dclk = 1; sclk = 1;
		#5 dclk = 0; sclk = 1;
		#5 dclk = 1; sclk = 0; rst = 0;
		#5 dclk = 0; sclk = 0;
		// Test receive path
		repeat (80)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; rdi = 0;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0; rdi = 0;
		end
		repeat (160)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; rdi = 50000;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0; rdi = -50000;
		end
		repeat (160)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; rdi = -50000;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0; rdi = 50000;
		end
		repeat (80)
		begin
			#5 dclk = 1; sclk = 1;
			#5 dclk = 0; sclk = 1; rdi = 0;
			#5 dclk = 1; sclk = 0;
			#5 dclk = 0; sclk = 0; rdi = 0;
		end
	end
      
endmodule


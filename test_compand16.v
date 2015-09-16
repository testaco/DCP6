`timescale 1ns / 1ps
//
//				test_compand16.v - Test Compander with 16-bit X & Y I/O	
//
//					 (C) Copyright 2008-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module test_compand16;

	// Inputs
	reg [15:0] tdix,tdiy;
	reg tiv;
	reg [15:0] rdix,rdiy;
	reg riv;
	reg clk;
	reg cmpd;
	reg xmt;

	// Outputs
	wire [15:0] tdox,tdoy;
	wire tov;
	wire [15:0] rdox,rdoy;
	wire rov;
	// Test
	reg [15:0] tx,ty,rx,ry;

	// Instantiate the Unit Under Test (UUT)
	compand16 uut (
		.tdix(tdix), 
		.tdiy(tdiy), 
		.tiv(tiv), 
		.rdix(rdix), 
		.rdiy(rdiy), 
		.riv(riv), 
		.tdox(tdox), 
		.tdoy(tdoy), 
		.tov(tov), 
		.rdox(rdox), 
		.rdoy(rdoy), 
		.rov(rov), 
		.clk(clk), 
		.cmpd(cmpd), 
		.xmt(xmt)
	);
	always @ (posedge clk)
	begin
		if (tov) tx <= tdox;
		if (tov) ty <= tdoy;
		if (rov) rx <= rdox;
		if (rov) ry <= rdoy;
	end

	initial begin
		// Initialize Inputs
		tdix = 0;
		tdiy = 0;
		tiv = 0;
		rdix = 0;
		rdiy = 0;
		riv = 0;
		clk = 0;
		cmpd = 0;
		xmt = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Idle
		repeat (36)
		begin
			#5 clk = 0; 
			#5 clk = 1;
		end
		// Test Transmitter w/o expansion
		#5 xmt = 1; cmpd = 0;
		#5 clk = 0; tiv = 1; tdix = 3000; tdiy = 4000;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 32767; tdiy = 32767;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		// Test Transmitter with expansion
		#5 xmt = 1; cmpd = 1;
		#5 clk = 0; tiv = 1; tdix = 32767; tdiy = -32767;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 32767; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 16384; tdiy = 16384;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = 16384;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -8192; tdiy = 8192;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -8192; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -4096; tdiy = -4096;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = -4096;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 2048; tdiy = -2048;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 2048; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 1024; tdiy = 1024;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = 1024;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -512; tdiy = 512;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -512; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -256; tdiy = -256;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = -256;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 128; tdiy = -128;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 128; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 64; tdiy = 64;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = 64;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -32; tdiy = 32;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -32; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -16; tdiy = -16;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = -16;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 8; tdiy = -8;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 8; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 4; tdiy = 4;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = 4;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -2; tdiy = 2;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -2; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = -1; tdiy = -1;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = -1;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 1; tdix = 0; tdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; tiv = 0;
			#5 clk = 1;
		end
		// Idle
		repeat (72)
		begin
			#5 clk = 0; 
			#5 clk = 1;
		end
		// Test Receiver w/o expansion
		#5 xmt = 0; cmpd = 0;
		#5 clk = 0; riv = 1; rdix = 3000; rdiy = 4000;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 32767; rdiy = 32767;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		// Test Receiver with expansion
		#5 xmt = 0; cmpd = 1;
		#5 clk = 0; riv = 1; rdix = 32767; rdiy = -32767;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 32767; rdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 16384; rdiy = 16384;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 0; rdiy = 16384;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = -8192; rdiy = 8192;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = -8192; rdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = -4096; rdiy = -4096;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 0; rdiy = -4096;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 2048; rdiy = -2048;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 2048; rdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 1024; rdiy = 1024;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 0; rdiy = 1024;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = -512; rdiy = 512;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = -512; rdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = -256; rdiy = -256;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 0; rdiy = -256;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 128; rdiy = -128;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 128; rdiy = 0;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 64; rdiy = 64;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = 0; rdiy = 64;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 1; rdix = -32; rdiy = 32;
		#5 clk = 1;
		repeat (35)
		begin
			#5 clk = 0; riv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; 
	end
      
endmodule


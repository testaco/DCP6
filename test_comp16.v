`timescale 1ns / 1ps
//
//			test_comp16.v - Test Compressor with 16-bit X and Y inputs	
//
//					(C) Copyright 2008-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module uses serial multipliers that require 8 clock cycles.
//
module test_comp16;

	// Inputs
	reg [15:0] dix;
	reg [15:0] diy;
	reg iv;
	reg clk;
	reg [7:0] cin;
	reg cwe;

	// Outputs
	wire [15:0] dox;
	wire [15:0] doy;
	wire ov;
	
	// Test
	reg [15:0] xout,yout,xin,yin;

	// Instantiate the Unit Under Test (UUT)
	comp16 uut (
		.dix(dix), 
		.diy(diy), 
		.iv(iv), 
		.dox(dox), 
		.doy(doy), 
		.ov(ov), 
		.clk(clk), 
		.cin(cin), 
		.cwe(cwe)
	);
	always @ (posedge clk)
	begin
		if (ov) xout <= dox;
		if (ov) yout <= doy;
	end

	initial begin
		// Initialize Inputs
		dix = 0;
		diy = 0;
		iv = 0;
		clk = 0;
		cin = 0;
		cwe = 0;
		xin = 0;
		yin = 32767;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Initialize for gain of 1
		repeat (64)
		begin
			#5 clk = 0; cwe = 1; cin = 8'h10;
			#5 clk = 1;
		end
		#5 clk = 0; cwe = 0; cin = 8'h00;
		#5 clk = 1;
		
		// transmit
		repeat (256)
		begin
			#5 clk = 0; iv = 1; dix = xin; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			xin = xin+256;
			yin = yin-256;
		end

		// Initialize for gain of 2 then 1
		repeat (32)
		begin
			#5 clk = 0; cwe = 1; cin = 8'h10;
			#5 clk = 1;
		end
		repeat (16)
		begin
			#5 clk = 0; cwe = 1; cin = 8'h20;
			#5 clk = 1;
		end
		repeat (8)
		begin
			#5 clk = 0; cwe = 1; cin = 8'h40;
			#5 clk = 1;
		end
		repeat (8)
		begin
			#5 clk = 0; cwe = 1; cin = 8'h80;
			#5 clk = 1;
		end
		#5 clk = 0; cwe = 0; cin = 0;
		#5 clk = 1;
		
		// transmit
		repeat (2)
		begin
			#5 clk = 0; iv = 1; dix = 1023; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = 1023;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = -1023; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = -1023;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 2047; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = 2047;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = -2047; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = -2047;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 4095; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = 4095;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = -4095; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = -4095;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 8191; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = 8191;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = -8191; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = -8191;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 16383; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = 16383;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = -16383; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = -16383;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 32767; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = 32767;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = -32767; diy = 0;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0; iv = 1; dix = 0; diy = -32767;
			#5 clk = 1;
			repeat (31)
			begin
				#5 clk = 0; iv = 0;
				#5 clk = 1;
			end
			#5 clk = 0;
		end
		#5 clk = 0;
	end
      
endmodule


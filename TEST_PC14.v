`timescale 1ns / 1ps
//
//					TEST_PC14 - Test 14-bit Program Control Unit
//
//					(C) Copyright 2007-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This test program exercises the PCU in the MCU16C.
//
// History:
//		2011-9-15	new for Spartan-6 version of CPU (CPU16C)
//
module TEST_PC14;

	// Inputs
	reg [15:0] pdata;
	reg [13:0] rdata;
	reg [3:0] flags;
	reg hv;
	reg [5:0] h6;
	reg ce;
	reg clk;
	reg rst;

	// Outputs
	wire [13:0] paddr;

	// Instantiate the Unit Under Test (UUT)
	PC14 uut (
		.paddr(paddr), 
		.pdata(pdata), 
		.rdata(rdata), 
		.flags(flags), 
		.hv(hv), 
		.h6(h6), 
		.ce(ce), 
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		pdata = 0;
		rdata = 0;
		flags = 1;	// always flag set
		hv = 0;
		h6 = 0;
		ce = 1;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
      // Reset
		#5 clk = 0; rst = 1;
		#5 clk = 1;
		// Test
		#5 clk = 0; pdata = 16'h4010; rst = 0;	// JMP 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h0111;	// CALL
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h0222;	// CALL
		#5 clk = 1;
		#5 clk = 0; pdata = 16'hE200;	// NOP (OR R0,R0)
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h5000;	// RET
		#5 clk = 1;
		#5 clk = 0; pdata = 16'hE200;	// NOP (OR R0,R0)
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h5000;	// RET
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h6800;	// REP 2 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'hE200;	// NOP (OR R0,R0)
		#5 clk = 1;
		#5 clk = 0; pdata = 16'hE200;	// NOP (OR R0,R0)
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h4410;	// JV 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h4610;	// JNV 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'hAD01;	// LDH 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h4610; hv = 1; h6 = 1;	// JNV 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h6400; hv = 0; h6 = 0; rdata = 16'h0333;	// STRA 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'hE200;	// NOP - required before return
		#5 clk = 1;
		#5 clk = 0; pdata = 16'h5000;	rdata = 0;	// RET 
		#5 clk = 1;
		#5 clk = 0; pdata = 16'hE200;	// NOP 
		#5 clk = 1;
		#5 clk = 0;
	end
      
endmodule


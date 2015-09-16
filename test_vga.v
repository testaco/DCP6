`timescale 1ns / 1ps
//
//						test_vga.v - Test 480 x 640 VGA Display Controller
//
//							(C) Copyright 2007-2011 John B. Stephensen
//
// This module generates a clock and writes data to the VGA memory.
//
module test_vga;

	// Inputs
	reg mcs;
	reg [12:0] maddr;
	reg [15:0] min;
	reg mwr;
	reg mclk;
	reg mrst;
	reg vclk;

	// Outputs
	wire red;
	wire grn;
	wire blu;
	wire vsync;
	wire hsync;

	// Instantiate the Unit Under Test (UUT)
	vga uut (
		.mcs(mcs), 
		.maddr(maddr), 
		.min(min), 
		.mwr(mwr), 
		.mclk(mclk), 
		.mrst(mrst), 
		.red(red), 
		.grn(grn), 
		.blu(blu), 
		.vsync(vsync), 
		.hsync(hsync), 
		.vclk(vclk)
	);

	initial begin
		// Initialize Inputs
		mcs = 0;
		maddr = 0;
		min = 0;
		mwr = 0;
		mclk = 0;
		mrst = 0;
		vclk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Write to graphic memory (third 2048 word block)
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4096; min = 200;	// mid-scale
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4097; min = 200;	// mid-scale
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4098; min = 200;	// mid-scale
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4099; min = 200;	// mid-scale
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4100; min = 300;	// down
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4101; min = 300;	// down
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4102; min = 300;	// down
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4103; min = 300;	// down
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4104; min = 100;	// up
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4105; min = 100;	// up
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4106; min = 100;	// up
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4107; min = 100;	// up
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4108; min = 200;	// center
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4109; min = 200;	// center
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4110; min = 200;	// center
		#5 mclk = 1;
		#5 mclk = 0; mcs = 1; mwr = 1;  maddr = 4111; min = 200;	// center
		#5 mclk = 1;
		#5 mclk = 0; mcs = 0; mwr = 0;  maddr = 0; min = 0;
		// display frame
		repeat (1050)
		begin
			repeat (800)
			begin
				#5 vclk = 0;
				#5 vclk = 1;
			end
		end

	end
      
endmodule


`timescale 1ns / 1ps
// 
//				test_cordic16a.v - Test 16-bit Serial CORDIC Processing Engine
// 
//					  (C) Copyright 2007-2013 John B. Stephensen
// 
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// cordic16s16 uses 24Q23 format for the Z accumulator to increase accuracy
//
module test_cordic16s16a;

	// Inputs
	reg [15:0] xi;
	reg [15:0] yi;
	reg [15:0] zi;
	reg load;
	reg mi;
	reg clk;
	reg rst;

	// Outputs
	wire [15:0] xo;
	wire [15:0] yo;
	wire [15:0] zo;
	wire rdy;
	wire mo;
	
	// Test
	reg [15:0] xout,yout,zout;

	// Instantiate the Unit Under Test (UUT)
	cordic16s16a uut (
		.xi(xi), 
		.yi(yi), 
		.zi(zi), 
		.xo(xo), 
		.yo(yo), 
		.zo(zo), 
		.load(load), 
		.mi(mi),
		.mo(mo),		
		.rdy(rdy), 
		.clk(clk), 
		.rst(rst)
	);
	always @ (posedge clk)
	begin
		if (rdy) xout <= xo;
		if (rdy) yout <= yo;
		if (rdy) zout <= zo;
	end

	initial begin
		// Initialize Inputs
		xi = 0;
		yi = 0;
		zi = 0;
		load = 0;
		mi = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// reset
		#5 clk = 0; rst = 1;
		#5 clk = 1;
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// demodulate Fs/4
		repeat (16)
		begin
			#5 clk = 0; xi = 16384; yi = 16384; zi = 0; load = 1;
			#5 clk = 1;
			repeat (20)
			begin
				#5 clk = 0; load = 0;
				#5 clk = 1;
			end
			#5 clk = 0; xi = -16384; yi = 16384; zi = 0; load = 1;
			#5 clk = 1;
			repeat (20)
			begin
				#5 clk = 0; load = 0;
				#5 clk = 1;
			end
			#5 clk = 0; xi = -16384; yi = -16384; zi = 0; load = 1;
			#5 clk = 1;
			repeat (20)
			begin
				#5 clk = 0; load = 0;
				#5 clk = 1;
			end
			#5 clk = 0; xi = 16384; yi = -16384; zi = 0; load = 1;
			#5 clk = 1;
			repeat (20)
			begin
				#5 clk = 0; load = 0;
				#5 clk = 1;
			end
		end
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// rotate by 0-360 degrees
		zi = -512; mi = 1;
		repeat (129)
		begin
			#5 clk = 0; xi = 20000; yi = 20000; zi = zi+512; load = 1; // -2dBFS
			#5 clk = 1;
			repeat (20)
			begin
				#5 clk = 0; load = 0;
				#5 clk = 1;
			end
		end
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// rotate by 0-360 degrees
		zi = -512; mi = 1;
		repeat (129)
		begin
			#5 clk = 0; xi = 200; yi = 200; zi = zi+512; load = 1; // -42dBFS
			#5 clk = 1;
			repeat (20)
			begin
				#5 clk = 0; load = 0;
				#5 clk = 1;
			end
		end
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// AM Demodulation
		zi = 0; mi = 0;
		#5 clk = 0; xi = 0; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 2929; yi = 2929; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 10000; yi = 10000; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 17071; yi = 17071; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 20000; yi = 20000; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 17071; yi = 17071; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 10000; yi = 10000; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 2929; yi = 2929; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 0; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 4142; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 14142; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 24142; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 28284; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 24142; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 14142; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 4142; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		#5 clk = 0; xi = 0; yi = 0; zi = 0; load = 1; // 
		#5 clk = 1;
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// translate 0-360 degree angles -8dBFS
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 14142; yi = 0; zi = 0; load = 1; // 0 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 10000; yi = 10000; zi = 0; load = 1; // 45 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 0; yi = 14142; zi = 0; load = 1; // 90 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -10000; yi = 10000; zi = 0; load = 1; // 135 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -14142; yi = 0; zi = 0; load = 1; // 180 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -10000; yi = -10000; zi = 0; load = 1; // 225 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 0; yi = -14142; zi = 0; load = 1; // 270 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 10000; yi = -10000; zi = 0; load = 1; // 315 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 14142; yi = 0; zi = 0; load = 1; // 360 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// translate 0-360 degree angles -28dBFS
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 1414; yi = 0; zi = 0; load = 1; // 0 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 1000; yi = 1000; zi = 0; load = 1; // 45 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 0; yi = 1414; zi = 0; load = 1; // 90 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -1000; yi = 1000; zi = 0; load = 1; // 135 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -1414; yi = 0; zi = 0; load = 1; // 180 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -1000; yi = -1000; zi = 0; load = 1; // 225 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 0; yi = -1414; zi = 0; load = 1; // 270 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 1000; yi = -1000; zi = 0; load = 1; // 315 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 1414; yi = 0; zi = 0; load = 1; // 360 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// translate 0-360 degree angles -48dBFS
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 141; yi = 0; zi = 0; load = 1; // 0 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 100; yi = 100; zi = 0; load = 1; // 45 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 0; yi = 141; zi = 0; load = 1; // 90 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -100; yi = 100; zi = 0; load = 1; // 135 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -141; yi = 0; zi = 0; load = 1; // 180 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = -100; yi = -100; zi = 0; load = 1; // 225 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 0; yi = -141; zi = 0; load = 1; // 270 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 100; yi = -100; zi = 0; load = 1; // 315 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		#3 clk = 1; mi = 0;
		#3 clk = 1; xi = 141; yi = 0; zi = 0; load = 1; // 360 degrees
		#3 clk = 0;
		#3 clk = 0;
		repeat (20)
		begin
			#3 clk = 1;
			#3 clk = 1; load = 0;
			#3 clk = 0;
			#3 clk = 0;
		end
		// idle
		repeat (20)
		begin
			#5 clk = 0; load = 0;
			#5 clk = 1;
		end
		// mix Fs/8 inputs with Fs/4 phase rotation
		repeat (2)
		begin
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = 14142; yi = 0; zi = 0; load = 1; // 0 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = 10000; yi = 10000; zi = 16384; load = 1; // 45 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end	
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = 0; yi = 14142; zi = 32768; load = 1; // 90 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = -10000; yi = 10000; zi = 49152; load = 1; // 135 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = -14142; yi = 0; zi = 0; load = 1; // 180 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = -10000; yi = -10000; zi = 16384; load = 1; // 225 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = 0; yi = -14142; zi = 32768; load = 1; // 270 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end
			#3 clk = 1; mi = 1;
			#3 clk = 1; xi = 10000; yi = -10000; zi = 49152; load = 1; // 315 degrees
			#3 clk = 0;
			#3 clk = 0;
			repeat (20)
			begin
				#3 clk = 1;
				#3 clk = 1; load = 0;
				#3 clk = 0;
				#3 clk = 0;
			end
		end
	end
      
endmodule


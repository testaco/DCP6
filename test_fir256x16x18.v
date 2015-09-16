`timescale 1ns / 1ps
//
//				test_fir256x16x18.v - Test FIR Filter Peripheral
//
//					(C) Copyright 2008-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_fir256x16x18;

	// Inputs
	reg [2:0] ioaddr;
	reg iocs;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg clk;
	reg rst;
	reg [15:0] i;

	// Outputs
	wire [15:0] dout;

	// Instantiate the Unit Under Test (UUT)
	fir256x16x18 uut (
		.ioaddr(ioaddr), 
		.iocs(iocs),
		.din(din), 
		.iowr(iowr), 
		.dout(dout), 
		.iord(iord),
		.clk(clk), 
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		ioaddr = 0;
		iocs = 0;
		din = 0;
		iowr = 0;
		iord = 0;
		clk = 0;
		rst = 0;
		i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Reset
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		repeat (16)
		begin
			#5 clk = 0; rst = 1;
			#5 clk = 1;
		end
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                             Data                              | 0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                        LSW Coefficient                        | 1
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                                                       |  MSB  | 2
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|         Taps/Phase - 1        |           Total Taps          | 3
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                                       |  Len  |     Base      | 4
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                           |     Coefficient Base Address      | 5
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                     Reset Address Counter                     | 6
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		// Set buffer length to 32 and base address to 0
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 4; din = 0;
		#5 clk = 1;
		// Set filter length to 16, 16 taps per phase for interpolation by 1
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 3; din = 16'h0F10;
		#5 clk = 1;
		// reset address counter
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0;
		#5 clk = 1;
		// Load Coefficients
		repeat (16)
		begin
			i = i + 256;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 0; // coef 0
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din <= i;
			#5 clk = 1;
		end
		#5 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// Test filter
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 16384; // write data
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 5; din = 0; // start filer
		#5 clk = 1;
		repeat (19)
		begin
			#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0; // wait
			#5 clk = 1;
		end
		#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 1; // read status
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 1;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0; // read result
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		repeat (16)
		begin
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 0; // write data
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 5; din = 0; // start filer
			#5 clk = 1;
			repeat (19)
			begin
				#5 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; // wait
				#5 clk = 1;
			end
			//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
			//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
			//		|                             Data                              | 0
			//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
			//		|OVF|                                               | F | E |RDY| 1
			//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
			#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 1; // read status
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 1;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0; // read result
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0;
			#5 clk = 1;
		end
		
		// Interpolation filter
		i = 0;
		//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                             Data                              | 0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                        LSW Coefficient                        | 1
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                                                       |  MSB  | 2
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|         Taps/Phase - 1        |           Total Taps          | 3
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                                       |  Len  |     Base      | 4
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                           |     Coefficient Base Address      | 5
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                     Reset Address Counter                     | 6
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		// Set buffer length to 32 and base address to 0
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 4; din = 16'h0000;
		#5 clk = 1;
		// Set filter length to 16, 4 taps per phase for interpolation by 4
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 3; din = 16'h0310;
		#5 clk = 1;
		// reset address counter
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0;
		#5 clk = 1;
		// Load Coefficients
		repeat (16)
		begin
			i = i + 256;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 0; // coef 0
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din <= i;
			#5 clk = 1;
		end
		#5 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// Test filter
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 16384; // write data
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 5; din = 0; // start filer
		#5 clk = 1;
		repeat (19)
		begin
			#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0; // wait
			#5 clk = 1;
		end
		//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|                             Data                              | 0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//		|OVF|                                               | F | E |RDY| 1
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 1; // read status
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 1;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0; // read results
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
		#5 clk = 1;
		repeat (16)
		begin
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 0; // write data
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 5; din = 0; // start filer
			#5 clk = 1;
			repeat (19)
			begin
				#5 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; // wait
				#5 clk = 1;
			end
			//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
			//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
			//		|                             Data                              | 0
			//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
			//		|OVF|                                               | F | E |RDY| 1
			//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
			#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 7; // read status
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 7;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0; // read results
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0;
			#5 clk = 1;
		end
		
		#5 clk = 0;

	end
      
endmodule


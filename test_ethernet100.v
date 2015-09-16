`timescale 1ns / 1ps
//
//			test_ethernet100.v - Test Full-duplex Ethernet RMII Interface
//
//						(C) Copyright 2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This version test an Ethernet port using DMA to block RAM.
//
module test_etherne100;

	// Inputs
	reg mcs0,mcs1;
	reg [9:0] maddr;
	reg mwr0;
	reg [15:0] min0;
	reg iocs;
	reg [2:0] ioaddr;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg mclk;
	reg mrst;
	reg rclk;
	reg [1:0] rxd;
	reg rxer;
	reg rxv;
	reg mint;
	reg [15:0] i;

	// Outputs
	wire [15:0] mout0,mout1;
	wire [15:0] dout;
	wire refclk;
	wire [1:0] txd;
	wire txv;
	wire mdc;
	wire rstn;

	// Bidirs 
	wire mdio;

	// Instantiate the Unit Under Test (UUT)
	ethernet100 uut (
		.mcs0(mcs0),
		.mcs1(mcs1),
		.maddr(maddr),
		.mwr0(mwr0),	// transmit
		.min0(min0),
		.mout0(mout0),
		.mout1(mout1),	// receive
		.iocs(iocs), 
		.ioaddr(ioaddr), 
		.din(din), 
		.dout(dout), 
		.iowr(iowr), 
		.iord(iord), 
		.mclk(mclk), 
		.mrst(mrst), 
		.rxd(txd), 
		.rxv(txv), 
		.txd(txd), 
		.txv(txv),
		.rclk(mclk),
		.refclk(refclk), 
		.mdc(mdc), 
		.mdio(mdio), 
		.mint(mint),
		.rstn(rstn)
	);

	initial begin
		// Initialize Inputs
		mcs0 = 0;
		mcs1 = 0;
		maddr = 0;
		min0 = 0;
		mwr0 = 0;
		iocs = 0;
		ioaddr = 0;
		din = 0;
		iowr = 0;
		iord = 0;
		mclk = 0;
		mrst = 0;
		rxd = 0;
		rxer = 0;
		rxv = 0;
		rclk = 0;
		mint = 0;
		i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Reset
		repeat (16)
		begin
			#5 mclk = 0; mrst = 0;
			#5 mclk = 1;
		end
		repeat (16)
		begin
			#5 mclk = 0; mrst = 1;
			#5 mclk = 1;
		end
		repeat (16)
		begin
			#5 mclk = 0; mrst = 0;
			#5 mclk = 1;
		end
		
		// enable PHY
		#5 mclk = 0; iocs = 1; iowr = 1; ioaddr = 3; din = 1;
		#5 mclk = 1;
		#5 mclk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 mclk = 1;
		
	// send and receive 5 frames
	repeat (2)
	begin
		repeat (5)
		begin
			// Write frame to memory
			#5 mclk = 0; mcs0 = 1; mwr0 = 1; maddr = 0; min0 = 16'h5555; // Preamble
			#5 mclk = 1;
			#5 mclk = 0; mcs0 = 1; mwr0 = 1; maddr = 1; min0 = 16'h5555; // Preamble
			#5 mclk = 1;
			#5 mclk = 0; mcs0 = 1; mwr0 = 1; maddr = 2; min0 = 16'h5555; // Preamble
			#5 mclk = 1;
			#5 mclk = 0; mcs0 = 1; mwr0 = 1; maddr = 3; min0 = 16'h55D5; // Start
			#5 mclk = 1;
			maddr = 4;
			repeat (8)
			begin
				#5 mclk = 0; mcs0 = 1; mwr0 = 1; min0 = 256*(i+1)+i; // Data
				#5 mclk = 1;
				maddr = maddr + 1; i = i + 2;
			end
			#5 mclk = 0; mcs0 = 0; mwr0 = 0; maddr = 0; min0 = 0;
			// sync DCM
			repeat (8)
			begin
				#5 mclk = 0;
				#5 mclk = 1;
				#5 mclk = 0;
				#5 mclk = 1;
			end
			// start transmission
			#5 mclk = 0; iocs = 1; iowr = 1; ioaddr = 1; din = 24;
			#5 mclk = 1;
			#5 mclk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
			#5 mclk = 1;
			// transmit frame - 96 dibits
			repeat (100)
			begin
				#5 mclk = 0;
				#5 mclk = 1;
				#5 mclk = 0;
				#5 mclk = 1;
			end
			// received frame size and flags must move across clock boundaries
			repeat (5)
			begin
				#5 mclk = 0;
				#5 mclk = 1;
				#5 mclk = 0;
				#5 mclk = 1;
			end
		end
		repeat (5)
		begin
			// read received words
			#5 mclk = 0; iocs = 1; iowr = 0; iord = 1; ioaddr = 0; // read status
			#5 mclk = 1;
			#5 mclk = 0; iocs = 0; iowr = 0; iord = 0; ioaddr = 0; // idle
			#5 mclk = 1;
			// propogate MSB of memory address
			#5 mclk = 0; mcs1 = 0;
			#5 mclk = 1;
			maddr = 0;
			repeat (8)
			begin
				#5 mclk = 0; mcs1 = 1; // read data
				#5 mclk = 1;
				#5 mclk = 0; mcs1 = 0;
				#5 mclk = 1;
				maddr = maddr + 1;
			end
			#5 mclk = 0; iocs = 1; iowr = 1; iord = 0; ioaddr = 0; // release buffer
			#5 mclk = 1;
			#5 mclk = 0; iocs = 0; iowr = 0; iord = 0; ioaddr = 0;
			#5 mclk = 1;
			// received frame flags must move across clock boundaries
			repeat (5)
			begin
				#5 mclk = 0; iocs = 0; iowr = 0; iord = 0; ioaddr = 0;
				#5 mclk = 1;
				#5 mclk = 0;
				#5 mclk = 1;
			end
		end
	end
	#5 mclk = 0;
	end
    
endmodule


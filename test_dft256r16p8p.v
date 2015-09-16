`timescale 1ns / 1ps
//
//	test_dft256r16p8p.v - 32-256 point FFT/IFFT with Buffer and Control Logic
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_dft256r16p8p;

	// Inputs
	reg iocs;
	reg [2:0] ioaddr;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg trst,refsym;
	reg [3:0] tmag,tphs;
	reg tiv;
	reg toe;
	reg [15:0] rdix;
	reg [15:0] rdiy;
	reg riv;
	reg roe;
	reg clk;
	reg rst;
	reg xmt;
	reg sof;
	reg sync;
	reg dcd;

	// Outputs
	wire [15:0] dout;
	wire [15:0] tdox;
	wire [15:0] tdoy;
	wire tov;
	wire ten;
	wire rrst,rov,reof;
	wire [7:0] rphs;
	wire intr;

	// Instantiate the Unit Under Test (UUT)
	dft256r16p8p uut (
		.iocs(iocs), 
		.ioaddr(ioaddr), 
		.din(din), 
		.iowr(iowr),
		.dout(dout),
		.iord(iord),
		.trst(trst),
		.refsym(refsym), 
		.tmag(tmag),
		.tphs(tphs), 
		.tiv(tiv), 
		.toe(toe), 
		.tdox(tdox), 
		.tdoy(tdoy),		
		.tov(tov),
		.ten(ten),
		.rdix(rdix), 
		.rdiy(rdiy), 
		.riv(riv),
		.rrst(rrst),
		.roe(roe),
		.rphs(rphs),
		.rov(rov),
		.reof(reof),
		.clk(clk), 
		.rst(rst), 
		.xmt(xmt), 
		.sof(sof),
		.sync(sync),
		.dcd(dcd),
		.intr(intr)
	);

	initial begin
		// Initialize Inputs
		iocs = 0;
		ioaddr = 0;
		din = 0;
		iowr = 0;
		iord = 0;
		trst = 0;
		refsym = 0;
		tmag = 0;
		tphs = 0;
		tiv = 0;
		toe = 0;
		rdix = 0;
		rdiy = 0;
		riv = 0;
		roe = 0;
		clk = 0;
		rst = 0;
		xmt = 0;
		sof = 0;
		sync = 0;
		dcd = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Reset
		repeat (16)
		begin
			#5 clk = 0; rst = 1; xmt = 1;
			#5 clk = 1;
		end
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		// Configure for IFFT
		//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  0 |FWD|                                       | 0 |    FFT Size   | (Resets FFT engine)
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  1 |   |         CP Length         |         FFT Length - 1        |
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                                               |SYN|SOF|RST|RUN|
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  3 |                                                               | Transmit Symbol
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  4 |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   | Scaling Factors (0-3 right shifts)
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 5 |                               |       Offset Increment        | Filter Bank Offset
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 0; din = 16'h0005; // 32-point inverse FFT
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 1; din = 16'h081F; // 8 sample prefix, 32 sample FFT
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 16'h0001; // 1 shift per iteration
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 5; din = 16'h0000; // no offset
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// load memory with AM signal
		#5 clk = 0; trst = 1;
		#5 clk = 1;
		#5 clk = 0; trst = 0;
		#5 clk = 1;
		#5 clk = 0; tiv = 1; refsym = 1; tmag = 15; tphs = 0;	// carrier
		#5 clk = 1;
		#5 clk = 0; tiv = 1; refsym = 1; tmag = 13; tphs = 0;	// LSB
		#5 clk = 1;
		#5 clk = 0; tiv = 1; refsym = 1; tmag = 13; tphs = 0;	// USB
		#5 clk = 1;
		repeat (29)
		begin
			#5 clk = 0; tiv = 1; refsym = 1; tmag = 0; tphs = 0;	// unused
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 0; refsym = 0; tmag = 0; tphs = 0;
		#5 clk = 1;
		// Start IFFT sequence
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0001; // start IFFT
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// wait for IFFT load
		repeat (40)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read status flags
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		// load memory with DSB signal
		#5 clk = 0; trst = 1;
		#5 clk = 1;
		#5 clk = 0; trst = 0;
		#5 clk = 1;
		#5 clk = 0; tiv = 1; refsym = 1; tmag = 0; tphs = 0;	// no carrier
		#5 clk = 1;
		#5 clk = 0; tiv = 1; refsym = 1; tmag = 14; tphs = 0;	// LSB
		#5 clk = 1;
		#5 clk = 0; tiv = 1; refsym = 1; tmag = 14; tphs = 0;	// USB
		#5 clk = 1;
		repeat (29)
		begin
			#5 clk = 0; tiv = 1; refsym = 1; tmag = 0; tphs = 0;	// unused
			#5 clk = 1;
		end
		#5 clk = 0; tiv = 0; refsym = 0; tmag = 0; tphs = 0;
		#5 clk = 1;
		// Run IFFT
		repeat (240)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read status flags
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		// Output buffer
		repeat (84)
		begin
			#5 clk = 0; toe = 1;
			#5 clk = 1;
			repeat (7)
			begin
				#5 clk = 0; toe = 0;
				#5 clk = 1;
			end
		end
		#5 clk = 0;
        
		// Reset
		repeat (16)
		begin
			#5 clk = 0; rst = 1; xmt = 0;
			#5 clk = 1;
		end
		#5 clk = 0; rst = 0;
		#5 clk = 1;
		// Configure for FFT
		//	    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  0 |FWD|                                       | 0 |    FFT Size   | (Resets FFT engine)
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  1 |   |         CP Length         |         FFT Length - 1        |
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                                               |SYN|SOF|   |RUN|
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  3 |                                                               |
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  4 |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   | Scaling Factors (0-3 right shifts)
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 5 |                               |       Offset Increment        | Filter Bank Offset
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 0; din = 16'h8005; // 32-point FFT
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 1; din = 16'h081F; // 8 sample prefix, 32 sample FFT
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 16'h5555; // 1 shift per iteration
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 5; din = 16'h0000; // no offset
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0001; // start
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// load buffer with 5 cycle maximum amplitude sine wave
		repeat (4)
		begin
			#5 clk = 0; riv = 1; rdix = 5000; rdiy = -5000; dcd = 1;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 7071; rdiy = 0;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 5000; rdiy = 5000;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = 7071;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -5000; rdiy = 5000;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -7071; rdiy = 0;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -5000; rdiy = -5000;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = -7071;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 0; rdix = 0; rdiy = 0;
		#5 clk = 1;
		// let FFT execute
		repeat (240)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read status flags
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		// read RAM
		repeat (32)
		begin
			#5 clk = 0; roe = 1;
			#5 clk = 1;
		end
		#5 clk = 0; roe = 0;
		#5 clk = 1;
		// load buffer with 5 cycle maximum amplitude sine wave
		repeat (5)
		begin
			#5 clk = 0; riv = 1; rdix = 7071; rdiy = 0;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 5000; rdiy = 5000;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = 7071;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -5000; rdiy = 5000;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -7071; rdiy = 0;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -5000; rdiy = -5000;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = -7071;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 5000; rdiy = -5000;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 0; rdix = 0; rdiy = 0;
		#5 clk = 1;
		// let FFT execute
		repeat (240)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read status flags
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		// read RAM
		repeat (32)
		begin
			#5 clk = 0; roe = 1;
			#5 clk = 1;
		end
		#5 clk = 0; roe = 0;
		#5 clk = 1;
		// load buffer with 5 cycle low amplitude sine wave
		repeat (5)
		begin
			#5 clk = 0; riv = 1; rdix = 50; rdiy = 50;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = 71;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -50; rdiy = 50;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -71; rdiy = 0;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -50; rdiy = -50;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = -71;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 50; rdiy = -50;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 71; rdiy = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 0; rdix = 0; rdiy = 0;
		#5 clk = 1;
		// let FFT execute
		repeat (240)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read status flags
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		// read RAM
		repeat (32)
		begin
			#5 clk = 0; roe = 1;
			#5 clk = 1;
		end
		#5 clk = 0; roe = 0;
		#5 clk = 1;
		// load buffer with 5 cycle low amplitude sine wave
		repeat (5)
		begin
			#5 clk = 0; riv = 1; rdix = 71; rdiy = 0;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 50; rdiy = 50;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = 71;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -50; rdiy = 50;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -71; rdiy = 0;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = -50; rdiy = -50;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 0; rdiy = -71;
			#5 clk = 1;
			#5 clk = 0; riv = 1; rdix = 50; rdiy = -50;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 0; rdix = 0; rdiy = 0;
		#5 clk = 1;
		// let FFT execute
		repeat (240)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read status flags
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		// read RAM
		repeat (32)
		begin
			#5 clk = 0; roe = 1;
			#5 clk = 1;
		end
		#5 clk = 0; roe = 0;
		#5 clk = 1;
		// load buffer with zero amplitude waveform
		repeat (40)
		begin
			#5 clk = 0; riv = 1; rdix = 0; rdiy = 0; dcd = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 0; rdix = 0; rdiy = 0;
		#5 clk = 1;
		// let FFT execute
		repeat (240)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read status flags
		#5 clk = 0; iocs = 1; iord = 1; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iord = 0; ioaddr = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iord = 0; ioaddr = 0;
		#5 clk = 1;
		// read RAM
		repeat (32)
		begin
			#5 clk = 0; roe = 1;
			#5 clk = 1;
		end
		#5 clk = 0; roe = 0;
		#5 clk = 1;
		#5 clk = 0;
	end
      
endmodule


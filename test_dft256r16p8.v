`timescale 1ns / 1ps
//
//	test_dft256r16p8.v - 32-256 point FFT/IFFT with Buffer and Control Logic
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_dft256r16p8;

	// Inputs
	reg iocs;
	reg [2:0] ioaddr;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg mcs;
	reg [7:0] maddr;
	reg [15:0] min;
	reg mwr;
	reg toe;
	reg [15:0] rdix;
	reg [15:0] rdiy;
	reg riv;
	reg clk;
	reg rst;
	reg xmt;
	reg sof;
	reg sync;
	reg dcd;

	// Outputs
	wire [15:0] dout;
	wire [15:0] mout;
	wire [15:0] tdox;
	wire [15:0] tdoy;
	wire tov;
	wire ten;
	wire intr;

	// Instantiate the Unit Under Test (UUT)
	dft256r16p8 uut (
		.iocs(iocs), 
		.ioaddr(ioaddr), 
		.din(din), 
		.iowr(iowr),
		.dout(dout),
		.iord(iord),
		.mcs(mcs),
		.maddr(maddr), 
		.min(min),
		.mout(mout), 
		.mwr(mwr), 
		.toe(toe), 
		.tdox(tdox), 
		.tdoy(tdoy),		
		.tov(tov),
		.ten(ten),
		.rdix(rdix), 
		.rdiy(rdiy), 
		.riv(riv), 
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
		mcs = 0;
		maddr = 0;
		min = 0;
		mwr = 0;
		toe = 0;
		rdix = 0;
		rdiy = 0;
		riv = 0;
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
		//  3 |                                                           |REF| Transmit Symbol
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
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0002; // reset FIFO
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// load memory with AM signal
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 112; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 113; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 114; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 115; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 116; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 117; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 118; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 119; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 120; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 121; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 122; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 123; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 124; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 125; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 126; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 127; min = 16'h8000;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 128; min = 16'hC000; // pilot carrier at +6 dBsc
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 129; min = 16'h8000;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 130; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 131; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 132; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 133; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 134; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 135; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 136; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 137; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 138; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 139; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 140; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 141; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 142; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 143; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 0; mwr = 0; maddr = 0; min = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 3; din = 16'h0001; // load FIFO with reference symbol
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// load memory with AM signal
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 112; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 113; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 114; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 115; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 116; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 117; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 118; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 119; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 120; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 121; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 122; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 123; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 124; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 125; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 126; min = 16'h8040;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 127; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 128; min = 16'hC040; // pilot carrier at +6 dBsc
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 129; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 130; min = 16'h8040;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 131; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 132; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 133; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 134; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 135; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 136; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 137; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 138; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 139; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 140; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 141; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 142; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 143; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 0; mwr = 0; maddr = 0; min = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 3; din = 16'h0000; // load FIFO
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// load memory with AM signal
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 112; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 113; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 114; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 115; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 116; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 117; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 118; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 119; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 120; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 121; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 122; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 123; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 124; min = 16'h8080;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 125; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 126; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 127; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 128; min = 16'hC040; // pilot carrier at +6 dBsc
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 129; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 130; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 131; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 132; min = 16'h8080;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 133; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 134; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 135; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 136; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 137; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 138; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 139; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 140; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 141; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 142; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 143; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 0; mwr = 0; maddr = 0; min = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 3; din = 16'h0000; // load FIFO
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		// load memory with AM signal
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 112; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 113; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 114; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 115; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 116; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 117; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 118; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 119; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 120; min = 16'h80C0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 121; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 122; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 123; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 124; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 125; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 126; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 127; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 128; min = 16'hC040; // pilot carrier at +6 dBsc
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 129; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 130; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 131; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 132; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 133; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 134; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 135; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 136; min = 16'h80C0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 137; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 138; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 139; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 140; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 141; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 142; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 1; mwr = 1; maddr = 143; min = 0;
		#5 clk = 1;
		#5 clk = 0; mcs = 0; mwr = 0; maddr = 0; min = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 3; din = 16'h0000; // load FIFO
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		repeat (40)
		begin
			#5 clk = 0; toe = 1;
			#5 clk = 1;
			repeat (15)
			begin
				#5 clk = 0; toe = 0;
				#5 clk = 1;
			end
		end
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0001; // start transmission
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		repeat (200)
		begin
			#5 clk = 0; toe = 1;
			#5 clk = 1;
			repeat (15)
			begin
				#5 clk = 0; toe = 0;
				#5 clk = 1;
			end
		end
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0000; // end transmission
		#5 clk = 1;
		#5 clk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
		#5 clk = 1;
		repeat (40)
		begin
			#5 clk = 0; toe = 1;
			#5 clk = 1;
			repeat (15)
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
		//  3 |                                                           |REF| Transmit Symbol
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  4 |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   | Scaling Factors (0-3 right shifts)
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 5 |                               |       Offset Increment        | Filter Bank Offset
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 0; din = 16'h8005; // 32-point FFT
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 1; din = 16'h081F; // 8 sample prefix, 32 sample FFT
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 3; din = 16'h0001; // reference symbol
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 4; din = 16'h5555; // 1 shift per iteration
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 5; din = 16'h0000; // no offset
		#5 clk = 1;
		#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 2; din = 16'h0003; // start
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
		repeat (400)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
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
		repeat (400)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
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
		repeat (400)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
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
		repeat (400)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read FIFO
		repeat (4)
		begin
			maddr = 111;	// just below lowest subcarrier
			repeat (32)
			begin
				#5 clk = 0; mcs = 1; maddr = maddr+1;
				#5 clk = 1;
				#5 clk = 0;
				#5 clk = 1;
			end
			#5 clk = 0; mcs = 0; maddr = 0;
			#5 clk = 1;
			#5 clk = 0; iocs = 1; iowr = 1; ioaddr = 3;	// discard entry
			#5 clk = 1;
			#5 clk = 0; iocs = 0; ioaddr = 0;
			#5 clk = 1;
		end
		// load buffer with zero amplitude waveform
		repeat (40)
		begin
			#5 clk = 0; riv = 1; rdix = 0; rdiy = 0; dcd = 0;
			#5 clk = 1;
		end
		#5 clk = 0; riv = 0; rdix = 0; rdiy = 0;
		#5 clk = 1;
		// let FFT execute
		repeat (400)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
		// read memory
		maddr = 111;
		repeat (32)
		begin
			#5 clk = 0; mcs = 1; maddr = maddr+1;
			#5 clk = 1;
			#5 clk = 0;
			#5 clk = 1;
		end
		#5 clk = 0; mcs = 0; maddr = 0;
		#5 clk = 1;
		#5 clk = 0;
	end
      
endmodule


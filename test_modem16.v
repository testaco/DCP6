`timescale 1ns / 1ps
//
//				 test_modem16.v - Test Modulator and Demodulator	
//
//					(C) Copyright 2004-2009 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
// 

module test_modem16;

	// Inputs
	reg iocs;
	reg [2:0] ioaddr;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg [15:0] rdix;
	reg [15:0] rdiy;
	reg riv;
	reg toe;
	reg clk;
	reg rst;

	// Outputs
	wire [15:0] dout;
	wire [15:0] tdox;
	wire [15:0] tdoy;
	wire tov;
	wire xmt;
	
	// Test
	reg [15:0] xout,yout;
	wire [15:0] x,y;
	wire xyv;
	wire [15:0] m;
	wire [11:0] p;
	wire mpv;

	// Instantiate the Unit Under Test (UUT)
	modem16 uut (
		.iocs(iocs), 		// CPU interface
		.ioaddr(ioaddr), 
		.din(din), 
		.dout(dout), 
		.iowr(iowr), 
		.iord(iord), 
		.rdix(rdix), 		// receiver input
		.rdiy(rdiy), 
		.riv(riv), 
		.toe(toe), 			// transmitter output
		.tdox(tdox), 
		.tdoy(tdoy), 
		.tov(tov), 
		.x(x),				// test signals
		.y(y),
		.xyv(xyv),
		.m(m),
		.p(p),
		.mpv(mpv),
		.clk(clk), 
		.rst(rst), 
		.xmtout(xmt) 
	);
	always @ (posedge clk)
	begin
		if (tov) xout <= tdox;
		if (tov) yout <= tdoy;
	end

	initial begin
		// Initialize Inputs
		iocs = 0;
		ioaddr = 0;
		din = 0;
		iowr = 0;
		iord = 0;
		rdix = 0;
		rdiy = 0;
		riv = 0;
		toe = 0;
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Test receiving SSB (CORDIC rotate mode with BFO=0)
		#8 clk = 0; rst = 1;
		#8 clk = 1;
		#8 clk = 0; rst = 0;
		#8 clk = 1;
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                               |  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 16'h0002; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  6 |                         BFO Frequency                         | BFO
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  7 |                                                   |INI|RST|XMT| Command
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 7; din = 16'h0002; // 
		#8 clk = 1;
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
		// generate signal
		#8 clk = 0; riv = 1; rdix = 16384; rdiy = 16384;
		#8 clk = 1;
		repeat (39)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		#8 clk = 0; riv = 1; rdix = -16384; rdiy = 16384;
		#8 clk = 1;
		repeat (39)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		#8 clk = 0; riv = 1; rdix = -16384; rdiy = -16384;
		#8 clk = 1;
		repeat (39)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		#8 clk = 0; riv = 1; rdix = 16384; rdiy = -16384;
		#8 clk = 1;
		repeat (39)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		// read FIFO
		repeat (4)
		begin
			#8 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 1; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 1; din = 0;
			#8 clk = 1;
		end
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
        
		// Test receiving PM
		#8 clk = 0; rst = 1;
		#8 clk = 1;
		#8 clk = 0; rst = 0;
		#8 clk = 1;
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                               |  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 16'h0000; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  6 |                         BFO Frequency                         | BFO
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  7 |                                                   |INI|RST|XMT| Command
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 7; din = 16'h0002; // 
		#8 clk = 1;
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
		// generate signal
		#8 clk = 0; riv = 1; rdix = 10000; rdiy = 0;
		#8 clk = 1;
		repeat (35)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		#8 clk = 0; riv = 1; rdix = 0; rdiy = 10000;
		#8 clk = 1;
		repeat (35)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		#8 clk = 0; riv = 1; rdix = -10000; rdiy = 0;
		#8 clk = 1;
		repeat (35)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		#8 clk = 0; riv = 1; rdix = 0; rdiy = -10000;
		#8 clk = 1;
		repeat (35)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
		// read FIFO
		repeat (4)
		begin
			#8 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 1; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 1; din = 0;
			#8 clk = 1;
		end
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
        
		// Test receiving FM
		#8 clk = 0; rst = 1;
		#8 clk = 1;
		#8 clk = 0; rst = 0;
		#8 clk = 1;
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                               |  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 16'h0001; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  6 |                         BFO Frequency                         | BFO
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  7 |                                                   |INI|RST|XMT| Command
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 7; din = 16'h0002; // 
		#8 clk = 1;
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
		// generate signal
		repeat (40) dc(0);
		repeat (160) dc(8192);	// full carrier
		repeat (40) dc(0);		// null
		repeat (160) fs8(8192);	// ref+data
		repeat (40) dc(0);
		// read FIFO
		repeat (4)
		begin
			#8 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 1; iowr = 0; ioaddr = 1; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 0; ioaddr = 1; din = 0;
			#8 clk = 1;
		end
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
        
		// Test transmitting SSB
		#8 clk = 0; rst = 1;
		#8 clk = 1;
		#8 clk = 0; rst = 0;
		#8 clk = 1;
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                               |  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 16'h0002; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  6 |                         BFO Frequency                         | BFO
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  7 |                                                   |INI|RST|XMT| Command
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 7; din = 16'h0003; // 
		#8 clk = 1;
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
		// load FIFO
		repeat (2)
		begin
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 32767;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = -32767;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = -32767;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 32767;
			#8 clk = 1;
		end
		// Let FIFO empty
		repeat (16)
		begin
			#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 1;
			#8 clk = 1;
			repeat (35)
			begin
				#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 0;
				#8 clk = 1;
			end
		end

		// Test transmitting PM
		#8 clk = 0; rst = 1; toe = 0;
		#8 clk = 1;
		#8 clk = 0; rst = 0;
		#8 clk = 1;
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                               |  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 16'h0000; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  6 |                         BFO Frequency                         | BFO
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  7 |                                                   |INI|RST|XMT| Command
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 7; din = 16'h0003; // 
		#8 clk = 1;
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
		// load FIFO
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 16'h7FFF; // full amplitude
		#8 clk = 1;
		repeat (2)
		begin
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 16384;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 32768;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 49152;
			#8 clk = 1;
		end
		// Let FIFO empty
		repeat (16)
		begin
			#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 1;
			#8 clk = 1;
			repeat (35)
			begin
				#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 0;
				#8 clk = 1;
			end
		end

		// Test transmitting FM
		#8 clk = 0; rst = 1; toe = 0;
		#8 clk = 1;
		#8 clk = 0; rst = 0;
		#8 clk = 1;
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                               |  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 16'h0001; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  6 |                         BFO Frequency                         | BFO
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 0; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  7 |                                                   |INI|RST|XMT| Command
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 7; din = 16'h0003; // 
		#8 clk = 1;
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
		// load FIFO
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 16'h7FFF; // full amplitude
		#8 clk = 1;
		repeat (4)
		begin
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 16384;
			#8 clk = 1;
		end
		repeat (4)
		begin
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 0;
			#8 clk = 1;
		end
		repeat (4)
		begin
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = -16384;
			#8 clk = 1;
		end
		// Let FIFO empty
		repeat (16)
		begin
			#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 1;
			#8 clk = 1;
			repeat (35)
			begin
				#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 0;
				#8 clk = 1;
			end
		end
        
		// Test SSB Transmission with 1 kHz sine wave and 1.5 kHz BFO
		#8 clk = 0; rst = 1;
		#8 clk = 1;
		#8 clk = 0; rst = 0;
		#8 clk = 1;
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |                               |  FM Delay - 1 |CRE|TRE|SSB|FM | Modem Config.
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 2; din = 16'h0002; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  6 |                         BFO Frequency                         | BFO
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 6; din = 16'h3000; // 
		#8 clk = 1;
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  7 |                                                   |INI|RST|XMT| Command
		//    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 7; din = 16'h0003; // 
		#8 clk = 1;
		#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0;
		#8 clk = 1;
		// load FIFO
		repeat (2)
		begin
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 14142;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 10000;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 10000;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 14142;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = -10000;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 10000;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = -14142;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = -10000;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = -10000;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 0;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = -14142;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 0; din = 10000;
			#8 clk = 1;
			#8 clk = 0; iocs = 1; iord = 0; iowr = 1; ioaddr = 1; din = -10000;
			#8 clk = 1;
		end
		// Let FIFO empty
		repeat (32)
		begin
			#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 1;
			#8 clk = 1;
			repeat (35)
			begin
				#8 clk = 0; iocs = 0; iord = 0; iowr = 0; ioaddr = 0; din = 0; toe = 0;
				#8 clk = 1;
			end
		end
	end
	
	// receive DC
	task dc;
	input signed [15:0] m;
	begin
		rcv(m,0);
		rcv(m,0);
		rcv(m,0);
		rcv(m,0);
		rcv(m,0);
		rcv(m,0);
		rcv(m,0);
		rcv(m,0);
	end
	endtask
	
	// receive Fs/8
	task fs8;
	input signed [15:0] m;
	begin
		rcv(m,0);
		rcv(m*0.7071,m*0.7071);
		rcv(0,m);
		rcv(-m*0.7071,m*0.7071);
		rcv(-m,0);
		rcv(-m*0.7071,-m*0.7071);
		rcv(0,-m);
		rcv(m*0.7071,-m*0.7071);
	end
	endtask
	
	// receive data
	task rcv;
	input signed [15:0] x,y;
	begin
		#8 clk = 0; riv = 1; rdix = x; rdiy = y;
		#8 clk = 1;
		repeat (39)
		begin
			#8 clk = 0; riv = 0;
			#8 clk = 1;
		end
	end
	endtask
      
endmodule


`timescale 1ns / 1ps
// 
//				test_tuner1fir.v - Test DDC/DUC, DDS, CIC and FIR LPF
//
//					(C) Copyright 2006-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//

module test_tuner1fir;

	// Inputs
	reg iocs;
	reg [2:0] ioaddr;
	reg [15:0] din;
	reg iowr;
	reg iord;
	reg mclk;
	reg mrst;
	reg [15:0] adc;
	reg ovf;
	reg sclk;
	reg dclk;
	reg [15:0] dix;
	reg [15:0] diy;
	reg iv;
	reg xmt;

	// Outputs
	wire [15:0] dout;
	wire [15:0] dac;
	wire rfd;
	wire [19:0] dox;
	wire [19:0] doy;
	wire ov;

	// Instantiate the Unit Under Test (UUT)
	tuner1fir uut (
		.iocs(iocs),
		.ioaddr(ioaddr),
		.din(din),
		.iowr(iowr),
		.dout(dout),
		.iord(iord),
		.mclk(sclk),
		.mrst(mrst), 
		.adc(adc),
		.ovf(ovf),		
		.dac(dac), 
		.sclk(sclk), 
		.dclk(dclk),
//		.iq(sclk),
		.rfd(rfd),		
		.dix(dix), 
		.diy(diy), 
		.iv(iv), 
		.dox(dox), 
		.doy(doy), 
		.ov(ov), 
		.xmt(xmt) 
	);

	initial begin
		// Initialize Inputs
		iocs = 0;
		ioaddr = 0;
		din = 0;
		iowr = 0;
		iord = 0;
		mclk = 0;
		mrst = 0;
		adc = 32768;
		ovf = 0;
		sclk = 0;
		dclk = 0;
		dix = 0;
		diy = 0;
		iv = 0;
		xmt = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		// Reset
		repeat (16)
		begin
			#5 sclk = 0; dclk = 0; mrst = 1;
			#5 sclk = 1; dclk = 1;
			#5 sclk = 1; dclk = 0;
			#5 sclk = 0; dclk = 1;
		end
		repeat (16)
		begin
			#5 sclk = 0; dclk = 0; mrst = 0;
			#5 sclk = 1; dclk = 1;
			#5 sclk = 1; dclk = 0;
			#5 sclk = 0; dclk = 1;
		end
		
	repeat (2)
	begin	
		// Set Frequency and Decimation for Receiving at 1 Mbps
		//
		//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 0 |                         LSW Frequency                         | 2^32 * F/80M
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 1 |                         MSW Frequency                         |
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |       Exponent        |    Integer    |       Fraction        | CIC Gain
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 3 |               |               CIC Decimation - 1              |
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  4 |   |       Blanker Threshold       |                           |
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 5 |     FIR Decimation    |       Number of Coefficients - 2      | (reset)
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 6 |                           |          1/4 Instruction          | Load FIR
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 7 |                                                           |RST| 
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//
		setreg(0,16'h3333);
		setreg(1,16'h1F33);	// frequency = 9.75 MHz
//		setreg(0,16'hCCCD);
//		setreg(1,16'h20CC);	// frequency = 10.25 MHz
		setreg(2,16'h70FD);	// CIC gain (3.960 x 2^28)
		setreg(3,16'h000F);	// CIC decimation (16)
//		setreg(4,16'h7FFF);	// blanker threshold
		setreg(5,16'h1477);	// FIR decimation and length (5,121)
		//
		// Load FIR filter coefficients
		//
		//	 35 34 33 32 31            0
		// +--+--+--+--+---------------+
		//	|WR|LD|SK|  |  COEFFICIENT  |
		//	+--+--+--+--+---------------+
		//
		setreg(7,1);			// reset address
		load(0,1,0,103);	// 0
		load(0,0,0,540);
		load(0,0,0,1804);
		load(0,0,0,4687);
		load(0,0,0,10228);
		load(0,0,0,19445);
		load(0,0,0,32841);
		load(0,0,0,49704);
		load(0,0,0,67405);
		load(0,0,0,80978);
		load(0,0,0,83360);
		load(0,0,0,66574);
		load(0,0,0,23917);
		load(0,0,0,-47175);
		load(0,0,0,-142342);
		load(0,0,0,-248650);
		load(0,0,0,-345175);
		load(0,0,0,-406493);
		load(0,0,0,-408946);
		load(0,0,0,-338469);
		load(0,0,0,-197775);
		load(0,0,0,-10227);
		load(0,0,0,181968);
		load(0,0,0,326235);
		load(0,0,0,373719);
		load(0,0,0,295645);
		load(0,0,0,96929);
		load(0,0,0,-178293);
		load(0,0,0,-452995);
		load(0,0,0,-635973);
		load(0,0,0,-649257);
		load(0,0,0,-456676);
		load(0,0,0,-84030);
		load(0,0,0,377773);
		load(0,0,0,791075);
		load(0,0,0,1009215);
		load(0,0,0,924473);
		load(0,0,0,511702);
		load(0,0,0,-148032);
		load(0,0,0,-875522);
		load(0,0,0,-1436169);
		load(0,0,0,-1609167);
		load(0,0,0,-1264453);
		load(0,0,0,-423025);
		load(0,0,0,722316);
		load(0,0,0,1839451);
		load(0,0,0,2541019);
		load(0,0,0,2501598);
		load(0,0,0,1576100);
		load(0,0,0,-117459);
		load(0,0,0,-2181620);
		load(0,0,0,-4004041);
		load(0,0,0,-4894743);
		load(0,0,0,-4265203);
		load(0,0,0,-1802942);
		load(0,0,0,2407910);
		load(0,0,0,7858435);
		load(0,0,0,13694357);
		load(0,0,0,18889377);
		load(0,0,0,22472104);
		load(0,0,0,23749927);	// 60
		load(0,0,0,22472104);
		load(0,0,0,18889377);
		load(0,0,0,13694357);
		load(0,0,0,7858435);
		load(0,0,0,2407910);
		load(0,0,0,-1802942);
		load(0,0,0,-4265203);
		load(0,0,0,-4894743);
		load(0,0,0,-4004041);
		load(0,0,0,-2181620);
		load(0,0,0,-117459);
		load(0,0,0,1576100);
		load(0,0,0,2501598);
		load(0,0,0,2541019);
		load(0,0,0,1839451);
		load(0,0,0,722316);
		load(0,0,0,-423025);
		load(0,0,0,-1264453);
		load(0,0,0,-1609167);
		load(0,0,0,-1436169);
		load(0,0,0,-875522);
		load(0,0,0,-148032);
		load(0,0,0,511702);
		load(0,0,0,924473);
		load(0,0,0,1009215);
		load(0,0,0,791075);
		load(0,0,0,377773);
		load(0,0,0,-84030);
		load(0,0,0,-456676);
		load(0,0,0,-649257);
		load(0,0,0,-635973);
		load(0,0,0,-452995);
		load(0,0,0,-178293);
		load(0,0,0,96929);
		load(0,0,0,295645);
		load(0,0,0,373719);
		load(0,0,0,326235);
		load(0,0,0,181968);
		load(0,0,0,-10227);
		load(0,0,0,-197775);
		load(0,0,0,-338469);
		load(0,0,0,-408946);
		load(0,0,0,-406493);
		load(0,0,0,-345175);
		load(0,0,0,-248650);
		load(0,0,0,-142342);
		load(0,0,0,-47175);
		load(0,0,0,23917);
		load(0,0,0,66574);
		load(0,0,0,83360);
		load(0,0,0,80978);
		load(0,0,0,67405);
		load(0,0,0,49704);
		load(0,0,0,32841);
		load(0,0,0,19445);
		load(0,0,0,10228);
		load(0,0,0,4687);
		load(0,0,0,1804);
		load(0,0,0,540);
		load(1,0,0,103);	// 120
		load(0,0,0,999999);
		load(0,0,0,0);
		setreg(7,0);	// release reset (start tuner)
		idle(8);
		// Generate received signal at 10 MHz
		repeat (300) fs8(0);
		repeat (600) fs8(32767);
		repeat (300) fs8(0);
	end
	
		// Set Frequency and Interpolation for Transmitting at 1 Mbps
		xmt = 1;
		//
		//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 0 |                         LSW Frequency                         | 2^32 * F/80M
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 1 |                         MSW Frequency                         |
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 2 |       Exponent        |    Integer    |       Fraction        | CIC Gain
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 3 |               |             CIC Interpolation - 1             |
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//  4 |   |       Blanker Threshold       |                           |
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 5 |     FIR Decimation    |       Number of Coefficients - 2      | (reset)
		//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 6 |                           |          1/4 Instruction          | Load FIR
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//	 7 |                                                           |RST| 
		//	   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
		//
//		setreg(0,16'h3333);
//		setreg(1,16'h1F33);	// frequency = 9.75 MHz
//		setreg(0,16'hCCCD);
//		setreg(1,16'h20CC);	// frequency = 10.25 MHz
		setreg(0,16'h3333);
		setreg(1,16'h0733);	// frequency = 2.25 MHz
//		setreg(0,16'hCCCD);
//		setreg(1,16'h08CC);	// frequency = 2.75 MHz
		setreg(2,16'h70FD);	// CIC gain (3.960 x 2^28)
		setreg(3,16'h000F);	// CIC interpolation (16)
//		setreg(4,16'h7FFF);	// blanker threshold
		setreg(5,16'h0477);	// FIR decimation and length (1,121)
		//
		// Load FIR filter coefficients
		//
		//	 35 34 33 32 31            0
		// +--+--+--+--+---------------+
		//	|WR|LD|SK|  |  COEFFICIENT  |
		//	+--+--+--+--+---------------+
		//
		setreg(7,1);	// reset address
		load(0,1,0,515);			// 0
		load(0,0,0,97225);		// 1
		load(0,0,0,416800);		// 2
		load(0,0,0,-1243250);	// 3
		load(0,0,0,-988875);		// 4
		load(0,0,0,1478225);		// 5
		load(0,0,0,-3246285);	// 6
		load(0,0,0,5046075);		// 7
		load(0,0,0,-7180845);	// 8
		load(0,0,0,9197255);		// 9
		load(0,0,0,-10908100);	// 10
		load(0,0,0,12039550);	// 11
		load(0,0,0,118749635);	// 12
		load(0,0,0,12039550);	// 13
		load(0,0,0,-10908100);	// 14
		load(0,0,0,9197255);		// 15
		load(0,0,0,-7180845);	// 16
		load(0,0,0,5046075);		// 17
		load(0,0,0,-3246285);	// 18
		load(0,0,0,1478225);		// 19
		load(0,0,0,-988875);		// 20
		load(0,0,0,-1243250);	// 21
		load(0,0,0,416800);		// 22
		load(0,0,0,97225);		// 23
		load(1,0,0,515);			// 24
		load(0,1,0,2700);			// 0
		load(0,0,0,164205);		// 1
		load(0,0,0,332870);		// 2
		load(0,0,0,-1725875);	// 3
		load(0,0,0,-51135);		// 4
		load(0,0,0,484645);		// 5
		load(0,0,0,-2283380);	// 6
		load(0,0,0,4622365);		// 7
		load(0,0,0,-8045835);	// 8
		load(0,0,0,12705095);	// 9
		load(0,0,0,-20020205);	// 10
		load(0,0,0,39292175);	// 11
		load(0,0,0,112360520);	// 12
		load(0,0,0,-9014710);	// 13
		load(0,0,0,-587295);		// 14
		load(0,0,0,3611580);		// 15
		load(0,0,0,-4377610);	// 16
		load(0,0,0,3955375);		// 17
		load(0,0,0,-3179865);	// 18
		load(0,0,0,1868595);		// 19
		load(0,0,0,-1692345);	// 20
		load(0,0,0,-711710);		// 21
		load(0,0,0,404890);		// 22
		load(1,0,0,51140);		// 23
		load(0,1,0,9020);			// 0
		load(0,0,0,248520);		// 1
		load(0,0,0,119585);		// 2
		load(0,0,0,-2032465);	// 3
		load(0,0,0,909840);		// 4
		load(0,0,0,-891465);		// 5
		load(0,0,0,-420150);		// 6
		load(0,0,0,2558510);		// 7
		load(0,0,0,-6322265);	// 8
		load(0,0,0,12507990);	// 9
		load(0,0,0,-24473715);	// 10
		load(0,0,0,68471785);	// 11
		load(0,0,0,94446885);	// 12
		load(0,0,0,-21326015);	// 13
		load(0,0,0,7880500);		// 14
		load(0,0,0,-2115125);	// 15
		load(0,0,0,-740160);		// 16
		load(0,0,0,1888865);		// 17
		load(0,0,0,-2264975);	// 18
		load(0,0,0,1631175);		// 19
		load(0,0,0,-2044730);	// 20
		load(0,0,0,-235875);		// 21
		load(0,0,0,337025);		// 22
		load(1,0,0,23435);		// 23
		load(0,1,0,23435);		// 0
		load(0,0,0,337025);		// 1
		load(0,0,0,-235875);		// 2
		load(0,0,0,-2044730);	// 3
		load(0,0,0,1631175);		// 4
		load(0,0,0,-2264975);	// 5
		load(0,0,0,1888865);		// 6
		load(0,0,0,-740160);		// 7
		load(0,0,0,-2115125);	// 8
		load(0,0,0,7880500);		// 9
		load(0,0,0,-21326015);	// 10
		load(0,0,0,94446885);	// 11
		load(0,0,0,68471785);	// 12
		load(0,0,0,-24473715);	// 13
		load(0,0,0,12507990);	// 14
		load(0,0,0,-6322265);	// 15
		load(0,0,0,2558510);		// 16
		load(0,0,0,-420150);		// 17
		load(0,0,0,-891465);		// 18
		load(0,0,0,909840);		// 19
		load(0,0,0,-2032465);	// 20
		load(0,0,0,119585);		// 21
		load(0,0,0,248520);		// 22
		load(1,0,0,9020);			// 23
		load(0,1,0,51140);		// 0
		load(0,0,0,404890);		// 1
		load(0,0,0,-711710);		// 2
		load(0,0,0,-1692345);	// 3
		load(0,0,0,1868595);		// 4
		load(0,0,0,-3179865);	// 5
		load(0,0,0,3955375);		// 6
		load(0,0,0,-4377610);	// 7
		load(0,0,0,3611580);		// 8
		load(0,0,0,-587295);		// 9
		load(0,0,0,-9014710);	// 10
		load(0,0,0,112360520);	// 11
		load(0,0,0,39292175);	// 12
		load(0,0,0,-20020205);	// 13
		load(0,0,0,12705095);	// 14
		load(0,0,0,-8045835);	// 15
		load(0,0,0,4622365);		// 16
		load(0,0,0,-2283380);	// 17
		load(0,0,0,484645);		// 18
		load(0,0,0,-51135);		// 19
		load(0,0,0,-1725875);	// 20
		load(0,0,0,332870);		// 21
		load(0,0,0,164205);		// 22
		load(1,0,0,2700);			// 23
		load(0,0,0,999999);
		load(0,0,0,0);
		setreg(7,0);	// release reset (start tuner)
		idle(4096);
		// Transmit
		repeat (10) fs40oe(0,15);
		repeat (40) fs40oe(32767,15);
		repeat (10) fs40oe(0,15);
	end
	
	// load coefficient
	task load;
	input wr;
	input ld;
	input sk;
	input signed [27:0] coef;
	begin
		setreg(6,coef[15:0]);
		setreg(6,{wr,ld,sk,1'b0,coef[27:16]});
	end
	endtask
	
	// set register
	task setreg;
	input [2:0] addr;
	input [15:0] data;
	begin
		#3.125 sclk = 0; dclk = 0; iocs = 1; iowr = 1; ioaddr = addr; din = data;
		#3.125 sclk = 1; dclk = 1;
		#3.125 sclk = 1; dclk = 0;
		#3.125 sclk = 0; dclk = 1;
		repeat (3)
		begin
			#3.125 sclk = 0; dclk = 0; iocs = 0; iowr = 0; ioaddr = 0; din = 0;
			#3.125 sclk = 1; dclk = 1;
			#3.125 sclk = 1; dclk = 0;
			#3.125 sclk = 0; dclk = 1;
		end
	end
	endtask
	
	// receive Fs/8
	task fs8;
	input signed [15:0] m;
	begin
		rcv(0);
		rcv(m*0.7071);
		rcv(m);
		rcv(m*0.7071);
		rcv(0);
		rcv(-m*0.7071);
		rcv(-m);
		rcv(-m*0.7071);
	end
	endtask
	
	// receive data
	task rcv;
	input signed [15:0] s;
	begin
		#3.125 sclk = 0; dclk = 0;
		#3.125 sclk = 1; dclk = 1;
		#3.125 sclk = 1; dclk = 0; adc = 32768 + s; 
		#3.125 sclk = 0; dclk = 1;
	end
	endtask
	
	// transmit Fs/4
	task fs4;
	input signed [15:0] mag;
	input integer i;
	begin
		send(mag*0.7071,mag*0.7071,i);
		send(-mag*0.7071,mag*0.7071,i);
		send(-mag*0.7071,-mag*0.7071,i);
		send(mag*0.7071,-mag*0.7071,i);
	end
	endtask
	
	// transmit Fs/4
	task fs40;
	input signed [15:0] mag;
	input integer i;
	begin
		send(mag,0,i);
		send(0,mag,i);
		send(-mag,0,i);
		send(0,-mag,i);
	end
	endtask
	
	// transmit Fs/4
	task fs4oe;
	input signed [15:0] mag;
	input integer i;
	begin
		sendoe(mag*0.7071,mag*0.7071,i);
		sendoe(-mag*0.7071,mag*0.7071,i);
		sendoe(-mag*0.7071,-mag*0.7071,i);
		sendoe(mag*0.7071,-mag*0.7071,i);
	end
	endtask
	
	// transmit Fs/4
	task fs40oe;
	input signed [15:0] mag;
	input integer i;
	begin
		sendoe(mag,0,i);
		sendoe(0,mag,i);
		sendoe(-mag,0,i);
		sendoe(0,-mag,i);
	end
	endtask
	
	// transmit data
	task send;
	input signed [15:0] x;
	input signed [15:0] y;
	input integer i;
	begin
		#3.125 sclk = 0; dclk = 0; iv = 1; dix = x; diy = y;
		#3.125 sclk = 1; dclk = 1;
		#3.125 sclk = 1; dclk = 0; 
		#3.125 sclk = 0; dclk = 1;
		repeat (i)
		begin
			#3.125 sclk = 0; dclk = 0; iv = 0; dix = 0; diy = 0;
			#3.125 sclk = 1; dclk = 1;
			#3.125 sclk = 1; dclk = 0;
			#3.125 sclk = 0; dclk = 1;
		end
	end
	endtask
	
	// transmit data
	task sendoe;
	input signed [15:0] x;
	input signed [15:0] y;
	input integer i;
	begin
		while (~rfd)
		begin
			#3.125 sclk = 0; dclk = 0; iv = 0; dix = 0; diy = 0;
			#3.125 sclk = 1; dclk = 1;
			#3.125 sclk = 1; dclk = 0;
			#3.125 sclk = 0; dclk = 1;
		end
		#3.125 sclk = 0; dclk = 0; iv = 1; dix = x; diy = y;
		#3.125 sclk = 1; dclk = 1;
		#3.125 sclk = 1; dclk = 0; 
		#3.125 sclk = 0; dclk = 1;
		repeat (i)
		begin
			#3.125 sclk = 0; dclk = 0; iv = 0; dix = 0; diy = 0;
			#3.125 sclk = 1; dclk = 1;
			#3.125 sclk = 1; dclk = 0;
			#3.125 sclk = 0; dclk = 1;
		end
	end
	endtask
	
	// toggle clock
	task idle;
	input integer n;
	begin
		repeat (n)
		begin
			#3.125 sclk = 0; dclk = 0;
			#3.125 sclk = 1; dclk = 1;
			#3.125 sclk = 1; dclk = 0;
			#3.125 sclk = 0; dclk = 1;
		end
	end
	endtask
      
endmodule


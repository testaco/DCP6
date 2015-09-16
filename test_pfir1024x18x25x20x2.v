`timescale 1ns / 1ps
//
//					test_pfir1024x18x25x20x2 - Test 1024-tap FIR Filter
//
//					  (C) Copyright 2007-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
// 
module test_pfir1024x18x25x20x2;

	// Inputs
	reg [17:0] dix;
	reg [17:0] diy;
	reg iv;
	reg oe;
	reg clk;
	reg mrst;
	reg [5:0] dec;
	reg [9:0] ncoef;
	reg [8:0] pdata;
	reg pwr;
	reg prst;

	// Outputs
	wire rfd;
	wire [19:0] dox;
	wire [19:0] doy;
	wire ov;
	wire ovf;
	
	// Test
	reg [19:0] x,y;

	// Instantiate the Unit Under Test (UUT)
	pfir1024x18x25x20x2 uut (
		.rfd(rfd),
		.dix(dix), 
		.diy(diy), 
		.iv(iv),
		.oe(oe),
		.dox(dox), 
		.doy(doy), 
		.ov(ov), 
		.ovf(ovf), 
		.clk(clk),
		.mrst(mrst), 
		.dec(dec),
		.ncoef(ncoef),
		.pclk(clk),		
		.pdata(pdata), 
		.pwr(pwr), 
		.prst(prst)
	);
	always @ (posedge clk)
	begin
		if (ov) x <= dox;
		if (ov) y <= doy;
	end

	initial begin
		// Initialize Inputs
		dix = 0;
		diy = 0;
		iv = 0;
		oe = 1;
		clk = 0;
		mrst = 0;
		dec = 1;	// 1
		ncoef = 0; // 2 
		pdata = 0;
		pwr = 0;
		prst = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		// reset
		ncoef = 35; // 37
		reset;
		// configure for interpolation by 2 with 0.4*Fs passband
		rstreg;
		load(1,4194297*2,19);
		load(0,-52*2,1);
		load(0,213*2,2);
		load(0,-616*2,3);
		load(0,1476*2,4);
		load(0,-3117*2,5);
		load(0,6011*2,6);
		load(0,-10790*2,7);
		load(0,18285*2,8);
		load(0,-29551*2,9);
		load(0,45937*2,10);
		load(0,-69201*2,11);
		load(0,101798*2,12);
		load(0,-147518*2,13);
		load(0,213090*2,14);
		load(0,-312601*2,15);
		load(0,482669*2,16);
		load(0,-858323*2,17);
		load(0,2659438*2,18);
		load(0,2659438*2,19);
		load(0,-858323*2,20);
		load(0,482669*2,21);
		load(0,-312601*2,22);
		load(0,213090*2,23);
		load(0,-147518*2,24);
		load(0,101798*2,25);
		load(0,-69201*2,26);
		load(0,45937*2,27);
		load(0,-29551*2,28);
		load(0,18285*2,29);
		load(0,-10790*2,30);
		load(0,6011*2,31);
		load(0,-3117*2,32);
		load(0,1476*2,33);
		load(0,-616*2,34);
		load(0,213*2,35);
		load(1,-52*2,36);
		load(0,0,0);
		rstreg;
		idle(8);
		repeat (4)
		begin
			#5 clk = 0; mrst = 0;
			#5 clk = 1;
		end
		// Transmit
		repeat (1) fs4(0,38);
		repeat (4) fs4(131071,40);
		repeat (4) fs4(131071,35);
		repeat (4) fs4(131071,30);
		repeat (4) fs4(131071,35);
		repeat (4) fs4(131071,40);
		repeat (4) fs4(131071,35);
		repeat (4) fs4(131071,30);
		repeat (4) fs4(131071,35);
		repeat (4) fs4(131071,40);
		repeat (4) fs4(131071,35);
		repeat (2) fs4(0,38);

		// reset
		ncoef = 13; // 15
		reset;
		// configure for interpolation by 2 with Fs/4 passband
		rstreg;
		load(0,914*2,1);
		load(0,-7485*2,2);
		load(0,33443*2,3);
		load(0,-107658*2,4);
		load(0,285207*2,5);
		load(0,-712964*2,6);
		load(0,2605700*2,7);
		load(0,2605700*2,8);
		load(0,-712964*2,9);
		load(0,285207*2,10);
		load(0,-107658*2,11);
		load(0,33443*2,12);
		load(0,-7485*2,13);
		load(1,914*2,14);
		load(1,4194300*2,7);
		load(0,0,0);
//		load(0,65536,1);
//		load(0,65536,2);
//		load(0,65536,3);
//		load(1,65536,4);
//		load(0,65536,1);
//		load(0,65536,2);
//		load(0,65536,3);
//		load(1,65536,4);
//		load(0,0,0);
		rstreg;
		idle(8);
		repeat (4)
		begin
			#5 clk = 0; mrst = 0;
			#5 clk = 1;
		end
		// Transmit
		repeat (1) fs4(0,18);
		repeat (16) fs4(131071,18);
		repeat (2) fs4(0,18);
		
		// reset
		ncoef = 33; // 35
		reset;
		// configure for interpolation by 4
		rstreg;
		load(0,440*4,1);
		load(0,37028*4,2);
		load(0,-64047*4,3);
		load(0,-50599*4,4);
		load(0,1601302*4,5);
		load(0,750449*4,6);
		load(0,-234504*4,7);
		load(0,47366*4,8);
		load(1,8654*4,9);
		load(0,2951*4,1);
		load(0,50715*4,2);
		load(0,-161280*4,3);
		load(0,286762*4,4);
		load(0,1738491*4,5);
		load(0,286762*4,6);
		load(0,-161280*4,7);
		load(0,50715*4,8);
		load(1,2591*4,9);
		load(0,8654*4,1);
		load(0,47366*4,2);
		load(0,-234504*4,3);
		load(0,750449*4,4);
		load(0,1601302*4,5);
		load(0,-50599*4,6);
		load(0,-64047*4,7);
		load(0,37028*4,8);
		load(1,440*4,9);
		load(0,20530*4,1);
		load(0,11133*4,2);
		load(0,-217628*4,3);
		load(0,1234010*4,4);
		load(0,1234010*4,5);
		load(0,-217628*4,6);
		load(0,11133*4,7);
		load(1,20530*4,8);
		load(0,0,0);
		rstreg;
		idle(8);
		repeat (4)
		begin
			#5 clk = 0; mrst = 0;
			#5 clk = 1;
		end
		// Transmit
		repeat (1) fs4(0,38);
		repeat (40) fs4(131071,38);
		repeat (2) fs4(0,38);
	end
	
	// reset
	task reset;
	begin
		repeat (16)
		begin
			#5 clk = 0; mrst = 1;
			#5 clk = 1;
		end
		#5 clk = 0; mrst = 0;
		#5 clk = 1;
	end
	endtask
	
	// load coefficient
	task load;
	input w;
	input signed [24:0] coef;
	input [9:0] indx;
	begin
		setreg(indx[8:0]);
		setreg({coef[7:0],indx[9]});
		setreg(coef[16:8]);
		setreg({w,coef[24:17]});
	end
	endtask
	
	// set register
	task setreg;
	input [8:0] data;
	begin
		#5 clk = 0; pwr = 1; pdata = data;
		#5 clk = 1;
	end
	endtask
	
	// reset address counter
	task rstreg;
	begin
		#5 clk = 0; pwr = 0; pdata = 0; prst = 1;
		#5 clk = 1;
		#5 clk = 0; pwr = 0; pdata = 0; prst = 0;
		#5 clk = 1;
	end
	endtask
	
	// transmit Fs/4
	task fs4;
	input signed [17:0] mag;
	input integer i;
	begin
		sendoe(mag*0.7071,mag*0.7071,i);
		sendoe(-mag*0.7071,mag*0.7071,i);
		sendoe(-mag*0.7071,-mag*0.7071,i);
		sendoe(mag*0.7071,-mag*0.7071,i);
	end
	endtask
	
	// transmit Fs/4
	task fs40;
	input signed [17:0] mag;
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
	input signed [17:0] x;
	input signed [17:0] y;
	input integer i;
	begin
		#5 clk = 0; iv = 1; dix = x; diy = y;
		#5 clk = 1;
		repeat (i)
		begin
			#5 clk = 0; iv = 0;
			#5 clk = 1;
		end
	end
	endtask
	
	// transmit data and toggle OE
	task sendoe;
	input signed [17:0] x;
	input signed [17:0] y;
	input integer i;
	begin
		#5 clk = 0; iv = 1; dix = x; diy = y; 
		#5 clk = 1;
		#5 clk = 0; oe = 0; iv = 0; 
		#5 clk = 1;
		#5 clk = 0; oe = 0; iv = 0; 
		#5 clk = 1;
		repeat (i-3)
		begin
			#5 clk = 0; oe = 1; iv = 0;
			#5 clk = 1;
		end
		#5 clk = 0; oe = 0; iv = 0; 
		#5 clk = 1;
	end
	endtask
	
	// toggle clock
	task idle;
	input integer n;
	begin
		repeat (n)
		begin
			#5 clk = 0;
			#5 clk = 1;
		end
	end
	endtask
      
endmodule


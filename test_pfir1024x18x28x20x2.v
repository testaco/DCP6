`timescale 1ns / 1ps
//
//					test_pfir1024x18x28x20x2 - Test 1024-tap FIR Filter
//
//					  (C) Copyright 2007-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
// 
module test_pfir1024x18x28x20x2;

	// Inputs
	reg [17:0] dix;
	reg [17:0] diy;
	reg iv;
	reg oe;
	reg clk;
	reg mrst;
	reg [5:0] dec;
	reg [9:0] ncoef;
	reg [15:0] pdata;
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
	pfir1024x18x28x20x2 uut (
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
				
		// configure for decimation by 5
		dec = 5; // 5
		ncoef = 119; // 121
		rston;
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
		rstoff;
		idle(8);
		repeat (4)
		begin
			#5 clk = 0; mrst = 0;
			#5 clk = 1;
		end
		// Receive
		repeat (5) fs20(0,50);
		repeat (40) fs20(131071,50);
		repeat (10) fs20(0,50);
				
		// configure for interpolation by 5
		dec = 1; // 1
		ncoef = 119; // 121
		rston;
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
		rstoff;
		idle(8);
		repeat (4)
		begin
			#5 clk = 0; mrst = 0;
			#5 clk = 1;
		end
		// Transmit
		repeat (1) fs4(0,121);
		repeat (40) fs4(131071,121);
		repeat (2) fs4(0,121);
	end
	
	// reset
	task rston;
	begin
		#5 clk = 0; pwr = 0; pdata = 0; prst = 1;	mrst = 1;
		#5 clk = 1;
		#5 clk = 0; pwr = 0; pdata = 0; prst = 0;
		#5 clk = 1;
	end
	endtask
	task rstoff;
	begin
		#5 clk = 0; pwr = 0; pdata = 0; prst = 1; mrst = 0;
		#5 clk = 1;
		#5 clk = 0; pwr = 0; pdata = 0; prst = 0;
		#5 clk = 1;
	end
	endtask
	
	// load coefficient
	task load;
	input wr;
	input ld;
	input sk;
	input signed [27:0] coef;
	begin
		setreg(coef[15:0]);
		setreg({wr,ld,sk,1'b0,coef[27:16]});
	end
	endtask
	
	// set register
	task setreg;
	input [15:0] data;
	begin
		#5 clk = 0; pwr = 1; pdata = data;
		#5 clk = 1;
	end
	endtask
	
	// transmit Fs/20
	task fs20;
	input signed [17:0] mag;
	input integer i;
	begin
		send(mag*1.000,mag*0.000,i);		// 0
		send(mag*0.951,mag*0.309,i);		// 18
		send(mag*0.809,mag*0.588,i);		// 36
		send(mag*0.588,mag*0.809,i);		// 54
		send(mag*0.309,mag*0.951,i);		// 72
		send(mag*0.000,mag*1.000,i);		// 90
		send(mag*-0.309,mag*0.951,i);		// 108
		send(mag*-0.588,mag*0.809,i);		// 126
		send(mag*-0.809,mag*0.588,i);		// 144
		send(mag*-0.951,mag*0.309,i);		// 162
		send(mag*-1.000,mag*0.000,i);		// 180
		send(mag*-0.951,mag*-0.309,i);	// 198
		send(mag*-0.809,mag*-0.588,i);	// 216
		send(mag*-0.588,mag*-0.809,i);	// 234
		send(mag*-0.309,mag*-0.951,i);	// 252
		send(mag*0.000,mag*-1.000,i);		// 270
		send(mag*0.309,mag*-0.951,i);		// 288
		send(mag*0.588,mag*-0.809,i);		// 306
		send(mag*0.809,mag*-0.588,i);		// 324
		send(mag*0.951,mag*-0.309,i);		// 342
	end
	endtask
	
	// transmit Fs/8
	task fs8;
	input signed [17:0] mag;
	input integer i;
	begin
		send(mag,0,i);
		send(mag*0.70710678,mag*0.70710678,i);
		send(0,mag,i);
		send(-mag*0.70710678,mag*0.70710678,i);
		send(-mag,0,i);
		send(-mag*0.70710678,-mag*0.70710678,i);
		send(0,-mag,i);
		send(mag*0.70710678,-mag*0.70710678,i);
	end
	endtask
	
	// transmit Fs/4
	task fs4;
	input signed [17:0] mag;
	input integer i;
	begin
		sendoe(mag*0.70710678,mag*0.70710678,i);
		sendoe(-mag*0.70710678,mag*0.70710678,i);
		sendoe(-mag*0.70710678,-mag*0.70710678,i);
		sendoe(mag*0.70710678,-mag*0.70710678,i);
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


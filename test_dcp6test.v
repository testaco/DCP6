`timescale 1ns / 1ps
//
//						test_dcp6test.v - Test DCP-6 PCB Test Program
//
//							(C) Copyright 2011 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-3 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//

module test_dcp6test;

	// Inputs
	reg [15:2] ADC;
	reg OVF;
	reg DCO;
	reg CLK;
	reg REF;
	reg MISO;
	reg [1:0] RXD;
	reg RXER;
	reg RXV;
	reg MINT;
	reg URXD;
	reg SDI2;

	// Outputs
	wire ADCSCK;
	wire ADCCSN;
	wire [13:0] DAC;
	wire MOSI;
	wire SS;
	wire SCK;
	wire [1:0] TXD;
	wire TXV;
	wire REFCLK;
	wire MDC;
	wire RSTN;
	wire UTXD;
	wire UTXE;
	wire GRNLED;
	wire REDLED;
	wire PTT;
	wire SCK2;
	wire SDO2;
	wire SS2;
	wire SS3;

	// Bidirs
	wire ADCSDIO;
	wire MDIO;
	wire [9:0] IO;

	// Instantiate the Unit Under Test (UUT)
	dcp6test uut (
		.ADC(ADC), 
		.OVF(OVF), 
		.DCO(DCO), 
		.ADCSCK(ADCSCK), 
		.ADCSDIO(ADCSDIO), 
		.ADCCSN(ADCCSN), 
		.DAC(DAC), 
		.CLK(CLK), 
		.REF(REF), 
		.MISO(MISO), 
		.MOSI(MOSI), 
		.SS(SS), 
		.SCK(SCK), 
		.RXD(RXD), 
		.RXER(RXER), 
		.RXV(RXV), 
		.TXD(TXD), 
		.TXV(TXV), 
		.REFCLK(REFCLK), 
		.MDC(MDC), 
		.MDIO(MDIO), 
		.MINT(MINT), 
		.RSTN(RSTN), 
		.URXD(URXD), 
		.UTXD(UTXD), 
		.UTXE(UTXE), 
		.GRNLED(GRNLED), 
		.REDLED(REDLED), 
		.PTT(PTT), 
		.IO(IO), 
		.SCK2(SCK2), 
		.SDO2(SDO2), 
		.SDI2(SDI2), 
		.SS2(SS2), 
		.SS3(SS3)
	);

	initial begin
		// Initialize Inputs
		ADC = 0;
		OVF = 0;
		DCO = 0;
		CLK = 0;
		REF = 0;
		MISO = 0;
		RXD = 0;
		RXER = 0;
		RXV = 0;
		MINT = 0;
		URXD = 0;
		SDI2 = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Run test in RAM
		repeat (100000)
		begin
			#6.25 CLK = 0;
			#6.25 CLK = 1;
		end

	end
      
endmodule


//
//											8 kW Dual-Port RAM
//
//							(C) Copyright 2010-2013 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-3 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
// This module implements a 8,192 x 16-bit dual-port memory using 8 block RAMs.
//
module ram8kx16dp(
    input [12:0] aa,		// address input
    input [12:0] ab,
    input [15:0] dia,	// data input
    input [15:0] dib,
    output [15:0] doa,	// data output
    output [15:0] dob,
	 input cea,				// enable
	 input ceb,
    input wea,				// write enable
    input web,
    input clk,				// master clock and reset
    input rst
    );
// internal signals
wire [31:0] doa0,doa1,doa2,doa3,doa4,doa5,doa6,doa7;
wire [31:0] dob0,dob1,dob2,dob3,dob4,dob5,dob6,dob7;
// RAM
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("SR"),
	.RST_PRIORITY_B("SR"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram0 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[1:0]}),
	.DIPA(4'hF),
	.DOA(doa0),
	.DOPA(),
	.DIB({30'h00000000,dib[1:0]}),
	.DIPB(4'hF),
	.DOB(dob0),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram1 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[3:2]}),
	.DIPA(4'hF),
	.DOA(doa1),
	.DOPA(),
	.DIB({30'h00000000,dib[3:2]}),
	.DIPB(4'hF),
	.DOB(dob1),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram2 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[5:4]}),
	.DIPA(4'hF),
	.DOA(doa2),
	.DOPA(),
	.DIB({30'h00000000,dib[5:4]}),
	.DIPB(4'hF),
	.DOB(dob2),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram3 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[7:6]}),
	.DIPA(4'hF),
	.DOA(doa3),
	.DOPA(),
	.DIB({30'h00000000,dib[7:6]}),
	.DIPB(4'hF),
	.DOB(dob3),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram4 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[9:8]}),
	.DIPA(4'hF),
	.DOA(doa4),
	.DOPA(),
	.DIB({30'h00000000,dib[9:8]}),
	.DIPB(4'hF),
	.DOB(dob4),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram5 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[11:10]}),
	.DIPA(4'hF),
	.DOA(doa5),
	.DOPA(),
	.DIB({30'h00000000,dib[11:10]}),
	.DIPB(4'hF),
	.DOB(dob5),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram6 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[13:12]}),
	.DIPA(4'hF),
	.DOA(doa6),
	.DOPA(),
	.DIB({30'h00000000,dib[13:12]}),
	.DIPB(4'hF),
	.DOB(dob6),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(2),
	.DATA_WIDTH_B(2),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(1'b0),
	.INIT_B(1'b0),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(1'b0),
	.SRVAL_B(1'b0),
	.WRITE_MODE_A("READ_FIRST"),
	.WRITE_MODE_B("READ_FIRST")
	) ram7 (
	.ADDRA({aa,1'b0}),
	.ADDRB({ab,1'b0}),
	.DIA({30'h00000000,dia[15:14]}),
	.DIPA(4'hF),
	.DOA(doa7),
	.DOPA(),
	.DIB({30'h00000000,dib[15:14]}),
	.DIPB(4'hF),
	.DOB(dob7),
	.DOPB(),
	.CLKA(clk),
	.CLKB(clk),
	.WEA({wea,wea,wea,wea}),
	.WEB({web,web,web,web}),
	.ENA(cea),
	.ENB(ceb),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(rst),
	.RSTB(rst)
	);
// connect output
assign doa = {doa7[1:0],doa6[1:0],doa5[1:0],doa4[1:0],doa3[1:0],doa2[1:0],doa1[1:0],doa0[1:0]};
assign dob = {dob7[1:0],dob6[1:0],dob5[1:0],dob4[1:0],dob3[1:0],dob2[1:0],dob1[1:0],dob0[1:0]};
endmodule

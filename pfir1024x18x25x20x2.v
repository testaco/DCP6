//
//		pfir1024x18x25x20x2.v - Finite Impulse Response Filter using RAM Buffer 
//
//					(C) Copyright 2004-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This is a MAC engine for I/Q FIR filters that processes 2 samples per instruction.
// X and Y samples are stored in two 1024x18 RAMs and instructions in a 1024x36 ROM.
// This module executes 36-bit instructions formatted as follows:
//
//		  35   34         10   9     0
//		+----+---------------+---------+
//		| W  |  COEFFICIENT  |  INDEX  |
//		+----+---------------+---------+
//
//		INDEX - 10-bit offset from base address (backwards in time starting at 1)
//		COEFFICIENT - 25-bit multiplier
//		W - write out accumulated result and then zero accumulator
//
// The base address is set when the first instruction is executed by loading
// the next sample address.
//
// I/O is parallel X and Y samples represented as twos complement 18-bit signed
// fractions. DIX and DIY are the inputs and DOX and DOY are the outputs. IV and
// OV indicate that the data inputs and outputs are valid, respectively. Two data
// samples are processed per clock using one coefficient. The DEC input determines
// the number of samples to be processed in each convolution. The sample index goes
// backwards in time and the first sample that can be processed is number 1.
//
// The coefficient ROM is loaded from PDATA in 9-bit words and read in 36-bit words.
// PRST resets the coefficient address to zero and PWR increments the address on each
// write. Time delays are set to match pmac18x24x20. This adds 4 clocks to the 6
// clock MAC time delay as follows:
//
//	Clock	Action
//		1	Increment counter
//		2	Read Program RAM	
//		3	Instruction to RAM output register
//		4	Subtract index from base address
//		5	multiply data by coefficient (A & B regs)
//		6	multiply data by coefficient (P reg)
//		7	accumulate lower bits and save middle and upper bits
//		8	add lower partial products, accumulate middle bits and save upper bits
//		9	add upper partial products, accumulate upper bits and round lower bits
//	  10	round upper bits and save lower rounded bits
//
// The instruction counter will stop at 1024 and issue NOP (all zero) instructions.
// The instruction counter will restart at zero when sufficient data is available. 
//
// P: 225 LUTs, 319 registers, 4 block RAMs and 4 DSP48s used. Maximum clock rate is 205 MHz. 
// M: 235 LUTs, 321 registers, 4 block RAMs and 4 DSP48s used. Maximum clock rate is 231 MHz. 
// Longest delay is 44-bit accumulator in mac18x25x20.
//
// History:
//		1-5-11	modify sfir512x18x24x20x2 for parallel processing of X and Y inputs
//		8-23-11	separate PCLK
//
module pfir1024x18x25x20x2 (
	 output rfd,				// ready for data
	 input [17:0] dix,diy,	// data input (parallel X and Y samples)
	 input iv,					// input valid (X when sclk = 1 and Y when sclk = 0)
	 input oe,					// enable output (stalls pipeline if 0)
    output [19:0] dox,doy,	// data output (serial X and Y samples)
	 output ov,					// output valid
	 output ovf,				// overflow
    input clk,					// master clock
	 input mrst,				// master reset
	 input [5:0] dec,			// decimation modulus
	 input [9:0] ncoef,		// number of coefficients minus two
	 input pclk,				// programming clock
	 input [8:0] pdata,		// program RAM input (in 9-bit 1/4-instruction words)
	 input pwr,					// program RAM write enable (also increments address)
	 input prst					// reset configuration parameter counters
	 );
// internal signals
reg busy;							// convolution in progress
reg tc;								// end of filter flag
reg nop;								// no operation flag for MAC pipeline
reg ready;							// buffer RAM contain enough samples to process
reg full;							// buffer RAM full
wire start;							// start convolution
wire eof;							// end of filter
reg [11:0] pctr;					// program input counter
reg [9:0] sctr;					// sample (data) input counter
reg [9:0] size2;					// number of outstanding samples
reg [9:0] cctr0;					// coefficient counter
wire [35:0] rom1a,rom1b;		// instruction ROM output
reg [9:0] index2;					// fields within ROM output
reg [24:0] coef2;
reg w2;								// write data delay
reg [9:0] base1,base2,daddr3;	// base address and data address for calculations *M002*
reg [24:0] coef3,coef4;			// coefficient bus
wire [35:0] ram4x,ram4y;		// data RAM output (upper 18 bits unused)
wire [17:0] data4x,data4y;
reg [5:3] w;
reg [4:0] z;						// coefficient zero delay
reg [4:1] r;						// reset delay
wire ovfx,ovfy;					// MAC overflow outputs
// delay reset to allow coef and data to be zeroed
always @ (posedge clk)
begin
	r <= {r[3:1],mrst}; 
end
// coefficient input counter for loading configuration
always @ (posedge pclk)
begin
	if (prst) pctr <= 0;
	else if (pwr) pctr <= pctr + 1'b1;
end
// sample counter and coefficient counter plus inhibit register
// SCTR generates memory address for each sample pair
// CCTR0 is address of coefficient for convolution step
always @ (posedge clk)
begin
	if (mrst) sctr <= 0;								// count all samples for RAM address
	else if (iv) sctr <= sctr + 1'b1;
	if (mrst) base1 <= 0;							// increment base by decimation factor
	else if (start) base1 <= base1 + {4'h0,dec};
	size2 <= sctr - base1;							// calculate number of unprocessed samples in RAM
	if (mrst) base2 <= 0;							// delay use for addressing
	else if (z[1]) base2 <= base1;
	if (start|mrst) cctr0 <= 0;					// coefficient index starts at zero
	else if (oe & busy) cctr0 <= cctr0 + 1'b1;// stop when output not enabled or busy reset
	ready <= ~size2[9] & (|size2[8:0]);			// ready when samples available > samples required
	full <= ~size2[9] & (|size2[8:4]);			// full when > 15 excess samples
	if (oe) tc <= (cctr0[9:0] == ncoef);		// next to last coefficient detection
	if (mrst) busy <= 0;
	else if (oe) busy <= start | (busy & ~eof);	// set when cctr0 zeroed and reset when end detected
	nop <= ~oe;											// set no operation flag when counter stalled
end
// end of filter only if output enabled
assign eof = tc & oe;
// check for sufficient samples to start new convolution
assign start = oe & ready & (eof | ~busy);
// signal source when 16 or more entries unprocessed
assign rfd = ~full;
// coefficient ROMs - one holds the lower 18-bits the other the upper 18 bits of each instruction
// Port A = 9-bit write, Port B = 36-bit read - 2 DCLK delay
// reset output when program halted 
RAMB16BWER #(
	.DATA_WIDTH_A(9),
	.DATA_WIDTH_B(18),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(9'h000),
	.INIT_B(36'h000000000),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(9'h000),
	.SRVAL_B(36'h000000000),
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
	) rama (
	.ADDRA({pctr[11:2],pctr[0],3'b000}),		// program input address
	.ADDRB({cctr0,4'h0}),				// coefficient output address
	.DIA({24'h000000,pdata[7:0]}),	// program data input
	.DIPA({3'b000,pdata[8]}),
	.DOA(),
	.DOPA(),
	.DIB(32'hFFFFFFFF),
	.DIPB(4'hF),
	.DOB({rom1a[34:27],rom1a[25:18],rom1a[16:9],rom1a[7:0]}),	// program data output
	.DOPB({rom1a[35],rom1a[26],rom1a[17],rom1a[8]}),
	.CLKA(pclk),
	.CLKB(clk),
	.WEA({pwr,pwr,pwr,pwr}),
	.WEB(4'h0),
	.ENA(~pctr[1]),	// lower 18 bits of 36-bit word in this RAM
	.ENB(1'b1),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(1'b0),
	.RSTB(nop|~busy)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(9),
	.DATA_WIDTH_B(18),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(9'h000),
	.INIT_B(36'h000000000),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(9'h000),
	.SRVAL_B(36'h000000000),
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
	) ramb (
	.ADDRA({pctr[11:2],pctr[0],3'b000}),		// program input address
	.ADDRB({cctr0,4'h0}),				// coefficient output address
	.DIA({24'h000000,pdata[7:0]}),	// program data input
	.DIPA({3'b000,pdata[8]}),
	.DOA(),
	.DOPA(),
	.DIB(32'hFFFFFFFF),
	.DIPB(4'hF),
	.DOB({rom1b[34:27],rom1b[25:18],rom1b[16:9],rom1b[7:0]}),	// program data output
	.DOPB({rom1b[35],rom1b[26],rom1b[17],rom1b[8]}),
	.CLKA(pclk),
	.CLKB(clk),
	.WEA({pwr,pwr,pwr,pwr}),
	.WEB(4'h0),
	.ENA(pctr[1]),	// upper 18 bits of 36-bit word in this RAM
	.ENB(1'b1),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(1'b0),
	.RSTB(nop|~busy)
	);
always @ (posedge clk)
begin
	index2 <= rom1a[9:0];						// 10-bit time index of data
	coef2 <= {rom1b[16:0],rom1a[17:10]};	// 25-bit coefficient
	w2 <= rom1b[17];								// write accumulator to output
end
// cycle 3 - calculate data address
always @ (posedge clk)
begin
	daddr3 <= base2 - index2;	// BASE is at least 1 less than SCTR
end
// cycle 4 - data present
always @ (posedge clk)
begin
	if (mrst) coef3 <= 25'h0000000;
	else coef3 <= coef2;		// coefficient delay
	if (mrst) coef4 <= 25'h0000000;
	else coef4 <= coef3;		// coefficient for use
	w <= {w[4:3],w2};			// write sum of products to output (after nop ins.)
	if (oe) z[0] <= start;	// same treatment as CCTR0 and ROM
	if (nop) z[1] <= 0; else z[1] <= z[0];
	z[4:2] <= {z[3:1]};		// coefficient zero
end
//	1Kx18 Buffer RAMs for data samples - one for X and one for Y samples
// write port A - read port B.
RAMB16BWER #(
	.DATA_WIDTH_A(18),
	.DATA_WIDTH_B(18),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(18'h00000),
	.INIT_B(18'h00000),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(18'h00000),
	.SRVAL_B(18'h00000),
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
	) ramx (
	.ADDRA({sctr,4'h0}),				// data input address (M009)
	.ADDRB({daddr3,4'h0}),			// data output address (M009)
	.DIA({16'h0000,dix[15:0]}),	// data input
	.DIPA({2'b00,dix[17:16]}),
	.DOA(),
	.DOPA(),
	.DIB(32'hFFFFFFFF),
	.DIPB(4'hF),
	.DOB({ram4x[33:18],ram4x[15:0]}),	// data output
	.DOPB({ram4x[35:34],ram4x[17:16]}),
	.CLKA(clk),								// common clocks
	.CLKB(clk),
	.WEA({iv,iv,iv,iv}),					// write data
	.WEB(4'h0),
	.ENA(1'b1),
	.ENB(1'b1),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(1'b0),
	.RSTB(1'b0)
	);
RAMB16BWER #(
	.DATA_WIDTH_A(18),
	.DATA_WIDTH_B(18),
	.DOA_REG(0),
	.DOB_REG(0),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(18'h00000),
	.INIT_B(18'h00000),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(18'h00000),
	.SRVAL_B(18'h00000),
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
	) ramy (
	.ADDRA({sctr,4'h0}),					// data input address
	.ADDRB({daddr3,4'h0}),				// data output address
	.DIA({16'h0000,diy[15:0]}),		// data input
	.DIPA({2'b00,diy[17:16]}),
	.DOA(),
	.DOPA(),
	.DIB(32'hFFFFFFFF),
	.DIPB(4'hF),
	.DOB({ram4y[33:18],ram4y[15:0]}),	// data output
	.DOPB({ram4y[35:34],ram4y[17:16]}),
	.CLKA(clk),									// common clocks
	.CLKB(clk),
	.WEA({iv,iv,iv,iv}),						// write data
	.WEB(4'h0),
	.ENA(1'b1),
	.ENB(1'b1),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(1'b0),
	.RSTB(1'b0)
	);
assign data4x = ram4x[17:0];
assign data4y = ram4y[17:0];
// parallel multiplier-accumulators for rectangular (I/Q) data
mac18x25x20 macx (
	.cin(coef4), 
	.din(data4x[17:0]),
	.first(z[4]|w[5]),	// anything following write is coefficient 0
	.last(w[4]),
	.dout(dox),
	.ov(ov), 	// use this output
	.ovf(ovfx),	
	.clk(clk), 
	.rst(r[4])	// delayed reset
	);
mac18x25x20 macy (
	.cin(coef4), 
	.din(data4y[17:0]),
	.first(z[4]|w[5]),	// anything following write is coefficient 0
	.last(w[4]),
	.dout(doy),
	.ov(), 		// use other output
	.ovf(ovfy),	
	.clk(clk), 
	.rst(r[4])	// delayed reset
	);
assign ovf = ovfx | ovfy;
endmodule

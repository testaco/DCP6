//
//		pfir1024x18x28x20x2a.v - Finite Impulse Response Filter using RAM Buffer 
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
// X and Y samples are stored in two 1024x18 RAMs and instructions in a 1024x32 RAM.
// This module executes 32-bit instructions formatted as follows:
//
//		  31   30   29   28   27                           0
//		+----+----+----+----+-------------------------------+
//		| WR | LD | SK |    |          COEFFICIENT          |
//		+----+----+----+----+-------------------------------+
//
//		COEFFICIENT - 28-bit multiplier
//		WR - write out accumulated result
//		LD - reset data pointer to first sample and load accumulator
//		SK - decrement data pointer by two if previous coefficient was zero
//
// The data pointer is set when the first instruction is executed by loading
// the next sample address minus one (SK=0) or two (SK=1).
//
// I/O is parallel X and Y samples represented as twos complement 18-bit signed
// fractions. DIX and DIY are the inputs and DOX and DOY are the outputs. IV and
// OV indicate that the data inputs and outputs are valid, respectively. Two data
// samples are processed per clock using one coefficient. The DEC input determines
// the number of samples to be processed in each convolution. The sample index goes
// backwards in time and the first sample that can be processed is number 1.
//
// The coefficient RAM is loaded from PDATA in 16-bit words and read in 32-bit words.
// PRST resets the coefficient address to zero and PWR increments the address on each
// write. Time delays are set to match mac18x28x20. This adds 4 clocks to the 6
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
// The coefficient counter (CCTR0) will stop at DEC and restart at zero when sufficient data
// is available. 
//
// 230 LUT6s, 259 registers, 4 block RAMs and 4 DSP48s used. Maximum clock rate is 207 MHz. 
// Longest delay is mul;tiplier 0 to multiplier 1 in mac18x28x20.
//
// History:
//		2011-11-30	created from pfir1024x18x25x20
//		2011-12-11	change dctr3 to reduce logic levels (was 251 LUT, 285 reg, 214 MHz)
//		2013-11-25	create from pfir1024x18x28x20 with no change
//		2013-5-30	add coefficient address input and counter (was 228 LUT, 256 reg, 205 MHz)
//
module pfir1024x18x28x20x2a (
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
	 input [9:0] ncoef,		// ending address of coefficients minus two
	 input [9:0] acoef,		// starting address of coefficients
	 input pclk,				// programming clock
	 input [15:0] pdata,		// program RAM input (in 16-bit 1/2-instruction words)
	 input pwr,					// program RAM write enable (also increments address)
	 input prst					// reset configuration parameter counters
	 );
// internal signals
reg busy;							// convolution in progress
reg tc;								// end of filter flag
wire nop;							// no operation flag for MAC pipeline
reg ready;							// buffer RAM contain enough samples to process
reg full;							// buffer RAM full
wire start;							// start convolution
wire eof;							// end of filter
reg [10:0] pctr;					// program input counter
reg [9:0] sctr;					// sample (data) input counter
reg [9:0] size2;					// number of outstanding samples
reg [9:0] cctr0;					// coefficient counter
wire [31:0] rom2a,rom2b;		// instruction ROM output
wire [27:0] coef2;				// coefficient output
wire wr2,ld2,sk2;					// write, load and skip outputs
reg [9:0] base1,base2,dctr3;	// base address and data address for calculations
reg [27:0] coef3,coef4;			// coefficient bus
wire [35:0] ram4x,ram4y;		// data RAM output (upper 18 bits unused)
wire [17:0] data4x,data4y;
reg [2:0] ce;						// counter enable delay
reg wr3,ld3,wr4,ld4;				// write and load delays
reg [1:0] z;						// coefficient zero delay
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
	else if (z[1]) base2 <= base1 - 1'b1;		// and subtract 1
//	else if (z[1]) base2 <= base1;
//	if (start|mrst) cctr0 <= 0;					// coefficient index starts at zero
	if (start|mrst) cctr0 <= acoef;				// set index of first coefficient
	else if (oe & busy) cctr0 <= cctr0 + 1'b1;// stop when output not enabled or busy reset
	ready <= ~size2[9] & (|size2[8:0]);			// ready when samples available > samples required
	full <= ~size2[9] & (|size2[8:4]);			// full when > 15 excess samples
	if (oe) tc <= (cctr0[9:0] == ncoef);		// next to last coefficient detection
	if (mrst) busy <= 0;
	else if (oe) busy <= start | (busy & ~eof);	// set when cctr0 zeroed and reset when end detected
	ce <= {ce[1:0],oe & (start | (busy & ~eof))};// delay to control data counter, load, write & coef. outputs
	if (oe) z <= {z[0],start};						// delay start
end
// end of filter only if output enabled
assign eof = tc & oe;
// check for sufficient samples to start new convolution
assign start = oe & ready & (eof | ~busy);
// signal source when 16 or more entries unprocessed
assign rfd = ~full;
// coefficient ROMs - one holds the lower 16-bits the other the upper 16 bits of each instruction
// Port A = 16-bit write, Port B = 32-bit read - 2 DCLK delay
// reset output when program halted 
RAMB16BWER #(
	.DATA_WIDTH_A(18),
	.DATA_WIDTH_B(18),
	.DOA_REG(0),
	.DOB_REG(1),
	.EN_RSTRAM_A("TRUE"),
	.EN_RSTRAM_B("TRUE"),
	.INIT_A(18'h00000),
	.INIT_B(18'h00000),
	.INIT_FILE("NONE"),
	.RSTTYPE("SYNC"),
	.RST_PRIORITY_A("CE"),
	.RST_PRIORITY_B("CE"),
	.SRVAL_A(18'h000000000),
	.SRVAL_B(18'h00000),
	.WRITE_MODE_A("WRITE_FIRST"),
	.WRITE_MODE_B("WRITE_FIRST")
	) rama (
	.ADDRA({pctr[10:1],4'h0}),		// program input address
	.ADDRB({cctr0,4'h0}),			// coefficient output address
	.DIA({16'h0000,pdata[15:0]}),	// program data input
	.DIPA(4'h0),
	.DOA(),
	.DOPA(),
	.DIB(32'hFFFFFFFF),
	.DIPB(4'hF),
	.DOB(rom2a[31:0]),	// program data output
	.DOPB(),
	.CLKA(pclk),
	.CLKB(clk),
	.WEA({pwr,pwr,pwr,pwr}),
	.WEB(4'h0),
	.ENA(~pctr[0]),	// lower 16 bits of 32-bit word in this RAM
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
	.DOB_REG(1),
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
	) ramb (
	.ADDRA({pctr[10:1],4'h0}),		// program input address
	.ADDRB({cctr0,4'h0}),			// coefficient output address
	.DIA({16'h0000,pdata[15:0]}),	// program data input
	.DIPA(4'h0),
	.DOA(),
	.DOPA(),
	.DIB(32'hFFFFFFFF),
	.DIPB(4'hF),
	.DOB(rom2b[31:0]),	// program data output
	.DOPB(),
	.CLKA(pclk),
	.CLKB(clk),
	.WEA({pwr,pwr,pwr,pwr}),
	.WEB(4'h0),
	.ENA(pctr[0]),	// upper 16 bits of 32-bit word in this RAM
	.ENB(1'b1),
	.REGCEA(1'b1),
	.REGCEB(1'b1),
	.RSTA(1'b0),
	.RSTB(1'b0)
	);
assign coef2 = {rom2b[11:0],rom2a[15:0]};	// 28-bit coefficient
assign wr2 = rom2b[15];							// write accumulator to output
assign ld2 = rom2b[14];							// load accumulator
assign sk2 = rom2b[13];							// skip next sample
// cycle 3 - zero coefficient, load and read strobes if counter stalled
// else form address starting with base2 - 1 and then decrementing by 1 or 2
// cycle 4 - delay coefficient and strobes to match data availability
assign nop = ~ce[2];	// set no operation flag when RAM output invalid
always @ (posedge clk)
begin
//	if (ce[2]) dctr3 <= (ld2 ? base2 : dctr3) + {9'b111111111,~sk2};
	if (ld2 & ce[2]) dctr3 <= base2;	// load starting sample address or
	else if (ce[2]) dctr3 <= dctr3 + {9'b111111111,~sk2};	// subtract 1 or 2
	if (mrst|nop) coef3 <= 28'h0000000;	// zero coef.
	else coef3 <= coef2;						// delay coef. to match counter output
	if (mrst|nop) ld3 <= 0;
	else ld3 <= ld2;
	if (mrst|nop) wr3 <= 0;
	else wr3 <= wr2;
	coef4 <= coef3;	// coefficient for use by multipliers
	ld4 <= ld3;			// load accumulator rather than add to current sum
	wr4 <= wr3;			// write sum of products to output
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
	.ADDRA({sctr,4'h0}),				// data input address
	.ADDRB({dctr3,4'h0}),			// data output address
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
	.ADDRB({dctr3,4'h0}),				// data output address
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
mac18x28x20 macx (
	.cin(coef4), 
	.din(data4x[17:0]),
	.first(ld4),
	.last(wr4),
	.dout(dox),
	.ov(ov), 	// use this output
	.ovf(ovfx),	
	.clk(clk), 
	.rst(r[4])	// delayed reset
	);
mac18x28x20 macy (
	.cin(coef4), 
	.din(data4y[17:0]),
	.first(ld4),
	.last(wr4),
	.dout(doy),
	.ov(), 		// use other output
	.ovf(ovfy),	
	.clk(clk), 
	.rst(r[4])	// delayed reset
	);
assign ovf = ovfx | ovfy;
endmodule

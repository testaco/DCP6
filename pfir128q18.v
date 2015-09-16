//
//		pfir128q18.v - Finite Impulse Response Filter using Shift Register Buffers 
//
//					(C) Copyright 2004-2013 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This is a MAC engine for I/Q FIR filters that processes 8 samples per clock cycle.
// X and Y samples are stored in eight 32x18 shift registers and instructions in four
// 32x18 shift registers plus one 32x4 shift register. This module executes 128-bit
// instructions, each containing 4 coefficients, that are formatted as follows:
//
//	 127  126  125  124       113    96      81     64      49     32      17      0
//	+----+----+----+----+-//-+---------+-//-+---------+-//-+---------+-//-+---------+
//	| WR | LD | RD | TC |    |  COEF0  |    |  COEF1  |    |  COEF2  |    |  COEF3  |
//	+----+----+----+----+-//-+---------+-//-+---------+-//-+---------+-//-+---------+
//
//		COEF0-3 - 18-bit coefficients (LS bits of 19, 20, 21 or 22-bit coef.)
//		WR - write out accumulated result and reset data pointer to first sample
//		LD - load accumulator (start of convolution)
//		RD - read new sample into data shift register
//		TC - terminal count (reset coefficient counter)
//
// The instructions are loaded through the PDATA bus when PWR is active. They are
// loaded in reverse order, starting with 64 16-bit words containing bits 31-0 of
// each instruction. Even words contain bits 15-0 and odd words bits 31-16. This
// is followed by 64 words containing bits 63-32, 64 words containing bits 95-64
// and 64 words containing bits 127-96. PRST should be asserted before loading to
// reset the address counter.
//
// I/O is parallel X and Y samples represented as twos complement 18-bit signed
// fractions. DIX and DIY are the inputs and DOX and DOY are the outputs. IV and OV
// indicate that the data inputs and outputs are valid, respectively. 8 data samples
// are processed per clock using 4 coefficients. Pipelining is as follows:
//
//	Clock	Action
//		0	read SR 0
//		1	read SR 1, latch SR 0 output
//		2	read SR 2, latch SR 1 output, multiply SR 0 data
//		3	read SR 3, latch SR 2 output, multiply SR 1 data, latch SR 0 data
//		4	latch SR 3 output, multiply SR 2 data, add SR 0 and 1 data
//		5	multiply SR 3 data, add SR 0, 1 and 2 data
//		6	accumulate SR 0, 1, 2 and 3 data
//		7	scale output
//		8	round output
//		9	data output valid
//
// 523 LUT6 (3.5% XC6SLX25), 368 registers and 8 DSP48s used. 
// 288 (-2) or 332 (-3) MHz max. clock rate. Longest path: final accumulators.
//
// History:
//		2013-10-1	add input FIFO (was 396 LUT, 319 reg, 332 MHz)
//		2013-10-13	use FIFO with almost full logic (was 490 LUT, 376 reg, 332 MHz)
//		2013-10-13	use quad multiply-add module to improve simulation
//		2013-10-16	register ready for data output (not almost full or full)
//		2013-10-21	use 22-bit configuration data bus
//		2013-12-12	add coefficient start address (was 519 LUT, 359 reg)
//
module pfir128q18 (
	 output rfd,				// ready for data (at least one free entry in FIFO)
	 input [17:0] dix,diy,	// data input
	 input iv,					// input valid
	 input oe,					// enable output
    output [17:0] dox,doy,	// receiver data output
	 output ov,					// output valid
	 output ovf,				// overflow
    input clk,					// master clock
	 input rst,					// master reset
	 input [2:0] shift,		// output scaling
	 input [4:0] caddr,		// coefficient start address
	 input [21:0] pdata,		// coefficient input
	 input pwr					// coefficient write enable
	 );
// internal signals
reg [4:0] dctr0,dctr1,dctr2,dctr3;	// data counter
reg [4:0] cctr0,cctr1,cctr2,cctr3;	// coefficient counter
wire dce,cce;					// counter clock enables
wire [17:0] coef0,coef1,coef2,coef3;
wire [17:0] fox,foy;			// FIFO data output
wire foe,fov,frdy;			// FIFO output enable, output valid and ready for data
reg valid,ready;				// FIFO output register valid and ready for data
reg [17:0] dix0,diy0,dix1,diy1,dix2,diy2,dix3,diy3;	// data SR input delay
wire [17:0] data0x,data1x,data2x,data3x,data0y,data1y,data2y,data3y;
wire [47:0] a0x,a0y,a1x,a1y,a2x,a2y,a3x,a3y;	// adder outputs
reg [39:8] ax,ay;				// accumulators
wire lda;						// load accumulator
reg [21:0] mx,my,rx,ry;		// multiplexers and rounder outputs
wire sx,sy;						// multiplxer output sign bits
wire rv;							// rounder input valid
wire write,load,read,term;	// control signals from coef. SR
wire wr0,ld0,rd0,tc0,z0;	// control signals to logic
reg [10:1] wr,ld,rd,tc,z;	// control signal delays
// data input FIFO
assign foe = read & (oe|~write);
fifo16x36s fifo (
	.rfd(frdy),					// at least one unused entry
	.pdi({dix,diy}),			// data from outside world
	.iv(iv),						// write to FIFO
	.oe(foe),					// read from FIFO (output enable)
	.pdo({fox,foy}),			// data to first FIR shift register
	.ov(fov),					// FIFO output valid
	.empty(),
	.full(),
	.clk(clk),
	.rst(rst)
	);
always @ (posedge clk)
begin
	if (foe) dix0 <= fox;	// delayed FIFO data
	if (foe) diy0 <= foy;
	if (foe) valid <= fov;	// delayed data valid
	ready <= frdy;				// delayed ready for data
end
assign rfd = ready;			// connect output
// coefficient counter addresses shift register taps to obtain coefficients
// stall if waiting for input data or permission to output data
assign cce = (valid|~read) & (oe|~write);
always @ (posedge clk)
begin
	if (rst|tc0) cctr0 <= caddr;				// reset to start convolution
	else if (cce) cctr0 <= cctr0 + 1'b1;	// increment counter
	cctr1 <= cctr0;								// delay addresses for pipeline
	cctr2 <= cctr1;
	cctr3 <= cctr2;
end
// Coefficient memory - four 64x18-bit and one 64x4-bit shift registers
wire [17:0] coef0e,coef1e,coef2e;	// final registers
srlc32x18e c0 (.a(cctr0), .d(pdata[17:0]), .y(coef0), .ce(pwr), .clk(clk), .q(coef0e));
srlc32x18e c1 (.a(cctr1), .d(coef0e), .y(coef1), .ce(pwr), .clk(clk), .q(coef1e));
srlc32x18e c2 (.a(cctr2), .d(coef1e), .y(coef2), .ce(pwr), .clk(clk), .q(coef2e));
srl32x18e c3 (.a(cctr3), .d(coef2e), .y(coef3), .ce(pwr), .clk(clk));
// control signal ROM
srl32x4e c0c (.a(cctr0), .d(pdata[21:18]), .y({write,load,read,term}), .ce(pwr), .clk(clk));
assign wr0 = oe & write & (valid|~read);	// write result & reset data counter
assign ld0 = load;								// load accumulator with first result
assign rd0 = valid & read & (oe|~write);	// read FIFO and shift into data memory
assign tc0 = term & (valid|~read) & (oe|~write);	// terminal count - reset coef. counter
assign z0 = (read & ~valid)|(write & ~oe);	// no data in FIFO or waiting to write 
always @ (posedge clk)
begin
	wr <= {wr[9:1],wr0};	// delay signals for pipeline
	ld <= {ld[9:1],ld0};
	rd <= {rd[9:1],rd0};
	tc <= {tc[9:1],tc0};
	z <= {z[9:1],z0};
end
//	Data memory - four 32x18-bit shift registers for X-axis samples and four for Y-axis samples
// The data counter is disabled to allow data to be shifted in when DCE is false. Data shifts
// across all four registers with the appropriate delays for pipelining. This produces the same
// sequence of data for the multipliers as incrementing the data counter without shifting. New
// data must only be loaded in the final phase at the end of the convolution.
assign dce = (oe|~write) & ~read;	// inhibit count if reading in new data sample
always @ (posedge clk)
begin
	if (rst|wr0) dctr0 <= 0;					// reset to start new phase
	else if (dce) dctr0 <= dctr0 + 1'b1;	// increment counter
	dctr1 <= dctr0;
	dctr2 <= dctr1;
	dctr3 <= dctr2;
end
always @ (posedge clk)
begin
	if (rd0) dix1 <= data0x;	// place register between each shift register
	if (rd[1]) dix2 <= data1x;	// to match registers on adder outputs
	if (rd[2]) dix3 <= data2x;
	if (rd0) diy1 <= data0y;
	if (rd[1]) diy2 <= data1y;
	if (rd[2]) diy3 <= data2y;
end
srl32x18e d0x (.a(dctr0), .d(dix0), .y(data0x), .ce(rd0), .clk(clk));
srl32x18e d1x (.a(dctr1), .d(dix1), .y(data1x), .ce(rd[1]), .clk(clk));
srl32x18e d2x (.a(dctr2), .d(dix2), .y(data2x), .ce(rd[2]), .clk(clk));
srl32x18e d3x (.a(dctr3), .d(dix3), .y(data3x), .ce(rd[3]), .clk(clk));
srl32x18e d0y (.a(dctr0), .d(diy0), .y(data0y), .ce(rd0), .clk(clk));
srl32x18e d1y (.a(dctr1), .d(diy1), .y(data1y), .ce(rd[1]), .clk(clk));
srl32x18e d2y (.a(dctr2), .d(diy2), .y(data2y), .ce(rd[2]), .clk(clk));
srl32x18e d3y (.a(dctr3), .d(diy3), .y(data3y), .ce(rd[3]), .clk(clk));
// 8 multipliers and accumulators (4 for X and 4 for Y)
// reset inputs when coefficient not present
mad18x18x48q madx (
	.A0(data0x), .B0(coef0), .RST0(z0),
	.A1(data1x), .B1(coef1), .RST1(z[1]),
	.A2(data2x), .B2(coef2), .RST2(z[2]),
	.A3(data3x), .B3(coef3), .RST3(z[3]),
	.P(a3x), .CE(1'b1), .CLK(clk));
mad18x18x48q mady (
	.A0(data0y), .B0(coef0), .RST0(z0),
	.A1(data1y), .B1(coef1), .RST1(z[1]),
	.A2(data2y), .B2(coef2), .RST2(z[2]),
	.A3(data3y), .B3(coef3), .RST3(z[3]),
	.P(a3y), .CE(1'b1), .CLK(clk));
// accumulate last adder outputs - middle 32 bits only
assign lda = ld[6];	// 0 = accumulate, 1 = load
always @ (posedge clk)
begin
	ax <= a3x[39:8] + (lda ? 32'h00000000 : ax);
	ay <= a3y[39:8] + (lda ? 32'h00000000 : ay);
end
// scale receiver output and round
assign sx = mx[21];	// sign bits
assign sy = my[21];
assign rv = wr[8];	// rounder input valid
always @ (posedge clk)
begin
	case (shift)
	0: mx <= 22'h000000;	// scale sums by 1/32, 1/16, 1/8, 1/4, 1/2, 1 or 2
	1: mx <= ax[39:18];	// for decimation by 32, 16, 8, 4 , 2 or 1
	2: mx <= ax[38:17];	// to allow 19, 20, 21 or 22 bit coefficients
	3: mx <= ax[37:16];
	4: mx <= ax[36:15];
	5: mx <= ax[35:14];
	6: mx <= ax[34:13];
	7: mx <= ax[33:12];
	default: mx <= 22'hxxxxxx;
	endcase
	case (shift)
	0: my <= 22'h000000;
	1: my <= ay[39:18];
	2: my <= ay[38:17];
	3: my <= ay[37:16];
	4: my <= ay[36:15];
	5: my <= ay[35:14];
	6: my <= ay[34:13];
	7: my <= ay[33:12];
	default: my <= 22'hxxxxxx;
	endcase
	if (rv) rx <= mx + {18'h00000,~sx,sx,sx,sx};	// round from 22 to 18 bits
	if (rv) ry <= my + {18'h00000,~sy,sy,sy,sy};
end
// connect outputs
assign dox = rx[21:4];	// 18-bit outputs
assign doy = ry[21:4];
assign ov = wr[9];		// rounder output valid
assign ovf = 1'b0;		// overflow not implemented
endmodule

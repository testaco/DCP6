//
//					 fir256x16x18.v - FIR Filter Peripheral
//
//					(C) Copyright 2008-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This module processes implements 2-16 filters with 32-256 taps each. Writing to
// output port 0 loads samples into data memory. Writing the starting address of the
// filter coefficient set to port 5 starts the filter. The result can be read from
// input port 0. When interpolating filters are implemented, multiple results are
// generated and can be read sequentially from port 0. 
//
//	Output Ports:
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                             Data                              | 0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                        LSW Coefficient                        | 1
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                                                       |  MSB  | 2
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|         Taps/Phase - 1        |           Total Taps          | 3
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                                       |  Len  |     Base      | 4
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                           |     Coefficient Base Address      | 5
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		}                     Reset Address Counter                     | 6
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		Total Taps: total number of coefficients
//		Taps/Phase: number of coefficients used for each output - 1
//		Base:       base address of data buffer (32-word increments)
//		Len:        length of data buffer (0=32, 1=64, 2=128, 3=256)
//
//	Input Ports:
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|                             Data                              | 0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		|OVF|                                               | F | E |RDY| 1
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		RDY: calculations complete
//		E:   FIFO empty (no results)
//		F:   FIFO full (more than 15 results)
//		OVF: accumulator overflow
//
// 102 MHz maximum clock frequency with 167 LUTs, 90 registers, 1 RAM and 1 MAC used.
// Calculation of output values requires one clock cycle per tap plus an additional 4
// clock cycles for pipeline delays.
//
//   Phs	Decscription
//		0	increment CCTR
//		1	read RAM
//		2	multiply
//		3	accumulate
//
// Revision History:
//		9-16-11	modify S3 code to calculate interpolated outputs sequentially and store in FIFO
//
module fir256x16x18 (
    input [2:0] ioaddr,	// port address
    input iocs,			// address valid
    input [15:0] din,	// input data
    input iowr,			// data valid
	 input iord,			// get output
    output [15:0] dout,	// output data
    input clk,				// master clock
    input rst				// master reset
    );
// internal signals
wire s0,s1,s2,s3,s4,s5;	// port select signals
wire write,start,rdy;	// data valid, start convolution & convolution complete
reg rstacc;					// restart accumulator
wire rstcia;				// reset coefficient input address counter
wire accen;					// enable accumulator writes
reg [2:1] fv;				// accumulator load delay (first coefficient)
reg [2:1] dv;				// accumulator output valid delay (last coefficient)
reg [2:1] cv;				// processing complete
wire load;					// load coefficient
wire cz,czd;				// coefficient counter is zero and delayed version
wire ovf,sign;				// accumulator overflow and sign bits
reg [1:0] msc;				// most significant coefficient bits
reg [8:5] base;			// buffer base address / 32
reg [1:0] length;			// buffer length
reg [8:0] actr;			// address counter for loading coefficients
reg [7:0] ttaps,ptaps;	// number of taps in filter
wire [7:0] sctr;			// sample counter (address for next sample)
reg [7:0] cctr,dctr;		// coefficient and data counters
reg [8:0] caddr;			// coefficient address (512 possible locations)
reg [7:0] dindx;			// index to data within data buffer
wire [7:0] dofs;			// offset from buffer base to sample to be read/written (dindx/dctr)
wire [8:0] aaddr,baddr;	// port A and B addresses
wire [17:0] coef;			// RAM coefficient output and multiplier input
wire [15:0] data;			// RAM data output and multiplier input
wire [47:0] acc;			// accumulator output
wire [15:0] fin,fout;	// rounded result
wire fwr,empty,full;		// FIFO write and FIFO status
reg [15:0] omux;			// output multiplexer
// decode I/O port addresses
assign s0 = iocs & (ioaddr == 0);
assign s1 = iocs & (ioaddr == 1);
assign s2 = iocs & (ioaddr == 2);
assign s3 = iocs & (ioaddr == 3);
assign s4 = iocs & (ioaddr == 4);
assign s5 = iocs & (ioaddr == 5);
assign s6 = iocs & (ioaddr == 6);
// configuration registers
always @ (posedge clk)
begin
	if (rst) ttaps <= 0;
	else if (s3 & iowr) ttaps <= din[7:0];		// filter taps
	if (rst) ptaps <= 0;
	else if (s3 & iowr) ptaps <= din[15:8];
	if (rst) base <= 0;
	else if (s4 & iowr) base <= din[3:0];		// data buffer base address
	if (rst) length <= 0;
	else if (s4 & iowr) length <= din[5:4];	// data buffer length
	if (rst|rstcia) actr <= 0;
	else if (load) actr <= actr + 9'b000000001;	// coef. address counter
	if (rst) msc <= 0;
	else if (s2 & iowr) msc <= din[1:0];		// MS 2 bits of coefficient
end
assign write = s0 & iowr;	// write data to port 0
assign load = s1 & iowr;	// load coefficients via port 1
assign start = s5 & iowr;	// start on write to port 5
assign rstcia = s6 & iowr;	// reset address counter
// sample counter increments when new sample arrives and points at new address
// 2-16 counters are implemented in distributed RAM
RAM16X8SP ctr (
	.A(base[8:5]),	// one counter for each possible base address
	.D(sctr + 8'h01),
	.O(sctr),
	.WE(write),	// increment when writing data to buffer
	.WCLK(clk)
	);
// multiplexer selects number of bits to use from base address and counter
// counter is SCTR if not filtering and DINDX (DCTR - tap number - 1) when filtering
assign dofs = cz ? sctr : dindx;
MUX4X9 damux (
	.D0({base[8:5],dofs[4:0]}),
	.D1({base[8:6],dofs[5:0]}),
	.D2({base[8:7],dofs[6:0]}),
	.D3({base[8],dofs[7:0]}),
	.S(length),
	.Y(baddr)
	);
// coefficient counter (CCTR) decrements after data written and stops at zero
// coefficient address counter (CADDR) increments while CCTR is non-zero
// data index counter (DINDX) is set on start and then decrements
// it is then reloaded each time it reaches zero
// data address is new address - data offset
always @ (posedge clk)
begin
	if (rst) cctr <= 0;
	else if (start) cctr <= ttaps;			// load total number of taps
	else if (~cz) cctr <= cctr - 1'b1;		// then decrement
	if (start) caddr <= din[8:0];				// load first coefficient address
	else if (~cz) caddr <= caddr + 1'b1;	// then increment
	if (rst) dctr <= 0;
	else if (start|dz) dctr <= ptaps;		// load number of taps per phase
	else if (~cz) dctr <= dctr - 1'b1;		// then decrement
	if (start|dz) dindx <= sctr - 1'b1;		// load last data sample address
	else if (~cz) dindx <= dindx - 1'b1;	// then decrement
	fv <= {fv[1],start|(dz & ~cz)};			// first coefficient delay
	dv <= {dv[1],dz & ~cz};						// last coefficient delay
	cv <= {cv[1],cz};								// processing complete delay
end
assign cz = ~|cctr;				// stop when 0 reached
assign dz = ~|dctr;				// load when 0 reached
// coefficient and data RAM - 1 clock delay
// load enables writing of coefficient sets
// zero output when counting inhibited
assign aaddr = load ? actr : caddr;
RAMB16_S18_S18 dram (
	.ADDRA({1'b0,aaddr}),		// coefficient address
	.ADDRB({1'b1,baddr}),		// data address
	.DIA(din),						// 18-bit coefficient input
	.DIPA(msc),
	.DIB(din),						// 16-bit data input
	.DIPB(2'b00),
	.DOA(coef[15:0]),				// 18-bit coefficient output
	.DOPA(coef[17:16]),
	.DOB(data[15:0]),				// 16-bit data output
	.DOPB(),
	.CLKA(clk),						// common clocks
	.CLKB(clk),
	.WEA(load),						// write coefficient
	.WEB(write),					// write data
	.ENA(1'b1),						// always enabled
	.ENB(1'b1),
	.SSRA(rst|cz),					// zero output when no coefficient
	.SSRB(rst|cz)
	);
// multiply 18-bit data by 18-bit coefficient -  1 clock delay
assign accen = ~fv[1];
DSP48A1 #(
	.A0REG(0),	// register accumulated output
	.A1REG(0),
	.B0REG(0),
	.B1REG(0),
	.CREG(0),
	.DREG(0),
	.MREG(0),
	.PREG(1),
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),
	.RSTTYPE("SYNC")
	) mul0 (
	.OPMODE({4'b0000,accen,3'b001}),	// MUL (01) or MAC (09)
	.A({data,2'b00}),	// 16-bit data
	.B(coef),			// 18-bit coefficient
	.BCOUT(),
	.C(48'h000000),
	.D(18'b000000000000000000),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(),
	.PCOUT(),
	.P(acc),
	.CLK(clk),
	.CEA(1'b1),
	.CEB(1'b1),
	.CEC(1'b1),
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(1'b1),
	.CECARRYIN(1'b1),
	.CEOPMODE(1'b1),
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
// overflow if accumulated value extends into upper bits
assign sign = acc[35];
assign ovf = (sign ^ acc[34]);
// round result towards zero or saturate if overflow
assign fin = (ovf ?
	{sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign,~sign}
	: acc[34:19]) 
	+ {15'b000000000000000,sign};
// store results in FIFO
assign fwr = dv[2];
fifo16x16s fifo (
	.pdi(fin),					// rounded accumulator output
	.iv(fwr),					// convolution done
	.oe(iord & ~ioaddr[0]),	// read command
	.pdo(fout),					// user output
	.ov(),
	.empty(empty),				// data to be read
	.full(full),				// overflow
	.clk(clk),
	.rst(rst)
	);
// connect outputs
assign rdy = cv[2] & cz;	// all outputs valid after RAM and multiplier delays
always @ (posedge clk) if (iord) omux <= (ioaddr[0]) ? {ovf,12'h000,full,empty,rdy} : fout;
assign dout = omux;
endmodule

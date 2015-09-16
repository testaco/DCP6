//
//					CPU16.v - 16-bit Central Processing Unit (rev. E)
//
//					  (C) Copyright 2007-2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This CPU is a RISC processor with 16 16-bit registers using 2-address instructions. It uses a
// Harvard architecture with a 16-bit instruction size and 16-bit data word lengths. Subsidiary
// modules decode ALU and program flow control instructions. Memory, I/O access, context switching,
// and 16-bit constant loading are controlled from this module and the instruction formats are:
// 
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// 	| 1   0   0   0 |          Port Number          | Data Register | OUT
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   0   0   1 |     Offset    |  Address Reg. | Data Register | WR
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   0   1   0 |          Port Number          | Data Register | IN
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   0   1   1 |     Offset    |  Address Reg. | Data Register | RD
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1   1   1 | 1   0   1   1 | x   x   x | 0 | x   x | Bank  | RBS
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1   1   1 | 1   0   1   1 | x   x   x | 1 | x   x   x   x | RBI
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1   1   1 | 1   1   0   0 |             Data              | LDH
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// I/O instructions use bits 11-4 to specify the I/O port being accessed. Memory instructions use the
// contents of register B (specified in bits 7-4) plus a 4-bit offset from bits 11-8 to specify the
// memory location. Optionally, the LDH instruction can supply an additional 8 bits for a 12-bit offset.
// Register A (specified by bits 3-0) is the data source for writes and outputs and the data destination
// for reads and inputs. The RBS instruction selects 1 of 4 register banks and an associated stack. The
// RBI instruction increments the bank select register. This module also determines the flags tested for
// conditional jumps and returns as follows:
//
//		Flag	Condition
//		----	------------------------------
//		 00	Unconditional
//		 01	Overflow flag
//		 10	Carry flag
//		 11	Zero flag
//
// The zero flag is only modified by add and subtract operations. The carry flag is modified only by the
// bit test, shift, set carry, clear carry and 2-register add and subtract operations. All instructions
// execute in one clock cycle with the exception of the read and input instructions that require 2 cycles.
//
// NOTE: The first instruction fetched is $0000 - a call to 0.
//
// 92 MHz (-2) or 126 MHz (-3) MHz maximum and uses 1 DSP48, 643 LUTs and 192 registers.
//
// History:
//		M001	5-31-08	Load immediate data to register.
//		M002	6-8-08	Remove encode instruction
//		M003	8-5-08	Convert to 16-bit instruction format
//		M004	9-29-08	Move input multiplexer to MCU16.v and bit test to ALU.v
//		M005	2-28-09	Use external memory with 2 cycle reads and do 2-cycle inputs
//		M006	3-24-09	Added mask instruction
//		M007	3-26-09	make program memory external to allow data access (remove PGM instruction)
//		M007	4-28-09	fix iord strobe bug
//		M008	7-13-09	changed link flag to overflow flag
//		M009	7-18-09	16-bit register load now 2 sequential 8-bit load instructions
//		M010	3-21-10	smaller divider
//		M011	3-25-10	allow pointer plus offset memory addressing
//		M012	12-14-10	modify for larger memory space on Spartan-6
//		M013	4-2-11	move LDH decode to this module and allow use as memory address offset
//		M014	10-22-11	move bank select logic to this module (was 120 MHz, 440 LUT, 116 reg., 1 DSP48)
//		M015	10-31-11	remove 4-8-bit math & add 4-8-12-bit moves (was 121 MHz, 440 LUT, 108 reg., 1 DSP48)
//		M016	11-5-11	CPU16D instruction set and 8-bit I/O port address
//		M017	12-3-11	added SIZE instruction to ALU16 (was 475 LUT & 110 reg.)
//		M018	12-20-11	pass V, C, Z flags individually to PFCU (1 less LUT)
//		M019	3-21-12	square root added to ALU (581 LUTs and 195 regs)
//		M020	4-8-12	new ALU with 1-15 bit rotate and insert
//		M021	4-10-12	variable-length sign extension
//		M022	4-13-12	move 16 kW program RAM into this module (was 625 LUT, 180 reg., 83 MHz)
//		M023	4-29-12	input/read strobe to ALU on 2nd cycle of instruction (was 634 LUT)
//		M024	5-10-12	new jump/return instructions (signed numbers)
//		M025	3-14-13	MRD pin and 6-bit MSEL output (was 642 LUT)
//
module CPU16(
	 output [7:0] ioaddr,		// I/O address bus (256 directly-addressed ports)
    input [15:0] din0,din1,	// I/O data input
	 output iord,					// requesting data on input bus
    output [15:0] dout,			// I/O data output
    output iowr,					// valid data on output bus
	 output [15:10] msel,		// memory bank select output (4096-word banks)
	 output [13:0] maddr,		// memory address (16,384 indirectly-accessed words)
//	 input [15:0] min0,min1,min2,min3,	// memory data input
	 input [15:0] min1,min2,min3,	// memory data input
	 output mrd,					// memory read
	 output [15:0] mout,			// memory data output
	 output mwr,					// memory write
//	 output [13:0] paddr,		// program memory address
//	 input [15:0] pdata,			// program data (instructions)
//	 output pcs,					// program memory enable (used to hold instruction for additional cycle)
	 input clk,						// common clock
	 input rst						// reset CPU state
	 );
// internal signals
wire pcs,mcs0;						// dual-port RAM enables
wire [15:0] pdata,min0;			// dual-port RAM instruction and data ports
wire [13:0] paddr;				// program port address
wire [3:0] op,mod;				// ALU operation and modifier
wire [3:0] aa,ab;					// register address fields
wire [15:0] a,b;					// register file outputs for address and data
wire zero,carry,ovflo,sign;	// ALU flags
wire inp,out,write,read;		// I/O and memory operations
wire ldh,rbs;						// load constant and change context operations
wire inrd1;							// I/O input or memory read cycle 1 and 2 for use
reg inrd2;							// in extending instruction execution to 2 clock cycles
reg hv;								// last instruction was high byte
reg [7:0] hd;						// saved high byte value
wire [7:0] mofs;					// offset to add to register for memory address
reg [1:0] bs;						// stack and register file bank select
// Program flow control logic reads instructions from ROM and controls branching.
// Branches occur if specific flags set - MSB flag input is unconditional branch.
PC14 pfcu (
	.z(zero),			// zero, carry, overflow and sign flags from ALU
	.c(carry),
	.v(ovflo),
	.s(sign),
	.paddr(paddr),		// address of next intruction
	.pdata(pdata),		// current instruction
	.rdata(a[13:0]),	// data from A register
	.hv(hv),				// previous instruction was LDH
	.h6(hd[5:0]),		// data from LDH
	.ss(bs),				// return address stack select for context switching
	.ce(~inrd1),		// PC count enable (low for 1st cycle of 2-cycle instructions)
	.clk(clk),
	.rst(rst)
	);
assign pcs = ~inrd1;	// enable program RAM output
// assign fields for load and data manipulation instuctions (program control decoded elsewhere)
assign aa = pdata[3:0];						// A register address
assign ab = pdata[7:4];						// B register address
assign mod = pdata[11:8];					// operation modifier
assign op = pdata[15:12];					// operation code field
assign out = (op == 8);						// output operation
assign write = (op == 9);					// memory write operation
assign inp = (op == 10);					// input operation
assign read = (op == 11);					// memory read operation
assign rbs = (op == 15) & (mod == 11);	// register bank selection
assign ldh = (op == 15) & (mod == 12);	// load high byte
// decode input and read instructions cycle 1 and cycle 2
assign inrd1 = (inp|read) & ~inrd2;
always @ (posedge clk)
	if (rst) inrd2 <= 0;
	else inrd2 <= inrd1;
// HD loaded and HV set by LDH instruction for one clock cycle
always @ (posedge clk)
begin
	hv <= ldh;			// high byte valid
	hd <= pdata[7:0];	// high byte value
end
// the register file stack pointer selects 1 of 4 16-register banks
always @ (posedge clk)
begin
	if (rst) bs <= 0;
	else if (rbs) bs <= ab[0] ? (bs + 1'b1) : aa[1:0];
end
// ALU provides memory address on B and data for memory writes or outputs on A
ALU16 alu (
	.a(a),				// ALU register A output
	.b(b),				// ALU register B output
	.d0(din0),			// data from I/O port to ALU
	.d1(din1),
	.m0(min0),			// data from memory to ALU
	.m1(min1),
	.m2(min2),
	.m3(min3),
	.inrd(inrd2),		// write to register on 2nd cycle
	.hv(hv),				// LDH instruction detected
	.h8(hd),				// LDH data
	.rs(bs),				// register bank select for context switching
	.pdata(pdata),		// instruction input
	.zero(zero),		// zero, carry and overflow flags from ALU
	.carry(carry),
	.ovflo(ovflo),
	.sign(sign),
	.clk(clk),			// for flags
	.rst(rst)
	);
// Memory Bus
// MSEL - upper 4 address bits direct from register to minimize propagation delay in memory chip select
// MADDR - lower 14 address bits are register B contents plus 4 or 12-bit offset
assign mofs = hv ? hd : 8'h00;	// bits 11-4 of offset are zero or data from previous LDH
assign msel = b[15:10];			// M025
assign maddr = b[13:0] + {2'b00,mofs,mod};	// 14-bit memory address
assign mout = a;					// 16-bit data from register A
assign mrd = read & inrd1;		// read from memory (strobe on 1st cycle only)
assign mwr = write;				// write to memory
// I/O Bus
assign ioaddr = pdata[11:4];	// 8-bit I/O address
assign dout = a;					// 16-bit data from register A
assign iord = inp & inrd1;		// read from input port (strobe on 1st cycle only)
assign iowr = out;				// write to output port
// 16k words shared program and data RAM
assign mcs0 = (msel[15:14] == 2'b00);		// 16kW program RAM
ram16kx16dp pgmram (
	.aa(paddr[13:0]),
	.ab(maddr[13:0]),
	.dia(16'hFFFF),
	.dib(mout),
	.doa(pdata),
	.dob(min0),
	.cea(pcs),
	.ceb(mcs0),
	.wea(1'b0),
	.web(mwr),
	.clk(clk),
	.rst(rst)
	);
endmodule

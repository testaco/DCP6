//
//						16-bit Arithmetic Logic Unit (rev. E)
//
//					(C) Copyright 2007-2012 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This ALU implements the arithmetic and logical instructions for a RISC processor
// using two-address instructions with sixteen 16-bit general-purpose registers. It
// also multiplexes data from I/O and memory in order to minimize delays in the FPGA.
//
// The ALU has 5 groups of inputs:
//		PDATA - Instruction to be executed (source determined externally)
//		HD - 8-bit constant value from previous insturuction field (HV set if valid)
//		D0-1 - Data from two I/O port groups (0-127 or 128-255)
//		M0-3 - Data from four memory ports (blocks of 16,384 words)
//		RS - register bank select (also controls external stack memory selection)
// It also has 3 groups of outputs:
//		A - Data from read/write port of the register file (register selected by PDATA)
//		B - Data from read-only port of the register file (register selected by PDATA)
//		Flags - zero, carry and overflow flags for external program flow control logic
//
//	Instructions execute in one clock cycle, except IN and RD which take 2 clock cycles
// to allow for external memory access. The following instructions are implemented:
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 0   1 | 0   1 |             Data              |   Register A  | MVI
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 0   1 | 1   0 |             Data              |   Register A  | ADI
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 0   1 | 1   1 |             Data              |   Register A  | CPI
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 0   0   0 |    MOD    |  Register B   |   Register A  | Math
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 0   0   1 |    MOD    | Reg. B/Const. |   Register A  | Logic
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 0   1 |  Word Length  |   Register B  |   Register A  | INS
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   0   0 |    MOD    |   Register B  |   Register A  | SXL/SXH/SXW/REV
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   0   0 | 1   1   0 |      MOD      |   Register A  |	SHR
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   0   0 | 1   1   1 |      MOD      |   Register A  |	SHL
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   0   1 |    MOD    |   Register B  |   Register A  | MAC
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   0 | 0   0 |MOD|   Register B  |   Register A  | DIV
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   0 | 0   1   0 |   Register B  |   Register A  | SQRT
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   0 | 1   0   0 |   Bit Select  |   Register A  | TST
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   0 | 1   1   0 | x   x |MOD| C | x   x   x   x | STC/CLC/STZ/CLZ
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   0 |MOD| 1   1 |   Register B  |   Register A  | CMP
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   1 | 1   0   1 | x |    MOD    |   Register A  | LOAD P/Q/R
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   1 | 1   1   0 |  Shift Amount |   Register A  | ROT
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1   1 | 1   1   1 |    Sign Bit   |   Register A  | SEX
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
// 505 LUT6s, 128 registers and 1 DSP48A used. 125 MHz max. clock.
//
// Normal Warnings:
//		<r_16> is unconnected.
//
// History:
//		M001	4-16-08	Reduced propogation delay by adding duplicate arithmetic and logic units.
//		M002	6-8-08	Removed convolutional encoder (more efficient as I/O device)
//		M003	8-5-08	Moved output multiplexer ports to allow 16-bit instruction format
//		M004	8-9-08	32-bit unsigned divider logic replaces 16-bit fractional divider
//		M005	8-12-08	Removed barrel shifer and replaced with byte swap and bit shifter (-112 slices)
//		M006	9-29-08	Allow comparison and bit test operations by inhibiting storage in register
//		M007	3-24-09	Added mask instruction
//		M008	3-28-08	Add set/reset carry and link bit instructions - move w/o op decode to this module
//		M009	7-13-09	Add overflow bit and use carry bit in shifter (no link bit)
//		M010	7-16-09	Fixed rotate left bug
//		M011	7-18-09	replace complex math unit with immediate math unit for ADI and CPI with 8-bit constants
//		M012	3-21-10	fix carry/zero enable logic
//		M013	3-25-10	change comparison op codes
//		M014	12-8-10	eliminated warnings for Spartan-6
//		M015	12-23-10	use A register in immediate operations by checking pdata[15] only (4->3 levels of logic)
//		M016	4-2-11	move LDH decode to CPU module
//		M017	9-15-11	infer divider components
//		M018	9-22-11	fix constant adder/subtractor (op field must be used to identify CPI instead of mod field)
//		M019	9-23-11	change register write enable logic
//		M020	10-22-11	move bank select logic to CPU module (was 313 LUT, 61 reg., 1 DSP48, 122MHz)
//		M021	10-31-11	remove 4 & 8-bit math and add 4-8-12-bit moves (was 311 LUT, 57 reg., 1 DSP48, 130MHz)
//		M022	11-5-11	change opcodes for CPU16D
//		M023	12-3-11	add SIZE instruction to mask register writes (was 347 LUT, 59 reg., 1 DSP48, 126MHz)
//		M024	3-21-12	add square root instruction
//		M025	4-8-12	add variable-length move and rotate inst., relocate LPL,LPH... and delete 4-8-12-bit moves
//		M026	4-10-12	add variable-length sign extension and delete 4-8-12-bit insert/rotate instructions
//		M027	4-13-12	remove ABS and replace M register with A1 and B1 registers in multiplier to reduce delays
//		M028	4-14-12	fix shift carry out
//		M029	4-29-12	external input/read instruction decode
//		M030	5-10-12	fix overflow for subtract and add sign flag
//
module ALU16 (
    output [15:0] a,b,				// data from registers A and B
	 input [15:0] d0,d1,				// data from I/O ports
	 input [15:0] m0,m1,m2,m3,		// data from memory
	 input inrd,						// input or read instruction (write register)
	 input hv,							// LDH instruction detected
	 input [7:0] h8,					// LDH data
	 input [1:0] rs,					// register bank selection
	 input [15:0] pdata,				// instruction
	 output zero,carry,ovflo,sign,// zero, carry, overflow and sign flags for math and shift operations
	 input clk,rst						// clock and reset for flags, multiplier, divider and square root logic
	 );
// multiplier/divider generation control
`define muldiv
// internal signals
wire [15:0] c;		// 16-bit constant or sign extended 8-bit constant
wire sbr,sbi;		// register subtract or immediate subtract
wire cp;				// propogate carry flag
wire co,coi;		// carry out bit adder/subtractor
reg ci;				// carry flag for adder/subtractor/shifter
wire vr,vi;			// register and immediate arithmetic overflow
reg s,v;				// sign flag and overflow flag
wire zr,zi;			// zero detector outputs
wire z;				// arithmetic zero flag
wire zen,cen,ven;	// enable zero flag, carry flag or overflow flag
wire [3:0] bitsel;// bit select
wire bitmux;		// selected bit
wire sv;				// shift enable
wire si;				// shift end bit
wire [3:0] fsel;	// function multiplexer select input
wire [15:0] f0,f1,f2,f3,f4,f5,f6,f7;	// ALU functional unit outputs
wire [15:0] f;		// function multiplexer output
wire mvi,adi,cpi,cmp,tst,mv,dv,rv,csr,zsr;	// decoded operations
wire math,logop,shiftop,imath,rmath,shift,lpqr,rot,sex;
wire aluop;			// ALU operations
wire vmov;			// variable-length move instruction decoded
wire wo;				// register write operation decoded
wire [15:1] wm;	// write mask for top 15 bits
wire [15:0] we;	// write to register A (by bit)
wire [1:0] typ;	// instruction type
wire [2:0] op,mod;// ALU operation and modifier
wire [3:0] aa,ab;	// register address fields
// assign fields for load and data manipulation instuctions
assign aa = pdata[3:0];						// A register address
assign ab = pdata[7:4];						// B register address
assign mod = pdata[10:8];					// operation modifier
assign op = pdata[13:11];					// operation code field
assign typ = pdata[15:14];					// instruction type field
assign c[7:0] = pdata[11:4];				// 8-bit constant field
// decode write-only operations
assign mvi = (typ == 1) & (op[2:1] == 2'b01);				// move immediate data
assign adi = (typ == 1) & (op[2:1] == 2'b10);				// add immediate data
assign cpi = (typ == 1) & (op[2:1] == 2'b11);				// compare immediate data
assign mv = (typ == 3) & (op == 5);								// multiply operations
assign dv = (typ == 3) & (op == 6) & (mod[2:1] == 0);		// divide operations (mod = 0 or 1)
assign rv = (typ == 3) & (op == 6) & (mod == 2);			// square root operation
assign tst = (typ == 3) & (op == 6) & (mod == 4);			// bit testing operations
assign csr = (typ == 3) & (op == 6) & (mod == 6) & ~c[1]; // carry bit operations
assign zsr = (typ == 3) & (op == 6) & (mod == 6) & c[1];	// zero bit operations
assign cmp = (typ == 3) & (op == 6) & (mod[1:0] == 3);	// comparison operations (mod = 3 or 7)
assign math = (typ == 3) & (op == 0);							// register absv/negate/add/subtract operations
assign logop = (typ == 3) & (op == 1);							// register logical operations
assign shiftop = (typ == 3) & (op == 4);						// register shift operations
assign shift = (typ == 3) & (op == 4) & (mod[2:1] == 2'b11); // shift left/right
assign aluop = (typ == 3) & (op != 5) & (op[2:1] != 2'b11);	// ALU read/write operation
assign vmov = (typ == 3) & (op[2:1] == 1);					// insert instruction (Dx)
assign lpqr = (typ == 3) & (op == 7) & (mod == 5);			// load mul/div/sqrt results (FD)
assign rot = (typ == 3) & (op == 7) & (mod == 6);			// rotate operations (FE)
assign sex = (typ == 3) & (op == 7) & (mod == 7);			// sign extension operations (FF)
// ALU does arithmetic, logical and shifting operations in 1 clock cycle
// 16-bit constant created by concatenating HD and immediate data field from next instruction
// else 8-bit constant sign extended to 16 bits
assign c[15:8] = hv ? h8 : {c[7],c[7],c[7],c[7],c[7],c[7],c[7],c[7]};
// Dual-port memory containing data (A/B) and address (B) registers
// update registers on all ALU operations except memory writes and
// on move and add immediate instructions (2nd cycle of memory reads)
assign wo = mvi | adi | inrd | aluop | lpqr | rot | sex;
assign we = {wo,wo,wo,wo,wo,wo,wo,wo,wo,wo,wo,wo,wo,wo,wo,wo};
// dual-port register file grouped into four 16-word banks selected by rs
// A and B outputs feed ALU logic and A input is ALU output or memory output (F)
RAM64X16D16W regfile (
	.AA({rs,aa}),	// 1st operand address
	.AB({rs,ab}),	// 2nd operand address
	.DA(f),			// 1st operand input
	.YA(a),			// 1st operand output
	.YB(b),			// 2nd operand output
	.WE(we),			// write results to high aand low bytes
	.WCLK(clk)		// write clock (read is asynchronous)
	);
// 16-bit adder or subtractor using registers A and B or B only
// propogate carry only for register-to-register math
assign sbr = mod[0];
assign cp = (op == 0) & mod[2];
addsubmovneg16a aur (
	.A(a),					// accumulator register
	.B(b),					// another register
	.CI(cp ? ci : sbr),	// carry input is zero or previous output
	.CO(co),					// carry output
	.SUB(sbr),				// select add (0) or subtract (1)
	.ENA(mod[1]),			// select zero or A input
	.Y(f0)					// result
	);
// detect overflow and zero output
assign vr = (a[15] & (sbr ^ b[15]) & ~f0[15])|(~a[15] & (sbr ^ ~b[15]) & f0[15]);
zero16 zdr (
	.A(f0),
	.Y(zr)
	); 
// carry flag is set/reset by carry out bit during register-to-register math
// carry flag is set/reset by bit multiplexer data when shifting or testing bits
// check for zero and 2's complement overflow during 16-bit math
assign rmath = cmp | math;			// register to register math operations
assign imath = adi|cpi;				// immediate data to register math operations
assign sv = tst | shift;			// bit manipulation operations
assign cen = rmath|imath|sv|csr;	// enable carry FF
assign zen = rmath|imath|zsr;		// enable zero FF
assign ven = rmath|imath;			// enable overflow FF
always @ (posedge clk)
begin
	if (cen) ci <= (rmath & co)|(imath & coi)|(sv & bitmux)|(csr & c[0]);	// carry out or shift out
	if (ven) v <= (rmath & vr)|(imath & vi);				// overflow
	if (ven) s <= (rmath & f0[15])|(imath & f5[15]);	// sign
end
// zero flag input multiplexer must be instantiated to get minimum delay
MUX4S zf (.D({c[0],c[0],zr,zi}), .S({zsr,rmath}), .Q(z), .CE(zen), .CLK(clk), .RST(rst));
assign carry = ci;
assign zero = z;
assign ovflo = v;
assign sign = s;
// 16-bit adder or subtractor using register A and constant
assign sbi = op[2] & op[1];	// detect CPI (01 11X)
addsubmovneg16a aui (
	.A(a),			// accumulator
	.B(c),			// constant
	.CI(sbi),		// set carry for subtract
	.CO(coi),
	.SUB(sbi),		// subtract during comparison
	.ENA(op[2]),	// add to zero for move immediate (01 01X)
	.Y(f5)
	);
// detect overflow and zero output
assign vi = (a[15] & (sbi ^ c[15]) & ~f5[15])|(~a[15] & (sbi ^ ~c[15]) & f5[15]);
zero16 zdi (
	.A(f5),
	.Y(zi)
	);
// logical operations on one bit in register A - bit select, reset, set or toggle
lu16a lu (
	.a(a),
	.b(b),
	.c(c[3:0]),
	.op(mod),
	.y(f1)
	);
// rotate multiplexers
wire [15:0] i;	// intermediate results
MUX4X16 rmux1 (
	.D0(a),						// no change
	.D1({a[0],a[15:1]}),		// rotate right 1 bits
	.D2({a[1:0],a[15:2]}),	// rotate right 2 bits
	.D3({a[2:0],a[15:3]}),	// rotate right 3 bits
	.S(ab[1:0]),
	.Y(i)
	);
MUX4X16 rmux4 (
	.D0(i),							// no change
	.D1({i[3:0],i[15:4]}),		// rotate right 4 bits
	.D2({i[7:0],i[15:8]}),		// rotate right 8 bits
	.D3({i[11:0],i[15:12]}),	// rotate right 12 bits
	.S(ab[3:2]),
	.Y(f2)
	);
// sign extend logic uses 1 LUT6 perbit plus one sign bit multiplexer
wire [3:0] spos;	// sign bit position
wire sbit;			// selected sign bit
assign spos = c[3:0];
MUX16 sxm (.D(a), .S(spos), .Y(sbit));		// get sign bit
assign f3[0] = a[0];								// bit 0
assign f3[1] = (spos < 1) ? sbit : a[1];	// bit 1
assign f3[2] = (spos < 2) ? sbit : a[2];	// bit 2
assign f3[3] = (spos < 3) ? sbit : a[3];	// bit 3
assign f3[4] = (spos < 4) ? sbit : a[4];	// bit 4
assign f3[5] = (spos < 5) ? sbit : a[5];	// bit 5
assign f3[6] = (spos < 6) ? sbit : a[6];	// bit 6
assign f3[7] = (spos < 7) ? sbit : a[7];	// bit 7
assign f3[8] = (spos < 8) ? sbit : a[8];	// bit 8
assign f3[9] = (spos < 9) ? sbit : a[9];	// bit 9
assign f3[10] = (spos < 10) ? sbit : a[10];	// bit 10
assign f3[11] = (spos < 11) ? sbit : a[11];	// bit 11
assign f3[12] = (spos < 12) ? sbit : a[12];	// bit 12
assign f3[13] = (spos < 13) ? sbit : a[13];	// bit 13
assign f3[14] = (spos < 14) ? sbit : a[14];	// bit 14
assign f3[15] = (spos < 15) ? sbit : a[15];	// bit 15
// insert logic replaces 1-16 LS bits in A with bits from B
wire [3:0] size;			// field size to insert
assign size = c[7:4];	// comes from bits 11-8 of instruction
assign f7[0] = b[0];								// bit 0
assign f7[1] = (size < 1) ? a[1] : b[1];	// bit 1
assign f7[2] = (size < 2) ? a[2] : b[2];	// bit 2
assign f7[3] = (size < 3) ? a[3] : b[3];	// bit 3
assign f7[4] = (size < 4) ? a[4] : b[4];	// bit 4
assign f7[5] = (size < 5) ? a[5] : b[5];	// bit 5
assign f7[6] = (size < 6) ? a[6] : b[6];	// bit 6
assign f7[7] = (size < 7) ? a[7] : b[7];	// bit 7
assign f7[8] = (size < 8) ? a[8] : b[8];	// bit 8
assign f7[9] = (size < 9) ? a[9] : b[9];	// bit 9
assign f7[10] = (size < 10) ? a[10] : b[10];	// bit 10
assign f7[11] = (size < 11) ? a[11] : b[11];	// bit 11
assign f7[12] = (size < 12) ? a[12] : b[12];	// bit 12
assign f7[13] = (size < 13) ? a[13] : b[13];	// bit 13
assign f7[14] = (size < 14) ? a[14] : b[14];	// bit 14
assign f7[15] = (size < 15) ? a[15] : b[15];	// bit 15
// Select bits to test or append to shifted word, op[1] is 0 for SHL/SHR and 1 for TST (M028)
assign bitsel = op[1] ? c[3:0] : {c[0],c[0],c[0],c[0]};	// select bit 0 or 15 when shifting
MUX16 smux1 (
	.D(a),		// sample reg. A bits
	.S(bitsel),	// select bit
	.Y(bitmux)	// output to carry flag
	);
// shift logic for end bits
MUX4 smux16 (
	.D({c[1],ci,a[15],a[0]}),	// select 0, 1, carry bit, bit 15 or bit 0 (M009)
	.S(c[3:2]),						// inst. bits 7-6 select shifter input
	.Y(si)
	);
// shift multiplexer
MUX8X16 dmux (
	.D0({b[7],b[7],b[7],b[7],b[7],b[7],b[7],b[7],b[7:0]}),				// extend sign of LSB to MSB
	.D1({b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15:8]}),	// move MSB to LSB & extend sign
	.D2({b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15],b[15]}),
	.D3({8'h00,b[7:0]}),		// zero MSB
	.D4({8'h00,b[15:8]}),	// move MSB to LSB and zero MSB
	.D5({b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]}),
	.D6({si,a[15:1]}),	// shift right by 1 bit
	.D7({a[14:0],si}),	// shift left by 1 bit
	.S(mod[2:0]),
	.Y(f4)
	);
// output multiplexer - use optimized multiplxers
wire [2:0] mop;	// modified op code for rotate and load mul/div/sqrt results
assign mop[0] = logop|sex|mvi|adi|cpi|vmov;
assign mop[1] = rot|sex|lpqr|vmov;
assign mop[2] = shiftop|mvi|adi|cpi|lpqr|vmov;
assign fsel = inrd ? {1'b1,op[1] ? {1'b1,b[15:14]} : {2'b01,pdata[11]}} : {1'b0,mop};
MUX16X16 fmux (
	.D0(f0),		// register arithmetic (math)
	.D1(f1),		// logic (logop)
	.D2(f2),		// rotate (rot)
	.D3(f3),		// sign extension (sex)
	.D4(f4),		// shift (shiftop)
	.D5(f5),		// immediate arithmetic (mvi|adi|cpi)
	.D6(f6),		// multiply/divide results (lpqr)
	.D7(f7),		// insert (vmov)
	.D8(16'h0000),
	.D9(16'h0000),
	.D10(d0),	// I/O ports 0-127
	.D11(d1),	// I/O ports 128-255
	.D12(m0),	// memory 0000-3FFF
	.D13(m1),	// memory 4000-7FFF
	.D14(m2),	// memory 8000-BFFF
	.D15(m3),	// memory C000-FFFF
	.S(fsel),
	.Y(f)
	);
// select whether multiplier and divider are generated
`ifdef muldiv
// internal signals
wire [47:0] sp;			// sum of products
wire [15:0] q,r,sq,sr;	// quotient and remainder from divider & square root
// 16-bit multiplier/accumulator
// MOD  INST.  DESCRIPTION
//  0   UMUL   Unsigned Multiply
//  1   USML   Unsigned x Signed Multiply (was UMLN)
//  2   UMAC   Unsigned Multiply-Accumulate
//  3   UMSB   Unsigned Multiply-Subtract
//  4   MUL    Signed Multiply
//  5   SUML   Signed x Unsigned Multiply (was MULN)
//  6   MAC    Signed Multiply-Accumulate
//  7   MSUB   Signed Multiply-Subtract
// registers on inputs to accumulator with unregistered output to CPU A register
wire acc,sub,sa,sb;				// MAC control signals
assign acc = mod[1];				// accumulator enabled if mod = 2, 3, 6 or 7
assign sub = (mod[1:0] == 3);	// subtract if mod = 3 or 7
assign sa = mod[2] & a[15];	// signed A input if mod = 4, 5, 6 or 7
assign sb = (mod[2]^(mod[1:0]==1)) & b[15];	// signed B in. if mod = 1, 4, 6 or 7
DSP48A1 #(
	.A0REG(0),
	.A1REG(1),		// use second multiplier input register
	.B0REG(0),
	.B1REG(1),
	.CREG(1),		// use as accumulator input register for feedback
	.DREG(0),
	.MREG(0),
	.PREG(0),		// don't use accumulator output register
	.CARRYINSEL("OPMODE5"),
	.CARRYINREG(0),
	.CARRYOUTREG(0),
	.OPMODEREG(1),	// latch MAC mode with inputs (A & B) and feedback (C)
	.RSTTYPE("SYNC")
	) mul0 (
//	.OPMODE({sub,1'b0,sub,1'b0,acc,acc,2'b01}),	// select mode
	.OPMODE({sub,3'b000,acc,acc,2'b01}),	// select mode
	.A({sa,sa,a}),	// expand 16-bit inputs to 18 bits by putting
	.B({sb,sb,b}),	// sign bits (if any) into top two bits
	.BCOUT(),
	.C(sp),			// feedback from accumulator output
	.D(18'b000000000000000000),
	.M(),
	.CARRYIN(1'b0),
	.CARRYOUT(),
	.CARRYOUTF(),
	.PCIN(48'h000000),
	.PCOUT(),
	.P(sp),
	.CLK(clk),
	.CEA(mv),		// latch multiplier inputs
	.CEB(mv),
	.CEC(mv),		// latch sum of products in C register
	.CED(1'b1),
	.CEM(1'b1),
	.CEP(1'b1),
	.CECARRYIN(1'b1),
	.CEOPMODE(mv),	// latch MAC mode
	.RSTA(1'b0),
	.RSTB(1'b0),
	.RSTC(1'b0),
	.RSTD(1'b0),
	.RSTM(1'b0),
	.RSTP(1'b0),
	.RSTCARRYIN(1'b0),
	.RSTOPMODE(1'b0)
	);
// 16-bit divider
div16a div (
	.ain(a),			// numerator and denominator input
	.bin(b),
	.iv(dv),			// load data and start
	.mod(mod[0]),	// 1=division with remainder, 0=generate fractional remainder
	.qout(q),		// quotient
	.rout(r),		// remainder
	.ov(),			// overflow unused
	.clk(clk),
	.rst(rst)
	);
// 16-bit square root
sqrt16a sqrt (
	.dh(a),			// radicand upper 16 bits
	.dl(b),			// radicand lower 16 bits
	.size(1'b1),	// 0=16-bits, 1=32-bits
	.iv(rv),			// load data and start
	.qout(sq),		// root
	.rout(sr),		// remainder
	.ov(),			// output ready
	.clk(clk), 
	.rst(rst) 
	);
// Retreive product, quotient and root (uses opcode $FD w/B selecting reg.)
// input selected by register B field or set to port 7 for variable-length moves
MUX8X16 pqrmux (
	.D0(sp[15:0]),		// LSW sum of products
	.D1(sp[31:16]),	// MSW sum of products
	.D2(q),				// quotient
	.D3(r),				// remainder
	.D4(sq),				// square root
	.D5(sr),				// remainder
	.D6(sp[30:15]),	// fractional product
	.D7(16'hFFFF),		// unused
	.S(ab[2:0]),
	.Y(f6)
	);
`else
// No multipler or divider or square root
assign f6 = 16'hFFFF;
`endif
endmodule

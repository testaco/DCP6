//
//					  PC14.v - 14-bit Program Flow Controller
//
//					(C) Copyright 2007-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This unit consists of a program counter (PC), return address stack, stack pointer (SP)
// and associated logic used to control program flow in a microcontroller. It recognizes
// the jump, call, return and repeat instructions. Instruction formats are:
//
//		 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 0   0 |                   Absolute Address                    | Call
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 0   1 | 0   0 |       Relative Address        |   Condition   | Jump
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1 | 1   0   0   0 |               |   Condition   | Return
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1 | 1   0   0   1 |               |       A       | Set return addr. 
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//		| 1   1 | 1   1 | 1   0   1   0 |             Count             | Repeat
//		+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
//
//		C = flag condition (0=true, 1=false)
//
// Since the instruction ROM has a 1 clock delay, the PC always contains the address of
// the next instruction in sequence. This is used to advantage when storing the return
// address. The PC is bypassed on jumps, calls and returns to eliminate this delay and
// the PC is loaded with the address of the instruction following the return.
//
// S6: 101 LUT6s and 37 registers used. 154 MHz maximum clock rate. Maximum delay is
// incrementing program counter.
//
// History:
//		M001	5-31-08	conditional call and return
//		M002	8-5-08	16-bit format - add mark and loop, rel. jump only, remove cond. call
//		M003	8-26-08	modify encoding to allow future use of 3-bit condition code
//		M004	8-29-08	allow 9-bit relative address
//		M005	2-25-09	add suport for 2-cycle instructions
//		M006	3-26-09	make program memory external
//		M007	7-14-09	add STRA instruction
//		M008	12-8-10	eliminated repeat counter truncation warnings for Spartan-6
//		M009	12-9-10	changed condition code logic to use LUT6 and XOR
//		M010	12-18-10	increased stack to 32 entries
//		M011	4-2-11	allow use of LDH to extend offset in relative jumps
//		M012	10-22-11	four 16-entry return address stacks (was 102 LUT, 57 reg., 153 MHz)
//		M013	11-5-11	8-bit displacement for jump instructions (CPU16D inst. set)
//		M014	12-20-11	process Z and C flags to provide > and <= conditions (1 less LUT)
//		M015	5-10-12	add conditional jumps and returns using sign flag (new coding)
//
module PC14 (
	 output [13:0] paddr,	// program address
	 input [15:0] pdata,		// program data
	 input [13:0] rdata,		// register A data
	 input z,c,v,s,			// zero, carry, overflow and sign flags from ALU
	 input hv,					// LDH detected
	 input [5:0] h6,			// LDH data
	 input [1:0] ss,			// stack select
	 input ce,					// PC count enable 
	 input clk,					// master clock
	 input rst					// reset PC and SP
	 );
// internal signals
reg [13:0] pc,ra;							// program counter and return address registers
wire [13:0] pcin;							// program counter input
wire [1:0] sel;							// select address input
wire inc;									// increment program counter
wire [3:0] sp,sp1;						// stack pointer (M012)
wire push,pop;								// push or pop stack (increment or decrement)
reg push1;									// delayed write strobe for stack
wire call,jmp,ret,rpt,stra;			// PC control instructions
wire [13:0] addr,absaddr,retaddr;	// absolute addresses
wire [8:0] reladdr;						// relative address
wire [5:0] msaddr;						// most significant address bits
wire [1:0] flag;							// selects flag to test
wire [3:0] cond;							// jump/call/return condition field
wire fv,jmpv,retv;						// selected condition true
reg [7:0] count;							// repeat counter
wire zero;									// counter is zero
// instuction fields
assign call = (pdata[15:14] == 2'b00);			// call instruction decoded
assign jmp = (pdata[15:12] == 4'b0100);		// jump instruction group
assign ret = (pdata[15:8] == 8'b11111000);	// return instruction decoded
assign stra = (pdata[15:8] == 8'b11111001);	// STRA instructions decoded
assign rpt = (pdata[15:8] == 8'b11111010);	// repeat instruction decoded
assign cond = pdata[3:0];							// flag select (jump/return condition)
assign reladdr = pdata[11:4];						// jump address
assign absaddr = pdata[13:0];						// call address
// process condition code
//		 0 = always
//		 1 = overflow (V=1)
//		 2 = A > B (C=1 and Z=0)
//		 3 = A <= B (C=0 or Z=1)
//		 4 = A = B (Z=1)
//		 5 = A != B (Z=0)
//		 6 = A >= B (C=1)
//		 7 = A < B (C=0)
//		 8 = A = + (S=0 and Z=0)
//		 9 = A = - (S=1)
//		10 = A > B (Z or (S xor V) = 0)
//		11 = A <= B (Z or (S xor V) = 1)
//		12 = A = 0+ (S=0)
//		13 = A = 0- (S=1 or Z=1)
//		14 = A >= B (S xor V = 0)
//		15 = A < B (S xor V = 1)
assign fv = (cond == 0) | ((cond == 1) & v) |
				((cond == 2) & (c & ~z)) | ((cond == 3) & (z | ~c)) | 
				((cond == 4) & z) | ((cond == 5) & ~z) |
				((cond == 6) & c) | ((cond == 7) & ~c) |
				((cond == 8) & (~s & ~z)) | ((cond == 9) & s) | 
				((cond == 10) & ~(z|(s^v))) | ((cond == 11) & (z|(s^v))) | 
				((cond == 12) & ~s) | ((cond == 13) & (s | z)) | 
				((cond == 14) & ~(s^v)) | ((cond == 15) & (s^v)) ; 
assign retv = ret & fv;
assign jmpv = jmp & fv;
// select source of next address:
// 0 = PC, 1 = relative address, 2 = absolute address, 3 = address from stack
assign sel[0] = jmpv | retv;
assign sel[1] = call | retv;
// calculate absolute address from relative address
assign msaddr = hv ? h6 : {reladdr[7],reladdr[7],reladdr[7],reladdr[7],reladdr[7],reladdr[7]};
assign addr = pc + {msaddr,reladdr[7:0]};
// program counter - increment, except when program flow instruction decoded
// select jump/call address or return address
MUX4X14 pcimux (
	.D0(pc),			// increment
	.D1(addr),		// jump
	.D2(absaddr),	// call
	.D3(retaddr),	// return
	.S(sel),
	.Y(pcin)
	);
// PC is always current address plus one
always @ (posedge clk)
begin
	if (rst) pc <= 14'b00000000000000;					// reset PC
	else if (inc) pc <= pcin + 14'b00000000000001;	// increment PC
end
assign inc = ce & zero & ~rpt;	// count up when repeat instruction inactive and not memory read
// select PC as program address unless jump/call/return valid
MUX4X14 pcomux (
	.D0(pc),			// increment
	.D1(addr),		// jump
	.D2(absaddr),	// call
	.D3(retaddr),	// return
	.S(sel),
	.Y(paddr)
	);
// stack - push on call and pop on return
assign push = call|stra;	// push during call or set return address instructions
assign pop = ret & fv;		// pop on successful return instruction
// stack write delayed 1 clock cycle to allow stack pointer increment
always @ (posedge clk)
begin
	push1 <= push;					// delayed stack write enable
	ra <= stra ? rdata : pc;	// delay data from register or PC for stack push (M009)
end
// 4 stack pointers - increment on call and decrement on return
// pre-increment on write and post-decrement on read
assign sp1 = sp + {pop,pop,pop,pop|push};
RAM32X4SP spram (
	.A({3'b000,ss}),	// bottom 2 bits for switching context
	.D(sp1),				// next SP contents if pushed or popped
	.O(sp),
	.WE(pop|push),		// write if call or return instruction
	.WCLK(clk)
	);
// 4 return address stacks (M010)
RAM64X14S stack (
	.A({ss,sp}),	// top 2 bits for switching context
	.D(ra),			// RA used to delay PC+1 until write
	.O(retaddr),
	.WE(push1),
	.WCLK(clk)
	);
// Repeat counter - inhibits incrementing of program counter
always @ (posedge clk)
begin
	if (rst) count <= 0;								// reset on power-up
	else if (rpt) count <= reladdr[7:0];		// load on repeat instruction
	else if (~zero) count <= count - 8'h01;	// count down when not zero
end
assign zero = ~|count;	// detect all zeros
endmodule

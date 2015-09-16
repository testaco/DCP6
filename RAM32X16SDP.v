//
//			RAM32X16SDP - Dual-Port Distributed RAM - 32 16-bit words
//
//					(C) Copyright 2007-2011 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	This RAM has one write port and 2 read ports and occupies 16 slices.
// Port A is read/write and port B is read only. Reading is asynchronous
// and writing is synchronous to WCLK when WEL or WEH are true.
//
// Uses 3 Spartan-6 simple-dual-port distributed RAMs.
//
module RAM32X16SDP(WADDR, RADDR, DI, DO, WE, WCLK);
    input [4:0] WADDR;		// port A address
    input [4:0] RADDR;		// port B address
    input [15:0] DI;		// port A data input
    output [15:0] DO;	// port B data output
    input WE;				// write enable for port A
    input WCLK;			// write clock for port A
// Use 3 RAM32X6SDP
wire [17:12] d;	// top six bits of RAM output port
RAM32X6SDP ram0 (.WADDR(WADDR), .DI(DI[5:0]), .WE(WE), .WCLK(WCLK), .RADDR(RADDR), .DO(DO[5:0]));
RAM32X6SDP ram1 (.WADDR(WADDR), .DI(DI[11:6]), .WE(WE), .WCLK(WCLK), .RADDR(RADDR), .DO(DO[11:6]));
RAM32X6SDP ram2 (.WADDR(WADDR), .DI({2'b00,DI[15:12]}), .WE(WE), .WCLK(WCLK), .RADDR(RADDR), .DO(d[17:12]));
assign DO[15:12] = d[15:12];	// d[17:16] unused
endmodule

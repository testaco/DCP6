//
//			RAM32X6SDP - Dual-Port Distributed RAM - 32 6-bit words
//
//					(C) Copyright 2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	This RAM has one write port and one read port. Reading is asynchronous
// and writing is synchronous to WCLK when WE is true.
//
module RAM32X6SDP(RADDR, WADDR, DI, DO, WE, WCLK);
    input [4:0] RADDR;	// read address
    input [4:0] WADDR;	// write address
    input [5:0] DI;		// data input
    output [5:0] DO;		// data output
    input WE;				// write enables for port A MSB and LSB
    input WCLK;			// write clock for port A
// Wire RAM32M ports
RAM32M ram (
	.DIA(DI[1:0]),
	.DOA(DO[1:0]),
	.ADDRA(RADDR),
	.DIB(DI[3:2]),
	.DOB(DO[3:2]),
	.ADDRB(RADDR),
	.DIC(DI[5:4]),
	.DOC(DO[5:4]),
	.ADDRC(RADDR),
	.DID(2'b00),
	.DOD(),
	.ADDRD(WADDR),
	.WE(WE),
	.WCLK(WCLK)
	);
endmodule

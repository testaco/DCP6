//
//			RAM64X16D16W - Dual-Port Distributed RAM - 64 16-bit words
//
//					(C) Copyright 2010 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
//	This RAM has one write port and 2 read ports and occupies 8 slices.
// Port A is read/write and port B is read only. Reading is asynchronous
// and writing is synchronous to WCLK when WE is true. The word length is
// variable from 4 to 16 bits on write and all bits are right justified.
//
module RAM64X16D16W (
    input [5:0] AA,		// port A address
    input [5:0] AB,		// port B address
    input [15:0] DA,		// port A data input
    output [15:0] YA,	// port A data output
    output [15:0] YB,	// port B data output
    input [15:0] WE,		// write enables for port A
    input WCLK				// write clock for port A
	 );
// Use 16 RAM64X1D
RAM64X1D ram0 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[0]), .WE(WE[0]), .WCLK(WCLK), .SPO(YA[0]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[0]));
RAM64X1D ram1 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[1]), .WE(WE[1]), .WCLK(WCLK), .SPO(YA[1]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[1]));
RAM64X1D ram2 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[2]), .WE(WE[2]), .WCLK(WCLK), .SPO(YA[2]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[2]));
RAM64X1D ram3 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[3]), .WE(WE[3]), .WCLK(WCLK), .SPO(YA[3]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[3]));
RAM64X1D ram4 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[4]), .WE(WE[4]), .WCLK(WCLK), .SPO(YA[4]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[4]));
RAM64X1D ram5 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[5]), .WE(WE[5]), .WCLK(WCLK), .SPO(YA[5]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[5]));
RAM64X1D ram6 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[6]), .WE(WE[6]), .WCLK(WCLK), .SPO(YA[6]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[6]));
RAM64X1D ram7 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[7]), .WE(WE[7]), .WCLK(WCLK), .SPO(YA[7]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[7]));
RAM64X1D ram8 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[8]), .WE(WE[8]), .WCLK(WCLK), .SPO(YA[8]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[8]));
RAM64X1D ram9 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[9]), .WE(WE[9]), .WCLK(WCLK), .SPO(YA[9]),
					.DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[9]));
RAM64X1D ram10 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[10]), .WE(WE[10]), .WCLK(WCLK), .SPO(YA[10]),
					 .DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[10]));
RAM64X1D ram11 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[11]), .WE(WE[11]), .WCLK(WCLK), .SPO(YA[11]),
					 .DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[11]));
RAM64X1D ram12 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[12]), .WE(WE[12]), .WCLK(WCLK), .SPO(YA[12]),
					 .DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[12]));
RAM64X1D ram13 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[13]), .WE(WE[13]), .WCLK(WCLK), .SPO(YA[13]),
					 .DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[13]));
RAM64X1D ram14 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[14]), .WE(WE[14]), .WCLK(WCLK), .SPO(YA[14]),
					 .DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[14]));
RAM64X1D ram15 (.A0(AA[0]), .A1(AA[1]), .A2(AA[2]), .A3(AA[3]), .A4(AA[4]), .A5(AA[5]), .D(DA[15]), .WE(WE[15]), .WCLK(WCLK), .SPO(YA[15]),
					 .DPRA0(AB[0]), .DPRA1(AB[1]), .DPRA2(AB[2]), .DPRA3(AB[3]), .DPRA4(AB[4]), .DPRA5(AB[5]), .DPO(YB[15]));
endmodule

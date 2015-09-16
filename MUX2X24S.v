//
//						 2 x 24-bit Multiplexer with Latch
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module MUX2X24S(D0, D1, S, Q, CE, CLK, RST);
    input [23:0] D0,D1;	// input ports
    input S;				// select input
    output [23:0] Q;		// output port
	 input CE;				// clock enable
	 input CLK;				// clock output latch
	 input RST;				// reset output latch
// 12 copies of MUX2X2S
MUX2X2S mux0 (.D0(D0[1:0]), .D1(D1[1:0]), .S(S), .Q(Q[1:0]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux1 (.D0(D0[3:2]), .D1(D1[3:2]), .S(S), .Q(Q[3:2]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux2 (.D0(D0[5:4]), .D1(D1[5:4]), .S(S), .Q(Q[5:4]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux3 (.D0(D0[7:6]), .D1(D1[7:6]), .S(S), .Q(Q[7:6]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux4 (.D0(D0[9:8]), .D1(D1[9:8]), .S(S), .Q(Q[9:8]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux5 (.D0(D0[11:10]), .D1(D1[11:10]), .S(S), .Q(Q[11:10]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux6 (.D0(D0[13:12]), .D1(D1[13:12]), .S(S), .Q(Q[13:12]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux7 (.D0(D0[15:14]), .D1(D1[15:14]), .S(S), .Q(Q[15:14]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux8 (.D0(D0[17:16]), .D1(D1[17:16]), .S(S), .Q(Q[17:16]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux9 (.D0(D0[19:18]), .D1(D1[19:18]), .S(S), .Q(Q[19:18]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux10 (.D0(D0[21:20]), .D1(D1[21:20]), .S(S), .Q(Q[21:20]), .CE(CE), .CLK(CLK), .RST(RST));
MUX2X2S mux11 (.D0(D0[23:22]), .D1(D1[23:22]), .S(S), .Q(Q[23:22]), .CE(CE), .CLK(CLK), .RST(RST));
endmodule

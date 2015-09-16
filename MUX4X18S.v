//
//						 4 x 18-bit Multiplexer with Latch
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module MUX4X18S(D0, D1, D2, D3, S, Q, CE, CLK, RST);
    input [17:0] D0,D1,D2,D3;	// input ports
    input [1:0] S;				// select input
    output [17:0] Q;				// output port
	 input CE;						// clock enable
	 input CLK;						// clock output latch
	 input RST;						// reset output latch
// 16 copies of MUX4S
MUX4S mux0 (.D({D3[0],D2[0],D1[0],D0[0]}), .S(S), .Q(Q[0]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux1 (.D({D3[1],D2[1],D1[1],D0[1]}), .S(S), .Q(Q[1]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux2 (.D({D3[2],D2[2],D1[2],D0[2]}), .S(S), .Q(Q[2]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux3 (.D({D3[3],D2[3],D1[3],D0[3]}), .S(S), .Q(Q[3]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux4 (.D({D3[4],D2[4],D1[4],D0[4]}), .S(S), .Q(Q[4]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux5 (.D({D3[5],D2[5],D1[5],D0[5]}), .S(S), .Q(Q[5]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux6 (.D({D3[6],D2[6],D1[6],D0[6]}), .S(S), .Q(Q[6]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux7 (.D({D3[7],D2[7],D1[7],D0[7]}), .S(S), .Q(Q[7]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux8 (.D({D3[8],D2[8],D1[8],D0[8]}), .S(S), .Q(Q[8]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux9 (.D({D3[9],D2[9],D1[9],D0[9]}), .S(S), .Q(Q[9]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux10 (.D({D3[10],D2[10],D1[10],D0[10]}), .S(S), .Q(Q[10]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux11 (.D({D3[11],D2[11],D1[11],D0[11]}), .S(S), .Q(Q[11]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux12 (.D({D3[12],D2[12],D1[12],D0[12]}), .S(S), .Q(Q[12]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux13 (.D({D3[13],D2[13],D1[13],D0[13]}), .S(S), .Q(Q[13]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux14 (.D({D3[14],D2[14],D1[14],D0[14]}), .S(S), .Q(Q[14]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux15 (.D({D3[15],D2[15],D1[15],D0[15]}), .S(S), .Q(Q[15]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux16 (.D({D3[16],D2[16],D1[16],D0[16]}), .S(S), .Q(Q[16]), .CE(CE), .CLK(CLK), .RST(RST));
MUX4S mux17 (.D({D3[17],D2[17],D1[17],D0[17]}), .S(S), .Q(Q[17]), .CE(CE), .CLK(CLK), .RST(RST));
endmodule

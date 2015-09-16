//
//								8 x 16-bit Multiplexer
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module MUX8X16(D0, D1, D2, D3, D4, D5, D6, D7, S, Y);
    input [15:0] D0,D1,D2,D3,D4,D5,D6,D7;	// input ports
    input [2:0] S;								// select input
    output [15:0] Y;								// output port
// 16 copies of MUX8
MUX8 mux0 (.D({D7[0],D6[0],D5[0],D4[0],D3[0],D2[0],D1[0],D0[0]}), .S(S), .Y(Y[0]));
MUX8 mux1 (.D({D7[1],D6[1],D5[1],D4[1],D3[1],D2[1],D1[1],D0[1]}), .S(S), .Y(Y[1]));
MUX8 mux2 (.D({D7[2],D6[2],D5[2],D4[2],D3[2],D2[2],D1[2],D0[2]}), .S(S), .Y(Y[2]));
MUX8 mux3 (.D({D7[3],D6[3],D5[3],D4[3],D3[3],D2[3],D1[3],D0[3]}), .S(S), .Y(Y[3]));
MUX8 mux4 (.D({D7[4],D6[4],D5[4],D4[4],D3[4],D2[4],D1[4],D0[4]}), .S(S), .Y(Y[4]));
MUX8 mux5 (.D({D7[5],D6[5],D5[5],D4[5],D3[5],D2[5],D1[5],D0[5]}), .S(S), .Y(Y[5]));
MUX8 mux6 (.D({D7[6],D6[6],D5[6],D4[6],D3[6],D2[6],D1[6],D0[6]}), .S(S), .Y(Y[6]));
MUX8 mux7 (.D({D7[7],D6[7],D5[7],D4[7],D3[7],D2[7],D1[7],D0[7]}), .S(S), .Y(Y[7]));
MUX8 mux8 (.D({D7[8],D6[8],D5[8],D4[8],D3[8],D2[8],D1[8],D0[8]}), .S(S), .Y(Y[8]));
MUX8 mux9 (.D({D7[9],D6[9],D5[9],D4[9],D3[9],D2[9],D1[9],D0[9]}), .S(S), .Y(Y[9]));
MUX8 mux10 (.D({D7[10],D6[10],D5[10],D4[10],D3[10],D2[10],D1[10],D0[10]}), .S(S), .Y(Y[10]));
MUX8 mux11 (.D({D7[11],D6[11],D5[11],D4[11],D3[11],D2[11],D1[11],D0[11]}), .S(S), .Y(Y[11]));
MUX8 mux12 (.D({D7[12],D6[12],D5[12],D4[12],D3[12],D2[12],D1[12],D0[12]}), .S(S), .Y(Y[12]));
MUX8 mux13 (.D({D7[13],D6[13],D5[13],D4[13],D3[13],D2[13],D1[13],D0[13]}), .S(S), .Y(Y[13]));
MUX8 mux14 (.D({D7[14],D6[14],D5[14],D4[14],D3[14],D2[14],D1[14],D0[14]}), .S(S), .Y(Y[14]));
MUX8 mux15 (.D({D7[15],D6[15],D5[15],D4[15],D3[15],D2[15],D1[15],D0[15]}), .S(S), .Y(Y[15]));
endmodule

//
//								16 x 16-bit Multiplexer
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module MUX16X16(D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14,D15, S, Y);
    input [15:0] D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14,D15;	// input ports
    input [3:0] S;																		// select input
    output [15:0] Y;																		// output port
// 16 copies of MUX16
MUX16 mux0 (.D({D15[0],D14[0],D13[0],D12[0],D11[0],D10[0],D9[0],D8[0],D7[0],D6[0],D5[0],D4[0],D3[0],D2[0],D1[0],D0[0]}), .S(S), .Y(Y[0]));
MUX16 mux1 (.D({D15[1],D14[1],D13[1],D12[1],D11[1],D10[1],D9[1],D8[1],D7[1],D6[1],D5[1],D4[1],D3[1],D2[1],D1[1],D0[1]}), .S(S), .Y(Y[1]));
MUX16 mux2 (.D({D15[2],D14[2],D13[2],D12[2],D11[2],D10[2],D9[2],D8[2],D7[2],D6[2],D5[2],D4[2],D3[2],D2[2],D1[2],D0[2]}), .S(S), .Y(Y[2]));
MUX16 mux3 (.D({D15[3],D14[3],D13[3],D12[3],D11[3],D10[3],D9[3],D8[3],D7[3],D6[3],D5[3],D4[3],D3[3],D2[3],D1[3],D0[3]}), .S(S), .Y(Y[3]));
MUX16 mux4 (.D({D15[4],D14[4],D13[4],D12[4],D11[4],D10[4],D9[4],D8[4],D7[4],D6[4],D5[4],D4[4],D3[4],D2[4],D1[4],D0[4]}), .S(S), .Y(Y[4]));
MUX16 mux5 (.D({D15[5],D14[5],D13[5],D12[5],D11[5],D10[5],D9[5],D8[5],D7[5],D6[5],D5[5],D4[5],D3[5],D2[5],D1[5],D0[5]}), .S(S), .Y(Y[5]));
MUX16 mux6 (.D({D15[6],D14[6],D13[6],D12[6],D11[6],D10[6],D9[6],D8[6],D7[6],D6[6],D5[6],D4[6],D3[6],D2[6],D1[6],D0[6]}), .S(S), .Y(Y[6]));
MUX16 mux7 (.D({D15[7],D14[7],D13[7],D12[7],D11[7],D10[7],D9[7],D8[7],D7[7],D6[7],D5[7],D4[7],D3[7],D2[7],D1[7],D0[7]}), .S(S), .Y(Y[7]));
MUX16 mux8 (.D({D15[8],D14[8],D13[8],D12[8],D11[8],D10[8],D9[8],D8[8],D7[8],D6[8],D5[8],D4[8],D3[8],D2[8],D1[8],D0[8]}), .S(S), .Y(Y[8]));
MUX16 mux9 (.D({D15[9],D14[9],D13[9],D12[9],D11[9],D10[9],D9[9],D8[9],D7[9],D6[9],D5[9],D4[9],D3[9],D2[9],D1[9],D0[9]}), .S(S), .Y(Y[9]));
MUX16 mux10 (.D({D15[10],D14[10],D13[10],D12[10],D11[10],D10[10],D9[10],D8[10],D7[10],D6[10],D5[10],D4[10],D3[10],D2[10],D1[10],D0[10]}), .S(S), .Y(Y[10]));
MUX16 mux11 (.D({D15[11],D14[11],D13[11],D12[11],D11[11],D10[11],D9[11],D8[11],D7[11],D6[11],D5[11],D4[11],D3[11],D2[11],D1[11],D0[11]}), .S(S), .Y(Y[11]));
MUX16 mux12 (.D({D15[12],D14[12],D13[12],D12[12],D11[12],D10[12],D9[12],D8[12],D7[12],D6[12],D5[12],D4[12],D3[12],D2[12],D1[12],D0[12]}), .S(S), .Y(Y[12]));
MUX16 mux13 (.D({D15[13],D14[13],D13[13],D12[13],D11[13],D10[13],D9[13],D8[13],D7[13],D6[13],D5[13],D4[13],D3[13],D2[13],D1[13],D0[13]}), .S(S), .Y(Y[13]));
MUX16 mux14 (.D({D15[14],D14[14],D13[14],D12[14],D11[14],D10[14],D9[14],D8[14],D7[14],D6[14],D5[14],D4[14],D3[14],D2[14],D1[14],D0[14]}), .S(S), .Y(Y[14]));
MUX16 mux15 (.D({D15[15],D14[15],D13[15],D12[15],D11[15],D10[15],D9[15],D8[15],D7[15],D6[15],D5[15],D4[15],D3[15],D2[15],D1[15],D0[15]}), .S(S), .Y(Y[15]));
endmodule

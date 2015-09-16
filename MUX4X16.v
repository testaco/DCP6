//
//								4 x 16-bit Multiplexer
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
module MUX4X16(D0, D1, D2, D3, S, Y);
    input [15:0] D0,D1,D2,D3;	// input ports
    input [1:0] S;				// select input
    output [15:0] Y;				// output port
// 16 copies of MUX4
MUX4 mux0 (.D({D3[0],D2[0],D1[0],D0[0]}), .S(S), .Y(Y[0]));
MUX4 mux1 (.D({D3[1],D2[1],D1[1],D0[1]}), .S(S), .Y(Y[1]));
MUX4 mux2 (.D({D3[2],D2[2],D1[2],D0[2]}), .S(S), .Y(Y[2]));
MUX4 mux3 (.D({D3[3],D2[3],D1[3],D0[3]}), .S(S), .Y(Y[3]));
MUX4 mux4 (.D({D3[4],D2[4],D1[4],D0[4]}), .S(S), .Y(Y[4]));
MUX4 mux5 (.D({D3[5],D2[5],D1[5],D0[5]}), .S(S), .Y(Y[5]));
MUX4 mux6 (.D({D3[6],D2[6],D1[6],D0[6]}), .S(S), .Y(Y[6]));
MUX4 mux7 (.D({D3[7],D2[7],D1[7],D0[7]}), .S(S), .Y(Y[7]));
MUX4 mux8 (.D({D3[8],D2[8],D1[8],D0[8]}), .S(S), .Y(Y[8]));
MUX4 mux9 (.D({D3[9],D2[9],D1[9],D0[9]}), .S(S), .Y(Y[9]));
MUX4 mux10 (.D({D3[10],D2[10],D1[10],D0[10]}), .S(S), .Y(Y[10]));
MUX4 mux11 (.D({D3[11],D2[11],D1[11],D0[11]}), .S(S), .Y(Y[11]));
MUX4 mux12 (.D({D3[12],D2[12],D1[12],D0[12]}), .S(S), .Y(Y[12]));
MUX4 mux13 (.D({D3[13],D2[13],D1[13],D0[13]}), .S(S), .Y(Y[13]));
MUX4 mux14 (.D({D3[14],D2[14],D1[14],D0[14]}), .S(S), .Y(Y[14]));
MUX4 mux15 (.D({D3[15],D2[15],D1[15],D0[15]}), .S(S), .Y(Y[15]));
endmodule

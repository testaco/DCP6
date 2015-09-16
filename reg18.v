//
//								reg18.v - 18-bit Register
//
//					(C) Copyright 2004-2008 John B. Stephensen
//
// This Verilog source file and all its derivatives are licensed only for
// personal non-profit educational use in the Amateur Radio Service and
// the license is not transferrable. The information is provided as-is for
// experimental purposes and the author does not warranty its freedom
// from defects or its suitability for any specific application.
//
// This is commonly used to suppress optimization in ISE 10. 9 slices used.
//
module reg18 (
    input [17:0] d,
    output [17:0] q,
    input clk,
    input ce,
	 input rst
    );
// use 18 D flip-flops with synchronous reset and set and clock enable
FDRSE #(.INIT(1'b0)) ff0 (.D(d[0]), .Q(q[0]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff1 (.D(d[1]), .Q(q[1]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff2 (.D(d[2]), .Q(q[2]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff3 (.D(d[3]), .Q(q[3]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff4 (.D(d[4]), .Q(q[4]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff5 (.D(d[5]), .Q(q[5]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff6 (.D(d[6]), .Q(q[6]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff7 (.D(d[7]), .Q(q[7]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff8 (.D(d[8]), .Q(q[8]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff9 (.D(d[9]), .Q(q[9]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff10 (.D(d[10]), .Q(q[10]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff11 (.D(d[11]), .Q(q[11]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff12 (.D(d[12]), .Q(q[12]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff13 (.D(d[13]), .Q(q[13]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff14 (.D(d[14]), .Q(q[14]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff15 (.D(d[15]), .Q(q[15]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff16 (.D(d[16]), .Q(q[16]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
FDRSE #(.INIT(1'b0)) ff17 (.D(d[17]), .Q(q[17]), .C(clk), .CE(ce), .R(rst), .S(1'b0));
endmodule

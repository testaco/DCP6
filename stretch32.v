//
//						stretch32.v - Stretch pulse to 32 clock cycles
//
//							(C) Copyright 2012 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-6 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
module stretch32(
    input n,	// 1 clock wide
    output w,	// 32 clocks wide (0.67 us @ 48 MHz)
    input c		// clock
    );
// internal signals
reg t;			// toggle FF
reg [31:0] d;	// delay line
reg q;			// output FF
// logic
always @ (posedge c)
begin
	if (n) t <= ~t;	// toggle on input pulse
	d <= {d[30:0],t};	// shift register
	q <= t^d[31];		// latch output
end
assign w = q;	// always 32 clocks wide
endmodule

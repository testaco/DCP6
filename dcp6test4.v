//
//							dcp6test4.v - Test DCP-6 PCB with WB Tuner
//
//							(C) Copyright 2012-2013 John B. Stephensen
//
// This Verilog source file and all explicitly and implicitly referenced files and all of their
// derivatives are licensed only for personal non-profit educational use in the Amateur Radio
// Service with the DCP-6 PCB and the license is not transferrable. The information is provided
// as-is for experimental purposes and the author does not warranty its freedom from defects or
// its suitability for any specific application.
//
//	Test configuration for DCP-6 and DCP-6A supporting one wideband channel.
//
// ISE 14.6 balanced design goal:
// 7804 LUT6s (51%), 5792 registers (19%), 43 RAMB16 and 25 DSP48 synthesized in XC6SLX25-2.
// 6628 LUT6s (44%) and 5701 registers (18%) implemented with 2226 (59%) slices occupied.
// Compile time appx. 9 min.
//
// History:
//		2013-10-9	mod. for wide-band tuner and high-speed OFDM
//
module dcp6test4 (
    input [15:2] ADC,	// 14-bit 80 Msps ADC
	 input OVF,				// ADC overflow
	 input DCO,				// ADC clock output
	 output ADCSCK,		// SPI clock
	 inout ADCSDIO,		// SPI bidirectional data
	 output ADCCSN,		// SPI chip select (active low)
    output [13:0] DAC,	// 14-bit 80 Msps DAC
    input CLK,				// Master clock at ADC sample rate
	 input REF,				// frequency standard input
	 output VCXO,			// VCXO frequency adjust
	 input MISO,			// Flash master in/slave out
	 output MOSI,			// Flash master out/slave in
	 output SSN,			// Flash slave select (active low)
	 output SCK,			// Flash bit clock
	 output WPN,			// Flash write protect
	 output HLDN,			// Flash hold
	 input [1:0] RXD,		// Ethernet received data
	 input RXV,				// Ethernet received signal valid
	 output [1:0] TXD,	// Ethernet transmit data
	 output TXV,			// Ethernet transmit output valid
	 output REFCLK,		// Ethernet clock
	 output MDC,			// Ethernet management interface clock
	 inout MDIO,			// Ethernet management interface bidirectional data
	 input MINT,			// Ethernet interrupt
	 output RSTN,			// Ethernet PHY reset (active low)
	 input URXD,			// UART received data
	 output UTXD,			// UART transmit data
	 output UTXE,			// UART transmit enable
	 output GRNLED,REDLED,	// active high LEDs
//	 output GRNLED2,REDLED2,	// active high LEDs
	 output PTT,			// open-drain output
	 inout [9:0] IO,		// GPIO pins
	 output SCK2,			// LS ADC & DAC serial clock
	 output SDO2,			// LS DAC serial data output
	 input SDI2,			// LS ADC serial data input
	 output SS2N,			// LS DAC select (active low)
	 output SS3N			// LS ADC select (active low)
	 );
// internal signals
wire rst;								// reset logic
wire [15:10] msel;					// memory bank select
wire [13:0] maddr;					// data address (of word)
wire [15:0] min,mout;//,mio;			// data bus (direction referenced to MCU)
wire mrd,mwr;							// read from/write to memory
wire mcs1,mcs2,mcs3,mcs4,mcs5;	// memory bank selects
reg [13:10] mdosel;					// memory output multiplxer port select input
wire [15:0] min1,min2,min3,min4,min5;	// memory input ports
wire [7:0] ioaddr;					// I/O address bus
wire [15:0] din,dout;				// I/O data bus (direction referenced to MCU)
wire iord,iowr;						// read and write enables
wire iocs0,iocs1,iocs2,iocs3,iocs4,iocs5,iocs6,iocs7;	// CPU I/O port selects
wire iocs8,iocs9,iocs10,iocs11,iocs12,iocs13,iocs14c,iocs14d,iocs15a,iocs15b,iocs15c,iocs15d;
wire miocs0,miocs1,miocs2,miocs3,miocs4,miocs5,miocs6,miocs7,miocs8,miocs9;
reg [3:0] isel;						// input multiplexer port select input
wire [15:0] din0,din1,din2,din3,din4,din5,din6,din7;
wire [15:0] din8,din9,din10,din11,din12,din13,din15;
//wire [15:0] mio0,mio1,mio2,mio3,mio4,mio5,mio6,mio7,mio8,mio9;
//wire esof,erxce,eeof,erxswap;	// ethernet test
wire [15:0] mrax,mray,mtax,mtay;	// modem A data I/O
wire mrav,mtav,mfae;
//wire [15:0] mrbx,mrby,mtbx,mtby;	// modem B data I/O
//wire mrbv,mtbv,mfbe;
wire starta,synca,dcda,xmta;		// modem outputs for OFDM and T/R switching
//wire startb,syncb,dcdb,xmtb;
wire [15:0] frax,fray,ftax,ftay;	// FFT A baseband I/O
wire frav,ftav,ftae;
//wire [15:0] frbx,frby,ftbx,ftby;	// FFT B baseband I/O
//wire frbv,ftbv,ftbe;
//wire [15:0] mftax,mftay,mftbx,mftby;	// multiplexed transmit data
//wire mftav,mftbv;
wire [17:0] trax,tray;				// tuner A baseband output
wire trav;								// data valid
//wire [19:0] trbx,trby;				// tuner B baseband output
//wire trbv;								// data valid
wire [15:0] ttax,ttay;				// tuner A baseband input
wire ttav,tardy;						// data valid and ready for data
//wire [15:0] ttbx,ttby;				// tuner B baseband input
//wire ttbv,tbrdy;						// data valid and ready for data
wire ptta;//,pttb;						// enable transmitter
wire fcda;//,fcdb;						// full carrier detect
wire [7:0]rphs;						// subcarrier receive signals
wire decode,vrfd,rv;
wire [3:0] tmag,tphs;				// subcarrier transmit signals
wire trst,tv,refsym;
// Test signals
wire frdya;//,frdyb;					// FIFO ready for data
//reg testv;
//wire [15:0] x,y,m,t,f;		// modem test signals for output on LS DAC
//wire [11:0] p;
//wire xyv,mpv,ftev;
//wire [7:0] x0,y0;				// FFT test signals for output on LS DAC
//wire [8:0] w;
//wire [15:0] gaina,gainb;	// AGC gain
// generate internal clocks from ADC and DAC clock inputs
wire adcclk,dacclk;		// external clock inputs
wire sclk0,sclk,dclk;	// tuner clocks
wire mclk0,mclk;			// CPU clocks
wire rclk0,rclk;			// ethernet clock
wire iq;						// I/Q flag (I=1, Q=0)
wire locked1,locked2; 	// DCM and PLL locked
IBUFG adcclkbuf (.I(DCO), .O(adcclk));
IBUFG dacclkbuf (.I(CLK), .O(dacclk));
DCM_SP #(
	.CLKIN_PERIOD(12.5),	// 80 MHz input
	.CLK_FEEDBACK("1X"),
	.CLKFX_MULTIPLY(3),	// 48M CPU (-2)
	.CLKFX_DIVIDE(5),
//	.CLKFX_MULTIPLY(9),	// 72M CPU (-3)
//	.CLKFX_DIVIDE(10),
	.CLKIN_DIVIDE_BY_2("FALSE")
	) dcm (
	.RST(1'b0),			// don't reset
	.CLKIN(dacclk),	// external clock input
	.CLKFB(sclk),		// DLL feedback
	.CLK0(sclk0),		// 80 MHz tuner clock
	.CLK90(),
	.CLK180(),
	.CLK270(),
	.CLK2X(dclk0),		// 160 MHz tuner clock
	.CLK2X180(),
	.CLKFX(mclk0),		// CPU clock
	.CLKFX180(),
	.CLKDV(),
	.PSEN(1'b0),
	.PSINCDEC(1'b0),
	.PSCLK(1'b0),
	.LOCKED(locked1)
	);
wire clkfb;	// internal feedback
PLL_BASE #(
	.BANDWIDTH("LOW"),			// for low jitter
	.CLKFBOUT_MULT(10),			// 800 MHz VCO -> 80 MHz PFD
	.CLKFBOUT_PHASE(0.0),
	.CLKIN_PERIOD(12.5),			// 80 MHz input
	.CLKOUT0_DIVIDE(16),			// 800 MHz VCO -> 50 MHz rclk0
	.CLKOUT0_DUTY_CYCLE(0.5),
	.CLKOUT0_PHASE(0.0),
	.CLK_FEEDBACK("CLKFBOUT"),	// minimum jitter
	.COMPENSATION("INTERNAL"),
	.DIVCLK_DIVIDE(1),			// 80 MHz ref -> 80 MHz PFD
	.REF_JITTER(0.001),			// input is crystal oscillator
	.RESET_ON_LOSS_OF_LOCK("FALSE")
	) pll (
	.RST(1'b0),						// don't reset
	.CLKIN(dacclk),				// external clock input
	.CLKFBIN(clkfb),				// internal PLL feedback
	.CLKFBOUT(clkfb),
	.CLKOUT0(rclk0),				// ethernet clock output
	.LOCKED(locked2)
	);
// buffer general clocks
BUFG sclkbuf (.I(sclk0), .O(sclk));		// tuner sample clock
BUFG dclkbuf (.I(dclk0), .O(dclk));		// tuner data clock (2xSCLK)
BUFG mclkbuf (.I(mclk0), .O(mclk));		// CPU clock
BUFG rclkbuf (.I(rclk0), .O(rclk));		// ethernet reference clock
// Buffer Ethernet clock
ODDR2 #(
	.DDR_ALIGNMENT("NONE"),
	.INIT(1'b0),
	.SRTYPE("SYNC")
	) refclkbuf (
	.D0(1'b1),	// data forms single-rate clock
	.D1(1'b0),
	.C0(rclk),	// double data rate clock
	.C1(~rclk),
	.CE(1'b1),
	.R(1'b0),
	.S(1'b0),
	.Q(REFCLK)	// output
	);
//OBUF refclkbuf (.I(rclk), .O(REFCLK));	// ethernet clock output
//OBUF refclkbuf (.I(rclk0), .O(REFCLK));	// ethernet clock output
// reset if DCM or PLL output not stable
assign rst = ~locked1 | ~locked2;		// general reset
// IQ is used for multiplexing and demultiplexing in-phase and quadrature samples
// it tracks SCLK but changes state after the positive-going edge of DCLK
iqgen iqg (
	.sclk(sclk),
	.dclk(dclk),
	.iq(iq)
	);
// test signals
wire [9:5] test;
// right I/O connector
//OBUF t0buf (.I(test[0]), .O(IO[0]));	// pin 2
//OBUF t1buf (.I(test[1]), .O(IO[1]));	// pin 4
//OBUF t2buf (.I(test[2]), .O(IO[2]));	// pin 6
//OBUF t3buf (.I(test[3]), .O(IO[3]));	// pin 8
//OBUF t4buf (.I(test[4]), .O(IO[4]));	// pin 10
// left I/O connector
OBUF t5buf (.I(test[5]), .O(IO[5]));	// pin 2
OBUF t6buf (.I(test[6]), .O(IO[6]));	// pin 4
OBUF t7buf (.I(test[7]), .O(IO[7]));	// pin 6
OBUF t8buf (.I(test[8]), .O(IO[8]));	// pin 8
OBUF t9buf (.I(test[9]), .O(IO[9]));	// pin 10
// CPU and DMA use MCLK
CPU16 cpu (
	.ioaddr(ioaddr),	// I/O address 
	.din0(din),			// I/O input bus (0-7F)
	.din1(16'hFFFF),
	.iord(iord), 		// I/O read
	.dout(dout), 		// I/O output bus (all)
	.iowr(iowr),		// I/O write
	.msel(msel), 		// memory bank select
	.maddr(maddr),		// memory address
	.min1(min),			// peripheral memory input bus (4000-7FFF)
	.min2(min5),		// data memory input bus (8000-BFFF)
	.min3(16'hFFFF),	// unused (C000-FFFF)
	.mout(mout),		// memory output bus (all)
	.mrd(mrd),
	.mwr(mwr),
	.clk(mclk), 
	.rst(rst) 
	);
// External memory input multiplexer supports 4 banks of memory
// read instruction is 2 cycles so select input is latched
always @ (posedge mclk) mdosel <= msel[13:10];
MUX4X16 rammux (
	.D0(min1),	// 4000-4FFF
	.D1(min2),	// 5000-5FFF
	.D2(min3),	// 6000-6FFF
	.D3(min4),	// 7000-7FFF
	.S(mdosel[13:12]),
	.Y(min)
	);
// Memory bank selects
assign mcs1 = (msel[15:12] == 4'b0100);	// 4kW Ethernet RAM
assign mcs2 = (msel[15:12] == 4'b0101);	// 4kW Ethernet RAM
//assign mcs3 = (msel[15:12] == 4'b0110);	// 4kW FFT 1 RAM
//assign mcs4 = (msel[15:12] == 4'b0111);	// 4kW FFT 2 RAM
assign mcs5 = (msel[15:13] == 3'b100);		// 8kW Data RAM
// 16 kW Data Memory - only port A used
ram16kx16dp dataram (
	.aa(maddr),
	.ab(14'hFFFF),
	.dia(mout),
	.dib(16'hFFFF),
	.doa(min5),
	.dob(),
	.cea(mcs5),
	.ceb(1'b0),
	.wea(mwr),
	.web(1'b0),
	.clk(mclk),
	.rst(rst)
	);
// I/O port input multiplexers support 16 blocks of 8 input ports
always @ (posedge mclk) isel <= ioaddr[6:3];	// 16x8 ports per mux
MUX16X16 imux (
	.D0(din0),			// Ethernet
	.D1(din1),			// Serial Flash
	.D2(din2),			// Convolutional Encoder
	.D3(din3),			// Viterbi Decoder
	.D4(din4),			// UART
	.D5(16'hFFFF),		// unused
	.D6(16'hFFFF),		// unused
	.D7(din7),			// CRC
	.D8(din8),			// Demodulator
	.D9(din9),			// DFT
	.D10(din10),		// BP(4,3,7) CODEC
	.D11(din11),		// Tuner
	.D12(din12),		// Gain Cont./Clipper
	.D13(din13),		// LS ADC & DAC
	.D14(16'hFFFF),	// unused
	.D15(din15),		// ADC peak detect
	.S(isel),			// upper bits of I/O address
	.Y(din)				// data to multiplexer in ALU
	);
// I/O port selects - 16 blocks of 8
assign iocs0 = (ioaddr[6:3] == 0);		// Ethernet
assign iocs1 = (ioaddr[6:3] == 1);		// SPI
assign iocs2 = (ioaddr[6:3] == 2);		// Convolutional Encoder
assign iocs3 = (ioaddr[6:3] == 3);		// Viterbi Decoder
assign iocs4 = (ioaddr[6:3] == 4);		// UART
//assign iocs5 = (ioaddr[6:3] == 5);		// unused (FIR)
//assign iocs6 = (ioaddr[6:3] == 6);		// unused (I2S)
assign iocs7 = (ioaddr[6:3] == 7);		// CRC
assign iocs8 = (ioaddr[6:3] == 8);		// Demodulator
assign iocs9 = (ioaddr[6:3] == 9);		// DFT
assign iocs10 = (ioaddr[6:3] == 10);	// BP(4,3,7) CODEC
assign iocs11 = (ioaddr[6:3] == 11);	// Tuner
assign iocs12 = (ioaddr[6:3] == 12);	// Gain Cont./Clipper
assign iocs13 = (ioaddr[6:3] == 13);	// LS ADC & DAC
//assign iocs14 = (ioaddr[6:3] == 14);	// unused
//assign iocs14c = (ioaddr[6:1] == 58);	// panel LEDs
//assign iocs14d = (ioaddr[6:1] == 59);
assign iocs15a = (ioaddr[6:1] == 60);	// AFC DAC
assign iocs15b = (ioaddr[6:1] == 61);	// ADC peak detect
assign iocs15c = (ioaddr[6:1] == 62);	// board LEDs
assign iocs15d = (ioaddr[6:1] == 63);
// Ethernet Interface (100 Mbps FDX)
ethernet100 enet (
	.maddr(maddr[9:0]),	// 1 kW RAMs
	.mcs0(mcs1),			// transmit
	.mwr0(mwr),
	.min0(mout),
	.mout0(min1),
	.mcs1(mcs2),			// receive
	.mout1(min2),
	.iocs(iocs0),
	.ioaddr(ioaddr[2:0]),// I/O interface
	.din(dout),
	.dout(din0),
	.iowr(iowr),
	.iord(iord),
	.mclk(mclk),			// CPU clock
	.mrst(rst),
	.rxd(RXD),				// Ethernet PHY
	.rxv(RXV),
	.txd(TXD),
	.txv(TXV),
	.rclk(rclk),			// Ethernet clock
	.rstn(RSTN),
	.mdc(MDC),				// Ethernet PHY management
	.mdio(MDIO),
	.mint(MINT)
//	,.test(test[9:5])		// test signals
	);
// SPI (for serial flash)
spi spi0 (
	.iocs(iocs1),
	.ioaddr(ioaddr[2:0]),	// I/O interface
	.din(dout),
	.dout(din1),
	.iowr(iowr),
	.clk(mclk),			// CPU clock
	.rst(rst),
	.sdi(MISO),			// SPI
	.sdo(MOSI),
	.ssn(SSN),
	.sck(SCK)
	);
assign WPN = 1'b1;
assign HLDN = 1'b1;
// Convolutional Encoder
encbicm8w enc (
	.iocs(iocs2),
	.ioaddr(ioaddr[2:0]),
	.din(dout),
	.dout(din2),
	.iord(iord),
	.iowr(iowr),
	.clk(mclk),
	.rst(rst),
	.trst(trst),
	.tmag(tmag),
	.tphs(tphs),
	.tov(tv),
	.refsym(refsym)
	);
// Viterbi Decoder
viterbi8p dec (
	.iocs(iocs3),
	.ioaddr(ioaddr[2:0]),
	.din(dout),
	.dout(din3),
	.iord(iord),
	.iowr(iowr),
	.clk(mclk),
	.rst(rst),
	.start(decode),
	.rfd(vrfd),
	.phs(rphs),
	.iv(rv)
	);
// BP(4,3,7) CODEC
bp437p16 bp (
	.iocs(iocs10),
	.ioaddr(ioaddr[2:0]),
	.din(dout),
	.iowr(iowr),
	.dout(din10),
	.iord(iord),
	.clk(mclk) 
	);
// UART
uart uart0 (
	.iocs(iocs4),
	.ioaddr(ioaddr[2:0]),
	.din(dout),
	.dout(din4),
	.iord(iord),
	.iowr(iowr),
	.clk(mclk),
	.rst(rst),
	.txd(UTXD),
	.txen(UTXE),
	.rxd(URXD)
	);
// CRC hardware assist
crc1632p8a crc (
	.ioaddr(ioaddr[2:0]),
	.iocs(iocs7),
	.din(dout),
	.iowr(iowr),
	.dout(din7),
	.iord(iord),
	.clk(mclk),
	.rst(rst)
	 );
// modem contains CORDIC demodulator
// plus RSSI and phase correlator for OFDM
// baseband I/O is 16x16-bits to/from CPU
dem18f dem (
//	.x(x),				// test signals
//	.y(y),
//	.xyv(xyv),
//	.m(m),
//	.p(p),
//	.mpv(mpv),
//	.t(t),
//	.f(f),
//	.ftv(ftev),
	.iocs(iocs8),		// CPU interface
	.ioaddr(ioaddr[2:0]),
	.din(dout),
	.dout(din8),
	.iowr(iowr),
	.iord(iord),
	.rdix(trax),		// receiver input (no AGC)
	.rdiy(tray),
	.riv(trav),
	.pttout(ptta),
	.start(starta),	// synchronization signals to FFT
	.sync(synca),
	.dcd(dcda),
	.fcd(fcda),
	.clk(mclk),			// common clock and reset
	.rst(rst),
	.xmtout(xmta)		// T/R switch output
	);
// 32-256 point FFT and IFFT
dft256r16p8p dft ( 
//	.w(w),					// test
//	.x(x0),
//	.y(y0),
	.iocs(iocs9),			// CPU interface
	.ioaddr(ioaddr[2:0]),
	.din(dout),
	.iowr(iowr),
	.dout(din9),
	.iord(iord),
	.trst(trst),			// transmitter input
	.refsym(refsym),
	.tmag(tmag),
	.tphs(tphs),
	.tiv(tv),
	.toe(ftae & mfae),	// output enable when modem stopped 
	.tdox(ftax),			// to AGC/resample/comp. 
	.tdoy(ftay),
	.tov(ftav),
	.ten(ftae),				// FFT transmit enable output
	.cpe(),
	.rdix(mrax),			// from AGC
	.rdiy(mray), 
	.riv(mrav),
	.rrst(decode),			// receiver output
	.roe(vrfd),
	.rphs(rphs),
	.rov(rv),
	.reof(),
	.clk(mclk), 
	.rst(rst), 
	.xmt(xmta),				// transmit
	.sof(starta),			// sync. inputs
	.sync(synca),
	.dcd(dcda),
	.intr()					// sync. output
	);
// AGC Module converts 20 to 16 bits on receive
//agcrsmplclip arc1 (	// with resampler
agccliphs arc (			// without resampler
	.iocs(iocs12),		// configuration interface
	.ioaddr(ioaddr[2:0]),
	.iowr(iowr),
	.din(dout),
	.iord(iord),
	.dout(din12),
	.rdix(trax),		// 2x20-bit baseband input from tuner
	.rdiy(tray),
	.riv(trav),
	.rdox(mrax),		// 2x16-bit baseband output to modem and FFT
	.rdoy(mray),
	.rov(mrav),
	.tie(mfae),			// input enable to modem and FFT
	.tdix(ftax),		// 2x16-bit baseband input bypasses AGC
	.tdiy(ftay),
	.tiv(ftav),
	.toe(tardy),		// 2x16-bit baseband output to tuner
	.tdox(ttax),
	.tdoy(ttay),
	.tov(ttav),
	.clk(mclk),			// master clock and reser
	.rst(rst),
	.xmt(xmta)
	);
// Test Signal Generator (32 ksps data valid)
//reg [10:0] tctr;
//wire ttc;
//always @ (posedge mclk)
//begin
//	if (rst|ttc) tctr <= 0;
//	else tctr <= tctr + 1'b1;
//	testv <= ttc;
//end
//assign ttc = (tctr == 1499);
// The tuner converts a signal at specified a frequency to a baseband output near DC. The
// AD9255 ADC output is offset binary and changes 2.3-8.3 ns before the SCLK positive edge.
// In transmit mode, the baseband signal is converted to the specified output frequency.
// The AD9744 DAC input is offset binary and requires a 2 ns setup time and 1.5 ns hold
// time relative to the postiive-going edge of SCLK so must be delayed by 1/2 SCLK period.
// ADC SPI port
assign ADCCSN = 1'b1;	// disable SPI port
assign ADCSCK = 1'b0;
assign ADCSDIO = 1'bx;
// ADC buffer registers
reg [13:0] uadc,sadc;	// unsigned and signed ADC data output
reg [13:0] rfia;//,rfib;	// ADC buffers
reg adcovf,adcovff;		// ADC overflow flag
// latch incoming data using external clock
//always @ (posedge adcclk)
always @ (posedge sclk)
begin
	uadc <= ADC;
	adcovf <= OVF;
end
// convert offset binary to signed fraction (internal clock)
always @ (posedge sclk)
begin
	sadc <= {~uadc[13],uadc[12:0]};
	rfia <= sadc;	// buffer input to each tuner
//	rfib <= sadc;
end
// latch ADC overflow and reset when read (adcovf is asynchronous)
always @ (posedge mclk) if (iocs15b & iord) adcovff <= 0; else adcovff <= (adcovff|adcovf);
// measure maximum ADC output magnitude
wire [10:0] maxadc;	// 11-bit unsigned output
wire maxrst;			// reset
max12 max (
	.sig(sadc[13:2]),	// ADC input samples
	.max(maxadc),		// maximum sample magnitude
	.clk(sclk),			// ADC sample rate
	.rst(maxrst)		// reset when read
	);
assign din15 = {adcovff,4'h0,maxadc};	// convert to 16 bits
// generate delayed read enable synchronized to DCLK
syn2clk synmax (
	.a(iocs15b & iord),	// detect read of max. sig. reg.
	.aclk(mclk),			// CPU clock and reset
	.arst(rst),
	.b(maxrst),				// reset maximum signal magnitude register
	.bclk(sclk),			// ADC clock and reset
	.brst(rst)
	);
// DAC output select and conversion to offset binary
//wire [15:0] rfoa,rfob;					// tuner outputs
//reg [13:0] daca,dacb,dacmux,dacreg;	// DAC input registers
//reg [14:0] dacab;							// adder
//always @ (negedge sclk)
//begin
//	daca <= rfoa[15:2];			// buffer tuner outputs and truncate
//	dacb <= rfob[15:2];
//	dacab <= {daca[13],daca} + {dacb[13],dacb};	// sum both for ISB
//	case ({ptta,pttb})									// select output for DAC
//	2'b00: dacmux <= 14'h2000;							// neither transmitting
//	2'b01: dacmux <= {~dacb[13],dacb[12:0]};		// B transmitting
//	2'b10: dacmux <= {~daca[13],daca[12:0]};		// A transmitting
//	2'b11: dacmux <= {~dacab[14],dacab[13:1]};	// both transmitting
//	default: dacmux <= 14'hxxxx;
//	endcase
//	dacreg <= dacmux;
//end
// DOC output register and conversion to offset binary
wire [15:0] rfoa;
reg [13:0] dac1,dac2;
always @ (negedge sclk)
begin
	dac1 <= rfoa[15:2];
	dac2 <= {~dac1[13],dac1[12:0]};
end
assign DAC = dac2;
tuner4 fe (
	.iocs(iocs11), 		// select this module
	.ioaddr(ioaddr[2:0]),// 8 registers
	.din(dout), 			// configuration data
	.iowr(iowr), 			// write configuration
	.dout(din11),			// status
	.iord(iord),				// read staus
	.rfin({rfia,2'b00}),	// 16-bit signed ADC input sampled at SCLK positive-going edge
	.rfout(rfoa),			// 16-bit signed DAC output changing at SCLK negative-going edge
	.rfd(tardy),
	.dix(ttax),				// 2x16-bit baseband input from clipper
	.diy(ttay), 
	.iv(ttav),
	.dox(trax),				// 2x18-bit baseband output to AGC
	.doy(tray), 
	.ov(trav),
	.iq(iq), 				// 1=I, 0=Q (changes after SCLK)
	.dclk(dclk), 			// filter clock 
	.mclk(mclk), 			// CPU I/O clock
	.mrst(rst), 
	.xmtin(xmta)//,
//	.rdy(frdya),			// FIFO test signals
//	.full(full)
	);
// Test DAC Multiplexer
//reg [2:0] bbs;		// source select
//reg [6:0] bbc;		// bit counter (63->0)
//wire bbnz;			// counter non-zero
//reg [11:0] bbd;	// data multiplexer
//reg [11:0] bbd0,bbd1,bbd2,bbd3,bbd4,bbd5,bbd6,bbd7;
//reg bbv;				// data valid mux.
//reg bbv0,bbv1,bbv2,bbv3,bbv4,bbv5,bbv6,bbv7;
//reg [15:0] bbsr;	// data shift register
//wire bbe;			// shift enable
//always @ (posedge mclk)
//begin
	// data multiplexer
//	if (rst) bbs <= 4;				// source select register
//	else if (iocs13 & iowr) bbs <= dout[2:0];
//	bbd0 <= x[15:4];					// magnitude
//	bbd1 <= {~y[15],y[14:4]};		// phase or frequency
//	bbd2 <= m[15:4];					// RSSI
//	bbd3 <= p;							// phase correlator
//	bbd4 <= ~gaina[15:4];			// AGC 1
//	bbd5 <= ~gainb[15:4];			// AGC 2
//	bbd5 <= {~w[8],w[7:0],3'b000}; // FFT sample timing
//	bbd6 <= {~ttx[15],ttx[14:4]};
//	bbd7 <= {~tty[15],tty[14:4]};
//	bbd6 <= {~t[15],t[14:4]};		// timing error
//	bbd7 <= {~f[15],f[14:4]};		// costas loop error
//	bbd6 <= {~x0,4'h0};				// pilot carrier magnitude and phase
//	bbd7 <= {~y0[7],y0[6:0],4'h0};
//	case (bbs)							// data multiplexer
//	0: bbd <= bbd0;
//	1: bbd <= bbd1;
//	2: bbd <= bbd2;
//	3: bbd <= bbd3;
//	4: bbd <= bbd4;
//	5: bbd <= bbd5;
//	6: bbd <= bbd6;
//	7: bbd <= bbd7;
//	default: bbd <= 12'hxxx;
//	endcase
	// strobe multiplexer
//	bbv0 <= xyv;
//	bbv1 <= xyv;
//	bbv2 <= mpv;
//	bbv3 <= mpv;
//	bbv4 <= mrav;	// AGC/rsmpl/clip data valid
//	bbv5 <= mrbv;
//	bbv5 <= mrav;
//	bbv6 <= ttv;
//	bbv7 <= ttv;
//	bbv6 <= ftev;
//	bbv7 <= ftev;
//	bbv6 <= mrv;
//	bbv7 <= mrv;
//	case (bbs)			// data valid multiplexer
//	0: bbv <= bbv0;
//	1: bbv <= bbv1;
//	2: bbv <= bbv2;
//	3: bbv <= bbv3;
//	4: bbv <= bbv4;
//	5: bbv <= bbv5;
//	6: bbv <= bbv6;
//	7: bbv <= bbv7;
//	default: bbv <= 1'bx;
//	endcase
	// bit counter
//	if (rst) bbc <= 0;						// power on reset
//	else if (bbv) bbc <= 64;				// start
//	else if (bbnz) bbc <= bbc - 1'b1; 	// count down
	// shift register
//	if (bbv) bbsr <= {2'b00,bbd,2'b00};			// PD1 PD0 D11 D10 D9 D8 D7 D6 D5 D4 D3 D2 D1 D0 X X
//	else if (bbe) bbsr <= {bbsr[14:0],1'b0};	// shift out MSB first
//end
//assign bbnz = |bbc;						// counter not zero
//assign bbe = (bbc[1:0] == 2'b01);	// shift enable
//assign SS2N = ~bbnz;						// SYNC- (low for 16 SCK)
//assign SDO2 = bbsr[15];					// serial data (read on negative edge SCK2, 5ns setup, 4.5 ns hold)
//assign SCK2 = ~(bbc[1]^bbc[0]);		// negative-going clock in center of bit cell (20 MHz max.)
// SPI (for LS ADC & DAC)
spils spi1 (
	.iocs(iocs13),
	.ioaddr(ioaddr[2:0]),	// I/O interface
	.din(dout),
	.dout(din13),
	.iowr(iowr),
	.clk(mclk),			// CPU clock
	.rst(rst),
	.sdi(SDI2),			// SPI
	.sdo(SDO2),
	.ss0n(SS2N),
	.ss1n(SS3N),
	.sck(SCK2)
	);
//assign din13 = 0;
//assign SDO2 = 0;
//assign SS2N = 1;
//assign SS3N = 1;
//assign SCK2 = 0;
// Delta-Sigma DAC for VCXO Control (< 0.1 PPB res.)
// write port 120 to load LS 4 bits
// write to port 121 to load MS 16 bits and transfer all 20 bits to DAC
reg [15:12] dsdb;	// save least significant 4 bits
always @ (posedge mclk) if (iocs15a & iowr & ~ioaddr[0]) dsdb <= dout[15:12];
dsdac20x1 afcdac (
	.din({dout,dsdb}),
	.we(iocs15a & iowr & ioaddr[0]),
	.clk(mclk),
	.rst(rst),
	.aout(VCXO)
	);
// buffer and stretch test outputs
stretch32 t5 (.n(starta), .w(test[5]), .c(mclk));
//stretch32 t6 (.n(synca), .w(test[6]), .c(mclk));
reg tdcd,tfcda;
always @ (posedge mclk)
begin
	tdcd <= dcda;
	tfcda <= fcda;
end
assign test[6] = tdcd;
assign test[7] = tfcda;
assign test[8] = redreg;
assign test[9] = grnreg;
// write port 124 to turn off red LED
// write port 125 to turn on red LED
// write port 126 to turn off green LED
// write port 127 to turn on green LED
reg redreg,grnreg;//,red2reg,grn2reg;
always @ (posedge mclk)
begin
	if (rst) redreg <= 1'b0;	// turn off when powered up
	else if (iocs15c & iowr) redreg <= ioaddr[0];
	if (rst) grnreg <= 1'b0;	// turn off when powered up
	else if (iocs15d & iowr) grnreg <= ioaddr[0];
//	if (rst) red2reg <= 1'b0;	// turn off when powered up
//	else if (iocs14c & iowr) red2reg <= ioaddr[0];
//	if (rst) grn2reg <= 1'b0;	// turn off when powered up
//	else if (iocs14d & iowr) grn2reg <= ioaddr[0];
end
OBUF pttbuf (.I(ptta), .O(PTT));
OBUF redbuf (.I(redreg), .O(REDLED));
OBUF grnbuf (.I(grnreg), .O(GRNLED));
//OBUF red2buf (.I(red2reg), .O(REDLED2));
//OBUF grn2buf (.I(grn2reg), .O(GRNLED2));
endmodule

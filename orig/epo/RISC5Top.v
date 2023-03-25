`timescale 1ns / 1ps  // NW 14.6.2018
//
// Embedded Project Oberon OS
// Astrobe for RISC5 v8.0
// CFB Software 
// http://www.astrobe.com
//
// Digilent Arty A7
//
// CFB 16.10.2021
//
module RISC5Top(
  input CLK100M,
  input [3:0] btn,
  input [3:0] swi,
  input  RxD,   // RS-232
  output TxD,
  input [2:0] MISO,          // SPI - SD card SPI1 / SPI2
  output [2:0] SCLK, MOSI,
  output [2:0] SS,
  output [3:0] leds,
  inout [31:0] GPIO,
  inout SDA, SCL);

// IO addresses for input / output
// 0  milliseconds / --
// 1  switches / LEDs
// 2  RS-232 data / RS-232 data (start)
// 3  RS-232 status / RS-232 control
// 4  SPI data / SPI data (start)
// 5  SPI status / SPI control
// 6  PS2 keyboard (not used)
// 7  mouse (not used)
// 8  general-purpose I/O data
// 9  general-purpose I/O tri-state control
// 10 I2C Control set
// 11 I2C Status (read-only)
// 12 I2C Data
// 13 I2C Clock high count
// 14 I2C Clock low count
// 15 I2C Control clear (write-only)

wire clk40, clk80;
reg rst;

wire[23:0] adr;
wire [3:0] iowadr; // word address
wire [31:0] inbus, inbus0;  // data to RISC core
wire [31:0] outbus;  // data from RISC core
wire [31:0] romout, codebus;  // code to RISC core
wire rd, wr, ben, ioenb;

wire [7:0] dataTx, dataRx;
wire rdyRx, doneRx, startTx, rdyTx;
reg bitrate;  // for RS232
wire limit;  // of cnt0

reg [3:0] Lreg;
reg [15:0] cnt0;
reg [31:0] cnt1; // milliseconds

wire [31:0] spiRx;
wire spiStart, spiRdy;
reg [4:0] spiCtrl;
reg [31:0] gpout, gpoc;
wire [31:0] gpin;
wire [7:0] i2c_control, i2c_data;
wire [4:0] i2c_status;
wire wr_i2c_conset, wr_i2c_data, wr_i2c_conclr;
reg [15:0] i2c_sclh, i2c_scll;

wire clkfbout, pllclk0, pllclk1;
wire pllclk2_unused, pllclk3_unused, pllclk4_unused, pllclk5_unused; 
wire pll_locked;

PLL_BASE # (
  .CLKIN_PERIOD(10),
  .CLKFBOUT_MULT(12),
  .CLKOUT0_DIVIDE(15),
  .CLKOUT1_DIVIDE(30)
) pll_blk (
  .CLKFBOUT(clkfbout),
  .CLKOUT0(pllclk0),
  .CLKOUT1(pllclk1),
  .CLKOUT2(pllclk2_unused),
  .CLKOUT3(pllclk3_unused),
  .CLKOUT4(pllclk4_unused),
  .CLKOUT5(pllclk5_unused),
  .LOCKED(pll_locked),
  .CLKFBIN(clkfbout),
  .CLKIN(CLK100M),
  .RST(1'b0)
  );
BUFG clk80bufg(.I(pllclk0), .O(clk80));
BUFG clk40bufg(.I(pllclk1), .O(clk40));

RISC5 riscx(.clk(clk40), .rst(rst), .irq(limit),
   .rd(rd), .wr(wr), .ben(ben),
   .adr(adr), .codebus(codebus), .inbus(inbus),
	.outbus(outbus));
  
PROM PM (.adr(adr[10:2]), .data(romout), .clk(~clk40));

RS232R receiver(.clk(clk40), .rst(rst), .RxD(RxD), .fsel(bitrate),
   .done(doneRx), .data(dataRx), .rdy(rdyRx));
   
RS232T transmitter(.clk(clk40), .rst(rst), .start(startTx),
   .fsel(bitrate), .data(dataTx), .TxD(TxD), .rdy(rdyTx));
   
SPI spi(.clk(clk40), .rst(rst), .start(spiStart), .dataTx(outbus),
   .fast(spiCtrl[3]), .wordsize(spiCtrl[4]), .dataRx(spiRx), .rdy(spiRdy),
 	.SCLK(SCLK[0]), .MOSI(MOSI[0]), .MISO(MISO[0] & MISO[1] & MISO[2]));
  
RAM ram (.clk(clk80), .wr(wr), .be(ben), .adr(adr[18:0]),
   .wdata(outbus), .rdata(inbus0));
   
I2C i2c(.clk(clk40), .rst(rst), .SDA(SDA), .SCL(SCL), .sclh(i2c_sclh),
   .scll(i2c_scll), .control(i2c_control), .status(i2c_status),
   .data(i2c_data), .wrdata(outbus[7:0]), .wr_conset(wr_i2c_conset),
   .wr_data(wr_i2c_data), .wr_conclr(wr_i2c_conclr));

assign codebus = (adr[23:14] == 10'h3FF) ? romout : inbus0;
assign iowadr = adr[5:2];
assign ioenb = (adr[23:6] == 18'h3FFFF);
assign inbus = ~ioenb ? inbus0 :
   ((iowadr == 0) ? cnt1 :
    (iowadr == 1) ? {20'b0, btn, 4'b0, swi} :
    (iowadr == 2) ? {24'b0, dataRx} :
    (iowadr == 3) ? {30'b0, rdyTx, rdyRx} :
    (iowadr == 4) ? spiRx :
    (iowadr == 5) ? {31'b0, spiRdy} :
//  (iowadr == 6) ? {3'b0, rdyKbd, dataMs} :
//  (iowadr == 7) ? {24'b0, dataKbd} :
    (iowadr == 8) ? {gpin} :
    (iowadr == 9) ? {gpoc} :
    (iowadr == 10) ? {24'b0, i2c_control} :
    (iowadr == 11) ? {24'b0, i2c_status, 3'b000} :
    (iowadr == 12) ? {24'b0, i2c_data} :
    (iowadr == 13) ? {16'b0, i2c_sclh} :
    (iowadr == 14) ? {16'b0, i2c_scll} : 0);

genvar i;
generate // tri-state buffer for gpio port
  for (i = 0; i < 32; i = i+1)
  begin: gpioblock
    IOBUF gpiobuf (.I(gpout[i]), .O(gpin[i]), .IO(GPIO[i]), .T(~gpoc[i]));
  end
endgenerate

assign dataTx = outbus[7:0];
assign startTx = wr & ioenb & (iowadr == 2);
assign doneRx = rd & ioenb & (iowadr == 2);
assign limit = (cnt0 == 39999);
assign spiStart = wr & ioenb & (iowadr == 4);
assign SS = ~spiCtrl[2:0];  //active low slave select
assign MOSI[1] = MOSI[0], SCLK[1] = SCLK[0];
assign MOSI[2] = MOSI[0], SCLK[2] = SCLK[0];
assign leds = Lreg; 
assign wr_i2c_conset = wr & ioenb & (iowadr == 10);
assign wr_i2c_data = wr & ioenb & (iowadr == 12);
assign wr_i2c_conclr = wr & ioenb & (iowadr == 15);

always @(posedge clk40)
begin
  spiCtrl <= ~rst ? 0 : (wr & ioenb & (iowadr == 5)) ? outbus[4:0] : spiCtrl;
  gpout <= (wr & ioenb & (iowadr == 8)) ? outbus : gpout;
  gpoc <= ~rst ? 0 : (wr & ioenb & (iowadr == 9)) ? outbus : gpoc;
  i2c_sclh <= ~rst ? 0 : (wr & ioenb & (iowadr == 13)) ? outbus[15:0] : i2c_sclh;
  i2c_scll <= ~rst ? 0 : (wr & ioenb & (iowadr == 14)) ? outbus[15:0] : i2c_scll;
  rst <= ((cnt1[4:0] == 0) & limit) ? ~btn[3] : rst;
  Lreg <= ~rst ? 0 : (wr & ioenb & (iowadr == 1)) ? outbus[3:0] : Lreg;
  cnt0 <= limit ? 0 : cnt0 + 1;
  cnt1 <= cnt1 + limit;
  bitrate <= ~rst ? 0 : (wr & ioenb & (iowadr == 3)) ? outbus[0] : bitrate;
end

endmodule

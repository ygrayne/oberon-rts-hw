/**
  Top level definition
  --
  Architecture: THM
  --
  Base: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences

  * no video RAM
  * no keyboard and mouse
  * separate clock and reset, move clock into tech directory
  * move bio into board directory
  * extended SPI device
  * extended IO address space
  * prom memfile parameter
  * 16 MB SDRAM
  * parameterised clock frequency for RS232 and SPI devices
**/

`timescale 1ns / 1ps
`default_nettype none

`define CLOCK_FREQ 50_000_000
`define PROM_FILE "../../../platform/p2-thm-de2-115/promfiles/BootLoad-16M-8M.mem"  // for PROM

module risc5 (
  // clocks
  input clk_in,
  // reset
  input rst_in_n,
  // SDRAM
  output sdram_clk,
  output sdram_cke,
  output sdram_cs_n,
  output sdram_ras_n,
  output sdram_cas_n,
  output sdram_we_n,
  output [1:0] sdram_ba,
  output [12:0] sdram_a,
  output [3:0] sdram_dqm,
  inout [31:0] sdram_dq,
  // RS-232
  input rs232_0_rxd,
  output rs232_0_txd,
  // SD card
  output sdcard_ss_n,
  output sdcard_sclk,
  output sdcard_mosi,
  input sdcard_miso,
  // board I/O
  output [8:0] led_g,
  output [17:0] led_r,
  output [6:0] hex7_n,
  output [6:0] hex6_n,
  output [6:0] hex5_n,
  output [6:0] hex4_n,
  output [6:0] hex3_n,
  output [6:0] hex2_n,
  output [6:0] hex1_n,
  output [6:0] hex0_n,
  input key3_n,
  input key2_n,
  input key1_n,
  input [17:0] sw
);

  // clk
  wire clk_ok;            // clocks stable
  wire mclk;              // memory clock, 100 MHz
  wire clk;               // system clock, 50 MHz
  // reset
  wire rst;               // system reset
  // cpu
  wire bus_stb;           // bus strobe
  wire bus_we;            // bus write enable
  wire [23:2] bus_addr;   // bus address (word address)
  wire [31:0] bus_din;    // bus data input, for reads
  wire [31:0] bus_dout;   // bus data output, for writes
  wire bus_ack;           // bus acknowledge
  // prom
  wire prom_stb;          // prom strobe
  wire [31:0] prom_dout;  // prom data output
  wire prom_ack;          // prom acknowledge
  // ram
  wire ram_stb;           // ram strobe
  wire [26:2] ram_addr;   // ram address
  wire [31:0] ram_dout;   // ram data output
  wire ram_ack;           // ram acknowledge
  // i/o
  wire io_stb;           // i/o strobe
  // tmr
  wire tmr_stb;           // timer strobe
  wire [31:0] tmr_dout;   // timer data output
  wire tmr_ack;           // timer acknowledge
  // bio
  wire bio_stb;           // board i/o strobe
  wire [31:0] bio_dout;   // board i/o data output
  wire bio_ack;           // board i/o acknowledge
  // ser
  wire ser_stb;           // serial line strobe
  wire [31:0] ser_dout;   // serial line data output
  wire ser_ack;           // serial line acknowledge
  // spi
  wire spi_stb;           // SPI strobe
  wire [31:0] spi_dout;   // SPI data output
  wire [2:0] spi_cs_n;    // SPI chip select output
  wire spi_ack;           // SPI acknowledge

  //--------------------------------------
  // module instances
  //--------------------------------------

  clk clk_0 (
    .clk_in(clk_in),
    .clk_ok(clk_ok),
    .clk_100_ps(sdram_clk),
    .clk_100(mclk),
    .clk_50(clk)
  );

  rst rst_0 (
    .clk(clk),
    .clk_ok(clk_ok),
    .rst_in_n(rst_in_n),
    .rst(rst)
  );

  cpu cpu_0 (
    .clk(clk),
    .rst(rst),
    .bus_stb(bus_stb),
    .bus_we(bus_we),
    .bus_addr(bus_addr[23:2]),
    .bus_din(bus_din[31:0]),
    .bus_dout(bus_dout[31:0]),
    .bus_ack(bus_ack)
  );

  prom #(.memfile(`PROM_FILE)) prom_0 (
    .clk(clk),
    .rst(rst),
    .stb(prom_stb),
    .we(bus_we),
    .addr(bus_addr[10:2]),
    .data_out(prom_dout[31:0]),
    .ack(prom_ack)
  );

  assign ram_addr[26:2] = { 3'b000, bus_addr[23:2] };
  ram ram_0 (
    .clk_ok(clk_ok),
    .clk2(mclk),
    .clk(clk),
    .rst(rst),
    .stb(ram_stb),
    .we(bus_we),
    .addr(ram_addr[26:2]),
    .data_in(bus_dout[31:0]),
    .data_out(ram_dout[31:0]),
    .ack(ram_ack),
    .sdram_cke(sdram_cke),
    .sdram_cs_n(sdram_cs_n),
    .sdram_ras_n(sdram_ras_n),
    .sdram_cas_n(sdram_cas_n),
    .sdram_we_n(sdram_we_n),
    .sdram_ba(sdram_ba[1:0]),
    .sdram_a(sdram_a[12:0]),
    .sdram_dqm(sdram_dqm[3:0]),
    .sdram_dq(sdram_dq[31:0])
  );

  tmr tmr_0 (
    .clk(clk),
    .rst(rst),
    .stb(tmr_stb),
    .data_out(tmr_dout[31:0]),
    .ack(tmr_ack)
  );

  bio bio_0 (
    .clk(clk),
    .rst(rst),
    .stb(bio_stb),
    .we(bus_we),
    .data_in(bus_dout[31:0]),
    .data_out(bio_dout[31:0]),
    .ack(bio_ack),
    .led_g(led_g[8:0]),
    .led_r(led_r[17:0]),
    .hex7_n(hex7_n[6:0]),
    .hex6_n(hex6_n[6:0]),
    .hex5_n(hex5_n[6:0]),
    .hex4_n(hex4_n[6:0]),
    .hex3_n(hex3_n[6:0]),
    .hex2_n(hex2_n[6:0]),
    .hex1_n(hex1_n[6:0]),
    .hex0_n(hex0_n[6:0]),
    .key3_n(key3_n),
    .key2_n(key2_n),
    .key1_n(key1_n),
    .sw(sw[17:0])
  );

  ser #(.clockfreq(`CLOCK_FREQ)) ser_0 (
    .clk(clk),
    .rst(rst),
    .stb(ser_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(ser_dout[31:0]),
    .ack(ser_ack),
    .rxd(rs232_0_rxd),
    .txd(rs232_0_txd)
  );

  spie #(.clockfreq(`CLOCK_FREQ)) spie_0 (
    .clk(clk),
    .rst(rst),
    .stb(spi_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    .data_out(spi_dout[31:0]),
    .ack(spi_ack),
    .cs_n(spi_cs_n[2:0]),
    .sclk(sdcard_sclk),
    .mosi(sdcard_mosi),
    .miso(sdcard_miso)
  );

  assign sdcard_ss_n = spi_cs_n[0];

  //--------------------------------------
  // address decoder (16 MB addr space)
  //--------------------------------------

  // PROM: 2 KB @ 0xFFE000
  assign prom_stb =
    (bus_stb == 1'b1 && bus_addr[23:12] == 12'hFFE
                     && bus_addr[11] == 1'b0) ? 1'b1 : 1'b0;

  // RAM: (16 MB - 8 kB) @ 0x000000
  assign ram_stb =
    (bus_stb == 1'b1 && bus_addr[23:13] != 11'h7FF) ? 1'b1 : 1'b0;

  // I/O: 256 bytes (64 words) @ 0xFFFF00
  assign io_stb = (bus_stb == 1'b1 && bus_addr[23:8] == 16'hFFFF) ? 1'b1 : 1'b0;

  assign tmr_stb = (io_stb == 1'b1 && bus_addr[7:2] == 6'b110000) ? 1'b1 : 1'b0; // -64
  assign bio_stb = (io_stb == 1'b1 && bus_addr[7:2] == 6'b110001) ? 1'b1 : 1'b0; // -60
  assign ser_stb = (io_stb == 1'b1 && bus_addr[7:3] == 5'b11001) ? 1'b1 : 1'b0;  // -56
  assign spi_stb = (io_stb == 1'b1 && bus_addr[7:3] == 5'b11010) ? 1'b1 : 1'b0;  // -48

  //--------------------------------------
  // data and acknowledge multiplexers
  //--------------------------------------

  assign bus_din[31:0] =
    prom_stb ? prom_dout[31:0] :
    ram_stb  ? ram_dout[31:0]  :
    tmr_stb  ? tmr_dout[31:0]  :
    bio_stb  ? bio_dout[31:0]  :
    ser_stb  ? ser_dout[31:0]  :
    spi_stb  ? spi_dout[31:0]  :
    32'h00000000;

  assign bus_ack =
    prom_stb ? prom_ack :
    ram_stb  ? ram_ack  :
    tmr_stb  ? tmr_ack  :
    bio_stb  ? bio_ack  :
    ser_stb  ? ser_ack  :
    spi_stb  ? spi_ack  :
    1'b0;

endmodule

`resetall

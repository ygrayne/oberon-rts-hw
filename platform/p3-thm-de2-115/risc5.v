/**
  Top level definition p3-thm-de2-115
  --
  Architecture: THM
  --
  Base:
    * TMM-oberon
    * Project Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences

  * no video RAM
  * no keyboard and mouse
  * separate clock and reset, move clock into tech directory
  * move bio into board directory as lsb
  * extended SPI device
  * extended IO address space
  * 16 MB SDRAM
  * parameterised clock frequency for perpiherals
  * process timers
  * start tables
  * system control
  * buffered RS232 device
**/

`timescale 1ns / 1ps
`default_nettype none

`define CLOCK_FREQ 50_000_000
`define PROM_FILE "../../../platform/p3-thm-de2-115/promfiles/BootLoad-512k-64k.mem"  // for PROM
`define RS232_BUF_SLOTS 255

module risc5 (
  // clock
  input clk_in,
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
  output sdcard_cs_n,
  output sdcard_sclk,
  output sdcard_mosi,
  input sdcard_miso,
  // LEDs, switches, buttons, 7-segment
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
  input [3:0] btn_in_n, // includes reset button
  input [17:0] swi_in
);

  // clk
  wire clk_ok;            // clocks stable
  wire mclk;              // memory clock, 100 MHz
  wire clk;               // system clock, 50 MHz
  // reset
  wire rst;               // system reset
  wire rst_trig;          // reset triggers
  // cpu
  wire bus_stb;
  wire bus_we;            // bus write enable
  wire [23:2] bus_addr;   // bus address (word address)
  wire [31:0] bus_din;    // bus data input, for reads
  wire [31:0] bus_dout;   // bus data output, for writes
  wire bus_ack;
  // prom
  wire prom_stb;
  wire [31:0] prom_dout;
  wire prom_ack;
  // ram
  wire ram_stb;
  wire [26:2] ram_addr;
  wire [31:0] ram_dout;
  wire ram_ack;
  // i/o
  wire io_stb;            // i/o strobe
  // ms timer
  wire tmr_stb;
  wire [31:0] tmr_dout;   // data out: running milliseconds since reset
  wire tmr_ms_tick;       // millisecond timer tick
  wire tmr_ack;
  // lsb
  wire lsb_stb;
  wire [31:0] lsb_dout;   // data out: buttons, switches
  wire [3:0] lsb_btn;     // button signals out
  wire [17:0] lsb_swi;    // button signals out
  wire lsb_ack;
  // start tables
  wire start_stb;
  wire [31:0] start_dout; // data out: start-up table number, armed bit
  wire start_ack;
  // sys ctrl reg
  wire scr_stb;
  wire [31:0] scr_dout;   // data out: register content
  wire scr_sysrst;        // system reset signal out
  wire scr_ack;
  // rs232
  wire rs232_0_stb;
  wire [31:0] rs232_0_dout; // data out: received data, status
  wire rs232_0_ack;
  // spi
  wire spi_0_stb;
  wire [31:0] spi_0_dout;   // data out: received data, status
  wire spi_0_sclk_d;          // sclk signal from device
  wire spi_0_mosi_d;          // mosi signal from device
  wire spi_0_miso_d;          // miso signals to device
  wire [2:0] spi_0_cs_n_d;    // chip selects from device
  wire spi_0_ack;
  // proc periodic timing
  wire ptmr_stb;
  wire [31:0] ptmr_dout;  // proc timers data output (ready signals)
  wire ptmr_ack;

  // clocks
  clk clk_0 (
    .clk_in(clk_in),
    .clk_ok(clk_ok),
    .clk_100_ps(sdram_clk),
    .clk_100(mclk),
    .clk_50(clk)
  );

  // reset
  assign rst_trig = lsb_btn[0] | scr_sysrst;
  rst rst_0 (
    // in
    .clk(clk),
    .clk_ok(clk_ok),
    .rst_in(rst_trig),
    // out
    .rst(rst)
  );

  // CPU
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

  // boot ROM
  prom #(.memfile(`PROM_FILE)) prom_0 (
    .clk(clk),
    .rst(rst),
    .stb(prom_stb),
    .we(bus_we),
    .addr(bus_addr[10:2]),
    .data_out(prom_dout[31:0]),
    .ack(prom_ack)
  );

  // SDRAM
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

  // ms timer
  tmr #(.clock_freq(`CLOCK_FREQ)) tmr_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(tmr_stb),
    .we(bus_we),
    // out
    .data_out(tmr_dout[31:0]),
    .ms_tick(tmr_ms_tick),
    .ack(tmr_ack)
  );

  // LEDs, switches, buttons
  lsb lsb_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(lsb_stb),
    .we(bus_we),
    .btn_in_n(btn_in_n[3:0]),
    .swi_in(swi_in[17:0]),
    .data_in(bus_dout[25:0]),
    // out
    .data_out(lsb_dout[31:0]),
    .ack(lsb_ack),
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
    .btn(lsb_btn[3:0]),
    .swi(lsb_swi[17:0])
  );

  // (-re) start tables
  start start_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(start_stb),
    .we(bus_we),
    .data_in(bus_dout[15:0]),
    // out
    .data_out(start_dout[31:0]),
    .ack(start_ack)
  );

  // sys ctrl register
  sysctrl sysctrl_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(scr_stb),
    .we(bus_we),
    .data_in(bus_dout[15:0]),
    // out
    .data_out(scr_dout[31:0]),
    .sysrst(scr_sysrst),
    .ack(scr_ack)
  );

  // RS232 buffered
  rs232 #(.clock_freq(`CLOCK_FREQ), .buf_slots(`RS232_BUF_SLOTS)) rs232_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(rs232_0_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[7:0]),
    // out
    .data_out(rs232_0_dout[31:0]),
    .ack(rs232_0_ack),
    // external
    .rxd(rs232_0_rxd),
    .txd(rs232_0_txd)
  );

  // SPI
  spie #(.clock_freq(`CLOCK_FREQ)) spie_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(spi_0_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[31:0]),
    // out
    .data_out(spi_0_dout[31:0]),
    .ack(spi_0_ack),
    // external
    .cs_n(spi_0_cs_n_d[2:0]),
    .sclk(spi_0_sclk_d),
    .mosi(spi_0_mosi_d),
    .miso(spi_0_miso_d)
  );

  assign sdcard_cs_n = spi_0_cs_n_d[0];
  assign sdcard_sclk = spi_0_sclk_d;
  assign sdcard_mosi = spi_0_mosi_d;
  assign spi_0_miso_d = sdcard_miso;

  // process periodic timers
  proctimers ptmr_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(ptmr_stb),
    .we(bus_we),
    .tick(tmr_ms_tick),
    .data_in(bus_dout[31:0]),
    // out
    .data_out(ptmr_dout[31:0]),
    .ack(ptmr_ack)
  );


  // address decoding
  // ----------------

  // PROM: 2 KB @ 0xFFE000
  assign prom_stb =
    (bus_stb == 1'b1 && bus_addr[23:12] == 12'hFFE
                     && bus_addr[11] == 1'b0) ? 1'b1 : 1'b0;

  // RAM: (16 MB - 8 kB) @ 000000H
  assign ram_stb =
    (bus_stb == 1'b1 && bus_addr[23:13] != 11'h7FF) ? 1'b1 : 1'b0;

  // I/O: 256 bytes (64 words) @ 0FFFF00H
  assign io_stb = (bus_stb == 1'b1 && bus_addr[23:8] == 16'hFFFF) ? 1'b1 : 1'b0;

  assign spi_0_stb   = (io_stb == 1'b1 && bus_addr[7:3] == 5'b11010) ? 1'b1 : 1'b0;  // -48 (data 000), -44 (ctrl/status 100)
  assign rs232_0_stb = (io_stb == 1'b1 && bus_addr[7:3] == 5'b11001) ? 1'b1 : 1'b0;  // -56 (data 000), -52 (ctrl/status 100)
  assign lsb_stb     = (io_stb == 1'b1 && bus_addr[7:2] == 6'b110001) ? 1'b1 : 1'b0; // -60 note: system LEDs via LED() procedure must be at this address
  assign tmr_stb     = (io_stb == 1'b1 && bus_addr[7:2] == 6'b110000) ? 1'b1 : 1'b0; // -64

  // the current addresses of P4 for compatibility
  assign scr_stb     = (io_stb == 1'b1 && bus_addr[7:2] == 6'b101111) ? 1'b1 : 1'b0;  // -68
  assign ptmr_stb    = (io_stb == 1'b1 && bus_addr[7:2] == 6'b011111) ? 1'b1 : 1'b0;  // -132
  assign start_stb   = (io_stb == 1'b1 && bus_addr[7:2] == 6'b010001) ? 1'b1 : 1'b0;  // -188


//  assign ptmr_stb = (io_stb == 1'b1 && bus_addr[7:2] == 6'b101111) ? 1'b1 : 1'b0;  // -68
//  assign start_stb = (io_stb == 1'b1 && bus_addr[7:2] == 6'b101110) ? 1'b1 : 1'b0;  // -72
//  assign scr_stb = (io_stb == 1'b1 && bus_addr[7:2] == 6'b101101) ? 1'b1 : 1'b0;  // -76


  // data out demultiplexing
  // -----------------------
  assign bus_din[31:0] =
    prom_stb    ? prom_dout[31:0] :
    ram_stb     ? ram_dout[31:0]  :
    tmr_stb     ? tmr_dout[31:0]  :
    lsb_stb     ? lsb_dout[31:0]  :
    rs232_0_stb ? rs232_0_dout[31:0]  :
    spi_0_stb   ? spi_0_dout[31:0]  :
    ptmr_stb    ? ptmr_dout[31:0]  :
    start_stb   ? start_dout[31:0]  :
    scr_stb     ? scr_dout[31:0] :
    32'h0;

  // bus ack demultiplexing
  // ======================
  assign bus_ack =
    prom_stb    ? prom_ack :
    ram_stb     ? ram_ack  :
    tmr_stb     ? tmr_ack  :
    lsb_stb     ? lsb_ack  :
    rs232_0_stb ? rs232_0_ack  :
    spi_0_stb   ? spi_0_ack  :
    ptmr_stb    ? ptmr_ack  :
    start_stb   ? start_ack :
    scr_stb     ? scr_ack :
    1'b0;

endmodule

`resetall
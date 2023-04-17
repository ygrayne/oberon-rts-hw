/**
  Top level definition p3-thm-de2-115
  --
  Architecture: THM
  --
  Base/origin:
    * THM-oberon
    * Project Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences

  * no video RAM
  * no keyboard and mouse
  * separate clock and reset, move clock into tech directory
  * move bio into board directory as lsb
  * improved SPI device
  * extended IO address space
  * 16 MB SDRAM
  * parameterised clock frequency for perpiherals
  * process timers (periodic)
  * (re-) start tables
  * system control and status, incl. error handling
  * buffered RS232 device
  * log buffer
  * watchdog
  * stack monitor
**/

`timescale 1ns / 1ps
`default_nettype none

`define CLOCK_FREQ 50_000_000
`define PROM_FILE "../../../platform/p3-thm-de2-115/promfiles/BootLoad-512k-64k.mem"  // for PROM
`define RS232_BUF_SLOTS 255
`define LOGBUF_ENTRIES 32

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
  // SD card (SPI)
  output sdcard_cs_n,
  output sdcard_sclk,
  output sdcard_mosi,
  input sdcard_miso,
  // RTC (SPI)
  output rtc_cs_n,
  output rtc_sclk,
  output rtc_mosi,
  input rtc_miso,
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
  input [3:0] btn_in_n,
  input [17:0] swi_in
);

  // clk
  wire clk_ok;                // clocks stable
  wire mclk;                  // memory clock, 100 MHz
  wire clk;                   // system clock, 50 MHz
  // reset
  wire rst_out;               // active high
  wire rst_out_n;             // active low
  // cpu
  wire bus_stb;
  wire bus_we;                // bus write enable
  wire [23:2] bus_addr;       // bus address (word address)
  wire [31:0] bus_din;        // bus data input, for reads
  wire [31:0] bus_dout;       // bus data output, for writes
  wire [31:0] cpu_spx;        // SP register value (for stack monitor)
  wire [31:0] cpu_lnkx;       // LNK register value (for calltrace)
  wire [23:0] cpu_pcx;        // PC value (for aborts, see sys ctrl)
  wire [31:0] cpu_irx;        // instruction register value (for calltrace)
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
  wire io_stb;                // i/o strobe
  // ms timer
  wire tmr_stb;
  wire [31:0] tmr_dout;       // data out: running milliseconds since reset
  wire tmr_ms_tick;           // millisecond timer tick
  wire tmr_ack;
  // lsb
  wire lsb_stb;
  wire [17:0] lsb_leds_r_in;  // signals in for red LEDs
  wire [31:0] lsb_dout;       // data out: buttons, switches
  wire [3:0] lsb_btn;         // button signals out
  wire [17:0] lsb_swi;        // button signals out
  wire lsb_ack;
  // start tables
  wire start_stb;
  wire [31:0] start_dout;     // data out: start-up table number, armed bit
  wire start_ack;
  // sys control and status
  wire scs_stb;
  wire rst;
  wire [31:0] scs_dout;       // data out: register content
  wire [7:0] scs_err_sig_in;  // error signals in
  wire scs_ack;
  // rs232
  wire rs232_0_stb;
  wire [31:0] rs232_0_dout;   // data out: received data, status
  wire rs232_0_ack;
  // spi
  wire spi_0_stb;
  wire [31:0] spi_0_dout;     // data out: received data, status
  wire spi_0_sclk_d;          // sclk signal from device
  wire spi_0_mosi_d;          // mosi signal from device
  wire spi_0_miso_d;          // miso signals to device
  wire [2:0] spi_0_cs_n_d;    // chip selects from device
  wire spi_0_ack;
  // proc periodic timing
  wire ptmr_stb;
  wire [31:0] ptmr_dout;      // proc timers data output (ready signals)
  wire ptmr_ack;
  // log buffer
  wire log_stb;
  wire [31:0] log_dout;       // log data output, log indices output
  wire log_ack;
  // watchdog
  wire wd_stb;
  wire [31:0] wd_dout;        // timeout value output
  wire wd_trig;               // watchdog trigger output
  wire wd_ack;
  // stack mmonitor
  wire stm_stb;
  wire [31:0] stm_dout;
  wire stm_trig_lim;          // stack limit trigger signal out
  wire stm_trig_hot;          // hot zone trigger signal out
  wire stm_ack;
  // call trace stacks
  wire cts_stb;
  wire [31:0] cts_dout;
  wire cts_ack;

  // clocks
  clk clk_0 (
    .clk_in(clk_in),
    .clk_ok(clk_ok),
    .clk_100_ps(sdram_clk),   // 100 MHz, phase-shifted
    .clk_100(mclk),           // 100 MHz
    .clk_50(clk)              // 50 MHz
  );

  // reset
  rst rst_0 (
    // in
    .clk_in(clk_in),          // 50 MHz "raw" input clock 
    .clk_ok(clk_ok),
    .rst_in_n(btn_in_n[3]),
    // out
    .rst_out(rst_out),
    .rst_out_n(rst_out_n)
  );

  // CPU
  cpu_x cpu_0 (
    .clk(clk),
    .rst(rst),
    .bus_stb(bus_stb),
    .bus_we(bus_we),
    .bus_addr(bus_addr[23:2]),
    .bus_din(bus_din[31:0]),
    .bus_dout(bus_dout[31:0]),
    .bus_ack(bus_ack),
    .spx(cpu_spx),
    .pcx(cpu_pcx),
    .irx(cpu_irx),
    .lnkx(cpu_lnkx)
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
  // uses one IO address
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
  // uses one IO address
  assign lsb_leds_r_in[17:0] = 18'b0;
  lsb_s lsb_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(lsb_stb),
    .we(bus_we),
    .leds_r_in(lsb_leds_r_in[17:0]),
    .data_in(bus_dout[31:0]),
    // out
    .data_out(lsb_dout[31:0]),
    .ack(lsb_ack),
    .btn_out(lsb_btn[3:0]),
    .swi_out(lsb_swi[17:0]),
    // external in
    .btn_in_n(btn_in_n[3:0]),
    .swi_in(swi_in[17:0]),
    // external out
    .leds_g(led_g[8:0]),
    .leds_r(led_r[17:0]),
    .hex7_n(hex7_n[6:0]),
    .hex6_n(hex6_n[6:0]),
    .hex5_n(hex5_n[6:0]),
    .hex4_n(hex4_n[6:0]),
    .hex3_n(hex3_n[6:0]),
    .hex2_n(hex2_n[6:0]),
    .hex1_n(hex1_n[6:0]),
    .hex0_n(hex0_n[6:0])
  );

  // (-re) start tables
  // uses one IO address
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

  // sys control and status
  // uses two consecutive IO addresses
  // order must correspond with values in SysCtrl.mod for correct logging
  assign scs_err_sig_in[7:0] = {3'b0, stm_trig_hot, stm_trig_lim, wd_trig, lsb_btn[1], 1'b0};
  scs scs_0 (
    // in
    .clk(clk),
    .restart(rst_out),
    .stb(scs_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .err_sig_in(scs_err_sig_in),
    .err_addr_in(cpu_pcx),
    .data_in(bus_dout[31:0]),
    // out
    .data_out(scs_dout[31:0]),
    .sys_rst(rst),
    .ack(scs_ack)
  );

  // RS232 buffered
  // uses two consecutive IO addresses
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
  // uses two consecutive IO addresses
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
    // external out
    .cs_n(spi_0_cs_n_d[2:0]),
    .sclk(spi_0_sclk_d),
    .mosi(spi_0_mosi_d),
    // external in
    .miso(spi_0_miso_d)
  );

  assign sdcard_cs_n = spi_0_cs_n_d[0];
  assign sdcard_sclk = spi_0_sclk_d;
  assign sdcard_mosi = spi_0_mosi_d;

  assign rtc_cs_n = spi_0_cs_n_d[1];
  assign rtc_sclk = spi_0_sclk_d;
  assign rtc_mosi = spi_0_mosi_d;

  assign spi_0_miso_d = sdcard_miso & rtc_miso;

  // process periodic timers
  // uses one IO address
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

  // log buffer
  // uses two consecutive IO addresses
  logbuf #(.num_entries(`LOGBUF_ENTRIES)) logbuf_0 (
    // in
    .clk(clk),
    .stb(log_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[15:0]),
    // out
    .data_out(log_dout[31:0]),
    .ack(log_ack)
  );

  // watchdog
  // uses one IO address
  watchdog watchdog_0 (
    // in
    .clk(clk),
    .rst(rst),
    .tick(tmr_ms_tick),
    .stb(wd_stb),
    .we(bus_we),
    .data_in(bus_dout[15:0]),
    // out
    .data_out(wd_dout[31:0]),
    .trig(wd_trig),
    .ack(wd_ack)
  );

  // stack monitor
  // uses four consecutive IO addresses
  stackmon stackmon_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(stm_stb),
    .we(bus_we),
    .addr(bus_addr[3:2]),
    .sp_in(cpu_spx[23:0]),
    .data_in(bus_dout[23:0]),
    // out
    .data_out(stm_dout[31:0]),
    .trig_lim(stm_trig_lim),
    .trig_hot(stm_trig_hot),
    .ack(stm_ack)
  );

 // call trace stacks
 // uses two consecutive IO addresses
 calltrace calltrace_0 (
   // in
   .clk(clk),
   .stb(cts_stb),
   .we(bus_we),
   .addr(bus_addr[2]),
   .ir_in(cpu_irx),
   .lnk_in(cpu_lnkx[23:0]),
   .data_in(bus_dout[23:0]),
   // out
   .data_out(cts_dout[31:0]),
   .ack(cts_ack)
 );


  // address decoding
  // ----------------

  // PROM: 2 KB @ 0xFFE000 => initial code address for CPU
  assign prom_stb = (bus_stb && bus_addr[23:12] == 12'hFFE && bus_addr[11] == 1'b0) ? 1'b1 : 1'b0;

  // RAM: (16 MB - 8 kB) @ 000000H
  assign ram_stb = (bus_stb && bus_addr[23:13] != 11'h7FF) ? 1'b1 : 1'b0;

  // I/O: 256 bytes (64 words) @ 0FFFF00H
  assign io_stb = (bus_stb && bus_addr[23:8] == 16'hFFFF) ? 1'b1 : 1'b0;

  // the traditional 16 IO addresses of (Embedded) Project Oberon
  assign spi_0_stb   = (io_stb && bus_addr[7:3] == 5'b11010)  ? 1'b1 : 1'b0;  // -48 (data), -44 (ctrl/status)
  assign rs232_0_stb = (io_stb && bus_addr[7:3] == 5'b11001)  ? 1'b1 : 1'b0;  // -56 (data), -52 (ctrl/status)
  assign lsb_stb     = (io_stb && bus_addr[7:2] == 6'b110001) ? 1'b1 : 1'b0;  // -60 note: system LEDs via LED()
  assign tmr_stb     = (io_stb && bus_addr[7:2] == 6'b110000) ? 1'b1 : 1'b0;  // -64

  // extended IO address range
  assign scs_stb     = (io_stb && bus_addr[7:3] == 5'b10111)  ? 1'b1 : 1'b0;  // -72
  assign cts_stb     = (io_stb && bus_addr[7:3] == 5'b10110)  ? 1'b1 : 1'b0;  // -80 (data), -76 (ctrl/status)
  assign stm_stb     = (io_stb && bus_addr[7:4] == 4'b1010)   ? 1'b1 : 1'b0;  // -96
  assign wd_stb      = (io_stb && bus_addr[7:2] == 6'b100100) ? 1'b1 : 1'b0;  // -112
  assign ptmr_stb    = (io_stb && bus_addr[7:2] == 6'b011111) ? 1'b1 : 1'b0;  // -132
  assign start_stb   = (io_stb && bus_addr[7:2] == 6'b010001) ? 1'b1 : 1'b0;  // -188
  assign log_stb     = (io_stb && bus_addr[7:3] == 5'b00100)  ? 1'b1 : 1'b0;  // -224 (data), -220 (indices)


  // data out multiplexing
  // ---------------------
  assign bus_din[31:0] =
    prom_stb    ? prom_dout[31:0] :
    ram_stb     ? ram_dout[31:0]  :
    spi_0_stb   ? spi_0_dout[31:0]  :
    rs232_0_stb ? rs232_0_dout[31:0]  :
    lsb_stb     ? lsb_dout[31:0]  :
    tmr_stb     ? tmr_dout[31:0]  :
    scs_stb     ? scs_dout[31:0] :
    cts_stb     ? cts_dout[31:0]  :
    stm_stb     ? stm_dout[31:0]  :
    wd_stb      ? wd_dout[31:0] :
    ptmr_stb    ? ptmr_dout[31:0]  :
    start_stb   ? start_dout[31:0]  :
    log_stb     ? log_dout[31:0] :
    32'h0;


  // bus ack multiplexing
  // --------------------
  assign bus_ack =
    prom_stb    ? prom_ack :
    ram_stb     ? ram_ack  :
    spi_0_stb   ? spi_0_ack  :
    rs232_0_stb ? rs232_0_ack  :
    lsb_stb     ? lsb_ack  :
    tmr_stb     ? tmr_ack  :
    scs_stb     ? scs_ack :
    cts_stb     ? cts_ack :
    stm_stb     ? stm_ack :
    wd_stb      ? wd_ack :
    ptmr_stb    ? ptmr_ack  :
    start_stb   ? start_ack :
    log_stb     ? log_ack :
    1'b0;

endmodule

`resetall

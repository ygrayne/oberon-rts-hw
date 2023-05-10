/**
  RISC5 processor definition for Oberon RTS p5-eth-de2-115
  --
  Architecture: ETH
  Board and technology: DE2-115, Altera Cyclone IV
  --
  Base/origin:
    * THM-oberon
    * Project Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

`define CLOCK_FREQ 25_000_000
`define PROM_FILE "../../platform/p5-eth-de2-115/bootload/BootLoad-256k-64k.mem"  // for PROM
`define RS232_BUF_SLOTS 256   // RS232 buffer size, for tx and rx
`define LOGBUF_ENTRIES 32
`define CALLTRACE_SLOTS 32    // depth of each calltrace stack
`define NUM_GPIO 4

module RISC5Top (
  // clock
  input clk_in,
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
  input [17:0] swi_in,
  // GPIO
  inout [`NUM_GPIO-1:0] gpio
  // SRAM
//  output wire [19:0] sram_addr,
//  inout wire [15:0] sram_data,
//  output wire sram_ce_n,
//  output wire sram_oe_n,
//  output wire sram_we_n,
//  output wire sram_ub_n,
//  output wire sram_lb_n
);

  // clk
  wire clk_ok;                // clocks stable
  wire clk;                   // system clock, 25 MHz
  wire clk_sram;
  wire clk_sram_ps;           // memory write clock
  // reset
  wire rst_out;               // active high
  // cpu
  wire [23:0] adr;            // address bus
  wire [31:0] inbus;          // data to RISC core
  wire [31:0] inbus0;         // data & code from RAM
  wire [31:0] codebus;        // code to RISC core from RAM
  wire [31:0] outbus;         // data from RISC core
  wire rd;                    // CPU read
  wire wr;                    // CPU write
  wire ben;                   // CPU byte enable
  wire irq;                   // interrupt request to CPU
  // cpu extensions
  wire cpu_intack;            // CPU out: interrupt ack
  wire cpu_rti;               // CPU out: return from interrupt
  wire cpu_intabort;          // CPU in: abort interrupt, "return" to addr 0, not interrupted code
  wire [31:0] cpu_spx;        // CPU out: stack pointer
  wire [31:0] cpu_lnkx;       // CPU out: link register
  wire [31:0] cpu_irx;        // CPU out: instruction register
  wire [23:0] cpu_spcx;       // CPU out: SPC register (saved PC on interrupt * 4)
  wire [21:0] cpu_pcx;        // CPU out: current PC
  // prom
  wire prom_stb;
  wire [31:0] prom_dout;
  wire prom_ack;
  // sram
  wire sram_stb;
  wire [31:0] sram_dout;
  wire sram_ack;
  // i/o
  wire io_en;                 // i/o enable
  wire [31:0] io_out;         // io devices output
  // ms timer
  wire tmr_stb;
  wire [31:0] tmr_dout;       // data out: running milliseconds since reset
  wire tmr_ms_tick;           // millisecond timer tick
  wire tmr_ack;
  // lsb
  wire lsb_stb;
  wire [17:0] lsb_leds_r_in;  // signals in for red LEDs
  wire [31:0] lsb_dout;       // buttons, switches
  wire [3:0] lsb_btn;         // button signals out
  wire [17:0] lsb_swi;        // switch signals out
  wire lsb_ack;
  // rs232
  wire rs232_0_stb;
  wire [31:0] rs232_0_dout;   // received data, status
  wire rs232_0_ack;
  // spi
  wire spi_0_stb;
  wire [31:0] spi_0_dout;     // received data, status
  wire spi_0_sclk_d;          // sclk signal from device
  wire spi_0_mosi_d;          // mosi signal from device
  wire spi_0_miso_d;          // miso signals to device
  wire [2:0] spi_0_cs_n_d;    // chip selects from device
  wire spi_0_ack;
  // sys control and status
  wire scs_stb;
  wire rst;                   // system reset signal out, active high
  wire rst_n;                 // system reset signal out, active low
  wire [31:0] scs_dout;       // register content, error data
  wire [7:0] scs_err_sig_in;  // error signals in
  wire [4:0] scs_cp_pid;      // current process' pid out
  wire scs_ack;
  // proc periodic timing
  wire ptmr_stb;
  wire [31:0] ptmr_dout;      // proc timers ready signals
  wire ptmr_ack;
  // log buffer
  wire log_stb;
  wire [31:0] log_dout;       // log data output, log indices
  wire log_ack;
  // watchdog
  wire wd_stb;
  wire [31:0] wd_dout;        // timeout value
  wire wd_trig;               // watchdog trigger signal out
  wire wd_ack;
  // stack mmonitor
  wire stm_stb;
  wire [31:0] stm_dout;       // stack limit, hotzone address, lowest address reached (usage)
  wire stm_trig_lim;          // stack limit trigger signal out
  wire stm_trig_hot;          // hot zone trigger signal out
  wire stm_ack;
  // call trace stacks
  wire cts_stb;
  wire [31:0] cts_dout;       // stack values output, status output
  wire cts_ack;
  // start tables
  wire start_stb;
  wire [31:0] start_dout;     // data out: start-up table number, armed bit
  wire start_ack;
  // gpio
  wire gpio_stb;
  wire [31:0] gpio_dout;      // pin data, in/out control status
  wire gpio_ack;


  // clocks
  clocks clocks_0 (
    // in
    .clk_in(clk_in),
    //out
    .clk_ok(clk_ok),
    .clk_sram_ps(clk_sram_ps),  // 50 MHz, 180 deg
    .clk_sram(clk_sram),        // 50 MHz
    .clk_sys(clk)               // 25 MHz
  );

  // reset
  reset reset_0 (
    // in
    .clk(clk),
    .clk_ok(clk_ok),
    .rst_in_n(btn_in_n[3]),
    // out
    .rst_out(rst_out)
  );

  // CPU
  risc5_1 #(.start_addr(24'hFFE000)) risc5_0 (
    // in
    .clk(clk),
    .rst(rst_n),
    .irq(irq),
    .codebus(codebus[31:0]),
    .inbus(inbus[31:0]),
    // out
    .rd(rd),
    .wr(wr),
    .ben(ben),
    .adr(adr[23:0]),
    .outbus(outbus[31:0]),
    // extensions in
    .intabort(cpu_intabort),
    // extensions out
    .intackx(cpu_intack),
    .rtix(cpu_rti),
    .spx(cpu_spx[31:0]),
    .spcx(cpu_spcx[23:0]),
    .lnkx(cpu_lnkx[31:0]),
    .irx(cpu_irx[31:0]),
    .pcx(cpu_pcx[21:0])
  );

  // boot ROM
  prom #(.mem_file(`PROM_FILE)) prom_0 (
    // in
    .clk(~clk),
    .addr(adr[10:2]),
    // out
    .data_out(prom_dout[31:0])
  );

//  // SRAM
//  sram sram_0 (
//    .clk(clk_sram),
//    .clk_ps(clk_sram_ps),
//    .rst(rst),
//    .en(sram_stb),
//    .be(ben),
//    .we(wr),
//    .addr(adr[20:0]),
//    .data_in(outbus[31:0]),
//    .data_out(inbus0[31:0]),
//    .sram_addr(sram_addr[19:0]),
//    .sram_data(sram_data[15:0]),
//    .sram_ce_n(sram_ce_n),
//    .sram_oe_n(sram_oe_n),
//    .sram_we_n(sram_we_n),
//    .sram_ub_n(sram_ub_n),
//    .sram_lb_n(sram_lb_n)
//  );

//  sram_test sram_test_0 (
//    .clk(clk),
//    .clk_sram(clk_sram),
//    .clk_sram_ps(clk_sram_ps),
//    .rst(rst),
//    .stb(sram_stb),
//    .we(wr),
//    .be(ben),
//    .addr(adr[2]),
//    .data_in(outbus[31:0]),
//    .data_out(sram_dout[31:0]),
//    .ack(sram_ack),
//    .sram_addr(sram_addr[19:0]),
//    .sram_data(sram_data[15:0]),
//    .sram_ce_n(sram_ce_n),
//    .sram_oe_n(sram_oe_n),
//    .sram_we_n(sram_we_n),
//    .sram_ub_n(sram_ub_n),
//    .sram_lb_n(sram_lb_n)
//  );

  // BRAM 256
  ramg5 #(.num_kbytes(256)) ram_0 (
    // in
    .clk(clk),
    .wr(wr),
    .be(ben),
    .addr(adr[17:0]),
    .data_in(outbus[31:0]),
    // out
    .data_out(inbus0[31:0])
  );


  // ms timer
  // uses one IO address
  ms_timer #(.clock_freq(`CLOCK_FREQ)) tmr_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(tmr_stb),
    .we(wr),
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
    .we(wr),
    .leds_r_in(lsb_leds_r_in[17:0]),
    .data_in(outbus[31:0]),
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

  // RS232 buffered
  // uses two consecutive IO addresses
  rs232 #(.clock_freq(`CLOCK_FREQ), .buf_slots(`RS232_BUF_SLOTS)) rs232_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(rs232_0_stb),
    .we(wr),
    .addr(adr[2]),
    .data_in(outbus[7:0]),
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
    .we(wr),
    .addr(adr[2]),
    .data_in(outbus[31:0]),
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

  // sys control and status
  // uses two consecutive IO addresses
  // order must correspond with values in SysCtrl.mod for correct logging
  assign scs_err_sig_in[7:0] = {3'b0, stm_trig_hot, stm_trig_lim, wd_trig, 1'b0, lsb_btn[0]};
  scs scs_0 (
    // in
    .clk(clk),
    .restart(rst_out),
    .stb(scs_stb),
    .we(wr),
    .addr(adr[2]),
    .err_sig(scs_err_sig_in),
    .err_addr({cpu_pcx[21:0], 2'b0}),
    .data_in(outbus[31:0]),
    // out
    .data_out(scs_dout[31:0]),
    .sys_rst(rst),
    .sys_rst_n(rst_n),
    .cp_pid(scs_cp_pid),
    .ack(scs_ack)
  );

  // process periodic timers
  // uses one IO address
  proctimers ptmr_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(ptmr_stb),
    .we(wr),
    .tick(tmr_ms_tick),
    .data_in(outbus[31:0]),
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
    .we(wr),
    .addr(adr[2]),
    .data_in(outbus[15:0]),
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
    .we(wr),
    .data_in(outbus[15:0]),
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
    .we(wr),
    .addr(adr[3:2]),
    .sp_in(cpu_spx[23:0]),
    .data_in(outbus[23:0]),
    // out
    .data_out(stm_dout[31:0]),
    .trig_lim(stm_trig_lim),
    .trig_hot(stm_trig_hot),
    .ack(stm_ack)
  );

 // call trace stacks
 // uses two consecutive IO addresses
 calltrace #(.num_slots(`CALLTRACE_SLOTS)) calltrace_0 (
   // in
   .clk(clk),
   .stb(cts_stb),
   .we(wr),
   .addr(adr[2]),
   .ir_in(cpu_irx),
   .lnk_in(cpu_lnkx[23:0]),
   .cp_pid(scs_cp_pid),
   .data_in(outbus[23:0]),
   // out
   .data_out(cts_dout[31:0]),
   .ack(cts_ack)
 );

  // (-re) start tables
  // uses one IO address
  start start_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(start_stb),
    .we(wr),
    .data_in(outbus[15:0]),
    // out
    .data_out(start_dout[31:0]),
    .ack(start_ack)
  );

  // GPIO
  // uses two consecutive IO addresses
  gpio #(.num_gpio(`NUM_GPIO)) gpio_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(gpio_stb),
    .we(wr),
    .addr(adr[2]),
    .data_in(outbus[`NUM_GPIO-1:0]),
    // out
    .data_out(gpio_dout),
    .ack(gpio_ack),
    // external
    .io_pin(gpio[`NUM_GPIO-1:0])
  );

  // address decoding
  // ----------------

//  assign sram_stb = (adr[23:13] != 11'h7FF) ? 1'b1 : 1'b0;

  // codebus multiplexer
  // PROM: 2 kB @ 0FFE000H => initial code address for CPU
  assign prom_stb = (adr[23:12] == 12'hFFE && adr[11] == 1'b0) ? 1'b1 : 1'b0;
  assign codebus[31:0] = ~prom_stb ? inbus0[31:0] : prom_dout[31:0];

  // inbus multiplexer
  // I/O: 256 bytes (64 words) @ 0FFFF00H
  // there's space for three more IO blocks "above" the PROM region
  assign io_en = (adr[23:8] == 16'hFFFF) ? 1'b1 : 1'b0;
  assign inbus[31:0] = ~io_en ? inbus0[31:0] : io_out[31:0];

  // the traditional 16 IO addresses of (Embedded) Project Oberon
  assign gpio_stb    = (io_en && adr[7:3] == 5'b11100)  ? 1'b1 : 1'b0;  // -32 (data), -28 (ctrl/status)
  assign spi_0_stb   = (io_en && adr[7:3] == 5'b11010)  ? 1'b1 : 1'b0;  // -48 (data), -44 (ctrl/status)
  assign rs232_0_stb = (io_en && adr[7:3] == 5'b11001)  ? 1'b1 : 1'b0;  // -56 (data), -52 (ctrl/status)
  assign lsb_stb     = (io_en && adr[7:2] == 6'b110001) ? 1'b1 : 1'b0;  // -60 note: system LEDs via LED()
  assign tmr_stb     = (io_en && adr[7:2] == 6'b110000) ? 1'b1 : 1'b0;  // -64

  // extended IO address range
  assign scs_stb     = (io_en && adr[7:3] == 5'b10111)  ? 1'b1 : 1'b0;  // -72
  assign cts_stb     = (io_en && adr[7:3] == 5'b10110)  ? 1'b1 : 1'b0;  // -80, -76 (ctrl/status)
  assign stm_stb     = (io_en && adr[7:4] == 4'b1010)   ? 1'b1 : 1'b0;  // -96
//  assign sram_stb    = (io_en && adr[7:3] == 5'b10011) ? 1'b1 : 1'b0;   // -104
  assign wd_stb      = (io_en && adr[7:2] == 6'b100100) ? 1'b1 : 1'b0;  // -112
  assign ptmr_stb    = (io_en && adr[7:2] == 6'b011111) ? 1'b1 : 1'b0;  // -132
  assign start_stb   = (io_en && adr[7:2] == 6'b010001) ? 1'b1 : 1'b0;  // -188
  assign log_stb     = (io_en && adr[7:3] == 5'b00100)  ? 1'b1 : 1'b0;  // -224 (data), -220 (indices)


  // data out multiplexing
  // ---------------------
  assign io_out[31:0] =
    gpio_stb    ? gpio_dout[31:0] :
    spi_0_stb   ? spi_0_dout :
    rs232_0_stb ? rs232_0_dout[31:0] :
    lsb_stb     ? lsb_dout[31:0] :
    tmr_stb     ? tmr_dout[31:0] :
    scs_stb     ? scs_dout[31:0] :
    cts_stb     ? cts_dout[31:0]  :
    stm_stb     ? stm_dout[31:0]  :
//    sram_stb    ? sram_dout[31:0] :
    wd_stb      ? wd_dout[31:0] :
    ptmr_stb    ? ptmr_dout[31:0] :
    start_stb   ? start_dout[31:0] :
    log_stb     ? log_dout[31:0] :
    32'h0;

endmodule

`resetall

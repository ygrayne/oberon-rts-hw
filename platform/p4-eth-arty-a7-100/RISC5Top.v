/**
  RISC5 processor definition for Oberon RTS p4-eth-arty-a7-100
  --
  Architecture: ETH
  Board and technology: Arty-A7-100, Xilinx Artix-7
  --
  Origins:
  * Project Oberon, NW 14.6.2018
  * Embedded Project Oberon for Arty-A7, v8.0, CFB 16.10.2021
  --
  Adaptations and extensions by Gray, gray@grayraven.org
  https://oberon-rts.org/licences
  --
  Changes/extensions (before stripping...):
  * extension of the IO address space to 1024 bytes
  * three RS232 devices, buffered
  * three SPI devices, two unbuffered, one buffered
  * stack overflow monitor
  * watchdog timer
  * logging facility
  * process timers
  * interrupt controller with eight interrupt lines
  * program/command start tables
  --
  Stripping down for building the equivalant for THM (March 2023)
  * remove two SPI devices
  * remove two RS232 devices
  * remove cycle counter
  * remove GPIO
  * remove proc delay
  * remove proc signal
  * remove proc monitor
  * remove stack monitor (also in prom file)
  * remove call tracing (also in prom file)
  * remove watchdog
  * remove interrupt ctrl
  * remove dev sig selector
  * remove log buffers (*)
  --
  Adding some new modules, replacing direct top level functionality
  * sys ctrl reg
  * reset device
  * milliseconds timer device
  --
  Re-adding stuff
  * log buffer
  * watchdog
  * stack monitor
  --
  Notes:
  * all ack signals are unused, they are for THM compatibility only
  * apart from the CPU, all modules use the active high reset signal
**/

`timescale 1ns / 1ps
`default_nettype none

`define CLOCK_FREQ 40_000_000
`define NUM_PROC_CTRL 16
`define MEM_BLK_SIZE 'h10000    // 64k
`define PROM_FILE "../../../platform/p4-eth-arty-a7-100/promfiles/BootLoad-512k-64k.mem"
`define RS232_BUF_SLOTS 256
`define LOGBUF_ENTRIES 32

  module RISC5Top (
  // clock
  input wire clk_in,
  // RS 232
  input  wire rs232_0_rxd,
  output wire rs232_0_txd,
  // SD card (SPI CS = 0)
  input wire sdcard_miso,
  output wire sdcard_cs_n,
  output wire sdcard_sclk,
  output wire sdcard_mosi,
  // SPI (other than SD card)
  input wire [1:1] spi_0_miso,
  output wire [1:1] spi_0_cs_n,
  output wire [1:1] spi_0_sclk,
  output wire [1:1] spi_0_mosi,
  // LEDs, switches, buttons
  input wire [3:0] btn_in,
  input wire [3:0] swi_in,
  output wire [7:0] sys_leds,       // on Pmod board
  output wire [3:0] leds_g          // on Arty board
 );

  // clk
  wire clk;                   // system clock
  wire clk2x;                 // memory clock
  wire clk_ok;                // clocks stable
  // reset
  wire rst_n;                 // active low
  wire rst;                   // active high
  wire rst_trig;              // reset triggers
  // cpu
  wire [23:0] adr;            // address bus
  wire [31:0] inbus;          // data to RISC core
  wire [31:0] inbus0;         // data & code from RAM
  wire [31:0] romout;         // code to RISC core from PROM
  wire [31:0] codebus;        // code to RISC core from RAM
  wire [31:0] outbus;         // data from RISC core
  wire [31:0] io_out;         // io devices output
  wire rd;                    // CPU read
  wire wr;                    // CPU write
  wire ben;                   // CPU byte enable
  wire irq_req;               // interrupt request to CPU
  // cpu extensions (currently unused)
  wire cpu_intack;            // CPU out: interrupt ack
  wire cpu_rti;               // CPU out: return from interrupt
  wire cpu_intabort;          // CPU in: abort interrupt, "return" to addr 0, not interrupted code
  wire [31:0] cpu_spx;        // CPU out: stack pointer
  wire [31:0] cpu_lnkx;       // CPU out: link register
  wire [31:0] cpu_irx;        // CPU out: instruction register
  wire [23:0] cpu_spcx;       // CPU out: SPC register (saved PC on interrupt * 4)
  wire [21:0] cpu_pcx;        // CPU out: current PC

  // io
  wire ioenb;                 // IO enable
  // ms timer
  wire tmr_stb;
  wire [31:0] tmr_dout;       // data out: running milliseconds since reset
  wire tmr_ms_tick;           // millisecond timer tick
  wire tmr_ack;
  // lsb
  wire lsb_stb;
  wire [3:0] lsb_leds_g_in;   // signals in for greed LEDs on board
  wire [31:0] lsb_dout;       // data out: buttons, switches
  wire [3:0] lsb_btn;         // button signals out
  wire [3:0] lsb_swi;         // switch signals out
  wire lsb_ack;
  // start tables
  wire start_stb;
  wire [31:0] start_dout;     // data out: start-up table number, armed bit
  wire start_ack;
  // sys ctrl
  wire scr_stb;
  wire [31:0] scr_dout;       // data out: register content
  wire scr_sys_rst;           // system reset signal out
  wire [7:0] scr_err_sig_in;  // error signals in
  wire scr_ack;
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
  wire [31:0] wd_dout;
  wire wd_trig;
  wire wd_ack;
  // stack monitor
  wire stm_stb;
  wire [31:0] stm_dout;
  wire stm_trig_lim;
  wire stm_trig_hot;
  wire stm_ack;
  // calltrace stacks
  wire cts_stb;
  wire [31:0] cts_dout;
  wire cts_ack;

  // clocks
  clocks clocks_0 (
    .clk_in(clk_in),
    .rst(1'b0),
    .outclk_0(clk),
    .outclk_1(clk2x),
    .locked(clk_ok)
  );

  // reset
  assign rst_trig = scr_sys_rst;
  rst rst_0 (
    // in
    .clk(clk),
    .clk_ok(clk_ok),
    .rst_in(rst_trig),
    // out
    .rst_n(rst_n),
    .rst(rst)
  );

  // CPU
  risc5_cpu risc5_cpu_0 (
    .clk(clk),
    .rst(rst_n),
    .irq(irq_req),
    .rd(rd),
    .wr(wr),
    .ben(ben),
    .adr(adr),
    .codebus(codebus),
    .inbus(inbus),
    .outbus(outbus),
    .intackx(cpu_intack),
    .rtix(cpu_rti),
    .intabort(cpu_intabort),
    .spx(cpu_spx),
    .spcx(cpu_spcx),
    .lnkx(cpu_lnkx),
    .irx(cpu_irx),
    .pcx(cpu_pcx)
  );

  // boot ROM
  prom #(.memfile(`PROM_FILE)) prom_0 (
    .clk(~clk),
    .adr(adr[10:2]),
    .data_out(romout)
  );

  // BRAM 512k (8 blocks of 64k)
  ramg #(.mem_blocks(8)) ram_0 (
    .clk(clk2x),
    .wr(wr),
    .be(ben),
    .adr(adr[18:0]),
    .wdata(outbus),
    .rdata(inbus0)
  );

  // ms timer
  // uses one IO address
  tmr #(.clock_freq(`CLOCK_FREQ)) tmr_0 (
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
  assign lsb_leds_g_in[3:0] = 4'b0;
  lsb_s lsb_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(lsb_stb),
    .we(wr),
    .leds_g_in(lsb_leds_g_in),
    .data_in(outbus[31:0]),
    // out
    .data_out(lsb_dout),
    .btn_out(lsb_btn),
    .swi_out(lsb_swi),
    .ack(lsb_ack),
    // external in
    .btn_in(btn_in),
    .swi_in(swi_in),
    // external out
    .leds_sys(sys_leds),
    .leds_g(leds_g)
  );

  // (re-) start tables
  // uses one IO address
  start start_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(start_stb),
    .we(wr),
    .data_in(outbus[15:0]),
    // out
    .data_out(start_dout),
    .ack(start_ack)
  );

  // sys control
  // uses two consecutive IO addresses
  // order must correspond with values in SysCtrl.mod for correct logging
  assign scr_err_sig_in[7:0] = {3'b0, stm_trig_hot, stm_trig_lim, wd_trig, lsb_btn[1], lsb_btn[0]};
  sysctrl sysctrl_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(scr_stb),
    .we(wr),
    .addr(adr[2]),
    .err_sig_in(scr_err_sig_in),
    .err_addr_in({cpu_pcx, 2'b0}), // PC is 22 bit word aligned
    .data_in(outbus[31:0]),
    // out
    .data_out(scr_dout[31:0]),
    .sys_rst(scr_sys_rst),
    .ack(scr_ack)
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
    .clk(clk),
    .rst(rst),
    .stb(spi_0_stb),
    .we(wr),
    .addr(adr[2]),
    .data_in(outbus[31:0]),
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

  assign spi_0_cs_n[1] = spi_0_cs_n_d[1];
  assign spi_0_sclk[1] = spi_0_sclk_d;
  assign spi_0_mosi[1] = spi_0_mosi_d;

  assign spi_0_miso_d = sdcard_miso & spi_0_miso;

  // process periodc timing
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
    .clk(clk),
    .rst(rst),
    .stb(stm_stb),
    .we(wr),
    .addr(adr[3:2]),
    .sp_in(cpu_spx[23:0]),
    .data_in(outbus[23:0]),
    .data_out(stm_dout),
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
    .we(wr),
    .addr(adr[2]),
    .ir_in(cpu_irx),
    .lnk_in(cpu_lnkx[23:0]),
    .data_in(outbus[23:0]),
    // out
    .data_out(cts_dout[31:0]),
    .ack(cts_ack)
  );

  // address decoding
  // ----------------

  // codebus multiplexer
  // PROM: 2 kB @ 0FFE000H => initial code address for CPU
  wire promswitch = (adr[23:12] == 12'hFFE && adr[11] == 1'b0) ? 1'b1 : 1'b0;
  assign codebus = promswitch ? romout : inbus0;

  // inbus multiplexer
  // I/O: 256 bytes (64 words) @ 0FFFF00H
  assign inbus = ~ioenb ? inbus0 : io_out;
  assign ioenb = (adr[23:8] == 16'hFFFF) ? 1'b1 : 1'b0;

  // the traditional 16 IO addresses of (Embedded) Project Oberon
  assign spi_0_stb   = (ioenb && adr[7:3] == 5'b11010)  ? 1'b1 : 1'b0;  // -48 (data), -44 (ctrl/status)
  assign rs232_0_stb = (ioenb && adr[7:3] == 5'b11001)  ? 1'b1 : 1'b0;  // -56 (data), -52 (ctrl/status)
  assign lsb_stb     = (ioenb && adr[7:2] == 6'b110001) ? 1'b1 : 1'b0;  // -60 note: system LEDs via LED()
  assign tmr_stb     = (ioenb && adr[7:2] == 6'b110000) ? 1'b1 : 1'b0;  // -64

  // extended IO address range
  assign scr_stb     = (ioenb && adr[7:3] == 5'b10111)  ? 1'b1 : 1'b0;  // -72
  assign cts_stb     = (ioenb && adr[7:3] == 5'b10110)  ? 1'b1 : 1'b0;  // -80, -76 (ctrl/status)
  assign stm_stb     = (ioenb && adr[7:4] == 4'b1010)   ? 1'b1 : 1'b0;  // -96
  assign wd_stb      = (ioenb && adr[7:2] == 6'b100100) ? 1'b1 : 1'b0;  // -112
  assign ptmr_stb    = (ioenb && adr[7:2] == 6'b011111) ? 1'b1 : 1'b0;  // -132
  assign start_stb   = (ioenb && adr[7:2] == 6'b010001) ? 1'b1 : 1'b0;  // -188
  assign log_stb     = (ioenb && adr[7:3] == 5'b00100)  ? 1'b1 : 1'b0;  // -224 (data), -220 (indices)


  // data out multiplexing
  // ---------------------
  assign io_out[31:0] =
    spi_0_stb   ? spi_0_dout :
    rs232_0_stb ? rs232_0_dout[31:0] :
    lsb_stb     ? lsb_dout[31:0] :
    tmr_stb     ? tmr_dout[31:0] :
    scr_stb     ? scr_dout[31:0] :
    cts_stb     ? cts_dout[31:0]  :
    stm_stb     ? stm_dout[31:0]  :
    wd_stb      ? wd_dout[31:0] :
    ptmr_stb    ? ptmr_dout[31:0] :
    start_stb   ? start_dout[31:0] :
    log_stb     ? log_dout[31:0] :
    32'h0;

endmodule

`resetall

//  echo echo_0 (
//    // in
//    .clk(clk),
//    .stb(log_stb),
//    .we(wr),
//    .addr(adr[2]),
//    .data_in(outbus[31:0]),
//    // out
//    .data_out(log_dout[31:0]),
//    .ack(log_ack)
//  );

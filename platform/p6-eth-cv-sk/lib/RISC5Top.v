/**
  RISC5 CPU and environment definition for Oberon RTS p6-eth-cv-sk
  --
  Architecture: ETH
  Board and technology: Terasic Cyclone V Starter Kit, Altera Cyclone V GX
  --
  Base/origin:
    * Project Oberon
    * THM-oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module RISC5Top #(
  parameter
    clock_freq = 25_000_000,  // as set in module 'clocks'
//    prom_file = "../../platform/p6-eth-cv-sk/bootload/BootLoad-512k-64k.mem",
//    prom_file = "../../platform/p6-eth-cv-sk/bootload/BootLoad-384k-64k.mem",
//    prom_file = "../../platform/p6-eth-cv-sk/bootload/BootLoad-416k-64k.mem",
    prom_file = "../../platform/p6-eth-cv-sk/bootload/BootLoad.mem",
    mem_lim = 'h68000,        // RAM size
    stack_org = 'h58000,      // initial stack pointer value
    stack_size = 'h4000,
    rs232_buf_slots = 256,    // RS232 buffer size, same for for tx and rx
    logbuf_entries = 32,
    calltrace_slots = 32,     // depth of each calltrace stack
    num_gpio = 26
  )(
  // clock
  input clk_in,
  // RS-232
  input rs232_0_rxd,
  output rs232_0_txd,
  // SD card (SPI CS = 0)
  output sdcard_cs_n,
  output sdcard_sclk,
  output sdcard_mosi,
  input sdcard_miso,
  // SPI CS = 1 and 2
  output wire [2:1] spi_cs_n,
  output wire [2:1] spi_sclk,
  output wire [2:1] spi_mosi,
  input wire [2:1] spi_miso,
  // LEDs, switches, buttons, 7-segment
  output [7:0] led_g,
  output [9:0] led_r,
  output [6:0] hex1_n,
  output [6:0] hex0_n,
  input [3:0] btn_in_n,
  input [9:0] swi_in,
  // GPIO
  inout [num_gpio-1:0] gpio,
  // I2C
  inout wire i2c_scl,
  inout wire i2c_sda,
  // SRAM
  output wire [17:0] sram_addr,
  inout wire [15:0] sram_data,
  output wire sram_ce_n,
  output wire sram_oe_n,
  output wire sram_we_n,
  output wire sram_ub_n,
  output wire sram_lb_n
);

  // clk
  wire clk_ok;                // clocks stable
  wire clk;
  wire clk_sram;
//  wire clk_sram_ps;
  wire clk_rst;
  // reset
  wire rst_out;               // active high
  // cpu
  wire [23:0] cpu_adr;        // address bus
  wire [31:0] cpu_inbus;      // data to CPU from RAM or IO
  wire [31:0] cpu_codebus;    // code to CPU from RAM or ROM
  wire [31:0] cpu_outbus;     // data from RISC core
  wire cpu_rd;                // CPU read signal
  wire cpu_wr;                // CPU write signal
  wire cpu_ben;               // CPU byte enable
  wire cpu_irq;               // interrupt request to CPU
  wire cpu_wait;
  // cpu extensions
  wire cpu_intack;            // CPU out: interrupt ack
  wire cpu_rti;               // CPU out: return from interrupt
  wire cpu_intabort;          // CPU in: abort interrupt, "return" to addr 0, not interrupted code
  wire [31:0] cpu_spx;        // CPU out: stack pointer
  wire [31:0] cpu_lnkx;       // CPU out: link register
  wire [31:0] cpu_irx;        // CPU out: instruction register
  wire [23:0] cpu_spcx;       // CPU out: SPC register (saved PC on interrupt * 4)
  wire [21:0] cpu_pcx;        // CPU out: program counter
  // prom
  wire prom_stb;
  wire [31:0] prom_dout;      // code from PROM
  // ram
  wire ram_stb;
  wire [31:0] ram_dout;       // data & code from RAM
  // sram test
  wire sram_stb;
  wire [31:0] sram_dout;
  wire wait_req;
  wire sram_ack;
  // i/o
  wire io_en;                 // i/o enable
  wire [31:0] io_out;         // io devices output
  // ms timer
  wire tmr_stb;
  wire [31:0] tmr_dout;       // running milliseconds since reset
  wire tmr_ms_tick;           // millisecond timer tick
  wire tmr_ack;
  // lsb
  wire lsb_stb;
  wire [9:0] lsb_leds_r_in;  // direct signals in for red LEDs
  wire [31:0] lsb_dout;      // buttons, switches
  wire [3:0] lsb_btn;        // button signals out
  wire [9:0] lsb_swi;        // switch signals out
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
  wire [7:0] scs_err_sig_in;  // direct error signals in (clk synched)
  wire [4:0] scs_cp_pid;      // current process' pid out
  wire scs_ack;
  // proc periodic timing
  wire ptmr_stb;
  wire [31:0] ptmr_dout;      // proc timers ready signals
  wire ptmr_ack;
  // log buffer
  wire log_stb;
  wire [31:0] log_dout;       // log data output, stored log indices
  wire log_ack;
//  // watchdog
//  wire wd_stb;
//  wire [31:0] wd_dout;        // timeout value
  wire wd_trig;               // watchdog trigger signal out
//  wire wd_ack;
  // stack monitor
  wire stm_stb;
  wire [31:0] stm_dout;       // stack limit, hotzone address, lowest address reached (stack usage)
  wire stm_trig_lim;          // stack limit trigger signal out
  wire stm_trig_hot;          // hot zone trigger signal out
  wire stm_ack;
//  // call trace stacks
//  wire cts_stb;
//  wire [31:0] cts_dout;       // stack values output, status output
//  wire cts_ack;
  // (re-) start tables
  wire start_stb;
  wire [31:0] start_dout;     // start-up table number, armed bit
  wire start_ack;
  // gpio
  wire gpio_stb;
  wire [31:0] gpio_dout;      // pin data, in/out control status
  wire gpio_ack;
  // i2c
  wire i2c_stb;
  wire [31:0] i2c_dout;
  wire i2c_ack;
  // sys config
  wire scfg_stb;
  wire [31:0] scfg_dout;
  wire scfg_ack;
//  // echo
//  wire echo_stb;
//  wire [31:0] echo_dout;
//  wire echo_ack;

  // clocks
  clocks clocks_0 (
    // in
    .rst(clk_rst),
    .clk_in(clk_in),
    //out
    .clk_ok(clk_ok),
    .clk(clk),
    .clk_2x(clk_sram)
//    .clk_2x_ps(clk_sram_ps)
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
//  assign cpu_wait= lsb_btn[1];
  risc5_2 #(.start_addr(24'hFFE000), .init_sp(32'h58000)) risc5_0 (
    // in
    .clk(clk),
    .rst(rst_n),
    .wait_req(cpu_wait),
    .irq(cpu_irq),
    .codebus(cpu_codebus[31:0]),
    .inbus(cpu_inbus[31:0]),
    // out
    .rd(cpu_rd),
    .wr(cpu_wr),
    .ben(cpu_ben),
    .adr(cpu_adr[23:0]),
    .outbus(cpu_outbus[31:0]),
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
  prom #(.mem_file(prom_file)) prom_0 (
    // in
    .clk(~clk),
    .en(prom_stb),
    .addr(cpu_adr[10:2]),
    // out
    .data_out(prom_dout[31:0])
  );

//  // SRAM 512k
//  sram sram_0 (
//    // in
//    .clk(clk_sram),
//    .rst(rst),
//    .en(ram_stb),
//    .be(cpu_ben),
//    .we(cpu_wr),
//    .re(cpu_rd),
//    .addr(cpu_adr[18:0]),
//    .data_in(cpu_outbus[31:0]),
//    // out
//    .data_out(ram_dout[31:0]),
//    .wait_req(cpu_wait),
//    // external
//    .sram_addr(sram_addr[17:0]),
//    .sram_data(sram_data[15:0]),
//    .sram_ce_n(sram_ce_n),
//    .sram_oe_n(sram_oe_n),
//    .sram_we_n(sram_we_n),
//    .sram_ub_n(sram_ub_n),
//    .sram_lb_n(sram_lb_n)
//  );

  // RAM
  ramg5 #(.num_kbytes(416)) ram_0 (
    // in
    .clk(clk),
    .en(ram_stb),
    .wr(cpu_wr),
    .be(cpu_ben),
    .addr(cpu_adr[18:0]),
    .data_in(cpu_outbus[31:0]),
    // out
    .data_out(ram_dout[31:0])
  );

  sram_test sram_test_0 (
    // in
    .clk(clk),
    .clk_sram(clk_sram),
    .rst(rst),
    .stb(sram_stb),
    .we(cpu_wr),
    .be(cpu_ben),
    .addr(cpu_adr[2]),
    .data_in(cpu_outbus[31:0]),
    //out
    .data_out(sram_dout[31:0]),
    .wait_req(cpu_wait),
    .ack(sram_ack),
    // external
    .sram_addr(sram_addr[17:0]),
    .sram_data(sram_data[15:0]),
    .sram_ce_n(sram_ce_n),
    .sram_oe_n(sram_oe_n),
    .sram_we_n(sram_we_n),
    .sram_ub_n(sram_ub_n),
    .sram_lb_n(sram_lb_n)
  );

  // ms timer
  // one IO address
  ms_timer #(.clock_freq(clock_freq)) tmr_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(tmr_stb),
    // out
    .data_out(tmr_dout[31:0]),
    .ms_tick(tmr_ms_tick),
    .ack(tmr_ack)
  );

  // LEDs, switches, buttons, 7-seg displays
  // one IO address
  assign lsb_leds_r_in[9] = cpu_wait;
  assign lsb_leds_r_in[8:0] = 9'b0;
  lsb_s lsb_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(lsb_stb),
    .we(cpu_wr),
    .leds_r_in(lsb_leds_r_in[9:0]),
    .data_in(cpu_outbus[31:0]),
    // out
    .data_out(lsb_dout[31:0]),
    .ack(lsb_ack),
    .btn_out(lsb_btn[3:0]),
    .swi_out(lsb_swi[9:0]),
    // external in
    .btn_in_n(btn_in_n[3:0]),
    .swi_in(swi_in[9:0]),
    // external out
    .leds_g(led_g[7:0]),
    .leds_r(led_r[9:0]),
    .hex1_n(hex1_n[6:0]),
    .hex0_n(hex0_n[6:0])
  );

  // RS232 buffered
  // two consecutive IO addresses
  rs232 #(.clock_freq(clock_freq), .buf_slots(rs232_buf_slots)) rs232_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(rs232_0_stb),
    .we(cpu_wr),
    .addr(cpu_adr[2]),
    .data_in(cpu_outbus[7:0]),
    // out
    .data_out(rs232_0_dout[31:0]),
    .ack(rs232_0_ack),
    // external
    .rxd(rs232_0_rxd),
    .txd(rs232_0_txd)
  );

  // SPI
  // two consecutive IO addresses
  spie #(.slow_div(64), .default_mode(2'b11)) spie_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(spi_0_stb),
    .we(cpu_wr),
    .addr(cpu_adr[2]),
    .data_in(cpu_outbus[31:0]),
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

  assign spi_cs_n[1] = spi_0_cs_n_d[1];
  assign spi_sclk[1] = spi_0_sclk_d;
  assign spi_mosi[1] = spi_0_mosi_d;

  assign spi_cs_n[2] = spi_0_cs_n_d[2];
  assign spi_sclk[2] = spi_0_sclk_d;
  assign spi_mosi[2] = spi_0_mosi_d;

  assign spi_0_miso_d = sdcard_miso & spi_miso[1] & spi_miso[2];

  // sys control and status
  // two consecutive IO addresses
  // order must correspond with values in SysCtrl.mod for correct logging
  assign scs_err_sig_in[7:0] = {3'b0, stm_trig_hot, stm_trig_lim, wd_trig, 1'b0, lsb_btn[0]};
  scs scs_0 (
    // in
    .clk(clk),
    .restart(rst_out),
    .stb(scs_stb),
    .we(cpu_wr),
    .addr(cpu_adr[2]),
    .err_sig(scs_err_sig_in),
    .err_addr({cpu_pcx[21:0], 2'b0}),
    .data_in(cpu_outbus[31:0]),
    // out
    .data_out(scs_dout[31:0]),
    .sys_rst(rst),
    .sys_rst_n(rst_n),
    .cp_pid(scs_cp_pid),
    .ack(scs_ack)
  );

  // process periodic timers
  // one IO address
  proctimers ptmr_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(ptmr_stb),
    .we(cpu_wr),
    .tick(tmr_ms_tick),
    .data_in(cpu_outbus[31:0]),
    // out
    .data_out(ptmr_dout[31:0]),
    .ack(ptmr_ack)
  );

//  // log buffer
//  // two consecutive IO addresses
//  logbuf #(.num_entries(logbuf_entries)) logbuf_0 (
//    // in
//    .clk(clk),
//    .stb(log_stb),
//    .we(cpu_wr),
//    .addr(cpu_adr[2]),
//    .data_in(cpu_outbus[15:0]),
//    // out
//    .data_out(log_dout[31:0]),
//    .ack(log_ack)
//  );

//  // watchdog
//  // one IO address
//  watchdog watchdog_0 (
//    // in
//    .clk(clk),
//    .rst(rst),
//    .tick(tmr_ms_tick),
//    .stb(wd_stb),
//    .we(cpu_wr),
//    .data_in(cpu_outbus[15:0]),
//    // out
//    .data_out(wd_dout[31:0]),
//    .trig(wd_trig),
//    .ack(wd_ack)
//  );

  // stack monitor
  // four consecutive IO addresses
  stackmon stackmon_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(stm_stb),
    .we(cpu_wr),
    .addr(cpu_adr[3:2]),
    .sp_in(cpu_spx[23:0]),
    .data_in(cpu_outbus[23:0]),
    // out
    .data_out(stm_dout[31:0]),
    .trig_lim(stm_trig_lim),
    .trig_hot(stm_trig_hot),
    .ack(stm_ack)
  );

// // call trace stacks
// // two consecutive IO addresses
// calltrace #(.num_slots(calltrace_slots)) calltrace_0 (
//   // in
//   .clk(clk),
//   .stb(cts_stb),
//   .we(cpu_wr),
//   .addr(cpu_adr[2]),
//   .ir_in(cpu_irx),
//   .lnk_in(cpu_lnkx[23:0]),
//   .cp_pid(scs_cp_pid),
//   .data_in(cpu_outbus[23:0]),
//   // out
//   .data_out(cts_dout[31:0]),
//   .ack(cts_ack)
// );

  // (-re) start tables
  // one IO address
  start start_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(start_stb),
    .we(cpu_wr),
    .data_in(cpu_outbus[15:0]),
    // out
    .data_out(start_dout[31:0]),
    .ack(start_ack)
  );

  // GPIO
  // two consecutive IO addresses
  gpio #(.num_gpio(num_gpio)) gpio_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(gpio_stb),
    .we(cpu_wr),
    .addr(cpu_adr[2]),
    .data_in(cpu_outbus[num_gpio-1:0]),
    // out
    .data_out(gpio_dout),
    .ack(gpio_ack),
    // external
    .io_pin(gpio[num_gpio-1:0])
  );

  // I2C
  // four consecutive IO addresses
  i2ce i2ce_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(i2c_stb),
    .we(cpu_wr),
    .addr(cpu_adr[3:2]),
    .data_in(cpu_outbus[31:0]),
    // out
    .data_out(i2c_dout[31:0]),
    .ack(i2c_ack),
    // external
    .scl(i2c_scl),
    .sda(i2c_sda)
  );

  // sys config
  // one IO address
  sysconf #(
    .mem_lim(mem_lim),
    .stack_org(stack_org),
    .stack_size(stack_size)
    ) sysconf_0 (
    // in
    .clk(clk),
    .stb(scfg_stb),
    .we(cpu_wr),
    .data_in(cpu_outbus[31:0]),
    // out
    .data_out(scfg_dout[31:0]),
    .ack(scfg_ack)
  );


//  // echo testing
//  echo echo_0 (
//    .clk(clk),
//    .stb(echo_stb),
//    .we(cpu_wr),
//    .addr(cpu_adr[2]),
//    .data_in(cpu_outbus[31:0]),
//    .data_out(echo_dout[31:0]),
//    .ack(echo_ack)
//  );


  // address decoding
  // ----------------
  // cf. memory map below

  // max RAM address space at 000000H to 0FFE000H (16 MB - 8 kB)
  // cpu_adr[23:0] = 0FFE000H => cpu_adr[23:13] = 11'h7FF
  assign ram_stb = (cpu_adr[23:13] != 11'h7FF);

  // cpu_codebus multiplexer: RAM or PROM
  // PROM: 2 kB at  0FFE000H => initial code address for CPU
  // PROM uses cpu_adr[10:2] (word address)
  // PROM could be extended to 4kB "below" the IO addresses
  assign prom_stb = (cpu_adr[23:12] == 12'hFFE && cpu_adr[11] == 1'b0);
  assign cpu_codebus[31:0] = ~prom_stb ? ram_dout[31:0] : prom_dout[31:0];

  // cpu_inbus multiplexer: RAM or IO
  // IO block: 256 bytes (64 words) at 0FFFF00H
  // there's space reserved for three more 256 bytes IO blocks
  // at: 0FFFE00H, 0FFFD00, 0FFFC00
  assign io_en = (cpu_adr[23:8] == 16'hFFFF);
  assign cpu_inbus[31:0] = ~io_en ? ram_dout[31:0] : io_out[31:0];

  // the traditional 16 IO addresses of (Embedded) Project Oberon
  assign i2c_stb     = (io_en && cpu_adr[7:4] == 4'b1111);    // -16, -12, -8, -4
  assign gpio_stb    = (io_en && cpu_adr[7:3] == 5'b11100);   // -32 (data), -28 (ctrl/status)
  assign spi_0_stb   = (io_en && cpu_adr[7:3] == 5'b11010);   // -48 (data), -44 (ctrl/status)
  assign rs232_0_stb = (io_en && cpu_adr[7:3] == 5'b11001);   // -56 (data), -52 (ctrl/status)
  assign lsb_stb     = (io_en && cpu_adr[7:2] == 6'b110001);  // -60 note: system LEDs via LED()
  assign tmr_stb     = (io_en && cpu_adr[7:2] == 6'b110000);  // -64

  // extended IO address range
  assign scs_stb     = (io_en && cpu_adr[7:3] == 5'b10111);   // -72
//  assign cts_stb     = (io_en && cpu_adr[7:3] == 5'b10110);  // -80, -76 (ctrl/status)
  assign stm_stb     = (io_en && cpu_adr[7:4] == 4'b1010);    // -96
  assign sram_stb    = (io_en && cpu_adr[7:3] == 5'b10011);  // -104
  assign scfg_stb    = (io_en && cpu_adr[7:2] == 6'b100101);  // -108
//  assign wd_stb      = (io_en && cpu_adr[7:2] == 6'b100100);  // -112
  assign ptmr_stb    = (io_en && cpu_adr[7:2] == 6'b011111);  // -132
  assign start_stb   = (io_en && cpu_adr[7:2] == 6'b010001);  // -188
//  assign log_stb     = (io_en && cpu_adr[7:3] == 5'b00100);   // -224 (data), -220 (indices)
//  assign echo_stb    = (io_en && cpu_adr[7:3] == 5'b00000);  // -256


  // IO data out multiplexing
  // ------------------------
  assign io_out[31:0] =
    i2c_stb     ? i2c_dout[31:0] :
    gpio_stb    ? gpio_dout[31:0] :
    spi_0_stb   ? spi_0_dout[31:0] :
    rs232_0_stb ? rs232_0_dout[31:0] :
    lsb_stb     ? lsb_dout[31:0] :
    tmr_stb     ? tmr_dout[31:0] :
    scs_stb     ? scs_dout[31:0] :
//    cts_stb     ? cts_dout[31:0]  :
    stm_stb     ? stm_dout[31:0]  :
    sram_stb    ? sram_dout[31:0] :
    scfg_stb    ? scfg_dout[31:0] :
//    wd_stb      ? wd_dout[31:0] :
    ptmr_stb    ? ptmr_dout[31:0] :
    start_stb   ? start_dout[31:0] :
//    log_stb     ? log_dout[31:0] :
//    echo_stb    ? echo_dout[31:0] :
    32'h0;

endmodule

`resetall

/**
FFFFFC  +---------------------------+
        | 64 dev addr (1 word each) |     256 Bytes
FFFF00  +---------------------------+
        | 64 dev addr (unused)      |     256 Bytes
FFFE00  +---------------------------+
        | 64 dev addr (unused)      |     256 Bytes
FFFD00  +---------------------------+
        | 64 dev addr (unused)      |     256 Bytes
FFFC00  +---------------------------+
        |                           |
        |      -- unused --         |     3 kB
        |                           !
FFF000  +---------------------------+
        |                           !
        |     PROM (2k used)        |     4 KB
        |                           |
FFE000  +---------------------------+
        |                           |
        |                           |
        |                           |
        |                           |
        |                           |
        |          max              |
        |          RAM              |     16 MB - 8 kB
        |         space             |
        |                           |
        |                           |
        |                           |
        |                           |
        |                           |
000000  +---------------------------+
**/
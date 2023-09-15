/**
  RISC5 CPU and environment definition for Oberon RTS p3-thm-de2-115
  --
  Architecture: THM
  Board and technology: DE2-115, Altera Cyclone IV E
  --
  Base/origins:
    * THM-oberon
    * Project Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module risc5 #(
  parameter
    clock_freq = 50_000_000,
    prom_file = "../../platform/bootload/BootLoad.mem",
    mem_lim = 'h80000,        // RAM size
    stack_org = 'h70000,      // initial stack pointer value
    stack_size = 'h8000,
    rs232_buf_slots = 256,
    logbuf_entries = 32,
    calltrace_slots = 32,
    num_gpio = 4
  )(
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
  input [17:0] swi_in,
  // GPIO
  inout [num_gpio-1:0] gpio
);

  // clk
  wire clk_ok;                // clocks stable
  wire clk;                   // system clock, 50 MHz
  wire mem_clk;               // memory clock, 100 MHz
  // reset
  wire rst_out;               // active high
  // cpu
  wire bus_stb;
  wire bus_we;                // bus write enable
  wire [23:2] bus_addr;       // bus address (word address)
  wire [31:0] bus_din;        // bus data input, for reads
  wire [31:0] bus_dout;       // bus data output, for writes
  // cpu extensions
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
  wire [31:0] tmr_dout;       // running milliseconds since reset
  wire tmr_ms_tick;           // millisecond timer tick
  wire tmr_ack;
  // lsb
  wire lsb_stb;
  wire [17:0] lsb_leds_r_in;  // direct signals in for red LEDs
  wire [31:0] lsb_dout;       // buttons, switches io data
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
  // stack monitor
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
  // sys config
  wire scfg_stb;
  wire [31:0] scfg_dout;
  wire scfg_ack;

  // clocks
  clocks clocks_0 (
    // in
    .clk_in(clk_in),
    //out
    .clk_ok(clk_ok),
    .clk(clk),               // 50 MHz
    .clk_2x(mem_clk),        // 100 MHz
    // external out
    .clk_2x_ps(sdram_clk)    // 100 MHz, phase-shifted
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
  cpu_x #(.start_addr(24'hFFE000)) cpu_0 (  // PROM address
    // in
    .clk(clk),
    .rst(rst),
    .bus_din(bus_din[31:0]),
    .bus_ack(bus_ack),
    // out
    .bus_stb(bus_stb),
    .bus_we(bus_we),
    .bus_addr(bus_addr[23:2]),
    .bus_dout(bus_dout[31:0]),
    // extenstions out
    .spx(cpu_spx[31:0]),
    .pcx(cpu_pcx[23:0]),
    .irx(cpu_irx[31:0]),
    .lnkx(cpu_lnkx[31:0])
  );

  // boot ROM
  prom #(.mem_file(prom_file)) prom_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(prom_stb),
    .we(bus_we),
    .addr(bus_addr[10:2]),
    // out
    .data_out(prom_dout[31:0]),
    .ack(prom_ack)
  );

  // SDRAM
  assign ram_addr[26:2] = {3'b000, bus_addr[23:2]};
  ram ram_0 (
    // in
    .clk_ok(clk_ok),
    .clk2(mem_clk),
    .clk(clk),
    .rst(rst),
    .stb(ram_stb),
    .we(bus_we),
    .addr(ram_addr[26:2]),
    .data_in(bus_dout[31:0]),
    // out
    .data_out(ram_dout[31:0]),
    .ack(ram_ack),
    // external
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

  // milliseconds timer
  // one IO address
  // read-only
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
  assign lsb_leds_r_in[17:0] = 18'b0; // only 'clk'-sync-ed signals
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

  // RS232 buffered
  // two consecutive IO addresses
  rs232 #(.clock_freq(clock_freq), .buf_slots(rs232_buf_slots)) rs232_0 (
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
  // two consecutive IO addresses
  spie spie_0 (
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

  // sys control and status
  // two consecutive IO addresses
  // order must correspond with values in SysCtrl.mod for correct logging
  // only 'clk'-sync-ed signals
  assign scs_err_sig_in[7:0] = {3'b0, stm_trig_hot, stm_trig_lim, wd_trig, 1'b0, lsb_btn[0]};
  scs scs_0 (
    // in
    .clk(clk),
    .restart(rst_out),
    .stb(scs_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .err_sig(scs_err_sig_in),
    .err_addr(cpu_pcx[23:0]),
    .data_in(bus_dout[31:0]),
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
    .we(bus_we),
    .tick(tmr_ms_tick),
    .data_in(bus_dout[31:0]),
    // out
    .data_out(ptmr_dout[31:0]),
    .ack(ptmr_ack)
  );

  // log buffer
  // two consecutive IO addresses
  logbuf #(.num_entries(logbuf_entries)) logbuf_0 (
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
  // one IO address
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
  // four consecutive IO addresses
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
 // two consecutive IO addresses
 calltrace #(.num_slots(calltrace_slots)) calltrace_0 (
   // in
   .clk(clk),
   .stb(cts_stb),
   .we(bus_we),
   .addr(bus_addr[2]),
   .ir_in(cpu_irx),
   .lnk_in(cpu_lnkx[23:0]),
   .cp_pid(scs_cp_pid),
   .data_in(bus_dout[23:0]),
   // out
   .data_out(cts_dout[31:0]),
   .ack(cts_ack)
 );

  // (-re) start tables
  // one IO address
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

  // GPIO
  // two consecutive IO addresses
  gpio #(.num_gpio(num_gpio)) gpio_0 (
    // in
    .clk(clk),
    .rst(rst),
    .stb(gpio_stb),
    .we(bus_we),
    .addr(bus_addr[2]),
    .data_in(bus_dout[num_gpio-1:0]),
    // out
    .data_out(gpio_dout),
    .ack(gpio_ack),
    // external
    .io_pin(gpio[num_gpio-1:0])
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
    .we(bus_we),
    .data_in(bus_dout[31:0]),
    // out
    .data_out(scfg_dout[31:0]),
    .ack(scfg_ack)
  );

  // address decoding
  // ----------------
  // cf. memory map below

  // RAM: (16 MB - 8 kB) at 000000H to 0FFE000H
  // adr[23:0] = 0FFE000H => adr[23:13] = 11'h7FF
  assign ram_stb = (bus_stb && bus_addr[23:13] != 11'h7FF);

  // PROM: 2 kB at 0FFE000H => initial code address for CPU
  // PROM uses adr[10:2] (word address)
  // PROM could be extended to 4kB "below" the IO addresses
  assign prom_stb = (bus_stb && bus_addr[23:12] == 12'hFFE && bus_addr[11] == 1'b0);

  // I/O: 256 bytes (64 words) at 0FFFF00H
  // there's space for three more 256 bytes IO blocks "above" the PROM region
  // at: 0FFFE00H, 0FFFD00, 0FFFC00
  assign io_stb = (bus_stb && bus_addr[23:8] == 16'hFFFF);

  // the traditional 16 IO addresses of (Embedded) Project Oberon
  assign gpio_stb    = (io_stb && bus_addr[7:3] == 5'b11100);   // -32 (data), -28 (ctrl/status)
  assign spi_0_stb   = (io_stb && bus_addr[7:3] == 5'b11010);   // -48 (data), -44 (ctrl/status)
  assign rs232_0_stb = (io_stb && bus_addr[7:3] == 5'b11001);   // -56 (data), -52 (ctrl/status)
  assign lsb_stb     = (io_stb && bus_addr[7:2] == 6'b110001);  // -60 note: system LEDs via LED()
  assign tmr_stb     = (io_stb && bus_addr[7:2] == 6'b110000);  // -64

  // extended IO address range
  assign scs_stb     = (io_stb && bus_addr[7:3] == 5'b10111);   // -72
  assign cts_stb     = (io_stb && bus_addr[7:3] == 5'b10110);   // -80 (data), -76 (ctrl/status)
  assign stm_stb     = (io_stb && bus_addr[7:4] == 4'b1010);    // -96
  assign scfg_stb    = (io_stb && bus_addr[7:2] == 6'b100101);  // -108
  assign wd_stb      = (io_stb && bus_addr[7:2] == 6'b100100);  // -112
  assign ptmr_stb    = (io_stb && bus_addr[7:2] == 6'b011111);  // -132
  assign start_stb   = (io_stb && bus_addr[7:2] == 6'b010001);  // -188
  assign log_stb     = (io_stb && bus_addr[7:3] == 5'b00100);   // -224 (data), -220 (indices)


  // data out multiplexing
  // ---------------------
  assign bus_din[31:0] =
    prom_stb    ? prom_dout[31:0] :
    ram_stb     ? ram_dout[31:0]  :
    gpio_stb    ? gpio_dout[31:0] :
    spi_0_stb   ? spi_0_dout[31:0]  :
    rs232_0_stb ? rs232_0_dout[31:0]  :
    lsb_stb     ? lsb_dout[31:0]  :
    tmr_stb     ? tmr_dout[31:0]  :
    scs_stb     ? scs_dout[31:0] :
    cts_stb     ? cts_dout[31:0]  :
    stm_stb     ? stm_dout[31:0]  :
    scfg_stb    ? scfg_dout[31:0] :
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
    gpio_stb    ? gpio_ack :
    spi_0_stb   ? spi_0_ack  :
    rs232_0_stb ? rs232_0_ack  :
    lsb_stb     ? lsb_ack  :
    tmr_stb     ? tmr_ack  :
    scs_stb     ? scs_ack :
    cts_stb     ? cts_ack :
    stm_stb     ? stm_ack :
    scfg_stb    ? scfg_ack :
    wd_stb      ? wd_ack :
    ptmr_stb    ? ptmr_ack  :
    start_stb   ? start_ack :
    log_stb     ? log_ack :
    1'b0;

endmodule

`resetall

/**
FFFFFF  +---------------------------+
        |    64 dev IO addresses    |  256 Bytes
FFFF00  +---------------------------+
        | 64 dev addr (reserved)    |  256 Bytes
FFFE00  +---------------------------+
        | 64 dev addr (reserved)    |  256 Bytes
FFFD00  +---------------------------+
        | 64 dev addr (reserved)    |  256 Bytes
FFFC00  +---------------------------+
        |         unused            |  3 kB
FFF000  +---------------------------+
        |      PROM (reserved)      |  2 kB
FFE800  +---------------------------+
        |          PROM             |  2 kB
FFE000  +---------------------------+
        |                           |
       ...                         ...
        |                           |
        |          max              |
        |          RAM              |  16 MB - 8 kB
        |         space             |
        |                           |
       ...                         ...
        |                           |
000000  +---------------------------+
**/
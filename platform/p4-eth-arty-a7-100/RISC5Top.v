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
  Changes/extensions:
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
  Stripping down for building the equivalant for THM
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
  * remove interrupt ctrl (also romswitch)
  * remove dev sig selector
  * remove log buffers
  --
  Adding some new modules, replacing direct top level functionality
  * add sys ctrl reg
  * add reset device
  * add milliseconds timer device
**/

`timescale 1ns / 1ps
`default_nettype none

`define CLOCK_FREQ 40_000_000
`define NUM_PROC_CTRL 16
`define MEM_BLK_SIZE 'h10000    // 64k
`define PROM_FILE "../../../platform/p4-eth-arty-a7-100/promfiles/BootLoad-512k-64k.mem"

module RISC5Top (
  input wire clk_in,
  input  wire rs232_0_rxd,
  output wire rs232_0_txd,
  input wire [1:0] spi_0_miso,
  output wire [1:0] spi_0_sclk,
  output wire [1:0] spi_0_mosi,
  output wire [1:0] spi_0_cs_n,
  input wire [3:0] btn_in,
  input wire [3:0] swi_in,
  output wire [7:0] sys_leds
 );

  // clk
  wire clk;                 // system clock
  wire clk2x;               // memory clock
  wire clk_ok;              // clocks stable
  // reset
  wire rst_n;               // active low
  // cpu
  wire [23:0] adr;          // address bus
  wire [31:0] inbus;        // data to RISC core
  wire [31:0] inbus0;       // data & code from RAM
  wire [31:0] romout;       // code to RISC core from PROM
  wire [31:0] codebus;      // code to RISC core from RAM
  wire [31:0] outbus;       // data from RISC core
  wire [31:0] iomap;        // io device address mapping/de-muxing
  wire [7:0] iowadr;        // IO word address (1024 IO addresses)
  wire rd;                  // CPU read
  wire wr;                  // CPU write
  wire ben;                 // CPU byte enable
  wire ioenb;               // IO enable
  wire irq_req;             // interrupt request to CPU
  // cpu extensions
  wire cpu_intack;          // CPU out: interrupt ack
  wire cpu_rti;             // CPU out: return from interrupt
  wire cpu_intabort;        // CPU in: abort interrupt, "return" to addr 0, not interrupted code
  wire [31:0] cpu_sp;       // CPU out: stack pointer
  wire [31:0] cpu_lnk;      // CPU out: link register
  wire [31:0] cpu_ir;       // CPU out: instruction register
  wire [23:0] cpu_spc;      // CPU out: SPC register (saved PC on interrupt * 4)
  wire [21:0] cpu_pc;       // CPU out: current PC
  // lsb
  wire lsb_wr;
  wire [31:0] lsb_dout;
  wire [3:0] lsb_btn;
  wire [3:0] lsb_swi;
  // start tables
  wire start_wr;
  wire [31:0] start_dout;
  // sys ctrl reg
  wire scr_wr;
  wire [31:0] scr_dout;
  wire scr_sysrst;
  // proc periodic timing
  wire ptmr_wr;
  wire [31:0] ptmr_dout;
  // // proc delay
  // wire pdel_wr;
  // wire [31:0] pdel_dout;
  // rs232
  wire rs232_0_rdd;           // read data (receive)
  wire rs232_0_wrd;           // write data (send)
  wire rs232_0_wrc;           // write control
  wire [31:0] rs232_0_dout;   // rx data
  wire [31:0] rs232_0_status; // status
  // ms timer
  wire [31:0] tmr_dout;
  wire tmr_ms_tick;
  // spi
  wire spi_0_wrd;
  wire spi_0_wrc;
  wire [31:0] spi_0_dout;
  wire [31:0] spi_0_status;

  // clocks
  clocks clocks_0 (
    .clk_in(clk_in),
    .rst(1'b0),
    .outclk_0(clk),
    .outclk_1(clk2x),
    .locked(clk_ok)
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
    .spx(cpu_sp),
    .spcx(cpu_spc),
    .lnkx(cpu_lnk),
    .irx(cpu_ir),
    .pcx(cpu_pc)
  );

  // RAM 512k (8 blocks of 64k)
  ramg #(.mem_blocks(8)) ram_0 (
    .clk(clk2x),
    .wr(wr),
    .be(ben),
    .adr(adr[18:0]),
    .wdata(outbus),
    .rdata(inbus0)
  );

  // Boot ROM
  prom #(.memfile(`PROM_FILE)) prom_0 (
    .adr(adr[10:2]),
    .data(romout),
    .clk(~clk)
  );

  // reset
  rst rst_0 (
    .clk(clk),
    .clk_ok(clk_ok),
    .rst_in(lsb_btn[0] | scr_sysrst),
    .rst_n(rst_n)
  );

  // ms timer
  tmr #(.clock_freq(`CLOCK_FREQ)) tmr_0 (
    .clk(clk),
    .rst_n(rst_n),
    .data_out(tmr_dout),
    .ms_tick(tmr_ms_tick)
  );

  // LEDs, switches, buttons
  lsb lsb_0 (
    .clk(clk),
    .rst_n(rst_n),
    .wr(lsb_wr),
    .btn_in(btn_in),
    .swi_in(swi_in),
    .data_in(outbus[7:0]),
    .data_out(lsb_dout),
    .leds(sys_leds),
    .btn(lsb_btn),
    .swi(lsb_swi)
  );

  // start tables
  wire [8:0] start_dout0;
  start start_0 (
    .rst_n(rst_n),
    .clk(clk),
    .wr(start_wr),
    .data_in(outbus[15:0]),
    .data_out(start_dout0)
  );
  assign start_dout[31:0] = {23'b0, start_dout0};

  // sys ctrl reg
  // only implements system reset
  wire [15:0] scr_dout0;
  sysctrl sysctrl_0 (
    .clk(clk),
    .rst_n(rst_n),
    .wr(scr_wr),
    .data_in(outbus[15:0]),
    .data_out(scr_dout0),
    .sysrst(scr_sysrst)
  );
  assign scr_dout[31:0] = {16'b0, scr_dout0};

  // process timing
  wire [15:0] ptmr_dout0;
  proctimers #(.num_proc_tmr(16)) ptmr_0 (
    .clk(clk),
    .rst_n(rst_n),
    .tick(tmr_ms_tick),
    .wr(ptmr_wr),
    .data_in(outbus[31:0]),
    .procRdy(ptmr_dout0)
  );
  assign ptmr_dout[31:0] = {16'b0, ptmr_dout0};

  // process delay
  // wire [15:0] pdel_dout0;
  // PROCDELBLK1 #(.num_proc_del(16)) pdel_0 (
  //   .clk(clk),
  //   .rst_n(rst_n),
  //   .tick(mstick),
  //   .wr(pdel_wr),
  //   .data_in(outbus[31:0]),
  //   .procRdy(pdel_dout0)
  // );
  // assign pdel_dout = {16'b0, pdel_dout0};

  // RS232 buffered
  // max 2048 slots
  // put into one module
  wire rs232_0_rx_empty;
  wire rs232_0_rx_full;
  wire rs232_0_tx_empty;
  wire rs232_0_tx_full;

  reg [0:0] rs232_0_ctrl = 0;
  wire rs232_0_fsel = rs232_0_ctrl[0]; // 0 = fast = default;

  always @(posedge clk) begin
    rs232_0_ctrl <= ~rst_n ? 1'b0 : rs232_0_wrc ? outbus[0:0] : rs232_0_ctrl;
  end

  localparam rs232_0_tx_slots = 128;
  // wire [$clog2(rs232_0_tx_slots):0] rs232_0_tx_count;
  rs232_txb #(.clock_freq(`CLOCK_FREQ), .num_slots(rs232_0_tx_slots)) rs232_0_tx (
    .clk(clk),
    .rst_n(rst_n),
    .fsel(rs232_0_fsel),
    .wr(rs232_0_wrd),
    .data_in(outbus[7:0]),
    .empty(rs232_0_tx_empty),
    .full(rs232_0_tx_full),
    // .count(rs232_0_tx_count),
    .txd(rs232_0_txd)
  );

  wire [7:0] rs232_0_dout0;

  localparam rs232_0_rx_slots = 256;
  // wire [$clog2(rs232_0_rx_slots):0] rs232_0_rx_count;
  rs232_rxb #(.clock_freq(`CLOCK_FREQ), .num_slots(rs232_0_rx_slots)) rs232_0_rx (
    .clk(clk),
    .rst_n(rst_n),
    .fsel(rs232_0_fsel),
    .rd(rs232_0_rdd),
    .data_out(rs232_0_dout0),
    .empty(rs232_0_rx_empty),
    .full(rs232_0_rx_full),
    // .count(rs232_0_rx_count),
    .rxd(rs232_0_rxd)
  );

  assign rs232_0_dout[31:0] = {24'b0, rs232_0_dout0};
  assign rs232_0_status[31:0] =
    {28'b0, ~rs232_0_tx_full, rs232_0_rx_full, rs232_0_tx_empty, ~rs232_0_rx_empty};
  // end RS232 module

  // SPI
  // Put into proper module

  // control register
  reg [8:0] spi_0_ctrl = 0;
  // [2:0] chip select
  // [3:3] fast transmit (default: slow)
  // [5:4] data width (default: 8 bits)
  // [6:6] ms byte first (default: ls byte first)

  // data width:
  // 2'b00 => 8 bits
  // 2'b01 => 32 bits
  // 2'b10 => 16 bits

  always @(posedge clk) begin
    spi_0_ctrl <= ~rst_n ? 8'b0 : spi_0_wrc ? outbus[8:0] : spi_0_ctrl;
  end

  assign spi_0_cs_n[1:0] = ~spi_0_ctrl[1:0];
  wire spi_0_fast = spi_0_ctrl[3];
  wire [1:0] spi_0_width = spi_0_ctrl[5:4];
  wire spi_0_msb_first = spi_0_ctrl[6];

  spie #(.clock_freq(`CLOCK_FREQ)) spi_0 (
    .clk(clk),
    .rst_n(rst_n),
    .start(spi_0_wrd),
    .fast(spi_0_fast),
    .datasize(spi_0_width),
    .msbytefirst(spi_0_msb_first),
    .dataTx(outbus[31:0]),
    .dataRx(spi_0_dout),
    .rdy(spi_0_rdy),
    .SCLK(spi_0_sclk[0]),
    .MOSI(spi_0_mosi[0]),
    .MISO(spi_0_miso[0] & spi_0_miso[1])
  );

  assign spi_0_mosi[1] = spi_0_mosi[0];
  assign spi_0_sclk[1] = spi_0_sclk[0];

  wire spi_0_rdy;
  assign spi_0_status[31:0] = {31'b0, spi_0_rdy};

// end SPI module


  // ============================================
  // codebus multiplexer:
  // 'cpu_intack': use address from interrupt controller, ie. set codebus to 'intc1_intout' from interrupt controller
  // 'romswitch': for startup, use high address "above" RAM
  // else 'inbus0'

  wire romswitch = (adr[20] == 1'b1);
  assign codebus = romswitch ? romout : inbus0;

  // Upon reset, start address 'StartAdr' (defined in RISC5.v) is assigned to register PC.
  // PC is [21:0], corresponding to [23:2] on the address bus, ie. 4-bytes aligned.
  // Hence StartAdr is also [21:0], corresponding to [23:2] on the actual bus.
  // Currently, StartAdr = 22'b100_0000_0000_0000_0000 (4000H), 2^18)
  // Consequently, adr[20] == 1'b1 means the ROM is allocated at address 100000H (4000H * 4)

  // ============================================
  // 1024 IO addresses
  assign iowadr = adr[9:2];   // 10 bits = 1024 addresses, ie. 256 4-byte addresses via [9:2]
  assign ioenb = (adr[23:10] == 14'b11_1111_1111_1111);      // 1024 bytes IO space, adr[23:0] = 0FFFC00H

  assign inbus = ~ioenb ? inbus0 : iomap;
  assign iomap =
    (iowadr == 206) ? `CLOCK_FREQ :       // -200
    (iowadr == 209) ? start_dout :        // -188
    (iowadr == 223) ? ptmr_dout :         // -132
    (iowadr == 239) ? scr_dout :          // -68
    (iowadr == 240) ? tmr_dout :          // -64
    (iowadr == 241) ? lsb_dout :          // -60
    (iowadr == 242) ? rs232_0_dout :      // -56
    (iowadr == 243) ? rs232_0_status :    // -52
    (iowadr == 244) ? spi_0_dout :        // -48
    (iowadr == 245) ? spi_0_status :      // -44
    0;

  assign start_wr = wr & ioenb & (iowadr == 209);
  assign ptmr_wr = wr & ioenb & (iowadr == 223);
  assign scr_wr = wr & ioenb & (iowadr == 239);
  assign lsb_wr = wr & ioenb & (iowadr == 241);
  assign rs232_0_wrd = wr & ioenb & (iowadr == 242);
  assign rs232_0_rdd = rd & ioenb & (iowadr == 242);
  assign rs232_0_wrc = wr & ioenb & (iowadr == 243);
  assign spi_0_wrd = wr & ioenb & (iowadr == 244);
  assign spi_0_wrc = wr & ioenb & (iowadr == 245);

// assign pdel_wr = wr & ioenb & (iowadr == 222);

endmodule

`resetall

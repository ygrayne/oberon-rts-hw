/**
  RISC5 processor definition for Oberon RTS p4-eth-arty-a7-100
  --
  Architecture: ETH
  Board and technology: Arty-A7-100 (Xilinx Artix-7)
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
  * simplify sys ctrl reg
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
  CLOCKS1 clocks_0 (
    .clk_in(clk_in),
    .rst(1'b0),
    .outclk_0(clk),
    .outclk_1(clk2x),
    .locked(clk_ok)
  );

  // CPU
  RISC5 risc5_0 (
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
  RAMG #(.mem_blocks(8)) ram_0 (
    .clk(clk2x),
    .wr(wr),
    .be(ben),
    .adr(adr[18:0]),
    .wdata(outbus),
    .rdata(inbus0)
  );

  // Boot ROM
  PROM #(.memfile(`PROM_FILE)) prom_0 (
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
  START2 start_0 (
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
  SYSCTRL sysctrl_0 (
    .clk(clk),
    .rst_n(rst_n),
    .wr(scr_wr),
    .data_in(outbus[15:0]),
    .data_out(scr_dout0),
    .sysrst(scr_sysrst)
  );
  assign scr_dout[31:0] = {16'b0, scr_dout0};

//  // reset
//  // FIX THIS
//  wire rst_btn = lsb_btn[0];              // manual reset button, debounced and synched to clock
//  reg rst_btn0 = 0;
//  always @(posedge clk) begin
//    rst_btn0 <= rst_btn;
//  end
//  wire user_rst = ~rst_btn & rst_btn0;    // reset signal, active on button release

//  wire rst_src = user_rst | scr_sysrst; // reset sources

//  reg [4:0] rst_cnt = 0;
//  wire rst_done = (rst_cnt == 15);       // number of milliseconds reset is held low
//  always @(posedge clk) begin
//    rst_n <= rst_done ? 1'b1 : rst_n ? ~rst_src : rst_n;   // reset timing
//    rst_cnt <= rst_n ? 5'b0 : tmr_ms_tick ? rst_cnt + 1'b1 : rst_cnt;
//  end
//  // // end FIX THIS

  // process timing
  wire [15:0] ptmr_dout0;
  PROCTIMBLK5 #(.NumPrCtrl(16)) ptmr_0 (
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
  // PROCDELBLK1 #(.NumPrCtrl(`NUM_PROC_CTRL)) pdel_0 (
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
  wire [$clog2(rs232_0_tx_slots):0] rs232_0_tx_count;
  RS232TB #(.ClockFreq(`CLOCK_FREQ), .BufNumSlots(rs232_0_tx_slots)) rs232_0_tx (
    .clk(clk),
    .rst_n(rst_n),
    .fsel(rs232_0_fsel),
    .wr(rs232_0_wrd),
    .data_in(outbus[7:0]),
    .empty(rs232_0_tx_empty),
    .full(rs232_0_tx_full),
    .count(rs232_0_tx_count),
    .txd(rs232_0_txd)
  );

  wire [7:0] rs232_0_dout0;

  localparam rs232_0_rx_slots = 256;
  wire [$clog2(rs232_0_rx_slots):0] rs232_0_rx_count;
  RS232RB #(.ClockFreq(`CLOCK_FREQ), .BufNumSlots(rs232_0_rx_slots)) rs232_0_rx (
    .clk(clk),
    .rst_n(rst_n),
    .fsel(rs232_0_fsel),
    .rd(rs232_0_rdd),
    .data_out(rs232_0_dout0),
    .empty(rs232_0_rx_empty),
    .full(rs232_0_rx_full),
    .count(rs232_0_rx_count),
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

  SPIE #(.ClockFreq(`CLOCK_FREQ)) spi_0 (
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

  // ============================================
  // external output ports for testing
//  assign extp[0] = clk;
//  assign extp[1] = pushtx;
//  assign extp[2] = pushx;
//  assign extp[3] = poptx;
//  assign extp[4] = popx;
//  assign extp[5] = btst1_wr;
//  assign extp[6] = btst1_rd;
//  assign extp[7] = 0;

//    (iowadr == 240) ? cnt1 :                               // -64 milliseconds timer, read value
//    (iowadr == 241) ? {24'b0, sysLeds_state} :             // -60 eight system lEDs, set and read status
//    (iowadr == 242) ? {24'b0, rs2321_dataRx} :             // -56 1st RS232, read Rx data, write Tx data
//    (iowadr == 243) ? rs2321_status :                      // -52 1st RS232, read status, write control
//    (iowadr == 244) ? spi1_dataRx :                        // -48 1st SPI, read Rx data, write Tx data
//    (iowadr == 245) ? spi1_status :                        // -44 1st SPI, read status, write control data
//    // 246                                                  // -40 interrupt controller, write data
//    (iowadr == 247) ? {28'b0, intc_intEn} :                // -36 interrupt controller, read enabled status, write control
//    (iowadr == 248) ? gp_in :                              // -32 GPIO, read input pin values, write output values
//    (iowadr == 249) ? gp_oc :                              // -28 GPIO, write control data
//  0;


//  // ============================================
//  // Stack overflow monitor
//  wire sm1_wrLim = wr & ioenb & (iowadr == 204);
//  wire sm1_wrHot = wr & ioenb & (iowadr == 203);
//  wire sm1_wrMax = wr & ioenb & (iowadr == 205);
//  wire sm1_wrNum = wr & ioenb & (iowadr == 191);
//  wire sm1_trigLim, sm1_trigHot;
//  wire [23:0] sm1_maxVal, sm1_hotVal, sm1_limVal;
//  wire [7:0] sm1_num;

//  STACKMON2 sm1 (
//    .rst(rst_n), .clk(clk), .sp(cpu_sp[23:0]), .wr_lim(sm1_wrLim), .wr_hot(sm1_wrHot), .wr_max(sm1_wrMax), .wr_num(sm1_wrNum),
//    .data(outbus[23:0]), .trigLim(sm1_trigLim), .trigHot(sm1_trigHot),
//    .max(sm1_maxVal), .hot(sm1_hotVal), .lim(sm1_limVal), .num(sm1_num)
//  );

//  // ============================================
//  // Backtrace stacks
//  localparam StackSlotCntBits = $clog2(`NUM_BT_SLOTS) + 1;

//  wire btst1_wr = wr & ioenb & (iowadr == 188);
//  wire btst1_rdpop = rd & ioenb & (iowadr == 187);
//  wire btst1_rd = rd & ioenb & (iowadr == 186);
//  wire [23:0] btst1_popdata, btst1_rddata, btst1_maxdata;
//  wire [StackSlotCntBits+7:0] btst1_stat;
//  wire [31:0] btst1_status = {{(24-StackSlotCntBits){1'b0}}, btst1_stat};

//  wire  pushx, popx, pushtx, poptx, morex, frozenx;

//  // '`NUM_PROC_CTRL+16': extra stacks for coroutines that are not processes
//  BTSTACKBLK3 #(.NumStacks(`NUM_PROC_CTRL + `NUM_EXTRA_BT_STACKS), .NumStackSlots(`NUM_BT_SLOTS)) btst1 (
//    .rst(rst_n), .clk(clk), .wr(btst1_wr), .rd(btst1_rd), .rd_pop(btst1_rdpop),
//    .freeze(cpu_intack), .unfreeze(cpu_rti), // freeze during interrupts
//    .din(outbus), .IR(cpu_ir), .LNK(cpu_lnk[23:0]), .pop_out(btst1_popdata),
//    .read_out(btst1_rddata), .max_out(btst1_maxdata), .status(btst1_stat),
//    .pushx(pushx), .popx(popx), .pushtx(pushtx), .poptx(poptx), .morex(morex), .frozenx(frozenx)
//  );

//  // ============================================
//  // Log buffers
//  localparam NumLogEntryItemsA = 64;

//  wire lb1_wrData = wr & ioenb & (iowadr == 201);
//  wire lb1_rdData = rd & ioenb & (iowadr == 201);
//  wire lb1_wrcPut = wr & ioenb & (iowadr == 200);
//  wire lb1_wrcGet = wr & ioenb & (iowadr == 199);
//  wire [7:0] lb1_dataRd;
//  wire [7:0] lb1_putIndex, lb1_getIndex;

//  LOGBUF3 #(.NumEntries(`NUM_LOG_ENTRIES), .NumEntryItems(NumLogEntryItemsA)) lb1 (
//    .clk(clk), .rdd(lb1_rdData), .wrd(lb1_wrData), .wrc_put(lb1_wrcPut), .wrc_get(lb1_wrcGet),
//    .data_in(outbus[7:0]), .data_out(lb1_dataRd), .put_index(lb1_putIndex), .get_index(lb1_getIndex)
//  );


//  // ============================================
//  // SPI 2nd device, buffered, extended variant
//  // max 2048 buffer slots
//  localparam SPI2_bufNumSlots = 64;
//  localparam SPI2_CntBits = $clog2(SPI2_bufNumSlots) + 1;

//  wire [31:0] spi2_dataRx;
//  wire spi2_txFull, spi2_txEmpty;
//  wire spi2_rxFull, spi2_rxEmpty;
//  wire [SPI2_CntBits-1:0] spi2_txCount, spi2_rxCount, spiMax2;
//  wire spi2_putTx = wr & ioenb & (iowadr == 229);
//  wire spi2_getRx = rd & ioenb & (iowadr == 229);
//  wire spi2_wrCtrl = wr & ioenb & (iowadr == 230);
//  wire [2:0] spi2_CSout;
//  assign spi2_CS = ~spi2_CSout[1:0];

//  wire [31:0] spi2_status = {{(12-SPI2_CntBits){1'b0}}, spi2_txCount, {(12-SPI2_CntBits){1'b0}}, spi2_rxCount, 4'b0, spi2_txEmpty, spi2_rxFull, ~spi2_txFull, ~spi2_rxEmpty};

//  SPIB #(.ClockFreq(`CLOCK_FREQ), .BufNumSlots(SPI2_bufNumSlots)) spi2 (
//    .rst(rst_n), .clk(clk), .ctrlData(outbus[9:0]), .wr(spi2_putTx), .wrc(spi2_wrCtrl), .rd(spi2_getRx), .txData(outbus),
//    .MISO(spi2_MISO), .rxData(spi2_dataRx), .txFull(spi2_txFull), .txEmpty(spi2_txEmpty), .rxFull(spi2_rxFull), .rxEmpty(spi2_rxEmpty),
//    .txCount(spi2_txCount), .rxCount(spi2_rxCount), .MOSI(spi2_MOSI), .SCLK(spi2_SCLK), .CS(spi2_CSout), .CTRL(spi2_CTRL)
//  );

//  // ============================================
//  // SPI 3rd device, nonbuffered, extended variant
//  wire [31:0] spi3_dataRx;
//  wire spi3_rdy;
//  reg [8:0] spi3_ctrl;
//  wire spi3_start = wr & ioenb & (iowadr == 227);
//  wire spi3_wrCtrl = wr & ioenb & (iowadr == 228);
//  assign spi3_CS = ~spi3_ctrl[0];
//  assign spi3_CTRL = spi3_ctrl[8];

//  wire [31:0] spi3_status = {31'b0, spi3_rdy};

//  always @(posedge clk) begin
//    spi3_ctrl <= ~rst_n ? 0 : spi3_wrCtrl ? outbus[8:0] : spi3_ctrl;
//  end

//  SPIE #(.ClockFreq(`CLOCK_FREQ)) spi3 (
//    .clk(clk), .rst(rst_n), .start(spi3_start), .fast(spi3_ctrl[3]), .datasize(spi3_ctrl[5:4]), .msbytefirst(spi3_ctrl[6]),
//    .dataTx(outbus), .dataRx(spi3_dataRx), .rdy(spi3_rdy),
//    .SCLK(spi3_SCLK), .MOSI(spi3_MOSI), .MISO(spi3_MISO)
//  );

  // ============================================
  // I2C device
  //wire [7:0] i2c_control, i2c_data;
  //wire [4:0] i2c_status;
  //wire i2c_wrConset = wr & ioenb & (iowadr == 250);
  //wire i2c_wrData = wr & ioenb & (iowadr == 252);
  //wire i2c_wrConclr = wr & ioenb & (iowadr == 255);
  //reg [15:0] i2c_sclh, i2c_scll;

  //always @ (posedge clk) begin
  //  i2c_sclh <= ~rst ? 0 : (wr & ioenb & (iowadr == 253)) ? outbus[15:0] : i2c_sclh;
  //  i2c_scll <= ~rst ? 0 : (wr & ioenb & (iowadr == 254)) ? outbus[15:0] : i2c_scll;
  //end

  //I2C i2c (
  //  .clk(clk), .rst(rst), .SDA(i2c_SDA), .SCL(i2c_SCL), .sclh(i2c_sclh), .scll(i2c_scll), .control(i2c_control), .status(i2c_status),
  //  .data(i2c_data), .wrdata(outbus[7:0]), .wr_conset(i2c_wrConset), .wr_data(i2c_wrData), .wr_conclr(i2c_wrConclr)
  //);


  // ============================================
//  // Watchdog
//  wire [15:0] wd1_data = outbus[15:0];
//  wire [15:0] wd1_timeout;
//  wire wd1_wrTimeout = wr & ioenb & (iowadr == 231);
//  wire wd1_bite;

//  WATCHDOG2 wd1 (
//    .clk(clk), .rst(rst_n), .tick(mstick), .wr_timeout(wd1_wrTimeout), .data(wd1_data), .timeout(wd1_timeout), .bite(wd1_bite)
//  );

//  // ============================================
//  // GPIO
//  reg [`NUM_GPIO-1:0]  gp_out, gp_oc;   // output values, output control
//  wire [`NUM_GPIO-1:0] gp_in;           // input values
//  wire gp_wrData = wr & ioenb & (iowadr == 215);
//  wire gp_wrCtrl = wr & ioenb & (iowadr == 216);

//  genvar i;
//  generate // tri-state buffer for gpio port
//    for (i = 0; i < `NUM_GPIO; i = i+1) begin: gpioblock
//      IOBUF gpiobuf (.I(gp_out[i]), .O(gp_in[i]), .IO(GPIO[i]), .T(~gp_oc[i]));
//    end
//  endgenerate

//  always @(posedge clk) begin
//    gp_out <= gp_wrData ? outbus[`NUM_GPIO-1:0] : gp_out;
//    gp_oc <= ~rst_n ? 0 : gp_wrCtrl ? outbus[`NUM_GPIO-1:0] : gp_oc;
//  end

//  // ============================================
//  // clock cycle counter (test instrumentation)
//  wire [31:0] cc_cntmax0, cc_cntmax1, cc_cntmax2, cc_cntmax3, cc_cntmax4, cc_cntmax5, cc_cntmax6, cc_cntmax7; // max values
//  wire [31:0] cc_cntmin0, cc_cntmin1, cc_cntmin2, cc_cntmin3, cc_cntmin4, cc_cntmin5, cc_cntmin6, cc_cntmin7; // min values
//  wire [4:0] cc_ctrlData = outbus[4:0];
//  wire cc_wrCtrl = wr & ioenb & (iowadr == 128); // write control data

//  CYCLECNT cc (
//    .clk(clk), .wr(cc_wrCtrl), .ctrl(cc_ctrlData),
//    .cntmax0(cc_cntmax0), .cntmax1(cc_cntmax1), .cntmax2(cc_cntmax2), .cntmax3(cc_cntmax3),
//    .cntmax4(cc_cntmax4), .cntmax5(cc_cntmax5), .cntmax6(cc_cntmax6), .cntmax7(cc_cntmax7),
//    .cntmin0(cc_cntmin0), .cntmin1(cc_cntmin1), .cntmin2(cc_cntmin2), .cntmin3(cc_cntmin3),
//    .cntmin4(cc_cntmin4), .cntmin5(cc_cntmin5), .cntmin6(cc_cntmin6), .cntmin7(cc_cntmin7)
//  );

//  // ============================================
//  // Interrupt controllers
//  localparam NumInt = 8;

//  wire intc1_wrData = wr & ioenb & (iowadr == 213);
//  wire intc1_wrCtrl = wr & ioenb & (iowadr == 214);
//  wire [31:0] intc1_intout;
//  wire [NumInt-1:0] intc1_irq;
//  wire [NumInt-1:0] intc1_intEn;
//  wire [NumInt-1:0] intc1_intNum;

//  INTCTRL3 #(.NumInt(NumInt)) intctrl1 (
//    .rst(rst_n), .clk(clk), .wr(intc1_wrData), .wrc(intc1_wrCtrl), .cpu_rti(cpu_rti),
//    .data(outbus), .vdata(intc1_intout), .irq(intc1_irq), .irqout(irq_req), .intno(intc1_intNum), .enabled(intc1_intEn)
//  );

//  // interrupt triggers
////  assign intc1_irq[0] = wd1_bite;     // watchdog
//  assign intc1_irq[1] = userKill;     // kill/abort push button
////  assign intc1_irq[2] = sm1_trigHot;  // stack monitor hot zone
//  assign intc1_irq[3] = 1'b0;         // used from software
//  assign intc1_irq[4] = 1'b0;
//  assign intc1_irq[5] = 1'b0;
//  assign intc1_irq[6] = 1'b0;
//  assign intc1_irq[7] = 1'b0;


//  // ============================================
//  // process monitor
//  wire pmon1_wr = wr & ioenb & (iowadr == 196);
//  wire [31:0] pmon1_evalMax, pmon1_execMax;
//  wire [27:0] pmon1_proc, pmon1_procMax;
//  wire pmon1_ready;

//  PROCMON2 pmon1 (
//    .clk(clk), .tick(mstick), .wr(pmon1_wr), .di(outbus),
//    .eval_max(pmon1_evalMax), .exec_max(pmon1_execMax), .proc_max(pmon1_procMax),
//    .proc_count(pmon1_proc), .ready(pmon1_ready)
//  );


//  // ============================================
//  // device signal selector
//  localparam NumDevices = 4;
//  wire devsig1_wr = wr & ioenb & (iowadr == 210);
////  wire [(NumDevices*4)-1:0] devsig1_devStats = {4'b0, rs2323_baseStatus, rs2322_baseStatus, rs2321_baseStatus};  // dev stats in
//  wire [(NumDevices*4)-1:0] devsig1_devStats = {4'b0, 4'b0, 4'b0, rs2321_baseStatus};  // dev stats in
//  wire [(NumDevices*2)-1:0] devsig1_devSigs; // dev sigs out
//  wire [(NumDevices*4)-1:0] devsig1_selected;

//  DEVSIG1 #(.NumDevices(NumDevices)) devsig1 (
//    .clk(clk), .rst(rst_n), .wr(devsig1_wr), .data(outbus[7:0]), .devstats(devsig1_devStats),
//    .devsigs(devsig1_devSigs), .selected(devsig1_selected)
//  );

//  // ============================================
//  // process device signals controllers
//  wire pcs1_wrDevSig = wr & ioenb & (iowadr == 220);
//  wire [`NUM_PROC_CTRL-1:0] pcs1_procRdySig;

//  PROCDEVSIGBLK1 #(.NumPrCtrl(`NUM_PROC_CTRL)) pcs1 (
//    .clk(clk), .rst(rst_n), .devsigs(devsig1_devSigs),
//    .wr(pcs1_wrDevSig), .di(outbus[20:0]), .procRdy(pcs1_procRdySig)
//  );
/**
  Serial Peripheral Interface (SPI) Receiver/Transmitter
  --
  Base: Project Oberon, PDR 23.3.12 / 16.10.13
  --
  Architecture: ANY
  --
  New features:
  * Separation of data width and speed selection
  * Data can be 8, 16, or 32 bits wide
  * Data can be sent out (MOSI) as LSByte or MSByte first
  * Clock frequency is parameterised
  --
  Serial clock frequency/speed:
  * fast: 10 MHz with 50 MHz clock
  * slow: 400 kHz with 50 MHz clock
  --
  Data width:
  * [1:0] data_width:
    * 2'b00 => 8 bits
    * 2'b01 => 32 bits
    * 2'b10 => 16 bits
  --
  (c) 2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module spie_rxtx (
  input wire clk,
  input wire rst,
  input wire start,
  input wire fast,              // use fast transfer speed
  input wire msbyte_first,      // send MSByte first, not LSByte (MSbit is always first)
  input wire [1:0] data_width,  // select 8, 16, or 32 bits data transfer
  input wire miso,
  input wire [31:0] data_tx,
  output wire [31:0] data_rx,
  output reg rdy,
  output wire mosi,
  output wire sclk
);

  localparam tick_cnt_fast_period = 2;        // clock cycles => freq = clock_freq / 4
  localparam tick_cnt_slow_period = 50;      // clock cycles => freq = clock_freq / 100
  localparam tick_cnt_fast_low = 1;           // clock cycles => duty cycle = 3/4 (3 high, 1 low)
  localparam tick_cnt_slow_low = 25;          // clock cycles => duty cycle = ~ 3/4

  localparam sclk_idle = 1'b0;

  wire w8  = (data_width == 2'b00);
  wire w16 = (data_width == 2'b10);
  wire w32 = (data_width == 2'b01);

  reg [31:0] shreg;
  reg [6:0] tick;
  reg [4:0] bitcnt;

  wire endtick = fast ? (tick == tick_cnt_fast_period) : (tick == tick_cnt_slow_period);  // clock period
  wire sclk_switch = fast ? (tick >= tick_cnt_fast_low) : (tick >= tick_cnt_slow_low);    // clock duty cycle
  wire endbit = w32 ? (bitcnt == 31) : w16 ? (bitcnt == 15) : (bitcnt == 7);

  assign data_rx = w32 ? shreg : w16 ? {16'b0, shreg[15:0]} : {24'b0, shreg[7:0]};
  assign mosi = (rst | rdy) ? 1'b1 : msbyte_first ? (w32 ? shreg[31] : w16 ? shreg[15] : shreg[7]) : shreg[7];
  assign sclk = (rst | rdy) ? 1'b1 : sclk_switch;
//  assign sclk = (rst | rdy) ? sclk_idle : sclk_idle ? sclk_switch : ~sclk_switch;

  always @ (posedge clk) begin
    tick <= (rst | rdy | endtick) ? 7'b0 : tick + 7'b1;
    rdy <= (rst | endtick & endbit) ? 1'b1 : start ? 1'b0 : rdy;
    bitcnt <= (rst | start) ? 5'b0 : (endtick & ~endbit) ? bitcnt + 5'b1 : bitcnt;

    shreg <= rst ? -1 : start ? data_tx[31:0] : endtick ?
      (msbyte_first ?
        ({shreg[30:0], miso}) :
        ({shreg[30:24], miso, shreg[22:16], shreg[31], shreg[14:8],
         (w16 ? miso : shreg[23]), shreg[6:0], (w8 ? miso : shreg[15])})) : shreg;
  end

endmodule

`resetall

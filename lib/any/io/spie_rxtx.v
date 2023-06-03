/**
  Serial Peripheral Interface (SPI) Receiver/Transmitter (Master)
  --
  Base: Project Oberon, PDR 23.3.12 / 16.10.13
  --
  Architecture: ANY
  --
  Data width:
  * [1:0] data_width:
    * 2'b00 => 8 bits
    * 2'b01 => 32 bits
    * 2'b10 => 16 bits
  --
  SPI modes:
                      idle     transceive
             cpol = 0               ++++++    ++++++
  mode = 0:  cpha = 0          |   bit   |   bit   |  ...    mosi/miso
                       ++++++++++++++    ++++++    ++++++    sclk

             cpol = 1  ++++++++++++++    ++++++    ++++++
  mode = 1:  cpha = 0          |   bit   |   bit   |  ...
                                    ++++++    ++++++

             cpol = 0          ++++++    ++++++    ++++++
  mode = 2:  cpha = 1          |   bit   |   bit   |  ...
                       +++++++++    ++++++    ++++++

             cpol = 1  +++++++++    ++++++    ++++++
  mode = 3:  cpha = 1          |   bit   |   bit   |  ...
                               ++++++    ++++++    ++++++

  --
  Frequency dividers for the serial clock:
  * fast_div: fast transmit
    * must be >= 3
    * aim for about 10 MHz or lower
  * slow_div: slow transmit
    * must result in a frequency between 100 and 400 kHz as per SD card specs
    * however, experience shows that moat SD cards prefer a value between 300 and 400 kHz
  Odd dividers will result in a non 50%/50% duty-cycle of the serial clock,
  with the low half period being longer by one 'clk' period.
  --
  SD card works with modes 0 and 3
  RTC works with modes 2 and 3
  --
  (c) 2022 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module spie_rxtx #(
  parameter
    fast_div = 5,             // cf. above
    slow_div = 125
  )(
  // internal
  input wire clk,
  input wire rst,
  input wire start,             // start transmission (when 'rdy' set)
  input wire fast,              // use fast transfer speed (fast_sclk)
  input wire msbyte_first,      // send MSByte first, not LSByte (MSbit is always first)
  input wire [1:0] data_width,  // select 8, 16, or 32 bits data transfer
  input wire cpol,              // serial clock polarity
  input wire cpha,              // serial clock phase
  input wire [31:0] data_tx,
  output wire [31:0] data_rx,
  output wire rdy,              // ready for transmission (via 'start')
  // external
  input wire miso,
  output wire mosi,
  output wire sclk
);

  localparam ticks_period_fast = fast_div - 1;
  localparam ticks_period_slow = slow_div - 1;
  localparam ticks_half_period_fast = ticks_period_fast / 2;
  localparam ticks_half_period_slow = ticks_period_slow / 2;

  wire w8  = (data_width == 2'b00);
  wire w16 = (data_width == 2'b10);
  wire w32 = (data_width == 2'b01);

  reg [7:0] ticks;        // count clock ticks in one serial clock phase
  reg [4:0] bit_cnt;      // count bits in a transmission
  reg sclk_e;             // serial clock enable
  assign rdy = ~sclk_e;
  reg [31:0] shreg;

  wire last_tick = fast ? (ticks == ticks_period_fast) : (ticks == ticks_period_slow);                // end of one bit
  wire sclk_switch = fast ? (ticks > ticks_half_period_fast) : (ticks > ticks_half_period_slow);      // starts low
  assign sclk = (rst | ~sclk_e) ? cpol :
    (cpol == 1'b0) ?  ((cpha == 1'b0) ? sclk_switch : ~sclk_switch) :
                      ((cpha == 1'b0) ? ~sclk_switch : sclk_switch);

  wire last_bit = w32 ? (bit_cnt == 31) : w16 ? (bit_cnt == 15) : (bit_cnt == 7);

  assign data_rx = w32 ? shreg : w16 ? {16'b0, shreg[15:0]} : {24'b0, shreg[7:0]};
  assign mosi = (rst | ~sclk_e) ? 1'b1 : msbyte_first ? (w32 ? shreg[31] : w16 ? shreg[15] : shreg[7]) : shreg[7];

  // serial clock
  always @(posedge clk) begin
    sclk_e <= rst | (last_bit & last_tick) ? 1'b0 : start ? 1'b1 : sclk_e;
    ticks <= (rst | ~sclk_e | last_tick) ? 8'b0 : ticks + 8'b1;
    bit_cnt <= (rst | start) ? 5'b0 : (last_tick & ~last_bit) ? bit_cnt + 5'b1 : bit_cnt;
  end

  // shifting
  always @(posedge clk) begin
    shreg <= rst ? 32'hffffffff : start ? data_tx[31:0] : last_tick ?
      (msbyte_first ? (
          {shreg[30:0], miso}
        ) : (
          {shreg[30:24], miso, shreg[22:16], shreg[31], shreg[14:8],
          (w16 ? miso : shreg[23]), shreg[6:0], (w8 ? miso : shreg[15])}
        )
      ) : shreg;
  end

endmodule

`resetall
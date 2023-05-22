/**
  Serial Peripheral Interface (SPI) Receiver/Transmitter (Master)
  --
  Base: Project Oberon, PDR 23.3.12 / 16.10.13
  --
  Architecture: ANY
  --
  New features:
  * Separation of data width and speed selection
  * Data can be 8, 16, or 32 bits wide
  * Data can be sent out (MOSI) as LSByte or MSByte first
  * Clock frequencies are parameterised
  --
  Serial clock frequency/speed:
  * fast => fast_sclk: 10 MHz with 50 MHz clock
  * slow => slow_sclk: 400 kHz with 50 MHz clock
  --
  Data width:
  * [1:0] datawidth:
    * 2'b00 => 8 bits
    * 2'b01 => 32 bits
    * 2'b10 => 16 bits
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module spie_rxtx #(parameter clock_freq = 50_000_000,  fast_sclk = 10_000_000, slow_sclk = 400_000) (
  input wire clk,
  input wire rst,
  input wire start,
  input wire fast,             // use fast transfer speed (fast_sclk)
  input wire msbytefirst,      // send MSByte first, not LSByte (MSbit is always first)
  input wire [1:0] datawidth,  // select 8, 16, or 32 bits data transfer
  input wire miso,
  input wire [31:0] data_tx,
  output wire [31:0] data_rx,
  output reg rdy,
  output wire mosi,
  output wire sclk
);

  localparam tickCntFast = (clock_freq / fast_sclk);
  localparam tickCntSlow = (clock_freq / slow_sclk);
  localparam tickCntFast2 = tickCntFast / 2;
  localparam tickCntSlow2 = tickCntSlow / 2;

  wire w8  = (datawidth == 2'b00) ? 1'b1 : 1'b0;
  wire w16 = (datawidth == 2'b10) ? 1'b1 : 1'b0;
  wire w32 = (datawidth == 2'b01) ? 1'b1 : 1'b0;

  reg [31:0] shreg;
  reg [6:0] tick;
  reg [4:0] bitcnt;

  wire endtick = fast ? (tick == tickCntFast) : (tick == tickCntSlow);
  wire sclk_switch = fast ? (tick >= tickCntFast2) : (tick >= tickCntSlow2);
  wire endbit = w32 ? (bitcnt == 31) : w16 ? (bitcnt == 15) : (bitcnt == 7);

  assign data_rx = w32 ? shreg : w16 ? {16'b0, shreg[15:0]} : {24'b0, shreg[7:0]};
  assign mosi = (rst | rdy) ? 1'b1 : msbytefirst ? (w32 ? shreg[31] : w16 ? shreg[15] : shreg[7]) : shreg[7];
  assign sclk = (rst | rdy) ? 1'b1 : sclk_switch;

  always @ (posedge clk) begin
    tick <= (rst | rdy | endtick) ? 7'b0 : tick + 7'b1;
    rdy <= (rst | endtick & endbit) ? 1'b1 : start ? 1'b0 : rdy;
    bitcnt <= (rst | start) ? 5'b0 : (endtick & ~endbit) ? bitcnt + 5'b1 : bitcnt;

    shreg <= rst ? -1 : start ? data_tx[31:0] : endtick ?
      (msbytefirst ?
        ({shreg[30:0], miso}) :
        ({shreg[30:24], miso, shreg[22:16], shreg[31], shreg[14:8],
         (w16 ? miso : shreg[23]), shreg[6:0], (w8 ? miso : shreg[15])})) : shreg;
  end

endmodule

`resetall

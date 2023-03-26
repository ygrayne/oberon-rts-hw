/**
  Serial Peripheral Interface (SPI) Receiver/Transmitter
  --
  Base: Project Oberon, PDR 23.3.12 / 16.10.13
  --
  New features:
  * Separation of data width and speed selection
  * Data can be 8, 16, or 32 bits wide
  * Data can be sent out (MOSI) as LSByte or MSByte first
  * Clock frequencies are parameterised
  --
  Serial clock frequency/speed:
  * fast = fastSCLK
  * slow = slowSCLK
  --
  Data width:
  * [1:0] datawidth: 2'b00 => 8 bits, 2'b01 => 32 bits, 2'b10 => 16 bits
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module spie_rctr #(parameter clock_freq = 50000000, fastSCLK = 10000000, slowSCLK = 400000) (
  input clk,
  inout rst,
  input start,
  input fast,             // use fast transfer speed (fastSCLK)
  input msbytefirst,      // send MSByte first, not LSByte (MSbit is always first)
  input [1:0] datawidth,  // select 8, 16, or 32 bits data transfer
  input miso,
  input [31:0] dataTx,
  output [31:0] dataRx,
  output reg rdy,
  output mosi,
  output sclk
);

  localparam tickCntFast = (clock_freq / fastSCLK);
  localparam tickCntSlow = (clock_freq / slowSCLK);
  localparam tickCntFast2 = tickCntFast / 2;
  localparam tickCntSlow2 = tickCntSlow / 2;

  wire w8  = (datawidth == 2'b00);
  wire w16 = (datawidth == 2'b10);
  wire w32 = (datawidth == 2'b01);

  reg [31:0] shreg;
  reg [6:0] tick;
  reg [4:0] bitcnt;

  wire endtick = fast ? (tick == tickCntFast) : (tick == tickCntSlow);
  wire sclk_switch = fast ? (tick >= tickCntFast2) : (tick >= tickCntSlow2);
  wire endbit = w32 ? (bitcnt == 31) : w16 ? (bitcnt == 15) : (bitcnt == 7);

  assign dataRx = w32 ? shreg : w16 ? {16'b0, shreg[15:0]} : {24'b0, shreg[7:0]};
  assign mosi = (rst | rdy) ? 1'b1 : msbytefirst ? (w32 ? shreg[31] : w16 ? shreg[15] : shreg[7]) : shreg[7];
  assign sclk = (rst | rdy) ? 1'b1 : sclk_switch;

  always @ (posedge clk) begin
    tick <= (rst | rdy | endtick) ? 7'b0 : tick + 7'b1;
    rdy <= (rst | endtick & endbit) ? 1'b1 : start ? 1'b0 : rdy;
    bitcnt <= (rst | start) ? 5'b0 : (endtick & ~endbit) ? bitcnt + 5'b1 : bitcnt;

    shreg <= rst ? -1 : start ? dataTx : endtick ?
      (msbytefirst ?
        ({shreg[30:0], miso}) :
        ({shreg[30:24], miso, shreg[22:16], shreg[31], shreg[14:8],
         (w16 ? miso : shreg[23]), shreg[6:0], (w8 ? miso : shreg[15])})) : shreg;
  end

endmodule

`resetall

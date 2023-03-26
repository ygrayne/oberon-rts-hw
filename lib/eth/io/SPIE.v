/**
  Serial Peripheral Interface (SPI)
  --
  Architecture: ETH
  --
  Base: Project Oberon, PDR 23.3.12 / 16.10.13
  --
  New features:
  * Separation of data width and speed selection
  * Data can be 8, 16, or 32 bits wide
  * Data can be sent out (MOSI) as LSByte or MSByte first
  * Clock frequency is parameterised
  --
  Clock frequency/speed:
  * fast = fast_sclk
  * slow = slow_sclk
  --
  Data width:
  * [1:0] width: 2'b00 => 8 bits, 2'b10 => 16 bits, 2'b01 => 32 bits
  --
  2020 Gray, gray@grayraven.org, 2020-06-16
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module spie #(parameter clock_freq = 50000000, fast_sclk = 10000000, slow_sclk = 400000) (
  input wire clk, rst_n,
  input wire start,
  input wire fast,             // use fast transfer speed
  input wire msbytefirst,      // send MSByte first, not LSByte (MBbit is always first)
  input wire [1:0] datasize,   // select 8, 16, or 32 data transfer
  input wire [31:0] dataTx,
  input wire MISO,
  output wire [31:0] dataRx,
  output reg rdy,
  output wire MOSI, SCLK
);

  localparam tickCntFast = (clock_freq / fast_sclk);
  localparam tickCntSlow = (clock_freq / slow_sclk);
  localparam tickCntFast2 = tickCntFast / 2;
  localparam tickCntSlow2 = tickCntSlow / 2;

  wire w8  = (datasize == 2'b00);
  wire w16 = (datasize == 2'b10);
  wire w32 = (datasize == 2'b01);

  reg [31:0] shreg;
  reg [6:0] tick;
  reg [4:0] bitcnt;

  wire endtick = fast ? (tick == tickCntFast) : (tick == tickCntSlow);
  wire SCLKswitch = fast ? (tick >= tickCntFast2) : (tick >= tickCntSlow2);
  wire endbit = w32 ? (bitcnt == 31) : w16 ? (bitcnt == 15) : (bitcnt == 7);

  assign dataRx = w32 ? shreg : w16 ? {16'b0, shreg[15:0]} : {24'b0, shreg[7:0]};

  assign MOSI = (~rst_n | rdy) ? 1 : msbytefirst ? (w32 ? shreg[31] : w16 ? shreg[15] : shreg[7]) : shreg[7];
  assign SCLK = (~rst_n | rdy) ? 1 : SCLKswitch;

  always @ (posedge clk) begin
    tick <= (~rst_n | rdy | endtick) ? 0 : tick + 1;
    rdy <= (~rst_n | endtick & endbit) ? 1 : start ? 0 : rdy;
    bitcnt <= (~rst_n | start) ? 0 : (endtick & ~endbit) ? bitcnt + 1 : bitcnt;

    shreg <= ~rst_n ? -1 : start ? dataTx : endtick ?
      (msbytefirst ?
        ({shreg[30:0], MISO}) :
        ({shreg[30:24], MISO, shreg[22:16], shreg[31], shreg[14:8],
         (w16 ? MISO : shreg[23]), shreg[6:0], (w8 ? MISO : shreg[15])})) : shreg;

  end
endmodule

`resetall

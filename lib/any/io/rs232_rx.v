/**
  RS232 receiver
  115,200 and 19,200 baud, 8 bits
  --
  Architecture: ANY
  --
  Base: Project Oberon, NW 4.5.09 / 15.8.10 / 15.11.10 / 13.8.15
  --
  Changes by Gray, gray@grayraven.org:
  2020-05: Parameterised clock frequency
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module rs232_rx #(parameter clock_freq = 50000000) (
  input wire clk,
  input wire rst_n,
  input wire done,
  input wire rxd,
  input wire fsel,
  output wire rdy,
  output wire [7:0] data_out
);

  localparam limitFast = clock_freq / 115200;
  localparam limitSlow = clock_freq / 19200;

  reg run, stat, Q0, Q1;
  reg [11:0] tick;
  reg [3:0] bitcnt;
  reg [7:0] shreg;
  wire endtick, midtick, endbit;
  wire [11:0] limit;

  assign rdy = stat;
  assign data_out = shreg;
  assign endtick = (tick == limit);
  assign midtick = (tick == {1'h0, limit[11:1]});
  assign endbit = (bitcnt == 8);
  // assign limit = fsel ? 2604 : 434; // 50 MHZ
  assign limit = fsel ? limitSlow[11:0] : limitFast[11:0];

  always @ (posedge clk) begin
    run <= ((Q1 & ~Q0) | (~(~rst_n | (endtick & endbit)) & run));
    stat <= ((endtick & endbit) | (~(~rst_n | done) & stat));
    Q0 <= rxd;
    Q1 <= Q0;
    tick <= (run & ~endtick) ? (tick + 1'b1) : 12'b0;
    bitcnt <= (endtick & ~endbit) ? (bitcnt + 1'b1) : (endtick & endbit) ? 4'b0 : bitcnt;
    shreg <= midtick ? {Q1, shreg[7:1]} : shreg;
  end
endmodule

`resetall

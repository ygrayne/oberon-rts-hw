/**
  THM interface to ETH START2
  --
  Architecture: THM
  ---

  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module start_thm (
  input clk,
  input rst,
  input stb,
  input we,
  input [15:0] data_in,
  output [31:0] data_out,
  output ack
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  wire [8:0] dout;

  start start_0 (
    .clk(clk),
    .rst_n(~rst),
    .wr(wr_data),
    .data_in(data_in),
    .data_out(dout)
  );

  assign data_out[31:0] =
    rd_data ? {23'b0, dout} :
    32'b0;

  assign ack = stb;

endmodule
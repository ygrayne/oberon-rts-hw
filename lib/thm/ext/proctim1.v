/**
  THM interface to ETH PROCTIMBLK5
  --
  Architecture: THM
  ---

  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module proctim_thm (
  input clk,
  input rst,
  input stb,
  input we,
  input tick,
  input [31:0] data_in,
  output [31:0] data_out,
  output ack
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  wire [15:0] dout;

  proctimers #(.num_proc_tmr(16)) proctimers_0 (
    .clk(clk),
    .rst_n(~rst),
    .wr(wr_data),
    .tick(tick),
    .data_in(data_in),
    .procRdy(dout)
  );

  assign data_out[31:0] =
    rd_data ? {16'b0, dout} :
    32'h0;

  assign ack = stb;

endmodule
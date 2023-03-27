/**
  THM interface to ETH SYSCTRL
  --
  Architecture: THM
  ---

  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module sysctrl_thm (
  input clk,
  input rst,
  input stb,
  input we,
  input [15:0] data_in,
  output [31:0] data_out,
  output sys_rst,
  output ack
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  wire [15:0] dout;

  sysctrl sysctrl_1 (
    .clk(clk),
    .rst_n(~rst),
    .wr(wr_data),
    .data_in(data_in),
    .data_out(dout),
    .sysrst(sys_rst)
  );

  assign data_out[31:0] =
    rd_data ? {16'b0, dout} :
    32'b0;

  assign ack = stb;

endmodule
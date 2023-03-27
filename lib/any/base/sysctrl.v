/**
  System control register
  Stripped down... only implements system reset
  --
  Architecture: ANY
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module sysctrl (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire [15:0] data_in,
  output wire [31:0] data_out,
  output wire sysrst,
  output wire ack
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  reg [15:0] scr = 0;

  always @(posedge clk) begin
    scr <= rst ? {1'b1, 15'b0} : wr_data ? data_in[15:0] : scr;
  end

  assign data_out[31:0] =
    rd_data ? {16'b0, scr[15:0]} :
    32'b0;
  assign sysrst = scr[0];

  assign ack = stb;

endmodule

`resetall
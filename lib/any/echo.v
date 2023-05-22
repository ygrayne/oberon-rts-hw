/**
  Echo
  --
  For testing
  --
  Architecture: ANY
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

`define ECHO1 32'hffff4444
`define ECHO2 32'h4444ffff

module echo (
  input wire clk,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire ack
);

  wire rd_data1 = stb & ~we & ~addr;
  wire wr_data1 = stb &  we & ~addr;
  wire rd_data2 = stb & ~we & addr;
  wire wr_data2 = stb &  we & addr;

  reg [15:0] data1 = 0;
  reg [15:0] data2 = 0;

  always @(posedge clk) begin
    data1 <= wr_data1 ? data_in[15:0] : data1;
    data2 <= wr_data2 ? data_in[31:16] : data2;
  end

  assign data_out[31:0] =
    rd_data1 ? {16'b0, data1} :
    rd_data2 ? {16'b0, data2} :
    32'b0;

  assign ack = stb;

endmodule

`resetall

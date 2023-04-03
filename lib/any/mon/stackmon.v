/**
  Stack monitor
  --
  Architecture: ANY
  --
  Stack grows downwards.
  --
  (c) 2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module stackmon (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire [1:0] addr,
  input wire [23:0] sp_in,
  input wire [23:0] data_in,
  output wire [31:0] data_out,
  output wire trig_lim,
  output wire trig_hot,
  output wire ack
);

  wire rd_stk_limit  = stb & ~we & (addr[1:0] == 2'b00);  // read absolute stack limit (lowest address)
  wire wr_stk_limit  = stb & we &  (addr[1:0] == 2'b00);
  wire rd_hot_limit  = stb & ~we & (addr[1:0] == 2'b01);  // read upper hotzone address
  wire wr_hot_limit  = stb & we &  (addr[1:0] == 2'b01);
  wire rd_min_sp_val = stb & ~we & (addr[1:0] == 2'b10);  // read minimum reached stack value
  wire wr_min_sp_val = stb & we &  (addr[1:0] == 2'b10);
  wire rd_cor_num    = stb & ~we & (addr[1:0] == 2'b11);  // read coroutine mumber/id
  wire wr_cor_num    = stb & we &  (addr[1:0] == 2'b11);

  reg [23:0] stack_limit = 0;
  reg [23:0] hot_limit = 0;
  reg [23:0] min_sp_val = 0;
  reg [7:0] cor_num = 0;

  assign trig_lim = (sp_in < stack_limit);
  assign trig_hot = (sp_in < hot_limit);

  always @(posedge clk) begin
    stack_limit <= rst ? 24'b0 : wr_stk_limit ? data_in[23:0] : stack_limit;
    hot_limit <= rst ? 24'b0 : wr_hot_limit ? data_in[23:0] : hot_limit;
    min_sp_val <= rst ? 24'b0 : wr_min_sp_val ? data_in[23:0] : (sp_in < min_sp_val) ? sp_in : min_sp_val;
    cor_num <= rst ? 8'b0 : wr_cor_num ? data_in[7:0] : cor_num;
  end

  assign data_out[31:0] =
    rd_stk_limit ? {8'b0, stack_limit} :
    rd_hot_limit ? {8'b0, hot_limit} :
    rd_min_sp_val ? {8'b0, min_sp_val} :
    rd_cor_num ? {24'b0, cor_num} :
    32'b0;

  assign ack = stb;

endmodule

`resetall
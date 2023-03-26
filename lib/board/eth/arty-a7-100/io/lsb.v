/**
  LSB: LEDs, switches, buttons
  --
  Architecture: ETH
  Board: Arty-A7-100
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module lsb (
  input wire clk,
  input wire rst_n,
  input wire wr,
  input wire [3:0] btn_in,
  input wire [3:0] swi_in,
  input wire [7:0] data_in,
  output wire [31:0] data_out,
  output reg [7:0] leds = 0,
  output wire [3:0] btn,
  output wire [3:0] swi
);

  // debouncers
  dbnc #(.polarity(1)) dbnc_btn0 (.clk(clk), .btn_in(btn_in[0]), .btn_out(btn[0]));
  dbnc #(.polarity(1)) dbnc_btn1 (.clk(clk), .btn_in(btn_in[1]), .btn_out(btn[1]));
  dbnc #(.polarity(1)) dbnc_btn2 (.clk(clk), .btn_in(btn_in[2]), .btn_out(btn[2]));
  dbnc #(.polarity(1)) dbnc_btn3 (.clk(clk), .btn_in(btn_in[3]), .btn_out(btn[3]));

  dbnc #(.polarity(1)) dbnc_swi0 (.clk(clk), .btn_in(swi_in[0]), .btn_out(swi[0]));
  dbnc #(.polarity(1)) dbnc_swi1 (.clk(clk), .btn_in(swi_in[1]), .btn_out(swi[1]));
  dbnc #(.polarity(1)) dbnc_swi2 (.clk(clk), .btn_in(swi_in[2]), .btn_out(swi[2]));
  dbnc #(.polarity(1)) dbnc_swi3 (.clk(clk), .btn_in(swi_in[3]), .btn_out(swi[3]));

  always @(posedge clk) begin
    leds <= ~rst_n ? 8'b0 : wr ? data_in[7:0] : leds;
  end

  assign data_out[31:0] = {16'b0, 4'b0, btn[3:0], 4'b0, swi[3:0]};

endmodule

`resetall
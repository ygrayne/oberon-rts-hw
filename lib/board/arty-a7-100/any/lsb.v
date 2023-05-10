/**
  LSB: LEDs, switches, buttons
  --
  Architecture: ANY
  Board: Arty-A7-100
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module lsb (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire [3:0] btn_in,
  input wire [3:0] swi_in,
  input wire [15:0] data_in,
  output wire [31:0] data_out,
  output reg [7:0] leds = 0,
  output wire [3:0] btn_out,
  output wire [3:0] swi_out,
  output reg [3:0] led_g,
  output wire ack
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  // debouncers
  dbnc #(.polarity(1)) dbnc_btn0 (.clk(clk), .btn_in(btn_in[0]), .btn_out(btn_out[0]));
  dbnc #(.polarity(1)) dbnc_btn1 (.clk(clk), .btn_in(btn_in[1]), .btn_out(btn_out[1]));
  dbnc #(.polarity(1)) dbnc_btn2 (.clk(clk), .btn_in(btn_in[2]), .btn_out(btn_out[2]));
  dbnc #(.polarity(1)) dbnc_btn3 (.clk(clk), .btn_in(btn_in[3]), .btn_out(btn_out[3]));

  dbnc #(.polarity(1)) dbnc_swi0 (.clk(clk), .btn_in(swi_in[0]), .btn_out(swi_out[0]));
  dbnc #(.polarity(1)) dbnc_swi1 (.clk(clk), .btn_in(swi_in[1]), .btn_out(swi_out[1]));
  dbnc #(.polarity(1)) dbnc_swi2 (.clk(clk), .btn_in(swi_in[2]), .btn_out(swi_out[2]));
  dbnc #(.polarity(1)) dbnc_swi3 (.clk(clk), .btn_in(swi_in[3]), .btn_out(swi_out[3]));

  always @(posedge clk) begin
    leds <= rst ? 8'b0 : wr_data ? data_in[7:0] : leds;
    led_g <= rst ? 4'b0 :  wr_data ? data_in[11:8] : led_g;
  end

  assign data_out[31:0] =
    rd_data ? {16'b0, 4'b0, btn_out[3:0], 4'b0, swi_out[3:0]} :
    32'b0;

  assign ack = stb;

endmodule

`resetall
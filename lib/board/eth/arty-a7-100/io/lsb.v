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
  DBNC dbnc_btn0 (.clk(clk), .hwbutton(btn_in[0]), .state(btn[0]));
  DBNC dbnc_btn1 (.clk(clk), .hwbutton(btn_in[1]), .state(btn[1]));
  DBNC dbnc_btn2 (.clk(clk), .hwbutton(btn_in[2]), .state(btn[2]));
  DBNC dbnc_btn3 (.clk(clk), .hwbutton(btn_in[3]), .state(btn[3]));

  DBNC dbnc_swi0 (.clk(clk), .hwbutton(swi_in[0]), .state(swi[0]));
  DBNC dbnc_swi1 (.clk(clk), .hwbutton(swi_in[1]), .state(swi[1]));
  DBNC dbnc_swi2 (.clk(clk), .hwbutton(swi_in[2]), .state(swi[2]));
  DBNC dbnc_swi3 (.clk(clk), .hwbutton(swi_in[3]), .state(swi[3]));

  always @(posedge clk) begin
    leds <= ~rst_n ? 8'b0 : wr ? data_in[7:0] : leds;
  end

  assign data_out[31:0] = {16'b0, 4'b0, btn[3:0], 4'b0, swi[3:0]};

endmodule

`resetall
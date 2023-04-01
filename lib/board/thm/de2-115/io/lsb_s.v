/**
  LSB: LEDs, Switches, Buttons
  --
  Red LEDs are switched by hardware input signals.
  --
  Architecture: THM
  --
  Based on THM bio.v
  --
  Seven segment display not accessible
  --
  data_in [25:0]:
    [7:0]: green LEDs (8 of 9 total)
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
  * all buttons handled here, incl. reset
  * change output data to align the "higher" switches with bit 16
  * enable red LEDs
  * add output wires for buttons and switches
**/

`timescale 1ns / 1ps
`default_nettype none

module lsb_s (
  // internal interface
  input clk,
  input rst,
  input stb,
  input we,
  input [25:0] data_in,
  input [17:0] led_r_in,
  output [31:0] data_out,
  output ack,
  // external interface,
  input [3:0] btn_in_n,
  input [17:0] swi_in,
  output reg [8:0] led_g,
  output reg [17:0] led_r,
  output reg [6:0] hex7_n,
  output reg [6:0] hex6_n,
  output reg [6:0] hex5_n,
  output reg [6:0] hex4_n,
  output reg [6:0] hex3_n,
  output reg [6:0] hex2_n,
  output reg [6:0] hex1_n,
  output reg [6:0] hex0_n,
  output [3:0] btn,
  output [17:0] swi
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  reg [3:0] btn_p_n;
  reg [3:0] btn_s_n;
  reg [17:0] swi_p;
  reg [17:0] swi_s;

  always @(posedge clk) begin
    if (rst) begin
      led_g[8:0] <= 9'h0;
      led_r[17:0] <= 18'h0;
      hex7_n[6:0] <= ~7'h0;
      hex6_n[6:0] <= ~7'h0;
      hex5_n[6:0] <= ~7'h0;
      hex4_n[6:0] <= ~7'h0;
      hex3_n[6:0] <= ~7'h0;
      hex2_n[6:0] <= ~7'h0;
      hex1_n[6:0] <= ~7'h0;
      hex0_n[6:0] <= ~7'h0;
    end else begin
      if (wr_data) begin
        led_g[7:0] <= data_in[7:0];
      end
      led_r[17:0] <= led_r_in[17:0];
    end
  end

  always @(posedge clk) begin
    btn_p_n[3:0] <= btn_in_n[3:0];
    btn_s_n[3:0] <= btn_p_n[3:0];
    swi_p[17:0] <= swi_in[17:0];
    swi_s[17:0] <= swi_p[17:0];
  end

  assign btn[3:0] = ~btn_s_n[3:0];
  assign swi[17:0] = swi_s[17:0];

  assign data_out[31:0] =
    rd_data ? {6'b0, swi[17:8], 4'b0, btn[3:0], swi[7:0]} :
    32'b0;

  assign ack = stb;

endmodule

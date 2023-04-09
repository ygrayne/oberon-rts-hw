/**
  LSB: LEDs, Switches, Buttons
  --
  Architecture: AMY
  Board: DE2-115
  --
  * Red LEDs are also switched by hardware input signals.
  * Red LEDs use "toggle" mechanism for on/off
  --
  Based on THM bio.v
  --
  Seven segment display not accessible yet
  --
  data_in [31:0]:
    [7:0]: green LEDs (8 of 9 total)
    [25:8]: greed LEDs (18)
    [30:26]: unused
    [31:31]: green LEDs toggle
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
  input [31:0] data_in,
  input [17:0] leds_r_in,
  output [31:0] data_out,
  output ack,
  // external interface,
  input [3:0] btn_in_n,
  input [17:0] swi_in,
  output [17:0] leds_r,
  output reg [8:0] leds_g,
  output reg [6:0] hex7_n,
  output reg [6:0] hex6_n,
  output reg [6:0] hex5_n,
  output reg [6:0] hex4_n,
  output reg [6:0] hex3_n,
  output reg [6:0] hex2_n,
  output reg [6:0] hex1_n,
  output reg [6:0] hex0_n,
  output [3:0] btn_out,
  output [17:0] swi_out
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  wire leds_r_on = data_in[31];

  reg [3:0] btn_p_n;
  reg [3:0] btn_s_n;
  reg [17:0] swi_p;
  reg [17:0] swi_s;

  reg [17:0] leds_r_s;
  reg [17:0] leds_r_d;
  assign leds_r[17:0] = leds_r_s[17:0] | leds_r_d[17:0];

  always @(posedge clk) begin
    if (rst) begin
      leds_r_s[17:0] <= 18'h0;
      leds_r_d[17:0] <= 18'h0;
      leds_g[8:0] <= 9'h0;
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
        leds_g[7:0] <= data_in[7:0];
        if (leds_r_on) begin
          leds_r_d[17:0] <= leds_r_d[17:0] | data_in[25:8];
        end
        else begin
          leds_r_d[17:0] <= leds_r_d[17:0] & ~data_in[25:8];
        end
      end
      leds_r_s[17:0] <= leds_r_in[17:0];
    end
  end

  always @(posedge clk) begin
    btn_p_n[3:0] <= btn_in_n[3:0];
    btn_s_n[3:0] <= btn_p_n[3:0];
    swi_p[17:0] <= swi_in[17:0];
    swi_s[17:0] <= swi_p[17:0];
  end

  assign btn_out[3:0] = ~btn_s_n[3:0];
  assign swi_out[17:0] = swi_s[17:0];

  assign data_out[31:0] =
    rd_data ? {6'b0, swi_out[17:8], 4'b0, btn_out[3:0], swi[7:0]} :
    32'b0;

  assign ack = stb;

endmodule

/**
  LSB: LEDs, Switches, Buttons
  Generously, we subsume the 7-segment displays as LEDs. :)
  --
  Architecture: ANY
  Board: DE2-115
  --
  * Red LEDs are also switched by hardware input signals.
  * Red LEDs use "toggle" mechanism for on/off
  * 7-segment displays (2 + 2 + 4, from left to right)
  * All buttons handled here, incl. reset
  --
  Base/origin: THM
  --
  data_in [31:0]:
    [7:0]: green LEDs (8 of 9 total)
    [25:8]: red LEDs (18), or 7-segment display value
    [29:26]: 7-segment display selector (data as data_in[11:8])
    [31:30]: red LEDs toggle (data as data_in[25:8])
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
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
  input [17:0] leds_r_in,   // can only be clock-synchronised source
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

  // control data in data_in
  // for red LEDs and 7-segments
  wire [5:0] ctrl = data_in[31:26];

  // 7-segment encoder out
  wire [6:0] segs_n;

  // clock synchronisers
  reg [3:0] btn_p_n;
  reg [3:0] btn_s_n;
  reg [17:0] swi_p;
  reg [17:0] swi_s;

  // red LEDs controls
  // OR-ed, see below
  reg [17:0] leds_r_s;  // direct hw signal
  reg [17:0] leds_r_d;  // via data

  // 7-segment LUT
  lut7 lut7_0 (
    .digit(data_in[11:8]),
    .segs_n(segs_n[6:0])
  );

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
    end
    else begin
      leds_r_s[17:0] <= leds_r_in[17:0];
      if (wr_data) begin
        leds_g[7:0] <= data_in[7:0];
        case (ctrl[5:0])
          6'b010000: leds_r_d[17:0] <= leds_r_d[17:0] & ~data_in[25:8];   // off
          6'b100000: leds_r_d[17:0] <= leds_r_d[17:0] | data_in[25:8];    // on
          6'b001000: hex0_n[6:0] <= segs_n[6:0];
          6'b001001: hex1_n[6:0] <= segs_n[6:0];
          6'b001010: hex2_n[6:0] <= segs_n[6:0];
          6'b001011: hex3_n[6:0] <= segs_n[6:0];
          6'b001100: hex4_n[6:0] <= segs_n[6:0];
          6'b001101: hex5_n[6:0] <= segs_n[6:0];
          6'b001110: hex6_n[6:0] <= segs_n[6:0];
          6'b001111: hex7_n[6:0] <= segs_n[6:0];
        endcase
      end
    end
  end

  // sync buttons and switches
  always @(posedge clk) begin
    btn_p_n[3:0] <= btn_in_n[3:0];
    btn_s_n[3:0] <= btn_p_n[3:0];
    swi_p[17:0] <= swi_in[17:0];
    swi_s[17:0] <= swi_p[17:0];
  end

  // output assignments
  assign btn_out[3:0] = ~btn_s_n[3:0];
  assign swi_out[17:0] = swi_s[17:0];

  assign leds_r[17:0] = leds_r_s[17:0] | leds_r_d[17:0];

  assign data_out[31:0] =
    rd_data ? {6'b0, swi_out[17:8], 4'b0, btn_out[3:0], swi_out[7:0]} :
    32'b0;

  assign ack = stb;

endmodule

module lut7 (
  input wire [3:0] digit,
  output reg [6:0] segs_n
);

  always @(digit) begin
    case (digit)
      0: segs_n[6:0] = ~7'b0111111;
      1: segs_n[6:0] = ~7'b0000110;
      2: segs_n[6:0] = ~7'b1011011;
      3: segs_n[6:0] = ~7'b1001111;
      4: segs_n[6:0] = ~7'b1100110;
      5: segs_n[6:0] = ~7'b1101101;
      6: segs_n[6:0] = ~7'b1111101;
      7: segs_n[6:0] = ~7'b0000111;
      8: segs_n[6:0] = ~7'b1111111;
      9: segs_n[6:0] = ~7'b1101111;
      10: segs_n[6:0] = ~7'b1110111;  // A
      11: segs_n[6:0] = ~7'b1111100;  // b
      12: segs_n[6:0] = ~7'b0111001;  // C
      13: segs_n[6:0] = ~7'b1011110;  // d
      14: segs_n[6:0] = ~7'b1111001;  // E
      15: segs_n[6:0] = ~7'b1110001;  // F
      default: segs_n[6:0] = ~7'b0000000;
    endcase
end

endmodule

`resetall

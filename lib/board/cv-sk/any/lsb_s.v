/**
  LSB: LEDs, Switches, Buttons
  Generously, we subsume the 7-segment displays under LEDs. :)
  --
  Architecture: ANY
  Board: CV-SK
  --
  * Red LEDs can also be operated by direct hardware input signals.
  * From software, red LEDs use "toggle" mechanism for on/off
  * 7-segment displays (2 + 2, from left to right)
  --
  data_in [31:0]:
    [7:0]: green LEDs
    [17:8]: red LEDs, or 7-segment display value
    [29:26]: 7-segment display selector (data as data_in[11:8])
    [31:30]: red LEDs toggle (data as data_in[17:8])
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module lsb_s #(parameter board = 4'd3) ( // board identifier
  // internal interface
  input clk,
  input rst,
  input stb,
  input we,
  input [31:0] data_in,
  input [9:0] leds_r_in,   // can only be clock-synchronised source
  output [31:0] data_out,
  output ack,
  // external interface,
  input [3:0] btn_in_n,
  input [9:0] swi_in,
  output [9:0] leds_r,
  output reg [7:0] leds_g,
  output reg [6:0] hex1_n,
  output reg [6:0] hex0_n,
  output [3:0] btn_out,
  output [9:0] swi_out
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  // control data in data_in
  // for red LEDs and 7-segments
  wire [5:0] ctrl = data_in[31:26];

  // 7-segment encoder out
  wire [6:0] segs_n;

  // clock synchronisers
  reg [3:0] btn_0_n;
  reg [3:0] btn_1_n;
  reg [9:0] swi_0;
  reg [9:0] swi_1;

  // red LEDs controls
  // OR-ed, see below
  reg [9:0] leds_r_s;  // direct hw signal
  reg [9:0] leds_r_d;  // via data

  // 7-segment LUT
  lut7 lut7_0 (
    .digit(data_in[11:8]),
    .segs_n(segs_n[6:0])
  );

  always @(posedge clk) begin
    if (rst) begin
      leds_r_s[9:0] <= 10'h0;
      leds_r_d[9:0] <= 10'h0;
      leds_g[7:0] <= 8'h0;
      hex1_n[6:0] <= ~7'h0;
      hex0_n[6:0] <= ~7'h0;
    end
    else begin
      leds_r_s[9:0] <= leds_r_in[9:0];
      if (wr_data) begin
        if (data_in[31:8] == 24'b0) begin
          leds_g[7:0] <= data_in[7:0];
        end
        else begin
          case (ctrl[5:0])
            6'b010000: leds_r_d[9:0] <= leds_r_d[9:0] & ~data_in[17:8];   // off
            6'b100000: leds_r_d[9:0] <= leds_r_d[9:0] | data_in[17:8];    // on
            6'b001000: hex0_n[6:0] <= segs_n[6:0];
            6'b001001: hex1_n[6:0] <= segs_n[6:0];
          endcase
        end
      end
    end
  end

  // sync buttons and switches
  always @(posedge clk) begin
    btn_0_n[3:0] <= btn_in_n[3:0];
    btn_1_n[3:0] <= btn_0_n[3:0];
    swi_0[9:0] <= swi_in[9:0];
    swi_1[9:0] <= swi_0[9:0];
  end

  // output assignments
  assign btn_out[3:0] = ~btn_1_n[3:0];
  assign swi_out[9:0] = swi_1[9:0];

  assign leds_r[9:0] = leds_r_s[9:0] | leds_r_d[9:0];

  assign data_out[31:0] =
    rd_data ? {board[3:0], 10'b0, swi_out[9:8], 4'b0, btn_out[3:0], swi_out[7:0]} :
    32'b0;

  assign ack = stb;

endmodule

module lut7 (
  input wire [3:0] digit,
  output reg [6:0] segs_n
);

  always @(*) begin
    case (digit)
      4'd0: segs_n[6:0] = ~7'b0111111;
      4'd1: segs_n[6:0] = ~7'b0000110;
      4'd2: segs_n[6:0] = ~7'b1011011;
      4'd3: segs_n[6:0] = ~7'b1001111;
      4'd4: segs_n[6:0] = ~7'b1100110;
      4'd5: segs_n[6:0] = ~7'b1101101;
      4'd6: segs_n[6:0] = ~7'b1111101;
      4'd7: segs_n[6:0] = ~7'b0000111;
      4'd8: segs_n[6:0] = ~7'b1111111;
      4'd9: segs_n[6:0] = ~7'b1101111;
      4'd10: segs_n[6:0] = ~7'b1110111;  // A
      4'd11: segs_n[6:0] = ~7'b1111100;  // b
      4'd12: segs_n[6:0] = ~7'b0111001;  // C
      4'd13: segs_n[6:0] = ~7'b1011110;  // d
      4'd14: segs_n[6:0] = ~7'b1111001;  // E
      4'd15: segs_n[6:0] = ~7'b1110001;  // F
      default: segs_n[6:0] = ~7'b0000000;
    endcase
end

endmodule

`resetall

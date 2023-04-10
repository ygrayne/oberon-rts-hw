/**
  LSB: LEDs, switches, buttons
  --
  Architecture: ANY
  Board: Arty-A7-100
  --
  * Green LEDs are also switched by hardware input signals.
  * Green LEDs use "toggle" mechanism for on/off
  * Compatible with DE2-115 design, hence the wide 'unused' gap.
  --
    data_in [31:0]:
    [7:0]: system LEDs on Pmod port
    [11:8]: green LEDs on the board (4)
    [30:12]: unused
    [31:31]: green LEDs toggle
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module lsb_s (
  // internal interface
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire [31:0] data_in,
  input wire [3:0] leds_g_in,
  output wire [31:0] data_out,
  output wire ack,
  // external interface
  input wire [3:0] btn_in,
  input wire [3:0] swi_in,
  output reg [7:0] leds_sys,
  output wire [3:0] leds_g,
  output wire [3:0] btn_out,
  output wire [3:0] swi_out
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  // control data in data_in
  // for red LEDs and 7-segments
  wire [1:0] ctrl = data_in[31:30];

  // green LEDs controls
  // OR-ed, see below
  reg [3:0] leds_g_s; // direct hw signal
  reg [3:0] leds_g_d; // via data

  // debouncers-syncers
  dbnc #(.polarity(1)) dbnc_btn0 (.clk(clk), .btn_in(btn_in[0]), .btn_out(btn_out[0]));
  dbnc #(.polarity(1)) dbnc_btn1 (.clk(clk), .btn_in(btn_in[1]), .btn_out(btn_out[1]));
  dbnc #(.polarity(1)) dbnc_btn2 (.clk(clk), .btn_in(btn_in[2]), .btn_out(btn_out[2]));
  dbnc #(.polarity(1)) dbnc_btn3 (.clk(clk), .btn_in(btn_in[3]), .btn_out(btn_out[3]));

  dbnc #(.polarity(1)) dbnc_swi0 (.clk(clk), .btn_in(swi_in[0]), .btn_out(swi_out[0]));
  dbnc #(.polarity(1)) dbnc_swi1 (.clk(clk), .btn_in(swi_in[1]), .btn_out(swi_out[1]));
  dbnc #(.polarity(1)) dbnc_swi2 (.clk(clk), .btn_in(swi_in[2]), .btn_out(swi_out[2]));
  dbnc #(.polarity(1)) dbnc_swi3 (.clk(clk), .btn_in(swi_in[3]), .btn_out(swi_out[3]));

  always @(posedge clk) begin
    if (rst) begin
      leds_sys[7:0] <= 8'b0;
      leds_g_s[3:0] <= 4'b0;
      leds_g_d[3:0] <= 4'b0;
    end
    else begin
      leds_g_s[3:0] <= leds_g_in[3:0];
      if (wr_data) begin
        leds_sys <= data_in[7:0];
        case (ctrl[1:0])
          2'b01: leds_g_d[3:0] <= leds_g_d[3:0] & ~data_in[11:8];   // off
          2'b10: leds_g_d[3:0] <= leds_g_d[3:0] | data_in[11:8];    // off
        endcase
      end
    end
  end

  // output assignments
  assign leds_g[3:0] = leds_g_s[3:0] | leds_g_d[3:0];

  assign data_out[31:0] =
    rd_data ? {16'b0, 4'b0, btn_out[3:0], 4'b0, swi_out[3:0]} :
    32'b0;

  assign ack = stb;

endmodule

`resetall
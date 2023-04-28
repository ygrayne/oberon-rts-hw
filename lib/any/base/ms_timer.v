/**
  Milliseconds timer
  --
  Architecture: ANY
  --
  Origin: RISC5Top.v of Project Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module ms_timer #(parameter clock_freq = 40_000_000) (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  output wire [31:0] data_out,
  output wire ms_tick,
  output wire ack
);

  wire rd_data = stb & ~we;

  localparam clock_divider = clock_freq / 1000;

  reg [15:0] cnt0 = 0;
  reg [31:0] cnt1 = 0;
  wire ms = (cnt0 == clock_divider - 1) ? 1'b1 : 1'b0;

  always @(posedge clk) begin
   cnt0[15:0] <= ms ? 16'b0 : cnt0[15:0] + 16'b1;
   cnt1[31:0] <= rst ? 32'b0 : ms ? cnt1[31:0] + 32'b1 : cnt1;
  end

  assign data_out[31:0] =
    rd_data ? cnt1[31:0] :
    32'b0;

  assign ms_tick = ms;

  assign ack = stb;

endmodule

`resetall
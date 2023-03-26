/**
  Milliseconds timer
  --
  Architecture: ETH
  --
  Origin: RISC5Top.v of Project Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module tmr #(parameter clock_freq = 40_000_000) (
  input wire clk,
  input wire rst_n,
  output wire [31:0] data_out,
  output wire ms_tick
);

  localparam clock_divider = clock_freq / 1000;

  reg [15:0] cnt0 = 0;
  reg [31:0] cnt1 = 0;
  wire ms = (cnt0 == clock_divider - 1);

  always @(posedge clk) begin
   cnt0 <= ms ? 16'b0 : cnt0 + 16'b1;
   cnt1 <= ~rst_n ? 32'b0 : ms ? cnt1 + 16'b1 : cnt1;
  end

  assign data_out = cnt1;
  assign ms_tick = ms;

endmodule

`resetall
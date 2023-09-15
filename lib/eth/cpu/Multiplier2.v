`timescale 1ns / 1ps   // NW 14.9.2015

// 2023-05: add 'en' input signal, default_nettype none

`default_nettype none

  module Multiplier (
    input wire clk, run, u,
    input wire en,
    output wire stall,
    input wire [31:0] x, y,
    output wire [63:0] z
  );

  reg [5:0] S;    // state
  reg [63:0] P;   // product
  wire [31:0] w0;
  wire [32:0] w1;

  assign stall = run & ~(S == 33);
  assign w0 = P[0] ? y : 0;
  assign w1 = (S == 32) & u ? {P[63], P[63:32]} - {w0[31], w0} :
         {P[63], P[63:32]} + {w0[31], w0};
  assign z = P;

  always @ (posedge clk) begin
    if (en) begin
      P <= (S == 0) ? {32'b0, x} : {w1[32:0], P[31:1]};
      S <= run ? S+1 : 0;
    end
  end

  endmodule

`resetall
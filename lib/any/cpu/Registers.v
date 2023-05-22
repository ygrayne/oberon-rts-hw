/**
  Generic register file for RISC5 CPU
  --
  Synchronous writes, asynchronous reads.
  --
  (c) 2022 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module Registers (
  input wire clk,
  input wire wr,
  input wire [3:0] rno0, rno1, rno2,
  input wire [31:0] din,
  output wire [31:0] dout0, dout1, dout2
);

  reg [31:0] R [0:15];

  assign dout0[31:0] = R[rno0];
  assign dout1[31:0] = R[rno1];
  assign dout2[31:0] = R[rno2];

  always @(posedge clk) begin
//    R[rno0] <= wr ? din[31:0] : R[rno0];
    if (wr) begin
      R[rno0] <= din[31:0];
    end
  end

endmodule

`resetall
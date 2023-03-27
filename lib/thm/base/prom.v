/**
  PROM
  --
  Architecture: THM
  --
  Origin: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
  --
  2023-03: parameter 'memfile'
**/

`timescale 1ns / 1ps
`default_nettype none

module prom #(parameter memfile) (
  input clk,
  input rst,
  input stb,
  input we,
  input [10:2] addr,
  output reg [31:0] data_out,
  output reg ack
);

  reg [31:0] mem[0:511];

  initial begin
    $readmemh(memfile, mem);
  end

  always @(posedge clk) begin
    if (stb & ~we) begin
      data_out <= mem[addr];
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ack <= 1'b0;
    end else begin
      if (stb & ~we) begin
        ack <= ~ack;
      end
    end
  end

endmodule

`resetall

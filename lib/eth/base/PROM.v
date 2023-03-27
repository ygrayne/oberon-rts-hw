/**
  32-bit PROM initialised from hex file
  --
  Architeture: ETH
  --
  Base: Project Oberon, PDR 23.12.13
  --
  Changes by Gray, gray@grayraven.org
  2020-05: memory file name parameterisation
  2023-03: simplified mem file parameterisation
**/

`timescale 1ns / 1ps
`default_nettype none

module prom #(parameter memfile = "BootLoad.mem") (
  input wire clk,
  input wire [8:0] adr,
  output reg [31:0] data_out
);

  reg [31:0] mem [511:0];

  initial begin
    $readmemh(memfile, mem);
  end

  always @(posedge clk) begin
    data_out <= mem[adr];
  end

endmodule

`resetall
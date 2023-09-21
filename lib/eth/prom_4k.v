/**
  32-bit PROM initialised from hex file, 4k
  --
  Architecture: ETH
  --
  Base: Project Oberon, PDR 23.12.13
  --
  Changes by Gray, gray@grayraven.org
  2020-05: memory file name parameterisation
  2023-03: simplified mem file parameterisation
**/

`timescale 1ns / 1ps
`default_nettype none

module prom_4k #(parameter mem_file = "BootLoad.mem") (
  input wire clk,
  input wire en,
  input wire [9:0] addr,
  output reg [31:0] data_out
);

  reg [31:0] mem [1023:0];

  initial begin
    $readmemh(mem_file, mem);
  end

  always @(posedge clk) begin
    if (en) begin
      data_out <= mem[addr];
    end
  end

endmodule

`resetall
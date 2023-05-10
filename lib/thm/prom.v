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
  2023-03: parameter 'mem_file'
**/

`timescale 1ns / 1ps
`default_nettype none

module prom #(parameter mem_file = "BootLoad.mem") (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire [8:0] addr,
  output reg [31:0] data_out,
  output reg ack
);

  wire rd_data = stb & ~we;

  reg [31:0] mem[0:511];

  initial begin
    $readmemh(mem_file, mem);
  end

  always @(posedge clk) begin
    if (rd_data) begin
      data_out <= mem[addr];
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ack <= 1'b0;
    end else begin
      if (rd_data) begin
        ack <= ~ack;
      end
    end
  end

endmodule

`resetall

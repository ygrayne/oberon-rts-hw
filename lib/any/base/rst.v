/**
  Reset
  --
  Architecture: ANY
  --
  Base: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module rst (
  input wire clk,
  input wire clk_ok,
  input wire rst_in,
  output wire rst,
  output wire rst_n
);

  reg [23:0] rst_counter;
  wire rst_counting = (rst_counter[23:0] == 24'h0FFFFF) ? 1'b0 : 1'b1;

  always @(posedge clk) begin
    if (rst_in | ~clk_ok) begin
      rst_counter[23:0] <= 24'h000000;
    end else begin
      if (rst_counting) begin
        rst_counter[23:0] <= rst_counter[23:0] + 24'h000001;
      end
    end
  end

  assign rst = rst_counting;
  assign rst_n = ~rst_counting;

endmodule

`resetall

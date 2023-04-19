/**
  Reset
  --
  Architecture: ANY
  Board: Arty A7
  --
  Origin: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module reset (
  input wire clk_in,    // 100 MHz
  input wire clk_ok,
  input wire rst_in,
  output wire rst_out,
  output wire rst_out_n
);

  reg rst_p;
  reg rst_s;
  reg [23:0] rst_counter;
  wire rst_counting = (rst_counter[23:0] == 24'hFFFFFF) ? 1'b0 : 1'b1;

  reg clk_in_0 = 0;
  always @(posedge clk_in) clk_in_0 <= ~clk_in_0;

  always @(posedge clk_in_0) begin
    rst_p <= rst_in;
    rst_s <= rst_p;
    if (rst_s | ~clk_ok) begin
      rst_counter[23:0] <= 24'h000000;
    end
    else begin
      if (rst_counting) begin
        rst_counter[23:0] <= rst_counter[23:0] + 24'h000001;
      end
    end
  end

  assign rst_out = rst_counting;
  assign rst_out_n = ~rst_counting;

endmodule

`resetall

/**
  Reset
  --
  Architecture: ANY
  Board: DE2-115
  --
  Origin: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module rst (
  input wire clk_in,
  input wire clk_ok,
  input wire rst_in_n,
  output wire rst_out,
  output wire rst_out_n
);

  reg rst_p_n;
  reg rst_s_n;
  reg [23:0] rst_counter;
  wire rst_counting = (rst_counter[23:0] == 24'hFFFFFF) ? 1'b0 : 1'b1;

  always @(posedge clk_in) begin
    rst_p_n <= rst_in_n;
    rst_s_n <= rst_p_n;
    if (~rst_s_n | ~clk_ok) begin
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

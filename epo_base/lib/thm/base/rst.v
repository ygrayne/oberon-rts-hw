/**
  Reset
  --
  Architecture: THM
  --
  Base: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module rst(
  input clk,
  input clk_ok,
  input rst_in_n,
  output rst
);

  reg rst_p_n;
  reg rst_s_n;
  reg [23:0] rst_counter;
  wire rst_counting = (rst_counter[23:0] == 24'hFFFFFF) ? 1'b0 : 1'b1;

  always @(posedge clk) begin
    rst_p_n <= rst_in_n;
    rst_s_n <= rst_p_n;
    if (~rst_s_n | ~clk_ok) begin
      rst_counter[23:0] <= 24'h000000;
    end else begin
      if (rst_counting) begin
        rst_counter[23:0] <= rst_counter[23:0] + 24'h000001;
      end
    end
  end

  assign rst = rst_counting;

endmodule

`resetall

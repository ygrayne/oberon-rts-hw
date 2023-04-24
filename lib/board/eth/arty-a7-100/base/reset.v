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
  input wire clk_in,    // 100 MHz "raw" FPGA-in clock
  input wire clk_ok,
  input wire rst_in,
  output reg rst_out,
  output wire rst_out_n
);

  reg rst_p;
  reg rst_s;
  reg [23:0] rst_cnt;

  reg clk_in_0 = 0;
  always @(posedge clk_in) clk_in_0 <= ~clk_in_0;

  always @(posedge clk_in_0) begin
    rst_p <= rst_in;
    rst_s <= rst_p;

    if (rst_s | ~clk_ok) begin
      rst_cnt[23:0] <= 24'h0;
      rst_out <= 1'b1;
    end
    else begin
      if (rst_out) begin
        if (rst_cnt[23:0] == 24'hFFFFFF) begin
          rst_out <= 1'b0;
        end
        else begin
          rst_cnt[23:0] <= rst_cnt[23:0] + 24'h1;
        end
      end
    end
  end

  assign rst_out_n = ~rst_out;

endmodule

`resetall

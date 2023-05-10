/**
  Reset
  --
  Architecture: ANY
  Board: Arty A7 (buttons are active high, not debounced)
  --
  Origin: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module reset (
  input wire clk,
  input wire clk_ok,
  input wire rst_in,
  output reg rst_out
);

  reg rst_0;
  reg rst_1;
  reg rst_1_0;
  reg [23:0] rst_cnt;
  wire rst = rst_1 & ~rst_1_0;

//  reg clk_in_0 = 0;
//  always @(posedge clk_in) clk_in_0 <= ~clk_in_0;

  always @(posedge clk) begin
    rst_0 <= rst_in;
    rst_1 <= rst_0;
    rst_1_0 <= rst_1;

    if (rst | ~clk_ok) begin
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

endmodule

`resetall

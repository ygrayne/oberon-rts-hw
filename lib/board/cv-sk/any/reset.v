/**
  Reset
  --
  Architecture: ANY
  Board: CV-SK (buttons are active low, debounced)
  Reset output is active high.
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
  input wire rst_in_n,
  output reg rst_out
);

  reg rst_0_n;
  reg rst_1_n;
  reg rst_1_n_0;
  reg [23:0] rst_cnt;
  wire rst = ~rst_1_n & rst_1_n_0;
  
  always @(posedge clk) begin
    rst_0_n <= rst_in_n;
    rst_1_n <= rst_0_n;
    rst_1_n_0 <= rst_1_n;

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

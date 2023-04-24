/**
  Reset
  --
  Architecture: ANY
  Board: DE2-115 (buttons are active low)
  --
  Origin: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module reset (
  input wire clk_in,  // 50 MHz "raw" FPGA-in clock
  input wire clk_ok,
  input wire rst_in_n,
  output reg rst_out,
  output wire rst_out_n
);

  reg rst_p_n;
  reg rst_s_n;
  reg [23:0] rst_cnt;

  always @(posedge clk_in) begin
    rst_p_n <= rst_in_n;
    rst_s_n <= rst_p_n;

    if (~rst_s_n | ~clk_ok) begin
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

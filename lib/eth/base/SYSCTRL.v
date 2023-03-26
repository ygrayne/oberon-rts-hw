`timescale 1ns / 1ps
/**
  System control register
  Stripped down... only implements system reset
  --
  Architecture: ETH
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

module sysctrl (
  input wire clk,
  input wire rst_n,
  input wire wr,
  input wire [15:0] data_in,
  output wire [15:0] data_out,
  output wire sysrst
);

  reg [15:0] scr = 0;

  always @(posedge clk) begin
    scr <= ~rst_n ? {1'b1, 15'b0} : wr ? data_in[15:0] : scr;
  end

  assign data_out[15:0] = scr[15:0];
  assign sysrst = scr[0];

endmodule

`resetall
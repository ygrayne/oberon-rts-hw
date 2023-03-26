/**
  Generate two clocks: 40 and 80 MHz
  --
  For Xilinx Artix-7
  --
  2022 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module  CLOCKS1 (
	input wire clk_in,
	input wire rst,
	output wire outclk_0, // 40 MHz
	output wire outclk_1, // 80 MHz
	output wire locked
);

// clocks
wire clkfbout;
wire pllclk2, pllclk3, pllclk4, pllclk5, pllpwrdwn; // dummies to keep the synthesiser happy

localparam BasePeriod = 10;    // nano seconds, 100 MHz
localparam M = 12;             // multiplier, BaseClock * M must be in the VCO range, which is 800 - 1,600 MHz for the A7
localparam D0 = 30;            // divider for clock output 0 = clk
localparam D1 = 15;            // divider for clock output 1 = clk2x, used for the RAM

PLLE2_BASE # (
  .CLKIN1_PERIOD(BasePeriod),
  .CLKFBOUT_MULT(M), // 8 to 16
  .CLKOUT0_DIVIDE(D0),
  .CLKOUT1_DIVIDE(D1)
) pll_blk (
  .CLKFBOUT(clkfbout),
  .CLKOUT0(outclk_0),
  .CLKOUT1(outclk_1),
  .CLKOUT2(pllclk2), .CLKOUT3(pllclk3), .CLKOUT4(pllclk4), .CLKOUT5(pllclk5),
  .LOCKED(locked),
  .CLKFBIN(clkfbout),
  .CLKIN1(clk_in),
  .RST(rst),
  .PWRDWN(pllpwrdwn)
);

endmodule

`resetall

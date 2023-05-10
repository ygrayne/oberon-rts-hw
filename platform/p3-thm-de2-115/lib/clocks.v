/**
  Clock generator
  --
  Generate three clocks:
  * system clock
  * memory clock (2x system clock)
  * memory clock (2x system clock, phase shifted
  --
  Architecture: THM
  Board: DE2-115
  --
  Base: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module clocks (
  input clk_in,
  output clk_ok,
  output clk_2x_ps,
  output clk_2x,
  output clk
);

  wire [1:0] inclk = {1'b0, clk_in};
  wire [5:0] outclk;
  wire locked;

  altpll #(
    .intended_device_family("Cyclone IV E"),
    .lpm_type("altpll"),
    .pll_type("auto"),
    .operation_mode("normal"),
    // 50 MHz input
    .inclk0_input_frequency(20000),	// cycle time in picosec
    // 100 MHz output, phase shifted
    .clk3_multiply_by(16),
    .clk3_divide_by(8),
    .clk3_duty_cycle(50),		    // in %
    .clk3_phase_shift(7917),		// in picosec
    // 100 MHz output, in-phase
    .clk2_multiply_by(16),
    .clk2_divide_by(8),
    .clk2_duty_cycle(50),		// in %
    .clk2_phase_shift(0),		// in picosec
    // 50 MHz output, in-phase
    .clk0_multiply_by(8),
    .clk0_divide_by(8),
    .clk0_duty_cycle(50),		// in %
    .clk0_phase_shift(0)		// in picosec
  ) clk_pll (
    .inclk(inclk[1:0]),
    .clk(outclk[5:0]),
    .locked(locked)
  );

  assign clk_2x_ps = outclk[3];
  assign clk_2x = outclk[2];
  assign clk = outclk[0];
  assign clk_ok = locked;

endmodule

`resetall

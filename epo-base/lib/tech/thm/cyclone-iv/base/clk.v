/**
  Clock generator
  --
  Generate three clocks
  --
  Architecture: THM
  Technology dependency: Cyclone IV
  --
  Base: THM-Oberon
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module clk(
  input clk_in,
  output clk_ok,
  output clk_100_ps,
  output clk_100,
  output clk_50
);

  wire [1:0] inclk = { 1'b0, clk_in };
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
    .clk3_duty_cycle(50),		// in %
    .clk3_phase_shift(7917),		// in picosec
    // 100 MHz output, in-phase
    .clk2_multiply_by(16),
    .clk2_divide_by(8),
    .clk2_duty_cycle(50),		// in %
    .clk2_phase_shift(0),		// in picosec
//    // 75 MHz output, in-phase
//    .clk1_multiply_by(12),
//    .clk1_divide_by(8),
//    .clk1_duty_cycle(50),		// in %
//    .clk1_phase_shift(0),		// in picosec
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

  assign clk_100_ps = outclk[3];
  assign clk_100 = outclk[2];
  assign clk_50 = outclk[0];
  assign clk_ok = locked;

endmodule

`resetall

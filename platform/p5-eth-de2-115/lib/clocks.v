/**
  Clock generator
  --
  Generate three clocks: system, sram, sram phase shifted
  --
  Board: DE2-115
  Technology: Cyclone IV
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module clocks (
  input wire clk_in,
  output wire clk_sys,
  output wire clk_sram,
  output wire clk_sram_ps,
  output wire clk_ok
);

  wire [1:0] in_clk = {1'b0, clk_in};
  wire [5:0] out_clk;
  wire locked;

  altpll #(
    .intended_device_family("Cyclone IV E"),
    .lpm_type("altpll"),
    .pll_type("auto"),
    .operation_mode("normal"),
    // 50 MHz input
    .inclk0_input_frequency(20000),	// cycle time in picosec
    // // 100 MHz output, phase shifted
    // .clk3_multiply_by(16),
    // .clk3_divide_by(8),
    // .clk3_duty_cycle(50),		  // in %
    // .clk3_phase_shift(7917),		// in picosec
    // 50 MHz output, phase shifted
    .clk2_multiply_by(8),
    .clk2_divide_by(8),
    .clk2_duty_cycle(50),		    // in %
    .clk2_phase_shift(10000),		// in picosec
    // 50 MHz output, in phase
    .clk1_multiply_by(8),
    .clk1_divide_by(8),
    .clk1_duty_cycle(50),		    // in %
    .clk1_phase_shift(0),		    // in picosec
    // 25 MHz output, in phase
    .clk0_multiply_by(8),
    .clk0_divide_by(16),
    .clk0_duty_cycle(50),		    // in %
    .clk0_phase_shift(0)		    // in picosec
  ) clk_pll (
    .inclk(in_clk[1:0]),
    .clk(out_clk[5:0]),
    .locked(locked)
  );

  assign clk_sram_ps = out_clk[2];
  assign clk_sram = out_clk[1];
  assign clk_sys = out_clk[0];
  assign clk_ok = locked;

endmodule

`resetall

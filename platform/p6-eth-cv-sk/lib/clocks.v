/**
  Clock generator
  --
  Terasic Cyclone V GX Starter Kit.
  --
  (c) 2022 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module  clocks (
	input wire rst,
	input wire clk_in,
	output wire clk,
	output wire clk_2x_ps0,
	output wire clk_2x_ps1,
	output wire clk_ok
);

  wire [2:0] clk_out;
  wire locked;

	altera_pll #(
		.fractional_vco_multiplier("false"),
		.reference_clock_frequency("50.0 MHz"),
		.operation_mode("source synchronous"),
//		.operation_mode("normal"),
		.number_of_clocks(3),
		.output_clock_frequency0("15.000000 MHz"),
		.phase_shift0("0 ps"),
		.duty_cycle0(50),
		.output_clock_frequency1("30.000000 MHz"),
		.phase_shift1("10000 ps"),
		.duty_cycle1(80),
		.output_clock_frequency2("30.000000 MHz"),
		.phase_shift2("15000 ps"),
		.duty_cycle2(80),
		.output_clock_frequency3("0 MHz"),
		.phase_shift3("0 ps"),
		.duty_cycle3(50),
		.output_clock_frequency4("0 MHz"),
		.phase_shift4("0 ps"),
		.duty_cycle4(50),
		.output_clock_frequency5("0 MHz"),
		.phase_shift5("0 ps"),
		.duty_cycle5(50),
		.output_clock_frequency6("0 MHz"),
		.phase_shift6("0 ps"),
		.duty_cycle6(50),
		.output_clock_frequency7("0 MHz"),
		.phase_shift7("0 ps"),
		.duty_cycle7(50),
		.output_clock_frequency8("0 MHz"),
		.phase_shift8("0 ps"),
		.duty_cycle8(50),
		.output_clock_frequency9("0 MHz"),
		.phase_shift9("0 ps"),
		.duty_cycle9(50),
		.output_clock_frequency10("0 MHz"),
		.phase_shift10("0 ps"),
		.duty_cycle10(50),
		.output_clock_frequency11("0 MHz"),
		.phase_shift11("0 ps"),
		.duty_cycle11(50),
		.output_clock_frequency12("0 MHz"),
		.phase_shift12("0 ps"),
		.duty_cycle12(50),
		.output_clock_frequency13("0 MHz"),
		.phase_shift13("0 ps"),
		.duty_cycle13(50),
		.output_clock_frequency14("0 MHz"),
		.phase_shift14("0 ps"),
		.duty_cycle14(50),
		.output_clock_frequency15("0 MHz"),
		.phase_shift15("0 ps"),
		.duty_cycle15(50),
		.output_clock_frequency16("0 MHz"),
		.phase_shift16("0 ps"),
		.duty_cycle16(50),
		.output_clock_frequency17("0 MHz"),
		.phase_shift17("0 ps"),
		.duty_cycle17(50),
		.pll_type("General"),
		.pll_subtype("General")
  ) clk_pll (
		.rst(rst),
		.outclk(clk_out[2:0]),
		.locked(locked),
		.refclk(clk_in)
	);

  assign clk = clk_out[0];
	assign clk_2x_ps0 = clk_out[1];
	assign clk_2x_ps1 = clk_out[2];
  assign clk_ok = locked;

endmodule

`resetall

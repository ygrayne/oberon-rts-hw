/**
  Register file for RISC5 CPU
  --
  Cyclone V (NOT WORKING)
  --
  (c) 2022 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module Registers (
  input wire clk,
  input wire wr,
  input wire [3:0] rno0, rno1, rno2,
  input wire [31:0] din,
  output wire [31:0] dout0, dout1, dout2
);

  wire [3:0] rnow1 = wr ? rno0 : rno1;
  wire [3:0] rnow2 = wr ? rno0 : rno2;

  regs_base	regs_0 (
    .address_a ( rno0 ),
    .address_b ( rno0 ),
    .clock ( clk ),
    .data_a ( din ),
    .data_b (),
    .wren_a ( wr ),
    .wren_b (1'b0),
    .q_a (),
    .q_b ( dout0 )
	);

  regs_base	regs_1 (
    .address_a ( rno0 ),
    .address_b ( rno1 ),
    .clock ( clk ),
    .data_a ( din ),
    .data_b (),
    .wren_a ( wr ),
    .wren_b (1'b0),
    .q_a (),
    .q_b ( dout1 )
	);

  regs_base	regs_2 (
    .address_a ( rno0 ),
    .address_b ( rno2 ),
    .clock ( clk ),
    .data_a ( din ),
    .data_b (),
    .wren_a ( wr ),
    .wren_b (1'b0),
    .q_a (),
    .q_b ( dout2 )
	);


  // regs_base2 regs_0 (
  //   // in
  //   .clock(clk),
  //   .wren(wr),
  //   .address(rno0[3:0]),
  //   .data(din[31:0]),
  //   // out
  //   .q(dout0[31:0])
	// );

  // regs_base2 regs_1 (
  //   // in
  //   .clock(clk),
  //   .wren(wr),
  //   .address(rnow1[3:0]),
  //   .data(din[31:0]),
  //   // out
  //   .q(dout1[31:0])
	// );

  // regs_base2 regs_2 (
  //   // in
  //   .clock(clk),
  //   .wren(wr),
  //   .address(rnow2[3:0]),
  //   .data(din[31:0]),
  //   // out
  //   .q(dout2[31:0])
	// );

endmodule

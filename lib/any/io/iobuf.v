/**
  Simple IO buffer for GPIO.
  --
  Pin naming and tristate logic compatible with Xilinx IOBUF
  --
  (c) 2022 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module IOBUF (
  inout wire IO, // IO pin
  input wire I,  // GPIO pin out
  output wire O, // GPIO pin in
  input wire T   // tristate control
);

  // T = 1 => O follows IO => GPIO input
  // T = 0 => I drives IO (O still follows IO = I) => GPIO output
  
  assign IO = T ? 1'bz : I;
  assign O = IO;

endmodule

`resetall

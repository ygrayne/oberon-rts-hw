/**
  Program/command Start Tables
  --
  Architecture: ETH
  --
  The FPGA just holds the table number and the armed signal, in order
  to survice a restart. The actual commands are defined in software.
  --
  2021 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module start (
  input wire clk,
  input wire rst_n,
  input wire wr,
  input wire [15:0] data_in,
  output reg [8:0] data_out
);

  // split input data
  wire [7:0] ctrl = data_in[7:0];
  wire [7:0] data = data_in[15:8];

  // selected table
  reg [7:0] selected_table = 0;
  reg armed = 0;

  // control signals
  wire set_table = wr & ctrl[0];
  wire set_armed = wr & ctrl[1];
  wire set_disarmed = wr & ctrl[2];

  always @(*) begin
    data_out = {armed, selected_table};
  end

  always @ (posedge clk) begin
    selected_table <= set_table ? data : selected_table;
    armed <= ~rst_n ? 1'b1 : ~set_disarmed & (set_armed | armed);
  end
endmodule

`resetall

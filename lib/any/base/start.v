/**
  Program/command start tables
  --
  Architecture: ANY
  --
  The FPGA just holds the table number and the armed signal, in order
  to survice a restart. The actual commands are defined in software.
  --
  2021 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module start (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire [15:0] data_in,
  output wire [31:0] data_out,
  output wire ack
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  // split input data
  wire [7:0] ctrl = data_in[7:0];
  wire [7:0] data = data_in[15:8];

  // selected table
  reg [7:0] selected_table = 0;
  reg armed = 0;

  // control signals
  wire set_table = wr_data & ctrl[0];
  wire set_armed = wr_data & ctrl[1];
  wire set_disarmed = wr_data & ctrl[2];

  always @ (posedge clk) begin
    selected_table <= set_table ? data[7:0] : selected_table;
    armed <= rst ? 1'b1 : ~set_disarmed & (set_armed | armed);
  end

  assign data_out[31:0] =
    rd_data ? {16'b0, 7'b0, armed, selected_table[7:0]} :
    32'b0;

  assign ack = stb;

endmodule

`resetall

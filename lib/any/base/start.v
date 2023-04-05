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
  wire [7:0] ctrl = data_in[15:8];
  wire [7:0] din = data_in[7:0];

  // table selection, arming
  reg [5:0] table_no;     // table number
  reg mode;               // which table: reload or recover
  reg armed;              // table will be read upon restart and recover

  // control signals
  wire set_table = ctrl[0];
  wire set_armed = ctrl[1];
  wire set_mode = ctrl[2];

  initial begin
    table_no = 6'b0;
    mode = 1'b0;
  end

  always @ (posedge clk) begin
    if (rst) begin
      armed <= 1'b1;
    end
    else begin
      if (wr_data) begin
        if (set_table) table_no <= din[5:0];
        if (set_mode) mode <= din[6:6];
        if (set_armed) armed <= din[7:7];
      end
    end

  end

  assign data_out[31:0] =
    rd_data ? {16'b0, 8'b0, armed, mode, table_no[5:0]} :
    32'b0;

  assign ack = stb;

endmodule

`resetall

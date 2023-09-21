/**
  Inter-Integrated Circuit (I2C) Device
  --
  Architecture: ANY
  ---
  Basis: Embedded Project Oberon
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module i2ce (
  // internal
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire [1:0] addr,
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire ack,
  // external
  inout wire scl,
  inout wire sda
);

  wire rd_conset  = stb & ~we & (addr[1:0] == 2'b00);     // -16
  wire wr_conset  = stb &  we & (addr[1:0] == 2'b00);     // -16
  wire rd_data    = stb & ~we & (addr[1:0] == 2'b01);     // -12
  wire wr_data    = stb &  we & (addr[1:0] == 2'b01);     // -12
  wire rd_sclx    = stb & ~we & (addr[1:0] == 2'b10);     // -8
  wire wr_sclx    = stb &  we & (addr[1:0] == 2'b10);     // -8
  wire rd_status  = stb & ~we & (addr[1:0] == 2'b11);     // -4
  wire wr_conclr  = stb &  we & (addr[1:0] == 2'b11);     // -4

  reg [31:0] sclx;
  wire [7:0] data;
  wire [7:0] conset;
  wire [4:0] status;

  always @(posedge clk) begin
    if (rst) begin
      sclx[31:0] <= 32'b0;
    end
    else if (wr_sclx) begin
      sclx[31:0] <= data_in[31:0];
    end
  end

  I2C i2c_0 (
    // in
    .clk(clk),
    .rst(~rst),
    .sclh(sclx[31:16]),
    .scll(sclx[15:0]),
    .wr_conset(wr_conset),
    .wr_data(wr_data),
    .wr_conclr(wr_conclr),
    .wrdata(data_in[7:0]),
    // out
    .control(conset[7:0]),
    .status(status[4:0]),
    .data(data[7:0]),
    // external
    .SDA(sda),
    .SCL(scl)
  );

  assign data_out[31:0] =
    rd_data   ? {24'b0, data} :
    rd_conset ? {24'b0, conset} :
    rd_status ? {24'b0, status[4:0], 3'b0} :
    rd_sclx   ? sclx[31:0] :
    32'b0;

  assign ack = stb;

endmodule

`resetall
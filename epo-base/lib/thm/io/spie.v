/**
  Serial Peripheral Interface (SPI) Device
  --
  Architecture: THM
  --
  Base: THM-Oberon, Project Oberon
  ---
  Control register:
  [2:0] chip select
  [3:3] fast transmit (default: slow)
  [5:4] data width (default: 8 bits)
  [6:6] ms byte first (default: ls byte first)

  Data width:
  2'b00 => 8 bits
  2'b01 => 32 bits
  2'b10 => 16 bits

  Note: these control settings are compatible with Astrobe's design.
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module spie #(parameter clockfreq = 50_000_000) (
  // internal interface
  input clk,
  input rst,
  input stb,
  input we,
  input addr,
  input[31:0] data_in,
  output[31:0] data_out,
  output ack,
  // external interface
  output[2:0] cs_n,
  output sclk,
  output mosi,
  input miso
);

  wire rd_data = stb & ~we & ~addr;	// read received data
  wire wr_data = stb &  we & ~addr;	// write data to transmit
  wire rd_ctrl = stb & ~we &  addr;	// read status
  wire wr_ctrl = stb &  we &  addr;	// write control

  wire spi_rdy;
  wire [31:0] dataRx;
  reg [6:0] spi_ctrl = 0;

  always @(posedge clk) begin
    if (rst) begin
      spi_ctrl[6:0] <= 7'b0;
    end else begin
      if (wr_ctrl) begin
        spi_ctrl[6:0] <= data_in[6:0];
      end
    end
  end

  assign cs_n[2:0] = ~spi_ctrl[2:0];

  spie_rctr #(.clockfreq(clockfreq)) spie_rctr_0 (
    .clk(clk),
    .rst(rst),
    .fast(spi_ctrl[3]),
    .datawidth(spi_ctrl[5:4]),
    .msbytefirst(spi_ctrl[6]),
    .start(wr_data),
    .dataTx(data_in[31:0]),
    .dataRx(dataRx[31:0]),
    .rdy(spi_rdy),
    .sclk(sclk),
    .mosi(mosi),
    .miso(miso)
  );

  assign data_out[31:0] =
    rd_data ? dataRx[31:0] :
    rd_ctrl ? {28'h0, 3'b0, spi_rdy}:
    32'h0;

  assign ack = stb;

endmodule

`resetall

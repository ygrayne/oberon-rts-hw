/**
  Serial Peripheral Interface (SPI) Device
  --
  Architecture: ANY
  ---
  Control register:
  [2:0] chip select
  [3:3] fast transmit (default: slow)
  [5:4] data width (default: 8 bits)
  [6:6] most significant byte first (default: least significant byte first)
  [11:7] currently unused, but reserved
  [13:12] SPI mode (default: 'default_mode')

  Data width:
  2'b00 => 8 bits
  2'b01 => 32 bits
  2'b10 => 16 bits

  Notes: 
  * these control settings are compatible with Astrobe's design
  * see 'spie_rxtx' about the parameters
  --
  (c) 2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module spie #(
  parameter
    fast_div = 5,
    slow_div = 125,
    default_mode = 2'b0
  )(
  // internal
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire ack,
  // external
  output wire [2:0] cs_n,
  output wire sclk,
  output wire mosi,
  input wire miso
);

  wire rd_data = stb & ~we & ~addr;	// read received data
  wire wr_data = stb &  we & ~addr;	// write data to transmit
  wire rd_ctrl = stb & ~we &  addr;	// read status
  wire wr_ctrl = stb &  we &  addr;	// write control

  wire spi_rdy;
  wire [31:0] data_rx;
  reg [13:0] spi_ctrl = 0;

  always @(posedge clk) begin
    if (rst) begin
      spi_ctrl[13:0] <= {default_mode, 12'b0};
    end
    else begin
      if (wr_ctrl) begin
        spi_ctrl[13:0] <= data_in[13:0];
      end
    end
  end

  spie_rxtx #(
    .fast_div(fast_div),
    .slow_div(slow_div)
    ) spie_rxtx_0 (
    // in
    .clk(clk),
    .rst(rst),
    .fast(spi_ctrl[3]),
    .data_width(spi_ctrl[5:4]),
    .msbyte_first(spi_ctrl[6]),
    .cpol(spi_ctrl[12]),
    .cpha(spi_ctrl[13]),
    .start(wr_data),
    .data_tx(data_in[31:0]),
    // out
    .data_rx(data_rx[31:0]),
    .rdy(spi_rdy),
    // external
    .sclk(sclk),
    .mosi(mosi),
    .miso(miso)
  );
  
  assign cs_n[2:0] = ~spi_ctrl[2:0];
  assign data_out[31:0] =
    rd_data ? data_rx[31:0] :
    rd_ctrl ? {22'h0, spi_ctrl[13:12], 7'b0, spi_rdy} :
    32'h0;
  assign ack = stb;

endmodule

`resetall

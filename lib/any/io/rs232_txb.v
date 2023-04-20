/**
  Buffered RS232 Transmitter
  --
  Architecture: ANY
  --
  Original RS232 transmitter design by NW 4.5.09 / 15.8.10 / 15.11.10
  --
  2020 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module rs232_txb #(parameter clock_freq = 50000000, num_slots = 63) (
  input wire clk,
  input wire rst,
  input wire fsel,
  input wire wr,
  input wire [7:0] data_in,
  output wire empty,
  output wire full,
  output wire txd
);

  reg tx_rdy_0;
  wire rdy;
  wire [7:0] fifo_out;
  wire tx_rdy = ~empty & rdy;
  wire start_tx = tx_rdy & ~tx_rdy_0;
  wire fifo_rd = start_tx;

  always @(posedge clk) begin
    tx_rdy_0 <= rst ? 1'b1 : tx_rdy;
  end

  // unbuffered RS232 transmitter
  rs232_tx #(.clock_freq(clock_freq)) rs232_tx_0 (
    .clk(clk),
    .rst_n(~rst),
    .fsel(fsel),
    .start(start_tx),
    .rdy(rdy),
    .data_in(fifo_out),
    .txd(txd)
  );

  // buffer
  fifo #(.num_slots(num_slots)) fifo_0 (
    .clk(clk),
    .rst(rst),
    .wr(wr),
    .rd(fifo_rd),
    .data_in(data_in),
    .data_out(fifo_out),
    .empty(empty),
    .full(full)
  );

endmodule

`resetall

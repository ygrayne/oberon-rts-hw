/**
  Buffered RS232 Receiver
  --
  Architecture: ANY
  --
  Original RS232 receiver design by NW 4.5.09 / 15.8.10 / 15.11.10 / 13.8.15
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module rs232_rxb #(parameter clock_freq = 50000000, num_slots = 63) (
  input wire clk,
  input wire rst,
  input wire fsel,
  input wire rd,
  input wire rxd,
  output wire [7:0] data_out,
  output wire empty,
  output wire full
);

  reg rx_rdy_0;
  wire rdy;
  wire [7:0] fifo_in;
  wire rx_rdy = ~full & rdy;
  wire rx_done = rx_rdy & ~rx_rdy_0;
  wire fifo_wr = rx_done;

  always @(posedge clk) begin
    rx_rdy_0 <= rst ? 1'b1 : rx_rdy;
  end

  // unbuffered RS232 receiver
  rs232_rx #(.clock_freq(clock_freq)) rs232_rx_0 (
    .clk(clk),
    .rst_n(~rst),
    .fsel(fsel),
    .data_out(fifo_in),
    .done(rx_done),
    .rdy(rdy),
    .rxd(rxd)
  );

  // buffer
  fifo #(.num_slots(num_slots), .data_width(8)) fifo_0 (
    .clk(clk),
    .rst(rst),
    .wr(fifo_wr),
    .rd(rd),
    .data_in(fifo_in),
    .data_out(data_out),
    .empty(empty),
    .full(full)
  );

endmodule

`resetall

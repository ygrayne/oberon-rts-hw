/**
  Buffered RS232 Receiver
  --
  Original RS232 receiver design by NW 4.5.09 / 15.8.10 / 15.11.10 / 13.8.15
  --
  2020 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module RS232RB #(parameter ClockFreq = 50000000, BufNumSlots = 63) (
  input wire clk,
  input wire rst_n,
  input wire fsel,
  input wire rd,
  input wire rxd,
  output wire [7:0] data_out,
  output wire empty,
  output wire full,
  output wire [$clog2(BufNumSlots):0] count
);

  reg rx_rdy_0;
  wire rdy;
  wire [7:0] fifo_in;
  wire rx_rdy = ~full & rdy;
  wire rx_done = rx_rdy & ~rx_rdy_0;
  wire fifo_wr = rx_done;

  always @(posedge clk) begin
    rx_rdy_0 <= ~rst_n ? 1'b1 : rx_rdy;
  end

  // unbuffered RS232 receiver
  RS232R #(.ClockFreq(ClockFreq)) rs232r (
    .clk(clk),
    .rst_n(rst_n),
    .fsel(fsel),
    .data_out(fifo_in),
    .done(rx_done),
    .rdy(rdy),
    .rxd(rxd)
  );

  // buffer
  FIFO1 #(.Slots(BufNumSlots), .Width(8)) fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr(fifo_wr),
    .rd(rd),
    .data_in(fifo_in),
    .data_out(data_out),
    .empty(empty),
    .full(full),
    .count(count)
  );

endmodule

`resetall

/**
  Buffered RS232 Transmitter
  --
  Original RS232 transmitter design by NW 4.5.09 / 15.8.10 / 15.11.10
  --
  2020 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module RS232TB #(parameter ClockFreq = 50000000, BufNumSlots = 63) (
  input wire clk,
  input wire rst_n,
  input wire fsel,
  input wire wr,
  input wire [7:0] data_in,
  output wire empty,
  output wire full,
  output wire [$clog2(BufNumSlots):0] count,
  output wire txd
);

  reg tx_rdy_0;
  wire rdy;
  wire [7:0] fifo_out;
  wire tx_rdy = ~empty & rdy;
  wire start_tx = tx_rdy & ~tx_rdy_0;
  wire fifo_rd = start_tx;

  always @(posedge clk) begin
    tx_rdy_0 <= ~rst_n ? 1'b1 : tx_rdy;
  end

  // unbuffered RS232 transmitter
  RS232T #(.ClockFreq(ClockFreq)) rs232t (
    .clk(clk), 
    .rst_n(rst_n),
    .fsel(fsel), 
    .start(start_tx), 
    .rdy(rdy), 
    .data_in(fifo_out),
    .txd(txd)
  );

  // buffer
  FIFO1 #(.Slots(BufNumSlots)) fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr(wr),
    .rd(fifo_rd),
    .data_in(data_in),
    .data_out(fifo_out),
    .empty(empty),
    .full(full),
    .count(count)
  );

endmodule

`resetall

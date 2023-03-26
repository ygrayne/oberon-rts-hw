/**
  Simple FIFO.
  --
  Parameters:
  * Width: data width in bits
  * Slots: number of fifo slots
  --
  2020 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module FIFO1 #(parameter Width = 8, Slots = 8) (
  input wire clk,
  input wire rst_n,
  input wire rd,
  input wire wr,
  input wire [Width-1:0] data_in,
  output wire empty, full,
  output reg [$clog2(Slots):0] count,   // number of items in fifo
  output wire [Width-1:0] data_out
);

  localparam ptr_width = $clog2(Slots);
  localparam count_width = $clog2(Slots) + 1;
  
  localparam ptr_zero = {(ptr_width){1'b0}};
  localparam count_zero = {(count_width){1'b0}};
  
  localparam slots = Slots[$clog2(Slots):0];

  reg [Width-1:0] mem[Slots-1:0];
  reg [$clog2(Slots)-1:0] rd_ptr, wr_ptr;

  assign empty = (count == count_zero);
  assign full = (count == slots);
  assign data_out = mem[rd_ptr];

  always @(posedge clk) begin
    // write fifo slots
    mem[wr_ptr] <= ((wr & ~full) | (wr & rd)) ? data_in : mem[wr_ptr];
    // pointers
    wr_ptr <= ~rst_n ? ptr_zero : ((wr & ~full) | (wr & rd)) ? wr_ptr + 1'b1 : wr_ptr;
    rd_ptr <= ~rst_n ? ptr_zero : ((rd & ~empty) | (rd & wr)) ? rd_ptr + 1'b1 : rd_ptr;
    // counter
    count <= ~rst_n ? count_zero : (
      (~wr & rd) ? (empty ? count_zero : count - 1'b1) :
      (wr & ~rd) ? (full ? slots : count + 1'b1) :
      count);
  end
endmodule

`resetall

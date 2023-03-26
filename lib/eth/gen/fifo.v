/**
  Simple FIFO.
  --
  Parameters:
  * width: data width in bits (max 32 bits)
  * num_slots: number of fifo slots (max 32 slots)
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module fifo #(parameter data_width = 8, num_slots = 8) (
  input wire clk,
  input wire rst_n,
  input wire rd,
  input wire wr,
  input wire [data_width-1:0] data_in,
  output wire empty, full,
  output wire [data_width-1:0] data_out
);

  // localparam ptr_width = $clog2(Slots);
  // localparam count_width = $clog2(Slots) + 1;

  // localparam ptr_zero = {(ptr_width){1'b0}};
  // localparam count_zero = {(count_width){1'b0}};

  // localparam slots = Slots[$clog2(Slots):0];


  reg [data_width-1:0] mem[num_slots-1:0];
  reg [14:0] rd_ptr, wr_ptr;        // num_slots can be max 0800H (32k)
  reg [15:0] count;

  // output reg [$clog2(Slots):0] count,   // number of items in fifo
  // reg [$clog2(Slots)-1:0] rd_ptr, wr_ptr;

  assign empty = (count == 16'b0);
  assign full = (count == num_slots[16:0]);
  assign data_out = mem[rd_ptr];

  always @(posedge clk) begin
    // write fifo slots
    mem[wr_ptr] <= ((wr & ~full) | (wr & rd)) ? data_in : mem[wr_ptr];
    // pointers
    wr_ptr <= ~rst_n ? 15'b0 : ((wr & ~full) | (wr & rd)) ? wr_ptr + 15'b1 : wr_ptr;
    rd_ptr <= ~rst_n ? 15'b0 : ((rd & ~empty) | (rd & wr)) ? rd_ptr + 15'b1 : rd_ptr;
    // counter
    count <= ~rst_n ? 16'b0 : (
      (~wr & rd) ? (empty ? 16'b0 : count - 16'b1) :
      (wr & ~rd) ? (full ? num_slots[15:0] : count + 16'b1) :
      count);
  end
endmodule

`resetall

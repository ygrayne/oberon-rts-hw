/**
  Log buffer
  --
  Stores 'num_entries' of log entries, each with 'entry_slots' 8 bit slots.
  The current software will attempt to store and retrieve 64 'entry_slots',
  hence each entry memory needs at least 64 bytes.
  --
  Architecture: ANY
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module logbuf #(num_entries = 32, entry_slots = 64) (
  input wire clk,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire ack
);

  wire rd_data = stb & ~we & ~addr;	  // read log data
  wire wr_data = stb &  we & ~addr;	  // write log data
  wire rd_index = stb & ~we & addr;	  // read indices
  wire wr_index = stb &  we & addr;	  // write indices

  reg [15:0] put_ix = 0;  // log write index
  reg [15:0] get_ix = 0;  // log read index

  always @(posedge clk) begin
    get_ix <= wr_index ? data_in[15:0] : get_ix;
    put_ix <= wr_index ? data_in[31:16] : put_ix;
  end

  wire init_entry = wr_index | rd_index;      // reset mem pointer in entry buffer to zero
  wire [num_entries-1:0] wr_entry;            // mux for write signal to entry buffer
  wire [num_entries-1:0] rd_entry;            // mux for read signal from entry buffer
  wire [7:0] dout_demux [0:num_entries-1];    // data out demux from entry buffers

  genvar i;
  generate
    for (i = 0; i < num_entries; i = i+1) begin: entries
      logentry #(.num_slots(entry_slots)) entry (
        .clk(clk),
        .wr(wr_entry[i]),
        .rd(rd_entry[i]),
        .init(init_entry),
        .din(data_in[7:0]),
        .dout(dout_demux[i])
      );

      assign wr_entry[i] = wr_data & (put_ix == i);
      assign rd_entry[i] = rd_data & (get_ix == i);
    end
  endgenerate

  assign data_out[31:0] =
    rd_data ? {24'b0, dout_demux[get_ix]} :
    rd_index ? {put_ix, get_ix} :
    32'b0;

  assign ack = stb;

endmodule


module logentry #(num_slots = 64) (
  input wire clk, init, rd, wr,
  input wire [7:0] din,
  output wire [7:0] dout
);

  reg [7:0] mem [0:num_slots-1];
  reg [$clog2(num_slots)-1:0] ptr = 0;

  assign dout = mem[ptr];

  always @(posedge clk) begin
    mem[ptr] <= wr ? din[7:0] : mem[ptr];
    ptr <= init ? 1'b0 : (wr | rd) ? ptr + 1'b1 : ptr;
  end

endmodule

`resetall

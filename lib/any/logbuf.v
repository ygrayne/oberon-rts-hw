/**
  Log buffer
  --
  Stores 'num_entries' of log entries, each with 64 8 bit slots,
  as required by the software driver.
  --
  Architecture: ANY
  Board: any
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module logbuf #(num_entries = 32) (
  input wire clk,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [15:0] data_in,
  output wire [31:0] data_out,
  output wire ack
);

  wire rd_data = stb & ~we & ~addr;	  // read log data
  wire wr_data = stb &  we & ~addr;	  // write log data
  wire rd_index = stb & ~we & addr;	  // read indices
  wire wr_index = stb &  we & addr;	  // write indices

  reg [7:0] put_ix = 0;  // log write index
  reg [7:0] get_ix = 0;  // log read index

  always @(posedge clk) begin
    get_ix <= wr_index ? data_in[7:0] : get_ix;
    put_ix <= wr_index ? data_in[15:8] : put_ix;
  end

  wire [7:0] dout_mux [num_entries-1:0];    // data out mux from entry buffers
  wire [num_entries-1:0] we_entry;
  reg [7:0] rd_ptr = 0;
  reg [7:0] wr_ptr = 0;

  always @(posedge clk) begin
    rd_ptr <= (wr_index | rd_index) ? 8'b0 : rd_data ? rd_ptr + 1'b1 : rd_ptr;
    wr_ptr <= (wr_index | rd_index) ? 8'b0 : wr_data ? wr_ptr + 1'b1 : wr_ptr;
  end

  genvar i;
  generate
    for (i = 0; i < num_entries; i = i+1) begin: entries
      logentry entry (
        .clk(clk),
        .we(we_entry[i]),
        .rd_ptr(rd_ptr[5:0]),
        .wr_ptr(wr_ptr[5:0]),
        .din(data_in[7:0]),
        .dout(dout_mux[i])
      );
      assign we_entry[i] = wr_data & (put_ix == i);
    end
  endgenerate

  assign data_out[31:0] =
    rd_data ? {24'b0, dout_mux[get_ix]} :
    rd_index ? {wr_ptr, rd_ptr, put_ix, get_ix} :
    32'b0;

  assign ack = stb;

endmodule


module logentry (
  input wire clk,
  input wire we,
  input wire [5:0] rd_ptr,
  input wire [5:0] wr_ptr,
  input wire [7:0] din,
  output reg [7:0] dout
);

  reg [7:0] mem [63:0];

  always @(posedge clk) begin
    if (we) begin
      mem[wr_ptr] <= din[7:0];
    end
    dout <= mem[rd_ptr];
  end

endmodule

`resetall

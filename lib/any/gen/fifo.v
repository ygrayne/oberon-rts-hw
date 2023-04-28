/**
  Simple FIFO.
  --
  Architecture: ANY
  --
  Parameters:
  * width: data width in bits (max 32 bits)
  * num_slots: number of fifo slots (max 256 slots)
  --
  (c) 2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module fifo #(parameter data_width = 8, num_slots = 8) (
  input wire clk,
  input wire rst,
  input wire rd,
  input wire wr,
  input wire [data_width-1:0] data_in,
  output wire empty, full,
  output wire [data_width-1:0] data_out
);

  reg [7:0] rd_ptr;
  reg [7:0] wr_ptr;
  reg [8:0] count;
  wire we;

  assign empty = (count == 8'b0) ? 1'b1 : 1'b0;
  assign full = (count == num_slots[8:0]) ? 1'b1 : 1'b0;

  always @(posedge clk) begin
    if (rst) begin
      rd_ptr[7:0] <= 8'b0;
      wr_ptr[7:0] <= 8'b0;
      count[8:0] <= 9'b0;
    end
		else begin
      if (empty) begin
        if (wr & rd) begin
          wr_ptr[7:0] <= wr_ptr[7:0] + 8'b1;
          rd_ptr[7:0] <= rd_ptr[7:0] + 8'b1;
        end
        else begin
          if (wr) begin
            wr_ptr[7:0] <= wr_ptr[7:0] + 8'b1;
            count[8:0] <= count[8:0] + 9'b1;
          end
        end
      end
      else begin
        if (full) begin
          if (wr & rd) begin
            wr_ptr[7:0] <= wr_ptr[7:0] + 8'b1;
            rd_ptr[7:0] <= rd_ptr[7:0] + 8'b1;
          end
          else begin
            if (rd) begin
              rd_ptr[7:0] <= rd_ptr[7:0] + 8'b1;
              count[8:0] <= count[8:0] - 9'b1;
            end
          end
        end
        else begin // in between
          if (wr & rd) begin
            wr_ptr[7:0] <= wr_ptr[7:0] + 8'b1;
            rd_ptr[7:0] <= rd_ptr[7:0] + 8'b1;
          end
          else begin
            if (wr) begin
              wr_ptr[7:0] <= wr_ptr[7:0] + 8'b1;
              count[8:0] <= count[8:0] + 9'b1;
            end
            else begin
              if (rd) begin
                rd_ptr[7:0] <= rd_ptr[7:0] + 8'b1;
                count[8:0] <= count[8:0] - 9'b1;
              end
            end
          end
        end
      end
    end
  end

  assign we = ((wr && ~full) | (wr && rd)) ? 1'b1 : 1'b0;

  fifo_mem #(.data_width(data_width), .num_slots(num_slots)) stack_mem_0 (
    .clk(clk),
    .we(we),
    .rd_ptr(rd_ptr),
    .wr_ptr(wr_ptr),
    .din(data_in[data_width-1:0]),
    .dout(data_out[data_width-1:0])
  );

endmodule


module fifo_mem #(parameter data_width = 8, num_slots = 8) (
  input wire clk,
  input wire we,
  input wire [7:0] rd_ptr,
  input wire [7:0] wr_ptr,
  input wire [data_width-1:0] din,
  output reg [data_width-1:0] dout
);

  reg [data_width-1:0] mem [num_slots-1:0];

  // read will return new data from write
  always @(posedge clk) begin
    if (we) begin
      mem[wr_ptr] = din[data_width-1:0];
    end
    dout[data_width-1:0] = mem[rd_ptr];
  end

endmodule

`resetall
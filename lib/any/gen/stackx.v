/**
  Extended Stack, with reading capability without popping.
  --
  Parameters:
  * data_width: data width in bits
  * num_slots: number of stack slots
  --
  The stack write pointer 'wr_ptr' points to the next unused slot, ie. the next
  'push' will store its value there. If the stack is full, 'wr_ptr' will
  point to a non-existing stack slot, which signals the full condition, and no
  more values can be pushed. 'pop', well, pops a value from the stack, unless
  the stack is frozen.

  To read the stack data without popping, 'freeze' it, and use 'pop' until 'more'
  goes low to indicate the end of the data. 'unfreeze' gets the stack back to
  the state before the freeze. 'push' is not recognised in the frozen state.

  The stack fills/grows from bottom to top, ie. from 'wr_ptr' = 0 "upwards".
  --
  (c) 2021 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module stackx  #(parameter data_width = 8, num_slots = 8) (
  input wire clk,
  input wire rst,
  input wire push,
  input wire pop,
  input wire read,
	input wire freeze,
  input wire unfreeze,
  input wire [data_width-1:0] data_in,
  output wire empty,
  output wire full,
  output reg frozen,
  output wire [7:0] count,
  output reg [7:0] max_count,
  output wire [data_width-1:0] data_out
);

  reg [7:0] rd_ptr;       // read pointer/address
  reg [7:0] wr_ptr;       // write pointer/address
	reg [7:0] rd_ptr_f;     // frozen rd_ptr
  wire we;
  
	assign empty = (wr_ptr[7:0] == 8'b0) ? 1'b1 : 1'b0;
	assign full = (wr_ptr[7:0] == num_slots) ? 1'b1 : 1'b0;
  assign count = wr_ptr;

  always @(posedge clk) begin
    if (rst) begin
      rd_ptr <= 8'b0;
      wr_ptr <= 8'b0;
			rd_ptr_f <= 8'b0;
      frozen <= 1'b0;
      max_count <= 8'b0;
    end
		else begin
      if (max_count < wr_ptr) max_count[7:0] <= wr_ptr[7:0];
      if (frozen) begin
        if (unfreeze) begin
          rd_ptr[7:0] <= rd_ptr_f[7:0];
          frozen <= 1'b0;
        end
        else begin
          if (read) begin
            if (rd_ptr > 8'b0) begin
              rd_ptr <= rd_ptr - 8'b1;
            end
          end
        end
      end
      else begin // unfrozen
        if (freeze) begin
          rd_ptr_f[7:0] <= rd_ptr[7:0];
          frozen <= 1'b1;
        end
        else begin
          if (wr_ptr == 0) begin // empty
              if (push) begin
                wr_ptr <= wr_ptr + 8'b1; // keep rd_ptr at 0
              end
            end
          else begin
            if (wr_ptr == num_slots) begin // full
              if (pop) begin
                wr_ptr <= wr_ptr - 8'b1;
                rd_ptr <= rd_ptr - 8'b1;
              end
            end
            else begin	// in between
              if (push) begin
                wr_ptr <= wr_ptr + 8'b1;
                rd_ptr <= rd_ptr + 8'b1;
              end
              else begin
                if (pop) begin
                  wr_ptr <= wr_ptr - 8'b1;  // no guard for wr_ptr, is caught by empty state above
                  if (rd_ptr > 8'b0) rd_ptr <= rd_ptr - 8'b1;
                end
              end
            end
          end
        end
      end
    end
  end

  assign we = (push == 1'b1) && (wr_ptr != num_slots) ? 1'b1 : 1'b0;

  stack_mem #(.data_width(data_width), .num_slots(num_slots)) stack_mem_0 (
    .clk(clk),
    .we(we),
    .rd_ptr(rd_ptr),
    .wr_ptr(wr_ptr),
    .din(data_in[data_width-1:0]),
    .dout(data_out[data_width-1:0])
  );

endmodule


module stack_mem #(parameter data_width = 8, num_slots = 8) (
  input wire clk,
  input wire we,
  input wire [7:0] rd_ptr,
  input wire [7:0] wr_ptr,
  input wire [data_width-1:0] din,
  output reg [data_width-1:0] dout
);

  reg [data_width-1:0] mem [num_slots-1:0];

  always @(posedge clk) begin
    if (we) begin
      mem[wr_ptr] <= din[data_width-1:0];
    end
    dout[data_width-1:0] <= mem[rd_ptr];
  end

endmodule

`resetall

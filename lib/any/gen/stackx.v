/**
  Extended Stack, with reading capability without popping.
  --
  Parameters:
  * data_width: data width in bits
  * num_slots: number of stack slots (see also the note below)
  --
  The stack fills/grows from bottom to top, ie. "upwards".

  'push' stores the data on 'data_in', 'pop' retrieves the data in reverse
  order via 'data_out'. The signals 'empty', 'full', and 'ovfl' indicate the stack
  state.

  Popping from the enpty stack will give the "last" bottom element, with
  'empty' signalling that condition.

  Pushing on a full stack will not store anything, obviously, but the stack
  ensures enforces strict 'one push for each pop' mechanics to ensure the popped
  data corresponds with the pushes. So pushing on a full stack, when no data is stored,
  must be followed by an equal number of pops, before data is actually removed
  from the top of the stack. Popping an overflowed stack will (repeatedly) return
  the topmost data item, but not actually pop the stack, ie. move the read
  pointer. 'ovfl' signals that condition.
  --
  The stack write pointer 'wr_ptr' points to the next unused slot, ie. the next
  'push' will store its value there. If the stack is full, 'wr_ptr' will
  point to a non-existing stack slot, which signals the full or overflow condition,
  respectively, and no more values will be stored, but 'wr_ptr' will still be
  increased to "count" the pushes on the overflowed stack.

  To read the stack data without popping, 'freeze' it, and use 'read'.
  'unfreeze' gets the stack back to the state before the freeze.
  'push' and 'pop' are not recognised in the frozen state. 'read' always returns
  the actual contents of the stack, independent of the overflow state. Reading
  "below" the lower bound of the stack will return the last element, just like 'pop'.
  --
  Note: we're refraining from making the code hard to read using $clog2 etc. everywhere.
  Just don't instantiate more than 128 stack slots :) and don't overflow the stack by
  more than 128 items. Otherwise increase the width of the pointers and counters.
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
  output wire ovfl,
  output reg frozen,
  output reg [7:0] count,
  output reg [7:0] max_count,
  output wire [data_width-1:0] data_out
);

  reg [7:0] rd_ptr;      // read pointer/address
  reg [7:0] wr_ptr;      // write pointer/address
	reg [7:0] rd_ptr_f;    // frozen rd_ptr
  wire we;               // write enable for stack memory

	assign empty = (wr_ptr[7:0] == 8'b0) ? 1'b1 : 1'b0;
	assign full = (wr_ptr[7:0] == num_slots) ? 1'b1 : 1'b0;
  assign ovfl = (wr_ptr[7:0] > num_slots) ? 1'b1 : 1'b0;

  always @(posedge clk) begin
    if (rst) begin
      rd_ptr <= 8'b0;
      wr_ptr <= 8'b0;
			rd_ptr_f <= 8'b0;
      frozen <= 1'b0;
      max_count <= 8'b0;
      count <= 8'b0;
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
                wr_ptr <= wr_ptr + 8'b1; // keep rd_ptr at 0 here
                count <= count + 8'b1;
              end
            end
          else begin
            if (wr_ptr > num_slots) begin // overflow
              if (push) begin
                wr_ptr <= wr_ptr + 8'b1;
              end
              else begin
                if (pop) begin
                  wr_ptr <= wr_ptr - 8'b1;
                end
              end
            end
            else begin
              if (wr_ptr == num_slots) begin // full
                if (push) begin
                  wr_ptr <= wr_ptr + 8'b1;
                end
                else begin
                  if (pop) begin
                    wr_ptr <= wr_ptr - 8'b1;
                    rd_ptr <= rd_ptr - 8'b1;
                    count <= count - 8'b1;
                  end
                end
              end
              else begin	// in between
                if (push) begin
                  wr_ptr <= wr_ptr + 8'b1;
                  rd_ptr <= rd_ptr + 8'b1;
                  count <= count + 8'b1;
                end
                else begin
                  if (pop) begin
                    wr_ptr <= wr_ptr - 8'b1;  // no guard required for wr_ptr
                    if (rd_ptr > 8'b0) rd_ptr <= rd_ptr - 8'b1;
                    count <= count - 8'b1;
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  assign we = push && (wr_ptr < num_slots) ? 1'b1 : 1'b0;

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

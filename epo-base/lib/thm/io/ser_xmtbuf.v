//
// ser_xmtbuf.v -- serial line transmitter buffer
//


`timescale 1ns / 1ps
`default_nettype none


module xmtbuf(clk, rst, bit_len, write, ready, data_in, serial_out);
    input clk;
    input rst;
    input [15:0] bit_len;
    input write;
    output reg ready;
    input [7:0] data_in;
    output serial_out;

  reg [1:0] state;
  reg [7:0] data_hold;
  reg load;
  wire empty;

  xmt xmt_0(clk, rst, bit_len, load, empty, data_hold, serial_out);

  always @(posedge clk) begin
    if (rst) begin
      state <= 2'b00;
      ready <= 1'b1;
      load <= 1'b0;
    end else begin
      case (state)
        2'b00:
          begin
            if (write) begin
              state <= 2'b01;
              data_hold <= data_in;
              ready <= 1'b0;
              load <= 1'b1;
            end
          end
        2'b01:
          begin
            state <= 2'b10;
            ready <= 1'b1;
            load <= 1'b0;
          end
        2'b10:
          begin
            if (empty & ~write) begin
              state <= 2'b00;
              ready <= 1'b1;
              load <= 1'b0;
            end else
            if (empty & write) begin
              state <= 2'b01;
              data_hold <= data_in;
              ready <= 1'b0;
              load <= 1'b1;
            end else
            if (~empty & write) begin
              state <= 2'b11;
              data_hold <= data_in;
              ready <= 1'b0;
              load <= 1'b0;
            end
          end
        2'b11:
          begin
            if (empty) begin
              state <= 2'b01;
              ready <= 1'b0;
              load <= 1'b1;
            end
          end
      endcase
    end
  end

endmodule

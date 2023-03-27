/**
  Millisecond timer
  --
  Architecture: THM
  --
  Based on THM tmr.v
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
  * add millisecond ticker output
  * add clock frequency parameter
**/

`timescale 1ns / 1ps
`default_nettype none

module tmr #(parameter clock_freq = 50_000_000) (
  input clk,
  input rst,
  input stb,
  output [31:0] data_out,
  output ms,
  output ack
);

  localparam clock_divider = clock_freq / 1000;

  wire millisec;
  reg [15:0] cnt0;
  reg [31:0] cnt1;

  assign millisec = (cnt0[15:0] == clock_divider[15:0] - 1'b1);

  always @(posedge clk) begin
    if (rst) begin
      cnt0[15:0] <= 16'd0;
    end else begin
      if (millisec) begin
        cnt0[15:0] <= 16'd0;
      end else begin
        cnt0[15:0] <= cnt0[15:0] + 16'd1;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      cnt1[31:0] <= 32'd0;
    end else begin
      if (millisec) begin
        cnt1[31:0] <= cnt1[31:0] + 32'd1;
      end
    end
  end

  assign data_out[31:0] = cnt1[31:0];
  assign ms = millisec;

  assign ack = stb;

endmodule

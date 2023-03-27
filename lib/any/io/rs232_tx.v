/**
  RS232 transmitter
  115,200 and 19,200 baud, 8 bits
  --
  Architecture: ANY
  --
  Base: Project Oberon, NW 4.5.09 / 15.8.10 / 15.11.10
  --
  Changes by Gray, gray@grayraven.org
  2020-05: Paramterised clock frequency
**/

`timescale 1ns / 1ps
`default_nettype none

module rs232_tx #(parameter clock_freq = 50000000) (
  input wire clk,
  input wire rst_n,
  input wire start,  // request to accept and send a byte
	input wire fsel,   // frequency selection, 0 = fast = default
  input wire [7:0] data_in,
  output wire rdy,
  output wire txd
);

  localparam limitFast = clock_freq / 115200;
  localparam limitSlow = clock_freq / 19200;

  wire endtick, endbit;
  wire [11:0] limit;
  reg run;
  reg [11:0] tick;
  reg [3:0] bitcnt;
  reg [8:0] shreg;

  assign limit = fsel ? limitSlow[11:0] : limitFast[11:0];
  assign endtick = tick == limit;
  assign endbit = (bitcnt == 4'd9);
  assign rdy = ~run;
  assign txd = shreg[0];

  always @ (posedge clk) begin
    run <= (~rst_n | endtick & endbit) ? 1'b0 : start ? 1'b1 : run;
    tick <= (run & ~endtick) ? tick + 1'b1 : 1'b0;
    bitcnt <= (endtick & ~endbit) ? bitcnt + 1'b1 :
      (endtick & endbit) ? 4'b0 : bitcnt;
    shreg <= (~rst_n) ? 1'b1 : start ? {data_in, 1'b0} :
      endtick ? {1'b1, shreg[8:1]} : shreg;
  end
endmodule

`resetall

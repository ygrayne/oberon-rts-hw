/**
  Simple watchdog
  --
  * 'ticker' counts from zero to 'timeoutval', sets 'trig' when ticker > timoutval.
  * 'ticker' is driven by 'tick', usually a one-millisecond signal.
  * If 'timeoutval' = 0, counting is stopped, ie. the watchdog is disabled.
  * When 'timeoutval' is written, the ticker counter is reset.
  --
  Architecture: ANY
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module watchdog (
  input wire clk,
  input wire rst,
  input wire tick,
  input wire stb,
  input wire we,
  input wire [15:0] data_in,
  output wire [31:0] data_out,
  output wire trig,
  output wire ack
);

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  reg trigger = 0;
  reg [15:0] timeoutval = 0;
  reg [15:0] ticker = 0;
  wire stop = (timeoutval == 0);

  always @ (posedge clk) begin
    timeoutval <= rst ? 16'b0 : wr_data ? data_in[15:0] : timeoutval;
    ticker <= rst ? 16'b0 : stop ? 16'b0 : wr_data ? 16'b0 : ticker + tick;
    trigger <= rst ? 1'b0 : ~wr_data & (ticker > timeoutval);
  end

  // outputs
  assign data_out[31:0] =
    rd_data ? {16'b0, timeoutval} :
    32'b0;
  assign trig = trigger;
  assign ack = stb;

endmodule

`resetall

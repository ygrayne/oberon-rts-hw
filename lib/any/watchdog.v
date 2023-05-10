/**
  Simple watchdog
  --
  * 'trig' is set high when 'ticker' > 'timeoutval'.
  * 'ticker' is driven by 'tick', usually a one-millisecond signal.
  * The watchdog is enabled when 'timeoutval' > 0.
  * Whenever 'timeoutval' is set, 'ticker' and 'trig' get reset.
  * Note: since 'ticker' and 'timeoutval' are both 16 bits, don't set a
    'timoutval' > 2^16 - 1, else 'ticker' > 'timeoutval' will not work (roll-over).
  --
  Architecture: ANY
  Board: any
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

  reg [15:0] timeoutval;
  reg [15:0] ticker;
  reg trigger;
  reg enable;

  always @(posedge clk) begin
    if (rst) begin
      timeoutval <= 16'b0;
      ticker <= 16'b0;
      trigger <= 1'b0;
      enable <= 1'b0;
    end
    else begin
      if (wr_data) begin
        timeoutval <= data_in[15:0];
        ticker <= 16'b0;
        trigger <= 1'b0;
        if (data_in[15:0] == 16'b0) enable <= 1'b0;
        else enable <= 1'b1;
      end
      else begin
        if (enable) begin
          if (ticker == timeoutval) begin
            trigger <= 1'b1;
//            timeoutval <= 16'b0;
//            ticker <= 16'b0;
            enable <= 1'b0;
          end
          else begin
            if (tick) begin
              ticker <= ticker + 16'b1;
            end
          end
        end
      end
    end
  end

  // outputs
  assign data_out[31:0] =
    rd_data ? {ticker, timeoutval} :
    32'b0;
  assign trig = trigger;
  assign ack = stb;

endmodule

`resetall

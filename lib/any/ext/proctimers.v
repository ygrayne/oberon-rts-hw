/**
  Process Timers
  --
  Instantiate 32 periodic process timers.
  --
  Architecture: ANY
  --
  Control data:
  for tickers:
  [0]: reset all tickers
  [1]: set ticker period
  for process timers:
  [2]: set process timer to use a specific ticker, reset ready bit
  [3]: reset (clear) ready signal
  [4]: enable
  [5]: disable
  [6]: force set ready
  --
  Data format:
  general:
  [7:0]: control data
  [31:16]: data: period for a ticker, ticker number for an individual process periodic timer
  for tickers:
  [15:0]: ticker number
  for process timers:
  [15:0]: individual timer number
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

  module proctimers (
    input wire clk,
    input wire rst,
    input wire stb,
    input wire we,
    input wire tick,
    input wire [31:0] data_in,
    output wire [31:0] data_out,
    output wire ack
  );

  wire wr_data = stb & we;
  wire rd_data = stb & ~we;

  // split input data
  wire [6:0] ctrl = data_in[6:0];
  wire [4:0] which = data_in[12:8];
  wire [15:0] data = data_in[31:16];

  // the eight tickers
  reg [15:0] period [7:0];
  reg [15:0] ticker [7:0];
  wire [7:0] period_done;
  wire reset_tickers = wr_data & ctrl[0];
  wire set_period = wr_data & ctrl[1];
  wire [2:0] select_tm = which[2:0];

  // generate the eight tickers
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin: tickers
      always @(posedge clk) begin
        period[i] <= rst ? 16'b0 : (set_period & (select_tm == i[2:0])) ? data : period[i];
        ticker[i] <= rst ? 16'b0 : (reset_tickers | period_done[i]) ? 16'b0 : ticker[i] + tick;
      end
      assign period_done[i] = (ticker[i] == period[i]);
    end
  endgenerate

  // control signals for process timers
  wire [31:0] wr_pt;
  wire [4:0] ctrl_pt = ctrl[6:2];
  wire [4:0] select_pc = which;  // address individual timers

  // output for process timers
  wire [31:0] proc_rdy;

  // generate the process timers
  genvar j;
  generate
    for (j = 0; j < 32; j = j+1) begin: timers
      proctim pt (
        .clk(clk), .rst(rst), .tick(tick),
        .period_done(period_done),
        .wr(wr_pt[j]),
        .ctrl(ctrl_pt),
        .data_in(data[2:0]),
        .proc_rdy(proc_rdy[j])
       );
      assign wr_pt[j] = (wr_data == 1'b1 && (select_pc == j)) ? 1'b1 : 1'b0;
    end
  endgenerate

  // assemble output data and signal
  assign data_out[31:0] =
    rd_data ? proc_rdy[31:0] :
    32'b0;

  assign ack = stb;

endmodule


module proctim (
  input wire clk,
  input wire rst,
  input wire tick,
  input wire wr,
  input wire [7:0] period_done,
  input wire [4:0] ctrl,
  input wire [2:0] data_in,
  output reg proc_rdy
);

  reg [2:0] ticker_no;
  reg en = 0;
  wire set_ticker = wr & ctrl[0];
  wire clear_ready = wr & ctrl[1];
  wire set_enabled = wr & ctrl[2];
  wire set_disabled = wr & ctrl[3];
  wire set_rdy = wr & ctrl[4];

  always @(posedge clk) begin
    ticker_no <= rst ? 3'b0 : set_ticker ? data_in[2:0] : ticker_no;
    en <= rst ? 1'b0 : ~set_disabled & (set_enabled | set_ticker | en);
    proc_rdy  <= rst ? 1'b0 : ~(set_ticker | set_enabled | set_disabled | clear_ready) & (en & (period_done[ticker_no] | set_rdy | proc_rdy));
  end
endmodule

`resetall

/**
  Process Timers Block
  --
  Instantiate 'numptmr' periodic process timers.
  --
  Architecture: ETH
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

  module proctimers #(parameter num_proc_tmr = 16) (
  input wire clk,
  input wire rst_n,
  input wire wr,
  input wire tick,
  input wire [31:0] data_in,
  output wire [num_proc_tmr-1:0] procRdy
);

  // splitting the input data
  wire [6:0] ctrl = data_in[6:0];
  wire [4:0] which = data_in[12:8];
  wire [15:0] data = data_in[31:16];


  // the eight tickers
  reg [15:0] period [7:0];
  reg [15:0] ticker [7:0];
  wire [7:0] period_done;
  wire reset_tickers = wr & ctrl[0];
  wire set_period = wr & ctrl[1];
  wire [2:0] select_tm = which[2:0];

  // generate the tickers
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin: tickers
      always @(posedge clk) begin
        period[i] <= ~rst_n ? 16'b0 : (set_period & (select_tm == i[2:0])) ? data : period[i];
        ticker[i] <= ~rst_n ? 16'b0 : (reset_tickers | period_done[i]) ? 16'b0 : ticker[i] + tick;
      end
      assign period_done[i] = (ticker[i] == period[i]);
    end
  endgenerate

  // control signals for process timers
  wire [num_proc_tmr-1:0] wr_pc;
  wire [4:0] select_pc = which;  // address individual timers

  // generate the process timers
  genvar j;
  generate
    for (j = 0; j < num_proc_tmr; j = j+1) begin: ptim
      proctim pt (
        .clk(clk), .rst_n(rst_n), .tick(tick),
        .period_done(period_done),
        .wr(wr_pc[j]),
        .ctrl(ctrl),
        .data(data[2:0]),
        .proc_rdy(procRdy[j])
       );
      assign wr_pc[j] = wr & (select_pc == j);
    end
  endgenerate
endmodule


module proctim (
  input wire clk,
  input wire rst_n,
  input wire tick,
  input wire wr,
  input wire [7:0] period_done,
  input wire [6:0] ctrl,
  input wire [2:0] data,
  output reg proc_rdy
);

  reg [2:0] ticker_no;
  reg en = 0;
  wire set_ticker = wr & ctrl[2];
  wire clear_ready = wr & ctrl[3];
  wire set_enabled = wr & ctrl[4];
  wire set_disabled = wr & ctrl[5];
  wire set_rdy = wr & ctrl[6];

  always @(posedge clk) begin
    ticker_no <= ~rst_n ? 3'b0 : set_ticker ? data : ticker_no;
    en <= ~rst_n ? 1'b0 : ~set_disabled & (set_enabled | set_ticker | en);
    proc_rdy  <= ~rst_n ? 1'b0 : ~(set_ticker | set_enabled | set_disabled | clear_ready) & (en & (period_done[ticker_no] | set_rdy | proc_rdy));
  end
endmodule

`resetall

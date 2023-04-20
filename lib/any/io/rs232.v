/**
  Serial Line Device (RS232)
  --
  Architecture: ANY
  ---
  Control data:
  data_in [0:0]:
    1'h0: 115200 baud
    1'h1: 9600 baud
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module rs232 #(parameter clock_freq = 50_000_000, buf_slots = 63) (
  // internal interface
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [7:0] data_in,
  output wire [31:0] data_out,
  output wire ack,
  // external interface
  input wire rxd,
  output wire txd
);

  wire rd_data = stb & ~we & ~addr; // read received data
  wire wr_data = stb &  we & ~addr; // write data to transmit
  wire rd_ctrl = stb & ~we &  addr; // read status
  wire wr_ctrl = stb &  we &  addr; // write control data

  reg [0:0] ctrl = 0;
  wire rx_empty, rx_full;
  wire tx_empty, tx_full;
  wire [7:0] rx_data;

  always @(posedge clk) begin
    if (rst) begin
      ctrl <= 1'b0;
    end else begin
      if (wr_ctrl) begin
        ctrl <= data_in[0:0];
      end
    end
  end

  rs232_rxb #(.clock_freq(clock_freq), .num_slots(buf_slots)) rs232_rxb_0 (
    .clk(clk),
    .rst(rst),
    .fsel(ctrl[0]),
    .rd(rd_data),
    .data_out(rx_data),
    .empty(rx_empty),
    .full(rx_full),
    .rxd(rxd)
  );

  rs232_txb #(.clock_freq(clock_freq), .num_slots(buf_slots)) rs232_txb_0 (
    .clk(clk),
    .rst(rst),
    .fsel(ctrl[0]),
    .wr(wr_data),
    .data_in(data_in[7:0]),
    .empty(tx_empty),
    .full(tx_full),
    .txd(txd)
  );

  assign data_out[31:0] =
    rd_data ? {24'h000000, rx_data[7:0]} :
    rd_ctrl ? {28'h0000000, ~tx_full, rx_full, tx_empty, ~rx_empty} :
    32'h0;

  assign ack = stb;

  // buffered use:
  // ~rx_empty: RXBNE  Rx buffer not empty, ie. data received, can receive more
  // tx_empty:  TXBE   Tx buffer empty, ie. ready to send
  // rx_full:   RXBF   Rx buffer full, ie. data received, cannot receive more
  // ~tx_full:  TXBNF  Tx buffer not full, ie. ready to send more

  // non-buffered use:
  // ~rx_empty: RXNE   Rx "register" non empty, ie. byte received
  // tx_empty:  TXE    Tx "register" empty, ie. ready to send

endmodule

`resetall

/**
  Serial Line Device (RS232)
  --
  Architecture: THM
  ---
  Base: THM-Oberon
  --
  Control data:
  data_in [2:0]:
    3'h0: 2400 baud
    3'h1: 4800 baud
    3'h2: 9600 baud
    3'h3: 19200 baud
    3'h4: 31250 baud
    3'h5: 38400 baud
    3'h6: 57600 baud
    3'h7: 115200 baud
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences

  * parameterised clock frequency
  * default baud rate is 115,200
**/

`timescale 1ns / 1ps
`default_nettype none

module ser #(parameter clockfreq = 50_000_000) (
  // internal interface
  input clk,
  input rst,
  input stb,
  input we,
  input addr,
  input [31:0] data_in,
  output [31:0] data_out,
  output ack,
  // external interface
  input rxd,
  output txd
);

  localparam bit_len_2400 = clockfreq / 2400;
  localparam bit_len_4800 = clockfreq / 4800;
  localparam bit_len_9600 = clockfreq / 9600;
  localparam bit_len_19200 = clockfreq / 19200;
  localparam bit_len_31250 = clockfreq / 31250;
  localparam bit_len_38400 = clockfreq / 38400;
  localparam bit_len_57600 = clockfreq / 57600;
  localparam bit_len_115200 = clockfreq / 115200;
  localparam default_bit_len = bit_len_115200;

  wire rd_data;
  wire wr_data;
  wire rd_ctrl;
  wire wr_ctrl;

  wire rcv_rdy;
  wire [7:0] rcv_data;
  wire xmt_rdy;

  reg [31:0] bit_len;

  assign rd_data = stb & ~we & ~addr; // read received data
  assign wr_data = stb &  we & ~addr; // write data to transmit
  assign rd_ctrl = stb & ~we &  addr; // read status
  assign wr_ctrl = stb &  we &  addr; // set bitrate

  rcvbuf rcvbuf_0(
    .clk(clk),
    .rst(rst),
    .bit_len(bit_len[15:0]),
    .read(rd_data),
    .ready(rcv_rdy),
    .data_out(rcv_data[7:0]),
    .serial_in(rxd)
  );

  xmtbuf xmtbuf_0(
    .clk(clk),
    .rst(rst),
    .bit_len(bit_len[15:0]),
    .write(wr_data),
    .ready(xmt_rdy),
    .data_in(data_in[7:0]),
    .serial_out(txd)
  );

  assign data_out[31:0] =
    rd_data ? { 24'h000000, rcv_data[7:0] } :
    rd_ctrl ? { 28'h0000000, 2'b00, xmt_rdy, rcv_rdy } :
    32'h00000000;

  always @(posedge clk) begin
    if (rst) begin
      bit_len <= default_bit_len;
    end else begin
      if (wr_ctrl) begin
          case (data_in[2:0])
          3'h0:  bit_len <= bit_len_2400;   //   2400 baud
          3'h1:  bit_len <= bit_len_4800;   //   4800 baud
          3'h2:  bit_len <= bit_len_9600;   //   9600 baud
          3'h3:  bit_len <= bit_len_19200;  //  19200 baud
          3'h4:  bit_len <= bit_len_31250;  //  31250 baud
          3'h5:  bit_len <= bit_len_38400;  //  38400 baud
          3'h6:  bit_len <= bit_len_57600;  //  57600 baud
          3'h7:  bit_len <= bit_len_115200; // 115200 baud
        endcase
      end
    end
  end

  assign ack = stb;

endmodule

`resetall

/**
  SRAM test device
  --
  Board: CV-SK
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module sram_test (
  // internal
  input wire clk,
  input wire clk_sram,
//  input wire clk_sram_ps,
  input wire rst,
  input wire stb,
  input wire we,
  input wire be,
  input wire addr,
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire ack,
  // etxernal
  output wire [17:0] sram_addr,
  inout wire [15:0] sram_data,
  output wire sram_ce_n,
  output wire sram_oe_n,
  output wire sram_we_n,
  output wire sram_ub_n,
  output wire sram_lb_n
  );

  wire rd_data = stb & ~we & ~addr;
  wire wr_data = stb &  we & ~addr;
  wire rd_ctrl = stb & ~we & addr;
  wire wr_ctrl = stb &  we & addr;

  reg [18:0] sram_a0;
  wire [31:0] sram_dout;
  wire rdy;

  always @(posedge clk) begin
    if (wr_ctrl) begin
      sram_a0[18:0] <= data_in[18:0];
    end
  end

  wire sram_en = wr_data | (wr_ctrl & data_in[31]);
  wire sram_we = wr_data;
  wire sram_be = stb & be;

  wire [18:0] sram_a = wr_data ? sram_a0[18:0] : (wr_ctrl && data_in[31]) ? data_in[18:0] : 19'b111_1100_0011_1010_0101;
  wire [31:0] sram_d = wr_data ? data_in[31:0] : 32'h00ABCDEF;

  // outputs
  assign data_out[31:0] =
    rd_data ? sram_dout[31:0] :
    rd_ctrl ? {31'b0, rdy} :
    32'b0;
  assign ack = stb;

  // SRAM
  sram sram_0 (
    // in
    .clk(clk_sram),
  //  .clk_ps(clk_sram_ps),
    .rst(rst),
    .en(sram_en),
    .be(sram_be),
    .we(sram_we),
    .addr(sram_a[18:0]),
    .data_in(sram_d[31:0]),
    // out
    .data_out(sram_dout[31:0]),
    .rdy(rdy),
    // external
    .sram_addr(sram_addr[17:0]),
    .sram_data(sram_data[15:0]),
    .sram_ce_n(sram_ce_n),
    .sram_oe_n(sram_oe_n),
    .sram_we_n(sram_we_n),
    .sram_ub_n(sram_ub_n),
    .sram_lb_n(sram_lb_n)
  );

endmodule

`resetall

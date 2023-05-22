/**
  SRAM test device
  --
  Board: DE2-115
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module sram_test (
  input wire clk,
  input wire clk_sram,
  input wire clk_sram_ps,
  input wire rst,
  input wire stb,
  input wire we,
  input wire be,
  input wire addr,
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire ack,
  // SRAM chip
  output wire [19:0] sram_addr,
  inout wire [15:0] sram_data,
  output wire sram_ce_n,
  output wire sram_oe_n,
  output wire sram_we_n,
  output wire sram_ub_n,
  output wire sram_lb_n
  );

  wire rd_data = stb & ~we & ~addr;
  wire wr_data = stb &  we & ~addr;
  wire rd_addr = stb & ~we & addr;
  wire wr_addr = stb &  we & addr;

  reg sram_we;
  reg sram_be;
  reg sram_en;
  reg [20:0] sram_a, sram_a0;
  reg [31:0] sram_d;
  wire [31:0] sram_dout;

  always @(posedge clk) begin
    if (rst) begin
      sram_en <= 1'b0;
      sram_we <= 1'b0;
      sram_be <= 1'b0;
      sram_a0 <= 20'b0;
    end
    else begin
      if (wr_addr) begin
        sram_a0[20:0] <= data_in[20:0];
        sram_en <= 1'b0;
        sram_we <= 1'b0;
      end
      else begin
        if (wr_data) begin
          sram_a[20:0] <= sram_a0[20:0];
          sram_d[31:0] <= data_in[31:0];
          sram_en <= 1'b1;
          sram_we <= 1'b1;
        end
        else begin
          if (rd_data) begin
            sram_a[20:0] <= sram_a0[20:0];
            sram_en <= 1'b1;
            sram_we <= 1'b0;
          end
          else begin
            sram_en <= 1'b1;
            sram_we <= 1'b0;
          end
        end
      end
    end
  end

  // outputs
  assign data_out[31:0] =
    rd_data ? sram_dout[31:0] :
    32'b0;
  assign ack = stb;

  // SRAM
  sram sram_0 (
    // in
    .clk(clk_sram),
    .clk_ps(clk_sram_ps),
    .rst(rst),
    .en(sram_en),
    .be(sram_be),
    .we(sram_we),
    .addr(sram_a[20:0]),
    .data_in(sram_d[31:0]),
    // out
    .data_out(sram_dout[31:0]),
    // SRAM external
    .sram_addr(sram_addr[19:0]),
    .sram_data(sram_data[15:0]),
    .sram_ce_n(sram_ce_n),
    .sram_oe_n(sram_oe_n),
    .sram_we_n(sram_we_n),
    .sram_ub_n(sram_ub_n),
    .sram_lb_n(sram_lb_n)
  );

endmodule

`resetall

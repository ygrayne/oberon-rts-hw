/**
  SRAM interface, 1M x 16 (2 MByte, [20:0])
  --
  Board: DE2-115
  --
  SRAM is 16 bit wide, 16-bit addressed ([19:0])
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module sram (
  input wire clk,
  input wire clk_ps,
  input wire rst,
  input wire en,
  input wire be,
  input wire we,
  input wire [20:0] addr,           // byte address
  input wire [31:0] data_in,
  output wire [31:0] data_out,

  output wire [19:0] sram_addr,     // half-word address (16 bits)
  inout wire [15:0] sram_data,      // data to and from SRAM
  output wire sram_ce_n,            // chip enable
  output wire sram_oe_n,            // output enable
  output wire sram_we_n,            // write enable
  output wire sram_ub_n,            // upper byte enable (read and write)
  output wire sram_lb_n             // lower byte enable (read and write)
);

  reg state;
  reg [31:0] dbuf;

  assign sram_ce_n = en;
  assign sram_oe_n = we;
  assign sram_we_n = ~(we & clk_ps);
//  assign sram_ub_n = 1'b0;
//  assign sram_lb_n = 1'b0;

  wire [1:0] addr10 = addr[1:0];
  wire [3:0] b_en = (~we | ~be) ? 4'b1111 :
    {addr10 == 2'b11, addr10 == 2'b10, addr10 == 2'b01, addr10 == 2'b00};

  assign sram_lb_n = (state == 1'b0) ? ~b_en[0] : ~b_en[2];
  assign sram_ub_n = (state == 1'b0) ? ~b_en[1] : ~b_en[3];

  assign sram_data[15:0] =
    we ? ((state == 1'b0) ? data_in[15:0] : data_in[31:16]): 16'hzzzz;

  assign sram_addr[19:0] =
    (state == 1'b0) ? {addr[20:2], 1'b0} : {addr[20:2], 1'b1};

  assign data_out[31:0] = dbuf[31:0]; // {sram_data[15:0], dbuf[15:0]};

  always @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end
    else begin
      state <= ~state;
    end
  end

  always @(posedge clk) begin
    if (~we) begin
      if (state == 1'b0) begin
        dbuf[15:0] <= sram_data[15:0];
      end
      else begin
        dbuf[31:16] <= sram_data[15:0];
      end
    end
  end

endmodule

`resetall
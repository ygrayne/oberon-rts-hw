/**
  RAM blocks: allocate BRAM, 32 bit wide
  --
  Parameter: 'num_kbytes': the number of kBytes
  --
  Write:
    * the CPU always writes a 32 bits word to the data bus
      (see term 'assign outbus = ...' for CPU)
    * without 'be', the address is word-aligned
    * with 'be'
      * the byte is positioned at the correct byte-aligned address inside the 32 bit word on the bus
      * the other bits are zero
      * it's the reponsibility of this device to write only the byte to memory
  Read:
    * the CPU always reads 32 bits from a word-aligned address
    * the CPU will mask out and shift the byte, ie. 'be' is not relevant for reads
      (see term 'assign inbus1 = ...' for CPU)
  --
  (c) 2022 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module ramg5 #(parameter num_kbytes = 128) (
  input wire clk,
  input wire en,
  input wire we,
  input wire be,
  input wire [$clog2(num_kbytes*'h400)-1:0] addr,
  input wire [31:0] data_in,
  output wire [31:0] data_out
);

  localparam num_kwords = num_kbytes / 4;
  localparam addr_width = $clog2(num_kbytes*'h400);

  // (byte-wise) write enable (addr[1:0])
  // reads are always 32 bits, see above
  wire [1:0] addr10 = addr[1:0];
  wire [3:0] b_en = ~en ? 4'b0 : (~we | ~be) ? 4'b1111 : {addr10 == 2'b11, addr10 == 2'b10, addr10 == 2'b01, addr10 == 2'b00};

  // address bus for the RAM blocks, word-aligned
  wire [addr_width-1:2] addr4 = addr[addr_width-1:2];

  // four RAM blocks, each one byte wide, full capacity depth, in parallel
  RAM_Nkx8 #(.num_onekb(num_kwords)) ram_Nkx8_0 (.clk(~clk), .en(b_en[0]), .we(we), .addr(addr4), .din(data_in[7:0]), .dout(data_out[7:0]));
  RAM_Nkx8 #(.num_onekb(num_kwords)) ram_Nkx8_1 (.clk(~clk), .en(b_en[1]), .we(we), .addr(addr4), .din(data_in[15:8]), .dout(data_out[15:8]));
  RAM_Nkx8 #(.num_onekb(num_kwords)) ram_Nkx8_2 (.clk(~clk), .en(b_en[2]), .we(we), .addr(addr4), .din(data_in[23:16]), .dout(data_out[23:16]));
  RAM_Nkx8 #(.num_onekb(num_kwords)) ram_Nkx8_3 (.clk(~clk), .en(b_en[3]), .we(we), .addr(addr4), .din(data_in[31:24]), .dout(data_out[31:24]));

endmodule


/**
  One byte wide storage block.
  'num_onekb' defines the number of one-kB blocks.
**/

module RAM_Nkx8 #(parameter num_onekb = 32) (
  input wire clk,
  input wire we,
  input wire en,
  input wire [$clog2(num_onekb*'h400)-1:0] addr,
  input wire [7:0] din,
  output reg [7:0] dout
);

  localparam num_bytes = num_onekb * 'h400;

  reg [7:0] ram [0:num_bytes-1];

  always @(posedge clk) begin
    if (en) begin
      if (we) begin
        ram[addr] <= din;
      end
      else begin
        dout <= ram[addr];
      end
    end
  end

endmodule

`resetall

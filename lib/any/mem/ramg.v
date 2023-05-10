/**
  RAM blocks: allocate BRAM in 32k and 16k 32-bit blocks
  Allocate as many 32k blocks as possible, then add a 16k block as needed
  --
  Parameter: 'mem_blocks': the number of 16kx32 blocks, ie. 16,384 * 4 bytes
  Limitation: minimum mem_blocks = 3 (ie. 196,608 bytes, allocates one 32k and one 16k block)
  --
  Logic for byte-wise write enable and rdata mux-ing from Astrobe's design. Thanks.
  --
  Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module ramg #(parameter mem_blocks = 3) (
  input wire clk,
  input wire wr,
  input wire be,
  input wire [$clog2(mem_blocks * 'h10000)-1:0] adr,
  input wire [31:0] wdata,
  output reg [31:0] rdata
);

  localparam Num16k = 0; //mem_blocks % 2;
  localparam Num32k = 4; // mem_blocks / 2;
  localparam NumBlocks = Num32k + Num16k;
  localparam MaxAdrBit = $clog2(mem_blocks * 'h10000);

  // clock divider
  reg clkb;
  always @(posedge clk) clkb <= ~clkb;

  // basic write enable, byte-wise (adr[1:0])
  wire [1:0] adr10 = adr[1:0];
  wire [3:0] byte_en = {~be | (adr10 == 2'b11), ~be | (adr10 == 2'b10), ~be | (adr10 == 2'b01), ~be | (adr10 == 2'b00)};
  wire [3:0] bwe = (wr & ~clkb) ? byte_en : 4'b0;

  wire [31:0] rdd [0:NumBlocks-1];  // rdata mux, 32 bits
  reg [3:0] we [0:NumBlocks-1];     // byte-wise write enable

  // update write enable and rdata
  integer i;
  always @ * begin
    for (i = 0; i < NumBlocks; i = i + 1) begin
      we[i] = 0;
    end
    rdata = 0;
    rdata = rdd[adr[MaxAdrBit-1:17]];
    we[adr[MaxAdrBit-1:17]] = bwe;
  end

  genvar j;
  generate
    for (j = 0; j < Num32k; j = j + 1) begin: b32k
      RAMG_base32 #(.cells(32768)) r32 (.clk(clk), .we(we[j]), .addr(adr[16:2]), .din(wdata), .dout(rdd[j]));
    end
    if (Num16k == 1) begin: b16k
      RAMG_base32 #(.cells(16384)) r16 (.clk(clk), .we(we[Num32k]), .a(adr[15:2]), .di(wdata), .do(rdd[Num32k]));
    end
  endgenerate
endmodule

/**
  32 bit wide base, with 'cells' cells.
**/
module RAMG_base32 #(parameter cells = 16384) (
  input wire clk,
  input wire [3:0] we,
  input wire [$clog2(cells)-1:0] addr,
  input wire [31:0] din,
  output wire [31:0] dout
);

  RAMG_base8 #(.cells(cells)) r0 (.clk(clk), .we(we[0]), .addr(addr), .din(din[7:0]), .dout(dout[7:0]));
  RAMG_base8 #(.cells(cells)) r1 (.clk(clk), .we(we[1]), .addr(addr), .din(din[15:8]), .dout(dout[15:8]));
  RAMG_base8 #(.cells(cells)) r2 (.clk(clk), .we(we[2]), .addr(addr), .din(din[23:16]), .dout(dout[23:16]));
  RAMG_base8 #(.cells(cells)) r3 (.clk(clk), .we(we[3]), .addr(addr), .din(din[31:24]), .dout(dout[31:24]));

endmodule

/**
  8 bit wide base, with 'cells' cells.
**/
module RAMG_base8 #(parameter cells = 16384) (
  input wire clk,
  input wire we,
  input wire [$clog2(cells)-1:0] addr,
  input wire [7:0] din,
  output reg [7:0] dout
);

  reg [7:0] ram [0:cells-1];

  always @(posedge clk) begin
    if (we) ram[addr] <= din;
    dout <= ram[addr];
  end
endmodule

`resetall

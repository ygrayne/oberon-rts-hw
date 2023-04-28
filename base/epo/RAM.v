//
// Embedded Project Oberon OS 
// Astrobe for RISC5 v8.0
// CFB Software 
// https://www.astrobe.com
//
// CFB 14.10.2021 512 KB version
`timescale 1ns / 1ps 
 
module RAM (
  input clk,
  input wr,
  input be,
  input [18:0] adr,
  input [31:0] wdata,
  output [31:0] rdata);

wire [3:0] byte_en, bwe;
reg clkdiv2;

assign byte_en = {(~be | (adr[1:0] == 2'b11)),
                  (~be | (adr[1:0] == 2'b10)),
                  (~be | (adr[1:0] == 2'b01)),
                  (~be | (adr[1:0] == 2'b00))};

assign bwe = (wr & ~clkdiv2) ? byte_en : 4'b0000;

BRAM bram (.clk(clk), .adr(adr[18:2]), .bwe(bwe), .wdata(wdata), .rdata(rdata));

always @(posedge clk) clkdiv2 <= ~clkdiv2; 

endmodule


module BRAM (clk, adr, bwe, wdata, rdata);
input clk;
input [16:0] adr;
input [3:0] bwe;
input [31:0] wdata;
output reg [31:0] rdata;

reg [3:0] we [0:3];
wire [31:0] do [0:3];
integer i;

always @ (adr or bwe or do[0] or do[1] or do[2] or do[3]) begin
  for (i = 0; i <= 3; i = i + 1) begin
    we[i] = 4'b0000;
  end;
  rdata = do[adr[16:15]];
  we[adr[16:15]] = bwe;
end

ram_32Kx32 block0  (.clk(clk), .we(we[0]), .a(adr[14:0]), .di(wdata), .do(do[0]));
ram_32Kx32 block1  (.clk(clk), .we(we[1]), .a(adr[14:0]), .di(wdata), .do(do[1]));
ram_32Kx32 block2  (.clk(clk), .we(we[2]), .a(adr[14:0]), .di(wdata), .do(do[2]));
ram_32Kx32 block3  (.clk(clk), .we(we[3]), .a(adr[14:0]), .di(wdata), .do(do[3]));

endmodule

module ram_32Kx32 (clk, we, a, di, do);
input clk;
input [3:0] we;
input [14:0] a;
input [31:0] di;
output [31:0] do;

ram_32Kx8 ram0 (.clk(clk), .we(we[0]), .a(a), .di(di[7:0]),   .do(do[7:0]));
ram_32Kx8 ram1 (.clk(clk), .we(we[1]), .a(a), .di(di[15:8]),  .do(do[15:8]));
ram_32Kx8 ram2 (.clk(clk), .we(we[2]), .a(a), .di(di[23:16]), .do(do[23:16]));
ram_32Kx8 ram3 (.clk(clk), .we(we[3]), .a(a), .di(di[31:24]), .do(do[31:24]));

endmodule

module ram_32Kx8 (clk, we, a, di, do);
input clk;
input we;
input [14:0] a;
input [7:0] di;
output reg [7:0] do;

reg [7:0] ram [0:32767];

always @(posedge clk) begin 
  if (we)
    ram[a] <= di; 
  do <= ram[a];
end

endmodule

/**
  System Configuration
  --
  Configuration parameters for the system RAM.
  * mem_lim: total RAM in bytes
  * stack_org: address of boundary between modules/stack and heap space
  * stack_size: stack size in bytes

  A few used configurations:
  * total 192k, heap: 32k, stack: 16k
    mem_lim = 'h30000, stack_org = 'h28000, stack_size = 'h4000
  * total: 256k, heap: 64k, stack: 16k
    mem_lim = 'h40000, stackOrg = 'h30000, stack_size = 'h4000
  * total: 256k, heap: 64k, stack: 16k
    mem_lim = 'h40000, stackOrg = 'h30000, stack_size = 'h4000
  * total 384k, heap: 64k, stack: 16k
    mem_lim = 'h60000, stackOrg = 'h50000, stack_size = 'h4000
  * total: 416k, heap: 64k, stack: 16k
    mem_lim = 'h68000, stackOrg = 'h58000, stack_size = 'h4000
  * total: 512k, heap: 64k, stack: 16k
    mem_lim = 'h80000, stackOrg = 'h70000, stack_size = 'h4000
  * total: 650k, heap: 64k, stack: 32k
    mem_lim = 'h90000, stackOrg = 'h80000, stack_size = 'h8000
  * total: 1M, heap: 512k, stack: 64k
    mem_lim = 'h100000, stackOrg = 'h80000, stack_size = 'h10000
  * total: 16M - 8k, heap: 8M, stack: 128k
    mem_lim = 'h1000000 - 'h2000, stackOrg = 'h800000, stack_size = 'h20000
  --
  Architecture: ANY
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none


module sysconf #(
  parameter
    mem_lim = 'h40000,
    stack_org = 'h30000,
    stack_size = 'h4000
  )(
  input wire clk,
  input wire stb,
  input wire we,
  input wire [1:0] data_in,
  output reg [31:0] data_out,
  output wire ack
);

  localparam
    mem_lim_ix = 2'd0,
    stack_org_ix = 2'd1,
    stack_size_ix = 2'd2;

  wire wr_select = stb &  we;

  reg [31:0] par [0:3];
  wire [1:0] select = data_in[1:0];

  initial begin
    par[mem_lim_ix] = mem_lim;
    par[stack_org_ix] = stack_org;
    par[stack_size_ix] = stack_size;
    par[3] = 32'h0;
  end

  always @(posedge clk) begin
    if (wr_select) begin
      case (select)
        mem_lim_ix: data_out[31:0] <= par[mem_lim_ix];
        stack_org_ix: data_out[31:0] <= par[stack_org_ix];
        stack_size_ix: data_out[31:0] <= par[stack_size_ix];
        default: data_out[31:0] <= 32'b0;
      endcase
    end
  end

  assign ack = stb;

endmodule

`resetall

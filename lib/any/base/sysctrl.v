/**
  System control and status
  --
  Architecture: ANY
  --
  (c) 2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module scs (
  input wire clk,
  input wire restart,               // from reset circuitry
  input wire stb,
  input wire we,
  input wire addr,
  input wire [7:0] err_sig,         // hardware error signals
  input wire [23:0] err_addr,       // program counter
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire sys_rst,              // reset the hardware (global 'rst')
  output wire sys_rst_n,            // reset the hardware (global 'rst_n')
  output wire [4:0] cp_pid,         // current process pid for other hardware to tap
  output wire ack
);

  wire wr_scs = stb &  we & ~addr;
  wire rd_scs = stb & ~we & ~addr;
  wire wr_err = stb &  we &  addr;
  wire rd_err = stb & ~we &  addr;

  reg [7:0] scs;          // control and status
  reg [4:0] cp_pid_r;     // current process pid
  reg [4:0] err_pid_r;    // error process pid
  reg [23:0] err_addr_r;  // error address
  reg [7:0] err_no_r;     // error number
  reg rst_trig;           // reset trigger from software


  integer i;
  always @(posedge clk) begin
    if (restart) begin
      scs[7:0] = 8'b0;
      cp_pid_r[4:0] = 5'b0;
      err_pid_r[4:0] = 5'b0;
      err_addr_r[23:0] = 24'b0;
      err_no_r[7:0] = 8'b0;
      rst_trig = 1'b0;
    end
    else begin
      if (scs[1]) begin         // resetting
        if (~rst_trig) begin
          rst_trig <= 1'b1;
        end
        else begin
          rst_trig <= 1'b0;
          scs[1] <= 1'b0;
        end
      end
      else begin                // otherwise
        if (wr_scs) begin
          scs <= data_in[7:0];
          cp_pid_r <= data_in[12:8];
          err_pid_r <= data_in[17:13];
        end
        else begin
          if (wr_err) begin
            err_addr_r <= data_in[31:8];
            err_no_r <= data_in[7:0];
          end
          else begin
            i = 0;
            while (~scs[1] && (i < 8)) begin
              if (err_sig[i]) begin
                scs[1] <= 1'b1;           // start reset
                err_addr_r <= err_addr;
                err_no_r <= {1'b1, i[2:0]};
              end
              i = i + 1;
            end
          end
        end
      end
    end
  end

  assign data_out[31:0] =
    rd_scs ? {14'b0, err_pid_r[4:0], cp_pid_r[4:0], scs[7:0]} :
    rd_err ? {err_addr_r[23:0], err_no_r[7:0]} :
    32'b0;

  assign sys_rst = restart | rst_trig;
  assign sys_rst_n = ~sys_rst;
  assign cp_pid = cp_pid_r;

  assign ack = stb;

endmodule

`resetall
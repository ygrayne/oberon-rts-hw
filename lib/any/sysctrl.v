/**
  System control and status
  --
  Architecture: ANY
  --
  SCS:
  [0]: reset, don't restart
  [1]: start reset sequence
  [2]: currently handling error, all errors disabled apart from err_sig[0]
  [7:3]: unused
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
  reg reset;              // reset signal
  reg [23:0] rst_cnt;     // reset duration timer counter
  reg [7:0] err_sig_0;    // error signal edge detection
  reg [7:0] err_sig_pend; // pending error signals

  always @(posedge clk) begin
    if (restart) begin      // cold start: power up, FPGA reconfig, reset button
      scs[7:0] <= 8'b0;
      cp_pid_r[4:0] <= 5'b0;
      err_pid_r[4:0] <= 5'b0;
      err_addr_r[23:0] <= 24'b0;
      err_no_r[7:0] <= 8'b0;
      reset <= 1'b0;
      rst_cnt[23:0] <= 24'b0;
      err_sig_0[7:0] <= 8'b0;
      err_sig_pend[7:0] <= 8'b0;
    end
    else begin
      // edge detection and pending
      err_sig_0[7:0] <= err_sig[7:0];
      err_sig_pend[7:0] <= (err_sig[7:0] & ~err_sig_0[7:0]) | err_sig_pend[7:0];

      // resetting
      if (scs[1]) begin
        if (~reset) begin
          reset <= 1'b1;
          rst_cnt[23:0] <= 24'b0;
        end
        else begin
          if (rst_cnt == 24'hFFFF) begin
            reset <= 1'b0;
            scs[1] <= 1'b0;
          end
          else begin
            rst_cnt[23:0] <= rst_cnt[23:0] + 24'b1;
          end
        end
      end
      else begin
        // writing SCS
        if (wr_scs) begin
          scs[7:0] <= data_in[7:0];
          cp_pid_r[4:0] <= data_in[12:8];
          err_pid_r[4:0] <= data_in[17:13];
        end
        else begin
          // error detection and handling
          if (err_sig_pend[0] == 1'b1) begin  // special powers for err_sig[0]
            err_no_r[7:0] <= 8'h10;
            err_addr_r[23:0] <= err_addr[23:0];
            scs[1] <= 1'b1;
            scs[2] <= 1'b1;
            err_sig_pend[7:0] <= 8'b0;
          end
          else begin
            if (scs[2] == 1'b0) begin  // not currently handling an error
              // trap handler
              if (wr_err) begin
                err_addr_r[23:0] <= data_in[31:8];
                err_no_r[7:0] <= data_in[7:0];
                scs[1] <= 1'b1; // request reset
                scs[2] <= 1'b1; // will be set to 0 by software
                err_sig_pend[7:0] <= 8'b0;
              end
              else begin
                // hw-triggered errors
                if (err_sig_pend[7:0] != 8'b0) begin
                  err_addr_r[23:0] <= err_addr[23:0];
                  scs[1] <= 1'b1;
                  scs[2] <= 1'b1;
                  if (err_sig_pend[1] == 1'b1) err_no_r[7:0] <= 8'h11;
                  else if (err_sig_pend[2] == 1'b1) err_no_r[7:0] <= 8'h12;
                  else if (err_sig_pend[3] == 1'b1) err_no_r[7:0] <= 8'h13;
                  else if (err_sig_pend[4] == 1'b1) err_no_r[7:0] <= 8'h14;
                  else if (err_sig_pend[5] == 1'b1) err_no_r[7:0] <= 8'h15;
                  else if (err_sig_pend[6] == 1'b1) err_no_r[7:0] <= 8'h16;
                  else if (err_sig_pend[7] == 1'b1) err_no_r[7:0] <= 8'h17;
                  err_sig_pend[7:0] <= 8'b0; // only one error at a time
                end
              end
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

  assign sys_rst = restart | reset;
  assign sys_rst_n = ~sys_rst;
  assign cp_pid = cp_pid_r;

  assign ack = stb;

endmodule

`resetall
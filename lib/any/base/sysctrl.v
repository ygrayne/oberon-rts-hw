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
  input wire [7:0] err_sig_in,      // hardware error signals
  input wire [23:0] err_addr_in,    // program counter
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire sys_rst,              // reset the hardware ('rst')
  output wire ack
);

  wire wr_scs = stb &  we & ~addr;
  wire rd_scs = stb & ~we & ~addr;
  wire wr_err = stb &  we &  addr;
  wire rd_err = stb & ~we &  addr;
  
  reg [7:0] scs;        // control and status
  reg [4:0] cp_pid;     // current process pid
  reg [4:0] err_pid;    // error process pid
  reg [23:0] err_addr;  // error address
  reg [7:0] err_no;     // error number
  reg rst_trig;         // reset trigger from software
  
//  initial begin
//    scs[7:0] = 8'b0;
//    cp_pid[4:0] = 5'b0;
//    err_pid[4:0] = 5'b0;
//    err_addr[23:0] = 24'b0;
//    err_no[7:0] = 8'b0;
//  end

  integer i;
  always @(posedge clk) begin
    if (restart) begin
      scs[7:0] = 8'b0;
      cp_pid[4:0] = 5'b0;
      err_pid[4:0] = 5'b0;
      err_addr[23:0] = 24'b0;
      err_no[7:0] = 8'b0;
      rst_trig = 1'b0;
    end
    else begin
      if (scs[1]) begin
        rst_trig <= 1'b1;
        scs[1] <= 1'b0;
      end
      else begin
        rst_trig <= 1'b0;
      end
      if (wr_scs) begin
        scs <= data_in[7:0];
        cp_pid <= data_in[12:8];
        err_pid <= data_in[17:13];
      end
      else begin
        if (wr_err) begin
          err_addr <= data_in[31:8];
          err_no <= data_in[7:0];
        end
        else begin
          i = 0;
          while (~scs[1] && (i < 8)) begin
            if (err_sig_in[i]) begin
              scs[1] <= 1'b1;           // reset
              err_addr <= err_addr_in;
              err_no <= {1'b1, i[2:0]};
            end
            i = i + 1;
          end
        end
      end
    end
  end
    
//    else begin
//      if (rst) begin
//        scs <= {7'b0, scs[0]}; // keep other status regs across resets
//      end
//      else begin
//        if (wr_scs) begin
//          if (wr_fast == 2'b00) begin
//            scs <= data_in[7:0];
//            cp_pid <= data_in[12:8];
//            err_pid <= data_in[17:13];
//          end
//          else begin
//            if (wr_fast == 2'b01) begin
//              cp_pid <= data_in[4:0];     // no need to read-modify-write
//            end
//          end
//        end
//        else begin
//          if (wr_err) begin
//            err_addr <= data_in[31:8];
//            err_no <= data_in[7:0];
//          end
//          else begin
//            i = 0;
//            while (~scs[1] && (i < 8)) begin
//              if (err_sig_in[i]) begin
//                scs[1] <= 1'b1;           // reset
//                err_addr <= err_addr_in;
//                err_no <= {1'b1, i[2:0]};
//              end
//              i = i + 1;
//            end
//          end
//        end
//      end
//    end


  assign data_out[31:0] =
    rd_scs ? {14'b0, err_pid[4:0], cp_pid[4:0], scs[7:0]} :
    rd_err ? {err_addr[23:0], err_no[7:0]} :
    32'b0;

  assign sys_rst = restart | rst_trig;

  assign ack = stb;

endmodule

`resetall
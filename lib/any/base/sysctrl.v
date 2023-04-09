/**
  System control and status
  --
  Architecture: ANY
  --
  2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module sysctrl (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [7:0] err_sig_in,
  input wire [23:0] err_addr_in,
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output wire sys_rst,
  output wire ack
);

  wire wr_scr = stb &  we & ~addr;
  wire rd_scr = stb & ~we & ~addr;
  wire wr_err = stb &  we &  addr;
  wire rd_err = stb & ~we &  addr;

  reg [31:0] scr;
  reg [23:0] err_addr;
  reg [7:0] err_no;

  initial begin
    scr = 32'b0;
    err_addr = 24'b0;
    err_no = 8'b0;
  end

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      scr <= {14'b0, scr[12:8], scr[12:8], 7'b0, scr[0]};
    end
    else begin
      if (wr_scr) begin
        scr <= data_in[31:0];
      end
      else begin
        if (wr_err) begin
          err_addr <= data_in[31:8];
          err_no <= data_in[7:0];
        end
        else begin
          i = 0;
          while(~scr[1] && i < 8) begin
            if (err_sig_in[i]) begin
              scr[1] <= 1'b1;
              err_addr <= err_addr_in;
              err_no <= {1'b1, i[2:0]};
            end
            i = i + 1;
          end
        end
      end
    end
  end


  assign data_out[31:0] =
    rd_scr ? scr[31:0] :
    rd_err ? {err_addr[23:0], err_no[7:0]} :
    32'b0;

  assign sys_rst = scr[1];

  assign ack = stb;

endmodule

`resetall
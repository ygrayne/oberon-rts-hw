/**
  SRAM controller, SRAM controller, 2MB, arranged as 1M x 16 (1M half-words)
  --
  Read/write cycle within two CPU clock cycles (freq = double CPU clock freq).
  --
  Currently only works with SRAM testing device (via IO).
  --
  Board: DE2-115
  --
  SRAM is half-word addressed (row address, [19:0]).
  --
  (c) 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module sram (
  // internal
  input io_en,
  input wire clk,
//  input wire clk_ps,
  input wire rst,
  input wire en,
  input wire be,
  input wire we,
  input wire [20:0] addr,         // byte address
  input wire [31:0] data_in,
  output wire [31:0] data_out,
  output reg rdy,
  // external (SRAM chip)
  output wire [19:0] sram_addr,   // half-word address
  inout wire [15:0] sram_data,    // data to and from SRAM
  output wire sram_ce_n,          // chip enable
  output wire sram_oe_n,          // output enable
  output wire sram_we_n,          // write enable
  output wire sram_ub_n,          // upper byte enable (read and write)
  output wire sram_lb_n           // lower byte enable (read and write)
);

  // buffers
  reg [20:0] addr_c;              // capture address from bus
  reg [31:0] data_in_c;           // capture write data from bus
  reg [31:0] data_out_c;          // collect read data from SRAM
  reg be_c;                       // byte enable (only relevant for writes)

  // SRAM data and signals for state machine
  reg [19:0] sram_addr0;          // address to SRAM
  reg [15:0] sram_data0;          // data to SRAM
  reg sram_ce, sram_oe, sram_we;  // control signals to SRAM
  reg sram_lb, sram_ub;

  // connect SRAM
  assign sram_addr[19:0] = sram_addr0[19:0];
  assign sram_data[15:0] = sram_we ? sram_data0[15:0] : 16'hzzzz; // tri-state output
  assign sram_ce_n = ~sram_ce;
  assign sram_oe_n = ~sram_oe;
  assign sram_we_n = ~sram_we;
  assign sram_lb_n = ~sram_lb;
  assign sram_ub_n = ~sram_ub;

  assign data_out[31:0] = data_out_c[31:0];

  // FSM states
  reg [2:0] state, next;
  localparam
    idle = 3'd0,
    rd0 = 3'd1,
    wr0 = 3'd2,
    rd1 = 3'd3,
    wr1 = 3'd4,
    rda = 3'd5,
    wra = 3'd6;

  // FSM state change
  always @(posedge clk) begin
    if (rst) begin
      state <= idle;
    end
    else begin
      state <= next;
    end
  end

  // capture address and data from bus
  // capture byte enable signal
  always @(posedge clk) begin
    if (en) begin
      if (state == idle) begin
        addr_c[20:0] <= addr[20:0];
        if (we) begin
          data_in_c[31:0] <= data_in[31:0];
          be_c <= be;
        end
      end
    end
  end

  // collect data read from SRAM
  always @(posedge clk) begin
    if (state == rd0) begin
      data_out_c[15:0] <= sram_data[15:0];
    end
    else if (state == rd1) begin
      data_out_c[31:16] <= sram_data[15:0];
    end
  end

  // next FSM state and outputs
  always @(*) begin
    // defaults
    next = state;
    rdy = 1'b0;
    sram_ce = 1'b1;
    sram_oe = 1'b0;
    sram_we = 1'b0;
    sram_lb = 1'b1;
    sram_ub = 1'b1;
    sram_data0[15:0] = {16{1'bx}};
    sram_addr0[19:0] = {20{1'bx}};
    case(state)
      idle: begin
        if (~en) begin
          sram_ce = 1'b0;
          rdy = 1'b1;
          next = idle;
        end
        // address and are available on bus
        // byte enable signal available
        else begin
          if (~we) begin
            sram_addr0[19:0] = {addr[20:0], 1'b0};
            sram_oe = 1'b1;
            next = rd0;
          end
          else begin
            sram_addr0[19:0] = {addr[20:0], 1'b0};
            sram_data0[15:0] = data_in[15:0];
            next = wr0;
          end
        end
      end
      rd0: begin
        sram_addr0[19:0] = {addr[20:0], 1'b0};
        sram_oe = 1'b1;
        next = rda;
      end
      wr0: begin
        sram_addr0[19:0] = {addr[20:0], 1'b0};
        sram_data0[15:0] = data_in[15:0];
        if (be) begin
          sram_lb = (addr[1:0] == 2'b00);
          sram_ub = (addr[1:0] == 2'b01);
        end
        sram_we = 1'b1;
        next = wra;
      end
      // use captured address and data
      // use captured byte enable signal
      rda: begin
        sram_addr0[19:0] = {addr_c[20:0], 1'b1};
        sram_oe = 1'b1;
        next = rd1;
      end
      wra: begin
        sram_addr0[19:0] = {addr_c[20:0], 1'b1};
        sram_data0[15:0] = data_in_c[31:16];
        next = wr1;
      end
      rd1: begin
        sram_addr0[19:0] = {addr_c[20:0], 1'b1};
        sram_oe = 1'b1;
        next = idle;
      end
      wr1: begin
        sram_addr0[19:0] = {addr_c[20:0], 1'b1};
        sram_data0[15:0] = data_in_c[31:16];
        if (be_c) begin
          sram_lb = (addr_c[1:0] == 2'b10);
          sram_ub = (addr_c[1:0] == 2'b11);
        end
        sram_we = 1'b1;
        next = idle;
      end
    endcase
  end

endmodule

`resetall
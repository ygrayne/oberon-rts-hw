/**
  GPIO
  --
  Architecture: ANY
  --
  Parameters:
  * num_gpio: number of GPIO pins (max 32)
  --
  (c) 2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module gpio #(parameter num_gpio = 32) (
  input wire clk,
  input wire rst,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [num_gpio-1:0] data_in,   // data to ports
  inout wire [num_gpio-1:0] io_pin,    // the actual pins
  output wire [31:0] data_out,         // data from ports, port status
  output wire ack
);

  localparam unused = 32 - num_gpio;

  wire rd_data = stb & ~we & ~addr; // read gpio data from ports
  wire wr_data = stb &  we & ~addr; // write gpio data to ports
  wire rd_ctrl = stb & ~we &  addr; // read status
  wire wr_ctrl = stb &  we &  addr; // write control data

  reg [num_gpio-1:0] gpio_out;     // data to pins
  reg [num_gpio-1:0] gpio_oc;      // output control, default = 0 => tristate => input
  wire [num_gpio-1:0] gpio_in;     // data from pins

  always @(posedge clk) begin
    if (rst) begin
      gpio_oc[num_gpio-1:0] <= {num_gpio{1'b0}};  // tristate
    end
    else begin
      if (wr_data) begin
        gpio_out[num_gpio-1:0] <= data_in[num_gpio-1:0];
      end
      else begin
        if (wr_ctrl) begin
          gpio_oc[num_gpio-1:0] <= data_in[num_gpio-1:0];
        end
      end
    end
  end

  genvar i;
  generate
    for (i = 0; i < num_gpio; i = i+1) begin: gpioblock
      IOBUF iobuf (.I(gpio_out[i]), .O(gpio_in[i]), .IO(io_pin[i]), .T(~gpio_oc[i]));
    end
  endgenerate

  assign data_out[31:0] =
    rd_data ? {{unused{1'b0}}, gpio_in} :
    rd_ctrl ? {{unused{1'b0}}, gpio_oc} :
    32'h0;

  assign ack = stb;

endmodule

`resetall
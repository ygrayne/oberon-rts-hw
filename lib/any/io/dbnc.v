/**
  Button/switch debouncer
  --
  Architecture: ANY
  --
  Parameter:
    polarity: 1 => btn_in is active high, 0 => low
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module dbnc #(parameter polarity = 1'b1) (
  input wire clk,
  input wire rst,
  input wire btn_in,     // not debounced HW button
  output wire btn_out    // debounced state of btn_in
);

  wire btn_pol = (polarity == 1'b1) ? btn_in : ~btn_in;

  reg state;
  reg [16:0] count;
  reg btn_s_0;
  reg btn_s_1;

  always @(posedge clk) begin
    btn_s_0 <= btn_pol;
    btn_s_1 <= btn_s_0;

    if (rst) begin
      state <= 1'b0;
      count[16:0] <= 17'b0;
    end
    else begin
      if (btn_s_1 == state) begin   // idle
        count[16:0] <= 17'b0;
      end
      else begin // button pressed
        count[16:0] <= count[16:0] + 17'b1;
        if (count == &count) begin
          state <= ~state;  // => btn_s_1 == state, counting stops
        end
      end
    end
  end

  assign btn_out = state;

endmodule

`resetall

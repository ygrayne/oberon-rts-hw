`timescale 1ns / 1ps
/**
  Control and status module for Nexys-A7-200 "video" LEDs, switches, buttons
  8 LEDs, 8 switches, 5 buttons
  Buttons and switches are debounced
  --
  (c) 2020 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

module LSB1 (
  input clk,
  input [31:0] data,
  input set,
  input [3:0] hwbtn,
  input [3:0] hwswi,
  output reg [7:0] leds = 0,
  output [4:0] btn,
  output [7:0] swi
);

  //assign btn[3:0] = hwbtn[3:0];
  //assign swi[3:0] = hwswi[3:0];

  // debouncers
  DBNC dbnc_btn0 (.clk(clk), .hwbutton(hwbtn[0]), .state(btn[0]));
  DBNC dbnc_btn1 (.clk(clk), .hwbutton(hwbtn[1]), .state(btn[1]));
  DBNC dbnc_btn2 (.clk(clk), .hwbutton(hwbtn[2]), .state(btn[2]));
  DBNC dbnc_btn3 (.clk(clk), .hwbutton(hwbtn[3]), .state(btn[3]));
  DBNC dbnc_btn4 (.clk(clk), .hwbutton(hwbtn[4]), .state(btn[4]));

  DBNC dbnc_swi0 (.clk(clk), .hwbutton(hwswi[0]), .state(swi[0]));
  DBNC dbnc_swi1 (.clk(clk), .hwbutton(hwswi[1]), .state(swi[1]));
  DBNC dbnc_swi2 (.clk(clk), .hwbutton(hwswi[2]), .state(swi[2]));
  DBNC dbnc_swi3 (.clk(clk), .hwbutton(hwswi[3]), .state(swi[3]));
  DBNC dbnc_swi4 (.clk(clk), .hwbutton(hwswi[4]), .state(swi[4]));
  DBNC dbnc_swi5 (.clk(clk), .hwbutton(hwswi[5]), .state(swi[5]));
  DBNC dbnc_swi6 (.clk(clk), .hwbutton(hwswi[6]), .state(swi[6]));
  DBNC dbnc_swi7 (.clk(clk), .hwbutton(hwswi[7]), .state(swi[7]));

  always @(posedge clk) begin
    leds <= set ? data[7:0] : leds;
  end
endmodule

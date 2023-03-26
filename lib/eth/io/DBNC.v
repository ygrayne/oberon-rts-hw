/**
  Button/switch debouncer
  Requires button/switch to make stable contact for 2.6ms (see 'count' to adjust)
  --
  2020 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module DBNC (
  input wire clk,
  input wire hwbutton,    // HW button, active high
  output reg state = 0    // debounced state of hwbutton
);

  // sync hwbutton with the clock
  // the signal is still bouncy!
  reg hwsynced0, hwsynced1;
  always @(posedge clk) begin
    hwsynced0 <= hwbutton;  // change to ~hwbutton if active low
    hwsynced1 <= hwsynced0;
  end
  // detect button/switch activation
  wire nochange = (hwsynced1 == state);

  // counter to measure time of stable contact of hwbutton
  // max counter value determines the debounce period
  reg [16:0] count;         // 50 MHz: 2^17 => 2.6ms
  wire count_max = &count;	// reduction: true when all bits of count are 1

  // keep 'count' at zero when idle, or repeatedly reset to zero during bounce time
  // accept state change when counter reaches max
  always @(posedge clk) begin
    count <= nochange ? 0 : count + 1;
    state <= count_max ? ~state : state;
  end

endmodule

`resetall

// unused pulses
//output closed,  // a pulse of one clock cycle when the HW button/switch makes contact
//output open     // a pulse of one clock cycle when the HW button/switch is released/opened

//assign closed = ~nochange & count_max & ~state;
//assign open   = ~nochange & count_max &  state;
/**
  Button/switch debouncer
  --
  Architecture: gen
  --
  Parameter:
    polarity: 1 => btn_in is active high, 0 => low
  --
  2020 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module dbnc #(parameter polarity = 1) (
  input wire clk,
  input wire btn_in,     // HW button
  output wire btn_out    // debounced state of btn_in
);

  wire btn_pol = (polarity == 1) ? btn_in : ~btn_in;

  reg state = 0;

  // sync btn_pol with the clock
  // the signal is still bouncy!
  reg hwsynced0, hwsynced1;
  always @(posedge clk) begin
    hwsynced0 <= btn_pol;
    hwsynced1 <= hwsynced0;
  end
  // detect button/switch activation
  wire nochange = (hwsynced1 == state);

  // counter to measure time of stable contact of btn_in
  // max counter value determines the debounce period
  reg [16:0] count;         // 50 MHz: 2^17 => 2.6ms
  wire count_max = &count;	// reduction: true when all bits of count are 1

  // keep 'count' at zero when idle, or repeatedly reset to zero during bounce time
  // accept state change when counter reaches max
  always @(posedge clk) begin
    count <= nochange ? 0 : count + 1;
    state <= count_max ? ~state : state;
  end

  assign btn_out = state;

endmodule

`resetall

// unused pulses
//output closed,  // a pulse of one clock cycle when the HW button/switch makes contact
//output open     // a pulse of one clock cycle when the HW button/switch is released/opened

//assign closed = ~nochange & count_max & ~state;
//assign open   = ~nochange & count_max &  state;
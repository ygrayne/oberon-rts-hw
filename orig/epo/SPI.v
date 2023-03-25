`timescale 1ns / 1ps

// Motorola Serial Peripheral Interface (SPI) PDR 23.3.12 / 16.10.13
// transmitter / receiver of words (fast, clk/4) or bytes (slow, clk/100)
// e.g 10MHz or ~400KHz respectively at 40MHz (slow needed for SD-card init)
// note: bytes are always MSbit first; but if fast, words are LSByte first

// PDR 06.11.2017 / CFB 20.04.2018 Idle the clock at high for DS3234 RTC chip
// CFB 29.05.2020 Adjusted tick limits for 40MHz clock
// CFB 03.06.2020 Added wordsize parameter - separated from fast 

module SPI(
  input clk, rst,
  input start, fast, wordsize,
  input [31:0] dataTx,
  output [31:0] dataRx,
  output reg rdy,
  input MISO, output MOSI, output SCLK);

wire endbit, endtick;
reg [31:0] shreg;
reg [6:0] tick;
reg [4:0] bitcnt;

assign endtick = fast ? (tick == 4) : (tick == 99);  //40MHz clk
assign endbit = wordsize ? (bitcnt == 31) : (bitcnt == 7);
assign dataRx = wordsize ? shreg : {24'b0, shreg[7:0]};
assign MOSI = (~rst | rdy) ? 1 : shreg[7];
assign SCLK = (~rst | rdy) ? 1 : fast ? endtick : tick[6];

always @ (posedge clk) begin
  tick <= (~rst | rdy | endtick) ? 0 : tick + 1;
  rdy <= (~rst | endtick & endbit) ? 1 : start ? 0 : rdy;
  bitcnt <= (~rst | start) ? 0 : (endtick & ~endbit) ? bitcnt + 1 : bitcnt;
  shreg <= ~rst ? -1 : start ? dataTx : endtick ? 
    {shreg[30:24], MISO, shreg[22:16], shreg[31], shreg[14:8],
        shreg[23], shreg[6:0], (wordsize ? shreg[15] : MISO)} : shreg;   
end

endmodule
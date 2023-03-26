`timescale 1ns / 1 ps // NW 4.5.09 / 15.8.10 / 15.11.10 / 13.8.15

// RS232 receiver for 19200 / 115200 bps, 8 bit data

// CFB 24.07.16 Clock is 50 MHz, default rate is 115.2 KHz
// 50000 / 2604 = 19.2 KHz
// 50000 / 434 = 115.2 KHz 
// CFB 28.05.20 Clock is 40 MHz, default rate is 115.2 KHz
// 40000 / 2083 = 19.2 KHz
// 40000 / 347 = 115.2 KHz 

module RS232R(   // translated from Lola
  input clk, rst, done, RxD, fsel,
  output rdy,
  output [7:0] data);

reg run, stat, Q0, Q1;
reg [11:0] tick;
reg [3:0] bitcnt;
reg [7:0] shreg;
wire endtick, midtick, endbit;
wire [11:0] limit;

assign rdy = stat;
assign data = shreg;
assign endtick = (tick == limit);
assign midtick = (tick == {1'h0, limit[11:1]});
assign endbit = (bitcnt == 8);
assign limit = fsel ? 2083 : 347; // 40 MHZ

always @ (posedge clk) begin 
  run <= ((Q1 & ~Q0) | (~(~rst | (endtick & endbit)) & run));
  stat <= ((endtick & endbit) | (~(~rst | done) & stat));
  Q0 <= RxD;
  Q1 <= Q0;
  tick <= (run & ~endtick) ? (tick + 1) : 0;
  bitcnt <= (endtick & ~endbit) ? (bitcnt + 1) : (endtick & endbit) ? 0 : bitcnt;
  shreg <= midtick ? {Q1, shreg[7:1]} : shreg;
end
endmodule

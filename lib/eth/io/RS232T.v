`timescale 1ns / 1ps  // NW 4.5.09 / 15.8.10 / 15.11.10

// RS232 transmitter for 19200 bps, 8 bit data
// CFB 24.07.16 Clock is 50 MHz, default rate is 115.2 KHz
// 50000 / 2604 = 19.2 KHz
// 50000 / 434 = 115.2 KHz 
// CFB 28.05.20 Clock is 40 MHz, default rate is 115.2 KHz
// 40000 / 2083 = 19.2 KHz
// 40000 / 347 = 115.2 KHz 

module RS232T(
    input clk, rst,
    input start, // request to accept and send a byte
	 input fsel,  // frequency selection
    input [7:0] data,
    output rdy,
    output TxD);

wire endtick, endbit;
wire [11:0] limit;
reg run;
reg [11:0] tick;
reg [3:0] bitcnt;
reg [8:0] shreg;

assign limit = fsel ? 2083 : 347; // 40 MHZ
assign endtick = tick == limit;
assign endbit = bitcnt == 9;
assign rdy = ~run;
assign TxD = shreg[0];

always @ (posedge clk) begin
  run <= (~rst | endtick & endbit) ? 0 : start ? 1 : run;
  tick <= (run & ~endtick) ? tick + 1 : 0;
  bitcnt <= (endtick & ~endbit) ? bitcnt + 1 :
    (endtick & endbit) ? 0 : bitcnt;
  shreg <= (~rst) ? 1 : start ? {data, 1'b0} :
    endtick ? {1'b1, shreg[8:1]} : shreg;
end
endmodule

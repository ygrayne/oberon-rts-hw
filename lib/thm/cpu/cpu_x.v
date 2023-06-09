//
// cpu_x.v -- the RISC5 CPU
// extended, search for "gray"
//


`timescale 1ns / 1ps
`default_nettype none


module cpu_x #(parameter start_addr = 24'hFFE000) ( // gray
  clk, rst,
  bus_stb, bus_we, bus_addr,
  bus_din, bus_dout, bus_ack,
  spx, lnkx, pcx, irx  // gray
);
    input clk;                  // system clock
    input rst;                  // system reset
    output bus_stb;             // bus strobe
    output bus_we;              // bus write enable
    output [23:2] bus_addr;     // bus address (word address)
    input [31:0] bus_din;       // bus data input, for reads
    output [31:0] bus_dout;     // bus data output, for writes
    input bus_ack;              // bus acknowledge
    // gray
    output [31:0] spx;         // stack pointer value
    output [31:0] lnkx;        // link register value
    output [23:0] pcx;         // program counter value
    output [31:0] irx;         // instruction register value

  wire cpu_stb;
  wire cpu_we;
  wire cpu_ben;
  wire [23:0] cpu_addr;
  wire [31:0] cpu_din;
  wire [31:0] cpu_dout;
  wire cpu_ack;

  cpu_bus cpu_bus_0 (
    .clk(clk),
    .rst(rst),
    // from devices (in)
    .bus_ack(bus_ack),
    // to devices (out)
    .bus_stb(bus_stb),
    .bus_we(bus_we),
    .bus_addr(bus_addr[23:2]),
    .bus_din(bus_din[31:0]),
    .bus_dout(bus_dout[31:0]),
    // from cpu (in)
    .cpu_stb(cpu_stb),
    .cpu_we(cpu_we),
    .cpu_ben(cpu_ben),
    .cpu_addr(cpu_addr[23:0]),
    .cpu_dout(cpu_dout[31:0]),
    // to cpu (out)
    .cpu_din(cpu_din[31:0]),
    .cpu_ack(cpu_ack)
  );

  cpu_core_x #(.start_addr(start_addr)) cpu_core_0 ( // gray
    .clk(clk),
    .rst(rst),
    // to bus (out)
    .bus_stb(cpu_stb),
    .bus_we(cpu_we),
    .bus_ben(cpu_ben),
    .bus_addr(cpu_addr[23:0]),
    .bus_dout(cpu_dout[31:0]),
    // from bus (in)
    .bus_din(cpu_din[31:0]),
    .bus_ack(cpu_ack),
    // gray
    .spx_out(spx[31:0]),
    .lnkx_out(lnkx[31:0]),
    .pcx_out(pcx[23:0]),
    .irx_out(irx[31:0])
  );

endmodule

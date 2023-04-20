/**
  Calltrace stack
  --
  Instantiate 'num_stacks' calltrace stacks with 'num_slots' slots each.
  --
  The calltrace stack is selected by input 'cp_pid' from the SCS.

  The selected calltrace stack registers
  1) the entry into a procedure, pushing the LNK value
  2) the exit from a procedure, popping the topmost LNK value
  Hence, at any point, the stack represents a backtrace of procedure calls, a "stack trace".

  For this, the IR (instruction register) of the CPU is monitored for corresponding
  push and pop instructions.

  The stacked LNK data can be read without popping the stack, to be able to get a trace
  at any time without losing the stacked data.
  --
  Controls data_in[7:0]:
  [1]: clear stack as given by ctrl_data
  [2]: freeze stack as given by ctrl_data
  [3]: unfreeze stack as given by ctrl_data
  [4]: block all hw-push
  [5]: unblock, ie. allow hw-push

  Control data_in[13:8];
  [5:0] stack number
  --
  (c) 2021 - 2023 Gray, gray@grayraven.org
  https://oberon-rts.org/licences
**/

`timescale 1ns / 1ps
`default_nettype none

module calltrace (
  input wire clk,
  input wire stb,
  input wire we,
  input wire addr,
  input wire [31:0] ir_in,        // instruction register value
  input wire [23:0] lnk_in,       // LNK register value
  input wire [4:0] cp_pid,        // current process' pid
  input wire [23:0] data_in,
  output wire [31:0] data_out,
  output wire ack
);

  localparam num_stacks = 32;
  localparam num_slots = 32;
  localparam data_width = 24;

  wire wr_data = stb &  we & ~addr;     // write to the selected stack (push, no effect in frozen state)
  wire rd_data = stb & ~we & ~addr;     // read from the selected stack, data depends on frozen state
  wire wr_ctrl = stb &  we & addr;      // write control data
  wire rd_ctrl = stb & ~we & addr;      // read control/status data

  // split ctrl data_in
  wire [7:0] ctrl = data_in[7:0];
  wire [5:0] ctrl_data = data_in[13:8];

  // controls
  wire wr_clear     = wr_ctrl & ctrl[1];    // clear a stack
  wire wr_freeze    = wr_ctrl & ctrl[2];    // freeze current stack
  wire wr_unfreeze  = wr_ctrl & ctrl[3];    // unfreeze current stack
  wire wr_block     = wr_ctrl & ctrl[4];    // block all hw-registering of calls
  wire wr_unblock   = wr_ctrl & ctrl[5];    // unblock hw-registering of calls

  // push and pop signals
  wire push_trig = (ir_in == 32'hAFE00000) ? 1'b1 : 1'b0;  // push trigger: STW LNK, SP, 0
  wire pop_trig = (ir_in == 32'hC700000F) ? 1'b1 : 1'b0;   // pop trigger: B LNK

  reg push_trig0, pop_trig0;                 // edge pulse signals
  wire push_p = push_trig & ~push_trig0;     // push edge pulse
  wire pop_p = pop_trig & ~pop_trig0;        // pop edge pulse

  reg blocked;
  initial blocked = 1'b0;

  // actual push and pop signals
  wire push_c = wr_data | (~blocked & push_p);
  wire pop_c = rd_data | (~blocked & pop_p);

  // stacks input data
  wire [23:0] stack_din = wr_data ? data_in[23:0] : lnk_in[23:0];

  // control and output signals for individual stacks
  wire [num_stacks-1:0] push, pop, read, rst, freeze, unfreeze;
  wire [num_stacks-1:0] empty, full, ovfl, frozen;

  // output muxers from the stacks
  wire [7:0] count [num_stacks-1:0];
  wire [7:0] max_count [num_stacks-1:0];
  wire [23:0] stack_data_out_mux [num_stacks-1:0];
  wire [23:0] stack_ctrl_out_mux [num_stacks-1:0];

  always @(posedge clk) begin
    push_trig0 <= push_trig;
    pop_trig0 <= pop_trig;
    blocked <= wr_block ? 1'b1 : wr_unblock ? 1'b0 : blocked;
  end

  // generate the stacks
  genvar j;
  generate
    for (j = 0; j < num_stacks; j = j+1) begin: ct_stacks
      // control signals
      assign push[j] = push_c & (cp_pid == j);
      assign pop[j] = pop_c & (cp_pid == j);
      assign read[j] = rd_data & (cp_pid == j);
      assign freeze[j] = wr_freeze & (cp_pid == j);
      assign unfreeze[j] = wr_unfreeze & (cp_pid == j);
      assign rst[j] = wr_clear & (ctrl_data == j);

      stackx #(.data_width(data_width), .num_slots(num_slots)) stackx_0 (
        // in
        .clk(clk),
        .rst(rst[j]),
        .push(push[j]),
        .pop(pop[j]),
        .read(read[j]),
        .freeze(freeze[j]),
        .unfreeze(unfreeze[j]),
        .data_in(stack_din),
        // out
        .empty(empty[j]),
        .full(full[j]),
        .ovfl(ovfl[j]),
        .frozen(frozen[j]),
        .count(count[j]),
        .max_count(max_count[j]),
        .data_out(stack_data_out_mux[j])
      );
      // status signals
      assign stack_ctrl_out_mux[j] = {max_count[j], count[j], 4'b0, frozen[j], ovfl[j], full[j], empty[j]};
    end
  endgenerate

  assign data_out[31:0] =
    rd_data ? {8'b0, stack_data_out_mux[cp_pid]} :
    rd_ctrl ? {3'b0, cp_pid[4:0], stack_ctrl_out_mux[cp_pid]} :
    32'b0;

  assign ack = stb;

endmodule

`resetall

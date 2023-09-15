/**
  RISC5 CPU
  --
  With interrupt and floating-point
  --
  Architecture: ETH
  --
  Design:
    * Project Oberon, NW 31.8.2018
    * Embedded Project Oberon, CFB 13.10.2021
  --
  Changes by gray@grayraven.org
  * make externally available several registers: SP, LNK, IR, SPC, PC
  * make externally available several signals: intAck, RTI
  * non-returning interrupt funcationality (intabort)
  * parameterised start address
  * wait_req input signal
**/

`timescale 1ns / 1ps
`default_nettype none

module risc5_2 #(
  parameter
    start_addr = 24'hFFE000
  )(
  input wire clk, rst, irq, wait_req,
  input wire [31:0] inbus, codebus,
  input wire intabort,           // ** gray: abort interrupt: load address 0 = abort handler as return address for interrupt
  output wire intackx, rtix,     // ** gray: 'intAck' and 'RTI' signal for external interrupt controller
  output wire [31:0] spx,        // ** gray: stack pointer value (reg 14)
  output wire [31:0] lnkx,       // ** gray: link register value (reg 15)
  output wire [31:0] irx,        // ** gray: instruction register value
  output wire [23:0] spcx,       // ** gray: saved PC on interrupt
  output wire [21:0] pcx,        // ** gray: PC
  output wire [23:0] adr,
  output wire rd, wr, ben,
  output wire [31:0] outbus
);

  localparam StartAdr = start_addr[23:2];   // PC is adr[23:2]
  localparam IsrAdr = 1;

  reg [21:0] PC;    // program counter
  reg [31:0] IR;    // instruction register
  reg N, Z, C, OV;  // condition flags
  reg [31:0] H;     // aux register

  wire [21:0] pcmux, pcmux0, nxpc;
  wire cond, S;
  wire sa, sb, sc;

  // instruction fields
  wire p, q, u, v;
  wire [3:0] op, ira, ira0, irb, irc;
  wire [2:0] cc;
  wire [15:0] imm;
  wire [19:0] off;
  wire [21:0] disp;

  reg stallL1;
  wire stall, stallL0, stallM, stallD, stallFA, stallFM, stallFD;
  wire nn, zz, cx, vv;

  // interrupts
  reg irq1, intEnb, intPnd, intMd;
  reg [25:0] SPC;     // saved PC on interrupt
  wire intAck;

  // ALU, arith units
  wire regwr;
  wire [31:0] A, B, C0, C1, aluRes, regmux, inbus1;
  wire [31:0] lshout, rshout;
  wire [31:0] quotient, remainder;
  wire [63:0] product;
  wire [31:0] fsum, fprod, fquot;

  wire ADD, SUB, MUL, DIV;
  wire FAD, FSB, FML, FDV;
  wire LDR, STR, BR, RTI;

  // gray: externalised signals
  assign intackx = intAck;          // 'intAck' signal for external interrupt controller
  assign rtix = RTI;                // 'RTI' signal for external interrupt controller
  assign spcx = {SPC[21:0], 2'b0};  // interrupt return address for abort handler = offending location
  assign irx = IR;                  // instruction register value for calltrace stack
  assign pcx = PC;                  // program counter for calltrace stack
  // gray end

  Registers regs (
    // in
    .clk(clk),
    .rst(rst),
    .en(~wait_req),
    .wr(regwr),
    .rno0(ira0),
    .rno1(irb),
    .rno2(irc),
    .din(regmux),
    // out
    .dout0(A),
    .dout1(B),
    .dout2(C0)
  );

  Multiplier mulUnit (
    // in
    .clk(clk),
    .en(~wait_req),
    .run(MUL),
    .u(~u),
    .x(B),
    .y(C1),
    // out
    .stall(stallM),
    .z(product)
  );

  Divider divUnit (
    // in
    .clk(clk),
    .en(~wait_req),
    .run(DIV),
    .u(~u),
    .x(B),
    .y(C1),
    // out
    .stall(stallD),
    .quot(quotient),
    .rem(remainder)
  );

  LeftShifter LSUnit (
    // in
    .x(B),
    .sc(C1[4:0]),
    // out
    .y(lshout)
  );

  RightShifter RSUnit (
    // in
    .x(B),
    .sc(C1[4:0]),
    .md(IR[16]),
    // out
    .y(rshout)
  );

  FPAdder fpaddx (
    // in
    .clk(clk),
    .en(~wait_req),
    .run(FAD|FSB),
    .u(u),
    .v(v),
    .x(B),
    .y({FSB^C0[31], C0[30:0]}),
    // out
    .stall(stallFA),
    .z(fsum)
  );

  FPMultiplier fpmulx (
    // in
    .clk(clk),
    .en(~wait_req),
    .run(FML),
    .x(B),
    .y(C0),
    // out
    .stall(stallFM),
    .z(fprod)
  );

  FPDivider fpdivx (
    // in
    .clk(clk),
    .en(~wait_req),
    .run(FDV),
    .x(B),
    .y(C0),
    // out
    .stall(stallFD),
    .z(fquot)
  );

  // ** gray: stack pointer and link register values
  reg [31:0] SP, LNK;
  always @(posedge clk) begin
    if (~wait_req) begin
      SP <= (regwr & (ira0 == 14)) ? regmux : SP;
      LNK <= (regwr & (ira0 == 15)) ? regmux : LNK;
    end
  end
  assign spx = SP;
  assign lnkx = LNK;
  // ** gray end

  assign p = IR[31];
  assign q = IR[30];
  assign u = IR[29];
  assign v = IR[28];
  assign cc  = IR[26:24];
  assign ira = IR[27:24];
  assign irb = IR[23:20];
  assign op  = IR[19:16];
  assign irc = IR[3:0];
  assign imm = IR[15:0];   // reg instr.
  assign off = IR[19:0];   // mem instr.
  assign disp = IR[21:0];  // branch instr.

  assign ADD = ~p & (op == 8);
  assign SUB = ~p & (op == 9);
  assign MUL = ~p & (op == 10);
  assign DIV = ~p & (op == 11);
  assign FAD = ~p & (op == 12);
  assign FSB = ~p & (op == 13);
  assign FML = ~p & (op == 14);
  assign FDV = ~p & (op == 15);

  assign LDR = p & ~q & ~u;
  assign STR = p & ~q & u;
  assign BR = p & q;
  assign RTI = BR & ~u & ~v & IR[4];

  // Arithmetic-logical unit (ALU)
  assign ira0 = BR ? 4'd15 : ira;
  assign C1 = q ? {{16{v}}, imm} : C0;
  assign adr = stallL0 ? B[23:0] + {{4{off[19]}}, off} : {pcmux, 2'b00};
  assign rd = LDR & ~stallL1;
  assign wr = STR & ~stallL1;
  assign ben = p & ~q & v & ~stallL1;  // byte enable

  assign aluRes[31:0] =
    ~op[3] ? (            // 0xxx
      ~op[2] ? (          // 00xx
        ~op[1] ? (        // 000x
          ~op[0] ? (      // 0000: MOV
            q ?
              (~u ? {{16{v}}, imm} : {imm, 16'b0}) :              // q
              (~u ? C0 : (~v ? H : {N, Z, C, OV, 20'b0, 8'h53}))  // ~q
            ) :           // 0001: LSL
            lshout
          ) :             // 001x: ASR, ROR
          rshout
        ) : (             // 01xx
        ~op[1] ?
          (~op[0] ? B & C1 : B & ~C1) : // 0100: AND, 0101: ANN
          (~op[0] ? B | C1 : B ^ C1)    // 0110: IOR, 0111: XOR
        )
      ) : (         // 1xxx
      ~op[2] ? (    // 10xx
        ~op[1] ?
          (~op[0] ? B + C1 + (u & C) : B - C1 - (u & C)) :  // 1000: ADD, 1001: SUB
          (~op[0] ? product[31:0] : quotient)               // 1010: MUL, 1011: DIV
        ) : (       // 11xx floating point
        ~op[1] ?    // 110x
          fsum :    // 1100: FAD, 1101: FSB
          (~op[0] ? fprod : fquot)    // 1110: FML, 1111: FDV
        )
      );

  assign regwr = ~p & ~stall | (LDR & ~stallL1) | (BR & cond & v);

  assign regmux = LDR ? inbus1 : (BR & v) ? {8'b0, nxpc, 2'b0} : aluRes;

  assign inbus1 = ~ben ? inbus :
    {24'b0, (adr[1] ? (adr[0] ? inbus[31:24] : inbus[23:16]) :
            (adr[0] ? inbus[15:8] : inbus[7:0]))};

  assign outbus = ~ben ? A :
    adr[1] ? (
      adr[0] ? {A[7:0], 24'b0} : {8'b0, A[7:0], 16'b0}
    ) : (
      adr[0] ? {16'b0, A[7:0], 8'b0} : {24'b0, A[7:0]}
    );

  // Control unit CU
  assign S = N ^ OV;
  assign nxpc = PC + 22'd1;
  assign cond = IR[27] ^ (
    (cc == 0) & N |       // MI, PL
    (cc == 1) & Z |       // EQ, NE
    (cc == 2) & C |       // CS, CC
    (cc == 3) & OV |      // VS, VC
    (cc == 4) & (C|Z) |   // LS, HI
    (cc == 5) & S |       // LT, GE
    (cc == 6) & (S|Z) |   // LE, GT
    (cc == 7)             // T, F
  );

  assign intAck = intPnd & intEnb & ~intMd & ~stall;

  assign pcmux = ~rst | stall | intAck | RTI ?
    (~rst | stall ?
      (~rst ? StartAdr[21:0] : PC) :
      (intAck ? IsrAdr[21:0] : SPC[21:0])  // if intAck | RTI
    ) : pcmux0;

  assign pcmux0 = (BR & cond) ? (u ? nxpc + disp : (IR[7] ? C0[23:0] + nxpc : C0[23:2])) : nxpc;

  assign sa = aluRes[31];
  assign sb = B[31];
  assign sc = C1[31];

  assign nn = RTI ? SPC[25] : regwr ? regmux[31] : N;
  assign zz = RTI ? SPC[24] : regwr ? (regmux == 32'b0) : Z;
  assign cx = RTI ? SPC[23] :
    ADD ? ((~sb & sc & ~sa) | (sb & sc & sa) | (sb & ~sa)) :
    SUB ? ((~sb & sc & ~sa) | (sb & sc & sa) | (~sb & sa)) : C;
  assign vv = RTI ? SPC[22] :
    ADD ? ((sa & ~sb & ~sc) | (~sa & sb & sc)) :
    SUB ? ((sa & ~sb & sc) | (~sa & sb & ~sc)) : OV;

  assign stallL0 = (LDR | STR) & ~stallL1;
  assign stall = stallL0 | stallM | stallD | stallFA | stallFM | stallFD;

  always @ (posedge clk) begin
    if (~wait_req) begin
      PC <= pcmux;
      IR <= stall ? IR : codebus;
      stallL1 <= stallL0;
      N <= nn;
      Z <= zz;
      C <= cx;
      OV <= vv;
      H <= MUL ? product[63:32] : DIV ? remainder : H;

      irq1 <= irq;  // edge detector
      intPnd <= rst & ~intAck & ((~irq1 & irq) | intPnd);
      intMd <= rst & ~RTI & (intAck | intMd);
      intEnb <= ~rst ? 0 : (BR & ~u & ~v & IR[5]) ? IR[0] : intEnb;
      // ** gray: intabort: load address 0 = abort handler as return address, cond flags are zero (don't matter
      SPC <= (intAck) ? {nn, zz, cx, vv, pcmux0} : intabort ? {26'b0} : SPC;
    end
  end
endmodule

`resetall

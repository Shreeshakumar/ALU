`timescale 1ns / 1ps
 
module tb_Design1;
 
parameter N = 8;
 
reg CLK, RST, MODE, CE, CIN;
reg [N-1:0] OPA, OPB;
reg [1:0] IN_VALID;
reg [3:0] CMD;
 
wire ERR, OFLOW, COUT, G, L, E;
wire [2*N-1:0] RES;
 
alu_design #(.N(N)) dut (
    .CLK(CLK), .RST(RST), .MODE(MODE), .CE(CE), .CIN(CIN),
    .OPA(OPA), .OPB(OPB), .INP_VALID(IN_VALID), .CMD(CMD),
    .ERR(ERR), .RES(RES), .OFLOW(OFLOW), .COUT(COUT),
    .G(G), .L(L), .E(E)
);
 
always #5 CLK = ~CLK;
 
initial begin
#10;
    CLK=0; RST=1; CE=0; MODE=0; CIN=0;
    OPA=0; OPB=0; IN_VALID=0; CMD=0;
    #20;
    RST=0; CE=1;
    #10;
 
    // ---- ARITHMETIC MODE ----
 
    // ADD
    MODE=1; CMD=4'd0; OPA=8'd100; OPB=8'd50; IN_VALID=2'b11; CIN=0;
    #10;
 
    // SUB
    CMD=4'd1; OPA=8'd100; OPB=8'd30; IN_VALID=2'b11;
    #10;
 
    // SUB underflow
    CMD=4'd1; OPA=8'd30; OPB=8'd100; IN_VALID=2'b11;
    #10;
 
    // ADD_CIN
    CMD=4'd2; OPA=8'd100; OPB=8'd50; IN_VALID=2'b11; CIN=1;
    #10;
 
    // SUB_CIN
    CMD=4'd3; OPA=8'd100; OPB=8'd50; IN_VALID=2'b11; CIN=1;
    #10;
 
    // INC_A
    CMD=4'd4; OPA=8'd10; IN_VALID=2'b01;
    #10;
 
    // DEC_A
    CMD=4'd5; OPA=8'd10; IN_VALID=2'b01;
    #10;
 
    // INC_B
    CMD=4'd6; OPB=8'd20; IN_VALID=2'b10;
    #10;
 
    // DEC_B
    CMD=4'd7; OPB=8'd20; IN_VALID=2'b10;
    #10;
 
    // CMP A>B
    CMD=4'd8; OPA=8'd100; OPB=8'd50; IN_VALID=2'b11;
    #10;
 
    // CMP A<B
    CMD=4'd8; OPA=8'd50; OPB=8'd100; IN_VALID=2'b11;
    #10;
 
    // CMP A==B
    CMD=4'd8; OPA=8'd50; OPB=8'd50; IN_VALID=2'b11;
    #10;
 
    // CMD=9 : (A+1)*(B+1) -- 3 cycle operation
    // OPA=4, OPB=5 => (5)*(6) = 30
    CMD=4'd9; OPA=8'd4; OPB=8'd5; IN_VALID=2'b11;
    #10; // cycle 1
    #10; // cycle 2
     OPB=8'd7; // cycle 3 : RES = 30
    #10;
      CMD=4'd9; OPA=8'd4;  IN_VALID=2'b11;
    #10; // cycle 1
    #10; // cycle 2
    #10; // cycle 3 : RES = 30
 
    // CMD=10 : (A<<1)*B => (3<<1)*5 = 30
    CMD=4'd10; OPA=8'd3; OPB=8'd5; IN_VALID=2'b11;
    #50;
 
    // Signed ADD
    CMD=4'd11; OPA=8'd50; OPB=8'd30; IN_VALID=2'b11;
    #10;
 
    // Signed ADD overflow
    CMD=4'd11; OPA=8'd100; OPB=8'd100; IN_VALID=2'b11;
    #10;
 
    // Signed SUB
    CMD=4'd12; OPA=8'd80; OPB=8'd30; IN_VALID=2'b11;
    #10;
 
    // Signed SUB overflow
    CMD=4'd12; OPA=8'd100; OPB=8'hA0; IN_VALID=2'b11;
    #10;
 
    // ---- LOGICAL MODE ----
    MODE=0; CIN=0;
 
    // AND
    CMD=4'd0; OPA=8'hAA; OPB=8'hF0; IN_VALID=2'b11;
    #10;
 
    // NAND
    CMD=4'd1; OPA=8'hAA; OPB=8'hF0; IN_VALID=2'b11;
    #10;
 
    // OR
    CMD=4'd2; OPA=8'hAA; OPB=8'h55; IN_VALID=2'b11;
    #10;
 
    // NOR
    CMD=4'd3; OPA=8'hAA; OPB=8'h55; IN_VALID=2'b11;
    #10;
 
    // XOR
    CMD=4'd4; OPA=8'hAA; OPB=8'hFF; IN_VALID=2'b11;
    #10;
 
    // XNOR
    CMD=4'd5; OPA=8'hAA; OPB=8'hFF; IN_VALID=2'b11;
    #10;
 
    // NOT_A
    CMD=4'd6; OPA=8'hAA; IN_VALID=2'b01;
    #10;
 
    // NOT_B
    CMD=4'd7; OPB=8'hAA; IN_VALID=2'b10;
    #10;
 
    // SHR1_A
    CMD=4'd8; OPA=8'hAA; IN_VALID=2'b01;
    #10;
 
    // SHL1_A
    CMD=4'd9; OPA=8'h55; IN_VALID=2'b01;
    #10;
 
    // SHR1_B
    CMD=4'd10; OPB=8'hAA; IN_VALID=2'b10;
    #10;
 
    // SHL1_B
    CMD=4'd11; OPB=8'h55; IN_VALID=2'b10;
    #10;
 
    // ROL by 1
    CMD=4'd12; OPA=8'hB4; OPB=8'h01; IN_VALID=2'b11;
    #10;
 
    // ROL by 4
    CMD=4'd12; OPA=8'hB4; OPB=8'h04; IN_VALID=2'b11;
    #10;
 
    // ROL with ERR
    CMD=4'd12; OPA=8'hB4; OPB=8'h12; IN_VALID=2'b11;
    #10;
 
    // ROR by 1
    CMD=4'd13; OPA=8'hB4; OPB=8'h01; IN_VALID=2'b11;
    #10;
 
    // ROR by 4
    CMD=4'd13; OPA=8'hB4; OPB=8'h04; IN_VALID=2'b11;
    #10;
 
    // ROR with ERR
    CMD=4'd13; OPA=8'hB4; OPB=8'h13; IN_VALID=2'b11;
    #10;
 
    // RST test
    RST=1; #10; RST=0;
    #10;
 
    $finish;
end
 
initial begin
    $monitor("T=%0t MODE=%b CMD=%0d OPA=%0d OPB=%0d IN_VALID=%b CIN=%b | RES=%0d COUT=%b OFLOW=%b G=%b L=%b E=%b ERR=%b",
              $time, MODE, CMD, OPA, OPB, IN_VALID, CIN, RES, COUT, OFLOW, G, L, E, ERR);
end
 
initial begin
    $dumpfile("tb_Design1.vcd");
    $dumpvars(0, tb_Design1);
end
 
endmodule

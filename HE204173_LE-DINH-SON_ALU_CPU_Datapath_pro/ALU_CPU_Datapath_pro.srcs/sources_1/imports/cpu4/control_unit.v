// =====================================================================
// FILE: control_unit.v  -  hardwired control
//   instruction_decoder : DECODE stage, opcode -> control word (no clock)
//   branch_unit         : EXECUTE stage, decides jump + flush
//   control_unit        : wraps both
//
// Control word layout (11 bits):
//   {alu_ctrl[2:0], alu_src_sel, wb_sel, reg_we, mem_we,
//    zero_we, carry_we, is_jmp, is_jz}
// Reserved opcodes 1100-1111 give the all-zero word = NOP.
// =====================================================================
module instruction_decoder (
    input      [3:0] opcode,
    output     [2:0] alu_ctrl,
    output           alu_src_sel,
    output           wb_sel,
    output           reg_we,
    output           mem_we,
    output           zero_we,
    output           carry_we,
    output           is_jmp,
    output           is_jz
);
    // ALU codes (must match alu.v)
    localparam [2:0] A_ADD = 3'd0, A_SUB = 3'd1, A_AND = 3'd2, A_OR  = 3'd3,
                     A_XOR = 3'd4, A_NOT = 3'd5, A_PASS = 3'd6;

    reg [10:0] cw;
    assign {alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we,
            zero_we, carry_we, is_jmp, is_jz} = cw;

    //                    alu     src wb  rwe mwe zwe cwe jmp jz
    always @(*) begin
        case (opcode)
            4'b0000: cw = {A_ADD , 1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0}; // ADD
            4'b0001: cw = {A_SUB , 1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0}; // SUB
            4'b0010: cw = {A_AND , 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0}; // AND
            4'b0011: cw = {A_OR  , 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0}; // OR
            4'b0100: cw = {A_XOR , 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0}; // XOR
            4'b0101: cw = {A_NOT , 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0}; // NOT
            4'b0110: cw = {A_PASS, 1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0}; // LDI
            4'b0111: cw = {A_PASS, 1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0}; // MOV
            4'b1000: cw = {A_PASS, 1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0}; // LOAD
            4'b1001: cw = {A_PASS, 1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0}; // STORE
            4'b1010: cw = {A_ADD , 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0}; // JMP
            4'b1011: cw = {A_ADD , 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1}; // JZ
            default: cw = 11'b000_0000_0000;                                  // reserved = NOP
        endcase
    end
endmodule

module branch_unit (
    input  is_jmp,
    input  is_jz,
    input  zero_flag,
    output pc_sel,
    output flush
);
    assign pc_sel = is_jmp | (is_jz & zero_flag);
    assign flush  = pc_sel;
endmodule

module control_unit (
    // ---- DECODE stage ----
    input  [3:0] opcode,
    output [2:0] alu_ctrl,
    output       alu_src_sel,
    output       wb_sel,
    output       reg_we,
    output       mem_we,
    output       zero_we,
    output       carry_we,
    output       is_jmp,
    output       is_jz,
    // ---- EXECUTE stage ----
    input        ex_is_jmp,
    input        ex_is_jz,
    input        zero_flag,
    output       pc_sel,
    output       flush
);
    instruction_decoder DECODER (
        .opcode(opcode), .alu_ctrl(alu_ctrl), .alu_src_sel(alu_src_sel),
        .wb_sel(wb_sel), .reg_we(reg_we), .mem_we(mem_we),
        .zero_we(zero_we), .carry_we(carry_we),
        .is_jmp(is_jmp), .is_jz(is_jz)
    );
    branch_unit BRANCH (
        .is_jmp(ex_is_jmp), .is_jz(ex_is_jz), .zero_flag(zero_flag),
        .pc_sel(pc_sel), .flush(flush)
    );
endmodule

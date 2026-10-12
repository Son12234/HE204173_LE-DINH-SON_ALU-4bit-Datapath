// =====================================================================
// FILE: cpu_top.v  -  4-bit RISC CPU, 3-stage pipeline (IF / ID / EX)
// Only CONNECTS the blocks.
//   STAGE 1 IF : PC MUX -> PC -> instruction memory -> IF/ID (IR)
//   STAGE 2 ID : decoder -> ID/EX register
//   STAGE 3 EX : register read -> operand MUX -> ALU -> data memory
//                -> write-back MUX -> Rd, flags, branch decision
// Instruction: [11:8] opcode | [7:6] Rd | [5:4] Rs | [3:0] imm/addr
// A taken jump (decided in EX) flushes the 2 younger instructions.
// =====================================================================
module cpu_top #(
    parameter PROGRAM_FILE = "program.mem"
)(
    input         clk,
    input         rst,
    output [3:0]  pc_out,        // fetch address
    output [11:0] instr_out,     // instruction currently in EX
    output [3:0]  alu_out,       // ALU result
    output [3:0]  wb_data_out,   // value going into Rd
    output        zero_out,      // stored Zero flag
    output        carry_out      // stored Carry flag
);
    // ------------------------- signal declarations -------------------------
    // IF
    wire [3:0]  pc, pc_plus_1, pc_next;
    wire [11:0] fetched;
    // IF/ID
    wire [11:0] id_instr;
    wire [3:0]  id_pc;
    wire        id_valid;
    // ID
    wire [3:0]  id_opcode = id_instr[11:8];
    wire [1:0]  id_rd     = id_instr[7:6];
    wire [1:0]  id_rs     = id_instr[5:4];
    wire [3:0]  id_imm    = id_instr[3:0];
    wire [2:0]  id_alu_ctrl;
    wire        id_alu_src_sel, id_wb_sel, id_reg_we, id_mem_we;
    wire        id_zero_we, id_carry_we, id_is_jmp, id_is_jz;
    // ID/EX
    wire [2:0]  ex_alu_ctrl;
    wire        ex_alu_src_sel, ex_wb_sel, ex_reg_we, ex_mem_we;
    wire        ex_zero_we, ex_carry_we, ex_is_jmp, ex_is_jz;
    wire [1:0]  ex_rd, ex_rs;
    wire [3:0]  ex_imm, ex_pc;
    wire        ex_valid;
    wire [11:0] ex_instr;
    // EX
    wire [3:0]  rd_value, rs_value, alu_b, alu_result, mem_data, wb_data;
    wire        alu_zero, alu_carry;
    wire        zero_flag, carry_flag;
    wire        pc_sel, flush;

    // =========================== STAGE 1 : IF ===========================
    assign pc_plus_1 = pc + 4'd1;                       // wraps 15 -> 0

    mux2 PC_MUX (.d0(pc_plus_1), .d1(ex_imm), .sel(pc_sel), .y(pc_next));

    program_counter PC (.clk(clk), .rst(rst), .pc_en(1'b1),
                        .pc_next(pc_next), .pc_out(pc));

    instruction_memory #(.PROGRAM_FILE(PROGRAM_FILE)) IMEM (
        .address(pc), .instruction(fetched));

    instruction_register IR (
        .clk(clk), .rst(rst), .ir_load(1'b1), .flush(flush),
        .instruction_in(fetched), .pc_in(pc),
        .instruction_out(id_instr), .pc_out(id_pc), .valid_out(id_valid));

    // =========================== STAGE 2 : ID ===========================
    control_unit CU (
        .opcode(id_opcode),
        .alu_ctrl(id_alu_ctrl), .alu_src_sel(id_alu_src_sel),
        .wb_sel(id_wb_sel), .reg_we(id_reg_we), .mem_we(id_mem_we),
        .zero_we(id_zero_we), .carry_we(id_carry_we),
        .is_jmp(id_is_jmp), .is_jz(id_is_jz),
        .ex_is_jmp(ex_is_jmp), .ex_is_jz(ex_is_jz), .zero_flag(zero_flag),
        .pc_sel(pc_sel), .flush(flush));

    pipeline_register ID_EX (
        .clk(clk), .rst(rst), .flush(flush),
        .alu_ctrl_in(id_alu_ctrl), .alu_src_sel_in(id_alu_src_sel),
        .wb_sel_in(id_wb_sel), .reg_we_in(id_reg_we), .mem_we_in(id_mem_we),
        .zero_we_in(id_zero_we), .carry_we_in(id_carry_we),
        .is_jmp_in(id_is_jmp), .is_jz_in(id_is_jz),
        .rd_in(id_rd), .rs_in(id_rs), .imm_in(id_imm),
        .pc_in(id_pc), .valid_in(id_valid), .instr_in(id_instr),
        .alu_ctrl(ex_alu_ctrl), .alu_src_sel(ex_alu_src_sel),
        .wb_sel(ex_wb_sel), .reg_we(ex_reg_we), .mem_we(ex_mem_we),
        .zero_we(ex_zero_we), .carry_we(ex_carry_we),
        .is_jmp(ex_is_jmp), .is_jz(ex_is_jz),
        .rd(ex_rd), .rs(ex_rs), .imm(ex_imm),
        .pc(ex_pc), .valid(ex_valid), .instr(ex_instr));

    // =========================== STAGE 3 : EX ===========================
    register_file RF (
        .clk(clk), .rst(rst),
        .ra(ex_rd), .rb(ex_rs),            // A = Rd, B = Rs
        .wa(ex_rd), .wd(wb_data), .we(ex_reg_we),
        .qa(rd_value), .qb(rs_value));

    mux2 OPERAND_MUX (.d0(rs_value), .d1(ex_imm), .sel(ex_alu_src_sel), .y(alu_b));

    alu ALU (.a(rd_value), .b(alu_b), .alu_ctrl(ex_alu_ctrl),
             .result(alu_result), .carry(alu_carry), .zero(alu_zero));

    flag_register FLAGS (
        .clk(clk), .rst(rst),
        .zero_we(ex_zero_we), .carry_we(ex_carry_we),
        .zero_in(alu_zero), .carry_in(alu_carry),
        .zero_flag(zero_flag), .carry_flag(carry_flag));

    data_memory DMEM (
        .clk(clk), .address(alu_result), .write_data(rd_value),
        .mem_we(ex_mem_we), .read_data(mem_data));

    mux2 WB_MUX (.d0(alu_result), .d1(mem_data), .sel(ex_wb_sel), .y(wb_data));

    // ------------------------------ debug outputs ------------------------------
    assign pc_out      = pc;
    assign instr_out   = ex_instr;
    assign alu_out     = alu_result;
    assign wb_data_out = wb_data;
    assign zero_out    = zero_flag;
    assign carry_out   = carry_flag;
endmodule

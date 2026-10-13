// =====================================================================
// FILE: pipeline_register.v  -  ID/EX pipeline register
// Copies decoder outputs + instruction fields from ID to EX each clock.
// rst or flush -> every control signal 0 (bubble: EX changes nothing).
// =====================================================================
module pipeline_register (
    input             clk,
    input             rst,
    input             flush,
    // ---- from DECODE ----
    input      [2:0]  alu_ctrl_in,
    input             alu_src_sel_in,
    input             wb_sel_in,
    input             reg_we_in,
    input             mem_we_in,
    input             zero_we_in,
    input             carry_we_in,
    input             is_jmp_in,
    input             is_jz_in,
    input      [1:0]  rd_in,
    input      [1:0]  rs_in,
    input      [3:0]  imm_in,
    input      [3:0]  pc_in,
    input             valid_in,
    input      [11:0] instr_in,
    // ---- to EXECUTE ----
    output reg [2:0]  alu_ctrl,
    output reg        alu_src_sel,
    output reg        wb_sel,
    output reg        reg_we,
    output reg        mem_we,
    output reg        zero_we,
    output reg        carry_we,
    output reg        is_jmp,
    output reg        is_jz,
    output reg [1:0]  rd,
    output reg [1:0]  rs,
    output reg [3:0]  imm,
    output reg [3:0]  pc,
    output reg        valid,
    output reg [11:0] instr
);
    initial begin
        {alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we,
         zero_we, carry_we, is_jmp, is_jz} = 11'd0;
        {rd, rs, imm, pc} = 12'd0;
        valid = 1'b0;
        instr = 12'hC00;
    end

    always @(posedge clk) begin
        if (rst | flush) begin
            {alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we,
             zero_we, carry_we, is_jmp, is_jz} <= 11'd0;
            {rd, rs, imm, pc} <= 12'd0;
            valid <= 1'b0;
            instr <= 12'hC00;
        end else begin
            {alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we,
             zero_we, carry_we, is_jmp, is_jz}
                <= {alu_ctrl_in, alu_src_sel_in, wb_sel_in, reg_we_in, mem_we_in,
                    zero_we_in, carry_we_in, is_jmp_in, is_jz_in};
            {rd, rs, imm, pc} <= {rd_in, rs_in, imm_in, pc_in};
            valid <= valid_in;
            instr <= instr_in;
        end
    end
endmodule

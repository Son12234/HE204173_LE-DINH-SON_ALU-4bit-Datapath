`timescale 1ns / 1ps
// MODULE TEST 3: decoder (all 16 opcodes) + branch unit (6 cases). 22 checks.
module tb_control_unit;
    reg  [3:0] opcode = 0;
    reg        ex_is_jmp = 0, ex_is_jz = 0, zero_flag = 0;
    wire [2:0] alu_ctrl;
    wire       alu_src_sel, wb_sel, reg_we, mem_we, zero_we, carry_we, is_jmp, is_jz;
    wire       pc_sel, flush;
    integer    errors = 0, tests = 0, k;

    control_unit DUT (
        .opcode(opcode), .alu_ctrl(alu_ctrl), .alu_src_sel(alu_src_sel),
        .wb_sel(wb_sel), .reg_we(reg_we), .mem_we(mem_we),
        .zero_we(zero_we), .carry_we(carry_we), .is_jmp(is_jmp), .is_jz(is_jz),
        .ex_is_jmp(ex_is_jmp), .ex_is_jz(ex_is_jz), .zero_flag(zero_flag),
        .pc_sel(pc_sel), .flush(flush));

    wire [10:0] got = {alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we,
                       zero_we, carry_we, is_jmp, is_jz};

    // expected decoder table (truth table, Table 17), index = opcode
    // {alu[2:0] src wb rwe mwe zwe cwe jmp jz}
    reg [10:0] want [0:15];
    initial begin
        want[0]  = 11'b000_0_0_1_0_1_1_0_0;  // ADD
        want[1]  = 11'b001_0_0_1_0_1_1_0_0;  // SUB
        want[2]  = 11'b010_0_0_1_0_1_0_0_0;  // AND
        want[3]  = 11'b011_0_0_1_0_1_0_0_0;  // OR
        want[4]  = 11'b100_0_0_1_0_1_0_0_0;  // XOR
        want[5]  = 11'b101_0_0_1_0_1_0_0_0;  // NOT
        want[6]  = 11'b110_1_0_1_0_0_0_0_0;  // LDI
        want[7]  = 11'b110_0_0_1_0_0_0_0_0;  // MOV
        want[8]  = 11'b110_1_1_1_0_0_0_0_0;  // LOAD
        want[9]  = 11'b110_1_0_0_1_0_0_0_0;  // STORE
        want[10] = 11'b000_0_0_0_0_0_0_1_0;  // JMP
        want[11] = 11'b000_0_0_0_0_0_0_0_1;  // JZ
        want[12] = 11'b0; want[13] = 11'b0; want[14] = 11'b0; want[15] = 11'b0; // reserved
    end

    task branch_case;
        input [8*22:1] name;
        input jmp, jz, z, exp_sel;
        begin
            ex_is_jmp = jmp; ex_is_jz = jz; zero_flag = z; #1;
            tests = tests + 1;
            if (pc_sel === exp_sel && flush === exp_sel)
                $display("PASS %0s pc_sel=%b flush=%b", name, pc_sel, flush);
            else begin
                errors = errors + 1;
                $display("FAIL %0s pc_sel=%b flush=%b (expected %b)", name, pc_sel, flush, exp_sel);
            end
        end
    endtask

    initial begin
        $display("\n===== tb_control_unit: control unit test =====");
        $display("--- Part A: decoder (DECODE stage) ---");
        for (k = 0; k < 16; k = k + 1) begin
            opcode = k[3:0]; #1;
            tests = tests + 1;
            if (got === want[k])
                $display("PASS opcode %b  alu=%0d src=%b wb=%b rwe=%b mwe=%b zwe=%b cwe=%b jmp=%b jz=%b",
                         opcode, alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we,
                         zero_we, carry_we, is_jmp, is_jz);
            else begin
                errors = errors + 1;
                $display("FAIL opcode %b  got %b, expected %b", opcode, got, want[k]);
            end
        end
        $display("--- Part B: branch unit (EXECUTE stage) ---");
        //            name                   jmp jz  Z  pc_sel
        branch_case("no jump instruction",   1'b0,1'b0,1'b0,1'b0);
        branch_case("no jump, Zero = 1",     1'b0,1'b0,1'b1,1'b0);
        branch_case("JMP",                   1'b1,1'b0,1'b0,1'b1);
        branch_case("JMP (Zero = 1)",        1'b1,1'b0,1'b1,1'b1);
        branch_case("JZ with Zero = 0",      1'b0,1'b1,1'b0,1'b0);
        branch_case("JZ with Zero = 1",      1'b0,1'b1,1'b1,1'b1);

        if (errors == 0) $display("tb_control_unit PASSED: %0d of %0d checks OK\n", tests, tests);
        else             $display("tb_control_unit FAILED: %0d of %0d checks failed\n", errors, tests);
        $finish;
    end
endmodule

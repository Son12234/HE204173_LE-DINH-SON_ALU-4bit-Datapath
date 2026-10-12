`timescale 1ns / 1ps
// =====================================================================
// CPU-LEVEL TEST (44 checks)
//   TEST 1 program.mem    : demonstration program + pipeline trace
//   TEST 2 prog_arith.mem : ADD, SUB, Carry, STORE, LOAD, Zero
//   TEST 3 prog_logic.mem : AND, OR, XOR, MOV, NOT, LDI, Zero
//   TEST 4 prog_jump.mem  : PC increment, JMP, JZ taken / not taken, flush
//   TEST 5 reset          : reset values, no X values
// Hierarchical names (CPU.RF.regs[n], CPU.IMEM.mem, CPU.DMEM.mem) are
// simulation-only.
// =====================================================================
module tb_cpu;
    reg  clk = 0, rst = 1;
    integer errors = 0, checks = 0, cycle = 0, k, guard;
    reg  trace_all = 0;

    always #5 clk = ~clk;                       // 10 ns period

    wire [3:0]  pc_out, alu_out, wb_data_out;
    wire [11:0] instr_out;
    wire        zero_out, carry_out;

    cpu_top #(.PROGRAM_FILE("program.mem")) CPU (
        .clk(clk), .rst(rst), .pc_out(pc_out), .instr_out(instr_out),
        .alu_out(alu_out), .wb_data_out(wb_data_out),
        .zero_out(zero_out), .carry_out(carry_out));

    // clock-cycle counter (counts only while reset is released)
    always @(posedge clk) cycle <= rst ? 0 : cycle + 1;

    // ----------------------------- trace -----------------------------
    always @(negedge clk) if (!rst) begin
        if (trace_all) begin
            $write("  cycle %2d | IF: addr %2d | ID: ", cycle + 1, CPU.pc);
            if (CPU.id_valid) $write("%h (addr %2d)", CPU.id_instr, CPU.id_pc);
            else              $write("bubble       ");
            $write(" | EX: ");
            if (CPU.ex_valid) $write("%h (addr %2d)", CPU.ex_instr, CPU.ex_pc);
            else              $write("bubble       ");
            $display(" | R1=%b R2=%b R3=%b", CPU.RF.regs[1], CPU.RF.regs[2], CPU.RF.regs[3]);
        end else if (CPU.ex_valid)
            $display("  EX addr %2d: %h | R0=%b R1=%b R2=%b R3=%b | Z=%b C=%b",
                     CPU.ex_pc, CPU.ex_instr, CPU.RF.regs[0], CPU.RF.regs[1],
                     CPU.RF.regs[2], CPU.RF.regs[3], zero_out, carry_out);
    end

    // ----------------------------- helpers -----------------------------
    task hold_reset;                 // reset for 2 clocks, then release
        begin
            rst = 1;
            repeat (2) @(posedge clk);
            #1 rst = 0;
        end
    endtask

    task load_prog;                  // new program, clear data memory, assert reset
        input [8*20:1] fname;
        begin
            rst = 1;
            for (k = 0; k < 16; k = k + 1) begin
                CPU.IMEM.mem[k] = 12'hC00;
                CPU.DMEM.mem[k] = 4'b0000;
            end
            $readmemh(fname, CPU.IMEM.mem);
        end
    endtask

    // wait until the instruction fetched from 'addr' sits in EX and its
    // result has been written (just after the next rising edge)
    task done;
        input [3:0] addr;
        begin
            guard = 0;
            @(negedge clk);
            while (!(CPU.ex_valid && CPU.ex_pc == addr) && guard < 200) begin
                @(negedge clk);
                guard = guard + 1;
            end
            if (guard >= 200) begin
                $display("FAIL timeout waiting for addr %0d", addr);
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
        end
    endtask

    task chk4;
        input [8*44:1] name;
        input [3:0] got, want;
        begin
            checks = checks + 1;
            if (got === want) $display("PASS %0s = %b", name, got);
            else begin
                errors = errors + 1;
                $display("FAIL %0s = %b (expected %b)", name, got, want);
            end
        end
    endtask

    task chk1;
        input [8*44:1] name;
        input got, want;
        begin
            checks = checks + 1;
            if (got === want) $display("PASS %0s = %b", name, got);
            else begin
                errors = errors + 1;
                $display("FAIL %0s = %b (expected %b)", name, got, want);
            end
        end
    endtask

    // ----------------------------- tests -----------------------------
    initial begin
        $dumpfile("tb_cpu.vcd");
        $dumpvars(0, tb_cpu);

        // ============ TEST 1 : demonstration program ============
        $display("\n===== TEST 1: demonstration program (program.mem) =====");
        trace_all = 1;
        hold_reset;
        done(2);
        chk4("ADD R1,R2 -> R1 (5+3)", CPU.RF.regs[1], 4'b1000);
        done(4);
        chk4("LDI R3,1010 -> R3", CPU.RF.regs[3], 4'b1010);
        chk4("XOR R1,R3 -> R1",   CPU.RF.regs[1], 4'b0010);
        chk4("R2 still 0011",     CPU.RF.regs[2], 4'b0011);
        $display("  5 instructions finished after %0d clock cycles", cycle);
        done(5);
        chk4("JMP 0101: PC (fetch address) = 5", pc_out, 4'd5);
        done(5);
        trace_all = 0;
        chk4("JMP runs again: program loops at 5", pc_out, 4'd5);

        // ============ TEST 2 : arithmetic and memory ============
        $display("\n===== TEST 2: arithmetic and memory (prog_arith.mem) =====");
        load_prog("prog_arith.mem");
        hold_reset;
        done(2);
        chk4("ADD R1,R2 (0101+0011) -> R1", CPU.RF.regs[1], 4'b1000);
        chk1("ADD: Carry", carry_out, 1'b0);
        chk1("ADD: Zero",  zero_out,  1'b0);
        done(3);
        chk4("STORE R1,0 -> data_memory[0]", CPU.DMEM.mem[0], 4'b1000);
        done(5);
        chk4("SUB R1,R2 (0101-0011) -> R1", CPU.RF.regs[1], 4'b0010);
        chk1("SUB: Zero", zero_out, 1'b0);
        chk1("SUB: Carry (1 = no borrow)", carry_out, 1'b1);
        done(6);
        chk4("STORE R1,1 -> data_memory[1]", CPU.DMEM.mem[1], 4'b0010);
        done(7);
        chk4("LOAD R0,0 -> R0", CPU.RF.regs[0], 4'b1000);
        done(8);
        chk4("SUB R2,R2 -> R2", CPU.RF.regs[2], 4'b0000);
        chk1("Zero flag after 0000 result", zero_out, 1'b1);
        $display("  9 instructions finished after %0d clock cycles (pipeline: 9 + 2)", cycle);

        // ============ TEST 3 : logic, MOV, NOT, LDI ============
        $display("\n===== TEST 3: logic operations (prog_logic.mem) =====");
        load_prog("prog_logic.mem");
        hold_reset;
        done(3);  chk4("AND 1100,1010 -> R3", CPU.RF.regs[3], 4'b1000);
        done(5);  chk4("OR 1100,1010 -> R3",  CPU.RF.regs[3], 4'b1110);
        done(6);  chk4("XOR 1100,1010 -> R1", CPU.RF.regs[1], 4'b0110);
        done(7);  chk4("MOV R2,R1 (R1=0110) -> R2", CPU.RF.regs[2], 4'b0110);
        done(9);  chk4("NOT 0101 -> R0",      CPU.RF.regs[0], 4'b1010);
        done(10); chk4("LDI R3,1010 -> R3",   CPU.RF.regs[3], 4'b1010);
        done(11);
        chk4("XOR R3,R3 -> R3", CPU.RF.regs[3], 4'b0000);
        chk1("Zero flag after 0000 result", zero_out, 1'b1);
        $display("  12 instructions finished after %0d clock cycles (pipeline: 12 + 2)", cycle);

        // ============ TEST 4 : PC and jumps ============
        $display("\n===== TEST 4: PC and jumps (prog_jump.mem) =====");
        load_prog("prog_jump.mem");
        repeat (2) @(posedge clk);
        #1;
        chk4("PC after reset", pc_out, 4'd0);
        rst = 0;
        @(posedge clk); #1;
        chk4("PC increment (0 -> 1)", pc_out, 4'd1);
        done(1);
        chk4("JMP 4: PC becomes 0100", pc_out, 4'b0100);
        chk1("JMP flushed the ID/EX register", CPU.ex_valid, 1'b0);
        done(5);
        chk1("SUB R1,R1 sets Zero", zero_out, 1'b1);
        done(6);
        chk4("JZ 9 taken: PC = 9", pc_out, 4'd9);
        done(10);
        chk1("ADD R3,R3 clears Zero", zero_out, 1'b0);
        done(11);
        chk4("JZ 14 not taken: next in EX is addr 12", CPU.ex_pc, 4'd12);
        done(13);
        chk4("R0 = 1 (JMP skipped addresses 2, 3)",     CPU.RF.regs[0], 4'd1);
        chk4("R2 = 6 (JZ skipped 7, 8; 14 never ran)",  CPU.RF.regs[2], 4'd6);
        chk4("Program stops at PC = 13", pc_out, 4'd13);

        // ============ TEST 5 : reset and unknown values ============
        $display("\n===== TEST 5: reset =====");
        rst = 1;
        @(posedge clk); #1;
        chk4("PC after reset",  pc_out, 4'd0);
        chk4("R0 after reset", CPU.RF.regs[0], 4'd0);
        chk4("R2 after reset", CPU.RF.regs[2], 4'd0);
        chk1("Zero after reset",  zero_out,  1'b0);
        chk1("Carry after reset", carry_out, 1'b0);
        chk1("IF/ID empty after reset", CPU.id_valid, 1'b0);
        chk1("ID/EX empty after reset", CPU.ex_valid, 1'b0);
        rst = 0;
        repeat (6) @(posedge clk);
        #1;
        // reduction XOR is X if ANY bit is X
        checks = checks + 1;
        if ((^{pc_out, instr_out, alu_out, wb_data_out, zero_out, carry_out,
               CPU.RF.regs[0], CPU.RF.regs[1], CPU.RF.regs[2], CPU.RF.regs[3]}) === 1'bx) begin
            errors = errors + 1;
            $display("FAIL unknown (X) value found on key outputs");
        end else
            $display("PASS no unknown (X) values on key outputs or registers");

        $display("\n==================================================");
        if (errors == 0) $display("tb_cpu PASSED: %0d of %0d checks OK", checks, checks);
        else             $display("tb_cpu FAILED: %0d of %0d checks failed", errors, checks);
        $display("==================================================\n");
        $finish;
    end

    // global watchdog
    initial begin #200000; $display("FAIL global timeout"); $finish; end
endmodule

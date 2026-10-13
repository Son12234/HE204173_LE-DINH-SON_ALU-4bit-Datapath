`timescale 1ns / 1ps
// MODULE TEST 1: ALU (no clock). 11 checks.
module tb_alu;
    reg  [3:0] a, b;
    reg  [2:0] alu_ctrl;
    wire [3:0] result;
    wire       carry, zero;
    integer    errors = 0, tests = 0;

    alu DUT (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .carry(carry), .zero(zero));

    task run;
        input [8*12:1] name;
        input [3:0] ia, ib;
        input [2:0] op;
        input [3:0] e_res;
        input       e_cy, e_z;
        begin
            a = ia; b = ib; alu_ctrl = op; #10;
            tests = tests + 1;
            if ({result, carry, zero} === {e_res, e_cy, e_z})
                $display("PASS %0s a=%b b=%b -> result=%b carry=%b zero=%b", name, a, b, result, carry, zero);
            else begin
                errors = errors + 1;
                $display("FAIL %0s a=%b b=%b -> result=%b carry=%b zero=%b", name, a, b, result, carry, zero);
                $display("     expected result=%b carry=%b zero=%b", e_res, e_cy, e_z);
            end
        end
    endtask

    initial begin
        $display("\n===== tb_alu: ALU module test =====");
        //  name           a      b      op    result C Z
        run("ADD 5+3     ", 4'b0101, 4'b0011, 3'd0, 4'b1000, 1'b0, 1'b0);
        run("ADD 15+1    ", 4'b1111, 4'b0001, 3'd0, 4'b0000, 1'b1, 1'b1);
        run("SUB 5-3     ", 4'b0101, 4'b0011, 3'd1, 4'b0010, 1'b1, 1'b0);
        run("SUB 3-5     ", 4'b0011, 4'b0101, 3'd1, 4'b1110, 1'b0, 1'b0);
        run("SUB 7-7     ", 4'b0111, 4'b0111, 3'd1, 4'b0000, 1'b1, 1'b1);
        run("AND         ", 4'b1100, 4'b1010, 3'd2, 4'b1000, 1'b0, 1'b0);
        run("OR          ", 4'b1100, 4'b1010, 3'd3, 4'b1110, 1'b0, 1'b0);
        run("XOR         ", 4'b1100, 4'b1010, 3'd4, 4'b0110, 1'b0, 1'b0);
        run("XOR to zero ", 4'b0110, 4'b0110, 3'd4, 4'b0000, 1'b0, 1'b1);
        run("NOT 0101    ", 4'b0101, 4'b0000, 3'd5, 4'b1010, 1'b0, 1'b0);
        run("PASS b      ", 4'b0000, 4'b1001, 3'd6, 4'b1001, 1'b0, 1'b0);

        if (errors == 0) $display("tb_alu PASSED: %0d of %0d tests OK\n", tests, tests);
        else             $display("tb_alu FAILED: %0d of %0d tests failed\n", errors, tests);
        $finish;
    end
endmodule

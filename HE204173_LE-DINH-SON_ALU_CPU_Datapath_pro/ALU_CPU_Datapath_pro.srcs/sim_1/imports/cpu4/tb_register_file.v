`timescale 1ns / 1ps
// MODULE TEST 2: register file. 11 checks.
module tb_register_file;
    reg        clk = 0, rst = 1, we = 0;
    reg  [1:0] ra = 0, rb = 0, wa = 0;
    reg  [3:0] wd = 0;
    wire [3:0] qa, qb;
    integer    errors = 0, tests = 0;

    always #5 clk = ~clk;

    register_file DUT (.clk(clk), .rst(rst), .ra(ra), .rb(rb), .wa(wa),
                       .wd(wd), .we(we), .qa(qa), .qb(qb));

    task expect4;
        input [8*26:1] name;
        input [3:0] got, want;
        begin
            tests = tests + 1;
            if (got === want) $display("PASS %0s = %b", name, got);
            else begin
                errors = errors + 1;
                $display("FAIL %0s = %b (expected %b)", name, got, want);
            end
        end
    endtask

    task put;                       // one write = one clock edge
        input [1:0] addr;
        input [3:0] data;
        begin
            wa = addr; wd = data; we = 1;
            @(posedge clk); #1; we = 0;
        end
    endtask

    initial begin
        $display("\n===== tb_register_file: register file test =====");
        // reset
        @(posedge clk); #1; rst = 0;
        ra = 0; rb = 3; #1;
        expect4("after reset R0 (port A)", qa, 4'b0000);
        expect4("after reset R3 (port B)", qb, 4'b0000);
        // write all four registers
        put(2'd0, 4'b0001);
        put(2'd1, 4'b0101);
        put(2'd2, 4'b1010);
        put(2'd3, 4'b1111);
        // read back on both ports
        ra = 0; rb = 1; #1;
        expect4("R0 on port A", qa, 4'b0001);
        expect4("R1 on port B", qb, 4'b0101);
        ra = 2; rb = 3; #1;
        expect4("R2 on port A", qa, 4'b1010);
        expect4("R3 on port B", qb, 4'b1111);
        ra = 1; rb = 1; #1;
        expect4("R1 on both ports (A)", qa, 4'b0101);
        expect4("R1 on both ports (B)", qb, 4'b0101);
        // we = 0 must not write
        wa = 2; wd = 4'b0000; we = 0;
        @(posedge clk); #1;
        ra = 2; #1;
        expect4("R2 unchanged when we=0", qa, 4'b1010);
        // second reset
        rst = 1; @(posedge clk); #1; rst = 0;
        ra = 3; rb = 2; #1;
        expect4("R3 after second reset", qa, 4'b0000);
        expect4("R2 after second reset", qb, 4'b0000);

        if (errors == 0) $display("tb_register_file PASSED: %0d of %0d checks OK\n", tests, tests);
        else             $display("tb_register_file FAILED: %0d of %0d checks failed\n", errors, tests);
        $finish;
    end
endmodule

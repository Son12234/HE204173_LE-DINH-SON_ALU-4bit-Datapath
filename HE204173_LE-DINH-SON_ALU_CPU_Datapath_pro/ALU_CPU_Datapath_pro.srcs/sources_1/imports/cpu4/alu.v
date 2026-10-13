// =====================================================================
// FILE: alu.v  -  4-bit ALU (purely combinational)
// Interface : a[3:0], b[3:0], alu_ctrl[2:0], result[3:0], carry, zero
// Sub-modules in this file: adder_subtractor, logic_unit,
//                           zero_detector, alu
//
// alu_ctrl : 0 ADD | 1 SUB | 2 AND | 3 OR | 4 XOR | 5 NOT | 6 PASS(b)
//
// CARRY CONVENTION (ALU, flag register, testbenches):
//   ADD : carry = carry-out of bit 3 (1 = result did not fit in 4 bits)
//   SUB : carry = 1 when a >= b (NO BORROW), 0 when a < b (borrow)
//   logic / PASS : carry = 0 (and the CPU never stores it)
// =====================================================================

// ---- adder / subtractor: A - B is built as A + ~B + 1 ----
module adder_subtractor (
    input  [3:0] a,
    input  [3:0] b,
    input        do_sub,      // 0 = add, 1 = subtract
    output [3:0] result,
    output       carry
);
    wire [3:0] b_eff = b ^ {4{do_sub}};                        // invert B for SUB
    wire [4:0] total = {1'b0, a} + {1'b0, b_eff} + {4'b0, do_sub}; // do_sub = carry-in
    assign result = total[3:0];
    assign carry  = total[4];                                   // carry-out / no-borrow
endmodule

// ---- logic unit: AND, OR, XOR, NOT, PASS ----
module logic_unit (
    input      [3:0] a,
    input      [3:0] b,
    input      [2:0] alu_ctrl,
    output reg [3:0] result
);
    always @(*) begin
        case (alu_ctrl)
            3'd2:    result = a & b;   // AND
            3'd3:    result = a | b;   // OR
            3'd4:    result = a ^ b;   // XOR
            3'd5:    result = ~a;      // NOT (uses A only)
            3'd6:    result = b;       // PASS B
            default: result = 4'b0000;
        endcase
    end
endmodule

// ---- zero detector ----
module zero_detector (
    input  [3:0] value,
    output       zero
);
    assign zero = ~(|value);           // 1 only when all four bits are 0
endmodule

// ---- top ALU ----
module alu (
    input  [3:0] a,
    input  [3:0] b,
    input  [2:0] alu_ctrl,
    output [3:0] result,
    output       carry,
    output       zero
);
    wire [3:0] ar_res, lg_res;
    wire       ar_cy;

    wire is_sub   = (alu_ctrl == 3'd1);
    wire is_arith = (alu_ctrl == 3'd0) | is_sub;

    adder_subtractor U_ARITH (.a(a), .b(b), .do_sub(is_sub),
                              .result(ar_res), .carry(ar_cy));
    logic_unit       U_LOGIC (.a(a), .b(b), .alu_ctrl(alu_ctrl),
                              .result(lg_res));

    assign result = is_arith ? ar_res : lg_res;
    assign carry  = is_arith ? ar_cy  : 1'b0;

    zero_detector    U_ZERO  (.value(result), .zero(zero));
endmodule

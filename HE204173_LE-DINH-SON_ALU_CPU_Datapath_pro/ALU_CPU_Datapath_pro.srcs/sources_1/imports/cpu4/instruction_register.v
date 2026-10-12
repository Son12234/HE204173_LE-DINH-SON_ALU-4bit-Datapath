// =====================================================================
// FILE: instruction_register.v  -  IF/ID pipeline register (the IR)
// Interface : clk, rst, ir_load, instruction_in, instruction_out
// Pipeline extras : flush, pc_in, pc_out, valid_out
// reset / flush -> NOP (C00), valid = 0 (bubble)
// =====================================================================
module instruction_register (
    input             clk,
    input             rst,
    input             ir_load,
    input             flush,
    input      [11:0] instruction_in,
    input      [3:0]  pc_in,
    output reg [11:0] instruction_out,
    output reg [3:0]  pc_out,
    output reg        valid_out
);
    localparam [11:0] NOP = 12'hC00;

    initial begin
        instruction_out = NOP;
        pc_out          = 4'd0;
        valid_out       = 1'b0;
    end

    always @(posedge clk) begin
        if (rst | flush) begin
            instruction_out <= NOP;
            pc_out          <= 4'd0;
            valid_out       <= 1'b0;
        end else if (ir_load) begin
            instruction_out <= instruction_in;
            pc_out          <= pc_in;
            valid_out       <= 1'b1;
        end
    end
endmodule

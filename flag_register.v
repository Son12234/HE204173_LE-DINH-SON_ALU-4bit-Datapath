// =====================================================================
// FILE: flag_register.v  -  stored Zero and Carry flags
// Separate write enables: logic ops update Zero only, ADD/SUB both.
// =====================================================================
module flag_register (
    input      clk,
    input      rst,
    input      zero_we,
    input      carry_we,
    input      zero_in,
    input      carry_in,
    output reg zero_flag,
    output reg carry_flag
);
    initial begin
        zero_flag  = 1'b0;
        carry_flag = 1'b0;
    end

    always @(posedge clk) begin
        if (rst) begin
            zero_flag  <= 1'b0;
            carry_flag <= 1'b0;
        end else begin
            zero_flag  <= zero_we  ? zero_in  : zero_flag;
            carry_flag <= carry_we ? carry_in : carry_flag;
        end
    end
endmodule

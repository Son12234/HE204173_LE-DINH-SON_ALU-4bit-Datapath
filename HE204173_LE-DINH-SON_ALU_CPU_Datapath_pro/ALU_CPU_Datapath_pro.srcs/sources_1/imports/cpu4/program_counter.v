// =====================================================================
// FILE: program_counter.v
// Interface : clk, rst, pc_en, pc_next, pc_out
// Holds the FETCH address. cpu_top keeps pc_en = 1 (fetch every clock).
// =====================================================================
module program_counter (
    input            clk,
    input            rst,
    input            pc_en,
    input      [3:0] pc_next,
    output reg [3:0] pc_out
);
    initial pc_out = 4'd0;

    always @(posedge clk) begin
        if (rst)        pc_out <= 4'd0;
        else if (pc_en) pc_out <= pc_next;
    end
endmodule

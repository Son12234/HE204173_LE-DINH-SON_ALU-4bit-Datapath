// =====================================================================
// FILE: register_file.v  -  R0..R3, 4 bits each
// Interface : clk, rst, ra, rb, wa, wd, we, qa, qb
// Two combinational read ports, one clocked write port.
// r0..r3 are extra wires so the registers can be added to a waveform.
// =====================================================================
module register_file (
    input        clk,
    input        rst,
    input  [1:0] ra,      // read address, port A
    input  [1:0] rb,      // read address, port B
    input  [1:0] wa,      // write address
    input  [3:0] wd,      // write data
    input        we,      // write enable
    output [3:0] qa,      // read data, port A
    output [3:0] qb       // read data, port B
);
    reg [3:0] regs [0:3];
    integer n;

    // power-up value 0 (no X before the first reset edge)
    initial for (n = 0; n < 4; n = n + 1) regs[n] = 4'b0000;

    // synchronous write, synchronous reset
    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < 4; n = n + 1) regs[n] <= 4'b0000;
        end else if (we) begin
            regs[wa] <= wd;
        end
    end

    // combinational reads
    assign qa = regs[ra];
    assign qb = regs[rb];

    // convenience names for waveform viewers
    wire [3:0] r0 = regs[0];
    wire [3:0] r1 = regs[1];
    wire [3:0] r2 = regs[2];
    wire [3:0] r3 = regs[3];
endmodule

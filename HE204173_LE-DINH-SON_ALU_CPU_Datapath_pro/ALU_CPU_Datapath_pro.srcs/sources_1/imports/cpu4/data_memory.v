// =====================================================================
// FILE: data_memory.v  -  16 x 4-bit data RAM (Harvard: separate from ROM)
// Interface : clk, address, write_data, mem_we, read_data
// Combinational read (LOAD), clocked write (STORE).
// =====================================================================
module data_memory (
    input        clk,
    input  [3:0] address,
    input  [3:0] write_data,
    input        mem_we,
    output [3:0] read_data
);
    reg [3:0] mem [0:15];
    integer m;

    initial for (m = 0; m < 16; m = m + 1) mem[m] = 4'b0000;

    always @(posedge clk)
        if (mem_we) mem[address] <= write_data;

    assign read_data = mem[address];
endmodule

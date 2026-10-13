// =====================================================================
// FILE: instruction_memory.v  -  16 x 12-bit ROM loaded from a .mem file
// Interface : address[3:0], instruction[11:0]
// Unused words hold C00 (reserved opcode = NOP), never X.
// =====================================================================
module instruction_memory #(
    parameter PROGRAM_FILE = "program.mem"
)(
    input  [3:0]  address,
    output [11:0] instruction
);
    reg [11:0] mem [0:15];
    integer j;

    initial begin
        for (j = 0; j < 16; j = j + 1) mem[j] = 12'hC00;
        $readmemh(PROGRAM_FILE, mem);      // one hex word per line
    end

    assign instruction = mem[address];
endmodule

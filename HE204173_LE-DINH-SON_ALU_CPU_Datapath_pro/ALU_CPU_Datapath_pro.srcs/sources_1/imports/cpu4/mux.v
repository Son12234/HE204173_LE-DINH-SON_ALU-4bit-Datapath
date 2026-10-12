// =====================================================================
// FILE: mux.v  -  2-input 4-bit multiplexer (sel = 0 -> d0, 1 -> d1)
// Used 3 times: operand MUX, write-back MUX, PC MUX.
// =====================================================================
module mux2 (
    input  [3:0] d0,
    input  [3:0] d1,
    input        sel,
    output [3:0] y
);
    assign y = sel ? d1 : d0;
endmodule

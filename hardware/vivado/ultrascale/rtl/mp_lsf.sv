`timescale 1ns / 1ps

`include "def.sv"

// dynamic left shifter, c = a << b
module mp_lsf #(
    parameter N = 8,
    parameter S = 3
) (
    input  logic [N-1:0] a,
    input  logic [S-1:0] b,
    output logic [N-1:0] c
);

    logic [N-1:0] tmp[S-1:0];
    assign tmp[0] = b[0] ? a << 1 : a;
    genvar i;
    generate
        for (i = 1; i < S; i = i + 1) begin
            assign tmp[i] = b[i] ? tmp[i-1] << 2 ** i : tmp[i-1];
        end
    endgenerate
    assign c = tmp[S-1];

endmodule

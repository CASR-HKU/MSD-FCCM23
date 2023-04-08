`timescale 1ns / 1ps

`include "def.sv"

// original design
// module bit_serial_mul #(
//     parameter IDX_DW = `HW_IDX_DW,
//     parameter ACT_DW = `HW_ACT_DW,
//     parameter PSU_DW = `HW_PSU_DW
// ) (
//     // input  logic              clk,
//     // input  logic              rst_n,
//     input  logic [PSU_DW-1:0] act_in,
//     input  logic [IDX_DW-1:0] wgt_in,
//     output logic [PSU_DW-1:0] psu_out
// );

//     // 2's complement with MSB
//     logic [ACT_DW-1:0] act_s;
//     assign act_s = (wgt_in == 3'd7) ? (act_in[PSU_DW-1:ACT_DW]) : act_in[ACT_DW-1:0];

//     logic [PSU_DW-1:0] pp_lsf;
//     mp_lsf #(
//         .N(PSU_DW),
//         .S(IDX_DW)
//     ) mp_lsf_inst (
//         .a({{(PSU_DW - ACT_DW) {1'b0}}, act_s}),
//         .b(IDX_DW),
//         .c(pp_lsf)
//     );

//     assign psu_out = pp_lsf;

// endmodule

module bit_serial_mul #(
    parameter IDX_DW = `HW_IDX_DW,
    parameter ACT_DW = `HW_ACT_DW,
    parameter PSU_DW = `HW_PSU_DW
) (
    input  logic [ACT_DW-1:0] act_in,
    input  logic [IDX_DW-1:0] wgt_in,
    output logic [PSU_DW-1:0] psu_out
);

    logic [ACT_DW + ACT_DW/2-1:0] pp_lsf;
    logic [ACT_DW-1:0] act_in_neg;

    assign act_in_neg = (wgt_in[IDX_DW-1] == 1'b1) ? (~act_in) : act_in;

    mp_lsf #(
        .N(ACT_DW + ACT_DW/2),
        .S(IDX_DW)
    ) mp_lsf_inst (
        .a({{(ACT_DW/2) {1'b0}}, act_in}),
        .b(wgt_in),
        .c(pp_lsf)
    );

    assign psu_out = pp_lsf[(PSU_DW+PSU_DW/2-1):(PSU_DW-PSU_DW/2)];

endmodule

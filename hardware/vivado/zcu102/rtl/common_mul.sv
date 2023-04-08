`timescale 1ns / 1ps

`include "def.sv"

(*use_dsp = "no"*)
module common_mul #(
    parameter WGT_DW = `HW_WGT_DW,
    parameter ACT_DW = `HW_ACT_DW,
    parameter PSU_DW = `HW_PSU_DW
) (
    input  logic              clk,
    input  logic              rst_n,
    input  logic [ACT_DW-1:0] act_in,
    input  logic [WGT_DW-1:0] wgt_in,
    output logic [PSU_DW-1:0] psu_out
);

    logic signed [  ACT_DW-1:0] act_in_s;
    logic signed [  WGT_DW-1:0] wgt_in_s;
    logic signed [2*ACT_DW-1:0] psu_tmp;

    assign act_in_s = act_in;
    assign wgt_in_s = wgt_in;
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            psu_tmp <= 0;
        end else begin
            psu_tmp <= act_in_s * wgt_in_s;
        end
    end
    assign psu_out = psu_tmp[(PSU_DW+PSU_DW/2-1):(PSU_DW-PSU_DW/2)];

endmodule

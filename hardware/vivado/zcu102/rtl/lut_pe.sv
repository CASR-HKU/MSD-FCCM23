`timescale 1ns / 1ps

`include "def.sv"

// The dataflow is fixed as input stationary
(* keep_hierarchy = "yes" *)
module lut_pe #(
    parameter VER_BUS_DW = `HW_LUT_VER_BUS_DW,
    parameter HOR_BUS_DW = `HW_LUT_HOR_BUS_DW,
    parameter IDX_DW     = `HW_IDX_DW,
    parameter WGT_DW     = `HW_WGT_DW,
    parameter ACT_DW     = `HW_ACT_DW,
    parameter PSU_DW     = `HW_PSU_DW
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  psum_sel,
    input  logic [HOR_BUS_DW-1:0] left_in,
    input  logic [VER_BUS_DW-1:0] top_in,
    output logic [HOR_BUS_DW-1:0] right_out,
    output logic [VER_BUS_DW-1:0] bottom_out
);

    logic [HOR_BUS_DW - 1:0] left_in_reg;
    logic [VER_BUS_DW - 1:0] psum_acc;
    logic [VER_BUS_DW - 1:0] psum_out;
    logic [VER_BUS_DW - 1:0] adder_out;

    // regs
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            left_in_reg <= 0;
        end else begin
            left_in_reg <= left_in;
        end
    end

    assign right_out  = left_in_reg;

`ifdef BIT_SERIAL
    bit_serial_mul #(
        .IDX_DW(IDX_DW),
        .ACT_DW(ACT_DW),
        .PSU_DW(PSU_DW)
    ) bit_serial_mul_inst (
        .act_in (top_in),
        .wgt_in (left_in),
        .psu_out(psum_out)
    );

`else
    common_mul #(
        .ACT_DW(ACT_DW),
        .WGT_DW(WGT_DW),
        .PSU_DW(PSU_DW)
    ) common_mul_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .act_in (top_in),
        .wgt_in (left_in),
        .psu_out(psum_out)
    );
`endif

    assign adder_out = psum_out + psum_acc;

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            psum_acc <= 0;
        end else begin
            psum_acc <= adder_out;
        end
    end

    logic [VER_BUS_DW-1:0] bottom_o_reg;
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            bottom_o_reg <= 0;
        end else begin
            bottom_o_reg <= psum_sel ? psum_acc : top_in;
        end
    end
    assign bottom_out = bottom_o_reg;

endmodule

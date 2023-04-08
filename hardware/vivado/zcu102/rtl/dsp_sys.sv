`timescale 1ns / 1ps

`include "def.sv"

// systolic array
(* keep_hierarchy = "yes" *)
module dsp_sys #(
    parameter ROWS       = `HW_DSP_PE_ROWS,
    parameter COLS       = `HW_DSP_PE_COLS,
    parameter VER_BUS_DW = `HW_DSP_VER_BUS_DW,
    parameter HOR_BUS_DW = `HW_DSP_HOR_BUS_DW
) (
    // common signals
    input  logic                                  clk,
    input  logic                                  rst_n,
    // input activations from shared buffer
    input  logic                                  psum_sel,
    input  logic [      COLS-1:0][VER_BUS_DW-1:0] act_in,
    // weights (index) from external
    input  logic [      ROWS-1:0][HOR_BUS_DW-1:0] wgt_idx,
    // output partial sums
    output logic [      COLS-1:0][VER_BUS_DW-1:0] psu_out
);

    // preload activation wires
    genvar r, c;

    // connections for PE
    (* dont_touch = "true" *) logic [ROWS-1:0][COLS-1:0][HOR_BUS_DW-1:0] row_connections;
    (* dont_touch = "true" *) logic [ROWS-1:0][COLS-1:0][VER_BUS_DW-1:0] col_connections;

    generate
        // systolic PEs
        for (r = 0; r < ROWS; r = r + 1) begin
            for (c = 0; c < COLS; c = c + 1) begin
                if ((r == 0) && (c == 0)) begin
                    // left top
                    dsp_pe dsp_pe_lt_inst (
                        .clk       (clk),
                        .rst_n     (rst_n),
                        .psum_sel  (psum_sel),
                        .left_in   (wgt_idx[r]),
                        .top_in    (act_in[c]),
                        .right_out (row_connections[r][c]),
                        .bottom_out(col_connections[r][c])
                    );
                end else if (c == 0) begin
                    // first column
                    dsp_pe dsp_pe_fc_inst (
                        .clk       (clk),
                        .rst_n     (rst_n),
                        .psum_sel  (psum_sel),
                        .left_in   (wgt_idx[r]),
                        .top_in    (col_connections[r-1][c]),
                        .right_out (row_connections[r][c]),
                        .bottom_out(col_connections[r][c])
                    );
                end else if (r == 0) begin
                    // first row
                    dsp_pe dsp_pe_fr_inst (
                        .clk       (clk),
                        .rst_n     (rst_n),
                        .psum_sel  (psum_sel),
                        .left_in   (row_connections[r][c-1]),
                        .top_in    (act_in[c]),
                        .right_out (row_connections[r][c]),
                        .bottom_out(col_connections[r][c])
                    );
                end else begin
                    // normal PE
                    dsp_pe dsp_pe_nm_inst (
                        .clk       (clk),
                        .rst_n     (rst_n),
                        .psum_sel  (psum_sel),
                        .left_in   (row_connections[r][c-1]),
                        .top_in    (col_connections[r-1][c]),
                        .right_out (row_connections[r][c]),
                        .bottom_out(col_connections[r][c])
                    );
                end
            end
        end
    endgenerate

    generate
        for (c = 0; c < COLS; c++) begin
            assign psu_out[c] = col_connections[ROWS-1][c];
        end
    endgenerate

endmodule

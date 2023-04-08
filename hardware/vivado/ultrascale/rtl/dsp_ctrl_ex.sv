`timescale 1ns / 1ps

`include "def.sv"

module dsp_ctrl_ex #(
    parameter ROWS              = `HW_DSP_PE_ROWS,
    parameter COLS              = `HW_DSP_PE_COLS,
    parameter BP_ACT_BUF_DEPTH  = `HW_BP_ACT_BUF_DEPTH,
    parameter BP_WGT_BUF_DEPTH  = `HW_BP_WGT_BUF_DEPTH,
    parameter BP_OUT_BUF_DEPTH  = `HW_BP_OUT_BUF_DEPTH
) (
    input  logic                        clk,
    input  logic                        rst_n,
    // tile size, updated when bp_ex_tile_start asserted
    input  logic [7:0]                  bp_subtile_K, // subtile of K (COLS)
    input  logic [7:0]                  bp_subtile_HW, // subtile of HW (ROWS)
    input  logic [23:0]                 bp_opt_subtile_HWCIJ, // for better timing
    input  logic [15:0]                 bp_subtile_CIJ, // subtile of CIJ (dataflow depth)
    // control signals
    input  logic                        bp_ex_tile_start,
    output logic [BP_ACT_BUF_DEPTH-1:0] bp_act_buf_ex_addr,
    output logic [BP_WGT_BUF_DEPTH-1:0] bp_wgt_buf_ex_addr,
    output logic [BP_OUT_BUF_DEPTH-1:0] bp_out_buf_ex_addr,
    output logic                        bp_psum_sel,
    output logic                        bp_ex_tile_end
);

    logic bp_ex_state;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bp_ex_state <= 1'b0;
        end
        else if (bp_ex_tile_end) begin
            bp_ex_state <= 1'b0;
        end
        else if (bp_ex_tile_start) begin
            bp_ex_state <= 1'b1;
        end
    end

    logic [15:0]                 cnt_dataflow_depth;
    logic [7:0]                  cnt_dataflow_k;
    logic [7:0]                  cnt_dataflow_hw;
    logic                        full_dataflow_depth;
    logic                        full_dataflow_k;
    logic                        full_dataflow_hw;
    
    assign full_dataflow_depth = (cnt_dataflow_depth == bp_subtile_CIJ - 1);
    assign full_dataflow_k     = full_dataflow_depth & (cnt_dataflow_k == bp_subtile_K - 1);
    assign full_dataflow_hw    = full_dataflow_k & (cnt_dataflow_hw == bp_subtile_HW - 1);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_dataflow_depth <= 0;
        end
        else if (bp_ex_state) begin
            if (full_dataflow_depth) begin
                cnt_dataflow_depth <= 0;
            end
            else cnt_dataflow_depth <= cnt_dataflow_depth + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_dataflow_k <= 0;
        end
        else if (bp_ex_state & full_dataflow_depth) begin
            if (full_dataflow_k) begin
                cnt_dataflow_k <= 0;
            end
            else cnt_dataflow_k <= cnt_dataflow_k + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_dataflow_hw <= 0;
        end
        else if (bp_ex_state & full_dataflow_k) begin
            if (full_dataflow_hw) begin
                cnt_dataflow_hw <= 0;
            end
            else cnt_dataflow_hw <= cnt_dataflow_hw + 1;
        end
    end

    logic [5:0] cnt_bp_psum_sel;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bp_psum_sel <= 1'b0;
        end
        else if (cnt_bp_psum_sel == ROWS - 1) begin
            bp_psum_sel <= 1'b0;
        end
        else if (full_dataflow_depth) begin
            bp_psum_sel <= 1'b1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_bp_psum_sel <= 0;
        end
        else if (bp_psum_sel) begin
            if (cnt_bp_psum_sel == ROWS - 1) begin
                cnt_bp_psum_sel <= 0;
            end
            else cnt_bp_psum_sel <= cnt_bp_psum_sel + 1;
        end
    end

    always_ff @( posedge clk ) begin : addr_compute
        if (~rst_n) begin
            bp_act_buf_ex_addr <= 0;
            bp_wgt_buf_ex_addr <= 0;
            bp_out_buf_ex_addr <= 0;
        end
        else begin
            bp_act_buf_ex_addr <= cnt_dataflow_hw * bp_subtile_CIJ + cnt_dataflow_depth;
            bp_wgt_buf_ex_addr <= cnt_dataflow_k * bp_subtile_CIJ + cnt_dataflow_depth;
            bp_out_buf_ex_addr <= cnt_dataflow_k * bp_opt_subtile_HWCIJ + cnt_dataflow_hw * bp_subtile_CIJ + cnt_dataflow_depth;
        end
    end

    assign bp_ex_tile_end = full_dataflow_hw;

endmodule
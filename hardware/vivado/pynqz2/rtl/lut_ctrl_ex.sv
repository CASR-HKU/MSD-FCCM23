`timescale 1ns / 1ps

`include "def.sv"

module lut_ctrl_ex #(
    parameter ROWS              = `HW_LUT_PE_ROWS,
    parameter COLS              = `HW_LUT_PE_COLS,
    parameter BS_ACT_BUF_DEPTH  = `HW_BS_ACT_BUF_DEPTH,
    parameter BS_WGT_BUF_DEPTH  = `HW_BS_WGT_BUF_DEPTH,
    parameter BS_OUT_BUF_DEPTH  = `HW_BS_OUT_BUF_DEPTH
) (
    input  logic                        clk,
    input  logic                        rst_n,
    // tile size, updated when bs_ex_tile_start asserted
    input  logic [7:0]                  bs_subtile_K, // subtile of K (COLS)
    input  logic [7:0]                  bs_subtile_HW, // subtile of HW (ROWS)
    input  logic [23:0]                 bs_opt_subtile_HWCIJ, // for better timing
    input  logic [15:0]                 bs_subtile_CIJ, // subtile of CIJ (dataflow depth)
    input  logic [23:0]                 bs_subtile_EBCIJ, // subtile of EB*CIJ (dataflow depth)
    // control signals
    input  logic                        bs_ex_tile_start,
    input  logic [2:0]                  bs_tile_eb,
    output logic [BS_ACT_BUF_DEPTH-1:0] bs_act_buf_ex_addr,
    output logic [BS_WGT_BUF_DEPTH-1:0] bs_wgt_buf_ex_addr,
    output logic [BS_OUT_BUF_DEPTH-1:0] bs_out_buf_ex_addr,
    output logic                        bs_psum_sel,
    output logic                        bs_ex_tile_end
);

    logic bs_ex_state;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bs_ex_state <= 1'b0;
        end
        else if (bs_ex_tile_end) begin
            bs_ex_state <= 1'b0;
        end
        else if (bs_ex_tile_start) begin
            bs_ex_state <= 1'b1;
        end
    end

    logic [2:0]                  cnt_eb;
    logic [BS_WGT_BUF_DEPTH-1:0] cnt_wgt_depth;
    logic [15:0]                 cnt_dataflow_depth;
    logic [7:0]                  cnt_dataflow_k;
    logic [7:0]                  cnt_dataflow_hw;
    logic                        full_cnt_eb;
    logic                        full_dataflow_depth;
    logic                        full_dataflow_k;
    logic                        full_dataflow_hw;
    
    assign full_cnt_eb         = (cnt_eb == bs_tile_eb-1);
    assign full_dataflow_depth = full_cnt_eb & (cnt_dataflow_depth == bs_subtile_CIJ-1);
    assign full_dataflow_k     = full_dataflow_depth & (cnt_dataflow_k == bs_subtile_K-1);
    assign full_dataflow_hw    = full_dataflow_k & (cnt_dataflow_hw == bs_subtile_HW-1);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_eb <= 0;
        end
        else if (bs_ex_state) begin
            if (full_cnt_eb) begin
                cnt_eb <= 0;
            end
            else cnt_eb <= cnt_eb + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_dataflow_depth <= 0;
        end
        else if (bs_ex_state & full_cnt_eb) begin
            if (full_dataflow_depth) begin
                cnt_dataflow_depth <= 0;
            end
            else cnt_dataflow_depth <= cnt_dataflow_depth + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_wgt_depth <= 0;
        end
        else if (bs_ex_state) begin
            if (full_dataflow_depth) begin
                cnt_wgt_depth <= 0;
            end
            else cnt_wgt_depth <= cnt_wgt_depth + 1;
        end
    end


    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_dataflow_k <= 0;
        end
        else if (bs_ex_state & full_dataflow_depth) begin
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
        else if (bs_ex_state & full_dataflow_k) begin
            if (full_dataflow_hw) begin
                cnt_dataflow_hw <= 0;
            end
            else cnt_dataflow_hw <= cnt_dataflow_hw + 1;
        end
    end

    logic [5:0] cnt_bs_psum_sel;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bs_psum_sel <= 1'b0;
        end
        else if (cnt_bs_psum_sel == ROWS - 1) begin
            bs_psum_sel <= 1'b0;
        end
        else if (full_dataflow_depth) begin
            bs_psum_sel <= 1'b1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_bs_psum_sel <= 0;
        end
        else if (bs_psum_sel) begin
            if (cnt_bs_psum_sel == ROWS - 1) begin
                cnt_bs_psum_sel <= 0;
            end
            else cnt_bs_psum_sel <= cnt_bs_psum_sel + 1;
        end
    end

    always_ff @( posedge clk ) begin : addr_compute
        if (~rst_n) begin
            bs_act_buf_ex_addr <= 0;
            bs_wgt_buf_ex_addr <= 0;
            bs_out_buf_ex_addr <= 0;
        end
        else begin
            bs_act_buf_ex_addr <= cnt_dataflow_hw * bs_subtile_CIJ + cnt_dataflow_depth;
            bs_wgt_buf_ex_addr <= cnt_dataflow_k * bs_subtile_EBCIJ + cnt_wgt_depth;
            bs_out_buf_ex_addr <= cnt_dataflow_k * bs_opt_subtile_HWCIJ + cnt_dataflow_hw * bs_subtile_CIJ + cnt_dataflow_depth;
        end
    end

    assign bs_ex_tile_end = full_dataflow_hw;

endmodule
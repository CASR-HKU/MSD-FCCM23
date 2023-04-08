`timescale 1ns / 1ps

`include "def.sv"

module ctrl_wb #(
    parameter BS_ROWS           = `HW_LUT_PE_ROWS,
    parameter BS_COLS           = `HW_LUT_PE_COLS,
    parameter BP_ROWS           = `HW_DSP_PE_ROWS,
    parameter BP_COLS           = `HW_DSP_PE_COLS,
    parameter BP_OUT_BUF_DEPTH  = `HW_BP_OUT_BUF_DEPTH,
    parameter BS_OUT_BUF_DEPTH  = `HW_BS_OUT_BUF_DEPTH
) (
    input  logic                                        clk,
    input  logic                                        rst_n,
    // tile size, updated when bp_ex_tile_start asserted
    input  logic [15:0]                                 bs_bw_out_times,
    input  logic [15:0]                                 bp_bw_out_times,
    // control signals
    input  logic                                        wb_tile_start,
    input  logic                                        wb_valid_out,
    output logic [2:0]                                  bs_out_buf_wb_en,
    output logic [BS_COLS-1:0][BS_OUT_BUF_DEPTH-1:0]    bs_out_buf_wb_addr,
    output logic [2:0]                                  bp_out_buf_wb_en,
    output logic [BP_COLS-1:0][BP_OUT_BUF_DEPTH-1:0]    bp_out_buf_wb_addr,
    output logic                                        wb_bs_bp_sel,
    output logic                                        wb_tile_end
);
    
    logic bs_wb_out_state, bp_wb_out_state;

    logic [15:0] cnt_bs_out_bw_times;
    logic full_cnt_bs_out_bw_times;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_bs_out_bw_times <= 0;
        end
        else if (bs_wb_out_state & wb_valid_out) begin
            if (full_cnt_bs_out_bw_times) begin
                cnt_bs_out_bw_times <= 0;
            end
            else cnt_bs_out_bw_times <= cnt_bs_out_bw_times + 1;
        end
    end
    assign full_cnt_bs_out_bw_times = bs_wb_out_state & wb_valid_out & (cnt_bs_out_bw_times == bs_bw_out_times - 1);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bs_out_buf_wb_en <= 0;
        end
        else if (bs_wb_out_state & wb_valid_out) begin
            if (bs_out_buf_wb_en == (BS_COLS/8 - 1)) begin
                bs_out_buf_wb_en <= 0;
            end
            else bs_out_buf_wb_en <= bs_out_buf_wb_en + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bs_wb_out_state <= 1'b0;
        end
        else if (full_cnt_bs_out_bw_times) begin
            bs_wb_out_state <= 1'b0;
        end
        else if (wb_tile_start) begin
            bs_wb_out_state <= 1'b1;
        end
    end

    genvar bs_col_idx;
    generate
        for (bs_col_idx = 0; bs_col_idx < BS_COLS; bs_col_idx ++) begin
            assign bs_out_buf_wb_addr[bs_col_idx] = cnt_bs_out_bw_times;
        end
    endgenerate

    logic [15:0] cnt_bp_out_bw_times;
    logic       full_cnt_bp_out_bw_times;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_bp_out_bw_times <= 0;
        end
        else if (bp_wb_out_state & wb_valid_out) begin
            if (full_cnt_bp_out_bw_times) begin
                cnt_bp_out_bw_times <= 0;
            end
            else cnt_bp_out_bw_times <= cnt_bp_out_bw_times + 1;
        end
    end
    assign full_cnt_bp_out_bw_times = bp_wb_out_state & wb_valid_out & (cnt_bp_out_bw_times == bp_bw_out_times - 1);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bp_out_buf_wb_en <= 0;
        end
        else if (bp_wb_out_state & wb_valid_out) begin
            if (bp_out_buf_wb_en == (BP_COLS/4 - 1)) begin
                bp_out_buf_wb_en <= 0;
            end
            else bp_out_buf_wb_en <= bp_out_buf_wb_en + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bp_wb_out_state <= 1'b0;
        end
        else if (full_cnt_bp_out_bw_times) begin
            bp_wb_out_state <= 1'b0;
        end
        else if (full_cnt_bs_out_bw_times) begin
            bp_wb_out_state <= 1'b1;
        end
    end

    genvar bp_col_idx;
    generate
        for (bp_col_idx = 0; bp_col_idx < BP_COLS; bp_col_idx ++) begin
            assign bp_out_buf_wb_addr[bp_col_idx] = cnt_bp_out_bw_times;
        end
    endgenerate

    assign wb_tile_end = full_cnt_bp_out_bw_times;
    assign wb_bs_bp_sel = (bs_wb_out_state == 1'b1) ? 1'b1 : 1'b0;

endmodule
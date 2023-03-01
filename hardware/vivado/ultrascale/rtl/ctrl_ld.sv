`timescale 1ns / 1ps

`include "def.sv"

module ctrl_ld #(
    parameter BS_ROWS           = `HW_LUT_PE_ROWS,
    parameter BS_COLS           = `HW_LUT_PE_COLS,
    parameter BP_ROWS           = `HW_DSP_PE_ROWS,
    parameter BP_COLS           = `HW_DSP_PE_COLS,
    parameter BP_ACT_BUF_DEPTH  = `HW_BP_ACT_BUF_DEPTH,
    parameter BP_WGT_BUF_DEPTH  = `HW_BP_WGT_BUF_DEPTH,
    parameter BS_ACT_BUF_DEPTH  = `HW_BS_ACT_BUF_DEPTH,
    parameter BS_WGT_BUF_DEPTH  = `HW_BS_WGT_BUF_DEPTH
) (
    input  logic                                        clk,
    input  logic                                        rst_n,
    // tile size, updated when bp_ex_tile_start asserted
    input  logic [15:0]                                 bw_act_times,
    input  logic [15:0]                                 bs_bw_wgt_times,
    input  logic [15:0]                                 bp_bw_wgt_times,
    // control signals
    input  logic                                        ld_tile_start,
    input  logic                                        ld_valid_act,
    input  logic                                        ld_valid_wgt,
    output logic [BP_COLS-1:0]                          bp_act_buf_ld_en,
    output logic [BP_COLS-1:0][BP_ACT_BUF_DEPTH-1:0]    bp_act_buf_ld_addr,
    output logic [BP_ROWS-1:0]                          bp_wgt_buf_ld_en,
    output logic [BP_ROWS-1:0][BP_WGT_BUF_DEPTH-1:0]    bp_wgt_buf_ld_addr,
    output logic [BS_ROWS-1:0]                          bs_act_buf_ld_en,
    output logic [BS_ROWS-1:0][BS_ACT_BUF_DEPTH-1:0]    bs_act_buf_ld_addr,
    output logic [BS_COLS-1:0]                          bs_wgt_buf_ld_en,
    output logic [BS_COLS-1:0][BS_WGT_BUF_DEPTH-1:0]    bs_wgt_buf_ld_addr,
    output logic                                        ld_tile_end
);
    
    logic ld_act_state, bp_ld_wgt_state, bs_ld_wgt_state;
    logic bp_ld_valid_wgt, bs_ld_valid_wgt;
    assign bp_ld_valid_wgt = bp_ld_wgt_state & ld_valid_wgt;
    assign bs_ld_valid_wgt = bs_ld_wgt_state & ld_valid_wgt;

    /******************************** Load ACT control ******************************/
    logic [15:0] cnt_act_bw_times;
    logic       full_cnt_act_bw_times;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_act_bw_times <= 0;
        end
        else if (ld_act_state & ld_valid_act) begin
            if (full_cnt_act_bw_times) begin
                cnt_act_bw_times <= 0;
            end
            else cnt_act_bw_times <= cnt_act_bw_times + 1;
        end
    end
    assign full_cnt_act_bw_times = ld_act_state & (cnt_act_bw_times == bw_act_times - 1);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            ld_act_state <= 1'b0;
        end
        else if (full_cnt_act_bw_times) begin
            ld_act_state <= 1'b0;
        end
        else if (ld_tile_start) begin
            ld_act_state <= 1'b1;
        end
    end

    genvar bp_col_idx;
    generate
        for (bp_col_idx = 0; bp_col_idx < BP_COLS; bp_col_idx ++) begin
            assign bp_act_buf_ld_en[bp_col_idx] = ld_act_state & ld_valid_act;
            assign bp_act_buf_ld_addr[bp_col_idx] = cnt_act_bw_times;
        end
    endgenerate

    genvar bs_col_idx;
    generate
        for (bs_col_idx = 0; bs_col_idx < BS_COLS; bs_col_idx ++) begin
            assign bs_act_buf_ld_en[bs_col_idx] = ld_act_state & ld_valid_act;
            assign bs_act_buf_ld_addr[bs_col_idx] = cnt_act_bw_times;
        end
    endgenerate

    /******************************** Load ACT control ******************************/

    /******************************** Load WGT control ******************************/
    logic [15:0] cnt_bs_wgt_bw_times;
    logic       full_cnt_bs_wgt_bw_times;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_bs_wgt_bw_times <= 0;
        end
        else if (bs_ld_valid_wgt) begin
            if (full_cnt_bs_wgt_bw_times) begin
                cnt_bs_wgt_bw_times <= 0;
            end
            else cnt_bs_wgt_bw_times <= cnt_bs_wgt_bw_times + 1;
        end
    end
    assign full_cnt_bs_wgt_bw_times = bs_ld_wgt_state & (cnt_bs_wgt_bw_times == bs_bw_wgt_times - 1);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bs_ld_wgt_state <= 1'b0;
        end
        else if (full_cnt_bs_wgt_bw_times) begin
            bs_ld_wgt_state <= 1'b0;
        end
        else if (ld_tile_start) begin
            bs_ld_wgt_state <= 1'b1;
        end
    end

    genvar bs_row_idx;
    generate
        for (bs_row_idx = 0; bs_row_idx < BS_ROWS; bs_row_idx ++) begin
            assign bs_wgt_buf_ld_en[bs_row_idx] = bs_ld_valid_wgt;
            assign bs_wgt_buf_ld_addr[bs_row_idx] = cnt_bs_wgt_bw_times;
        end
    endgenerate

    logic [15:0] cnt_bp_wgt_bw_times;
    logic       full_cnt_bp_wgt_bw_times;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_bp_wgt_bw_times <= 0;
        end
        else if (bp_ld_valid_wgt) begin
            if (full_cnt_bp_wgt_bw_times) begin
                cnt_bp_wgt_bw_times <= 0;
            end
            else cnt_bp_wgt_bw_times <= cnt_bp_wgt_bw_times + 1;
        end
    end
    assign full_cnt_bp_wgt_bw_times = bp_ld_wgt_state & (cnt_bp_wgt_bw_times == bp_bw_wgt_times - 1);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            bp_ld_wgt_state <= 1'b0;
        end
        else if (full_cnt_bp_wgt_bw_times) begin
            bp_ld_wgt_state <= 1'b0;
        end
        else if (full_cnt_bs_wgt_bw_times) begin
            bp_ld_wgt_state <= 1'b1;
        end
    end

    genvar bp_row_idx;
    generate
        for (bp_row_idx = 0; bp_row_idx < BP_ROWS; bp_row_idx ++) begin
            assign bp_wgt_buf_ld_en[bp_row_idx] = bp_ld_valid_wgt;
            assign bp_wgt_buf_ld_addr[bp_row_idx] = cnt_bp_wgt_bw_times;
        end
    endgenerate
    /******************************** Load WGT control ******************************/

    logic ld_act_finish, ld_wgt_finish;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            ld_act_finish <= 1'b0;
        end
        else if (ld_tile_end) begin
            ld_act_finish <= 1'b0;
        end
        else if (full_cnt_act_bw_times) begin
            ld_act_finish <= 1'b1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            ld_wgt_finish <= 1'b0;
        end
        else if (ld_tile_end) begin
            ld_wgt_finish <= 1'b0;
        end
        else if (full_cnt_bp_wgt_bw_times) begin
            ld_wgt_finish <= 1'b1;
        end
    end

    assign ld_tile_end = ld_act_finish & ld_wgt_finish;

endmodule
`timescale 1ns / 1ps

`include "def.sv"

(* keep_hierarchy = "yes" *)
module bp_dsp_core #(
    parameter BP_ROWS           = `HW_DSP_PE_ROWS,
    parameter BP_COLS           = `HW_DSP_PE_COLS,
    parameter BP_ACT_BUF_DEPTH  = `HW_BP_ACT_BUF_DEPTH,
    parameter BP_WGT_BUF_DEPTH  = `HW_BP_WGT_BUF_DEPTH,
    parameter BP_OUT_BUF_DEPTH  = `HW_BP_OUT_BUF_DEPTH,
    parameter BP_BUF_SIZE       = `HW_BP_BUF_SIZE,
    parameter IDX_DW            = `HW_IDX_DW,
    parameter WGT_DW            = `HW_WGT_DW,
    parameter ACT_DW            = `HW_DSP_VER_BUS_DW,
    parameter PSU_DW            = `HW_DSP_VER_BUS_DW
) (
    input  logic                                    clk,
    input  logic                                    rst_n,
    // act stream
    output logic                                    s_axis_bp_act_ld_tready,
    input  logic [63:0]                             s_axis_bp_act_ld_tdata,
    input  logic                                    s_axis_bp_act_ld_tvalid,
    // wgt stream
    output logic                                    s_axis_bp_wgt_ld_tready,
    input  logic [63:0]                             s_axis_bp_wgt_ld_tdata,
    input  logic                                    s_axis_bp_wgt_ld_tvalid,
    // output activations for wb
    output logic [63:0]                             bp_out_wb_data,
    // dsp ld
    input  logic [BP_COLS-1:0]                      bp_act_buf_ld_en,
    input  logic [BP_COLS-1:0][BP_ACT_BUF_DEPTH-1:0]bp_act_buf_ld_addr,
    input  logic [BP_ROWS-1:0]                      bp_wgt_buf_ld_en,
    input  logic [BP_ROWS-1:0][BP_WGT_BUF_DEPTH-1:0]bp_wgt_buf_ld_addr,
    input  logic                                    bp_awt_buf_ld_sel,
    // dsp ex
    input  logic [BP_ACT_BUF_DEPTH-1:0]             bp_act_buf_ex_addr,
    input  logic [BP_WGT_BUF_DEPTH-1:0]             bp_wgt_buf_ex_addr,
    input  logic [BP_OUT_BUF_DEPTH-1:0]             bp_out_buf_ex_addr,
    input  logic                                    bp_awt_buf_ex_sel,
    input  logic                                    bp_out_buf_ex_sel,
    input  logic                                    bp_psum_sel,
    // dsp wb
    input  logic [2:0]                              bp_out_buf_wb_en,
    input  logic [BP_COLS-1:0][BP_OUT_BUF_DEPTH-1:0]bp_out_buf_wb_addr,
    input  logic                                    bp_out_buf_wb_sel
);
    
    logic [BP_COLS-1:0][ACT_DW-1:0] bp_dsp_activation;
    logic [BP_COLS-1:0][ACT_DW-1:0] bp_dsp_ld_act_data;
    logic [BP_ROWS-1:0][WGT_DW-1:0] bp_dsp_weights;
    logic [BP_ROWS-1:0][WGT_DW-1:0] bp_dsp_ld_wgt_data;
    logic [BP_COLS-1:0][PSU_DW-1:0] bp_dsp_psu_out;
    logic [BP_COLS-1:0][PSU_DW-1:0] bp_dsp_out_wb_data;

    assign s_axis_bp_act_ld_tready = 1'b1;
    assign s_axis_bp_wgt_ld_tready = 1'b1;
    
    genvar bp_col_idx, bp_row_idx;
    generate
        for (bp_col_idx = 0; bp_col_idx < BP_COLS; bp_col_idx ++) begin
            buf_sdp #(
                .BUF_LD_ADDR_WIDTH  (BP_ACT_BUF_DEPTH),
                .BUF_LD_DATA_WIDTH  (ACT_DW),
                .BUF_EX_ADDR_WIDTH  (BP_ACT_BUF_DEPTH),
                .BUF_EX_DATA_WIDTH  (ACT_DW),
                .BUF_MEM_SIZE       (BP_BUF_SIZE)
            ) bp_dsp_act_buf (
                .clk                (clk),
                .buf_ld_wr_en       (bp_act_buf_ld_en[bp_col_idx]),
                .buf_ld_sel         (bp_awt_buf_ld_sel),
                .buf_ld_addr        (bp_act_buf_ld_addr[bp_col_idx]),
                .buf_ld_data        (bp_dsp_ld_act_data[bp_col_idx]),
                .buf_ex_sel         (bp_awt_buf_ex_sel),
                .buf_ex_addr        (bp_act_buf_ex_addr),
                .buf_ex_data        (bp_dsp_activation[bp_col_idx])
            );
        end
    endgenerate

    generate
        for (bp_row_idx = 0; bp_row_idx < BP_ROWS; bp_row_idx ++) begin
            buf_sdp #(
                .BUF_LD_ADDR_WIDTH  (BP_WGT_BUF_DEPTH),
                .BUF_LD_DATA_WIDTH  (WGT_DW),
                .BUF_EX_ADDR_WIDTH  (BP_WGT_BUF_DEPTH),
                .BUF_EX_DATA_WIDTH  (WGT_DW),
                .BUF_MEM_SIZE       (BP_BUF_SIZE)
            ) bp_dsp_wgt_buf (
                .clk                (clk),
                .buf_ld_wr_en       (bp_wgt_buf_ld_en[bp_row_idx]),
                .buf_ld_sel         (bp_awt_buf_ld_sel),
                .buf_ld_addr        (bp_wgt_buf_ld_addr[bp_row_idx]),
                .buf_ld_data        (bp_dsp_ld_wgt_data[bp_row_idx]),
                .buf_ex_sel         (bp_out_buf_wb_sel),
                .buf_ex_addr        (bp_wgt_buf_ex_addr),
                .buf_ex_data        (bp_dsp_weights[bp_row_idx])
            );
        end
    endgenerate

    generate
        for (bp_col_idx = 0; bp_col_idx < BP_COLS; bp_col_idx ++) begin
            buf_sdp #(
                .BUF_LD_ADDR_WIDTH  (BP_OUT_BUF_DEPTH),
                .BUF_LD_DATA_WIDTH  (PSU_DW),
                .BUF_EX_ADDR_WIDTH  (BP_OUT_BUF_DEPTH),
                .BUF_EX_DATA_WIDTH  (PSU_DW),
                .BUF_MEM_SIZE       (BP_BUF_SIZE)
            ) bp_dsp_out_buf (
                .clk                (clk),
                .buf_ld_wr_en       (bp_psum_sel),
                .buf_ld_sel         (bp_out_buf_ex_sel),
                .buf_ld_addr        (bp_out_buf_ex_addr),
                .buf_ld_data        (bp_dsp_psu_out[bp_col_idx]),
                .buf_ex_sel         (bp_awt_buf_ex_sel),
                .buf_ex_addr        (bp_out_buf_wb_addr[bp_col_idx]),
                .buf_ex_data        (bp_dsp_out_wb_data[bp_col_idx])
            );
        end
    endgenerate

    // systolic array
    dsp_sys dsp_sys_inst(
        .clk        (clk),
        .rst_n      (rst_n),
        .psum_sel   (bp_psum_sel),
        .act_in     (bp_dsp_activation),
        .wgt_idx    (bp_dsp_weights),
        .psu_out    (bp_dsp_psu_out)
    );

    // assign the input stream to buffers
    genvar col_grp_idx, col_buf_idx;
    generate
        for (col_grp_idx = 0; col_grp_idx < BP_COLS/4; col_grp_idx ++) begin
            for (col_buf_idx = 0; col_buf_idx < 4; col_buf_idx ++) begin
                assign bp_dsp_ld_act_data[col_grp_idx*4+col_buf_idx] = s_axis_bp_act_ld_tdata[16*(col_buf_idx+1)-1:16*col_buf_idx];
            end
        end
    endgenerate
    assign bp_dsp_ld_act_data[12] = s_axis_bp_act_ld_tdata[15:0];
    assign bp_dsp_ld_act_data[13] = s_axis_bp_act_ld_tdata[31:16];
    assign bp_dsp_ld_act_data[14] = s_axis_bp_act_ld_tdata[47:32];

    genvar row_grp_idx, row_buf_idx;
    generate
        for (row_grp_idx = 0; row_grp_idx < BP_ROWS/8; row_grp_idx ++) begin
            for (row_buf_idx = 0; row_buf_idx < 8; row_buf_idx ++) begin
                assign bp_dsp_ld_wgt_data[row_grp_idx*8+row_buf_idx] = s_axis_bp_wgt_ld_tdata[8*(row_buf_idx+1)-1:8*row_buf_idx];
            end
        end
    endgenerate
    assign bp_dsp_ld_wgt_data[8]    = s_axis_bp_wgt_ld_tdata[7:0];
    assign bp_dsp_ld_wgt_data[9]    = s_axis_bp_wgt_ld_tdata[15:8];
    assign bp_dsp_ld_wgt_data[10]   = s_axis_bp_wgt_ld_tdata[23:16];
    assign bp_dsp_ld_wgt_data[11]   = s_axis_bp_wgt_ld_tdata[31:24];
    assign bp_dsp_ld_wgt_data[12]   = s_axis_bp_wgt_ld_tdata[39:32];
    assign bp_dsp_ld_wgt_data[13]   = s_axis_bp_wgt_ld_tdata[47:40];

    // assign the output stream to buffers
    logic [BP_COLS/4:0][3:0][PSU_DW-1:0] grp_out_wb_data;    
    generate
        for (col_grp_idx = 0; col_grp_idx < BP_COLS/4; col_grp_idx ++) begin
            for (col_buf_idx = 0; col_buf_idx < 4; col_buf_idx ++) begin
                assign grp_out_wb_data[col_grp_idx][col_buf_idx] = bp_dsp_out_wb_data[col_grp_idx*4+col_buf_idx];
            end
        end
    endgenerate
    assign grp_out_wb_data[BP_COLS/4][0] = bp_dsp_out_wb_data[12];
    assign grp_out_wb_data[BP_COLS/4][1] = bp_dsp_out_wb_data[13];
    assign grp_out_wb_data[BP_COLS/4][2] = bp_dsp_out_wb_data[14];
    assign grp_out_wb_data[BP_COLS/4][3] = 16'd0;

    generate
        for (col_buf_idx = 0; col_buf_idx < 4; col_buf_idx ++) begin
            always_ff @( posedge clk ) begin
                if (~rst_n) begin
                    bp_out_wb_data[16*(col_buf_idx+1)-1:16*col_buf_idx] <= 0;
                end
                else begin
                    bp_out_wb_data[16*(col_buf_idx+1)-1:16*col_buf_idx] <= grp_out_wb_data[bp_out_buf_wb_en][col_buf_idx];
                end
            end        
        end
    endgenerate


endmodule
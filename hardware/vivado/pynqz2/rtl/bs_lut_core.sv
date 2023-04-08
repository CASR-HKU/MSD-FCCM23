`timescale 1ns / 1ps

`include "def.sv"

(* keep_hierarchy = "yes" *)
module bs_lut_core #(
    parameter BS_ROWS           = `HW_LUT_PE_ROWS,
    parameter BS_COLS           = `HW_LUT_PE_COLS,
    parameter BS_ACT_BUF_DEPTH  = `HW_BS_ACT_BUF_DEPTH,
    parameter BS_WGT_BUF_DEPTH  = `HW_BS_WGT_BUF_DEPTH,
    parameter BS_OUT_BUF_DEPTH  = `HW_BS_OUT_BUF_DEPTH,
    parameter BS_BUF_SIZE       = `HW_BS_BUF_SIZE,
    parameter IDX_DW            = `HW_IDX_DW,
    parameter WGT_DW            = `HW_WGT_DW,
    parameter ACT_DW            = `HW_ACT_DW,
    parameter PSU_DW            = `HW_PSU_DW
) (
    input  logic                                    clk,
    input  logic                                    rst_n,
    // act stream
    output logic                                    s_axis_bs_act_ld_tready,
    input  logic [63:0]                             s_axis_bs_act_ld_tdata,
    input  logic                                    s_axis_bs_act_ld_tvalid,
    // wgt stream
    output logic                                    s_axis_bs_wgt_ld_tready,
    input  logic [63:0]                             s_axis_bs_wgt_ld_tdata,
    input  logic                                    s_axis_bs_wgt_ld_tvalid,
    // output activations for wb
    output logic [63:0]                             bs_out_wb_data,
    // lut ld
    input  logic [BS_COLS-1:0]                      bs_act_buf_ld_en,
    input  logic [BS_COLS-1:0][BS_ACT_BUF_DEPTH-1:0]bs_act_buf_ld_addr,
    input  logic [BS_ROWS-1:0]                      bs_wgt_buf_ld_en,
    input  logic [BS_ROWS-1:0][BS_WGT_BUF_DEPTH-1:0]bs_wgt_buf_ld_addr,
    input  logic                                    bs_awt_buf_ld_sel,
    // lut ex
    input  logic [BS_ACT_BUF_DEPTH-1:0]             bs_act_buf_ex_addr,
    input  logic [BS_WGT_BUF_DEPTH-1:0]             bs_wgt_buf_ex_addr,
    input  logic [BS_OUT_BUF_DEPTH-1:0]             bs_out_buf_ex_addr,
    input  logic                                    bs_awt_buf_ex_sel,
    input  logic                                    bs_out_buf_ex_sel,
    input  logic                                    bs_psum_sel,
    // lut wb
    input  logic [2:0]                              bs_out_buf_wb_en,
    input  logic [BS_COLS-1:0][BS_OUT_BUF_DEPTH-1:0]bs_out_buf_wb_addr,
    input  logic                                    bs_out_buf_wb_sel
);
    
    logic [BS_COLS-1:0][ACT_DW-1:0] bs_lut_activation;
    logic [BS_COLS-1:0][ACT_DW-1:0] bs_lut_ld_act_data;
    logic [BS_ROWS-1:0][IDX_DW-1:0] bs_lut_weights;
    logic [BS_ROWS-1:0][IDX_DW-1:0] bs_lut_ld_wgt_data;
    logic [BS_COLS-1:0][PSU_DW-1:0] bs_lut_psu_out;
    logic [BS_COLS-1:0][PSU_DW-1:0] bs_lut_out_wb_data;

    assign s_axis_bs_act_ld_tready = 1'b1;
    assign s_axis_bs_wgt_ld_tready = 1'b1;
    
    genvar bs_col_idx, bs_row_idx;
    generate
        for (bs_col_idx = 0; bs_col_idx < BS_COLS; bs_col_idx ++) begin
            buf_sdp #(
                .BUF_LD_ADDR_WIDTH  (BS_ACT_BUF_DEPTH),
                .BUF_LD_DATA_WIDTH  (ACT_DW),
                .BUF_EX_ADDR_WIDTH  (BS_ACT_BUF_DEPTH),
                .BUF_EX_DATA_WIDTH  (ACT_DW),
                .BUF_MEM_SIZE       (BS_BUF_SIZE)
            ) bs_lut_act_buf (
                .clk                (clk),
                .buf_ld_wr_en       (bs_act_buf_ld_en[bs_col_idx]),
                .buf_ld_sel         (bs_awt_buf_ld_sel),
                .buf_ld_addr        (bs_act_buf_ld_addr[bs_col_idx]),
                .buf_ld_data        (bs_lut_ld_act_data[bs_col_idx]),
                .buf_ex_sel         (bs_awt_buf_ex_sel),
                .buf_ex_addr        (bs_act_buf_ex_addr),
                .buf_ex_data        (bs_lut_activation[bs_col_idx])
            );
        end
    endgenerate

    generate
        for (bs_row_idx = 0; bs_row_idx < BS_ROWS; bs_row_idx ++) begin
            buf_sdp #(
                .BUF_LD_ADDR_WIDTH  (BS_WGT_BUF_DEPTH),
                .BUF_LD_DATA_WIDTH  (IDX_DW),
                .BUF_EX_ADDR_WIDTH  (BS_WGT_BUF_DEPTH),
                .BUF_EX_DATA_WIDTH  (IDX_DW),
                .BUF_MEM_SIZE       (16384)
            ) bs_lut_wgt_buf (
                .clk                (clk),
                .buf_ld_wr_en       (bs_wgt_buf_ld_en[bs_row_idx]),
                .buf_ld_sel         (bs_awt_buf_ld_sel),
                .buf_ld_addr        (bs_wgt_buf_ld_addr[bs_row_idx]),
                .buf_ld_data        (bs_lut_ld_wgt_data[bs_row_idx]),
                .buf_ex_sel         (bs_out_buf_wb_sel),
                .buf_ex_addr        (bs_wgt_buf_ex_addr),
                .buf_ex_data        (bs_lut_weights[bs_row_idx])
            );
        end
    endgenerate

    generate
        for (bs_col_idx = 0; bs_col_idx < BS_COLS; bs_col_idx ++) begin
            buf_sdp #(
                .BUF_LD_ADDR_WIDTH  (BS_OUT_BUF_DEPTH),
                .BUF_LD_DATA_WIDTH  (PSU_DW),
                .BUF_EX_ADDR_WIDTH  (BS_OUT_BUF_DEPTH),
                .BUF_EX_DATA_WIDTH  (PSU_DW),
                .BUF_MEM_SIZE       (BS_BUF_SIZE)
            ) bs_lut_out_buf (
                .clk                (clk),
                .buf_ld_wr_en       (bs_psum_sel),
                .buf_ld_sel         (bs_out_buf_ex_sel),
                .buf_ld_addr        (bs_out_buf_ex_addr),
                .buf_ld_data        (bs_lut_psu_out[bs_col_idx]),
                .buf_ex_sel         (bs_awt_buf_ex_sel),
                .buf_ex_addr        (bs_out_buf_wb_addr[bs_col_idx]),
                .buf_ex_data        (bs_lut_out_wb_data[bs_col_idx])
            );
        end
    endgenerate

    // systolic array
    lut_sys lut_sys_inst(
        .clk        (clk),
        .rst_n      (rst_n),
        .psum_sel   (bs_psum_sel),
        .act_in     (bs_lut_activation),
        .wgt_idx    (bs_lut_weights),
        .psu_out    (bs_lut_psu_out)
    );

    // assign the input stream to buffers
    genvar col_grp_idx, col_buf_idx;
    generate
        for (col_grp_idx = 0; col_grp_idx < BS_COLS/8; col_grp_idx ++) begin
            for (col_buf_idx = 0; col_buf_idx < 8; col_buf_idx ++) begin
                assign bs_lut_ld_act_data[col_grp_idx*8+col_buf_idx] = s_axis_bs_act_ld_tdata[8*(col_buf_idx+1)-1:8*col_buf_idx];
            end
        end
    endgenerate
    // assign bs_lut_ld_act_data[32] = s_axis_bs_act_ld_tdata[7:0];
    // assign bs_lut_ld_act_data[33] = s_axis_bs_act_ld_tdata[15:8];
    // assign bs_lut_ld_act_data[34] = s_axis_bs_act_ld_tdata[23:16];
    // assign bs_lut_ld_act_data[35] = s_axis_bs_act_ld_tdata[31:24];

    genvar row_grp_idx, row_buf_idx;
    generate
        for (row_grp_idx = 0; row_grp_idx < BS_ROWS/16; row_grp_idx ++) begin
            for (row_buf_idx = 0; row_buf_idx < 16; row_buf_idx ++) begin
                assign bs_lut_ld_wgt_data[row_grp_idx*16+row_buf_idx] = s_axis_bs_wgt_ld_tdata[4*(row_buf_idx+1)-1:4*row_buf_idx];
            end
        end
    endgenerate
    assign bs_lut_ld_wgt_data[32] = s_axis_bs_wgt_ld_tdata[3:0];
    assign bs_lut_ld_wgt_data[33] = s_axis_bs_wgt_ld_tdata[7:4];
    assign bs_lut_ld_wgt_data[34] = s_axis_bs_wgt_ld_tdata[11:8];
    assign bs_lut_ld_wgt_data[35] = s_axis_bs_wgt_ld_tdata[15:12];
    assign bs_lut_ld_wgt_data[36] = s_axis_bs_wgt_ld_tdata[19:16];
    assign bs_lut_ld_wgt_data[37] = s_axis_bs_wgt_ld_tdata[23:20];
    assign bs_lut_ld_wgt_data[38] = s_axis_bs_wgt_ld_tdata[27:24];
    assign bs_lut_ld_wgt_data[39] = s_axis_bs_wgt_ld_tdata[31:28];

    // assign the output stream to buffers
    logic [BS_COLS/8-1:0][7:0][PSU_DW-1:0] grp_out_wb_data;    
    generate
        for (col_grp_idx = 0; col_grp_idx < BS_COLS/8; col_grp_idx ++) begin
            for (col_buf_idx = 0; col_buf_idx < 8; col_buf_idx ++) begin
                assign grp_out_wb_data[col_grp_idx][col_buf_idx] = bs_lut_out_wb_data[col_grp_idx*8+col_buf_idx];
            end
        end
    endgenerate
    // assign grp_out_wb_data[BS_COLS/8][0] = bs_lut_out_wb_data[32];
    // assign grp_out_wb_data[BS_COLS/8][1] = bs_lut_out_wb_data[33];
    // assign grp_out_wb_data[BS_COLS/8][2] = bs_lut_out_wb_data[34];
    // assign grp_out_wb_data[BS_COLS/8][3] = bs_lut_out_wb_data[35];
    // assign grp_out_wb_data[BS_COLS/8][4] = 8'd0;
    // assign grp_out_wb_data[BS_COLS/8][5] = 8'd0;
    // assign grp_out_wb_data[BS_COLS/8][6] = 8'd0;
    // assign grp_out_wb_data[BS_COLS/8][4] = 8'd0;

    generate
        for (col_buf_idx = 0; col_buf_idx < 8; col_buf_idx ++) begin
            always_ff @( posedge clk ) begin
                if (~rst_n) begin
                    bs_out_wb_data[8*(col_buf_idx+1)-1:8*col_buf_idx] <= 0;
                end
                else begin
                    bs_out_wb_data[8*(col_buf_idx+1)-1:8*col_buf_idx] <= grp_out_wb_data[bs_out_buf_wb_en][col_buf_idx];
                end
            end        
        end
    endgenerate


endmodule
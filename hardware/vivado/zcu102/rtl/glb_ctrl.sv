`timescale 1ns / 1ps

`include "def.sv"

module glb_ctrl #(
    parameter BS_ROWS           = `HW_LUT_PE_ROWS,
    parameter BS_COLS           = `HW_LUT_PE_COLS,
    parameter BP_ROWS           = `HW_DSP_PE_ROWS,
    parameter BP_COLS           = `HW_DSP_PE_COLS,
    parameter BS_ACT_BUF_DEPTH  = `HW_BS_ACT_BUF_DEPTH,
    parameter BS_WGT_BUF_DEPTH  = `HW_BS_WGT_BUF_DEPTH,
    parameter BS_OUT_BUF_DEPTH  = `HW_BS_OUT_BUF_DEPTH,
    parameter BP_ACT_BUF_DEPTH  = `HW_BP_ACT_BUF_DEPTH,
    parameter BP_WGT_BUF_DEPTH  = `HW_BP_WGT_BUF_DEPTH,
    parameter BP_OUT_BUF_DEPTH  = `HW_BP_OUT_BUF_DEPTH
) (
    input  logic                                    clk,
    input  logic                                    rst_n,
    // input axis_instr
    output logic                                    s_axis_instr_tready,
    input  logic                                    s_axis_instr_tvalid,
    input  logic [127:0]                            s_axis_instr_tdata,
    // output stream - mm2s cmd act
    output logic [79: 0]                            m_axis_mm2s_cmd_act_tdata,
    output logic                                    m_axis_mm2s_cmd_act_tvalid,
    input  logic                                    m_axis_mm2s_cmd_act_tready,        
    // output stream - mm2s cmd wgt
    output logic [79: 0]                            m_axis_mm2s_cmd_wgt_tdata,
    output logic                                    m_axis_mm2s_cmd_wgt_tvalid,
    input  logic                                    m_axis_mm2s_cmd_wgt_tready,    
    // output stream - s2mm cmd
    output logic [79: 0]                            m_axis_s2mm_cmd_out_tdata,
    output logic                                    m_axis_s2mm_cmd_out_tvalid,
    input  logic                                    m_axis_s2mm_cmd_out_tready,
    // ld/wb valid
    input  logic                                    ld_valid_act,
    input  logic                                    ld_valid_wgt,
    input  logic                                    wb_valid,
    output logic                                    wb_bs_bp_sel,
    // lut ld
    output logic [BS_COLS-1:0]                      bs_act_buf_ld_en,
    output logic [BS_COLS-1:0][BS_ACT_BUF_DEPTH-1:0]bs_act_buf_ld_addr,
    output logic [BS_ROWS-1:0]                      bs_wgt_buf_ld_en,
    output logic [BS_ROWS-1:0][BS_WGT_BUF_DEPTH-1:0]bs_wgt_buf_ld_addr,
    output logic                                    bs_awt_buf_ld_sel,
    // lut ex
    output logic [BS_ACT_BUF_DEPTH-1:0]             bs_act_buf_ex_addr,
    output logic [BS_WGT_BUF_DEPTH-1:0]             bs_wgt_buf_ex_addr,
    output logic [BS_OUT_BUF_DEPTH-1:0]             bs_out_buf_ex_addr,
    output logic                                    bs_awt_buf_ex_sel,
    output logic                                    bs_out_buf_ex_sel,
    output logic                                    bs_psum_sel,
    // lut wb
    output logic [2:0]                              bs_out_buf_wb_en,
    output logic [BS_COLS-1:0][BS_OUT_BUF_DEPTH-1:0]bs_out_buf_wb_addr,
    output logic                                    bs_out_buf_wb_sel,
    // dsp ld
    output logic [BP_COLS-1:0]                      bp_act_buf_ld_en,
    output logic [BP_COLS-1:0][BP_ACT_BUF_DEPTH-1:0]bp_act_buf_ld_addr,
    output logic [BP_ROWS-1:0]                      bp_wgt_buf_ld_en,
    output logic [BP_ROWS-1:0][BP_WGT_BUF_DEPTH-1:0]bp_wgt_buf_ld_addr,
    output logic                                    bp_awt_buf_ld_sel,
    // dsp ex
    output logic [BP_ACT_BUF_DEPTH-1:0]             bp_act_buf_ex_addr,
    output logic [BP_WGT_BUF_DEPTH-1:0]             bp_wgt_buf_ex_addr,
    output logic [BP_OUT_BUF_DEPTH-1:0]             bp_out_buf_ex_addr,
    output logic                                    bp_awt_buf_ex_sel,
    output logic                                    bp_out_buf_ex_sel,
    output logic                                    bp_psum_sel,
    // dsp wb
    output logic [2:0]                              bp_out_buf_wb_en,
    output logic [BP_COLS-1:0][BP_OUT_BUF_DEPTH-1:0]bp_out_buf_wb_addr,
    output logic                                    bp_out_buf_wb_sel,
    output logic                                    wb_tile_done,
    output logic                                    wb_status,
    // start latency counter
    output logic                                    first_instr
);
    
    // all the parameters for the current layer
    logic [15:0] param_bw_tile_times_act;
    logic [15:0] param_bw_tile_times_bs_wgt;
    logic [15:0] param_bw_tile_times_bp_wgt;
    logic [7:0]  bs_ceil_k_rows;
    logic [7:0]  bp_ceil_k_rows;
    logic [7:0]  bs_ceil_hw_cols;
    logic [7:0]  bp_ceil_hw_cols;
    logic [15:0] param_tile_cij;
    logic [23:0] param_tile_cij_ceilhw_bs;
    logic [23:0] param_tile_cij_ceilhw_bp;
    logic [2:0]  tile_bs_eb;
    logic [23:0] param_tile_cij_eb;
    logic [15:0] param_bs_bw_out_times;
    logic [15:0] param_bp_bw_out_times;
    logic [15:0] param_tile_number;
    logic [23:0] param_btt_tile_act;
    logic [23:0] param_btt_tile_wgt;
    logic [23:0] param_btt_tile_out;
    logic [31:0] ext_addr_act_tile;
    logic [31:0] ext_addr_wgt_tile;
    logic [31:0] ext_addr_out_tile;
    logic        last_layer;

    // decode the instructions
    logic hs_axis_instr;
    assign hs_axis_instr = s_axis_instr_tvalid & s_axis_instr_tready & (s_axis_instr_tdata[127] == 1'b1);

    logic first_instr_state;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            first_instr_state <= 1'b0;
        end
        else if (hs_axis_instr) begin
            first_instr_state <= 1'b1;
        end
    end
    assign first_instr = (~first_instr_state) & hs_axis_instr;

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            param_bw_tile_times_act     <= 0;
            param_bw_tile_times_bs_wgt  <= 0;
            param_bw_tile_times_bp_wgt  <= 0;
            bs_ceil_k_rows              <= 0;
            bp_ceil_k_rows              <= 0;
            bs_ceil_hw_cols             <= 0;
            bp_ceil_hw_cols             <= 0;
            param_tile_cij              <= 0;
            param_tile_cij_ceilhw_bs    <= 0;
            tile_bs_eb                  <= 0;
            param_tile_cij_eb           <= 0;
            param_bs_bw_out_times       <= 0;
            param_bp_bw_out_times       <= 0;
            param_tile_number           <= 0;
            param_btt_tile_act          <= 0;
            param_btt_tile_wgt          <= 0;
            param_btt_tile_out          <= 0;
            ext_addr_act_tile           <= 0;
            param_tile_cij_ceilhw_bp    <= 0;
            last_layer                  <= 0;
        end
        else if (hs_axis_instr && (s_axis_instr_tdata[126:125] == 2'b00)) begin
            param_bw_tile_times_act     <= s_axis_instr_tdata[15:0];
            param_bw_tile_times_bs_wgt  <= s_axis_instr_tdata[31:16];
            param_bw_tile_times_bp_wgt  <= s_axis_instr_tdata[47:32];
            bs_ceil_k_rows              <= s_axis_instr_tdata[55:48];
            bp_ceil_k_rows              <= s_axis_instr_tdata[63:56];
            bs_ceil_hw_cols             <= s_axis_instr_tdata[71:64];
            bp_ceil_hw_cols             <= s_axis_instr_tdata[79:72];
            param_tile_cij              <= s_axis_instr_tdata[95:80];
            param_tile_cij_ceilhw_bs    <= s_axis_instr_tdata[119:96];
            last_layer                  <= s_axis_instr_tdata[120];
        end
        else if (hs_axis_instr && (s_axis_instr_tdata[126:125] == 2'b01)) begin
            tile_bs_eb                  <= s_axis_instr_tdata[2:0];
            param_tile_cij_eb           <= s_axis_instr_tdata[31:8];
            param_bs_bw_out_times       <= s_axis_instr_tdata[47:32];
            param_bp_bw_out_times       <= s_axis_instr_tdata[63:48];
            param_tile_number           <= s_axis_instr_tdata[79:64];
            param_tile_cij_ceilhw_bp    <= s_axis_instr_tdata[103:80];
        end
        else if (hs_axis_instr && (s_axis_instr_tdata[126:125] == 2'b10)) begin
            param_btt_tile_act          <= s_axis_instr_tdata[23:0];
            param_btt_tile_wgt          <= s_axis_instr_tdata[47:24];
            param_btt_tile_out          <= s_axis_instr_tdata[87:64];
        end
        else if (hs_axis_instr && (s_axis_instr_tdata[126:125] == 2'b11)) begin
            ext_addr_act_tile           <= s_axis_instr_tdata[31:0];
            ext_addr_wgt_tile           <= s_axis_instr_tdata[63:32];
            ext_addr_out_tile           <= s_axis_instr_tdata[95:64];
        end
    end

    // when one layer is running, it cannot receive new instructions
    logic layer_running_begin, layer_running_sts, layer_running_end;
    assign layer_running_begin = hs_axis_instr && (s_axis_instr_tdata[126:125] == 2'b11);
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            layer_running_sts <= 1'b0;
        end
        else if (layer_running_end) begin
            layer_running_sts <= 1'b0;
        end
        else if (layer_running_begin) begin
            layer_running_sts <= 1'b1;
        end
    end

    assign s_axis_instr_tready = (~layer_running_sts);

    // sync of ld, ex and wb
    logic [15:0] cnt_ld_tile, cnt_ex_tile, cnt_wb_tile;

    logic ld_busy, ex_busy, wb_busy;
    logic ld_flag, ex_flag, wb_flag;
    logic ld_ex_sync, wb_ex_sync, tri_sync;
    logic ld_tile_done, ex_tile_done;
    logic ld_tile_eol, ex_tile_eol, wb_tile_eol;
    logic ld_layer_finish, ex_layer_finish;

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            ld_layer_finish <= 1'b0;
        end
        else if (wb_tile_eol & ld_layer_finish) begin
            ld_layer_finish <= 1'b0;
        end
        else if (ld_tile_eol) begin
            ld_layer_finish <= 1'b1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            ex_layer_finish <= 1'b0;
        end
        else if (wb_tile_eol & ex_layer_finish) begin
            ex_layer_finish <= 1'b0;
        end
        else if (ex_tile_eol) begin
            ex_layer_finish <= 1'b1;
        end
    end

    assign layer_running_end = wb_tile_eol;

    always_comb begin
        ld_ex_sync = (~ld_busy) & (~ex_busy) & (ld_flag ^ ex_flag) & (~ld_layer_finish);
        wb_ex_sync = (~wb_busy) & (~ex_busy) & (wb_flag ^ ex_flag);
        tri_sync   =    (~ex_layer_finish) & (((~ld_busy)&(~ex_busy)&(~wb_busy))|
                        ((~ld_busy)&(~ex_busy)&(~wb_flag^ex_flag))|
                        ((~wb_busy)&(~ex_busy)&(~ld_flag^ex_flag)));
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            ld_busy <= 1'b1;
        end 
        else if (wb_tile_eol) begin
            ld_busy <= 1'b1;
        end
        else if (ld_ex_sync) begin
            ld_busy <= 1'b1;
        end else if (ld_tile_done) begin
            ld_busy <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            ex_busy <= 1'b0;
        end
        else if (wb_tile_eol) begin
            ex_busy <= 1'b0;
        end
        else if (tri_sync) begin
            ex_busy <= 1'b1;
        end else if (ex_tile_done) begin
            ex_busy <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            wb_busy <= 1'b0;
        end 
        else if (wb_tile_eol) begin
            wb_busy <= 1'b0;
        end
        else if (wb_ex_sync) begin
            wb_busy <= 1'b1;
        end else if (wb_tile_done) begin
            wb_busy <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            ld_flag <= 1'b0;
        end
        else if (wb_tile_eol) begin
            ld_flag <= 1'b0;
        end
        else if (ld_ex_sync) begin
            ld_flag <= ~ld_flag;
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            ex_flag <= 1'b1;
        end 
        else if (wb_tile_eol) begin
            ex_flag <= 1'b1;
        end
        else if (tri_sync) begin
            ex_flag <= ~ex_flag;
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            wb_flag <= 1'b1;
        end 
        else if (wb_tile_eol) begin
            wb_flag <= 1'b1;
        end
        else if (wb_ex_sync) begin
            wb_flag <= ~wb_flag;
        end
    end

    // controllers
    logic ld_tile_start;
    logic wb_tile_start;
    logic bs_ex_tile_start, bp_ex_tile_start;
    logic bs_ex_tile_end, bp_ex_tile_end;
    assign ld_tile_start = layer_running_begin | ld_ex_sync;
    assign bs_ex_tile_start = tri_sync;
    assign bp_ex_tile_start = tri_sync;
    assign wb_tile_start = wb_ex_sync;

    ctrl_ld ctrl_ld_inst(
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),
        .bw_act_times       (param_bw_tile_times_act    ),
        .bs_bw_wgt_times    (param_bw_tile_times_bs_wgt ),
        .bp_bw_wgt_times    (param_bw_tile_times_bp_wgt ),
        .ld_tile_start      (ld_tile_start              ),
        .ld_valid_act       (ld_valid_act               ),
        .ld_valid_wgt       (ld_valid_wgt               ),
        .bp_act_buf_ld_en   (bp_act_buf_ld_en           ),
        .bp_act_buf_ld_addr (bp_act_buf_ld_addr         ),
        .bp_wgt_buf_ld_en   (bp_wgt_buf_ld_en           ),
        .bp_wgt_buf_ld_addr (bp_wgt_buf_ld_addr         ),
        .bs_act_buf_ld_en   (bs_act_buf_ld_en           ),
        .bs_act_buf_ld_addr (bs_act_buf_ld_addr         ),
        .bs_wgt_buf_ld_en   (bs_wgt_buf_ld_en           ),
        .bs_wgt_buf_ld_addr (bs_wgt_buf_ld_addr         ),
        .ld_tile_end        (ld_tile_done               )
    );

    lut_ctrl_ex lut_ctrl_ex_inst(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .bs_subtile_K           (bs_ceil_k_rows),
        .bs_subtile_HW          (bs_ceil_hw_cols),
        .bs_opt_subtile_HWCIJ   (param_tile_cij_ceilhw_bs),
        .bs_subtile_CIJ         (param_tile_cij),
        .bs_subtile_EBCIJ       (param_tile_cij_eb),
        .bs_ex_tile_start       (bs_ex_tile_start),
        .bs_tile_eb             (tile_bs_eb),
        .bs_act_buf_ex_addr     (bs_act_buf_ex_addr),
        .bs_wgt_buf_ex_addr     (bs_wgt_buf_ex_addr),
        .bs_out_buf_ex_addr     (bs_out_buf_ex_addr),
        .bs_psum_sel            (bs_psum_sel),
        .bs_ex_tile_end         (bs_ex_tile_end)
    );

    dsp_ctrl_ex dsp_ctrl_ex_inst(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .bp_subtile_K           (bp_ceil_k_rows),
        .bp_subtile_HW          (bp_ceil_hw_cols),
        .bp_opt_subtile_HWCIJ   (param_tile_cij_ceilhw_bp),
        .bp_subtile_CIJ         (param_tile_cij),
        .bp_ex_tile_start       (bp_ex_tile_start),
        .bp_act_buf_ex_addr     (bp_act_buf_ex_addr),
        .bp_wgt_buf_ex_addr     (bp_wgt_buf_ex_addr),
        .bp_out_buf_ex_addr     (bp_out_buf_ex_addr),
        .bp_psum_sel            (bp_psum_sel),
        .bp_ex_tile_end         (bp_ex_tile_end)
    );
    
    ctrl_wb ctrl_wb_inst(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .bs_bw_out_times        (param_bs_bw_out_times),
        .bp_bw_out_times        (param_bp_bw_out_times),
        .wb_tile_start          (wb_tile_start),
        .wb_valid_out           (wb_valid),
        .bs_out_buf_wb_en       (bs_out_buf_wb_en),
        .bs_out_buf_wb_addr     (bs_out_buf_wb_addr),
        .bp_out_buf_wb_en       (bp_out_buf_wb_en),
        .bp_out_buf_wb_addr     (bp_out_buf_wb_addr),
        .wb_bs_bp_sel           (wb_bs_bp_sel),
        .wb_tile_end            (wb_tile_done)
    );

    // ex tile sync
    logic lut_ex_finish, dsp_ex_finish;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            lut_ex_finish <= 1'b0;
        end
        else if (ex_tile_done) begin
            lut_ex_finish <= 1'b0;
        end
        else if (bs_ex_tile_end) begin
            lut_ex_finish <= 1'b1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            dsp_ex_finish <= 1'b0;
        end
        else if (ex_tile_done) begin
            dsp_ex_finish <= 1'b0;
        end
        else if (bp_ex_tile_end) begin
            dsp_ex_finish <= 1'b1;
        end
    end
    assign ex_tile_done = lut_ex_finish & dsp_ex_finish;

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_ld_tile <= 0;
        end
        else if (ld_tile_done) begin
            if (cnt_ld_tile == param_tile_number - 1) begin
                cnt_ld_tile <= 0;
            end
            else cnt_ld_tile <= cnt_ld_tile + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_ex_tile <= 0;
        end
        else if (ex_tile_done) begin
            if (cnt_ex_tile == param_tile_number - 1) begin
                cnt_ex_tile <= 0;
            end
            else cnt_ex_tile <= cnt_ex_tile + 1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            cnt_wb_tile <= 0;
        end
        else if (wb_tile_done) begin
            if (cnt_wb_tile == param_tile_number - 1) begin
                cnt_wb_tile <= 0;
            end
            else cnt_wb_tile <= cnt_wb_tile + 1;
        end
    end

    assign ld_tile_eol = ld_tile_done & (cnt_ld_tile == param_tile_number - 1);
    assign ex_tile_eol = ex_tile_done & (cnt_ex_tile == param_tile_number - 1);
    assign wb_tile_eol = wb_tile_done & (cnt_wb_tile == param_tile_number - 1);

    // memory interface cmd
    // final data mm2s cmd. If CORE_CMD_WIDTH changed, need to modify clearly
    // act cmd
    logic [79:0] ld_act_cmd;
    assign ld_act_cmd[22:0]  = param_btt_tile_act[22:0]; // BTT
    assign ld_act_cmd[23]    = 1'b1; // TYPE
    assign ld_act_cmd[29:24] = 0; // TYPE
    assign ld_act_cmd[30]    = 1'b1; // EOF
    assign ld_act_cmd[31]    = 1'b0; // DRR
    assign ld_act_cmd[63:32] = ext_addr_act_tile; // SADDR
    assign ld_act_cmd[79:64] = 0;

    // wgt cmd
    logic [79:0] ld_wgt_cmd;
    assign ld_wgt_cmd[22:0]  = param_btt_tile_wgt[22:0]; // BTT
    assign ld_wgt_cmd[23]    = 1'b1; // TYPE
    assign ld_wgt_cmd[29:24] = 0; // TYPE
    assign ld_wgt_cmd[30]    = 1'b1; // EOF
    assign ld_wgt_cmd[31]    = 1'b0; // DRR
    assign ld_wgt_cmd[63:32] = ext_addr_wgt_tile; // SADDR
    assign ld_wgt_cmd[79:64] = 0;

    // out cmd
    logic [79:0] wb_out_cmd;
    logic [3:0] s2mm_sts_tag;
    assign s2mm_sts_tag = (last_layer & (cnt_wb_tile == param_tile_number - 1)) ? 4'b1111 : 4'b0000;
    assign wb_out_cmd[22:0]  = param_btt_tile_out[22:0]; // BTT
    assign wb_out_cmd[23]    = 1'b1; // TYPE
    assign wb_out_cmd[29:24] = 0; // TYPE
    assign wb_out_cmd[30]    = 1'b1; // EOF
    assign wb_out_cmd[31]    = 1'b0; // DRR
    assign wb_out_cmd[63:32] = ext_addr_out_tile; // SADDR
    assign wb_out_cmd[71:64] = 0;  // SADDR
    assign wb_out_cmd[75:72] = s2mm_sts_tag;
    assign wb_out_cmd[79:76] = 0;

    // axi stream control
    assign m_axis_mm2s_cmd_act_tdata = ld_act_cmd;
    assign m_axis_mm2s_cmd_wgt_tdata = ld_wgt_cmd;

    logic act_mover_valid_r;
    logic act_mover_hs;
    logic act_mover_en;

    assign act_mover_hs = m_axis_mm2s_cmd_act_tready & m_axis_mm2s_cmd_act_tvalid;
    assign act_mover_en = ld_tile_start & ((~m_axis_mm2s_cmd_act_tvalid)|m_axis_mm2s_cmd_act_tready);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            act_mover_valid_r <= 1'b0;
        end
        else if (act_mover_hs&(~act_mover_en)) begin
            act_mover_valid_r <= 1'b0;
        end
        else if (act_mover_en) begin
            act_mover_valid_r <= 1'b1;
        end
    end
    assign m_axis_mm2s_cmd_act_tvalid = act_mover_valid_r;

    logic wgt_mover_valid_r;
    logic wgt_mover_hs;
    logic wgt_mover_en;

    assign wgt_mover_hs = m_axis_mm2s_cmd_wgt_tready & m_axis_mm2s_cmd_wgt_tvalid;
    assign wgt_mover_en = ld_tile_start & ((~m_axis_mm2s_cmd_wgt_tvalid)|m_axis_mm2s_cmd_wgt_tready);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            wgt_mover_valid_r <= 1'b0;
        end
        else if (wgt_mover_hs&(~wgt_mover_en)) begin
            wgt_mover_valid_r <= 1'b0;
        end
        else if (wgt_mover_en) begin
            wgt_mover_valid_r <= 1'b1;
        end
    end
    assign m_axis_mm2s_cmd_wgt_tvalid = wgt_mover_valid_r;

    logic out_mover_valid_r;
    logic out_mover_hs;
    logic out_mover_en;
    assign m_axis_s2mm_cmd_out_tdata = wb_out_cmd;
    assign out_mover_hs = m_axis_s2mm_cmd_out_tready & m_axis_s2mm_cmd_out_tvalid;
    assign out_mover_en = wb_tile_start & ((~m_axis_s2mm_cmd_out_tvalid)|m_axis_s2mm_cmd_out_tready);

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            out_mover_valid_r <= 1'b0;
        end
        else if (out_mover_hs&(~out_mover_en)) begin
            out_mover_valid_r <= 1'b0;
        end
        else if (out_mover_en) begin
            out_mover_valid_r <= 1'b1;
        end
    end
    assign m_axis_s2mm_cmd_out_tvalid = out_mover_valid_r;

    assign bs_awt_buf_ld_sel = ld_flag;
    assign bs_awt_buf_ex_sel = ex_flag;
    assign bs_out_buf_ex_sel = ex_flag;
    assign bs_out_buf_wb_sel = wb_flag;

    assign bp_awt_buf_ld_sel = ld_flag;
    assign bp_awt_buf_ex_sel = ex_flag;
    assign bp_out_buf_ex_sel = ex_flag;
    assign bp_out_buf_wb_sel = wb_flag;

    assign wb_status = wb_busy;

endmodule
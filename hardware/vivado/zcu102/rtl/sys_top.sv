`timescale 1ns / 1ps

`include "def.sv"

module sys_top #(
    parameter AXI_ADDR_WIDTH    =   `DFLT_CORE_AXI_ADDR_WIDTH           ,
    parameter AXI_DATA_WIDTH    =   `DFLT_CORE_AXI_DATA_WIDTH           ,
    parameter BS_ROWS           =   `HW_LUT_PE_ROWS                     ,
    parameter BS_COLS           =   `HW_LUT_PE_COLS                     ,
    parameter BP_ROWS           =   `HW_DSP_PE_ROWS                     ,
    parameter BP_COLS           =   `HW_DSP_PE_COLS                     ,
    parameter BS_ACT_BUF_DEPTH  =   `HW_BS_ACT_BUF_DEPTH                ,
    parameter BS_WGT_BUF_DEPTH  =   `HW_BS_WGT_BUF_DEPTH                ,
    parameter BS_OUT_BUF_DEPTH  =   `HW_BS_OUT_BUF_DEPTH                ,
    parameter BP_ACT_BUF_DEPTH  =   `HW_BP_ACT_BUF_DEPTH                ,
    parameter BP_WGT_BUF_DEPTH  =   `HW_BP_WGT_BUF_DEPTH                ,
    parameter BP_OUT_BUF_DEPTH  =   `HW_BP_OUT_BUF_DEPTH
) (
    // common signal
    input  logic                            clk                         ,
    input  logic                            rst_n                       ,
    // variable signal
    input  logic [31:0]                     scalar                      ,
    output logic [1:0][31:0]                status                      ,
    // m_axi for iofm
    input  logic                            m_axi_iofm_awready          ,
    output logic                            m_axi_iofm_awvalid          ,
    output logic [AXI_ADDR_WIDTH-1:0]       m_axi_iofm_awaddr           ,
    output logic [7:0]                      m_axi_iofm_awlen            ,
    output logic [3:0]                      m_axi_iofm_awid             ,
    output logic [2:0]                      m_axi_iofm_awsize           ,
    output logic [1:0]                      m_axi_iofm_awburst          ,
    output logic [2:0]                      m_axi_iofm_awprot           ,
    output logic [3:0]                      m_axi_iofm_awcache          ,
    output logic [3:0]                      m_axi_iofm_awuser           ,
    input  logic                            m_axi_iofm_wready           ,
    output logic                            m_axi_iofm_wvalid           ,
    output logic [AXI_DATA_WIDTH-1:0]       m_axi_iofm_wdata            ,
    output logic [AXI_DATA_WIDTH/8-1:0]     m_axi_iofm_wstrb            ,
    output logic                            m_axi_iofm_wlast            ,
    output logic                            m_axi_iofm_bready           ,
    input  logic                            m_axi_iofm_bvalid           ,
    input  logic [1:0]                      m_axi_iofm_bresp            ,
    input  logic                            m_axi_iofm_arready          ,
    output logic                            m_axi_iofm_arvalid          ,
    output logic [AXI_ADDR_WIDTH-1:0]       m_axi_iofm_araddr           ,
    output logic [7:0]                      m_axi_iofm_arlen            ,
    output logic [3:0]                      m_axi_iofm_arid             ,
    output logic [2:0]                      m_axi_iofm_arsize           ,
    output logic [1:0]                      m_axi_iofm_arburst          ,
    output logic [2:0]                      m_axi_iofm_arprot           ,
    output logic [3:0]                      m_axi_iofm_arcache          ,
    output logic [3:0]                      m_axi_iofm_aruser           ,
    output logic                            m_axi_iofm_rready           ,
    input  logic                            m_axi_iofm_rvalid           ,
    input  logic [AXI_DATA_WIDTH-1:0]       m_axi_iofm_rdata            ,
    input  logic [1:0]                      m_axi_iofm_rresp            ,
    input  logic                            m_axi_iofm_rlast            ,
    // m_axi for wgt
    input  logic                            m_axi_wgt_arready           ,
    output logic                            m_axi_wgt_arvalid           ,
    output logic [AXI_ADDR_WIDTH-1:0]       m_axi_wgt_araddr            ,
    output logic [7:0]                      m_axi_wgt_arlen             ,
    output logic [3:0]                      m_axi_wgt_arid              ,
    output logic [2:0]                      m_axi_wgt_arsize            ,
    output logic [1:0]                      m_axi_wgt_arburst           ,
    output logic [2:0]                      m_axi_wgt_arprot            ,
    output logic [3:0]                      m_axi_wgt_arcache           ,
    output logic [3:0]                      m_axi_wgt_aruser            ,
    output logic                            m_axi_wgt_rready            ,
    input  logic                            m_axi_wgt_rvalid            ,
    input  logic [AXI_DATA_WIDTH-1:0]       m_axi_wgt_rdata             ,
    input  logic [1:0]                      m_axi_wgt_rresp             ,
    input  logic                            m_axi_wgt_rlast             ,
    // input axis_instr
    output logic                            s_axis_instr_tready         ,
    input  logic                            s_axis_instr_tvalid         ,
    input  logic [  AXI_DATA_WIDTH-1:0]     s_axis_instr_tdata          
);
    
    logic                            i_axis_mm2s_cmd_act_tready  ;
    logic                            i_axis_mm2s_cmd_act_tvalid  ;
    logic [79:0]                     i_axis_mm2s_cmd_act_tdata   ;

    logic                            i_axis_mm2s_cmd_wgt_tready  ;
    logic                            i_axis_mm2s_cmd_wgt_tvalid  ;
    logic [79:0]                     i_axis_mm2s_cmd_wgt_tdata   ;

    logic                            i_axis_s2mm_cmd_out_tready  ;
    logic                            i_axis_s2mm_cmd_out_tvalid  ;
    logic [79:0]                     i_axis_s2mm_cmd_out_tdata   ;
    
    logic                            i_axis_mm2s_act_tready      ;
    logic                            i_axis_mm2s_act_tvalid      ;
    logic [AXI_DATA_WIDTH-1:0]       i_axis_mm2s_act_tdata       ;
    logic [AXI_DATA_WIDTH/8-1:0]     i_axis_mm2s_act_tkeep       ;
    logic                            i_axis_mm2s_act_tlast       ;

    logic                            i_axis_mm2s_wgt_tready      ;
    logic                            i_axis_mm2s_wgt_tvalid      ;
    logic [AXI_DATA_WIDTH-1:0]       i_axis_mm2s_wgt_tdata       ;
    logic [AXI_DATA_WIDTH/8-1:0]     i_axis_mm2s_wgt_tkeep       ;
    logic                            i_axis_mm2s_wgt_tlast       ;

    logic                            i_axis_s2mm_out_tready      ;
    logic                            i_axis_s2mm_out_tvalid      ;
    logic [AXI_DATA_WIDTH-1:0]       i_axis_s2mm_out_tdata       ;
    logic [AXI_DATA_WIDTH/8-1:0]     i_axis_s2mm_out_tkeep       ;
    logic                            i_axis_s2mm_out_tlast       ;

    logic                            first_instr                 ;

    mem_itf mem_itf_inst(
        .clk                         (clk                         ),
        .rst_n                       (rst_n                       ),
        .scalar                      (scalar                      ),
        .first_instr                 (first_instr                 ),
        .status                      (status                      ),
        .m_axi_iofm_awready          (m_axi_iofm_awready          ),
        .m_axi_iofm_awvalid          (m_axi_iofm_awvalid          ),
        .m_axi_iofm_awaddr           (m_axi_iofm_awaddr           ),
        .m_axi_iofm_awlen            (m_axi_iofm_awlen            ),
        .m_axi_iofm_awid             (m_axi_iofm_awid             ),
        .m_axi_iofm_awsize           (m_axi_iofm_awsize           ),
        .m_axi_iofm_awburst          (m_axi_iofm_awburst          ),
        .m_axi_iofm_awprot           (m_axi_iofm_awprot           ),
        .m_axi_iofm_awcache          (m_axi_iofm_awcache          ),
        .m_axi_iofm_awuser           (m_axi_iofm_awuser           ),
        .m_axi_iofm_wready           (m_axi_iofm_wready           ),
        .m_axi_iofm_wvalid           (m_axi_iofm_wvalid           ),
        .m_axi_iofm_wdata            (m_axi_iofm_wdata            ),
        .m_axi_iofm_wstrb            (m_axi_iofm_wstrb            ),
        .m_axi_iofm_wlast            (m_axi_iofm_wlast            ),
        .m_axi_iofm_bready           (m_axi_iofm_bready           ),
        .m_axi_iofm_bvalid           (m_axi_iofm_bvalid           ),
        .m_axi_iofm_bresp            (m_axi_iofm_bresp            ),
        .m_axi_iofm_arready          (m_axi_iofm_arready          ),
        .m_axi_iofm_arvalid          (m_axi_iofm_arvalid          ),
        .m_axi_iofm_araddr           (m_axi_iofm_araddr           ),
        .m_axi_iofm_arlen            (m_axi_iofm_arlen            ),
        .m_axi_iofm_arid             (m_axi_iofm_arid             ),
        .m_axi_iofm_arsize           (m_axi_iofm_arsize           ),
        .m_axi_iofm_arburst          (m_axi_iofm_arburst          ),
        .m_axi_iofm_arprot           (m_axi_iofm_arprot           ),
        .m_axi_iofm_arcache          (m_axi_iofm_arcache          ),
        .m_axi_iofm_aruser           (m_axi_iofm_aruser           ),
        .m_axi_iofm_rready           (m_axi_iofm_rready           ),
        .m_axi_iofm_rvalid           (m_axi_iofm_rvalid           ),
        .m_axi_iofm_rdata            (m_axi_iofm_rdata            ),
        .m_axi_iofm_rresp            (m_axi_iofm_rresp            ),
        .m_axi_iofm_rlast            (m_axi_iofm_rlast            ),
        .m_axi_wgt_arready           (m_axi_wgt_arready           ),
        .m_axi_wgt_arvalid           (m_axi_wgt_arvalid           ),
        .m_axi_wgt_araddr            (m_axi_wgt_araddr            ),
        .m_axi_wgt_arlen             (m_axi_wgt_arlen             ),
        .m_axi_wgt_arid              (m_axi_wgt_arid              ),
        .m_axi_wgt_arsize            (m_axi_wgt_arsize            ),
        .m_axi_wgt_arburst           (m_axi_wgt_arburst           ),
        .m_axi_wgt_arprot            (m_axi_wgt_arprot            ),
        .m_axi_wgt_arcache           (m_axi_wgt_arcache           ),
        .m_axi_wgt_aruser            (m_axi_wgt_aruser            ),
        .m_axi_wgt_rready            (m_axi_wgt_rready            ),
        .m_axi_wgt_rvalid            (m_axi_wgt_rvalid            ),
        .m_axi_wgt_rdata             (m_axi_wgt_rdata             ),
        .m_axi_wgt_rresp             (m_axi_wgt_rresp             ),
        .m_axi_wgt_rlast             (m_axi_wgt_rlast             ),
        .s_axis_mm2s_cmd_act_tready  (i_axis_mm2s_cmd_act_tready  ),
        .s_axis_mm2s_cmd_act_tvalid  (i_axis_mm2s_cmd_act_tvalid  ),
        .s_axis_mm2s_cmd_act_tdata   (i_axis_mm2s_cmd_act_tdata   ),
        .s_axis_mm2s_cmd_wgt_tready  (i_axis_mm2s_cmd_wgt_tready  ),
        .s_axis_mm2s_cmd_wgt_tvalid  (i_axis_mm2s_cmd_wgt_tvalid  ),
        .s_axis_mm2s_cmd_wgt_tdata   (i_axis_mm2s_cmd_wgt_tdata   ),
        .s_axis_s2mm_cmd_out_tready  (i_axis_s2mm_cmd_out_tready  ),
        .s_axis_s2mm_cmd_out_tvalid  (i_axis_s2mm_cmd_out_tvalid  ),
        .s_axis_s2mm_cmd_out_tdata   (i_axis_s2mm_cmd_out_tdata   ),
        .m_axis_mm2s_act_tready      (i_axis_mm2s_act_tready      ),
        .m_axis_mm2s_act_tvalid      (i_axis_mm2s_act_tvalid      ),
        .m_axis_mm2s_act_tdata       (i_axis_mm2s_act_tdata       ),
        .m_axis_mm2s_act_tkeep       (i_axis_mm2s_act_tkeep       ),
        .m_axis_mm2s_act_tlast       (i_axis_mm2s_act_tlast       ),
        .m_axis_mm2s_wgt_tready      (i_axis_mm2s_wgt_tready      ),
        .m_axis_mm2s_wgt_tvalid      (i_axis_mm2s_wgt_tvalid      ),
        .m_axis_mm2s_wgt_tdata       (i_axis_mm2s_wgt_tdata       ),
        .m_axis_mm2s_wgt_tkeep       (i_axis_mm2s_wgt_tkeep       ),
        .m_axis_mm2s_wgt_tlast       (i_axis_mm2s_wgt_tlast       ),
        .s_axis_s2mm_out_tready      (i_axis_s2mm_out_tready      ),
        .s_axis_s2mm_out_tvalid      (i_axis_s2mm_out_tvalid      ),
        .s_axis_s2mm_out_tdata       (i_axis_s2mm_out_tdata       ),
        .s_axis_s2mm_out_tkeep       (i_axis_s2mm_out_tkeep       ),
        .s_axis_s2mm_out_tlast       (i_axis_s2mm_out_tlast       ) 
    );

    logic                                    ld_valid_act;
    logic                                    ld_valid_wgt;
    logic                                    wb_valid;
    logic                                    wb_bs_bp_sel;

    logic [BS_COLS-1:0]                      bs_act_buf_ld_en;
    logic [BS_COLS-1:0][BS_ACT_BUF_DEPTH-1:0]bs_act_buf_ld_addr;
    logic [BS_ROWS-1:0]                      bs_wgt_buf_ld_en;
    logic [BS_ROWS-1:0][BS_WGT_BUF_DEPTH-1:0]bs_wgt_buf_ld_addr;
    logic                                    bs_awt_buf_ld_sel;
    
    logic [BS_ACT_BUF_DEPTH-1:0]             bs_act_buf_ex_addr;
    logic [BS_WGT_BUF_DEPTH-1:0]             bs_wgt_buf_ex_addr;
    logic [BS_OUT_BUF_DEPTH-1:0]             bs_out_buf_ex_addr;
    logic                                    bs_awt_buf_ex_sel;
    logic                                    bs_out_buf_ex_sel;
    logic                                    bs_psum_sel;
    
    logic [2:0]                              bs_out_buf_wb_en;
    logic [BS_COLS-1:0][BS_OUT_BUF_DEPTH-1:0]bs_out_buf_wb_addr;
    logic                                    bs_out_buf_wb_sel;
    
    logic [BP_COLS-1:0]                      bp_act_buf_ld_en;
    logic [BP_COLS-1:0][BP_ACT_BUF_DEPTH-1:0]bp_act_buf_ld_addr;
    logic [BP_ROWS-1:0]                      bp_wgt_buf_ld_en;
    logic [BP_ROWS-1:0][BP_WGT_BUF_DEPTH-1:0]bp_wgt_buf_ld_addr;
    logic                                    bp_awt_buf_ld_sel;
    
    logic [BP_ACT_BUF_DEPTH-1:0]             bp_act_buf_ex_addr;
    logic [BP_WGT_BUF_DEPTH-1:0]             bp_wgt_buf_ex_addr;
    logic [BP_OUT_BUF_DEPTH-1:0]             bp_out_buf_ex_addr;
    logic                                    bp_awt_buf_ex_sel;
    logic                                    bp_out_buf_ex_sel;
    logic                                    bp_psum_sel;
    
    logic [2:0]                              bp_out_buf_wb_en;
    logic [BP_COLS-1:0][BP_OUT_BUF_DEPTH-1:0]bp_out_buf_wb_addr;
    logic                                    bp_out_buf_wb_sel;
    logic                                    wb_tile_done;
    logic                                    wb_status;

    assign ld_valid_act = i_axis_mm2s_act_tready & i_axis_mm2s_act_tvalid;
    assign ld_valid_wgt = i_axis_mm2s_wgt_tready & i_axis_mm2s_wgt_tvalid;
    assign wb_valid     = i_axis_s2mm_out_tready & i_axis_s2mm_out_tvalid;

    glb_ctrl glb_ctrl_inst (
        .clk                        (clk),
        .rst_n                      (rst_n),
        .s_axis_instr_tready        (s_axis_instr_tready),
        .s_axis_instr_tvalid        (s_axis_instr_tvalid),
        .s_axis_instr_tdata         (s_axis_instr_tdata),
        .m_axis_mm2s_cmd_act_tdata  (i_axis_mm2s_cmd_act_tdata),
        .m_axis_mm2s_cmd_act_tvalid (i_axis_mm2s_cmd_act_tvalid),
        .m_axis_mm2s_cmd_act_tready (i_axis_mm2s_cmd_act_tready),
        .m_axis_mm2s_cmd_wgt_tdata  (i_axis_mm2s_cmd_wgt_tdata),
        .m_axis_mm2s_cmd_wgt_tvalid (i_axis_mm2s_cmd_wgt_tvalid),
        .m_axis_mm2s_cmd_wgt_tready (i_axis_mm2s_cmd_wgt_tready),
        .m_axis_s2mm_cmd_out_tdata  (i_axis_s2mm_cmd_out_tdata),
        .m_axis_s2mm_cmd_out_tvalid (i_axis_s2mm_cmd_out_tvalid),
        .m_axis_s2mm_cmd_out_tready (i_axis_s2mm_cmd_out_tready),
        .ld_valid_act               (ld_valid_act),
        .ld_valid_wgt               (ld_valid_wgt),
        .wb_valid                   (wb_valid),
        .wb_bs_bp_sel               (wb_bs_bp_sel),
        .bs_act_buf_ld_en           (bs_act_buf_ld_en),
        .bs_act_buf_ld_addr         (bs_act_buf_ld_addr),
        .bs_wgt_buf_ld_en           (bs_wgt_buf_ld_en),
        .bs_wgt_buf_ld_addr         (bs_wgt_buf_ld_addr),
        .bs_awt_buf_ld_sel          (bs_awt_buf_ld_sel), 
        .bs_act_buf_ex_addr         (bs_act_buf_ex_addr),
        .bs_wgt_buf_ex_addr         (bs_wgt_buf_ex_addr),
        .bs_out_buf_ex_addr         (bs_out_buf_ex_addr),
        .bs_awt_buf_ex_sel          (bs_awt_buf_ex_sel),
        .bs_out_buf_ex_sel          (bs_out_buf_ex_sel),
        .bs_psum_sel                (bs_psum_sel),
        .bs_out_buf_wb_en           (bs_out_buf_wb_en),
        .bs_out_buf_wb_addr         (bs_out_buf_wb_addr),
        .bs_out_buf_wb_sel          (bs_out_buf_wb_sel),
        .bp_act_buf_ld_en           (bp_act_buf_ld_en),
        .bp_act_buf_ld_addr         (bp_act_buf_ld_addr),
        .bp_wgt_buf_ld_en           (bp_wgt_buf_ld_en),
        .bp_wgt_buf_ld_addr         (bp_wgt_buf_ld_addr),
        .bp_awt_buf_ld_sel          (bp_awt_buf_ld_sel),
        .bp_act_buf_ex_addr         (bp_act_buf_ex_addr),
        .bp_wgt_buf_ex_addr         (bp_wgt_buf_ex_addr),
        .bp_out_buf_ex_addr         (bp_out_buf_ex_addr),
        .bp_awt_buf_ex_sel          (bp_awt_buf_ex_sel),
        .bp_out_buf_ex_sel          (bp_out_buf_ex_sel),
        .bp_psum_sel                (bp_psum_sel),
        .bp_out_buf_wb_en           (bp_out_buf_wb_en),
        .bp_out_buf_wb_addr         (bp_out_buf_wb_addr),
        .bp_out_buf_wb_sel          (bp_out_buf_wb_sel),
        .wb_tile_done               (wb_tile_done),
        .wb_status                  (wb_status),
        .first_instr                (first_instr)
    );

    logic [127:0] bs_out_wb_data, bp_out_wb_data;
    logic i_axis_mm2s_act_tready_bs, i_axis_mm2s_act_tready_bp;
    logic i_axis_mm2s_wgt_tready_bs, i_axis_mm2s_wgt_tready_bp;
    assign i_axis_mm2s_act_tready = i_axis_mm2s_act_tready_bs & i_axis_mm2s_act_tready_bp;
    assign i_axis_mm2s_wgt_tready = i_axis_mm2s_wgt_tready_bs & i_axis_mm2s_wgt_tready_bp;
    
    bs_lut_core bs_lut_core_inst(
        .clk                        (clk),
        .rst_n                      (rst_n),
        .s_axis_bs_act_ld_tready    (i_axis_mm2s_act_tready_bs),
        .s_axis_bs_act_ld_tdata     (i_axis_mm2s_act_tdata),
        .s_axis_bs_act_ld_tvalid    (i_axis_mm2s_act_tvalid),
        .s_axis_bs_wgt_ld_tready    (i_axis_mm2s_wgt_tready_bs),
        .s_axis_bs_wgt_ld_tdata     (i_axis_mm2s_wgt_tdata),
        .s_axis_bs_wgt_ld_tvalid    (i_axis_mm2s_wgt_tvalid),
        .bs_out_wb_data             (bs_out_wb_data),
        .bs_act_buf_ld_en           (bs_act_buf_ld_en),
        .bs_act_buf_ld_addr         (bs_act_buf_ld_addr),
        .bs_wgt_buf_ld_en           (bs_wgt_buf_ld_en),
        .bs_wgt_buf_ld_addr         (bs_wgt_buf_ld_addr),
        .bs_awt_buf_ld_sel          (bs_awt_buf_ld_sel),
        .bs_act_buf_ex_addr         (bs_act_buf_ex_addr),
        .bs_wgt_buf_ex_addr         (bs_wgt_buf_ex_addr),
        .bs_out_buf_ex_addr         (bs_out_buf_ex_addr),
        .bs_awt_buf_ex_sel          (bs_awt_buf_ex_sel),
        .bs_out_buf_ex_sel          (bs_out_buf_ex_sel),
        .bs_psum_sel                (bs_psum_sel),
        .bs_out_buf_wb_en           (bs_out_buf_wb_en),
        .bs_out_buf_wb_addr         (bs_out_buf_wb_addr),
        .bs_out_buf_wb_sel          (bs_out_buf_wb_sel)
    );

    bp_dsp_core bp_dsp_core_inst(
        .clk                        (clk),
        .rst_n                      (rst_n),
        .s_axis_bp_act_ld_tready    (i_axis_mm2s_act_tready_bp),
        .s_axis_bp_act_ld_tdata     (i_axis_mm2s_act_tdata),
        .s_axis_bp_act_ld_tvalid    (i_axis_mm2s_act_tvalid),
        .s_axis_bp_wgt_ld_tready    (i_axis_mm2s_wgt_tready_bp),
        .s_axis_bp_wgt_ld_tdata     (i_axis_mm2s_wgt_tdata),
        .s_axis_bp_wgt_ld_tvalid    (i_axis_mm2s_wgt_tvalid),
        .bp_out_wb_data             (bp_out_wb_data),
        .bp_act_buf_ld_en           (bp_act_buf_ld_en),
        .bp_act_buf_ld_addr         (bp_act_buf_ld_addr),
        .bp_wgt_buf_ld_en           (bp_wgt_buf_ld_en),
        .bp_wgt_buf_ld_addr         (bp_wgt_buf_ld_addr),
        .bp_awt_buf_ld_sel          (bp_awt_buf_ld_sel),
        .bp_act_buf_ex_addr         (bp_act_buf_ex_addr),
        .bp_wgt_buf_ex_addr         (bp_wgt_buf_ex_addr),
        .bp_out_buf_ex_addr         (bp_out_buf_ex_addr),
        .bp_awt_buf_ex_sel          (bp_awt_buf_ex_sel),
        .bp_out_buf_ex_sel          (bp_out_buf_ex_sel),
        .bp_psum_sel                (bp_psum_sel),
        .bp_out_buf_wb_en           (bp_out_buf_wb_en),
        .bp_out_buf_wb_addr         (bp_out_buf_wb_addr),
        .bp_out_buf_wb_sel          (bp_out_buf_wb_sel)
    );

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            i_axis_s2mm_out_tdata <= 0;
        end
        else if (wb_bs_bp_sel) begin
            i_axis_s2mm_out_tdata <= bs_out_wb_data;
        end
        else begin
            i_axis_s2mm_out_tdata <= bp_out_wb_data;
        end
    end

    assign i_axis_s2mm_out_tkeep = 16'hffff;
    assign i_axis_s2mm_out_tlast = wb_tile_done;
    assign i_axis_s2mm_out_tvalid = wb_status;

endmodule
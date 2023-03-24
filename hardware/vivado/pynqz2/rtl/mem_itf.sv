`timescale 1ns/1ps

`include "def.sv"

module mem_itf #(
    parameter AXI_ADDR_WIDTH    =   `DFLT_CORE_AXI_ADDR_WIDTH           ,
    parameter AXI_DATA_WIDTH    =   `DFLT_CORE_AXI_DATA_WIDTH           ,
    parameter CORE_STS_WIDTH    =   `DFLT_MEM_STS_WIDTH                 
)(
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
    // input axis_mm2s_instr
    output logic                            s_axis_mm2s_cmd_act_tready  ,
    input  logic                            s_axis_mm2s_cmd_act_tvalid  ,
    input  logic [79:0]                     s_axis_mm2s_cmd_act_tdata   ,
    // input axis_mm2s_instr
    output logic                            s_axis_mm2s_cmd_wgt_tready  ,
    input  logic                            s_axis_mm2s_cmd_wgt_tvalid  ,
    input  logic [79:0]                     s_axis_mm2s_cmd_wgt_tdata   ,
    // input axis_s2mm_instr
    output logic                            s_axis_s2mm_cmd_out_tready  ,
    input  logic                            s_axis_s2mm_cmd_out_tvalid  ,
    input  logic [79:0]                     s_axis_s2mm_cmd_out_tdata   ,
    // output axis_mm2s_act
    input  logic                            m_axis_mm2s_act_tready      ,
    output logic                            m_axis_mm2s_act_tvalid      ,
    output logic [AXI_DATA_WIDTH-1:0]       m_axis_mm2s_act_tdata       ,
    output logic [AXI_DATA_WIDTH/8-1:0]     m_axis_mm2s_act_tkeep       ,
    output logic                            m_axis_mm2s_act_tlast       ,
    // output axis_mm2s_wgt
    input  logic                            m_axis_mm2s_wgt_tready      ,
    output logic                            m_axis_mm2s_wgt_tvalid      ,
    output logic [AXI_DATA_WIDTH-1:0]       m_axis_mm2s_wgt_tdata       ,
    output logic [AXI_DATA_WIDTH/8-1:0]     m_axis_mm2s_wgt_tkeep       ,
    output logic                            m_axis_mm2s_wgt_tlast       ,
    // input axis_s2mm
    output logic                            s_axis_s2mm_out_tready      ,
    input  logic                            s_axis_s2mm_out_tvalid      ,
    input  logic [AXI_DATA_WIDTH-1:0]       s_axis_s2mm_out_tdata       ,
    input  logic [AXI_DATA_WIDTH/8-1:0]     s_axis_s2mm_out_tkeep       ,
    input  logic                            s_axis_s2mm_out_tlast        
);

    // mm2s_sts_act
    logic                              i_axis_mm2s_sts_act_tready;
    logic                              i_axis_mm2s_sts_act_tvalid;
    logic [  CORE_STS_WIDTH-1:0]       i_axis_mm2s_sts_act_tdata;
    logic [                 0:0]       i_axis_mm2s_sts_act_tkeep;
    logic                              i_axis_mm2s_sts_act_tlast;

    // mm2s_sts_wgt
    logic                              i_axis_mm2s_sts_wgt_tready;
    logic                              i_axis_mm2s_sts_wgt_tvalid;
    logic [  CORE_STS_WIDTH-1:0]       i_axis_mm2s_sts_wgt_tdata;
    logic [                 0:0]       i_axis_mm2s_sts_wgt_tkeep;
    logic                              i_axis_mm2s_sts_wgt_tlast;

    // mm2s_sts_out
    logic                              i_axis_s2mm_sts_out_tready;
    logic                              i_axis_s2mm_sts_out_tvalid;
    logic [  CORE_STS_WIDTH-1:0]       i_axis_s2mm_sts_out_tdata;
    logic [                 0:0]       i_axis_s2mm_sts_out_tkeep;
    logic                              i_axis_s2mm_sts_out_tlast;

    logic latency_cnt_start, latency_cnt_state, latency_cnt_end;
    assign latency_cnt_start = (latency_cnt_state == 1'b0) & m_axis_mm2s_act_tready & m_axis_mm2s_act_tvalid;
    assign latency_cnt_end = i_axis_s2mm_sts_out_tready & i_axis_s2mm_sts_out_tvalid & (i_axis_s2mm_sts_out_tdata[3:0] == 4'b1111);
    assign i_axis_mm2s_sts_act_tready = 1'b1;
    assign i_axis_mm2s_sts_wgt_tready = 1'b1;
    assign i_axis_s2mm_sts_out_tready = 1'b1;

    logic [31:0] latency_cnt;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            latency_cnt_state <= 1'b0;
        end
        else if (latency_cnt_end) begin
            latency_cnt_state <= 1'b0;
        end
        else if (latency_cnt_start) begin
            latency_cnt_state <= 1'b1;
        end
    end

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            latency_cnt <= 0;
        end
        else if (latency_cnt_state) begin
            latency_cnt <= latency_cnt + 1;
        end
    end

    assign status[0] = latency_cnt;
    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            status[1] <= 0;
        end
        else if (i_axis_s2mm_sts_out_tready & i_axis_s2mm_sts_out_tvalid) begin
            status[1][7:0] <= i_axis_s2mm_sts_out_tdata;
        end
    end

    logic mm2s_err_iofm, s2mm_err_iofm, mm2s_err_wgt;
    axi_datamover_iofm axi_datamover_iofm_inst (
        .m_axi_mm2s_aclk(clk),                        // input wire m_axi_mm2s_aclk
        .m_axi_mm2s_aresetn(rst_n),                  // input wire m_axi_mm2s_aresetn
        .mm2s_err(mm2s_err_iofm),                                      // output wire mm2s_err
        .m_axis_mm2s_cmdsts_aclk(clk),        // input wire m_axis_mm2s_cmdsts_aclk
        .m_axis_mm2s_cmdsts_aresetn(rst_n),  // input wire m_axis_mm2s_cmdsts_aresetn
        .s_axis_mm2s_cmd_tvalid (s_axis_mm2s_cmd_act_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
        .s_axis_mm2s_cmd_tready (s_axis_mm2s_cmd_act_tready),          // output wire s_axis_mm2s_cmd_tready
        .s_axis_mm2s_cmd_tdata  (s_axis_mm2s_cmd_act_tdata),            // input wire [79 : 0] s_axis_mm2s_cmd_tdata
        .m_axis_mm2s_sts_tvalid (i_axis_mm2s_sts_act_tvalid),          // output wire m_axis_mm2s_sts_tvalid
        .m_axis_mm2s_sts_tready (i_axis_mm2s_sts_act_tready),          // input wire m_axis_mm2s_sts_tready
        .m_axis_mm2s_sts_tdata  (i_axis_mm2s_sts_act_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
        .m_axis_mm2s_sts_tkeep  (i_axis_mm2s_sts_act_tkeep),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
        .m_axis_mm2s_sts_tlast  (i_axis_mm2s_sts_act_tlast),            // output wire m_axis_mm2s_sts_tlast
        .m_axi_mm2s_arid        (m_axi_iofm_arid),                        // output wire [3 : 0] m_axi_mm2s_arid
        .m_axi_mm2s_araddr      (m_axi_iofm_araddr[35:0]),                    // output wire [35 : 0] m_axi_mm2s_araddr
        .m_axi_mm2s_arlen       (m_axi_iofm_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
        .m_axi_mm2s_arsize      (m_axi_iofm_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
        .m_axi_mm2s_arburst     (m_axi_iofm_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
        .m_axi_mm2s_arprot      (m_axi_iofm_arprot),                    // output wire [2 : 0] m_axi_mm2s_arprot
        .m_axi_mm2s_arcache     (m_axi_iofm_arcache),                  // output wire [3 : 0] m_axi_mm2s_arcache
        .m_axi_mm2s_aruser      (m_axi_iofm_aruser),                    // output wire [3 : 0] m_axi_mm2s_aruser
        .m_axi_mm2s_arvalid     (m_axi_iofm_arvalid),                  // output wire m_axi_mm2s_arvalid
        .m_axi_mm2s_arready     (m_axi_iofm_arready),                  // input wire m_axi_mm2s_arready
        .m_axi_mm2s_rdata       (m_axi_iofm_rdata),                      // input wire [127 : 0] m_axi_mm2s_rdata
        .m_axi_mm2s_rresp       (m_axi_iofm_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
        .m_axi_mm2s_rlast       (m_axi_iofm_rlast),                      // input wire m_axi_mm2s_rlast
        .m_axi_mm2s_rvalid      (m_axi_iofm_rvalid),                    // input wire m_axi_mm2s_rvalid
        .m_axi_mm2s_rready      (m_axi_iofm_rready),                    // output wire m_axi_mm2s_rready
        .m_axis_mm2s_tdata      (m_axis_mm2s_act_tdata),                    // output wire [127 : 0] m_axis_mm2s_tdata
        .m_axis_mm2s_tkeep      (m_axis_mm2s_act_tkeep),                    // output wire [15 : 0] m_axis_mm2s_tkeep
        .m_axis_mm2s_tlast      (m_axis_mm2s_act_tlast),                    // output wire m_axis_mm2s_tlast
        .m_axis_mm2s_tvalid     (m_axis_mm2s_act_tvalid),                  // output wire m_axis_mm2s_tvalid
        .m_axis_mm2s_tready     (m_axis_mm2s_act_tready),                  // input wire m_axis_mm2s_tready
        .m_axi_s2mm_aclk        (clk),                        // input wire m_axi_s2mm_aclk
        .m_axi_s2mm_aresetn     (rst_n),                  // input wire m_axi_s2mm_aresetn
        .s2mm_err               (s2mm_err_iofm),                                      // output wire s2mm_err
        .m_axis_s2mm_cmdsts_awclk(clk),      // input wire m_axis_s2mm_cmdsts_awclk
        .m_axis_s2mm_cmdsts_aresetn(rst_n),  // input wire m_axis_s2mm_cmdsts_aresetn
        .s_axis_s2mm_cmd_tvalid (s_axis_s2mm_cmd_out_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
        .s_axis_s2mm_cmd_tready (s_axis_s2mm_cmd_out_tready),          // output wire s_axis_s2mm_cmd_tready
        .s_axis_s2mm_cmd_tdata  (s_axis_s2mm_cmd_out_tdata),            // input wire [79 : 0] s_axis_s2mm_cmd_tdata
        .m_axis_s2mm_sts_tvalid (i_axis_s2mm_sts_out_tvalid),          // output wire m_axis_s2mm_sts_tvalid
        .m_axis_s2mm_sts_tready (i_axis_s2mm_sts_out_tready),          // input wire m_axis_s2mm_sts_tready
        .m_axis_s2mm_sts_tdata  (i_axis_s2mm_sts_out_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
        .m_axis_s2mm_sts_tkeep  (i_axis_s2mm_sts_out_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
        .m_axis_s2mm_sts_tlast  (i_axis_s2mm_sts_out_tlast),            // output wire m_axis_s2mm_sts_tlast
        .m_axi_s2mm_awid        (m_axi_iofm_awid),                        // output wire [3 : 0] m_axi_s2mm_awid
        .m_axi_s2mm_awaddr      (m_axi_iofm_awaddr[35:0]),                    // output wire [35 : 0] m_axi_s2mm_awaddr
        .m_axi_s2mm_awlen       (m_axi_iofm_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
        .m_axi_s2mm_awsize      (m_axi_iofm_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
        .m_axi_s2mm_awburst     (m_axi_iofm_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
        .m_axi_s2mm_awprot      (m_axi_iofm_awprot),                    // output wire [2 : 0] m_axi_s2mm_awprot
        .m_axi_s2mm_awcache     (m_axi_iofm_awcache),                  // output wire [3 : 0] m_axi_s2mm_awcache
        .m_axi_s2mm_awuser      (m_axi_iofm_awuser),                    // output wire [3 : 0] m_axi_s2mm_awuser
        .m_axi_s2mm_awvalid     (m_axi_iofm_awvalid),                  // output wire m_axi_s2mm_awvalid
        .m_axi_s2mm_awready     (m_axi_iofm_awready),                  // input wire m_axi_s2mm_awready
        .m_axi_s2mm_wdata       (m_axi_iofm_wdata),                      // output wire [127 : 0] m_axi_s2mm_wdata
        .m_axi_s2mm_wstrb       (m_axi_iofm_wstrb),                      // output wire [15 : 0] m_axi_s2mm_wstrb
        .m_axi_s2mm_wlast       (m_axi_iofm_wlast),                      // output wire m_axi_s2mm_wlast
        .m_axi_s2mm_wvalid      (m_axi_iofm_wvalid),                    // output wire m_axi_s2mm_wvalid
        .m_axi_s2mm_wready      (m_axi_iofm_wready),                    // input wire m_axi_s2mm_wready
        .m_axi_s2mm_bresp       (m_axi_iofm_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
        .m_axi_s2mm_bvalid      (m_axi_iofm_bvalid),                    // input wire m_axi_s2mm_bvalid
        .m_axi_s2mm_bready      (m_axi_iofm_bready),                    // output wire m_axi_s2mm_bready
        .s_axis_s2mm_tdata      (s_axis_s2mm_out_tdata),                    // input wire [127 : 0] s_axis_s2mm_tdata
        .s_axis_s2mm_tkeep      (s_axis_s2mm_out_tkeep),                    // input wire [15 : 0] s_axis_s2mm_tkeep
        .s_axis_s2mm_tlast      (s_axis_s2mm_out_tlast),                    // input wire s_axis_s2mm_tlast
        .s_axis_s2mm_tvalid     (s_axis_s2mm_out_tvalid),                  // input wire s_axis_s2mm_tvalid
        .s_axis_s2mm_tready     (s_axis_s2mm_out_tready)                  // output wire s_axis_s2mm_tready
    );

    axi_datamover_wgt axi_datamover_wgt_inst (
        .m_axi_mm2s_aclk(clk),                        // input wire m_axi_mm2s_aclk
        .m_axi_mm2s_aresetn(rst_n),                  // input wire m_axi_mm2s_aresetn
        .mm2s_err(mm2s_err_wgt),                                      // output wire mm2s_err
        .m_axis_mm2s_cmdsts_aclk(clk),        // input wire m_axis_mm2s_cmdsts_aclk
        .m_axis_mm2s_cmdsts_aresetn(rst_n),  // input wire m_axis_mm2s_cmdsts_aresetn
        .s_axis_mm2s_cmd_tvalid (s_axis_mm2s_cmd_wgt_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
        .s_axis_mm2s_cmd_tready (s_axis_mm2s_cmd_wgt_tready),          // output wire s_axis_mm2s_cmd_tready
        .s_axis_mm2s_cmd_tdata  (s_axis_mm2s_cmd_wgt_tdata),            // input wire [79 : 0] s_axis_mm2s_cmd_tdata
        .m_axis_mm2s_sts_tvalid (i_axis_mm2s_sts_wgt_tvalid),          // output wire m_axis_mm2s_sts_tvalid
        .m_axis_mm2s_sts_tready (i_axis_mm2s_sts_wgt_tready),          // input wire m_axis_mm2s_sts_tready
        .m_axis_mm2s_sts_tdata  (i_axis_mm2s_sts_wgt_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
        .m_axis_mm2s_sts_tkeep  (i_axis_mm2s_sts_wgt_tkeep),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
        .m_axis_mm2s_sts_tlast  (i_axis_mm2s_sts_wgt_tlast),            // output wire m_axis_mm2s_sts_tlast
        .m_axi_mm2s_arid        (m_axi_wgt_arid),                        // output wire [3 : 0] m_axi_mm2s_arid
        .m_axi_mm2s_araddr      (m_axi_wgt_araddr[35:0]),                    // output wire [35 : 0] m_axi_mm2s_araddr
        .m_axi_mm2s_arlen       (m_axi_wgt_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
        .m_axi_mm2s_arsize      (m_axi_wgt_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
        .m_axi_mm2s_arburst     (m_axi_wgt_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
        .m_axi_mm2s_arprot      (m_axi_wgt_arprot),                    // output wire [2 : 0] m_axi_mm2s_arprot
        .m_axi_mm2s_arcache     (m_axi_wgt_arcache),                  // output wire [3 : 0] m_axi_mm2s_arcache
        .m_axi_mm2s_aruser      (m_axi_wgt_aruser),                    // output wire [3 : 0] m_axi_mm2s_aruser
        .m_axi_mm2s_arvalid     (m_axi_wgt_arvalid),                  // output wire m_axi_mm2s_arvalid
        .m_axi_mm2s_arready     (m_axi_wgt_arready),                  // input wire m_axi_mm2s_arready
        .m_axi_mm2s_rdata       (m_axi_wgt_rdata),                      // input wire [127 : 0] m_axi_mm2s_rdata
        .m_axi_mm2s_rresp       (m_axi_wgt_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
        .m_axi_mm2s_rlast       (m_axi_wgt_rlast),                      // input wire m_axi_mm2s_rlast
        .m_axi_mm2s_rvalid      (m_axi_wgt_rvalid),                    // input wire m_axi_mm2s_rvalid
        .m_axi_mm2s_rready      (m_axi_wgt_rready),                    // output wire m_axi_mm2s_rready
        .m_axis_mm2s_tdata      (m_axis_mm2s_wgt_tdata),                    // output wire [127 : 0] m_axis_mm2s_tdata
        .m_axis_mm2s_tkeep      (m_axis_mm2s_wgt_tkeep),                    // output wire [15 : 0] m_axis_mm2s_tkeep
        .m_axis_mm2s_tlast      (m_axis_mm2s_wgt_tlast),                    // output wire m_axis_mm2s_tlast
        .m_axis_mm2s_tvalid     (m_axis_mm2s_wgt_tvalid),                  // output wire m_axis_mm2s_tvalid
        .m_axis_mm2s_tready     (m_axis_mm2s_wgt_tready)                  // input wire m_axis_mm2s_tready
    );

endmodule
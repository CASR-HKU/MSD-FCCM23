`timescale 1ns / 1ps

`include "def.sv"

module fthbs_top #(
    parameter PS_CTRL_AXI_ADDR_WIDTH = `DFLT_PS_CTRL_AXI_ADDR_WIDTH,
    parameter PS_CTRL_AXI_DATA_WIDTH = `DFLT_PS_CTRL_AXI_DATA_WIDTH,
    parameter AUX_AXI_ADDR_WIDTH     = `DFLT_AUX_AXI_ADDR_WIDTH,
    parameter AUX_AXI_DATA_WIDTH     = `DFLT_AUX_AXI_DATA_WIDTH,
    parameter CORE_AXI_ADDR_WIDTH    = `DFLT_CORE_AXI_ADDR_WIDTH,
    parameter CORE_AXI_DATA_WIDTH    = `DFLT_CORE_AXI_DATA_WIDTH
) (
    // common signal
    input  wire                                clk,
    input  wire                                rst_n,
    output wire                                interrupt,
    // s_axi_control, AXI4-Lite slave
    output wire                                s_axi_control_awready,
    input  wire                                s_axi_control_awvalid,
    input  wire [  PS_CTRL_AXI_ADDR_WIDTH-1:0] s_axi_control_awaddr,
    output wire                                s_axi_control_wready,
    input  wire                                s_axi_control_wvalid,
    input  wire [  PS_CTRL_AXI_DATA_WIDTH-1:0] s_axi_control_wdata,
    input  wire [PS_CTRL_AXI_DATA_WIDTH/8-1:0] s_axi_control_wstrb,
    input  wire                                s_axi_control_bready,
    output wire                                s_axi_control_bvalid,
    output wire [                         1:0] s_axi_control_bresp,
    output wire                                s_axi_control_arready,
    input  wire                                s_axi_control_arvalid,
    input  wire [  PS_CTRL_AXI_ADDR_WIDTH-1:0] s_axi_control_araddr,
    input  wire                                s_axi_control_rready,
    output wire                                s_axi_control_rvalid,
    output wire [  PS_CTRL_AXI_DATA_WIDTH-1:0] s_axi_control_rdata,
    output wire [                         1:0] s_axi_control_rresp,
    // m_axi_aux, AXI4 master
    // input  wire                                m_axi_aux_awready,
    // output wire                                m_axi_aux_awvalid,
    // output wire [      AUX_AXI_ADDR_WIDTH-1:0] m_axi_aux_awaddr,
    // output wire [                         7:0] m_axi_aux_awlen,
    // output wire [                         2:0] m_axi_aux_awsize,
    // output wire [                         1:0] m_axi_aux_awburst,
    // output wire [                         1:0] m_axi_aux_awlock,
    // output wire [                         3:0] m_axi_aux_awregion,
    // output wire [                         3:0] m_axi_aux_awcache,
    // output wire [                         2:0] m_axi_aux_awprot,
    // output wire [                         3:0] m_axi_aux_awqos,
    // input  wire                                m_axi_aux_wready,
    // output wire                                m_axi_aux_wvalid,
    // output wire [      AUX_AXI_DATA_WIDTH-1:0] m_axi_aux_wdata,
    // output wire [    AUX_AXI_DATA_WIDTH/8-1:0] m_axi_aux_wstrb,
    // output wire                                m_axi_aux_wlast,
    // output wire                                m_axi_aux_bready,
    // input  wire                                m_axi_aux_bvalid,
    // input  wire [                         1:0] m_axi_aux_bresp,
    input  wire                                m_axi_aux_arready,
    output wire                                m_axi_aux_arvalid,
    output wire [      AUX_AXI_ADDR_WIDTH-1:0] m_axi_aux_araddr,
    output wire [                         7:0] m_axi_aux_arlen,
    // output wire [                       2 : 0] m_axi_aux_arsize,
    // output wire [                       1 : 0] m_axi_aux_arburst,
    // output wire [                       1 : 0] m_axi_aux_arlock,
    // output wire [                       3 : 0] m_axi_aux_arregion,
    // output wire [                       3 : 0] m_axi_aux_arcache,
    // output wire [                       2 : 0] m_axi_aux_arprot,
    // output wire [                       3 : 0] m_axi_aux_arqos,
    output wire                                m_axi_aux_rready,
    input  wire                                m_axi_aux_rvalid,
    input  wire [      AUX_AXI_DATA_WIDTH-1:0] m_axi_aux_rdata,
    input  wire [                         1:0] m_axi_aux_rresp,
    input  wire                                m_axi_aux_rlast,
    // m_axi_iofm, AXI4 master
    input  wire                                m_axi_iofm_awready,
    output wire                                m_axi_iofm_awvalid,
    output wire [     CORE_AXI_ADDR_WIDTH-1:0] m_axi_iofm_awaddr,
    output wire [                         7:0] m_axi_iofm_awlen,
    output logic [3:0]                         m_axi_iofm_awid   ,
    output logic [2:0]                         m_axi_iofm_awsize ,
    output logic [1:0]                         m_axi_iofm_awburst,
    output logic [2:0]                         m_axi_iofm_awprot ,
    output logic [3:0]                         m_axi_iofm_awcache,
    output logic [3:0]                         m_axi_iofm_awuser ,
    input  wire                                m_axi_iofm_wready,
    output wire                                m_axi_iofm_wvalid,
    output wire [     CORE_AXI_DATA_WIDTH-1:0] m_axi_iofm_wdata,
    output wire [   CORE_AXI_DATA_WIDTH/8-1:0] m_axi_iofm_wstrb,
    output wire                                m_axi_iofm_wlast,
    output wire                                m_axi_iofm_bready,
    input  wire                                m_axi_iofm_bvalid,
    input  wire [                         1:0] m_axi_iofm_bresp,
    input  wire                                m_axi_iofm_arready,
    output wire                                m_axi_iofm_arvalid,
    output wire [     CORE_AXI_ADDR_WIDTH-1:0] m_axi_iofm_araddr,
    output wire [                         7:0] m_axi_iofm_arlen,
    output logic [3:0]                         m_axi_iofm_arid   ,
    output logic [2:0]                         m_axi_iofm_arsize ,
    output logic [1:0]                         m_axi_iofm_arburst,
    output logic [2:0]                         m_axi_iofm_arprot ,
    output logic [3:0]                         m_axi_iofm_arcache,
    output logic [3:0]                         m_axi_iofm_aruser ,
    output wire                                m_axi_iofm_rready,
    input  wire                                m_axi_iofm_rvalid,
    input  wire [     CORE_AXI_DATA_WIDTH-1:0] m_axi_iofm_rdata,
    input  wire [                         1:0] m_axi_iofm_rresp,
    input  wire                                m_axi_iofm_rlast,
    // m_axi_wgt, AXI4 master
    input  wire                                m_axi_wgt_arready,
    output wire                                m_axi_wgt_arvalid,
    output wire [     CORE_AXI_ADDR_WIDTH-1:0] m_axi_wgt_araddr,
    output wire [                         7:0] m_axi_wgt_arlen,
    output logic [3:0]                         m_axi_wgt_arid   ,
    output logic [2:0]                         m_axi_wgt_arsize ,
    output logic [1:0]                         m_axi_wgt_arburst,
    output logic [2:0]                         m_axi_wgt_arprot ,
    output logic [3:0]                         m_axi_wgt_arcache,
    output logic [3:0]                         m_axi_wgt_aruser ,
    output wire                                m_axi_wgt_rready,
    input  wire                                m_axi_wgt_rvalid,
    input  wire [     CORE_AXI_DATA_WIDTH-1:0] m_axi_wgt_rdata,
    input  wire [                         1:0] m_axi_wgt_rresp,
    input  wire                                m_axi_wgt_rlast
);

    /***************************************** PS control *****************************************/
    logic ap_start, ap_done, ap_idle, ap_ready;
    logic [31:0] aux_instr_scalar, aux_instr_status, aux_debug_scalar, aux_debug_status;
    logic [63:0] aux_instr_addr, aux_debug_addr;
    logic [                   3:0][31:0] core_scalar;
    logic [                   1:0][31:0] core_status;

    // instructions from aux to agna core
    logic                                i_axis_instr_tready;
    logic                                i_axis_instr_tvalid;
    logic [AUX_AXI_DATA_WIDTH-1:0]       i_axis_instr_tdata;

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            aux_debug_status <= 32'h0;
        end else begin
            aux_debug_status[15:0] <= (ap_start&ap_done)      ? aux_debug_status[15:0]+1 : aux_debug_status[15:0];
        end
    end

    ps_ctrl ps_ctrl_inst (
        // common signal
        .clk                  (clk),
        .rst_n                (rst_n),
        .clk_en               (1'b1),
        .interrupt            (interrupt),
        // s_axi_control, AXI4-Lite slave
        .s_axi_control_awready(s_axi_control_awready),
        .s_axi_control_awvalid(s_axi_control_awvalid),
        .s_axi_control_awaddr (s_axi_control_awaddr),
        .s_axi_control_wready (s_axi_control_wready),
        .s_axi_control_wvalid (s_axi_control_wvalid),
        .s_axi_control_wdata  (s_axi_control_wdata),
        .s_axi_control_wstrb  (s_axi_control_wstrb),
        .s_axi_control_bready (s_axi_control_bready),
        .s_axi_control_bvalid (s_axi_control_bvalid),
        .s_axi_control_bresp  (s_axi_control_bresp),
        .s_axi_control_arready(s_axi_control_arready),
        .s_axi_control_arvalid(s_axi_control_arvalid),
        .s_axi_control_araddr (s_axi_control_araddr),
        .s_axi_control_rready (s_axi_control_rready),
        .s_axi_control_rvalid (s_axi_control_rvalid),
        .s_axi_control_rdata  (s_axi_control_rdata),
        .s_axi_control_rresp  (s_axi_control_rresp),
        // ps_control signal
        .ap_start             (ap_start),
        .ap_done              (ap_done),
        .ap_idle              (ap_idle),
        .ap_ready             (ap_ready),
        .aux_instr_scalar     (aux_instr_scalar),
        .aux_instr_addr       (aux_instr_addr),
        .aux_instr_status     (aux_instr_status),
        .aux_debug_scalar     (aux_debug_scalar),
        .aux_debug_addr       (aux_debug_addr),
        .aux_debug_status     (aux_debug_status),
        .core_scalar          (core_scalar),
        .core_status          (core_status)
    );
    /***************************************** PS control *****************************************/

    /****************************************** anga aux ******************************************/
    aux_instr #(
        .AXI_ADDR_WIDTH  (AUX_AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH  (AUX_AXI_DATA_WIDTH),
        .INSTR_FIFO_DEPTH(512)
    ) aux_instr_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .ap_start       (ap_start),
        .ap_done        (ap_done),
        .ap_idle        (ap_idle),
        .ap_ready       (ap_ready),
        .num_instr      (aux_instr_scalar),
        .base_addr      (aux_instr_addr),
        .status         (aux_instr_status),
        .m_axi_arready  (m_axi_aux_arready),
        .m_axi_arvalid  (m_axi_aux_arvalid),
        .m_axi_araddr   (m_axi_aux_araddr),
        .m_axi_arlen    (m_axi_aux_arlen),
        .m_axi_rready   (m_axi_aux_rready),
        .m_axi_rvalid   (m_axi_aux_rvalid),
        .m_axi_rdata    (m_axi_aux_rdata),
        .m_axi_rresp    (m_axi_aux_rresp),
        .m_axi_rlast    (m_axi_aux_rlast),
        .m_instr_tready (i_axis_instr_tready),
        .m_instr_tvalid (i_axis_instr_tvalid),
        .m_instr_tdata  (i_axis_instr_tdata)
    );
    /****************************************** anga aux ******************************************/

    /***************************************** anga core ******************************************/
    sys_top sys_top_inst (
        // common signal
        .clk                         (clk                   ),
        .rst_n                       (rst_n                 ),
        .scalar                      (core_scalar[0]        ),
        .status                      (core_status           ),
        .m_axi_iofm_awready          (m_axi_iofm_awready    ),
        .m_axi_iofm_awvalid          (m_axi_iofm_awvalid    ),
        .m_axi_iofm_awaddr           (m_axi_iofm_awaddr     ),
        .m_axi_iofm_awlen            (m_axi_iofm_awlen      ),
        .m_axi_iofm_awid             (m_axi_iofm_awid       ),
        .m_axi_iofm_awsize           (m_axi_iofm_awsize     ),
        .m_axi_iofm_awburst          (m_axi_iofm_awburst    ),
        .m_axi_iofm_awprot           (m_axi_iofm_awprot     ),
        .m_axi_iofm_awcache          (m_axi_iofm_awcache    ),
        .m_axi_iofm_awuser           (m_axi_iofm_awuser     ),
        .m_axi_iofm_wready           (m_axi_iofm_wready     ),
        .m_axi_iofm_wvalid           (m_axi_iofm_wvalid     ),
        .m_axi_iofm_wdata            (m_axi_iofm_wdata      ),
        .m_axi_iofm_wstrb            (m_axi_iofm_wstrb      ),
        .m_axi_iofm_wlast            (m_axi_iofm_wlast      ),
        .m_axi_iofm_bready           (m_axi_iofm_bready     ),
        .m_axi_iofm_bvalid           (m_axi_iofm_bvalid     ),
        .m_axi_iofm_bresp            (m_axi_iofm_bresp      ),
        .m_axi_iofm_arready          (m_axi_iofm_arready    ),
        .m_axi_iofm_arvalid          (m_axi_iofm_arvalid    ),
        .m_axi_iofm_araddr           (m_axi_iofm_araddr     ),
        .m_axi_iofm_arlen            (m_axi_iofm_arlen      ),
        .m_axi_iofm_arid             (m_axi_iofm_arid       ),
        .m_axi_iofm_arsize           (m_axi_iofm_arsize     ),
        .m_axi_iofm_arburst          (m_axi_iofm_arburst    ),
        .m_axi_iofm_arprot           (m_axi_iofm_arprot     ),
        .m_axi_iofm_arcache          (m_axi_iofm_arcache    ),
        .m_axi_iofm_aruser           (m_axi_iofm_aruser     ),
        .m_axi_iofm_rready           (m_axi_iofm_rready     ),
        .m_axi_iofm_rvalid           (m_axi_iofm_rvalid     ),
        .m_axi_iofm_rdata            (m_axi_iofm_rdata      ),
        .m_axi_iofm_rresp            (m_axi_iofm_rresp      ),
        .m_axi_iofm_rlast            (m_axi_iofm_rlast      ),
        .m_axi_wgt_arready           (m_axi_wgt_arready     ),
        .m_axi_wgt_arvalid           (m_axi_wgt_arvalid     ),
        .m_axi_wgt_araddr            (m_axi_wgt_araddr      ),
        .m_axi_wgt_arlen             (m_axi_wgt_arlen       ),
        .m_axi_wgt_arid              (m_axi_wgt_arid        ),
        .m_axi_wgt_arsize            (m_axi_wgt_arsize      ),
        .m_axi_wgt_arburst           (m_axi_wgt_arburst     ),
        .m_axi_wgt_arprot            (m_axi_wgt_arprot      ),
        .m_axi_wgt_arcache           (m_axi_wgt_arcache     ),
        .m_axi_wgt_aruser            (m_axi_wgt_aruser      ),
        .m_axi_wgt_rready            (m_axi_wgt_rready      ),
        .m_axi_wgt_rvalid            (m_axi_wgt_rvalid      ),
        .m_axi_wgt_rdata             (m_axi_wgt_rdata       ),
        .m_axi_wgt_rresp             (m_axi_wgt_rresp       ),
        .m_axi_wgt_rlast             (m_axi_wgt_rlast       ),
        .s_axis_instr_tready         (i_axis_instr_tready   ),
        .s_axis_instr_tvalid         (i_axis_instr_tvalid   ),
        .s_axis_instr_tdata          (i_axis_instr_tdata    )
    );
    /***************************************** anga core ******************************************/

endmodule

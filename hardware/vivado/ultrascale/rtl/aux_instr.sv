`timescale 1ns / 1ps

module aux_instr #(
    parameter AXI_ADDR_WIDTH   = 64,
    parameter AXI_DATA_WIDTH   = 128,
    parameter INSTR_FIFO_DEPTH = 256
) (
    // common signal
    input  logic                      clk,
    input  logic                      rst_n,
    // control signal
    input  logic                      ap_start,
    output logic                      ap_done,
    output logic                      ap_idle,
    output logic                      ap_ready,
    input  logic [              31:0] num_instr,
    input  logic [              63:0] base_addr,
    output logic [              31:0] status,
    // m_axi READ, AXI4 master
    input  logic                      m_axi_arready,
    output logic                      m_axi_arvalid,
    output logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [               7:0] m_axi_arlen,
    output logic                      m_axi_rready,
    input  logic                      m_axi_rvalid,
    input  logic [AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [               1:0] m_axi_rresp,
    input  logic                      m_axi_rlast,
    // m_axis, AXI4-Stream master
    input  logic                      m_instr_tready,
    output logic                      m_instr_tvalid,
    output logic [AXI_DATA_WIDTH-1:0] m_instr_tdata
);

    ///////////////////////////////////////////////////////////////////////////////
    // Local Parameters
    ///////////////////////////////////////////////////////////////////////////////
    localparam INSTR_FIFO_DATA_COUNT_WIDTH = $clog2(INSTR_FIFO_DEPTH) + 1;

    ///////////////////////////////////////////////////////////////////////////////
    // Wires and Variables
    ///////////////////////////////////////////////////////////////////////////////

    // Module status
    logic ap_start_r, ap_start_p, ap_busy;
    // AR channel
    logic m_axi_ar_hs;
    // R channel
    logic m_axi_r_hs;
    logic m_axi_r_done;
    // write to fifo
    logic [AXI_DATA_WIDTH-1:0] i_fifo_tdata;
    logic i_fifo_tready, i_fifo_tvalid, i_fifo_tlast;
    logic [AXI_DATA_WIDTH/8-1:0] i_fifo_tkeep;
    // fifo
    logic [INSTR_FIFO_DATA_COUNT_WIDTH-1:0] instr_fifo_rd_cnt;
    logic [INSTR_FIFO_DATA_COUNT_WIDTH-1:0] instr_fifo_wr_cnt;
    // read from fifo
    logic m_instr_hs, m_instr_last_done, m_instr_tlast;
    logic [AXI_DATA_WIDTH/8-1:0] m_instr_tkeep;


    ///////////////////////////////////////////////////////////////////////////////
    // Begin RTL
    ///////////////////////////////////////////////////////////////////////////////

    /*****************/
    /* Module status */
    /*****************/
    always_comb begin
        ap_idle  = ~(ap_start | ap_busy);
        ap_ready = ap_done;
    end
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            ap_start_r <= 1'b0;
            ap_start_p <= 1'b0;
            ap_busy <= 1'b0;
            ap_done <= 1'b0;
        end else begin
            ap_start_r <= ap_start;
            ap_start_p <= &{~ap_start_p, ap_start, ~ap_start_r};  // a pulse on rising edge of ap_start
            ap_busy <= ap_done ? 1'b0 : ap_start ? 1'b1 : ap_busy;
            ap_done <= &{~ap_done, m_instr_last_done};
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            status <= 0;
        end else begin
            status[31:24] <= m_axi_ar_hs ? status[31:24] + 1 : status[31:24];
            status[23:16] <= m_axi_r_hs ? status[23:16] + 1 : status[23:16];
            status[15:8]  <= m_instr_hs ? status[15:8] + 1 : status[15:8];
            status[7:0]   <= (m_axi_r_hs & (m_axi_rresp == 2'b00)) ? status[7:0] + 1 : status[7:0];
        end
    end

    /******************/
    /* AXI AR channel */
    /******************/
    always_comb begin
        m_axi_ar_hs = m_axi_arready & m_axi_arvalid;
    end

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            m_axi_arvalid <= 1'b0;
            m_axi_araddr  <= 'b0;
            m_axi_arlen   <= 'b0;
        end else begin
            m_axi_arvalid <= ap_start_p ? 1'b1 : m_axi_ar_hs ? 1'b0 : m_axi_arvalid;
            m_axi_araddr  <= ap_busy ? base_addr[AXI_ADDR_WIDTH-1:0] : 'b0;
            m_axi_arlen   <= ap_busy ? num_instr[7:0] - 1 : 'b0;
        end
    end

    /*****************/
    /* AXI R channel */
    /*****************/
    always_comb begin
        // m_axi_r
        m_axi_r_hs    = m_axi_rvalid & m_axi_rready;
        m_axi_r_done  = m_axi_rlast & m_axi_r_hs;
        // m_axi_r to s_fifo
        m_axi_rready  = i_fifo_tready;
        i_fifo_tvalid = m_axi_rvalid;
        i_fifo_tdata  = m_axi_rdata;
        i_fifo_tkeep  = {(AXI_DATA_WIDTH / 8) {1'b1}};
        i_fifo_tlast  = m_axi_rlast;
        // m_fifo to m_axis
        m_instr_hs = m_instr_tvalid & m_instr_tready;
        m_instr_last_done = m_instr_tlast & m_instr_hs;
    end

    /**************/
    /* INSTR FIFO */
    /**************/

    fifo_axis #(
        .FIFO_AXIS_DEPTH      (INSTR_FIFO_DEPTH),
        .FIFO_AXIS_TDATA_WIDTH(AXI_DATA_WIDTH),
        .FIFO_DATA_COUNT_WIDTH(INSTR_FIFO_DATA_COUNT_WIDTH),
        .FIFO_ADV_FEATURES    ("1414")
    ) instr_fifo (
        //common signal
        .clk               (clk),
        .rst_n             (rst_n),
        // s_axis
        .s_axis_tready     (i_fifo_tready),
        .s_axis_tvalid     (i_fifo_tvalid),
        .s_axis_tdata      (i_fifo_tdata),
        .s_axis_tkeep      (i_fifo_tkeep),
        .s_axis_tlast      (i_fifo_tlast),
        // m_axis
        .m_axis_tready     (m_instr_tready),
        .m_axis_tvalid     (m_instr_tvalid),
        .m_axis_tdata      (m_instr_tdata),
        .m_axis_tkeep      (m_instr_tkeep),
        .m_axis_tlast      (m_instr_tlast)
    );

endmodule

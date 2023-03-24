`timescale 1ns / 1ps

`include "def.sv"

module ps_ctrl #(
    parameter PS_CTRL_AXI_ADDR_WIDTH = `DFLT_PS_CTRL_AXI_ADDR_WIDTH,
    parameter PS_CTRL_AXI_DATA_WIDTH = `DFLT_PS_CTRL_AXI_DATA_WIDTH
) (
    // common signal
    input  wire                                      clk,
    input  wire                                      rst_n,
    input  wire                                      clk_en,
    output wire                                      interrupt,
    // s_axi_control, AXI4-Lite slave
    output wire                                      s_axi_control_awready,
    input  wire                                      s_axi_control_awvalid,
    input  wire [  PS_CTRL_AXI_ADDR_WIDTH-1:0]       s_axi_control_awaddr,
    output wire                                      s_axi_control_wready,
    input  wire                                      s_axi_control_wvalid,
    input  wire [  PS_CTRL_AXI_DATA_WIDTH-1:0]       s_axi_control_wdata,
    input  wire [PS_CTRL_AXI_DATA_WIDTH/8-1:0]       s_axi_control_wstrb,
    input  wire                                      s_axi_control_bready,
    output wire                                      s_axi_control_bvalid,
    output wire [                         1:0]       s_axi_control_bresp,
    output wire                                      s_axi_control_arready,
    input  wire                                      s_axi_control_arvalid,
    input  wire [  PS_CTRL_AXI_ADDR_WIDTH-1:0]       s_axi_control_araddr,
    input  wire                                      s_axi_control_rready,
    output wire                                      s_axi_control_rvalid,
    output wire [  PS_CTRL_AXI_DATA_WIDTH-1:0]       s_axi_control_rdata,
    output wire [                         1:0]       s_axi_control_rresp,
    // ps_control signal
    output wire                                      ap_start,
    input  wire                                      ap_done,
    input  wire                                      ap_idle,
    input  wire                                      ap_ready,
    output wire [                        31:0]       aux_instr_scalar,
    output wire [                        63:0]       aux_instr_addr,
    input  wire [                        31:0]       aux_instr_status,
    output wire [                        31:0]       aux_debug_scalar,
    output wire [                        63:0]       aux_debug_addr,
    input  wire [                        31:0]       aux_debug_status,
    output wire [                         3:0][31:0] core_scalar,
    input  wire [                         1:0][31:0] core_status
);
    //------------------------System Address Info-------------------
    // 0x00 : Control signals
    //        bit 0  - ap_start (Read/Write/COH)
    //        bit 1  - ap_done (Read/COR)
    //        bit 2  - ap_idle (Read)
    //        bit 3  - ap_ready (Read)
    //        bit 7  - auto_restart (Read/Write)
    //        others - reserved
    // 0x04 : Global Interrupt Enable Register
    //        bit 0  - Global Interrupt Enable (Read/Write)
    //        others - reserved
    // 0x08 : IP Interrupt Enable Register (Read/Write)
    //        bit 0  - Channel 0 (ap_done)
    //        bit 1  - Channel 1 (ap_ready)
    //        others - reserved
    // 0x0c : IP Interrupt Core_status Register (Read/TOW)
    //        bit 0  - Channel 0 (ap_done)
    //        bit 1  - Channel 1 (ap_ready)
    //        others - reserved
    // (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)


    //------------------------User Address Info-------------------

    // aux_instr_scalar: 0x10 (Read/Write)
    // aux_instr_addr_l: 0x14 (Read/Write)
    // aux_instr_addr_h: 0x18 (Read/Write)
    // aux_instr_status: 0x1c (Read)

    // aux_debug_scalar: 0x20 (Read/Write)
    // aux_debug_addr_l: 0x24 (Read/Write)
    // aux_debug_addr_h: 0x28 (Read/Write)
    // aux_debug_status: 0x2c (Read)

    // core_scalar[0]:   0x30 (Read/Write)
    // core_scalar[1]:   0x34 (Read/Write)
    // core_scalar[2]:   0x38 (Read/Write)
    // core_scalar[3]:   0x3C (Read/Write)

    // core_status[0]:   0x40 (Read)
    // core_status[1]:   0x44 (Read)

    // 0x50 : reserved
    // ...
    // 0xff : reserved

    //------------------------Address Parameter----------------------
    localparam
    ADDR_BITS               = PS_CTRL_AXI_ADDR_WIDTH,
    ADDR_AP_CTRL            = 8'h00,
    ADDR_GIE                = 8'h04,
    ADDR_IER                = 8'h08,
    ADDR_ISR                = 8'h0c,
    ADDR_AUX_INSTR_SCALAR   = 8'h10,
    ADDR_AUX_INSTR_ADDR_L   = 8'h14,
    ADDR_AUX_INSTR_ADDR_H   = 8'h18,
    ADDR_AUX_INSTR_STATUS   = 8'h1c,
    ADDR_AUX_DEBUG_SCALAR   = 8'h20,
    ADDR_AUX_DEBUG_ADDR_L   = 8'h24,
    ADDR_AUX_DEBUG_ADDR_H   = 8'h28,
    ADDR_AUX_DEBUG_STATUS   = 8'h2c,
    ADDR_CORE_SCALAR_0      = 8'h30,
    ADDR_CORE_SCALAR_1      = 8'h34,
    ADDR_CORE_SCALAR_2      = 8'h38,
    ADDR_CORE_SCALAR_3      = 8'h3c,
    ADDR_CORE_STATUS_0      = 8'h40,
    ADDR_CORE_STATUS_1      = 8'h44;
    //------------------------FSM Parameter----------------------
    localparam
    WRIDLE               = 2'd0,
    WRDATA               = 2'd1,
    WRRESP               = 2'd2,
    WRRESET              = 2'd3,
    RDIDLE               = 2'd0,
    RDDATA               = 2'd1,
    RDRESET              = 2'd2;

    //------------------------Local signal-------------------
    reg  [          1:0]       wstate = WRRESET;
    reg  [          1:0]       wnext;
    reg  [ADDR_BITS-1:0]       waddr;
    wire [         31:0]       wmask;
    wire                       aw_hs;
    wire                       w_hs;
    reg  [          1:0]       rstate = RDRESET;
    reg  [          1:0]       rnext;
    reg  [         31:0]       rdata;
    wire                       ar_hs;
    wire [ADDR_BITS-1:0]       raddr;
    // internal registers
    reg                        int_ap_idle;
    reg                        int_ap_ready;
    reg                        int_ap_done = 1'b0;
    reg                        int_ap_start = 1'b0;
    reg                        int_auto_restart = 1'b0;
    reg                        int_gie = 1'b0;
    reg  [          1:0]       int_ier = 2'b0;
    reg  [          1:0]       int_isr = 2'b0;
    reg  [         31:0]       int_aux_instr_scalar = 'b0;
    reg  [         63:0]       int_aux_instr_addr = 'b0;
    reg  [         31:0]       int_aux_debug_scalar = 'b0;
    reg  [         63:0]       int_aux_debug_addr = 'b0;
    reg  [          3:0][31:0] int_core_scalar = 'b0;

    //------------------------Instantiation------------------

    //------------------------AXI write fsm------------------
    assign s_axi_control_awready = (wstate == WRIDLE);
    assign s_axi_control_wready = (wstate == WRDATA);
    assign s_axi_control_bresp = 2'b00;  // OKAY
    assign s_axi_control_bvalid = (wstate == WRRESP);
    assign wmask = {
        {8{s_axi_control_wstrb[3]}},
        {8{s_axi_control_wstrb[2]}},
        {8{s_axi_control_wstrb[1]}},
        {8{s_axi_control_wstrb[0]}}
    };
    assign aw_hs = s_axi_control_awvalid & s_axi_control_awready;
    assign w_hs = s_axi_control_wvalid & s_axi_control_wready;

    // wstate
    always @(posedge clk) begin
        if (~rst_n) wstate <= WRRESET;
        else if (clk_en) wstate <= wnext;
    end

    // wnext
    always @(*) begin
        case (wstate)
            WRIDLE:  if (s_axi_control_awvalid) wnext = WRDATA;
 else wnext = WRIDLE;
            WRDATA:  if (s_axi_control_wvalid) wnext = WRRESP;
 else wnext = WRDATA;
            WRRESP:  if (s_axi_control_bready) wnext = WRIDLE;
 else wnext = WRRESP;
            default: wnext = WRIDLE;
        endcase
    end

    // waddr
    always @(posedge clk) begin
        if (clk_en) begin
            if (aw_hs) waddr <= s_axi_control_awaddr[ADDR_BITS-1:0];
        end
    end

    //------------------------AXI read fsm-------------------
    assign s_axi_control_arready = (rstate == RDIDLE);
    assign s_axi_control_rdata = rdata;
    assign s_axi_control_rresp = 2'b00;  // OKAY
    assign s_axi_control_rvalid = (rstate == RDDATA);
    assign ar_hs = s_axi_control_arvalid & s_axi_control_arready;
    assign raddr = s_axi_control_araddr[ADDR_BITS-1:0];

    // rstate
    always @(posedge clk) begin
        if (~rst_n) rstate <= RDRESET;
        else if (clk_en) rstate <= rnext;
    end

    // rnext
    always @(*) begin
        case (rstate)
            RDIDLE:
            if (s_axi_control_arvalid) rnext = RDDATA;
            else rnext = RDIDLE;
            RDDATA:
            if (s_axi_control_rready & s_axi_control_rvalid) rnext = RDIDLE;
            else rnext = RDDATA;
            default: rnext = RDIDLE;
        endcase
    end

    // rdata
    always @(posedge clk) begin
        if (clk_en) begin
            if (ar_hs) begin
                rdata <= 32'b0;
                case (raddr)
                    ADDR_AP_CTRL: begin
                        rdata[0] <= int_ap_start;
                        rdata[1] <= int_ap_done;
                        rdata[2] <= int_ap_idle;
                        rdata[3] <= int_ap_ready;
                        rdata[7] <= int_auto_restart;
                    end
                    ADDR_GIE: begin
                        rdata <= int_gie;
                    end
                    ADDR_IER: begin
                        rdata <= int_ier;
                    end
                    ADDR_ISR: begin
                        rdata <= int_isr;
                    end
                    ADDR_AUX_INSTR_SCALAR: begin
                        rdata <= int_aux_instr_scalar;
                    end
                    ADDR_AUX_INSTR_ADDR_L: begin
                        rdata <= int_aux_instr_addr[31:0];
                    end
                    ADDR_AUX_INSTR_ADDR_H: begin
                        rdata <= int_aux_instr_addr[63:32];
                    end
                    ADDR_AUX_INSTR_STATUS: begin
                        rdata <= aux_instr_status;
                    end
                    ADDR_AUX_DEBUG_SCALAR: begin
                        rdata <= int_aux_debug_scalar;
                    end
                    ADDR_AUX_DEBUG_ADDR_L: begin
                        rdata <= int_aux_debug_addr[31:0];
                    end
                    ADDR_AUX_DEBUG_ADDR_H: begin
                        rdata <= int_aux_debug_addr[63:32];
                    end
                    ADDR_AUX_DEBUG_STATUS: begin
                        rdata <= aux_debug_status;
                    end
                    ADDR_CORE_SCALAR_0: begin
                        rdata <= int_core_scalar[0];
                    end
                    ADDR_CORE_SCALAR_1: begin
                        rdata <= int_core_scalar[1];
                    end
                    ADDR_CORE_SCALAR_2: begin
                        rdata <= int_core_scalar[2];
                    end
                    ADDR_CORE_SCALAR_3: begin
                        rdata <= int_core_scalar[3];
                    end
                    ADDR_CORE_STATUS_0: begin
                        rdata <= core_status[0];
                    end
                    ADDR_CORE_STATUS_1: begin
                        rdata <= core_status[1];
                    end
                endcase
            end
        end
    end


    //------------------------Register logic-----------------
    assign interrupt        = int_gie & (|int_isr);
    assign ap_start         = int_ap_start;
    assign aux_instr_scalar = int_aux_instr_scalar;
    assign aux_instr_addr   = int_aux_instr_addr;
    assign aux_debug_scalar = int_aux_debug_scalar;
    assign aux_debug_addr   = int_aux_debug_addr;
    assign core_scalar      = int_core_scalar;

    // int_ap_start
    always @(posedge clk) begin
        if (~rst_n) int_ap_start <= 1'b0;
        else if (clk_en) begin
            if (w_hs && waddr == ADDR_AP_CTRL && s_axi_control_wstrb[0] && s_axi_control_wdata[0])
                int_ap_start <= 1'b1;
            else if (ap_done) int_ap_start <= int_auto_restart;  // clear on handshake/auto restart
        end
    end

    // int_ap_done
    always @(posedge clk) begin
        if (~rst_n) int_ap_done <= 1'b0;
        else if (clk_en) begin
            if (ap_done) int_ap_done <= 1'b1;
            else if (ar_hs && raddr == ADDR_AP_CTRL) int_ap_done <= 1'b0;  // clear on read
        end
    end

    // int_ap_idle
    always @(posedge clk) begin
        if (~rst_n) int_ap_idle <= 1'b0;
        else if (clk_en) begin
            int_ap_idle <= ap_idle;
        end
    end

    // int_ap_ready
    always @(posedge clk) begin
        if (~rst_n) int_ap_ready <= 1'b0;
        else if (clk_en) begin
            int_ap_ready <= ap_ready;
        end
    end

    // int_auto_restart
    always @(posedge clk) begin
        if (~rst_n) int_auto_restart <= 1'b0;
        else if (clk_en) begin
            if (w_hs && waddr == ADDR_AP_CTRL && s_axi_control_wstrb[0])
                int_auto_restart <= s_axi_control_wdata[7];
        end
    end

    // int_gie
    always @(posedge clk) begin
        if (~rst_n) int_gie <= 1'b0;
        else if (clk_en) begin
            if (w_hs && waddr == ADDR_GIE && s_axi_control_wstrb[0])
                int_gie <= s_axi_control_wdata[0];
        end
    end

    // int_ier
    always @(posedge clk) begin
        if (~rst_n) int_ier <= 1'b0;
        else if (clk_en) begin
            if (w_hs && waddr == ADDR_IER && s_axi_control_wstrb[0])
                int_ier <= s_axi_control_wdata[1:0];
        end
    end

    // int_isr[0]
    always @(posedge clk) begin
        if (~rst_n) int_isr[0] <= 1'b0;
        else if (clk_en) begin
            if (int_ier[0] & ap_done) int_isr[0] <= 1'b1;
            else if (w_hs && waddr == ADDR_ISR && s_axi_control_wstrb[0])
                int_isr[0] <= int_isr[0] ^ s_axi_control_wdata[0];  // toggle on write
        end
    end

    // int_isr[1]
    always @(posedge clk) begin
        if (~rst_n) int_isr[1] <= 1'b0;
        else if (clk_en) begin
            if (int_ier[1] & ap_ready) int_isr[1] <= 1'b1;
            else if (w_hs && waddr == ADDR_ISR && s_axi_control_wstrb[0])
                int_isr[1] <= int_isr[1] ^ s_axi_control_wdata[1];  // toggle on write
        end
    end
    //int_instr
    always @(posedge clk) begin
        if (~rst_n) begin
            int_aux_instr_scalar = 32'hAAAA_0000;
            int_aux_instr_addr   = 64'hAAAA_0000;
        end else if (w_hs) begin
            if (waddr == ADDR_AUX_INSTR_SCALAR)
                int_aux_instr_scalar = (s_axi_control_wdata&wmask) | (int_aux_instr_scalar&~wmask);
            else if (waddr == ADDR_AUX_INSTR_ADDR_L)
                int_aux_instr_addr[31:0] = (s_axi_control_wdata&wmask) | (int_aux_instr_addr[31:0]&~wmask);
            else if (waddr == ADDR_AUX_INSTR_ADDR_H)
                int_aux_instr_addr[63:32] = (s_axi_control_wdata&wmask) | (int_aux_instr_addr[63:32]&~wmask);
        end
    end

    //int_debug
    always @(posedge clk) begin
        if (~rst_n) begin
            int_aux_debug_scalar = 32'hBBBB_0000;
            int_aux_debug_addr   = 64'hBBBB_0000;
        end else if (w_hs) begin
            if (waddr == ADDR_AUX_DEBUG_SCALAR)
                int_aux_debug_scalar = (s_axi_control_wdata&wmask) | (int_aux_debug_scalar&~wmask);
            else if (waddr == ADDR_AUX_DEBUG_ADDR_L)
                int_aux_debug_addr[31:0] = (s_axi_control_wdata&wmask) | (int_aux_debug_addr[31:0]&~wmask);
            else if (waddr == ADDR_AUX_DEBUG_ADDR_H)
                int_aux_debug_addr[63:32] = (s_axi_control_wdata&wmask) | (int_aux_debug_addr[63:32]&~wmask);
        end
    end
    //int_core_scalar
    always @(posedge clk) begin
        if (~rst_n) int_core_scalar = 'b0;
        else if (w_hs) begin
            if (waddr == ADDR_CORE_SCALAR_0)
                int_core_scalar[0] = (s_axi_control_wdata & wmask) | (int_core_scalar[0] & ~wmask);
            else if (waddr == ADDR_CORE_SCALAR_1)
                int_core_scalar[1] = (s_axi_control_wdata & wmask) | (int_core_scalar[1] & ~wmask);
            else if (waddr == ADDR_CORE_SCALAR_2)
                int_core_scalar[2] = (s_axi_control_wdata & wmask) | (int_core_scalar[2] & ~wmask);
            else if (waddr == ADDR_CORE_SCALAR_3)
                int_core_scalar[3] = (s_axi_control_wdata & wmask) | (int_core_scalar[3] & ~wmask);
        end
    end

    //------------------------Memory logic-------------------

endmodule

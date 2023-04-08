`timescale 1ns / 1ps

`include "../rtl/def.sv"

`include "tb_itf.sv"
`include "tb_drv.sv"

module sys_top_tb;

    localparam CLK_PERIOD = 10;

    localparam AXI_ADDR_WIDTH = `DFLT_CORE_AXI_ADDR_WIDTH;
    localparam AXI_DATA_WIDTH = 64;
    localparam MEM_INSTR_USER_WIDTH = 1;

    localparam MEM_INSTR_LEN = 64;

    logic [31:0] scalar = 0;
    logic [1:0][31:0] status;

    clkrst_itf clkrst_i ();
    clkrst_drv #(
        .CLK_PERIOD(CLK_PERIOD),
        .RST_CYCLE (1)
    ) common_d;

    axi_itf #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_iofm_i ();
    s_axi_drv #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_iofm_d;

    axi_itf #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_wgt_i ();
    s_axi_drv #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_wgt_d;

    axis_itf #(
        .AXIS_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXIS_USER_WIDTH(MEM_INSTR_USER_WIDTH)
    ) axis_instr_i ();
    m_axis_drv #(
        .AXIS_DATA_WIDTH(AXI_DATA_WIDTH),
        .STREAM_LEN(MEM_INSTR_LEN)
    ) m_axis_instr_d;

    logic [AXI_DATA_WIDTH-1:0] instr_data_arr[MEM_INSTR_LEN] = '{default: 0};
    logic [MEM_INSTR_USER_WIDTH-1:0] instr_user_arr[MEM_INSTR_LEN] = '{default: 0};

    initial begin
        instr_data_arr[0]   = 64'h8001022801390199;
        instr_data_arr[1]   = 64'h9200400093000126;
        instr_data_arr[2]   = 64'ha0020004050002df;
        instr_data_arr[3]   = 64'hb002df0341000cc8;
        instr_data_arr[4]   = 64'hc000000705001b08;
        instr_data_arr[5]   = 64'hd000310016900000;
        instr_data_arr[6]   = 64'he000000016860000;
        instr_data_arr[7]   = 64'hf000000016d00000;
        instr_data_arr[8]   = 64'h8001021c01320320;
        instr_data_arr[9]   = 64'h9200240090000120;
        instr_data_arr[10]  = 64'ha002000630000510;
        instr_data_arr[11]  = 64'hb004bf0561001900;
        instr_data_arr[12]  = 64'hc000000b09001a70;
        instr_data_arr[13]  = 64'hd000510016900000;
        instr_data_arr[14]  = 64'he000000016860000;
        instr_data_arr[15]  = 64'hf000000016d00000;
        instr_data_arr[16]  = 64'h8001021c01320320;
        instr_data_arr[17]  = 64'h9200240090000120;
        instr_data_arr[18]  = 64'ha002000630000510;
        instr_data_arr[19]  = 64'hb004bf0561001900;
        instr_data_arr[20]  = 64'hc000000b09001a70;
        instr_data_arr[21]  = 64'hd000510016900000;
        instr_data_arr[22]  = 64'he000000016860000;
        instr_data_arr[23]  = 64'hf000000016d00000;
        instr_data_arr[24]  = 64'h8001021c01320320;
        instr_data_arr[25]  = 64'h9200240090000120;
        instr_data_arr[26]  = 64'ha002000630000510;
        instr_data_arr[27]  = 64'hb004bf0561001900;
        instr_data_arr[28]  = 64'hc000000b09001a70;
        instr_data_arr[29]  = 64'hd000510016900000;
        instr_data_arr[30]  = 64'he000000016860000;
        instr_data_arr[31]  = 64'hf000000016d00000;
        instr_data_arr[32]  = 64'h8001021c01320320;
        instr_data_arr[33]  = 64'h9200240090000120;
        instr_data_arr[34]  = 64'ha002000630000510;
        instr_data_arr[35]  = 64'hb004bf0561001900;
        instr_data_arr[36]  = 64'hc000000b09001a70;
        instr_data_arr[37]  = 64'hd000510016900000;
        instr_data_arr[38]  = 64'he000000016860000;
        instr_data_arr[39]  = 64'hf000000016d00000;
        instr_data_arr[40]  = 64'h8001021c01320692;
        instr_data_arr[41]  = 64'h9200200090000120;
        instr_data_arr[42]  = 64'ha0020003f00002d0;
        instr_data_arr[43]  = 64'hb002df0341003490;
        instr_data_arr[44]  = 64'hc000000705001a70;
        instr_data_arr[45]  = 64'hd000310016900000;
        instr_data_arr[46]  = 64'he000000016860000;
        instr_data_arr[47]  = 64'hf000000016d00000;
        instr_data_arr[48]  = 64'h8001021c01320620;
        instr_data_arr[49]  = 64'h9200100090000120;
        instr_data_arr[50]  = 64'ha002000cf0000990;
        instr_data_arr[51]  = 64'hb009e70b39003100;
        instr_data_arr[52]  = 64'hc000001711001a70;
        instr_data_arr[53]  = 64'hd000a90016900000;
        instr_data_arr[54]  = 64'he000000016860000;
        instr_data_arr[55]  = 64'hf000000016d00000;
        instr_data_arr[56]  = 64'h8001019c00320d24;
        instr_data_arr[57]  = 64'h9200080020000040;
        instr_data_arr[58]  = 64'ha0070001000000c0;
        instr_data_arr[59]  = 64'hb00b5102c0006920;
        instr_data_arr[60]  = 64'hc000000806000e70;
        instr_data_arr[61]  = 64'hd100708816900000;
        instr_data_arr[62]  = 64'he000000016860000;
        instr_data_arr[63]  = 64'hf000000016d00000;
        // instr_data_arr[64]  = 64'h80000024002401010201003b00070039;
        // instr_data_arr[65]  = 64'ha0000000002408000029000a00004802;
        // instr_data_arr[66]  = 64'hc0000000000003300000000420000390;
        // instr_data_arr[67]  = 64'he000000078280000780c000498080390;
        // instr_data_arr[68]  = 64'h80000080004002020803024000e00100;
        // instr_data_arr[69]  = 64'ha000000000800008024001c000008002;
        // instr_data_arr[70]  = 64'hc0000000000040000000003200001000;
        // instr_data_arr[71]  = 64'he000000078280000780c003278081000;
        // instr_data_arr[72]  = 64'h80000024002401010201003b00070039;
        // instr_data_arr[73]  = 64'ha0000000002408000029000a00004802;
        // instr_data_arr[74]  = 64'hc0000000000003300000000420000390;
        // instr_data_arr[75]  = 64'he000000078280000780c000498080390;
        // instr_data_arr[76]  = 64'h80000024002401010201003b00070039;
        // instr_data_arr[77]  = 64'ha0000000002408000029000a00004802;
        // instr_data_arr[78]  = 64'hc0000000000003300000000420000390;
        // instr_data_arr[79]  = 64'he000000078280000780c000498080390;
        // instr_data_arr[80]  = 64'h81000004000401010201000800010001;
        // instr_data_arr[81]  = 64'ha000000000040c800002000100000802;
        // instr_data_arr[82]  = 64'hc0000000000000300000000090000010;
        // instr_data_arr[83]  = 64'he000000078280000780c000108080010;
    end

    initial begin
        common_d = new;
        common_d.clkrst_i = clkrst_i;

        axi_iofm_d = new;
        axi_iofm_d.clkrst_i = clkrst_i;
        axi_iofm_d.axi_i = axi_iofm_i;

        axi_wgt_d = new;
        axi_wgt_d.clkrst_i = clkrst_i;
        axi_wgt_d.axi_i = axi_wgt_i;

        m_axis_instr_d = new;
        m_axis_instr_d.clkrst_i = clkrst_i;
        m_axis_instr_d.axis_i = axis_instr_i;
        m_axis_instr_d.set_data_arr(instr_data_arr);
        m_axis_instr_d.set_user_arr(instr_user_arr);


        fork
            common_d.run();
            axi_iofm_d.run();
            axi_wgt_d.run();
            m_axis_instr_d.run();
        join_none

        @(m_axis_instr_d.drv_done);
        // repeat(60) @(posedge clkrst_i.clk);
        // $stop;
    end

    sys_top sys_top_inst (
        // common signal
        .clk                (clkrst_i.clk),
        .rst_n              (clkrst_i.rst_n),
        // control signal
        .scalar             (scalar),
        .status             (status),
        // m_axi for iofm
        .m_axi_iofm_awready (axi_iofm_i.awready),
        .m_axi_iofm_awvalid (axi_iofm_i.awvalid),
        .m_axi_iofm_awaddr  (axi_iofm_i.awaddr),
        .m_axi_iofm_awlen   (axi_iofm_i.awlen),
        .m_axi_iofm_awid    (axi_iofm_i.awid),
        .m_axi_iofm_awsize  (axi_iofm_i.awsize),
        .m_axi_iofm_awburst (axi_iofm_i.awburst),
        .m_axi_iofm_awprot  (axi_iofm_i.awprot),
        .m_axi_iofm_awcache (axi_iofm_i.awcache),
        .m_axi_iofm_awuser  (axi_iofm_i.awuser),
        .m_axi_iofm_wready  (axi_iofm_i.wready),
        .m_axi_iofm_wvalid  (axi_iofm_i.wvalid),
        .m_axi_iofm_wdata   (axi_iofm_i.wdata),
        .m_axi_iofm_wstrb   (axi_iofm_i.wstrb),
        .m_axi_iofm_wlast   (axi_iofm_i.wlast),
        .m_axi_iofm_bready  (axi_iofm_i.bready),
        .m_axi_iofm_bvalid  (axi_iofm_i.bvalid),
        .m_axi_iofm_bresp   (axi_iofm_i.bresp),
        .m_axi_iofm_arready (axi_iofm_i.arready),
        .m_axi_iofm_arvalid (axi_iofm_i.arvalid),
        .m_axi_iofm_araddr  (axi_iofm_i.araddr),
        .m_axi_iofm_arlen   (axi_iofm_i.arlen),
        .m_axi_iofm_arid    (axi_iofm_i.arid),
        .m_axi_iofm_arsize  (axi_iofm_i.arsize),
        .m_axi_iofm_arburst (axi_iofm_i.arburst),
        .m_axi_iofm_arprot  (axi_iofm_i.arprot),
        .m_axi_iofm_arcache (axi_iofm_i.arcache),
        .m_axi_iofm_aruser  (axi_iofm_i.aruser),
        .m_axi_iofm_rready  (axi_iofm_i.rready),
        .m_axi_iofm_rvalid  (axi_iofm_i.rvalid),
        .m_axi_iofm_rdata   (axi_iofm_i.rdata),
        .m_axi_iofm_rresp   (axi_iofm_i.rresp),
        .m_axi_iofm_rlast   (axi_iofm_i.rlast),
        // m_axi for wgt
        .m_axi_wgt_arready  (axi_wgt_i.arready),
        .m_axi_wgt_arvalid  (axi_wgt_i.arvalid),
        .m_axi_wgt_araddr   (axi_wgt_i.araddr),
        .m_axi_wgt_arlen    (axi_wgt_i.arlen),
        .m_axi_wgt_arid     (axi_wgt_i.arid),
        .m_axi_wgt_arsize   (axi_wgt_i.arsize),
        .m_axi_wgt_arburst  (axi_wgt_i.arburst),
        .m_axi_wgt_arprot   (axi_wgt_i.arprot),
        .m_axi_wgt_arcache  (axi_wgt_i.arcache),
        .m_axi_wgt_aruser   (axi_wgt_i.aruser),
        .m_axi_wgt_rready   (axi_wgt_i.rready),
        .m_axi_wgt_rvalid   (axi_wgt_i.rvalid),
        .m_axi_wgt_rdata    (axi_wgt_i.rdata),
        .m_axi_wgt_rresp    (axi_wgt_i.rresp),
        .m_axi_wgt_rlast    (axi_wgt_i.rlast),
        // input axis_instr
        .s_axis_instr_tready(axis_instr_i.tready),
        .s_axis_instr_tvalid(axis_instr_i.tvalid),
        .s_axis_instr_tdata (axis_instr_i.tdata)
    );

endmodule

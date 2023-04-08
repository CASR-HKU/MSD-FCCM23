`timescale 1ns / 1ps

`include "../rtl/def.sv"

`include "tb_itf.sv"
`include "tb_drv.sv"

module sys_top_tb;

    localparam CLK_PERIOD = 10;

    localparam AXI_ADDR_WIDTH = `DFLT_CORE_AXI_ADDR_WIDTH;
    localparam AXI_DATA_WIDTH = `DFLT_CORE_AXI_DATA_WIDTH;
    localparam MEM_INSTR_USER_WIDTH = 1;

    localparam MEM_INSTR_LEN = 32;

    logic [31:0] scalar = 0;
    logic [31:0] status;

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
        instr_data_arr[0]   = 128'h8000001b001b01010101002c0006000c;
        instr_data_arr[1]   = 128'ha0000000001b0ab2003b000e00003602;
        instr_data_arr[2]   = 128'hc00000000000049000000003200000c0;
        instr_data_arr[3]   = 128'he0000000782c000078280000780c0000;
        instr_data_arr[4]   = 128'h80000240012003020101036000900200;
        instr_data_arr[5]   = 128'ha000000003600200024c00c400024002;
        instr_data_arr[6]   = 128'hc0000000000031000000003f00002000;
        instr_data_arr[7]   = 128'he0000000782c000078280000780c0000;
        instr_data_arr[8]   = 128'h80000b4002400605010106c005a00900;
        instr_data_arr[9]   = 128'ha00000000d80001905ac097400048002;
        instr_data_arr[10]  = 128'hc00000000000f200000000c600009000;
        instr_data_arr[11]  = 128'he0000000782c000078280000780c0000;
        instr_data_arr[12]  = 128'h80000b4002400605010106c005a00900;
        instr_data_arr[13]  = 128'ha00000000d80003205ac097400048002;
        instr_data_arr[14]  = 128'hc00000000000f200000000c600009000;
        instr_data_arr[15]  = 128'he0000000782c000078280000780c0000;
        instr_data_arr[16]  = 128'h8000120002400908010106c005a00e10;
        instr_data_arr[17]  = 128'ha00000001440001009300f5000048002;
        instr_data_arr[18]  = 128'hc000000000018800000000c60000e100;
        instr_data_arr[19]  = 128'he0000000782c000078280000780c0000;
        instr_data_arr[20]  = 128'h8000120002400908010106c005a00e10;
        instr_data_arr[21]  = 128'ha00000001440002009300f5000048002;
        instr_data_arr[22]  = 128'hc000000000018800000000c60000e100;
        instr_data_arr[23]  = 128'he0000000782c000078280000780c0000;
        instr_data_arr[24]  = 128'h8000120002400908010106c005a00e10;
        instr_data_arr[25]  = 128'ha00000001440002009300f5000048002;
        instr_data_arr[26]  = 128'hc000000000018800000000c60000e100;
        instr_data_arr[27]  = 128'he0000000782c000078280000780c0000;
        instr_data_arr[28]  = 128'h81000fc00240080702010d8005580c40;
        instr_data_arr[29]  = 128'ha00000001200000c0fd80c8b00048002;
        instr_data_arr[30]  = 128'hc00000000001c6300000012d8000c400;
        instr_data_arr[31]  = 128'he0000000782c000078280000780c0000;
        // instr_data_arr[32]  = 128'h800008700090160f030201b001680310;
        // instr_data_arr[33]  = 128'ha00000000c60000807ec0d3400012002;
        // instr_data_arr[34]  = 128'hc0000000000152000000003180003100;
        // instr_data_arr[35]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[36]  = 128'h800008700090160f030201b001680310;
        // instr_data_arr[37]  = 128'ha00000000c60000807ec0d3400012002;
        // instr_data_arr[38]  = 128'hc0000000000152000000003180003100;
        // instr_data_arr[39]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[40]  = 128'h800002d000900705030201b001680349;
        // instr_data_arr[41]  = 128'ha000000003f00010024c03d400012002;
        // instr_data_arr[42]  = 128'hc0000000000062000000003180003490;
        // instr_data_arr[43]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[44]  = 128'h800001b000900503050402d0031800c4;
        // instr_data_arr[45]  = 128'ha000000002d0001002d0063000012002;
        // instr_data_arr[46]  = 128'hc0000000000090000000005e80000c40;
        // instr_data_arr[47]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[48]  = 128'h80000080004002020803020001000384;
        // instr_data_arr[49]  = 128'ha0000000008000080200020000008002;
        // instr_data_arr[50]  = 128'hc0000000000040000000003000003840;
        // instr_data_arr[51]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[52]  = 128'h800001b000900503050402d0031800c4;
        // instr_data_arr[53]  = 128'ha000000002d0001002d0063000012002;
        // instr_data_arr[54]  = 128'hc0000000000090000000005e80000c40;
        // instr_data_arr[55]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[56]  = 128'h800001b000900503050402d0031800c4;
        // instr_data_arr[57]  = 128'ha000000002d0001002d0063000012002;
        // instr_data_arr[58]  = 128'hc0000000000090000000005e80000c40;
        // instr_data_arr[59]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[60]  = 128'h81000126009302020201012600930053;
        // instr_data_arr[61]  = 128'ha0000000012600c40080008000012602;
        // instr_data_arr[62]  = 128'hc0000000000010000000001b90000530;
        // instr_data_arr[63]  = 128'he0000000783800007834000078400000;
        // instr_data_arr[64]  = 128'h80000024002401010201003b00070039;
        // instr_data_arr[65]  = 128'ha0000000002408000029000a00004802;
        // instr_data_arr[66]  = 128'hc0000000000003300000000420000390;
        // instr_data_arr[67]  = 128'he000000078280000780c000498080390;
        // instr_data_arr[68]  = 128'h80000080004002020803024000e00100;
        // instr_data_arr[69]  = 128'ha000000000800008024001c000008002;
        // instr_data_arr[70]  = 128'hc0000000000040000000003200001000;
        // instr_data_arr[71]  = 128'he000000078280000780c003278081000;
        // instr_data_arr[72]  = 128'h80000024002401010201003b00070039;
        // instr_data_arr[73]  = 128'ha0000000002408000029000a00004802;
        // instr_data_arr[74]  = 128'hc0000000000003300000000420000390;
        // instr_data_arr[75]  = 128'he000000078280000780c000498080390;
        // instr_data_arr[76]  = 128'h80000024002401010201003b00070039;
        // instr_data_arr[77]  = 128'ha0000000002408000029000a00004802;
        // instr_data_arr[78]  = 128'hc0000000000003300000000420000390;
        // instr_data_arr[79]  = 128'he000000078280000780c000498080390;
        // instr_data_arr[80]  = 128'h81000004000401010201000800010001;
        // instr_data_arr[81]  = 128'ha000000000040c800002000100000802;
        // instr_data_arr[82]  = 128'hc0000000000000300000000090000010;
        // instr_data_arr[83]  = 128'he000000078280000780c000108080010;
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

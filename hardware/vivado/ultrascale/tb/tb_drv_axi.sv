`ifndef TB_DRV_AXI_SV
`define TB_DRV_AXI_SV

`include "tb_drv.sv"
`include "tb_itf.sv"

typedef enum  {AXI_WR_IDLE, AXI_WR_AW, AXI_WR_W, AXI_WR_B} AXI_WR_STATE;
typedef enum  {AXI_RD_IDLE, AXI_RD_AR, AXI_RD_R} AXI_RD_STATE;

class rand_bit;
    rand bit rand_num;
endclass

class s_axi_drv #(
    parameter int unsigned AXI_ADDR_WIDTH = 1,
    parameter int unsigned AXI_DATA_WIDTH = 8,
    parameter int unsigned AXI_ID_WIDTH   = 4,
    parameter int unsigned AXI_USER_WIDTH = 4
);
    AXI_WR_STATE axi_wr_sts;
    int axi_wr_cnt;
    logic [7:0] axi_wr_len;

    AXI_RD_STATE axi_rd_sts;
    logic [AXI_ADDR_WIDTH-1:0] axi_rd_addr;
    int axi_rd_cnt;
    logic [7:0] axi_rd_len;

    virtual clkrst_itf clkrst_i;
    virtual axi_itf #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ID_WIDTH  (AXI_ID_WIDTH  ),
        .AXI_USER_WIDTH(AXI_USER_WIDTH)
        ) axi_i;

    logic [AXI_DATA_WIDTH-1:0] data_arr [];
    int data_arr_index;
    event drv_done;

    rand_bit rand_bit_obj;

    function new;
        this.axi_wr_sts=AXI_WR_IDLE;
        this.axi_rd_sts=AXI_RD_IDLE;
    endfunction

    function set_data_arr(logic [AXI_DATA_WIDTH-1:0] data_arr []);
        this.data_arr = data_arr;
    endfunction

    task run;
       fork
           this.run_wr();
           this.run_rd();
       join_none
    endtask

    task run_wr;
        rand_bit_obj = new ();
        forever begin
            @(posedge this.clkrst_i.clk) begin
                if (this.axi_wr_sts==AXI_WR_IDLE | ~this.clkrst_i.rst_n) begin
                    this.axi_i.awready  <= 1'b0;
                    this.axi_i.wready   <= 1'b0;
                    this.axi_i.bvalid   <= 1'b0;
                    this.axi_i.bresp    <= 1'b0;
                    this.axi_i.bid      <= 1'b0;
                    this.axi_i.buser    <= 1'b0;
                    this.axi_wr_sts = AXI_WR_AW;
                end
                else if (this.axi_wr_sts==AXI_WR_AW) begin
                    if (this.axi_i.awready & this.axi_i.awvalid) begin
                        this.axi_i.awready  <= 1'b0;
                        this.axi_wr_len = this.axi_i.awlen;
                        this.axi_wr_cnt = 0;
                        this.axi_wr_sts = AXI_WR_W;
                    end
                    else
                        this.axi_i.awready  <= 1'b1;
                end
                else if (this.axi_wr_sts==AXI_WR_W) begin
                    if (this.axi_i.wready & this.axi_i.wvalid) begin
                        if (this.axi_wr_cnt<this.axi_wr_len) begin
                            this.axi_wr_cnt += 1;
                            rand_bit_obj.randomize();
                            this.axi_i.wready  <= rand_bit_obj.rand_num;
                        end
                        else begin
                            this.axi_i.wready  <= 1'b0;
                            this.axi_wr_sts=AXI_WR_B;
                        end
                    end
                    else
                        rand_bit_obj.randomize();
                        this.axi_i.wready  <= rand_bit_obj.rand_num;

                end
                else if (this.axi_wr_sts==AXI_WR_B) begin
                    if (this.axi_i.bready & this.axi_i.bvalid) begin
                        this.axi_i.bvalid  <= 1'b0;
                        this.axi_wr_sts = AXI_WR_AW;
                    end
                    else
                        this.axi_i.bvalid  <= 1'b1;
                end
            end
        end
    endtask

    task run_rd;
        forever begin
            @(posedge this.clkrst_i.clk) begin
                if (this.axi_rd_sts==AXI_RD_IDLE | ~this.clkrst_i.rst_n) begin
                    this.axi_i.arready  <= 1'b0;
                    this.axi_i.rvalid   <= 1'b0;
                    this.axi_i.rresp    <= 1'b0;
                    this.axi_i.rdata    <= 1'b0;
                    this.axi_i.rlast    <= 1'b0;
                    this.axi_i.rid      <= 1'b0;
                    this.axi_i.ruser    <= 1'b0;
                    this.axi_rd_sts = AXI_RD_AR;
                end
                else if (this.axi_rd_sts==AXI_RD_AR) begin
                    if (this.axi_i.arready & this.axi_i.arvalid) begin
                        this.axi_i.arready  <= 1'b0;
                        this.axi_rd_addr    = this.axi_i.araddr;
                        this.axi_rd_len     = this.axi_i.arlen;
                        this.axi_rd_cnt     = 0;
                        this.axi_rd_sts = AXI_RD_R;
                    end
                    else
                        this.axi_i.arready  = 1'b1;
                end
                else if (this.axi_rd_sts==AXI_RD_R) begin
                    if (this.axi_i.rready & this.axi_i.rvalid)
                        this.axi_rd_cnt += 1;
                    if (this.axi_rd_cnt <= this.axi_rd_len) begin
                        this.axi_i.rvalid   <= 1'b1;
                        // address: 000 - act, 001 - w, 011 - fout, 100 - res, 101 - bn
                        // this.axi_i.rdata    <= 128'h0F_0E_0D_0C_0B_0A_09_08_07_06_05_04_03_02_01_00 + {16{{4'(this.axi_rd_cnt+this.axi_rd_addr[7:4]),4'b0}}};
                        this.axi_i.rdata    <=  (this.axi_rd_addr[27:25] == 3'b000 && this.axi_rd_addr[15:0] < 16'd1280)?128'h01_02_03_02_01_03_03_01_02_01_03_02_01_02_02_01:
                                                (this.axi_rd_addr[27:25] == 3'b001 && this.axi_rd_addr[15:0] < 16'd640)?128'h01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01:
                                                (this.axi_rd_addr[27:25] == 3'b100 && this.axi_rd_addr[7:0] < 8'd56)?128'h01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01:
                                                (this.axi_rd_addr[27:25] == 3'b101)?128'h00_01_00_01_00_01_00_01_00_01_00_01_00_01_00_01:
                                                128'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
                        this.axi_i.rlast    <= (this.axi_rd_cnt==this.axi_rd_len);
                    end
                    else begin
                        this.axi_i.rvalid   <= 1'b0;
                        this.axi_i.rdata    <= 0;
                        this.axi_i.rlast    <= 0;
                        this.axi_rd_sts = AXI_RD_AR;
                    end
                end
            end
        end
    endtask

endclass

`endif

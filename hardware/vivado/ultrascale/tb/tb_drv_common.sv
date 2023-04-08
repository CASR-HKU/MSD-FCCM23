`ifndef TB_DRV_COMMON_SV
`define TB_DRV_COMMON_SV

`include "tb_itf.sv"

class clkrst_drv #(
    int CLK_PERIOD = 4,
    int RST_CYCLE = 4
);

    virtual clkrst_itf clkrst_i;
    event rst_n_done;

    task run;
        fork
            this.run_clk();
        join_none
        this.run_rst_n();
    endtask

    task run_rst_n;
        this.clkrst_i.rst_n = 0;
        #(CLK_PERIOD*RST_CYCLE+1) this.clkrst_i.rst_n = 1;
        -> rst_n_done;
    endtask

    task run_clk;
        this.clkrst_i.clk = 1;
        forever #(CLK_PERIOD/2) this.clkrst_i.clk = ~this.clkrst_i.clk;
    endtask

endclass

class ap_ctrl_drv;

    virtual clkrst_itf clkrst_i;
    virtual ap_ctrl_itf ap_ctrl_i;
    bit start_flag = 0;
    bit pulse_start = 1;
    event ap_done;

    task run;
        forever begin
            @(posedge this.clkrst_i.clk) begin
                if (~this.clkrst_i.rst_n) begin
                    this.ap_ctrl_i.ap_start = 1'b0;
                end
                else if (this.start_flag) begin
                    this.ap_ctrl_i.ap_start = 1'b1;
                    if (this.pulse_start)
                        this.start_flag = 0;
                end
                else
                    this.ap_ctrl_i.ap_start = 1'b0;
                if (this.ap_ctrl_i.ap_done) begin
                    this.ap_ctrl_i.ap_start = 1'b0;
                    this.start_flag = 0;
                    -> ap_done;
                    break;
                end
            end
        end
    endtask

    task set_start(pulse_start);
        this.start_flag = 1;
        this.pulse_start = pulse_start;
    endtask


endclass

`endif

`ifndef TB_DRV_AXIS_SV
`define TB_DRV_AXIS_SV

`include "tb_drv.sv"
`include "tb_itf.sv"

class m_axis_drv #(
    int AXIS_DATA_WIDTH = 128   ,
    int AXIS_USER_WIDTH = 1     ,
    int STREAM_LEN      = 16    
);

    virtual clkrst_itf clkrst_i;
    virtual axis_itf #(.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)) axis_i;

    logic [AXIS_DATA_WIDTH-1:0]     data_arr [STREAM_LEN];
    logic [AXIS_DATA_WIDTH/8-1:0]   keep_arr [STREAM_LEN];
    logic                           last_arr [STREAM_LEN];
    logic [AXIS_USER_WIDTH-1:0]     user_arr [STREAM_LEN];
    int arr_index;
    event drv_done;

    function new;
        this.data_arr = '{default:0};
        this.keep_arr = '{default:{AXIS_DATA_WIDTH/8{1'b1}}};
        this.last_arr = '{STREAM_LEN-1:1, default:0};
        this.user_arr = '{default:0};
    endfunction

    function void set_data_arr(logic [AXIS_DATA_WIDTH-1:0] data_arr [STREAM_LEN]);
        this.data_arr = data_arr;
    endfunction

    function void set_keep_arr(logic [AXIS_DATA_WIDTH/8-1:0] keep_arr [STREAM_LEN]);
        this.keep_arr = keep_arr;
    endfunction

    function void set_last_arr(logic last_arr [STREAM_LEN]);
        this.last_arr = last_arr;
    endfunction

    function void set_user_arr(logic [AXIS_USER_WIDTH-1:0] user_arr [STREAM_LEN]);
        this.user_arr = user_arr;
    endfunction

    task run;
        // forever begin
        //     if (~this.clkrst_i.rst_n) begin
        //         this.axis_i.tvalid = 1'b0;
        //         this.axis_i.tdata = 'b0;
        //         this.axis_i.tkeep = 'b0;
        //         this.axis_i.tstrb = 'b0;
        //         this.axis_i.tlast = 'b0;
        //         this.axis_i.tuser = 'b0;
        //         this.arr_index = 0;
        //     end
        //     else begin
        //         if (this.arr_index<STREAM_LEN) begin
        //             this.axis_i.tvalid = 1'b1;
        //             this.axis_i.tdata = this.data_arr[this.arr_index];
        //             this.axis_i.tkeep = this.keep_arr[this.arr_index];
        //             this.axis_i.tlast = this.last_arr[this.arr_index];
        //             this.axis_i.tuser = this.user_arr[this.arr_index];
        //         end
        //         else begin
        //             this.axis_i.tvalid = 1'b0;
        //             this.axis_i.tdata = 'hDEAD;
        //             this.axis_i.tkeep = 'b0;
        //             this.axis_i.tlast = 'b0;
        //             this.axis_i.tuser = 'b0;
        //             -> drv_done;
        //             $display("T=%0t m_axis_drv reach end", $time);
        //             break;
        //         end
        //     end
        //     // $display("T=%0t m_axis_drv wait", $time);
        //     @(posedge this.clkrst_i.clk) begin
        //         if (this.axis_i.tvalid & this.axis_i.tready)
        //             arr_index+=1;
        //     end
        // end
        forever begin
            @(posedge this.clkrst_i.clk) begin
                if (~this.clkrst_i.rst_n) begin
                    this.axis_i.tvalid  <= 1'b0;
                    this.axis_i.tdata   <= 'b0;
                    this.axis_i.tkeep   <= 'b0;
                    this.axis_i.tstrb   <= 'b0;
                    this.axis_i.tlast   <= 'b0;
                    this.axis_i.tuser   <= 'b0;
                    this.arr_index = 0;
                end
                else begin
                    if (this.axis_i.tready & this.axis_i.tvalid) begin
                        this.arr_index += 1;
                    end
                    if (this.arr_index<STREAM_LEN) begin
                        this.axis_i.tvalid  <= 1'b1;
                        this.axis_i.tdata   <= this.data_arr[this.arr_index];
                        this.axis_i.tkeep   <= this.keep_arr[this.arr_index];
                        this.axis_i.tlast   <= this.last_arr[this.arr_index];
                        this.axis_i.tuser   <= this.user_arr[this.arr_index];
                    end
                    else begin
                        this.axis_i.tvalid  <= 1'b0;
                        this.axis_i.tdata   <= 'hDEAD;
                        this.axis_i.tkeep   <= 'b0;
                        this.axis_i.tlast   <= 'b0;
                        this.axis_i.tuser   <= 'b0;
                        -> drv_done;
                        $display("T=%0t m_axis_drv reach end", $time);
                        break;
                    end
                end
            end
        end
    endtask

endclass



class s_axis_drv #(
    int AXIS_DATA_WIDTH = 128
);

    virtual clkrst_itf clkrst_i;
    virtual axis_itf #(.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)) axis_i;

    logic [AXIS_DATA_WIDTH-1:0] data_arr [];
    int arr_index;
    event drv_done;

    task run;
        forever begin
            if (~this.clkrst_i.rst_n) begin
                this.axis_i.tready = 1'b0;
            end
            else begin
                this.axis_i.tready = 1'b1;
            end
            // $display("T=%0t s_axis_drv wait", $time);
            @(posedge this.clkrst_i.clk);
        end
    endtask

endclass

`endif

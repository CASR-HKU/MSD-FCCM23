`ifndef TB_ITF_SV
`define TB_ITF_SV

interface clkrst_itf;
    logic clk;
    logic rst_n;
endinterface

interface ap_ctrl_itf;
    logic ap_start;
    logic ap_done;
endinterface


interface axis_itf #(
    parameter int unsigned AXIS_DATA_WIDTH = 8,
    parameter int unsigned AXIS_USER_WIDTH = 1
);
localparam int unsigned AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH / 8;
localparam int unsigned AXIS_STRB_WIDTH = AXIS_DATA_WIDTH / 8;

typedef logic [AXIS_DATA_WIDTH-1:0] data_t;
typedef logic [AXIS_KEEP_WIDTH-1:0] keep_t;
typedef logic [AXIS_STRB_WIDTH-1:0] strb_t;
typedef logic [AXIS_USER_WIDTH-1:0] user_t;

logic       tready;
logic       tvalid;
data_t      tdata;
keep_t      tkeep;
strb_t      tstrb;
logic       tlast;
user_t      tuser;

modport Master (
    output tvalid, tdata, tkeep, tstrb, tlast, tuser,
    input tready
);

modport Slave (
    input tvalid, tdata, tkeep, tstrb, tlast, tuser,
    output tready
);

endinterface: axis_itf


interface axi_itf #(
    parameter int unsigned AXI_ADDR_WIDTH = 1,
    parameter int unsigned AXI_DATA_WIDTH = 8,
    parameter int unsigned AXI_ID_WIDTH   = 4,
    parameter int unsigned AXI_USER_WIDTH = 4
);

localparam int unsigned AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

typedef logic [AXI_ID_WIDTH-1:0]      id_t;
typedef logic [AXI_ADDR_WIDTH-1:0]    addr_t;
typedef logic [7:0]                   len_t;
typedef logic [2:0]                   size_t;
typedef logic [1:0]                   burst_t;
typedef logic [3:0]                   cache_t;
typedef logic [2:0]                   prot_t;
typedef logic [3:0]                   qos_t;
typedef logic [3:0]                   region_t;
typedef logic [AXI_USER_WIDTH-1:0]    user_t;
typedef logic [AXI_DATA_WIDTH-1:0]    data_t;
typedef logic [AXI_STRB_WIDTH-1:0]    strb_t;
typedef logic [1:0]                   resp_t;

id_t        awid;
addr_t      awaddr;
len_t       awlen;
size_t      awsize;
burst_t     awburst;
logic       awlock;
cache_t     awcache;
prot_t      awprot;
qos_t       awqos;
region_t    awregion;
user_t      awuser;
logic       awvalid;
logic       awready;

data_t      wdata;
strb_t      wstrb;
logic       wlast;
user_t      wuser;
logic       wvalid;
logic       wready;

id_t        bid;
resp_t      bresp;
user_t      buser;
logic       bvalid;
logic       bready;

id_t        arid;
addr_t      araddr;
len_t       arlen;
size_t      arsize;
burst_t     arburst;
logic       arlock;
cache_t     arcache;
prot_t      arprot;
qos_t       arqos;
region_t    arregion;
user_t      aruser;
logic       arvalid;
logic       arready;

id_t        rid;
data_t      rdata;
resp_t      rresp;
logic       rlast;
user_t      ruser;
logic       rvalid;
logic       rready;

modport Master (
    output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid, input awready,
    output wdata, wstrb, wlast, wuser, wvalid, input wready,
    input bid, bresp, buser, bvalid, output bready,
    output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid, input arready,
    input rid, rdata, rresp, rlast, ruser, rvalid, output rready
);

modport Slave (
    input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid, output awready,
    input wdata, wstrb, wlast, wuser, wvalid, output wready,
    output bid, bresp, buser, bvalid, input bready,
    input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid, output arready,
    output rid, rdata, rresp, rlast, ruser, rvalid, input rready
);

endinterface: axi_itf

`endif

`ifndef DEF_SV
`define DEF_SV

// global
`define DFLT_CORE_AXI_ADDR_WIDTH 64
`define DFLT_CORE_AXI_DATA_WIDTH 64
`define DFLT_MEM_STS_WIDTH 8

`define DFLT_AUX_AXI_ADDR_WIDTH 64
`define DFLT_AUX_AXI_DATA_WIDTH 64
// other param in AUX
`define DFLT_MAX_TIME_OUT_CYCLE 32'd250_000_000
`define DFLT_AUX_INSTR_BURST_LEN 64
`define DFLT_AUX_INSTR_FIFO_DEPTH 16

`define DFLT_PS_CTRL_AXI_ADDR_WIDTH 8
`define DFLT_PS_CTRL_AXI_DATA_WIDTH 32

// LUT bit-serial
`define HW_IDX_DW 4
`define HW_WGT_DW 8
`define HW_ACT_DW 8
`define HW_PSU_DW 8

`define HW_LUT_PE_ROWS 40
`define HW_LUT_PE_COLS 40

`define BIT_SERIAL

`define HW_LUT_VER_BUS_DW (`HW_PSU_DW)
`ifdef BIT_SERIAL
`define HW_LUT_HOR_BUS_DW (`HW_IDX_DW)
`else
`define HW_LUT_HOR_BUS_DW (`HW_WGT_DW)
`endif

// 4 - 12, 8 - 11, 16 - 10
`define HW_BS_ACT_BUF_DEPTH 11
`define HW_BS_WGT_BUF_DEPTH 11
`define HW_BS_OUT_BUF_DEPTH 11
`define HW_BS_BUF_SIZE 32768

// DSP bit-parallel
`define HW_DSP_PE_ROWS 14
`define HW_DSP_PE_COLS 15

`define HW_DSP_A_DW 27
`define HW_DSP_B_DW 18
`define HW_DSP_P_DW 45

`define HW_DSP_VER_BUS_DW 16
`define HW_DSP_HOR_BUS_DW 8

`define HW_BP_ACT_BUF_DEPTH 10
`define HW_BP_WGT_BUF_DEPTH 10
`define HW_BP_OUT_BUF_DEPTH 10
`define HW_BP_BUF_SIZE 32768

// memory side
`define HW_GLB_MEM_BW 16

`define BS_BW_LARGER_RC
`define BP_BW_LARGER_RC

`endif

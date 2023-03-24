`include "def.sv"
module fifo_axis #(
    parameter FIFO_AXIS_DEPTH        = 16,
    parameter FIFO_AXIS_TDATA_WIDTH  = 128,
    parameter FIFO_DATA_COUNT_WIDTH  = $clog2(FIFO_AXIS_DEPTH) + 1,
    parameter FIFO_ADV_FEATURES      = "1414",
    parameter FIFO_PROG_FULL_THRESH  = 10,
    parameter FIFO_PROG_EMPTY_THRESH = 6
) (
    //common signal
    input logic clk,
    input logic rst_n,
    // fifo status
    output logic almost_empty_axis,
    output logic almost_full_axis,
    output logic prog_empty_axis,  // assert when less or equal to threshold
    output logic prog_full_axis,  // assert when greater or equal to threshold
    output logic [FIFO_DATA_COUNT_WIDTH-1:0] rd_data_count_axis,
    output logic [FIFO_DATA_COUNT_WIDTH-1:0] wr_data_count_axis,
    // m_axis
    input logic m_axis_tready,
    output logic m_axis_tvalid,
    output logic [FIFO_AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    output logic [FIFO_AXIS_TDATA_WIDTH/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tuser,
    output logic [1:0] m_axis_tdest,
    // s_axis
    output logic s_axis_tready,
    input logic s_axis_tvalid,
    input logic [FIFO_AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    input logic [FIFO_AXIS_TDATA_WIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tuser,
    input logic [1:0] s_axis_tdest
);

    localparam FIFO_AXIS_TID_WIDTH = 1;
    localparam FIFO_AXIS_TUSER_WIDTH = 1;

    //common signal
    logic m_aclk, s_aclk, s_aresetn;
    always_comb begin
        m_aclk = clk;
        s_aclk = clk;
        s_aresetn = rst_n;
    end

    // not used axis
    logic [FIFO_AXIS_TDATA_WIDTH/8-1:0] m_axis_tstrb;
    logic [    FIFO_AXIS_TID_WIDTH-1:0] m_axis_tid;
    logic [FIFO_AXIS_TDATA_WIDTH/8-1:0] s_axis_tstrb;
    logic [    FIFO_AXIS_TID_WIDTH-1:0] s_axis_tid;
    always_comb begin
        s_axis_tstrb = s_axis_tkeep;
        s_axis_tid   = 'b0;
    end


    // ECC related
    logic sbiterr_axis, dbiterr_axis;
    logic injectdbiterr_axis, injectsbiterr_axis;
    always_comb begin
        injectdbiterr_axis = 0;
        injectsbiterr_axis = 0;
    end

    xpm_fifo_axis #(
        .CASCADE_HEIGHT     (0),                       // DECIMAL
        .CDC_SYNC_STAGES    (2),                       // DECIMAL
        .CLOCKING_MODE      ("common_clock"),          // String
        .ECC_MODE           ("no_ecc"),                // String
        .FIFO_DEPTH         (FIFO_AXIS_DEPTH),         // DECIMAL
        .FIFO_MEMORY_TYPE   ("auto"),                  // String
        .PACKET_FIFO        ("false"),                 // String
        .PROG_EMPTY_THRESH  (FIFO_PROG_EMPTY_THRESH),  // DECIMAL
        .PROG_FULL_THRESH   (FIFO_PROG_FULL_THRESH),   // DECIMAL
        .RD_DATA_COUNT_WIDTH(FIFO_DATA_COUNT_WIDTH),   // DECIMAL
        .RELATED_CLOCKS     (0),                       // DECIMAL
        .SIM_ASSERT_CHK     (0),                       // DECIMAL
        .TDATA_WIDTH        (FIFO_AXIS_TDATA_WIDTH),   // DECIMAL
        .TDEST_WIDTH        (2),                       // DECIMAL
        .TID_WIDTH          (FIFO_AXIS_TID_WIDTH),     // DECIMAL
        .TUSER_WIDTH        (FIFO_AXIS_TUSER_WIDTH),   // DECIMAL
        .USE_ADV_FEATURES   (FIFO_ADV_FEATURES),       // String
        .WR_DATA_COUNT_WIDTH(FIFO_DATA_COUNT_WIDTH)    // DECIMAL
    ) xpm_fifo_axis_inst (
        .almost_empty_axis(almost_empty_axis),      // 1-bit output: Almost Empty : When asserted, this signal
                                                    // indicates that only one more read can be performed before the
                                                    // FIFO goes to empty.
        .almost_full_axis(almost_full_axis),        // 1-bit output: Almost Full: When asserted, this signal
                                                    // indicates that only one more write can be performed before
                                                    // the FIFO is full.
        .dbiterr_axis(dbiterr_axis),  // 1-bit output: Double Bit Error- Indicates that the ECC
                                      // decoder detected a double-bit error and data in the FIFO core
                                      // is corrupted.
        .m_axis_tdata(m_axis_tdata),  // TDATA_WIDTH-bit output: TDATA: The primary payload that is
                                      // used to provide the data that is passing across the
                                      // interface. The width of the data payload is an integer number
                                      // of bytes.
        .m_axis_tdest(m_axis_tdest),  // TDEST_WIDTH-bit output: TDEST: Provides routing information
                                      // for the data stream.
        .m_axis_tid(m_axis_tid),  // TID_WIDTH-bit output: TID: The data stream identifier that
                                  // indicates different streams of data.
        .m_axis_tkeep(m_axis_tkeep),  // TDATA_WIDTH/8-bit output: TKEEP: The byte qualifier that
                                      // indicates whether the content of the associated byte of TDATA
                                      // is processed as part of the data stream. Associated bytes
                                      // that have the TKEEP byte qualifier deasserted are null bytes
                                      // and can be removed from the data stream. For a 64-bit DATA,
                                      // bit 0 corresponds to the least significant byte on DATA, and
                                      // bit 7 corresponds to the most significant byte. For example:
                                      // KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                      // DATA[63:56] is a NULL byte
        .m_axis_tlast(m_axis_tlast),  // 1-bit output: TLAST: Indicates the boundary of a packet.
        .m_axis_tstrb(m_axis_tstrb),  // TDATA_WIDTH/8-bit output: TSTRB: The byte qualifier that
                                      // indicates whether the content of the associated byte of TDATA
                                      // is processed as a data byte or a position byte. For a 64-bit
                                      // DATA, bit 0 corresponds to the least significant byte on
                                      // DATA, and bit 0 corresponds to the least significant byte on
                                      // DATA, and bit 7 corresponds to the most significant byte. For
                                      // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                      // DATA[63:56] is not valid
        .m_axis_tuser(m_axis_tuser),  // TUSER_WIDTH-bit output: TUSER: The user-defined sideband
                                      // information that can be transmitted alongside the data
                                      // stream.
        .m_axis_tvalid(m_axis_tvalid),              // 1-bit output: TVALID: Indicates that the master is driving a
                                                    // valid transfer. A transfer takes place when both TVALID and
                                                    // TREADY are asserted
        .prog_empty_axis(prog_empty_axis),          // 1-bit output: Programmable Empty- This signal is asserted
                                                    // when the number of words in the FIFO is less than or equal to
                                                    // the programmable empty threshold value. It is de-asserted
                                                    // when the number of words in the FIFO exceeds the programmable
                                                    // empty threshold value.
        .prog_full_axis(prog_full_axis),            // 1-bit output: Programmable Full: This signal is asserted when
                                                    // the number of words in the FIFO is greater than or equal to
                                                    // the programmable full threshold value. It is de-asserted when
                                                    // the number of words in the FIFO is less than the programmable
                                                    // full threshold value.
        .rd_data_count_axis(rd_data_count_axis),    // RD_DATA_COUNT_WIDTH-bit output: Read Data Count- This bus
                                                    // indicates the number of words available for reading in the
                                                    // FIFO.
        .s_axis_tready(s_axis_tready),              // 1-bit output: TREADY: Indicates that the slave can accept a
                                                    // transfer in the current cycle.
        .sbiterr_axis(sbiterr_axis),  // 1-bit output: Single Bit Error- Indicates that the ECC
                                      // decoder detected and fixed a single-bit error.
        .wr_data_count_axis(wr_data_count_axis),    // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus
                                                    // indicates the number of words written into the FIFO.
        .injectdbiterr_axis(injectdbiterr_axis),    // 1-bit input: Double Bit Error Injection- Injects a double bit
                                                    // error if the ECC feature is used.
        .injectsbiterr_axis(injectsbiterr_axis),    // 1-bit input: Single Bit Error Injection- Injects a single bit
                                                    // error if the ECC feature is used.
        .m_aclk(m_aclk),  // 1-bit input: Master Interface Clock: All signals on master
                          // interface are sampled on the rising edge of this clock.
        .m_axis_tready(m_axis_tready),              // 1-bit input: TREADY: Indicates that the slave can accept a
                                                    // transfer in the current cycle.
        .s_aclk(s_aclk),  // 1-bit input: Slave Interface Clock: All signals on slave
                          // interface are sampled on the rising edge of this clock.
        .s_aresetn(s_aresetn),  // 1-bit input: Active low asynchronous reset.
        .s_axis_tdata(s_axis_tdata),  // TDATA_WIDTH-bit input: TDATA: The primary payload that is
                                      // used to provide the data that is passing across the
                                      // interface. The width of the data payload is an integer number
                                      // of bytes.
        .s_axis_tdest(s_axis_tdest),  // TDEST_WIDTH-bit input: TDEST: Provides routing information
                                      // for the data stream.
        .s_axis_tid(s_axis_tid),  // TID_WIDTH-bit input: TID: The data stream identifier that
                                  // indicates different streams of data.
        .s_axis_tkeep(s_axis_tkeep),  // TDATA_WIDTH/8-bit input: TKEEP: The byte qualifier that
                                      // indicates whether the content of the associated byte of TDATA
                                      // is processed as part of the data stream. Associated bytes
                                      // that have the TKEEP byte qualifier deasserted are null bytes
                                      // and can be removed from the data stream. For a 64-bit DATA,
                                      // bit 0 corresponds to the least significant byte on DATA, and
                                      // bit 7 corresponds to the most significant byte. For example:
                                      // KEEP[0] = 1b, DATA[7:0] is not a NULL byte KEEP[7] = 0b,
                                      // DATA[63:56] is a NULL byte
        .s_axis_tlast(s_axis_tlast),  // 1-bit input: TLAST: Indicates the boundary of a packet.
        .s_axis_tstrb(s_axis_tstrb),  // TDATA_WIDTH/8-bit input: TSTRB: The byte qualifier that
                                      // indicates whether the content of the associated byte of TDATA
                                      // is processed as a data byte or a position byte. For a 64-bit
                                      // DATA, bit 0 corresponds to the least significant byte on
                                      // DATA, and bit 0 corresponds to the least significant byte on
                                      // DATA, and bit 7 corresponds to the most significant byte. For
                                      // example: STROBE[0] = 1b, DATA[7:0] is valid STROBE[7] = 0b,
                                      // DATA[63:56] is not valid
        .s_axis_tuser(s_axis_tuser),  // TUSER_WIDTH-bit input: TUSER: The user-defined sideband
                                      // information that can be transmitted alongside the data
                                      // stream.
        .s_axis_tvalid(s_axis_tvalid)               // 1-bit input: TVALID: Indicates that the master is driving a
                                                    // valid transfer. A transfer takes place when both TVALID and
                                                    // TREADY are asserted

    );


endmodule

// Parameter usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Parameter name       | Data type          | Restrictions, if applicable                                             |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | CASCADE_HEIGHT       | Integer            | Range: 0 - 64. Default value = 0.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- No Cascade Height, Allow Vivado Synthesis to choose.                                                             |
// | 1 or more - Vivado Synthesis sets the specified value as Cascade Height.                                            |
// +---------------------------------------------------------------------------------------------------------------------+
// | CDC_SYNC_STAGES      | Integer            | Range: 2 - 8. Default value = 2.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the number of synchronization stages on the CDC path.                                                     |
// | Applicable only if CLOCKING_MODE = "independent_clock"                                                              |
// +---------------------------------------------------------------------------------------------------------------------+
// | CLOCKING_MODE        | String             | Allowed values: common_clock, independent_clock. Default value = common_clock.|
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate whether AXI Stream FIFO is clocked with a common clock or with independent clocks-                        |
// |                                                                                                                     |
// |   "common_clock"- Common clocking; clock both write and read domain s_aclk                                          |
// |   "independent_clock"- Independent clocking; clock write domain with s_aclk and read domain with m_aclk             |
// +---------------------------------------------------------------------------------------------------------------------+
// | ECC_MODE             | String             | Allowed values: no_ecc, en_ecc. Default value = no_ecc.                 |
// |---------------------------------------------------------------------------------------------------------------------|
// |                                                                                                                     |
// |   "no_ecc" - Disables ECC                                                                                           |
// |   "en_ecc" - Enables both ECC Encoder and Decoder                                                                   |
// |                                                                                                                     |
// | NOTE: ECC_MODE should be "no_ecc" if FIFO_MEMORY_TYPE is set to "auto". Violating this may result incorrect behavior.|
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_DEPTH           | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the AXI Stream FIFO Write Depth, must be power of two                                                       |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | FIFO_MEMORY_TYPE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
// |---------------------------------------------------------------------------------------------------------------------|
// | Designate the fifo memory primitive (resource type) to use-                                                         |
// |                                                                                                                     |
// |   "auto"- Allow Vivado Synthesis to choose                                                                          |
// |   "block"- Block RAM FIFO                                                                                           |
// |   "distributed"- Distributed RAM FIFO                                                                               |
// |   "ultra"- URAM FIFO                                                                                                |
// |                                                                                                                     |
// | NOTE: There may be a behavior mismatch if Block RAM or Ultra RAM specific features, like ECC or Asymmetry, are selected with FIFO_MEMORY_TYPE set to "auto".|
// +---------------------------------------------------------------------------------------------------------------------+
// | PACKET_FIFO          | String             | Allowed values: false, true. Default value = false.                     |
// |---------------------------------------------------------------------------------------------------------------------|
// |                                                                                                                     |
// |   "true"- Enables Packet FIFO mode                                                                                  |
// |   "false"- Disables Packet FIFO mode                                                                                |
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_EMPTY_THRESH    | Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5                                                                                                     |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | PROG_FULL_THRESH     | Integer            | Range: 5 - 4194301. Default value = 10.                                 |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
// |                                                                                                                     |
// |   Min_Value = 5 + CDC_SYNC_STAGES                                                                                   |
// |   Max_Value = FIFO_WRITE_DEPTH - 5                                                                                  |
// |                                                                                                                     |
// | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
// | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
// +---------------------------------------------------------------------------------------------------------------------+
// | RD_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of rd_data_count_axis. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+
// | RELATED_CLOCKS       | Integer            | Range: 0 - 1. Default value = 0.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios.                   |
// | Applicable only if CLOCKING_MODE = "independent_clock"                                                              |
// +---------------------------------------------------------------------------------------------------------------------+
// | SIM_ASSERT_CHK       | Integer            | Range: 0 - 1. Default value = 0.                                        |
// |---------------------------------------------------------------------------------------------------------------------|
// | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
// | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | TDATA_WIDTH          | Integer            | Range: 8 - 2048. Default value = 32.                                    |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the TDATA port, s_axis_tdata and m_axis_tdata                                                  |
// | NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits.                                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | TDEST_WIDTH          | Integer            | Range: 1 - 32. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the TDEST port, s_axis_tdest and m_axis_tdest                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | TID_WIDTH            | Integer            | Range: 1 - 32. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the ID port, s_axis_tid and m_axis_tid                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// | TUSER_WIDTH          | Integer            | Range: 1 - 4086. Default value = 1.                                     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Defines the width of the TUSER port, s_axis_tuser and m_axis_tuser                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | USE_ADV_FEATURES     | String             | Default value = 1000.                                                   |
// |---------------------------------------------------------------------------------------------------------------------|
// | Enables almost_empty_axis, rd_data_count_axis, prog_empty_axis, almost_full_axis, wr_data_count_axis,               |
// | prog_full_axis sideband signals.                                                                                    |
// |                                                                                                                     |
// |   Setting USE_ADV_FEATURES[1] to 1 enables prog_full flag; Default value of this bit is 0                           |
// |   Setting USE_ADV_FEATURES[2] to 1 enables wr_data_count; Default value of this bit is 0                            |
// |   Setting USE_ADV_FEATURES[3] to 1 enables almost_full flag; Default value of this bit is 0                         |
// |   Setting USE_ADV_FEATURES[9] to 1 enables prog_empty flag; Default value of this bit is 0                          |
// |   Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count; Default value of this bit is 0                           |
// |   Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                       |
// +---------------------------------------------------------------------------------------------------------------------+
// | WR_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
// |---------------------------------------------------------------------------------------------------------------------|
// | Specifies the width of wr_data_count_axis. To reflect the correct value, the width should be log2(FIFO_DEPTH)+1.    |
// +---------------------------------------------------------------------------------------------------------------------+

// Port usage table, organized as follows:
// +---------------------------------------------------------------------------------------------------------------------+
// | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
// |---------------------------------------------------------------------------------------------------------------------|
// | Description                                                                                                         |
// +---------------------------------------------------------------------------------------------------------------------+
// +---------------------------------------------------------------------------------------------------------------------+
// | almost_empty_axis| Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to|
// | empty.                                                                                                              |
// +---------------------------------------------------------------------------------------------------------------------+
// | almost_full_axis| Output    | 1                                     | s_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.|
// +---------------------------------------------------------------------------------------------------------------------+
// | dbiterr_axis   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error- Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
// +---------------------------------------------------------------------------------------------------------------------+
// | injectdbiterr_axis| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Double Bit Error Injection- Injects a double bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | injectsbiterr_axis| Input     | 1                                     | s_aclk  | Active-high | Tie to 1'b0            |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error Injection- Injects a single bit error if the ECC feature is used.                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_aclk         | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Master Interface Clock: All signals on master interface are sampled on the rising edge of this clock.               |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tdata   | Output    | TDATA_WIDTH                           | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tdest   | Output    | TDEST_WIDTH                           | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDEST: Provides routing information for the data stream.                                                            |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tid     | Output    | TID_WIDTH                             | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TID: The data stream identifier that indicates different streams of data.                                           |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tkeep   | Output    | TDATA_WIDTH/8                         | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TKEEP: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as part of the data stream. Associated bytes that have the TKEEP byte qualifier deasserted are null bytes           |
// | and can be removed from the data stream. For a 64-bit DATA, bit 0 corresponds to the least significant byte         |
// | on DATA, and bit 7 corresponds to the most significant byte. For example:                                           |
// |                                                                                                                     |
// |   KEEP[0] = 1b, DATA[7:0] is not a NULL byte                                                                        |
// |   KEEP[7] = 0b, DATA[63:56] is a NULL byte                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tlast   | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TLAST: Indicates the boundary of a packet.                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tready  | Input     | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TREADY: Indicates that the slave can accept a transfer in the current cycle.                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tstrb   | Output    | TDATA_WIDTH/8                         | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TSTRB: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as a data byte or a position byte. For a 64-bit DATA, bit 0 corresponds to the least significant byte on            |
// | DATA, and bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the most significant    |
// | byte. For example:                                                                                                  |
// |                                                                                                                     |
// |   STROBE[0] = 1b, DATA[7:0] is valid                                                                                |
// |   STROBE[7] = 0b, DATA[63:56] is not valid                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tuser   | Output    | TUSER_WIDTH                           | m_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TUSER: The user-defined sideband information that can be transmitted alongside the data stream.                     |
// +---------------------------------------------------------------------------------------------------------------------+
// | m_axis_tvalid  | Output    | 1                                     | m_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both TVALID and TREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_empty_axis| Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Empty- This signal is asserted when the number of words in the FIFO is less than or equal              |
// | to the programmable empty threshold value.                                                                          |
// | It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
// +---------------------------------------------------------------------------------------------------------------------+
// | prog_full_axis | Output    | 1                                     | s_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
// | to the programmable full threshold value.                                                                           |
// | It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
// +---------------------------------------------------------------------------------------------------------------------+
// | rd_data_count_axis| Output    | RD_DATA_COUNT_WIDTH                   | m_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Read Data Count- This bus indicates the number of words available for reading in the FIFO.                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_aclk         | Input     | 1                                     | NA      | Rising edge | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Slave Interface Clock: All signals on slave interface are sampled on the rising edge of this clock.                 |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_aresetn      | Input     | 1                                     | NA      | Active-low  | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | Active low asynchronous reset.                                                                                      |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tdata   | Input     | TDATA_WIDTH                           | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDATA: The primary payload that is used to provide the data that is passing across the interface. The width         |
// | of the data payload is an integer number of bytes.                                                                  |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tdest   | Input     | TDEST_WIDTH                           | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TDEST: Provides routing information for the data stream.                                                            |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tid     | Input     | TID_WIDTH                             | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TID: The data stream identifier that indicates different streams of data.                                           |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tkeep   | Input     | TDATA_WIDTH/8                         | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TKEEP: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as part of the data stream. Associated bytes that have the TKEEP byte qualifier deasserted are null bytes           |
// | and can be removed from the data stream. For a 64-bit DATA, bit 0 corresponds to the least significant byte         |
// | on DATA, and bit 7 corresponds to the most significant byte. For example:                                           |
// |                                                                                                                     |
// |   KEEP[0] = 1b, DATA[7:0] is not a NULL byte                                                                        |
// |   KEEP[7] = 0b, DATA[63:56] is a NULL byte                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tlast   | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TLAST: Indicates the boundary of a packet.                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tready  | Output    | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TREADY: Indicates that the slave can accept a transfer in the current cycle.                                        |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tstrb   | Input     | TDATA_WIDTH/8                         | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TSTRB: The byte qualifier that indicates whether the content of the associated byte of TDATA is processed           |
// | as a data byte or a position byte. For a 64-bit DATA, bit 0 corresponds to the least significant byte on            |
// | DATA, and bit 0 corresponds to the least significant byte on DATA, and bit 7 corresponds to the most significant    |
// | byte. For example:                                                                                                  |
// |                                                                                                                     |
// |   STROBE[0] = 1b, DATA[7:0] is valid                                                                                |
// |   STROBE[7] = 0b, DATA[63:56] is not valid                                                                          |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tuser   | Input     | TUSER_WIDTH                           | s_aclk  | NA          | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TUSER: The user-defined sideband information that can be transmitted alongside the data stream.                     |
// +---------------------------------------------------------------------------------------------------------------------+
// | s_axis_tvalid  | Input     | 1                                     | s_aclk  | Active-high | Required               |
// |---------------------------------------------------------------------------------------------------------------------|
// | TVALID: Indicates that the master is driving a valid transfer.                                                      |
// |                                                                                                                     |
// |   A transfer takes place when both TVALID and TREADY are asserted                                                   |
// +---------------------------------------------------------------------------------------------------------------------+
// | sbiterr_axis   | Output    | 1                                     | m_aclk  | Active-high | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Single Bit Error- Indicates that the ECC decoder detected and fixed a single-bit error.                             |
// +---------------------------------------------------------------------------------------------------------------------+
// | wr_data_count_axis| Output    | WR_DATA_COUNT_WIDTH                   | s_aclk  | NA          | DoNotCare              |
// |---------------------------------------------------------------------------------------------------------------------|
// | Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
// +---------------------------------------------------------------------------------------------------------------------+

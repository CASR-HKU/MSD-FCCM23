`timescale 1ns / 1ps

`include "def.sv"

(* keep_hierarchy = "yes" *)
module buf_sdp #(
    parameter BUF_LD_ADDR_WIDTH = 10,
    parameter BUF_LD_DATA_WIDTH = 8,
    parameter BUF_EX_ADDR_WIDTH = 10,
    parameter BUF_EX_DATA_WIDTH = 8,
    parameter BUF_MEM_SIZE      = 16384
) (
    input  wire                         clk,
    input  wire                         buf_ld_wr_en,
    input  wire                         buf_ld_sel,
    input  wire [BUF_LD_ADDR_WIDTH-1:0] buf_ld_addr,
    input  wire [BUF_LD_DATA_WIDTH-1:0] buf_ld_data,
    input  wire                         buf_ex_sel,
    input  wire [BUF_EX_ADDR_WIDTH-1:0] buf_ex_addr,
    output wire [BUF_EX_DATA_WIDTH-1:0] buf_ex_data
);

    // buf sel
    localparam UPDT_ADDR_WIDTH = BUF_LD_ADDR_WIDTH + 1;
    localparam EXEC_ADDR_WIDTH = BUF_EX_ADDR_WIDTH + 1;
    wire [UPDT_ADDR_WIDTH-1:0] updt_addr;
    assign updt_addr = {buf_ld_sel, buf_ld_addr};
    wire [EXEC_ADDR_WIDTH-1:0] exec_addr;
    assign exec_addr = {buf_ex_sel, buf_ex_addr};

    // Port A for Write(update)
    // Port B for Read(execute)
    xpm_memory_sdpram #(
        .ADDR_WIDTH_A(UPDT_ADDR_WIDTH),  // DECIMAL
        .ADDR_WIDTH_B(EXEC_ADDR_WIDTH),  // DECIMAL
        .AUTO_SLEEP_TIME(0),  // DECIMAL
        .BYTE_WRITE_WIDTH_A(BUF_LD_DATA_WIDTH),  // DECIMAL
        .CASCADE_HEIGHT(0),  // DECIMAL
        .CLOCKING_MODE("common_clock"),  // String
        .ECC_MODE("no_ecc"),  // String
        .MEMORY_INIT_FILE("none"),  // String
        .MEMORY_INIT_PARAM("0"),  // String
        .MEMORY_OPTIMIZATION("true"),  // String
        .MEMORY_PRIMITIVE("block"),  // String
        .MEMORY_SIZE(BUF_MEM_SIZE),  // DECIMAL
        .MESSAGE_CONTROL(0),  // DECIMAL
        .READ_DATA_WIDTH_B(BUF_EX_DATA_WIDTH),  // DECIMAL
        .READ_LATENCY_B(1),  // DECIMAL
        .READ_RESET_VALUE_B("0"),  // String
        .RST_MODE_A("SYNC"),  // String
        .RST_MODE_B("SYNC"),  // String
        .SIM_ASSERT_CHK(0),  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        .USE_EMBEDDED_CONSTRAINT(0),  // DECIMAL
        .USE_MEM_INIT(1),  // DECIMAL
        .USE_MEM_INIT_MMI(0),  // DECIMAL
        .WAKEUP_TIME("disable_sleep"),  // String
        .WRITE_DATA_WIDTH_A(BUF_LD_DATA_WIDTH),  // DECIMAL
        .WRITE_MODE_B("no_change"),  // String
        .WRITE_PROTECT(1)  // DECIMAL
    ) xpm_memory_sdpram_inst (
        .doutb(buf_ex_data),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
        .addra(updt_addr),  // ADDR_WIDTH_A-bit input: Address for port A write operations.
        .addrb(exec_addr),  // ADDR_WIDTH_B-bit input: Address for port B read operations.
        .clka(clk),  // 1-bit input: Clock signal for port A. Also clocks port B when
                     // parameter CLOCKING_MODE is "common_clock".
        .dina(buf_ld_data),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
        .ena(1'b1),  // 1-bit input: Memory enable signal for port A. Must be high on clock
        // cycles when write operations are initiated. Pipelined internally.
        .enb(1'b1),  // 1-bit input: Memory enable signal for port B. Must be high on clock
        // cycles when read operations are initiated. Pipelined internally.
        .regceb(1'b1),  // 1-bit input: Clock Enable for the last register stage on the output
                        // data path.
        .rstb(1'b0),  // 1-bit input: Reset signal for the final port B output register stage.
                      // Synchronously resets output port doutb to the value specified by
                      // parameter READ_RESET_VALUE_B.
        .wea(buf_ld_wr_en)  // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
        // for port A input data port dina. 1 bit wide when word-wide writes are
        // used. In byte-wide write configurations, each bit controls the
        // writing one byte of dina to address addra. For example, to
        // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
        // is 32, wea would be 4'b0010.

    );
endmodule

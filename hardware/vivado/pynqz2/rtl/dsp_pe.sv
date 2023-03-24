`timescale 1ns / 1ps

`include "def.sv"

(* keep_hierarchy = "yes" *)
module dsp_pe #(
    parameter VER_BUS_DW = `HW_DSP_VER_BUS_DW,
    parameter HOR_BUS_DW = `HW_DSP_HOR_BUS_DW,
    parameter DSP_A_DW   = `HW_DSP_A_DW,
    parameter DSP_B_DW   = `HW_DSP_B_DW,
    parameter DSP_P_DW   = `HW_DSP_P_DW
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  psum_sel,
    input  logic [HOR_BUS_DW-1:0] left_in,
    input  logic [VER_BUS_DW-1:0] top_in,
    output logic [HOR_BUS_DW-1:0] right_out,
    output logic [VER_BUS_DW-1:0] bottom_out
);

    // in 8-bit MACC optimization, 2 activations are combined
    logic [HOR_BUS_DW - 1:0] left_in_reg;

    logic [  DSP_A_DW - 1:0] dsp_a_in;
    logic [  DSP_B_DW - 1:0] dsp_b_in;
    logic [  DSP_P_DW - 1:0] dsp_c_in;
    logic [  DSP_P_DW - 1:0] dsp_p_out;
    logic [VER_BUS_DW-1:0]   psum_acc;

    // 8-bit MACC optimization
    assign dsp_a_in = {1'b0, top_in[15:8], 10'h000, top_in[7:0]};
    assign dsp_b_in = {{(DSP_B_DW - HOR_BUS_DW) {1'b0}}, left_in};
    assign dsp_c_in = {19'h00000, psum_acc[15:8], 10'h000, psum_acc[7:0]};

    // regs
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            left_in_reg <= 0;
        end else begin
            left_in_reg <= left_in;
        end
    end

    assign right_out  = left_in_reg;

    DSP48E1 #(
        // Feature Control Attributes: Data Path Selection
        .A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
        .B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
        .USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
        .USE_MULT("MULTIPLY"),            // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
        .USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
        // Pattern Detector Attributes: Pattern Detection Configuration
        .AUTORESET_PATDET("NO_RESET"),    // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
        .MASK(48'h3fffffffffff),          // 48-bit mask value for pattern detect (1=ignore)
        .PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
        .SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
        .SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
        .USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
        // Register Control Attributes: Pipeline Register Configuration
        .ACASCREG(1),  // Number of pipeline stages between A/ACIN and ACOUT (0-2)
        .ADREG(0),  // Pipeline stages for pre-adder (0-1)
        .ALUMODEREG(0),  // Pipeline stages for ALUMODE (0-1)
        .AREG(1),  // Pipeline stages for A (0-2)
        .BCASCREG(1),  // Number of pipeline stages between B/BCIN and BCOUT (0-2)
        .BREG(1),  // Pipeline stages for B (0-2)
        .CARRYINREG(1),  // Pipeline stages for CARRYIN (0-1)
        .CARRYINSELREG(1),  // Pipeline stages for CARRYINSEL (0-1)
        .CREG(1),  // Pipeline stages for C (0-1)
        .DREG(1),  // Pipeline stages for D (0-1)
        .INMODEREG(0),  // Pipeline stages for INMODE (0-1)
        .MREG(1),  // Multiplier pipeline stages (0-1)
        .OPMODEREG(0),  // Pipeline stages for OPMODE (0-1)
        .PREG(1)  // Number of pipeline stages for P (0-1)
    )
    DSP48E1_inst (
        // Cascade: 30-bit (each) output: Cascade Ports
        // .ACOUT(ACOUT),                   // 30-bit output: A port cascade
        // .BCOUT(BCOUT),                   // 18-bit output: B cascade
        // .CARRYCASCOUT(CARRYCASCOUT),     // 1-bit output: Cascade carry
        // .MULTSIGNOUT(MULTSIGNOUT),       // 1-bit output: Multiplier sign cascade
        // .PCOUT(PCOUT),                   // 48-bit output: Cascade output
        // Control outputs: Control Inputs/Status Bits
        // .OVERFLOW(OVERFLOW),             // 1-bit output: Overflow in add/acc
        // .PATTERNBDETECT(PATTERNBDETECT), // 1-bit output: Pattern bar detect
        // .PATTERNDETECT(PATTERNDETECT),   // 1-bit output: Pattern detect
        // .UNDERFLOW(UNDERFLOW),           // 1-bit output: Underflow in add/acc
        // Data outputs: Data Ports
        // .CARRYOUT(CARRYOUT),             // 4-bit output: Carry
        .P(dsp_p_out),  // 48-bit output: Primary data
        // .XOROUT(XOROUT),                 // 8-bit output: XOR data
        // Cascade inputs: Cascade Ports
        // .ACIN(ACIN),                     // 30-bit input: A cascade data
        // .BCIN(BCIN),                     // 18-bit input: B cascade
        // .CARRYCASCIN(CARRYCASCIN),       // 1-bit input: Cascade carry
        // .MULTSIGNIN(MULTSIGNIN),         // 1-bit input: Multiplier sign cascade
        // .PCIN(PCIN),                     // 48-bit input: P cascade
        // Control inputs: Control Inputs/Status Bits
        .ALUMODE(4'b0000),  // 4-bit input: ALU control
        // .CARRYINSEL(CARRYINSEL),         // 3-bit input: Carry select
        .CLK(clk),  // 1-bit input: Clock
        .INMODE(5'b10001),  // 5-bit input: INMODE control
        .OPMODE(9'b00_011_01_01),  // 9-bit input: Operation mode
        // Data inputs: Data Ports
        .A({3'b000, dsp_a_in}),  // 30-bit input: A data
        .B(dsp_b_in),  // 18-bit input: B data
        .C({3'b000, dsp_c_in}),  // 48-bit input: C data
        // .CARRYIN(CARRYIN),               // 1-bit input: Carry-in
        // .D(D),                           // 27-bit input: D data
        // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
        .CEA1(1'b1),  // 1-bit input: Clock enable for 1st stage AREG
        .CEA2(1'b1),  // 1-bit input: Clock enable for 2nd stage AREG
        .CEAD(1'b0),  // 1-bit input: Clock enable for ADREG
        .CEALUMODE(1'b0),  // 1-bit input: Clock enable for ALUMODE
        .CEB1(1'b1),  // 1-bit input: Clock enable for 1st stage BREG
        .CEB2(1'b1),  // 1-bit input: Clock enable for 2nd stage BREG
        .CEC(1'b1),  // 1-bit input: Clock enable for CREG
        .CECARRYIN(1'b0),  // 1-bit input: Clock enable for CARRYINREG
        .CECTRL(1'b0),  // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
        .CED(1'b1),  // 1-bit input: Clock enable for DREG
        .CEINMODE(1'b0),  // 1-bit input: Clock enable for INMODEREG
        .CEM(1'b1),  // 1-bit input: Clock enable for MREG
        .CEP(1'b1),  // 1-bit input: Clock enable for PREG
        .RSTA(~rst_n),  // 1-bit input: Reset for AREG
        .RSTALLCARRYIN(~rst_n),  // 1-bit input: Reset for CARRYINREG
        .RSTALUMODE(1'b0),  // 1-bit input: Reset for ALUMODEREG
        .RSTB(~rst_n),  // 1-bit input: Reset for BREG
        .RSTC(1'b0),  // 1-bit input: Reset for CREG
        .RSTCTRL(1'b0),  // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
        .RSTD(1'b0),  // 1-bit input: Reset for DREG and ADREG
        .RSTINMODE(1'b0),  // 1-bit input: Reset for INMODEREG
        .RSTM(~rst_n),  // 1-bit input: Reset for MREG
        .RSTP(~rst_n)  // 1-bit input: Reset for PREG
    );


    // DSP48E1 #(
    //     // Feature Control Attributes: Data Path Selection
    //     .AMULTSEL("A"),  // Selects A input to multiplier (A, AD)
    //     .A_INPUT("DIRECT"),  // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
    //     .BMULTSEL("B"),  // Selects B input to multiplier (AD, B)
    //     .B_INPUT("DIRECT"),  // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
    //     .PREADDINSEL("A"),  // Selects input to pre-adder (A, B)
    //     .RND(48'h000000000000),  // Rounding Constant
    //     .USE_MULT("MULTIPLY"),  // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
    //     .USE_SIMD("ONE48"),  // SIMD selection (FOUR12, ONE48, TWO24)
    //     .USE_WIDEXOR("FALSE"),  // Use the Wide XOR function (FALSE, TRUE)
    //     .XORSIMD("XOR24_48_96"),  // Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
    //     // Pattern Detector Attributes: Pattern Detection Configuration
    //     .AUTORESET_PATDET("NO_RESET"),  // NO_RESET, RESET_MATCH, RESET_NOT_MATCH
    //     .AUTORESET_PRIORITY("RESET"),  // Priority of AUTORESET vs. CEP (CEP, RESET).
    //     .MASK(48'h3fffffffffff),  // 48-bit mask value for pattern detect (1=ignore)
    //     .PATTERN(48'h000000000000),  // 48-bit pattern match for pattern detect
    //     .SEL_MASK("MASK"),  // C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
    //     .SEL_PATTERN("PATTERN"),  // Select pattern value (C, PATTERN)
    //     .USE_PATTERN_DETECT("NO_PATDET"),  // Enable pattern detect (NO_PATDET, PATDET)
    //     // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
    //     .IS_ALUMODE_INVERTED(4'b0000),  // Optional inversion for ALUMODE
    //     .IS_CARRYIN_INVERTED(1'b0),  // Optional inversion for CARRYIN
    //     .IS_CLK_INVERTED(1'b0),  // Optional inversion for CLK
    //     .IS_INMODE_INVERTED(5'b00000),  // Optional inversion for INMODE
    //     .IS_OPMODE_INVERTED(9'b000000000),  // Optional inversion for OPMODE
    //     .IS_RSTALLCARRYIN_INVERTED(1'b0),  // Optional inversion for RSTALLCARRYIN
    //     .IS_RSTALUMODE_INVERTED(1'b0),  // Optional inversion for RSTALUMODE
    //     .IS_RSTA_INVERTED(1'b0),  // Optional inversion for RSTA
    //     .IS_RSTB_INVERTED(1'b0),  // Optional inversion for RSTB
    //     .IS_RSTCTRL_INVERTED(1'b0),  // Optional inversion for RSTCTRL
    //     .IS_RSTC_INVERTED(1'b0),  // Optional inversion for RSTC
    //     .IS_RSTD_INVERTED(1'b0),  // Optional inversion for RSTD
    //     .IS_RSTINMODE_INVERTED(1'b0),  // Optional inversion for RSTINMODE
    //     .IS_RSTM_INVERTED(1'b0),  // Optional inversion for RSTM
    //     .IS_RSTP_INVERTED(1'b0),  // Optional inversion for RSTP
    //     // Register Control Attributes: Pipeline Register Configuration
    //     .ACASCREG(1),  // Number of pipeline stages between A/ACIN and ACOUT (0-2)
    //     .ADREG(0),  // Pipeline stages for pre-adder (0-1)
    //     .ALUMODEREG(0),  // Pipeline stages for ALUMODE (0-1)
    //     .AREG(1),  // Pipeline stages for A (0-2)
    //     .BCASCREG(1),  // Number of pipeline stages between B/BCIN and BCOUT (0-2)
    //     .BREG(1),  // Pipeline stages for B (0-2)
    //     .CARRYINREG(1),  // Pipeline stages for CARRYIN (0-1)
    //     .CARRYINSELREG(1),  // Pipeline stages for CARRYINSEL (0-1)
    //     .CREG(1),  // Pipeline stages for C (0-1)
    //     .DREG(1),  // Pipeline stages for D (0-1)
    //     .INMODEREG(0),  // Pipeline stages for INMODE (0-1)
    //     .MREG(1),  // Multiplier pipeline stages (0-1)
    //     .OPMODEREG(0),  // Pipeline stages for OPMODE (0-1)
    //     .PREG(1)  // Number of pipeline stages for P (0-1)
    // ) DSP48E2_inst (
    //     // Cascade outputs: Cascade Ports
    //     // .ACOUT(ACOUT),                   // 30-bit output: A port cascade
    //     // .BCOUT(BCOUT),                   // 18-bit output: B cascade
    //     // .CARRYCASCOUT(CARRYCASCOUT),     // 1-bit output: Cascade carry
    //     // .MULTSIGNOUT(MULTSIGNOUT),       // 1-bit output: Multiplier sign cascade
    //     // .PCOUT(PCOUT),                   // 48-bit output: Cascade output
    //     // Control outputs: Control Inputs/Status Bits
    //     // .OVERFLOW(OVERFLOW),             // 1-bit output: Overflow in add/acc
    //     // .PATTERNBDETECT(PATTERNBDETECT), // 1-bit output: Pattern bar detect
    //     // .PATTERNDETECT(PATTERNDETECT),   // 1-bit output: Pattern detect
    //     // .UNDERFLOW(UNDERFLOW),           // 1-bit output: Underflow in add/acc
    //     // Data outputs: Data Ports
    //     // .CARRYOUT(CARRYOUT),             // 4-bit output: Carry
    //     .P(dsp_p_out),  // 48-bit output: Primary data
    //     // .XOROUT(XOROUT),                 // 8-bit output: XOR data
    //     // Cascade inputs: Cascade Ports
    //     // .ACIN(ACIN),                     // 30-bit input: A cascade data
    //     // .BCIN(BCIN),                     // 18-bit input: B cascade
    //     // .CARRYCASCIN(CARRYCASCIN),       // 1-bit input: Cascade carry
    //     // .MULTSIGNIN(MULTSIGNIN),         // 1-bit input: Multiplier sign cascade
    //     // .PCIN(PCIN),                     // 48-bit input: P cascade
    //     // Control inputs: Control Inputs/Status Bits
    //     .ALUMODE(4'b0000),  // 4-bit input: ALU control
    //     // .CARRYINSEL(CARRYINSEL),         // 3-bit input: Carry select
    //     .CLK(clk),  // 1-bit input: Clock
    //     .INMODE(5'b10001),  // 5-bit input: INMODE control
    //     .OPMODE(9'b00_011_01_01),  // 9-bit input: Operation mode
    //     // Data inputs: Data Ports
    //     .A({3'b000, dsp_a_in}),  // 30-bit input: A data
    //     .B(dsp_b_in),  // 18-bit input: B data
    //     .C({3'b000, dsp_c_in}),  // 48-bit input: C data
    //     // .CARRYIN(CARRYIN),               // 1-bit input: Carry-in
    //     // .D(D),                           // 27-bit input: D data
    //     // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
    //     .CEA1(1'b1),  // 1-bit input: Clock enable for 1st stage AREG
    //     .CEA2(1'b1),  // 1-bit input: Clock enable for 2nd stage AREG
    //     .CEAD(1'b0),  // 1-bit input: Clock enable for ADREG
    //     .CEALUMODE(1'b0),  // 1-bit input: Clock enable for ALUMODE
    //     .CEB1(1'b1),  // 1-bit input: Clock enable for 1st stage BREG
    //     .CEB2(1'b1),  // 1-bit input: Clock enable for 2nd stage BREG
    //     .CEC(1'b1),  // 1-bit input: Clock enable for CREG
    //     .CECARRYIN(1'b0),  // 1-bit input: Clock enable for CARRYINREG
    //     .CECTRL(1'b0),  // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
    //     .CED(1'b1),  // 1-bit input: Clock enable for DREG
    //     .CEINMODE(1'b0),  // 1-bit input: Clock enable for INMODEREG
    //     .CEM(1'b1),  // 1-bit input: Clock enable for MREG
    //     .CEP(1'b1),  // 1-bit input: Clock enable for PREG
    //     .RSTA(~rst_n),  // 1-bit input: Reset for AREG
    //     .RSTALLCARRYIN(~rst_n),  // 1-bit input: Reset for CARRYINREG
    //     .RSTALUMODE(1'b0),  // 1-bit input: Reset for ALUMODEREG
    //     .RSTB(~rst_n),  // 1-bit input: Reset for BREG
    //     .RSTC(1'b0),  // 1-bit input: Reset for CREG
    //     .RSTCTRL(1'b0),  // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
    //     .RSTD(1'b0),  // 1-bit input: Reset for DREG and ADREG
    //     .RSTINMODE(1'b0),  // 1-bit input: Reset for INMODEREG
    //     .RSTM(~rst_n),  // 1-bit input: Reset for MREG
    //     .RSTP(~rst_n)  // 1-bit input: Reset for PREG
    // );

    logic [VER_BUS_DW-1:0] bottom_o_reg;
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            bottom_o_reg <= 0;
        end else begin
            bottom_o_reg <= psum_sel ? psum_acc : top_in;
        end
    end
    assign bottom_out = bottom_o_reg;

    always_ff @( posedge clk ) begin
        if (~rst_n) begin
            psum_acc <= 0;
        end
        else begin
            psum_acc <= dsp_p_out[31:16];
        end
    end

endmodule

`default_nettype none
`include "defines.vh"

module ID (
    input wire clk_i,
    input wire rst_i,

    input wire [31:0] inst_i,
    input wire [4:0] rf_waddr_i,
    input wire [31:0] rf_wdata_i,
    input wire rf_wen_i,
    input wire [1:0] rdata1_bypass_i,
    input wire [1:0] rdata2_bypass_i,
    input wire [31:0] exe_alu_result_i,
    input wire [31:0] mem_rf_wdata_i,
    output wire alu_src_o,
    output wire [`WIDTH_ALU_FUNCT] alu_funct_o,
    output wire [`WIDTH_INST_TYPE] inst_type_o,
    output wire [31:0] imm_o,
    output wire [31:0] rf_rdata1_o,
    output wire [31:0] rf_rdata2_o
);

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [31:0] id_rf_rdata1;
    logic [31:0] id_rf_rdata2;

    assign rf_rdata1_o = rdata1_bypass_i == `EN_NoBypass ? id_rf_rdata1 : (rdata1_bypass_i == `EN_EXEBypass ? exe_alu_result_i : mem_rf_wdata_i);
    assign rf_rdata2_o = rdata2_bypass_i == `EN_NoBypass ? id_rf_rdata2 : (rdata2_bypass_i == `EN_EXEBypass ? exe_alu_result_i : mem_rf_wdata_i);

    inst_decoder inst_decoder(
        .inst_i(inst_i),
        .rs1_o(rs1),
        .rs2_o(rs2),
        .alu_src_o(alu_src_o), // alu 的第 2 个输入是 rdata_2（0）还是 imm（1）
        .alu_funct_o(alu_funct_o),
        .inst_type_o(inst_type_o),
        .imm_o(imm_o)
    );

    register_file register_file (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rd_i(rf_waddr_i),
        .wdata_i(rf_wdata_i),
        .we_i(rf_wen_i),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .rdata1_o(id_rf_rdata1),
        .rdata2_o(id_rf_rdata2)
    );

endmodule
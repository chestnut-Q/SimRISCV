`default_nettype none
`include "defines.vh"

module IF (
    input wire clk_i,
    input wire rst_i,

    input wire stall_i,
    input wire [`WIDTH_INST_TYPE] id_inst_type_i,
    input wire [31:0] id_inst_i,
    input wire [31:0] if_inst_i,
    input wire [31:0] id_rf_rdata1_i,
    input wire [31:0] id_rf_rdata2_i,
    input wire [31:0] id_imm_i,
    input wire [31:0] id_PC_i,
    input wire [31:0] id_csr_branch_addr_i,
    input wire id_csr_branch_flag_i,
    output wire [31:0] if_PC_o
);

    logic branch;
    logic jump;
    logic [31:0] jump_addr;
    logic [31:0] branch_addr;
    logic rs1_equals_rs2;
    assign rs1_equals_rs2 = (id_rf_rdata1_i == id_rf_rdata2_i);
    assign branch = ((id_inst_type_i == `TYPE_B && ((id_inst_i[14:12] == `FUNCT3_BEQ && rs1_equals_rs2) || (id_inst_i[14:12] == `FUNCT3_BNE && !rs1_equals_rs2))) === 1'b1);
    assign jump = ((!branch && (if_inst_i[6:0] == `OP_JAL || id_inst_i[6:0] == `OP_JALR)) === 1'b1);
    assign jump_addr = id_inst_i[6:0] == `OP_JALR ? (id_rf_rdata1_i + id_imm_i) & (-2) : if_PC_o + {{19{if_inst_i[31]}}, if_inst_i[31], if_inst_i[19:12], if_inst_i[20], if_inst_i[30:21], 1'b0}; 
    assign branch_addr = id_PC_i + id_imm_i;

    PC_mux PC_mux(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rst_addr_i(`StartInstAddr),
        .stall_i(stall_i),
        .PC_src_i(branch), // BEQ, BNE
        .branch_addr_i(jump ? jump_addr : branch_addr),
        .jump_i(jump), // J
        .csr_branch_addr_i(id_csr_branch_addr_i),
        .csr_branch_flag_i(id_csr_branch_flag_i),
        .PC_o(if_PC_o)
    );

endmodule
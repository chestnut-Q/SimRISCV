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
    input wire [31:0] exe_inst_i,
    input wire [31:0] exe_alu_result_i,
    input wire [31:0] exe_csr_result_i,
    input wire [31:0] mem_rf_wdata_i,
    output reg alu_src_o,
    output reg [`WIDTH_ALU_FUNCT] alu_funct_o,
    output reg [6:0] alu_opcode_o,
    output reg [`WIDTH_INST_TYPE] inst_type_o,
    output reg [31:0] imm_o,
    output reg [31:0] rf_rdata1_o,
    output reg [31:0] rf_rdata2_o,
    output reg [11:0] csr_addr_o,
    output reg [2:0] csr_funct3_o,
    output reg [31:0] csr_branch_addr_o,
    output reg csr_branch_flag_o,
    input wire[31:0] mtvec_i,
    output reg mtvec_we,
    output reg [31:0] mtvec_o,
    input wire [31:0] mscratch_i,
    output reg mscratch_we,
    output reg [31:0] mscratch_o,
    input wire [31:0] mepc_i,
    output reg mepc_we,
    output reg [31:0] mepc_o,
    input wire [31:0] mcause_i,
    output reg mcause_we,
    output reg [31:0] mcause_o,
    input wire [31:0] mstatus_i,
    output reg mstatus_we,
    output reg [31:0] mstatus_o,
    input wire [31:0] mie_i,
    output reg mie_we,
    output reg [31:0] mie_o,
    input wire [31:0] mip_i,
    output reg mip_we,
    output reg [31:0] mip_o,
    input wire [31:0] satp_i,
    output reg satp_we,
    output reg [31:0] satp_o,
    input wire [1:0] priv_level_i,
    output reg priv_level_we,
    output reg [1:0] priv_level_o
);

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [31:0] id_rf_rdata1;
    logic [31:0] id_rf_rdata2;
    logic [6:0] exe_opcode;
    logic [4:0] exe_rd;

    assign exe_opcode = exe_inst_i[6:0];
    assign exe_rd = exe_inst_i[11:7];

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

    assign rf_rdata1_o = rdata1_bypass_i == `EN_NoBypass ? id_rf_rdata1 : (rdata1_bypass_i == `EN_EXEBypass ? (exe_alu_result_i) : mem_rf_wdata_i);
    assign rf_rdata2_o = rdata2_bypass_i == `EN_NoBypass ? id_rf_rdata2 : (rdata2_bypass_i == `EN_EXEBypass ?  (exe_alu_result_i) : mem_rf_wdata_i);

    always_comb begin
        if (rst_i) begin
            mtvec_we = 1'b0;
            mtvec_o = 32'b0;
            mscratch_we = 1'b0;
            mscratch_o = 32'b0;
            mepc_we = 1'b0;
            mepc_o = 32'b0;
            mcause_we = 1'b0;
            mcause_o = 32'b0;
            mstatus_we = 1'b0;
            mstatus_o = 32'b0;
            mie_we = 1'b0;
            mie_o = 32'b0;
            mip_we = 1'b0;
            mip_o = 32'b0;
            satp_we = 1'b0;
            satp_o = 32'b0;
            priv_level_we = 1'b0;
            priv_level_o = 32'b0;
            alu_opcode_o = `OP_INVALID;
            csr_funct3_o = 3'b111;
            csr_branch_addr_o = 32'b0;
            csr_branch_flag_o = 1'b0;
            csr_addr_o = 12'b0;
        end else begin
            mtvec_we = 1'b0;
            mtvec_o = mtvec_i;
            mscratch_we = 1'b0;
            mscratch_o = mscratch_i;
            mepc_we = 1'b0;
            mepc_o = mepc_i;
            mcause_we = 1'b0;
            mcause_o = mcause_i;
            mstatus_we = 1'b0;
            mstatus_o = mstatus_i;
            mie_we = 1'b0;
            mie_o = mie_i;
            mip_we = 1'b0;
            mip_o = mip_i;
            satp_we = 1'b0;
            satp_o = satp_i;
            priv_level_we = 1'b0;
            priv_level_o = priv_level_i;
            csr_branch_addr_o = 32'b0;
            csr_branch_flag_o = 1'b0;
            if ((mstatus_i[3] | ~priv_level_i[0]) & mip_i[7] & mie_i[7]) 
            // 当 mip.MTIP, mie.MTIE 同时为 1，且当前特权态下全局中断启用时，CPU 即触发时钟中断。
            begin
                alu_opcode_o = `OP_CSR;
                csr_funct3_o = `FUNCT3_EBREAK;
                csr_addr_o = `TIMER;
                priv_level_we = 1'b1;
                mstatus_we = 1'b1;
                mepc_we = 1'b1;
                mcause_we = 1'b1;
                csr_branch_flag_o = 1'b1;
                csr_branch_addr_o = mtvec_i;
            end else begin
                alu_opcode_o = inst_i[6:0];
                csr_funct3_o = inst_i[14:12];
                csr_addr_o = inst_i[31:20];
                case (alu_opcode_o)
                    `OP_CSR: begin
                        case (csr_funct3_o)
                            `FUNCT3_CSRRC, `FUNCT3_CSRRS, `FUNCT3_CSRRW: begin
                                case (csr_addr_o)
                                    `CSR_MTVEC: mtvec_we = 1'b1;
                                    `CSR_MSCRATCH: mscratch_we = 1'b1;
                                    `CSR_MEPC: mepc_we = 1'b1;
                                    `CSR_MCAUSE: mcause_we = 1'b1;
                                    `CSR_MSTATUS: mstatus_we = 1'b1;
                                    `CSR_MIE: mie_we = 1'b1;
                                    `CSR_MIP: mip_we = 1'b1;
                                    `CSR_SATP: satp_we = 1'b1;
                                    default: mtvec_we = 1'b0;
                                endcase
                            end
                            `FUNCT3_EBREAK: begin
                                case (csr_addr_o)
                                    `MRET: begin
                                        priv_level_we = 1'b1;
                                        mstatus_we = 1'b1;
                                        csr_branch_flag_o = 1'b1;
                                        csr_branch_addr_o = mepc_i;
                                    end
                                    `ECALL, `EBREAK: begin
                                        priv_level_we = 1'b1;
                                        mstatus_we = 1'b1;
                                        mepc_we = 1'b1;
                                        mcause_we = 1'b1;
                                        csr_branch_flag_o = 1'b1;
                                        csr_branch_addr_o = mtvec_i;
                                    end
                                    default: begin
                                    end
                                endcase
                            end
                        endcase
                    end
                    default: begin
                        csr_addr_o = 12'b0;
                    end
                endcase
            end
        end     
    end

endmodule
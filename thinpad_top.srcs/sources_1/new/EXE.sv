`default_nettype none
`include "defines.vh"

module EXE (
    input wire rst_i,
    input reg[31:0] inst_i,
    input wire [`WIDTH_INST_TYPE] inst_type_i,
    input reg [31:0] PC_i,
    input reg [31:0] rdata1_i,
    input reg [31:0] rdata2_i,
    input reg alu_src_i,
    input reg [6:0] alu_opcode_i,
    input reg [11:0] csr_addr_i,
    input reg [2:0] csr_funct3_i,
    input reg [31:0] imm_i,
    input reg [`WIDTH_ALU_FUNCT] alu_funct_i,
    output reg [31:0] alu_result_o,
    output reg [31:0] csr_result_o,

    input wire[31:0] mtvec_i,
    input reg mtvec_we_i,
    output reg [31:0] mtvec_o,
    output reg mtvec_we_o,

    input wire [31:0] mscratch_i,
    input reg mscratch_we_i,
    output reg [31:0] mscratch_o,
    output reg mscratch_we_o,

    input wire [31:0] mepc_i,
    input reg mepc_we_i,
    output reg [31:0] mepc_o,
    output reg mepc_we_o,

    input wire [31:0] mcause_i,
    input reg mcause_we_i,
    output reg [31:0] mcause_o,
    output reg mcause_we_o,

    input wire [31:0] mstatus_i,
    input reg mstatus_we_i,
    output reg [31:0] mstatus_o,
    output reg mstatus_we_o,

    input wire [31:0] mie_i,
    input reg mie_we_i,
    output reg [31:0] mie_o,
    output reg mie_we_o,

    input wire [31:0] mip_i,
    input reg mip_we_i,
    output reg [31:0] mip_o,
    output reg mip_we_o,

    input wire [31:0] satp_i,
    input reg satp_we_i,
    output reg [31:0] satp_o,
    output reg satp_we_o,

    input wire [1:0] priv_level_i,
    input reg priv_level_we_i,
    output reg [1:0] priv_level_o,
    output reg priv_level_we_o
);

  reg [31:0] alu_a;
  reg [31:0] alu_b;
  reg [`WIDTH_ALU_FUNCT] alu_op;
  reg [31:0] alu_result;

  ALU ALU(
    .a(alu_a),
    .b(alu_b),
    .op(alu_op),
    .y(alu_result)
  );

  always_comb begin
    if (rst_i) begin
      mtvec_o = 32'b0;
      mtvec_we_o = 1'b0;
      mscratch_o = 32'b0;
      mscratch_we_o = 1'b0;
      mepc_o = 32'b0;
      mepc_we_o = 1'b0;
      mcause_o = 32'b0;
      mcause_we_o = 1'b0;
      mstatus_o = 32'b0;
      mstatus_we_o = 1'b0;
      mie_o = 32'b0;
      mie_we_o = 1'b0;
      mip_o = 32'b0;
      mip_we_o = 1'b0;
      satp_o = 32'b0;
      satp_we_o = 1'b0;
      priv_level_o = 2'b0;
      priv_level_we_o = 1'b0;
      alu_result_o = 32'b0;
      csr_result_o = 32'b0;
    end else begin
      mtvec_we_o = mtvec_we_i;
      mscratch_we_o = mscratch_we_i;
      mepc_we_o = mepc_we_i;
      mcause_we_o = mcause_we_i;
      mstatus_we_o = mstatus_we_i;
      mie_we_o = mie_we_i;
      mip_we_o = mip_we_i;
      satp_we_o = satp_we_i; 
      priv_level_we_o = priv_level_we_i;
      case (alu_opcode_i)
        `OP_CSR: begin
          case (csr_funct3_i)
            `FUNCT3_EBREAK: begin
              case (csr_addr_i)
                `TIMER: begin
                  mepc_o = PC_i;
                  mcause_o = {1'b1, 27'b0, 4'b0111}; // Machine timer interrupt
                  priv_level_o = 2'b11;
                  mstatus_o = {mstatus_i[31:13], priv_level_i, mstatus_i[10:8], mstatus_i[3], mstatus_i[6:4], 1'b0, mstatus_i[2:0]};
                end
                `MRET: begin
                  priv_level_o = mstatus_i[12:11];
                  mstatus_o = {mstatus_i[31:13], 2'b11, mstatus_i[10:8], mstatus_i[3], mstatus_i[6:4], mstatus_i[7], mstatus_i[2:0]};
                end
                `ECALL: begin
                  mepc_o = PC_i;
                  mcause_o = {1'b0, 27'b0, 4'b1000};
                  priv_level_o = 2'b11;
                  mstatus_o = {mstatus_i[31:13], priv_level_i, mstatus_i[10:8], mstatus_i[3], mstatus_i[6:4], 1'b0, mstatus_i[2:0]};
                end
                `EBREAK: begin
                  mepc_o = PC_i;
                  mcause_o = {1'b0, 27'b0, 4'b0011};
                  priv_level_o = 2'b11;
                  mstatus_o = {mstatus_i[31:13], priv_level_i, mstatus_i[10:8], mstatus_i[3], mstatus_i[6:4], 1'b0, mstatus_i[2:0]};
                end
                default: begin
                end
              endcase
            end
            `FUNCT3_CSRRW: begin
              case (csr_addr_i)
                `CSR_MTVEC: begin
                  alu_result_o = mtvec_i;
                  mtvec_o = rdata1_i;
                  csr_result_o = mtvec_i;
                end
                `CSR_MSCRATCH: begin
                  alu_result_o = mscratch_i;
                  mscratch_o = rdata1_i;
                  csr_result_o = mscratch_i;
                end
                `CSR_MEPC: begin
                  alu_result_o = mepc_i;
                  mepc_o = rdata1_i;
                  csr_result_o = mepc_i;
                end
                `CSR_MCAUSE: begin
                  alu_result_o = mcause_i;
                  mcause_o = rdata1_i;
                  csr_result_o = mcause_i;
                end
                `CSR_MSTATUS: begin
                  alu_result_o = mstatus_i;
                  mstatus_o = rdata1_i;
                  csr_result_o = mstatus_i;
                end
                `CSR_MIE: begin
                  alu_result_o = mie_i;
                  mie_o = rdata1_i;
                  csr_result_o = mie_i;
                end
                `CSR_MIP: begin
                  alu_result_o = mip_i;
                  mip_o = rdata1_i;
                  csr_result_o = mip_i;
                end
                `CSR_SATP: begin
                  alu_result_o = satp_i;
                  satp_o = rdata1_i;
                  csr_result_o = satp_i;
                end
                default: begin
                end
              endcase
            end
            `FUNCT3_CSRRS: begin
              case (csr_addr_i)
                `CSR_MTVEC: begin
                  alu_result_o = mtvec_i;
                  mtvec_o = mtvec_i | rdata1_i;
                  csr_result_o = mtvec_i;
                end
                `CSR_MSCRATCH: begin
                  alu_result_o = mscratch_i;
                  mscratch_o = mscratch_i | rdata1_i;
                  csr_result_o = mscratch_i;
                end
                `CSR_MEPC: begin
                  alu_result_o = mepc_i;
                  mepc_o = mepc_i | rdata1_i;
                  csr_result_o = mepc_i;
                end
                `CSR_MCAUSE: begin
                  alu_result_o = mcause_i;
                  mcause_o = mcause_i | rdata1_i;
                  csr_result_o = mcause_i;
                end
                `CSR_MSTATUS: begin
                  alu_result_o = mstatus_i;
                  mstatus_o = mstatus_i | rdata1_i;
                  csr_result_o = mstatus_i;
                end
                `CSR_MIE: begin
                  alu_result_o = mie_i;
                  mie_o = mie_i | rdata1_i;
                  csr_result_o = mie_i;
                end
                `CSR_MIP: begin
                  alu_result_o = mip_i;
                  mip_o = mip_i | rdata1_i;
                  csr_result_o = mip_i;
                end
                `CSR_SATP: begin
                  alu_result_o = satp_i;
                  satp_o = satp_i | rdata1_i;
                  csr_result_o = satp_i;
                end
                default: begin
                end
              endcase
            end
            `FUNCT3_CSRRC: begin
              case (csr_addr_i)
                `CSR_MTVEC: begin
                  alu_result_o = mtvec_i;
                  mtvec_o = mtvec_i & ~rdata1_i;
                  csr_result_o = mtvec_i;
                end
                `CSR_MSCRATCH: begin
                  alu_result_o = mscratch_i;
                  mscratch_o = mscratch_i & ~rdata1_i;
                  csr_result_o = mscratch_i;
                end
                `CSR_MEPC: begin
                  alu_result_o = mepc_i;
                  mepc_o = mepc_i & ~rdata1_i;
                  csr_result_o = mepc_i;
                end
                `CSR_MCAUSE: begin
                  alu_result_o = mcause_i;
                  mcause_o = mcause_i & ~rdata1_i;
                  csr_result_o = mcause_i;
                end
                `CSR_MSTATUS: begin
                  alu_result_o = mstatus_i;
                  mstatus_o = mstatus_i & ~rdata1_i;
                  csr_result_o = mstatus_i;
                end
                `CSR_MIE: begin
                  alu_result_o = mie_i;
                  mie_o = mie_i & ~rdata1_i;
                  csr_result_o = mie_i;
                end
                `CSR_MIP: begin
                  alu_result_o = mip_i;
                  mip_o = mip_i & ~rdata1_i;
                  csr_result_o = mip_i;
                end
                `CSR_SATP: begin
                  alu_result_o = satp_i;
                  satp_o = satp_i & ~rdata1_i;
                  csr_result_o = satp_i;
                end
                default: begin
                end
              endcase
            end
          endcase
        end
      default: begin
        alu_a = (inst_i[6:0] == `OP_AUIPC || inst_type_i == `TYPE_J) ? PC_i : rdata1_i;
        alu_b = (alu_src_i == `EN_Imm) ? imm_i : rdata2_i;
        alu_op = alu_funct_i;
        alu_result_o = alu_result;
        csr_result_o = 32'b0;
        mtvec_o = mtvec_i;
        mscratch_o = mscratch_i;
        mepc_o = mepc_i;
        mcause_o = mcause_i;
        mstatus_o = mstatus_i;
        mie_o = mie_i;
        mip_o = mip_i;
        satp_o = satp_i;
        priv_level_o = priv_level_i;
      end
    endcase
    end 
  end

endmodule
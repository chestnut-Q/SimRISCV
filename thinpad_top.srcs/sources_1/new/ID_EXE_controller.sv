`default_nettype none
`include "defines.vh"

module ID_EXE_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] PC_i,
	input wire [31:0] inst_i,
	input wire [`WIDTH_INST_TYPE] inst_type_i,
	input wire [6:0] alu_opcode_i,
	input wire [`WIDTH_ALU_FUNCT] alu_funct_i,
	input wire alu_src_i,
	input wire [11:0] csr_addr_i,
	input wire [2:0] csr_funct3_i,
	input wire [31:0] imm_i,
	input wire [31:0] rdata1_i,
	input wire [31:0] rdata2_i,
	output reg [31:0] inst_o,
	output reg [`WIDTH_INST_TYPE] inst_type_o,
	output reg [6:0] alu_opcode_o,
	output reg [`WIDTH_ALU_FUNCT] alu_funct_o,
	output reg alu_src_o,
	output reg [11:0] csr_addr_o,
	output reg [2:0] csr_funct3_o,
	output reg [31:0] imm_o,
	output reg [31:0] rdata1_o,
	output reg [31:0] rdata2_o,
	output reg [31:0] PC_o,
	input wire id_mtvec_we,
	input wire [31:0] id_mtvec_i,
	output reg exe_mtvec_we,
	output reg [31:0] exe_mtvec_o,
	input wire id_mscratch_we,
	input wire [31:0] id_mscratch_i,
	output reg exe_mscratch_we,
	output reg [31:0] exe_mscratch_o,
	input wire id_mepc_we,
	input wire [31:0] id_mepc_i,
	output reg exe_mepc_we,
	output reg [31:0] exe_mepc_o,
	input wire id_mcause_we,
	input wire [31:0] id_mcause_i,
	output reg exe_mcause_we,
	output reg [31:0] exe_mcause_o,
	input wire id_mstatus_we,
	input wire [31:0] id_mstatus_i,
	output reg exe_mstatus_we,
	output reg [31:0] exe_mstatus_o,
	input wire id_mie_we,
	input wire [31:0] id_mie_i,
	output reg exe_mie_we,
	output reg [31:0] exe_mie_o,
	input wire id_mip_we,
	input wire [31:0] id_mip_i,
	output reg exe_mip_we,
	output reg [31:0] exe_mip_o,
	input wire id_priv_level_we,
	output reg exe_priv_level_we,
	input wire [1:0] id_priv_level_i,
	output reg [1:0] exe_priv_level_o
);

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            inst_o <= `NOP;
			inst_type_o <= `TYPE_I;
			alu_funct_o <= `FUNCT3_ADD;
			alu_src_o <= `EN_Imm;
			alu_opcode_o <= `OP_INVALID;
			csr_addr_o <= 12'b0;
			csr_funct3_o <= 3'b0;
			imm_o <= '0;
			rdata1_o <= '0;
			rdata2_o <= '0;

			exe_mtvec_we <= 1'b0;
			exe_mtvec_o <= 32'b0;
			exe_mscratch_we <= 1'b0;
			exe_mscratch_o <= 32'b0;
			exe_mepc_we <= 1'b0;
			exe_mepc_o <= 32'b0;
			exe_mcause_we <= 1'b0;
			exe_mcause_o <= 32'b0;
			exe_mstatus_we <= 1'b0;
			exe_mstatus_o <= 32'b0;
			exe_mie_we <= 1'b0;
			exe_mie_o <= 32'b0;
			exe_mip_we <= 1'b0;
			exe_mip_o <= 32'b0;
			exe_priv_level_we <= 1'b0;
			exe_priv_level_o <= 2'b0;
		end else if (stall_i) begin
		end else if (flush_i) begin
			inst_o <= `NOP;
			inst_type_o <= `TYPE_I;
		end else begin
            inst_o <= inst_i;
			inst_type_o <= inst_type_i;
			alu_funct_o <= alu_funct_i;
			alu_src_o <= alu_src_i;
			alu_opcode_o <= alu_opcode_i;
			csr_addr_o <= csr_addr_i;
			csr_funct3_o <= csr_funct3_i;
			imm_o <= imm_i;
			rdata1_o <= rdata1_i;
			rdata2_o <= rdata2_i;
			PC_o <= PC_i;

			exe_mtvec_we <= id_mtvec_we;
			exe_mtvec_o <= id_mtvec_i;
			exe_mscratch_we <= id_mscratch_we;
			exe_mscratch_o <= id_mscratch_i;
			exe_mepc_we <= id_mepc_we;
			exe_mepc_o <= id_mepc_i;
			exe_mcause_we <= id_mcause_we;
			exe_mcause_o <= id_mcause_i;
			exe_mstatus_we <= id_mstatus_we;
			exe_mstatus_o <= id_mstatus_i;
			exe_mie_we <= id_mie_we;
			exe_mie_o <= id_mie_i;
			exe_mip_we <= id_mip_we;
			exe_mip_o <= id_mip_i;
			exe_priv_level_we <= id_priv_level_we;
			exe_priv_level_o <= id_priv_level_i;
		end
	end

endmodule
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
	input wire [`WIDTH_ALU_FUNCT] alu_funct_i,
	input wire alu_src_i,
	input wire [31:0] imm_i,
	input wire [31:0] rdata1_i,
	input wire [31:0] rdata2_i,
	output reg [31:0] inst_o,
	output reg [`WIDTH_INST_TYPE] inst_type_o,
	output reg [31:0] branch_addr_o,
	output reg [`WIDTH_ALU_FUNCT] alu_funct_o,
	output reg alu_src_o,
	output reg [31:0] imm_o,
	output reg [31:0] rdata1_o,
	output reg [31:0] rdata2_o,
	output reg [31:0] PC_o
);

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            inst_o <= `NOP;
			inst_type_o <= `TYPE_I;
			branch_addr_o <= 32'd0;
			alu_funct_o <= `FUNCT3_ADD;
			alu_src_o <= `EN_Imm;
			imm_o <= '0;
			rdata1_o <= '0;
			rdata2_o <= '0;
		end else if (stall_i) begin
		end else if (flush_i) begin
			inst_o <= `NOP;
			inst_type_o <= `TYPE_I;
		end else begin
            inst_o <= inst_i;
			inst_type_o <= inst_type_i;
			branch_addr_o <= PC_i + imm_i;
			alu_funct_o <= alu_funct_i;
			alu_src_o <= alu_src_i;
			imm_o <= imm_i;
			rdata1_o <= rdata1_i;
			rdata2_o <= rdata2_i;
			PC_o <= PC_i;
		end
	end

endmodule
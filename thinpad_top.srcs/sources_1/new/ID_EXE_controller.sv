`default_nettype none

module ID_EXE_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] PC_i,
	input wire [31:0] inst_i,
	input wire [2:0] inst_type_i,
	input wire [3:0] alu_funct_i,
	input wire alu_src_i,
	input wire [31:0] imm_i,
	input wire [31:0] rdata1_i,
	input wire [31:0] rdata2_i,
	output reg [31:0] inst_o,
	output reg [2:0] inst_type_o,
	output reg [31:0] branch_addr_o,
	output reg [3:0] alu_funct_o,
	output reg alu_src_o,
	output reg [31:0] imm_o,
	output reg [31:0] rdata1_o,
	output reg [31:0] rdata2_o,
	output reg [31:0] PC_o
);

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            inst_o <= 32'h0000_0013;
			inst_type_o <= 3'd1;
			branch_addr_o <= 32'd0;
			alu_funct_o <= '0;
			alu_src_o <= '0;
			imm_o <= '0;
			rdata1_o <= '0;
			rdata2_o <= '0;
		end else if (stall_i) begin
		end else if (flush_i) begin
			inst_o <= 32'h0000_0013;
			inst_type_o <= 3'd1;
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
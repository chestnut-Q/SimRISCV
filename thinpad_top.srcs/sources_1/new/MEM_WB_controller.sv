`default_nettype none
`include "defines.vh"

module MEM_WB_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] inst_i,
	input wire [2:0] inst_type_i,
    input wire [31:0] alu_result_i,
	input wire [31:0] csr_result_i,
    input wire [31:0] mem_read_data_i, // 读内存的数据
	output wire [31:0] logic_rf_wdata_o,
    output reg rf_wen_o,
    output reg [31:0] rf_wdata_o,
    output reg [4:0] rf_waddr_o
);

	logic [6:0] opcode;
	logic [2:0] funct3;
	logic [4:0] rd;
	logic rf_wen;
	logic mem_to_reg;
	logic [31:0] rf_wdata;

	assign opcode = inst_i[6:0];
	assign funct3 = inst_i[14:12];
	assign rd = inst_i[11:7];
	assign rf_wen = (inst_type_i == `TYPE_R || inst_type_i == `TYPE_I || inst_type_i == `TYPE_U || inst_type_i == `TYPE_J);
	assign mem_to_reg = (opcode == `OP_LTYPE);
	assign rf_wdata = mem_to_reg ? (funct3 == `FUNCT3_BYTE ? {24'b0, mem_read_data_i[7:0]} : mem_read_data_i) : alu_result_i;
	assign logic_rf_wdata_o = rf_wdata;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            rf_wen_o <= '0;
			rf_wdata_o <= 32'd0;
			rf_waddr_o <= '0;
		end else if (stall_i) begin
		end else if (flush_i) begin
			rf_wen_o <= '0;
		end else begin
			case (opcode)
				`OP_CSR: begin
					case (funct3)
						`FUNCT3_CSRRC, `FUNCT3_CSRRW, `FUNCT3_CSRRS: begin
							rf_wen_o <= 1'b1;
							rf_wdata_o <= csr_result_i;
							rf_waddr_o <= rd;
						end
						default: begin
							rf_wen_o <= 1'b0;
							rf_wdata_o <= 32'b0;
							rf_waddr_o <= 5'b0;
						end
					endcase
				end
				default: begin
					rf_wen_o <= rf_wen;
					rf_wdata_o <= rf_wdata;
					rf_waddr_o <= rd;
				end
			endcase
		end
	end

endmodule
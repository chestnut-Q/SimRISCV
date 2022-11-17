`default_nettype none

module MEM_WB_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] inst_i,
	input wire [2:0] inst_type_i,
    input wire [31:0] alu_result_i,
    input wire [31:0] mem_read_data_i, // 读内存的数据
    output reg rf_wen_o,
    output reg [31:0] rf_wdata_o,
    output reg [4:0] rf_waddr_o
);

	typedef enum logic [2:0] {
		R_TYPE = 0,
		I_TYPE = 1,
		B_TYPE = 2,
		U_TYPE = 3,
		S_TYPE = 4,
		J_TYPE = 5
	} inst_type_t;

	logic [6:0] opcode;
	logic [2:0] funct3;
	logic [4:0] rd;
	logic rf_wen;
	logic mem_to_reg;
	logic [31:0] rf_wdata;

	assign opcode = inst_i[6:0];
	assign funct3 = inst_i[14:12];
	assign rd = inst_i[11:7];
	assign rf_wen = (inst_type_i == R_TYPE || inst_type_i == I_TYPE || inst_type_i == U_TYPE);
	assign mem_to_reg = (opcode == 7'b0000011);
	assign rf_wdata = mem_to_reg ? (funct3 == 3'b000 ? {24'b0, mem_read_data_i[7:0]} : mem_read_data_i) : alu_result_i;
	
	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            rf_wen_o <= '0;
			rf_wdata_o <= 32'd0;
			rf_waddr_o <= '0;
		end else if (stall_i) begin
		end else if (flush_i) begin
			rf_wen_o <= '0;
		end else begin
            rf_wen_o <= rf_wen;
			rf_wdata_o <= rf_wdata;
			rf_waddr_o <= rd;
		end
	end

endmodule
`default_nettype none

module EXE_MEM_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] inst_i,
	input wire [2:0] inst_type_i,
	input wire [31:0] alu_result_i,
	input wire [31:0] rdata2_i,
	output reg [31:0] inst_o,
	output reg [2:0] inst_type_o,
	output reg [31:0] alu_result_o,
	output reg mem_ren_o,
	output reg mem_wen_o,
	output reg [31:0] mem_addr_o, 
	output reg [31:0] mem_wdata_o,
	output reg sel_byte_o
);

	typedef enum logic [2:0] {
		R_TYPE = 0,
		I_TYPE = 1,
		B_TYPE = 2,
		U_TYPE = 3,
		S_TYPE = 4,
		J_TYPE = 5
	} inst_type_t;

	logic PC_src;
	logic [6:0] opcode;
	logic [4:0] rs2;
	logic [4:0] rd;
	logic mem_ren;
	logic mem_wen;
	logic [31:0] mem_wdata;

	assign opcode = inst_i[6:0];
	assign rs2 = inst_i[24:20];
	assign rd = inst_i[11:7];
	assign mem_wen = (opcode === 7'b0100011);
	assign mem_ren = (opcode === 7'b0000011 && rd != 5'b00000);
	assign mem_wdata = inst_i[14:12] === 3'b010 ? rdata2_i : {24'b0, rdata2_i[7:0]};

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            inst_o <= 32'h0000_0013;
			inst_type_o <= 3'd1;
			alu_result_o <= 32'd0;
			mem_ren_o <= '0;
			mem_wen_o <= '0;
			mem_addr_o <= 32'd0;
			mem_wdata_o <= 32'd0;
			sel_byte_o <= 1'b0;
		end else if (stall_i) begin
		end else if (flush_i) begin
			inst_o <= 32'h0000_0013;
			inst_type_o <= 3'd1;
			mem_ren_o <= '0;
			mem_wen_o <= '0;
		end else begin
            inst_o <= inst_i;
			inst_type_o <= inst_type_i;
			alu_result_o <= alu_result_i;
			mem_ren_o <= mem_ren;
			mem_wen_o <= mem_wen;
			mem_addr_o <= alu_result_i;
			mem_wdata_o <= mem_wdata;
			sel_byte_o <= (inst_i[14:12] === 3'b000);
		end
	end

endmodule
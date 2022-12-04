`default_nettype none
`include "defines.vh"

module IF_ID_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] PC_i,
    input wire [31:0] inst_i,
	output wire bht_branch_flag_o,
	output wire [31:0] bht_branch_addr_o,
    output reg [31:0] PC_o,
    output reg [31:0] inst_o
);

	reg bht_branch_flag_reg;
	reg [31:0] bht_branch_addr_reg;

	assign bht_branch_flag_o = (inst_i[6:0] == `OP_BTYPE);
	assign bht_branch_addr_o = (inst_i[6:0] == `OP_BTYPE) ? (PC_i + {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0}) : 32'b0;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            PC_o <= 32'd0;
            inst_o <= `NOP;
			bht_branch_flag_reg <= 1'b0;
			bht_branch_addr_reg <= 32'b0;
		end else if (stall_i) begin
			PC_o <= PC_o;
			inst_o <= inst_o;
		end else if (flush_i) begin
			inst_o <= `NOP;
		end else begin
            PC_o <= PC_i;
            inst_o <= inst_i;
		end
	end

endmodule
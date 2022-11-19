`default_nettype none

module IF_ID_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] PC_i,
    input wire [31:0] inst_i,
	
	input wire [2:0] bht_inst_type_i, 
	input wire [31:0] bht_imm,

    output reg [31:0] PC_o,
    output reg [31:0] inst_o,
	output reg [31:0] bht_addr_o
);

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            PC_o <= 32'd0;
            inst_o <= 32'h0000_0013;
		end else if (stall_i) begin
			PC_o <= PC_o;
			inst_o <= inst_o;
		end else if (flush_i) begin
			inst_o <= 32'h0000_0013;
		end else begin
            PC_o <= PC_i;
            inst_o <= inst_i;
			if (bht_inst_type_i == 3'b010) begin
				bht_addr_o = PC_i + bht_imm;
			end else begin
				bht_addr_o = PC_i + 4;
			end
		end
	end

endmodule
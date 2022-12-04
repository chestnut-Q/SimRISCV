`default_nettype none

module PC_mux(
    input wire clk_i,
    input wire rst_i,
    input wire [31:0] rst_addr_i,
    input wire stall_i,
    input wire branch_i,
    input wire [31:0] branch_addr_i,
    input wire jump_i, // whether to jump

    input wire [6:0] if_inst_type_i, // if_inst_type
    input wire [6:0] id_inst_type_i, // id_inst_type
    input wire [1:0] bht_state_i,
    input wire bht_actual_i,
    input wire bht_branch_flag_i,
    input wire [31:0] bht_branch_addr_i,
    input wire csr_branch_flag_i,
    input wire [31:0] csr_branch_addr_i,

    output reg bht_past_o,
    output reg [31:0] PC_o
);

    reg [31:0] PC_past_reg;
    reg bht_past_reg;
    assign bht_past_o = bht_past_reg;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            PC_o <= rst_addr_i;
            PC_past_reg <= rst_addr_i;
            bht_past_reg <= 1'b0;
		end else if (stall_i) begin
            PC_o <= PC_o;
        end else begin
            if (csr_branch_flag_i) begin
                PC_o <= csr_branch_addr_i;
            end else begin
                if ((bht_past_reg == 1'b1 && id_inst_type_i == `OP_BTYPE && !bht_actual_i) ||
                (bht_past_reg == 1'b0 && id_inst_type_i == `OP_BTYPE && bht_actual_i)) begin
                    if (bht_past_reg == 1'b1 && id_inst_type_i == `OP_BTYPE && !bht_actual_i) begin
                        PC_o <= PC_past_reg + 4; // 预测跳转但是实际没跳转，回到原来PC + 4
                    end else begin
                        PC_o <= branch_addr_i; // 预测没跳转但是实际跳转，回到跳转地址
                    end
                end else begin
                    if (jump_i || branch_i) begin
                        PC_o <= branch_addr_i;
                    end else begin
                        if (bht_branch_flag_i) begin
                            if (bht_state_i == 2'b10 || bht_state_i == 2'b11) begin
                                PC_o <= bht_branch_addr_i;
                                PC_past_reg <= PC_o;
                                bht_past_reg <= 1'b1; // 预测跳转
                            end else begin
                                PC_o <= PC_o + 4;
                                bht_past_reg <= 1'b0; // 预测不跳转
                            end
                        end else begin
                            PC_o <= PC_o + 4;
                        end
                    end
                end
            end
        end
	end

endmodule
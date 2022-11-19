`default_nettype none

module PC_mux(
    input wire clk_i,
    input wire rst_i,
    input wire [31:0] rst_addr_i,
    input wire stall_i,
    input wire PC_src_i,
    input wire [2:0] PC_src_type_i,
    input wire PC_src_zero_i,
    input wire [2:0] bht_pre_type_i,
    input wire [31:0] branch_addr_i,
    input wire [1:0] bht_state_i,
    input wire [31:0] bht_addr_i,
    output reg [31:0] PC_o,
    output reg bht_past_o
);

reg [31:0] PC_past_reg;
reg bht_past_reg;
assign bht_past_o = bht_past_reg;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            PC_o <= rst_addr_i;
		end else if (stall_i) begin
            PC_o <= PC_o;
        end else begin
            if ((bht_past_reg == 1'b1 && PC_src_type_i == 3'b010 && !PC_src_zero_i) ||  
            (bht_past_reg == 1'b0 && PC_src_type_i == 3'b010 && PC_src_zero_i)) begin
                if (bht_past_reg == 1'b1 && PC_src_type_i == 3'b010 && !PC_src_zero_i) begin
                    PC_o <= PC_past_reg + 4;
                end else begin
                    PC_o <= branch_addr_i;
                end
            end else begin 
                if (bht_pre_type_i == 3'b010) begin
                    if (bht_state_i == 2'b10 || bht_state_i == 2'b11) begin
                        PC_o <= bht_addr_i;
                        PC_past_reg <= PC_o;
                        bht_past_reg <= 1'b1;
                    end else begin
                        PC_o <= PC_o + 4;
                        bht_past_reg <= 1'b0;
                    end
                end else begin
                    PC_o <= PC_o + 4;
                end
            end
		end
	end

endmodule
`default_nettype none

module PC_mux(
    input wire clk_i,
    input wire rst_i,
    input wire [31:0] rst_addr_i,
    input wire stall_i,
    input wire PC_src_i,  // PC 跳转选项，+4（0）或者跳转（1）
    input wire [31:0] branch_addr_i,
    output reg [31:0] PC_o
);

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            PC_o <= rst_addr_i;
		end else if (stall_i) begin
            PC_o <= PC_o;
        end else begin
            if (PC_src_i) begin
                PC_o <= branch_addr_i;
            end else begin
                PC_o <= PC_o + 4;
            end
		end
	end

endmodule
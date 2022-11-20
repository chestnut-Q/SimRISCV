`default_nettype none
`include "defines.vh"

module IF_ID_controller (
    input wire clk_i,
    input wire rst_i,

	input wire stall_i,
	input wire flush_i,
    input wire [31:0] PC_i,
    input wire [31:0] inst_i,
    output reg [31:0] PC_o,
    output reg [31:0] inst_o
);

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            PC_o <= 32'd0;
            inst_o <= `NOP;
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
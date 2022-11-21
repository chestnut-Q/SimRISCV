`default_nettype none
`include "defines.vh"

module IF_master #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire stall,
    input wire [ADDR_WIDTH-1:0] addr_i,
    output reg [DATA_WIDTH-1:0] rdata_o,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o,
    output reg already_o
);

	typedef enum logic [3:0] {
		IDLE = 0,
        READ_SRAM_ACTION = 1,
        DONE = 2
	} state_t;

    state_t state, state_n;
    logic [31:0] rdata_reg;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
			state <= IDLE;
            rdata_reg <= 32'd0;
		end else begin
			state <= state_n;
            if (state == READ_SRAM_ACTION && wb_ack_i) begin
                rdata_reg <= wb_dat_i;
            end
		end
	end

	always_comb begin
		case (state)
			IDLE: begin
                state_n = READ_SRAM_ACTION;
			end
            READ_SRAM_ACTION: begin
                if (wb_ack_i) begin
                    state_n = DONE;
                end else begin
                    state_n = READ_SRAM_ACTION;
                end
            end
            DONE: begin
                if (!stall) begin
                    state_n = IDLE;
                end else begin
                    state_n = DONE;
                end
            end
            default: state_n = IDLE;
		endcase
	end

    assign rdata_o = rdata_reg;
    assign wb_cyc_o = wb_stb_o;
    assign wb_stb_o = (state == READ_SRAM_ACTION);
    assign wb_adr_o = addr_i;
    assign wb_dat_o = '0;
    assign wb_sel_o = 4'b1111;
    assign wb_we_o = 1'b0;
    assign already_o = (state == DONE);

endmodule
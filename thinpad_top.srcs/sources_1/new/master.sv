module master #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    input wire stall,
    input wire [ADDR_WIDTH-1:0] addr_i,
    input wire [DATA_WIDTH-1:0] wdata_i,
    input wire wen_i,
    input wire ren_i,
    input wire sel_byte_i, // ×Ö½Ú£¨1£©»òÕß×Ö£¨0£©
    input wire init,
    output reg [DATA_WIDTH-1:0] rdata_o,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o,
    output reg [3:0] state_o
);

	typedef enum logic [3:0] {
		IDLE = 0,
        READ_SRAM_ACTION = 1,
        READ_SRAM_DONE = 2,
		WRITE_SRAM_ACTION = 3,
        WRITE_SRAM_DONE = 4,
        ALREADY = 5
	} state_t;

    state_t state, state_n;
    logic [31:0] rdata_reg;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
			state <= IDLE;
            rdata_reg <= 32'd0;
		end else begin
			state <= state_n;
            if (state == READ_SRAM_DONE) begin
                case (wb_sel_o)
                    4'b0001: rdata_reg <= {24'd0, wb_dat_i[7:0]};
                    4'b0010: rdata_reg <= {24'd0, wb_dat_i[15:8]};
                    4'b0100: rdata_reg <= {24'd0, wb_dat_i[23:16]};
                    4'b1000: rdata_reg <= {24'd0, wb_dat_i[31:24]};
                    default: rdata_reg <= wb_dat_i;
                endcase
            end
		end
	end

	always_comb begin
		case (state)
            // INIT: begin
            //     if (ren_i) begin
            //         state_n = READ_SRAM_ACTION;
            //     end else if (wen_i) begin
            //         state_n = WRITE_SRAM_ACTION;
            //     end else begin
            //         if (init) begin
            //             state_n = INIT;
            //         end else begin
            //             state_n = IDLE;
            //         end
            //     end
			// end
			IDLE: begin
                if (ren_i) begin
                    state_n = READ_SRAM_ACTION;
                end else if (wen_i) begin
                    state_n = WRITE_SRAM_ACTION;
                end else begin
                    state_n = IDLE;
                end
			end
            READ_SRAM_ACTION: begin
                if (wb_ack_i) begin
                    state_n = READ_SRAM_DONE;
                end else begin
                    state_n = READ_SRAM_ACTION;
                end
            end
            READ_SRAM_DONE: state_n = ALREADY;
            WRITE_SRAM_ACTION: begin
                if (wb_ack_i) begin
                    state_n = WRITE_SRAM_DONE;
                end else begin
                    state_n = WRITE_SRAM_ACTION;
                end
            end
            WRITE_SRAM_DONE: state_n = ALREADY;
            ALREADY: begin
                if (!stall) begin
                    state_n = IDLE;
                end else begin
                    state_n = ALREADY;
                end
            end
            default: state_n = IDLE;
		endcase
	end

    assign rdata_o = rdata_reg;
    assign wb_cyc_o = wb_stb_o;
    assign wb_stb_o = (state == READ_SRAM_ACTION || state == WRITE_SRAM_ACTION);
    assign wb_adr_o = addr_i;
    assign wb_dat_o = wdata_i;
    assign wb_sel_o = sel_byte_i ? (4'b0001 << addr_i[1:0]) : 4'b1111;
    assign wb_we_o = (state == WRITE_SRAM_ACTION);
    assign state_o = state;

endmodule
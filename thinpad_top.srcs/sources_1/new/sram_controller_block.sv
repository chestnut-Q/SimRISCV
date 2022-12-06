module sram_controller_block #(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32,

	parameter SRAM_ADDR_WIDTH = 20,
	parameter SRAM_DATA_WIDTH = 32,

	localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
	localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
	// clk and reset
	input wire clk_i,
	input wire rst_i,

	// wishbone slave interface
	input wire wb_cyc_i,
	input wire wb_stb_i,
	output reg wb_ack_o,
	input wire [ADDR_WIDTH-1:0] wb_adr_i,
	input wire [DATA_WIDTH-1:0] wb_dat_i,
	output reg [DATA_WIDTH-1:0] wb_dat_o,
	input wire [DATA_WIDTH/8-1:0] wb_sel_i,
	input wire wb_we_i,

	// sram interface
	output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
	inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
	// input wire [SRAM_DATA_WIDTH-1:0] sram_data,
	output reg sram_ce_n,
	output reg sram_oe_n,
	output reg sram_we_n
);

	// 实现 SRAM 控制器
	typedef enum logic [1:0] {
		STATE_IDLE = 0,
		STATE_READ = 1,
		STATE_WRITE = 2,
		STATE_WRITE_2 = 3
	} state_t;

	state_t state, state_n;

	always_comb begin
		state_n = state;
		case (state)
			STATE_IDLE: begin
				if (wb_stb_i && wb_cyc_i) begin
					if (wb_we_i) begin
						state_n = STATE_WRITE;
					end else begin
						state_n = STATE_READ;
					end
				end
			end
			STATE_READ: state_n = STATE_IDLE;
			STATE_WRITE: state_n = STATE_WRITE_2;
			STATE_WRITE_2: state_n = STATE_IDLE;
			default: state_n = STATE_IDLE;
		endcase
	end

	// sram_data 三态门
    wire [SRAM_DATA_WIDTH-1:0] sram_data_i_comb;
    reg [SRAM_DATA_WIDTH-1:0] sram_data_o_comb;
    reg sram_data_t_comb;
    assign sram_data = sram_data_t_comb ? {SRAM_DATA_WIDTH{1'bz}} : sram_data_o_comb;
	genvar i;
	for (i = 0; i < SRAM_DATA_WIDTH / 8; i = i + 1) begin
		assign sram_data_i_comb[i*8+:8] = wb_sel_i[i] ? sram_data[i*8+:8] : 8'h00;
	end

	always_ff @ (posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
			state <= STATE_IDLE;
			wb_dat_o = '0;
		end else begin
			state <= state_n;
			if (wb_stb_i && !wb_we_i) begin // 发起请求且不是写 等于 发起读请求
				wb_dat_o <= sram_data_i_comb;
			end
		end
	end

	always_comb begin
		wb_ack_o = (state == STATE_READ || state == STATE_WRITE_2);
		sram_addr = wb_adr_i[18:0];
		sram_data_o_comb = {SRAM_DATA_WIDTH{1'b0}};
		sram_ce_n = ~wb_stb_i;
		sram_oe_n = 1'b1;
		sram_we_n = 1'b1;
		if (wb_we_i) begin
			// 写操作
			sram_data_t_comb = 1'b0;
			sram_data_o_comb = wb_dat_i;
			if (state == STATE_WRITE) begin
				sram_we_n = 1'b0;
			end
		end else begin
			// 读操作
			sram_data_t_comb = 1'b1;
			if (wb_stb_i) begin
				sram_oe_n = 1'b0;
			end
		end
	end

endmodule

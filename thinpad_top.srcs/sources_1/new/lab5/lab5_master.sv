module lab5_master #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // �����Ҫ�Ŀ����źţ����簴�����أ�
    // control signals
    input wire [ADDR_WIDTH-1:0] starting_addr,

    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

	// ʵ��ʵ�� 5 ���ڴ�+���� Master
	typedef enum logic [3:0] {
		IDLE = 0, // ��ʼ״̬
		READ_WAIT_ACTION = 1, // ���ڶ�ȡ״̬�Ĵ���
		READ_WAIT_CHECK = 2, // ��ȡ��״̬�Ĵ�����ǰ��ȡֵ���ж��Ƿ���Զ�ȡ�µ�ֵ
		READ_DATA_ACTION = 3, // ���ڶ�ȡ���ݼĴ���
		READ_DATA_DONE = 4, // ��ɶ�ȡ���ݼĴ�������������Ĳ���
		WRITE_SRAM_ACTION = 5, // ����д�� SRAM
		WRITE_SRAM_DONE = 6, // д�� SRAM ��ɣ���������Ĳ���
		WRITE_WAIT_ACTION = 7, // ���ڶ�ȡ״̬�Ĵ���
		WRITE_WAIT_CHECK = 8, // ��ȡ��״̬�Ĵ�����ǰ��ȡֵ���ж��Ƿ����д���µ�ֵ
		WRITE_DATA_ACTION = 9, // ����д�����ݼĴ���
		WRITE_DATA_DONE = 10 // ���д�����ݼĴ�������������Ĳ���
	} state_t;

	state_t state, state_n;
	logic [ADDR_WIDTH-1:0] addr;
	logic read_ack;
	logic write_ack;
	logic [DATA_WIDTH-1:0] dat_i_saved;
	logic [DATA_WIDTH/4-1:0] recv_byte;

	localparam ADD_ZERO = DATA_WIDTH - DATA_WIDTH/4;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
			state <= IDLE;
			addr <= starting_addr;
			dat_i_saved <= '0;
			recv_byte <= '0;
		end else begin
			state <= state_n;
			if (state == WRITE_SRAM_DONE) begin
				addr <= addr + 4;
			end
			if (wb_ack_i) begin
				dat_i_saved <= wb_dat_i;
			end
			if (state == READ_DATA_DONE) begin
				recv_byte <= dat_i_saved[DATA_WIDTH/4-1:0];
			end
		end
	end

	always_comb begin
		case (state)
			IDLE: begin
				state_n = READ_WAIT_ACTION;
			end
			READ_WAIT_ACTION: begin
				if (wb_ack_i) begin
					state_n = READ_WAIT_CHECK;
				end else begin
					state_n = READ_WAIT_ACTION;
				end
			end
			READ_WAIT_CHECK: begin
				if (read_ack) begin
					state_n = READ_DATA_ACTION;
				end else begin
					state_n = READ_WAIT_ACTION;
				end
			end
			READ_DATA_ACTION: begin
				if (wb_ack_i) begin
					state_n = READ_DATA_DONE;
				end else begin
					state_n = READ_DATA_ACTION;
				end
			end
			READ_DATA_DONE: begin
				state_n = WRITE_SRAM_ACTION;
			end
			WRITE_SRAM_ACTION: begin
				if (wb_ack_i) begin
					state_n = WRITE_SRAM_DONE;
				end else begin
					state_n = WRITE_SRAM_ACTION;
				end
			end
			WRITE_SRAM_DONE: begin
				state_n = WRITE_WAIT_ACTION;
			end
			WRITE_WAIT_ACTION: begin
				if (wb_ack_i) begin
					state_n = WRITE_WAIT_CHECK;
				end else begin
					state_n = WRITE_WAIT_ACTION;
				end
			end
			WRITE_WAIT_CHECK: begin
				if (write_ack) begin
					state_n = WRITE_DATA_ACTION;
				end else begin
					state_n = WRITE_WAIT_ACTION;
				end
			end
			WRITE_DATA_ACTION: begin
				if (wb_ack_i) begin
					state_n = WRITE_DATA_DONE;
				end else begin
					state_n = WRITE_DATA_ACTION;
				end
			end
			WRITE_DATA_DONE: begin
				state_n = IDLE;
			end
			default: begin
				state_n = IDLE;
			end
		endcase
	end

	assign read_ack = dat_i_saved[8];
	assign write_ack = dat_i_saved[13];
	assign wb_cyc_o = wb_stb_o;
	assign wb_stb_o = (state == READ_WAIT_ACTION || state == READ_DATA_ACTION || state == WRITE_SRAM_ACTION
		|| state == WRITE_WAIT_ACTION || state == WRITE_DATA_ACTION);
	assign wb_we_o = (state == WRITE_SRAM_ACTION || state == WRITE_DATA_ACTION);
	
	always_comb begin
		wb_adr_o = '0;
		wb_dat_o = '0;
		wb_sel_o = '0;
		case (state)
			READ_WAIT_ACTION: begin
				wb_adr_o = 32'h10000005;
				wb_sel_o = 4'b0010;
			end
			READ_DATA_ACTION: begin
				wb_adr_o = 32'h10000000;
				wb_sel_o = 4'b0001;
			end
			WRITE_SRAM_ACTION: begin
				wb_adr_o = addr;
				wb_dat_o = {{ADD_ZERO{1'b0}}, recv_byte};
				wb_sel_o = 4'b0001;
			end
			WRITE_WAIT_ACTION: begin
				wb_adr_o = 32'h10000005;
				wb_sel_o = 4'b0010;
			end
			WRITE_DATA_ACTION: begin
				wb_adr_o = 32'h10000000;
				wb_dat_o = {{ADD_ZERO{1'b0}}, recv_byte};
				wb_sel_o = 4'b0001;
			end
			default: ;
		endcase
	end

endmodule
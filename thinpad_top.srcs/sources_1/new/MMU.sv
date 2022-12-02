`default_nettype none

module MMU(
    input wire clk_i,
    input wire rst_i,
    
    input wire [31:0] virtual_addr_i,
    input wire [31:0] satp_i,
    input wire [1:0] priv_level_i,
    input wire [31:0] mem_req_data_i,
    input wire use_mmu_i,
    input wire mem_ack_i,
    output wire [31:0] physical_addr_o,
    output reg mmu_working_o,
    output wire already_o
);

	typedef enum logic [1:0] {
		IDLE = 0,
        LEVEL1 = 1,
		LEVEL2 = 2,
		PHYSICAL = 3
	} state_t;

    state_t state, state_n;
    logic translation;
    logic [31:0] physical_addr_reg;
    logic use_mmu;

    assign translation = (priv_level_i == 2'b00) && (satp_i[31] == 1'b1);
    assign use_mmu = use_mmu_i & translation;
    assign already_o = ((!use_mmu && mem_ack_i) || (use_mmu && state == PHYSICAL && mem_ack_i));
    assign physical_addr_o = use_mmu ? physical_addr_reg : virtual_addr_i;
    assign mmu_working_o = (use_mmu && state != PHYSICAL);

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            state <= IDLE;
            physical_addr_reg <= '0;
        end else begin
            state <= state_n;
            if (state == IDLE && state_n == LEVEL1) begin
                physical_addr_reg <= {satp_i[19:0], virtual_addr_i[31:22], 2'b00};
            end else if (state == LEVEL1 && state_n == LEVEL2) begin
                physical_addr_reg <= {mem_req_data_i[29:10], virtual_addr_i[21:12], 2'b00};
            end else if (state == LEVEL2 && state_n == PHYSICAL) begin
                physical_addr_reg <= {mem_req_data_i[29:10], virtual_addr_i[11:0]};
            end
        end
    end

    always_comb begin
        case(state)
            IDLE: begin
                if (use_mmu && translation)
                    state_n = LEVEL1;
                else
                    state_n = IDLE;
            end
            LEVEL1: begin
                if (mem_ack_i && mem_req_data_i[3:1] == 3'b000)
                    state_n = LEVEL2;
                else if (mem_ack_i && mem_req_data_i[3:1] != 3'b000)
                    state_n = PHYSICAL;
                else
                    state_n = LEVEL1;
            end
            LEVEL2: begin
                if (mem_ack_i)
                    state_n = PHYSICAL;
                else
                    state_n = LEVEL2;
            end
            PHYSICAL: begin
                if (mem_ack_i)
                    state_n = IDLE;
                else
                    state_n = PHYSICAL;
            end
            default: begin
            end
        endcase
    end

endmodule
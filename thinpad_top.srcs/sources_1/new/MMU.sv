`default_nettype none
`include "defines.vh"

module MMU(
    input wire clk_i,
    input wire rst_i,
    
    input wire [31:0] virtual_addr_i,
    input wire [31:0] satp_i,
    input wire [1:0] priv_level_i,
    input wire [31:0] mem_req_data_i,
    input wire ren_i,
    input wire wen_i,
    input wire use_mmu_i,
    input wire mem_ack_i,
    input wire tlb_flush_i,
    output wire [31:0] physical_addr_o,
    output reg mmu_working_o,
    output reg already_o,
    output reg [1:0] page_fault_o
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
    logic tlb_valid;
    logic [19:0] tlb_virtual;
    logic [19:0] tlb_physical;
    logic tlb_hit;

    localparam V=0, R=1, W=2, X=3;
    always_comb begin
        page_fault_o = 2'b00;

        if (ren_i) begin
            if (state == LEVEL1 && mem_ack_i) begin
                if (mem_req_data_i[V] == 1'b0) begin
                    page_fault_o = `PAGE_FAULT_REN;
                end else if (mem_req_data_i[3:1] != 3'b000) begin
                    if (mem_req_data_i[R] == 1'b0) begin
                        page_fault_o = `PAGE_FAULT_REN;
                    end
                end
            end
            if (state == LEVEL2 && mem_ack_i) begin
                if (mem_req_data_i[V] == 1'b0 || mem_req_data_i[3:1] == 3'b000) begin
                    page_fault_o = `PAGE_FAULT_REN;
                end else if (mem_req_data_i[R] == 1'b0) begin
                    page_fault_o = `PAGE_FAULT_REN;
                end
            end
        end else if (wen_i) begin
            if (state == LEVEL1 && mem_ack_i) begin
                if (mem_req_data_i[V] == 1'b0) begin
                    page_fault_o = `PAGE_FAULT_WEN;
                end else if (mem_req_data_i[3:1] != 3'b000) begin
                    if (mem_req_data_i[W] == 1'b0) begin
                        page_fault_o = `PAGE_FAULT_WEN;
                    end
                end
            end
            if (state == LEVEL2 && mem_ack_i) begin
                if (mem_req_data_i[V] == 1'b0 || mem_req_data_i[3:1] == 3'b000) begin
                    page_fault_o = `PAGE_FAULT_WEN;
                end else if (mem_req_data_i[W] == 1'b0) begin
                    page_fault_o = `PAGE_FAULT_WEN;
                end
            end
        end
    end

    always_comb begin
        already_o = 1'b0;
        if (page_fault_o != 2'b00)
            already_o = 1'b1;
        if (use_mmu && mem_ack_i && (tlb_hit || state == PHYSICAL))
            already_o = 1'b1;
        if (!use_mmu && mem_ack_i)
            already_o = 1'b1;
    end

    assign translation = (priv_level_i == 2'b00) && (satp_i[31] == 1'b1);
    assign use_mmu = use_mmu_i & translation;
    // assign tlb_hit = tlb_valid && tlb_virtual == virtual_addr_i[31:12];
    assign tlb_hit = 1'b0;
    assign physical_addr_o = use_mmu ? (tlb_hit ? {tlb_physical, virtual_addr_i[11:0]} : physical_addr_reg) : virtual_addr_i;
    assign mmu_working_o = (use_mmu && (state != PHYSICAL && !tlb_hit));

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
            state <= IDLE;
            physical_addr_reg <= '0;
            tlb_valid <= 1'b0;
            tlb_virtual <= '0;
            tlb_physical <= '0;
        end else begin
            state <= state_n;
            if (state == IDLE && state_n == LEVEL1) begin
                physical_addr_reg <= {satp_i[19:0], virtual_addr_i[31:22], 2'b00};
            end else if (state == LEVEL1 && state_n == LEVEL2) begin
                physical_addr_reg <= {mem_req_data_i[29:10], virtual_addr_i[21:12], 2'b00};
            end else if ((state == LEVEL1 || state == LEVEL2) && state_n == PHYSICAL) begin
                physical_addr_reg <= {mem_req_data_i[29:10], virtual_addr_i[11:0]};
            end else if (state == IDLE && tlb_hit) begin
                physical_addr_reg <= {tlb_physical, virtual_addr_i[11:0]};
            end

            if (tlb_flush_i) begin
                tlb_valid <= 1'b0;
            end else if ((state == LEVEL1 || state == LEVEL2) && state_n == PHYSICAL) begin
                tlb_valid <= 1'b1;
                tlb_virtual <= virtual_addr_i[31:12];
                tlb_physical <= mem_req_data_i[29:10];
            end
        end
    end

    always_comb begin
        case(state)
            IDLE: begin
                if (tlb_hit) // tlb hit
                    state_n = IDLE;
                else if (use_mmu && translation)
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
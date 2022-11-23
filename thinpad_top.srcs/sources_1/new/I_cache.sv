`default_nettype none
`include "defines.vh"

// 2 路组相联

module I_cache #(
    parameter CACHE_CAPACITY = 32,
    localparam CACHE_INDEX_WIDTH = $clog2(CACHE_CAPACITY)
) (
    input wire clk_i,
    input wire rst_i,
    //to mem
    output wire [31:0] mem_req_addr_o,
    output wire mem_req_valid_o,
    input wire [31:0] mem_req_data_i,
    input wire mem_req_ready_i,
    //to CPU
    input wire [31:0] cpu_req_addr_i,
    input wire cpu_req_valid_i,
    output wire [31:0] cpu_req_data_o,

    output wire already_o
);

	typedef enum logic [1:0] {
		IDLE = 0,
        Allocate = 1
	} state_t;

    localparam V=50, D=49, TagMSB=48, TagLSB=32 ,DataMSB=31, DataLSB=0;
    logic hit, way1hit, way2hit;
    logic [16:0] cpu_req_tag;
    logic mem_ready_valid;
    reg [50:0] cache_data [CACHE_CAPACITY-1:0]; // cache 寄存器
    logic [3:0] cpu_req_index;
    state_t state, state_n;

    assign cpu_req_index = cpu_req_addr_i[CACHE_INDEX_WIDTH+1:2];
    assign cpu_req_tag = cpu_req_addr_i[22:6];

    assign way1hit = cache_data[2*cpu_req_index][V] == 1'b1 && cache_data[2*cpu_req_index][TagMSB:TagLSB] == cpu_req_tag;
    assign way2hit = cache_data[2*cpu_req_index+1][V] == 1'b1 && cache_data[2*cpu_req_index+1][TagMSB:TagLSB] == cpu_req_tag;

    assign hit = way1hit | way2hit;

    assign mem_req_addr_o = cpu_req_addr_i;
    assign mem_req_valid_o = (state == Allocate);

    assign cpu_req_data_o = way1hit ? cache_data[2*cpu_req_index][DataMSB:DataLSB] :
                                       cache_data[2*cpu_req_index+1][DataMSB:DataLSB];

    assign already_o = (state == IDLE && hit);

    integer i;
    always_ff @ (posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (i = 0; i < CACHE_CAPACITY; i = i + 1) begin
                cache_data[i] <= '0;
            end
            state <= IDLE;
        end else begin
            state <= state_n;
            if (state == Allocate && mem_req_ready_i) begin
                cache_data[2*cpu_req_index][V] <= 1'b1;
                cache_data[2*cpu_req_index][DataMSB:DataLSB] <= mem_req_data_i;
                cache_data[2*cpu_req_index][TagMSB:TagLSB] <= cpu_req_tag;
                cache_data[2*cpu_req_index+1][V] <= cache_data[2*cpu_req_index][V];
                cache_data[2*cpu_req_index+1][DataMSB:DataLSB] <= cache_data[2*cpu_req_index][DataMSB:DataLSB];
                cache_data[2*cpu_req_index+1][TagMSB:TagLSB] <= cache_data[2*cpu_req_index][TagMSB:TagLSB];
            end
            if (cpu_req_data_o == `FENCEI && already_o) begin
                for (i = 0; i < CACHE_CAPACITY; i = i + 1) begin
                    cache_data[i][V] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        case(state)
            IDLE: begin
                if (cpu_req_valid_i) begin
                    if (hit) begin
                        state_n = IDLE;
                    end else begin
                        state_n = Allocate;
                    end
                end else begin
                    state_n = IDLE;
                end
            end
            Allocate: state_n = mem_req_ready_i ? IDLE : Allocate;
            default: state_n = IDLE;
        endcase
    end

endmodule
`default_nettype none
`include "defines.vh"

// 2 路组相联

module D_cache #(
    parameter CACHE_CAPACITY = 32, // 没有完全解耦，不能仅改动该参数
    localparam CACHE_INDEX_WIDTH = $clog2(CACHE_CAPACITY)
) (
    input wire clk_i,
    input wire rst_i,

    input wire write_through_all,
    input wire use_dcache,
    //to mem
    output reg [31:0] mem_req_addr_o,
    output reg mem_req_ren_o,
    output reg mem_req_wen_o,
    output reg [31:0] mem_req_wdata_o,
    input wire [31:0] mem_req_data_i,
    input wire mem_req_ready_i,
    output reg mem_sel_byte_o,
    //to CPU
    input wire [31:0] cpu_req_addr_i,
    input wire cpu_req_ren_i,
    input wire cpu_req_wen_i,
    input wire [31:0] cpu_req_wdata_i,
    input wire cpu_sel_byte_i,
    output reg [31:0] cpu_req_data_o,

    output wire already_o
);

	typedef enum logic [2:0] {
		IDLE = 0,
        Allocate = 1,
        WriteMem = 2,
        WriteMemAll = 3,
        NoCache = 4
	} state_t;

    localparam V=50, D=49, TagMSB=48, TagLSB=32 ,DataMSB=31, DataLSB=0;
    logic hit, way1hit, way2hit;
    logic write_dirty_cache;
    logic cacheable;
    logic [16:0] cpu_req_tag;
    logic mem_ready_valid;
    reg [50:0] cache_data [CACHE_CAPACITY-1:0]; // cache 寄存器
    logic [3:0] cpu_req_index;
    logic [4:0] write_all_counter;
    state_t state, state_n;

    assign cpu_req_index = cpu_req_addr_i[CACHE_INDEX_WIDTH+1:2];
    assign cpu_req_tag = cpu_req_addr_i[22:6];

    assign way1hit = cache_data[2*cpu_req_index][V] == 1'b1 && cache_data[2*cpu_req_index][TagMSB:TagLSB] == cpu_req_tag;
    assign way2hit = cache_data[2*cpu_req_index+1][V] == 1'b1 && cache_data[2*cpu_req_index+1][TagMSB:TagLSB] == cpu_req_tag;
    assign hit = way1hit | way2hit;

    assign write_dirty_cache = cache_data[2*cpu_req_index+1][D];
    assign cacheable = (cpu_req_addr_i[31:23] == 9'b1000_0000_0) && use_dcache;

    always_comb begin
        if (state == WriteMemAll) begin
            mem_req_addr_o = {9'b1000_0000_0, cache_data[write_all_counter][TagMSB:TagLSB], write_all_counter[4:1], 2'b00};
        end else if (cacheable) begin
            if (state == WriteMem)
                mem_req_addr_o = {9'b1000_0000_0, cache_data[2*cpu_req_index+1][TagMSB:TagLSB], cpu_req_index, 2'b00};
            else
                mem_req_addr_o = cpu_req_addr_i;
        end else begin
            mem_req_addr_o = cpu_req_addr_i;
        end

        if (state == WriteMemAll) begin
            mem_req_wdata_o = cache_data[write_all_counter][DataMSB:DataLSB];
        end else if (cacheable) begin
            mem_req_wdata_o = cache_data[2*cpu_req_index+1][DataMSB:DataLSB];
        end else begin
            mem_req_wdata_o = cpu_req_wdata_i;
        end

        if (state == WriteMemAll) begin
            mem_req_ren_o = 1'b0;
        end else begin
            mem_req_ren_o = (state == Allocate || (!cacheable && cpu_req_ren_i));
        end

        if (state == WriteMemAll) begin
            mem_req_wen_o = cache_data[write_all_counter][D];
        end else begin
            mem_req_wen_o = (state == WriteMem || (!cacheable && cpu_req_wen_i));
        end

        if (cacheable) begin
            cpu_req_data_o = (way1hit ? cache_data[2*cpu_req_index][DataMSB:DataLSB] : cache_data[2*cpu_req_index+1][DataMSB:DataLSB]);
            if (cpu_sel_byte_i) begin
                case (cpu_req_addr_i[1:0])
                    2'b00: cpu_req_data_o = {{24{cpu_req_data_o[7]}}, cpu_req_data_o[7:0]};
                    2'b01: cpu_req_data_o = {{24{cpu_req_data_o[15]}}, cpu_req_data_o[15:8]};
                    2'b10: cpu_req_data_o = {{24{cpu_req_data_o[23]}}, cpu_req_data_o[23:16]};
                    2'b11: cpu_req_data_o = {{24{cpu_req_data_o[31]}}, cpu_req_data_o[31:24]};
                    default: begin
                    end
                endcase
            end
        end else begin
            cpu_req_data_o = mem_req_data_i;
        end

        if (cacheable) begin
            mem_sel_byte_o = `EN_WORD;
        end else begin
            mem_sel_byte_o = cpu_sel_byte_i;
        end
    end

    assign already_o = (state_n == IDLE) && state != WriteMem && state != Allocate;

    integer i;
    always_ff @ (posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (i = 0; i < CACHE_CAPACITY; i = i + 1) begin
                cache_data[i] <= '0;
            end
            state <= IDLE;
            write_all_counter <= '0;
        end else begin
            state <= state_n;
            if (state == IDLE && write_through_all) begin
                write_all_counter <= CACHE_CAPACITY - 1;
            end else if (state == WriteMemAll) begin
                if (cache_data[write_all_counter][D] == 1'b0) begin
                    write_all_counter <= write_all_counter - 1;
                end else if (mem_req_ready_i) begin
                    cache_data[write_all_counter][D] <= 1'b0;
                    write_all_counter <= write_all_counter - 1;
                end
            end else begin
                if (hit && cacheable && cpu_req_wen_i) begin
                    if (way1hit) begin
                        if (cpu_sel_byte_i) begin
                            case (cpu_req_addr_i[1:0])
                                2'b00: cache_data[2*cpu_req_index][7:0] <= cpu_req_wdata_i[7:0];
                                2'b01: cache_data[2*cpu_req_index][15:8] <= cpu_req_wdata_i[7:0];
                                2'b10: cache_data[2*cpu_req_index][23:16] <= cpu_req_wdata_i[7:0];
                                2'b11: cache_data[2*cpu_req_index][31:24] <= cpu_req_wdata_i[7:0];
                                default: begin
                                end
                            endcase
                        end else begin
                            cache_data[2*cpu_req_index][DataMSB:DataLSB] <= cpu_req_wdata_i;
                        end
                        cache_data[2*cpu_req_index][D] <= 1'b1;
                    end else begin
                        if (cpu_sel_byte_i) begin
                            case (cpu_req_addr_i[1:0])
                                2'b00: cache_data[2*cpu_req_index+1][7:0] <= cpu_req_wdata_i[7:0];
                                2'b01: cache_data[2*cpu_req_index+1][15:8] <= cpu_req_wdata_i[7:0];
                                2'b10: cache_data[2*cpu_req_index+1][23:16] <= cpu_req_wdata_i[7:0];
                                2'b11: cache_data[2*cpu_req_index+1][31:24] <= cpu_req_wdata_i[7:0];
                                default: begin
                                end
                            endcase
                        end else begin
                            cache_data[2*cpu_req_index+1][DataMSB:DataLSB] <= cpu_req_wdata_i;
                        end
                        cache_data[2*cpu_req_index+1][D] <= 1'b1;
                    end
                end
                if (state == Allocate && mem_req_ready_i) begin
                    cache_data[2*cpu_req_index][V] <= 1'b1;
                    cache_data[2*cpu_req_index][D] <= 1'b0;
                    cache_data[2*cpu_req_index][DataMSB:DataLSB] <= mem_req_data_i;
                    cache_data[2*cpu_req_index][TagMSB:TagLSB] <= cpu_req_tag;
                    cache_data[2*cpu_req_index+1][V] <= cache_data[2*cpu_req_index][V];
                    cache_data[2*cpu_req_index+1][D] <= cache_data[2*cpu_req_index][D];
                    cache_data[2*cpu_req_index+1][DataMSB:DataLSB] <= cache_data[2*cpu_req_index][DataMSB:DataLSB];
                    cache_data[2*cpu_req_index+1][TagMSB:TagLSB] <= cache_data[2*cpu_req_index][TagMSB:TagLSB];
                end
                if (state == WriteMem && mem_req_ready_i) begin
                    cache_data[2*cpu_req_index+1][D] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        case(state)
            IDLE: begin
                if (write_through_all) begin
                    state_n = WriteMemAll;
                end else begin
                    if (cpu_req_ren_i) begin
                        if (!cacheable) begin
                            state_n = NoCache;
                        end else if (hit) begin
                            state_n = IDLE;
                        end else begin
                            state_n = Allocate;
                        end
                    end else if (cpu_req_wen_i) begin
                        if (!cacheable) begin
                            state_n = NoCache;
                        end else if (hit) begin
                            state_n = IDLE;
                        end else if (write_dirty_cache) begin
                            state_n = WriteMem;
                        end else begin
                            state_n = Allocate;
                        end
                    end else begin
                        state_n = IDLE;
                    end
                end
            end
            Allocate: begin
                if (mem_req_ready_i) begin
                    state_n = IDLE;
                end else begin
                    state_n = Allocate;
                end
            end
            WriteMem: state_n = mem_req_ready_i ? IDLE : WriteMem;
            WriteMemAll: state_n = (write_all_counter == 5'd0 && mem_req_ready_i) ? IDLE : WriteMemAll;
            NoCache: state_n = mem_req_ready_i ? IDLE : NoCache;
            default: state_n = IDLE;
        endcase
    end

endmodule
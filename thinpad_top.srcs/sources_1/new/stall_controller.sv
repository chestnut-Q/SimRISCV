`default_nettype none

module stall_controller (
    input wire [3:0] if_master_state_i,
    input wire [3:0] mem_master_state_i,
    input wire mem_master_wen,
    input wire mem_master_ren,
    input wire [31:0] id_inst_i,
    input wire [2:0] id_inst_type_i,
    input wire [31:0] exe_inst_i,
    input wire [2:0] exe_inst_type_i,
    input wire [31:0] mem_inst_i,
    input wire [2:0] mem_inst_type_i,
    input wire [4:0] wb_rd_i,
    input wire wb_rf_wen_i,
    input wire exe_alu_zero_i,
    input wire bht_past_i,
    output reg [4:0] stall_o,
    output reg [4:0] flush_o
);

	typedef enum logic [2:0] {
		R_TYPE = 0,
		I_TYPE = 1,
		B_TYPE = 2,
		U_TYPE = 3,
		S_TYPE = 4,
		J_TYPE = 5
	} inst_type_t;

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [4:0] exe_rd;
    logic exe_rf_wen;
    logic [4:0] mem_rd;
    logic mem_rf_wen;

    assign exe_rf_wen = (exe_inst_type_i == R_TYPE || exe_inst_type_i == I_TYPE || exe_inst_type_i == U_TYPE);
    assign mem_rf_wen = (mem_inst_type_i == R_TYPE || mem_inst_type_i == I_TYPE || mem_inst_type_i == U_TYPE);
    assign exe_rd = exe_inst_i[11:7];
    assign mem_rd = mem_inst_i[11:7];

    always_comb begin
        id_rs1 = 5'd0;
        id_rs2 = 5'd0;
        if (id_inst_type_i == R_TYPE || id_inst_type_i == S_TYPE || id_inst_type_i == B_TYPE) begin
            id_rs1 = id_inst_i[19:15];
            id_rs2 = id_inst_i[24:20];
        end else if (id_inst_type_i == I_TYPE) begin
            id_rs1 = id_inst_i[19:15];
        end
    end

	typedef enum logic [3:0] {
		IDLE = 0,
        READ_SRAM_ACTION = 1,
        READ_SRAM_DONE = 2,
		WRITE_SRAM_ACTION = 3,
        WRITE_SRAM_DONE = 4,
        ALREADY = 5
	} state_t;

    always_comb begin
        stall_o = 5'b00000;
        flush_o = 5'b00000;
        if (!(if_master_state_i == ALREADY &&
            (mem_master_state_i == ALREADY || (mem_master_state_i == IDLE && !mem_master_ren && !mem_master_wen)))) begin
            stall_o = 5'b11111;
        end else begin
            if ((wb_rf_wen_i && wb_rd_i != 5'd0 && (wb_rd_i == id_rs1 || wb_rd_i == id_rs2))
                || (mem_rf_wen && mem_rd != 5'd0 && (mem_rd == id_rs1 || mem_rd == id_rs2))
                || (exe_rf_wen && exe_rd != 5'd0 && (exe_rd == id_rs1 || exe_rd == id_rs2))) begin
                    stall_o[1:0] = 2'b11;
                    flush_o[2] = 1'b1;
                end else if ((bht_past_i == 1'b1 && exe_inst_type_i == B_TYPE && !exe_alu_zero_i) || (bht_past_i == 1'b0 && exe_inst_type_i == B_TYPE && exe_alu_zero_i)) begin
                    flush_o[2:1] = 2'b11;
                end
        end
    end

endmodule
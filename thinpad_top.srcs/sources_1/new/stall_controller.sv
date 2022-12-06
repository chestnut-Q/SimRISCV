`default_nettype none
`include "defines.vh"

module stall_controller (
    // input wire [3:0] if_master_state_i,
    // input wire [3:0] mem_master_state_i,
    input wire if_master_already_i,
    input wire mem_master_already_i,
    input wire [31:0] id_inst_i,
    input wire [`WIDTH_INST_TYPE] id_inst_type_i,
    input wire [31:0] exe_inst_i,
    input wire [`WIDTH_INST_TYPE] exe_inst_type_i,
    input wire [31:0] mem_inst_i,
    input wire [`WIDTH_INST_TYPE] mem_inst_type_i,
    input wire [4:0] wb_rd_i,
    input wire wb_rf_wen_i,
    input wire bht_past_i,
    input wire bht_actual_i,
    input wire branch_zero_i,
    input wire id_csr_branch_flag_i,
    output reg [4:0] stall_o,
    output reg [4:0] flush_o,
    output reg [1:0] rdata1_bypass_o, // ID 阶段 rdata1 bypass mux 0: rdata1; 1: exe_rd; 2: mem_rd
    output reg [1:0] rdata2_bypass_o, // ID 阶段 rdata2 bypass mux 0: rdata2; 1: exe_rd; 2: mem_rd
    input wire page_fault_i,
    input wire pred_valid_i,
    input wire pred_succ_i
);

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [11:0] id_csr;
    logic [4:0] exe_rd;
    logic [11:0] exe_csr;
    logic exe_rf_wen;
    logic [4:0] mem_rd;
    logic [11:0] mem_csr;
    logic mem_rf_wen;
    logic exe_is_load_inst;
    logic exe_is_csr_inst;

    assign exe_rf_wen = (exe_inst_type_i == `TYPE_R || exe_inst_type_i == `TYPE_I || exe_inst_type_i == `TYPE_U || exe_inst_type_i == `TYPE_J || exe_inst_i[6:0] == `OP_CSR);
    assign mem_rf_wen = (mem_inst_type_i == `TYPE_R || mem_inst_type_i == `TYPE_I || mem_inst_type_i == `TYPE_U || mem_inst_type_i == `TYPE_J);
    assign exe_rd = exe_inst_i[11:7];
    assign mem_rd = mem_inst_i[11:7];
    assign exe_csr = (exe_inst_i[6:0] == `OP_CSR) ? exe_inst_i[31:20] : 12'b0;
    assign mem_csr = (mem_inst_i[6:0] == `OP_CSR) ? mem_inst_i[31:20] : 12'b0;
    assign exe_is_load_inst = (exe_inst_i[6:0] == `OP_LTYPE);
    assign exe_is_csr_inst = (exe_inst_i[6:0] == `OP_CSR);

    always_comb begin
        id_rs1 = 5'd0;
        id_rs2 = 5'd0;
        if (id_inst_type_i == `TYPE_R || id_inst_type_i == `TYPE_S || id_inst_type_i == `TYPE_B) begin
            id_rs1 = id_inst_i[19:15];
            id_rs2 = id_inst_i[24:20];
        end else if (id_inst_type_i == `TYPE_I || id_inst_i[6:0] == `OP_JALR || id_inst_i[6:0] == `OP_CSR) begin
            id_rs1 = id_inst_i[19:15];
        end
    end

    assign id_csr = (id_inst_i[6:0] == `OP_CSR) ? id_inst_i[31:20] : 12'b0;


    always_comb begin
        stall_o = 5'b00000;
        flush_o = 5'b00000;
        if (page_fault_i) begin
            stall_o = 5'b00000;
        end else if (!if_master_already_i || !mem_master_already_i) begin
            stall_o = 5'b11111;
        end else begin
            if (pred_valid_i == 1'b1 && pred_succ_i == 1'b0) begin
                flush_o[1] = 1'b1;
            end else begin
                flush_o[0] = 1'b0;
            end
            if (exe_is_load_inst && exe_rf_wen && exe_rd != 5'd0 && (exe_rd == id_rs1 || exe_rd == id_rs2)) begin
                stall_o[1:0] = 2'b11;
                flush_o[2] = 1'b1;
            end else if ((id_inst_type_i == `TYPE_B && 
                ((id_inst_i[14:12] == `FUNCT3_BEQ && branch_zero_i) || (id_inst_i[14:12] == `FUNCT3_BNE && !branch_zero_i))) ||
                id_inst_type_i == `TYPE_J || id_csr_branch_flag_i) begin
                    flush_o[1] = 1'b1;
                end else if (id_inst_i[6:0] == `OP_CSR && id_inst_i[14:12] == `FUNCT3_EBREAK) begin
                    flush_o[1] = 1'b1;
                end
        end
    end

    always_comb begin
        rdata1_bypass_o = `EN_NoBypass;
        if (mem_rf_wen && mem_rd != 5'd0 && mem_rd == id_rs1) begin
            rdata1_bypass_o = `EN_MEMBypass;
        end
        if (!exe_is_load_inst && exe_rf_wen && exe_rd != 5'd0 && exe_rd == id_rs1) begin
            rdata1_bypass_o = `EN_EXEBypass;
        end
        rdata2_bypass_o = `EN_NoBypass;
        if (mem_rf_wen && mem_rd != 5'd0 && mem_rd == id_rs2) begin
            rdata2_bypass_o = `EN_MEMBypass;
        end
        if (!exe_is_load_inst && exe_rf_wen && exe_rd != 5'd0 && exe_rd == id_rs2) begin
            rdata2_bypass_o = `EN_EXEBypass;
        end
    end

endmodule
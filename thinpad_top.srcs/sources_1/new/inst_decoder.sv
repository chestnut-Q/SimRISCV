`default_nettype none
`include "defines.vh"

module inst_decoder (
    input wire [31:0] inst_i,
    output wire [4:0] rs1_o,
    output wire [4:0] rs2_o,
    output wire alu_src_o, // 0: rdata2; 1: imm
    output wire [`WIDTH_ALU_FUNCT] alu_funct_o,
    output wire [`WIDTH_INST_TYPE] inst_type_o,
    output reg [31:0] imm_o
);

	logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [`WIDTH_INST_TYPE] inst_type;

    assign opcode = inst_i[6:0];
    assign funct3 = inst_i[14:12];
    assign funct7 = inst_i[31:25];

	always_comb begin
		if (opcode == `OP_RTYPE) begin
			inst_type = `TYPE_R;
		end else if (opcode == `OP_ITYPE || opcode == `OP_LTYPE) begin
			inst_type = `TYPE_I;
		end else if (opcode == `OP_BTYPE) begin
			inst_type = `TYPE_B;
		end else if (opcode == `OP_LUI || opcode == `OP_AUIPC) begin
			inst_type = `TYPE_U;
		end else if (opcode == `OP_STYPE) begin
			inst_type = `TYPE_S;
		end else if (opcode == `OP_JAL || opcode == `OP_JALR) begin
			inst_type = `TYPE_J;
        end else if (opcode == `OP_CSR) begin
            inst_type = `TYPE_C;
        end else begin
            inst_type = `TYPE_R;
        end
	end

    assign rs1_o = inst_i[19:15];
    assign rs2_o = inst_i[24:20];
    assign alu_src_o = (inst_type == `TYPE_I || inst_type == `TYPE_S || inst_type == `TYPE_U);
    assign inst_type_o = inst_type;
    
    /* alu_funct begin */

    logic [`WIDTH_ALU_FUNCT] alu_funct;

    always_comb begin
        case (opcode)
            `OP_RTYPE: begin
                case (funct3)
                    `FUNCT3_ADD: begin
                        case (funct7)
                            `FUNCT7_ADD: alu_funct = `ALU_ADD;
                            `FUNCT7_SUB: alu_funct = `ALU_SUB;
                            default: alu_funct = `ALU_ADD;
                        endcase
                    end
                    `FUNCT3_SLL: begin
                        case (funct7)
                            `FUNCT7_SLL: alu_funct = `ALU_SLL;
                            `FUNCT7_SBCLR: alu_funct = `ALU_SBCLR;
                            default: alu_funct = `ALU_SLL;
                        endcase
                    end
                    `FUNCT3_XOR: alu_funct = `ALU_XOR;
                    `FUNCT3_SRL: begin
                        case (funct7)
                            `FUNCT7_SRL: alu_funct = `ALU_SRL;
                            `FUNCT7_SRA: alu_funct = `ALU_SRA;
                            default: alu_funct = `ALU_SRL;
                        endcase 
                    end
                    `FUNCT3_OR: alu_funct = `ALU_OR;
                    `FUNCT3_AND: begin
                        case (funct7)
                            `FUNCT7_AND: alu_funct = `ALU_AND;
                            `FUNCT7_ANDN: alu_funct = `ALU_ANDN;
                            default: alu_funct = `ALU_AND;
                        endcase
                    end
                    `FUNCT3_SLTU: alu_funct = `ALU_LT;
                    default: alu_funct = `ALU_ADD;
                endcase
            end
            `OP_ITYPE: begin //I-type
                case (funct3)
                    `FUNCT3_ADD: alu_funct = `ALU_ADD;
                    `FUNCT3_XOR: alu_funct = `ALU_XOR;
                    `FUNCT3_OR: alu_funct = `ALU_OR;
                    `FUNCT3_AND: alu_funct = `ALU_AND;
                    `FUNCT3_SLL: begin
                        case (funct7)
                            `FUNCT7_SLL: alu_funct = `ALU_SLL;
                            `FUNCT7_CLZ: alu_funct = `ALU_CLZ; 
                            default: alu_funct = `ALU_SLL;
                        endcase
                    end
                    `FUNCT3_SRL: alu_funct = `ALU_SRL;
                    default: alu_funct = `ALU_ADD;
                endcase
            end 
            `OP_STYPE: alu_funct = `ALU_ADD; // SB, SW
            `OP_LTYPE: alu_funct = `ALU_ADD; // LB, LW
            `OP_BTYPE: alu_funct = `ALU_SUB; // BEQ, BNE
            `OP_LUI: alu_funct = `ALU_LUI; // LUI
            `OP_AUIPC: alu_funct = `ALU_ADD; // AUIPC
            `OP_JAL: alu_funct = `ALU_JUMP; // JAL
            `OP_JALR: alu_funct = `ALU_JUMP; // JALR
            `OP_CSR: begin
                case (funct3)
                    `FUNCT3_CSRRC: alu_funct = `ALU_AND; // CSRRC
                    `FUNCT3_CSRRS: alu_funct = `ALU_OR; // CSRRS
                    default: alu_funct = `ALU_AND;
                endcase
            end
            
            default: alu_funct = `ALU_ADD;
        endcase
    end

    assign alu_funct_o = alu_funct;
    /* alu_funct end */

    /* imm gen begin */
    always_comb begin
        case (inst_type)
            `TYPE_I: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            `TYPE_S: imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            `TYPE_B: imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            `TYPE_U: imm_o = {inst_i[31:12], 12'd0};
            `TYPE_J: begin
                case (opcode)
                    `OP_JAL: imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0}; 
                    `OP_JALR: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
                    default: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
                endcase
            end 
            default: imm_o = 32'd0;
        endcase
    end 
    /* imm gen end */

endmodule
`default_nettype none

module inst_decoder (
    input wire [31:0] inst_i,
    output wire [4:0] rs1_o,
    output wire [4:0] rs2_o,
    output wire [4:0] rd_o,
    output wire alu_src_o, // 0: rdata2; 1: imm
    output wire [3:0] alu_funct_o,
    output wire [2:0] inst_type_o,
    output reg [31:0] imm_o,
    output reg [31:0] branch_addr_o
);

	typedef enum logic [2:0] {
		R_TYPE = 0,
		I_TYPE = 1,
		B_TYPE = 2,
		U_TYPE = 3,
		S_TYPE = 4,
		J_TYPE = 5,
        NONE = 6
	} inst_type_t;

	logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    inst_type_t inst_type;

    assign opcode = inst_i[6:0];
    assign funct3 = inst_i[14:12];
    assign funct7 = inst_i[31:25];

	always_comb begin
		if (opcode === 7'b0110011) begin
			inst_type = R_TYPE;
		end else if (opcode === 7'b0010011 || opcode === 7'b0000011) begin
			inst_type = I_TYPE;
		end else if (opcode === 7'b1100011) begin
			inst_type = B_TYPE;
		end else if (opcode === 7'b0110111 || opcode === 7'b0010111) begin
			inst_type = U_TYPE;
		end else if (opcode === 7'b0100011) begin
			inst_type = S_TYPE;
		end else if (opcode === 7'b1101111 || opcode === 7'b1100111) begin
			inst_type = J_TYPE;
        end else begin
            inst_type = NONE;
        end
	end

    assign rs1_o = inst_i[19:15];
    assign rs2_o = inst_i[24:20];
    assign rd_o = inst_i[11:7];
    assign alu_src_o = (inst_type === I_TYPE || inst_type === S_TYPE || inst_type === U_TYPE);
    assign inst_type_o = inst_type;
    
    /* alu_funct begin */
	typedef enum logic [3:0] {
		aluADD = 0,
		aluSUB = 1,
		aluAND = 2,
		aluOR = 3,
        aluXOR = 4,
        aluNOT = 5,
        aluSLL = 6,
        aluSRL = 7,
        aluSRA = 8,
        aluROL = 9,
        jump = 10, //Jָ�pc+4
        aluLUI = 11
    } alu_funct_t;

    alu_funct_t alu_funct;
    

    always_comb begin
        case (opcode)
            7'b0110011: begin
                case (funct3)
                    3'b000: begin
                        case (funct7)
                            7'b0000000: alu_funct = aluADD;
                            7'b0100000: alu_funct = aluSUB;
                            default: alu_funct = aluADD;
                        endcase
                    end
                    3'b001: alu_funct = aluSLL;
                    3'b100: alu_funct = aluXOR;
                    3'b101: begin
                        case (funct7)
                            7'b0000000: alu_funct = aluSRL;
                            7'b0100000: alu_funct = aluSRA;
                            default: alu_funct = aluSRL;
                        endcase 
                    end
                    3'b110: alu_funct = aluOR;
                    3'b111: alu_funct = aluAND;
                    default: alu_funct = aluADD;
                endcase
            end
            7'b0010011: begin //I-type
                case (funct3)
                    3'b000: alu_funct = aluADD;
                    3'b100: alu_funct = aluXOR;
                    3'b110: alu_funct = aluOR;
                    3'b111: alu_funct = aluAND;
                    default: alu_funct = aluADD;
                endcase
            end 
            7'b0100011: alu_funct = aluADD; // SB, SW
            7'b0000011: alu_funct = aluADD; // LB, LW
            7'b1100011: alu_funct = aluSUB; // BEQ, BNE
            7'b0110111: alu_funct = aluLUI; // LUI
            7'b0010111: alu_funct = aluADD; // AUIPC
            7'b1101111: alu_funct = jump; // JAL
            7'b1100111: alu_funct = jump; // JALR
            default: alu_funct = aluADD;
        endcase
    end

    assign alu_funct_o = alu_funct;
    /* alu_funct end */

    /* imm gen begin */
    always_comb begin
        case (inst_type)
            I_TYPE: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
            S_TYPE: imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            B_TYPE: imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            U_TYPE: imm_o = {inst_i[31:12], 12'd0};
            J_TYPE: begin
                case (opcode)
                    7'b1101111: imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0}; 
                    7'b1100111: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};// JALR
                    default: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
                endcase
            end 
            default: imm_o = 32'd0;
        endcase
    end 
    /* imm gen end */


endmodule
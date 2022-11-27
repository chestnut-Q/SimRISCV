// Constants
`define NOP 32'h00000013
// TODO recover the starting address
`define StartInstAddr 32'h80000000
// `define StartInstAddr 32'h80000340

`define WIDTH_INST_TYPE 2:0
`define WIDTH_ALU_FUNCT 3:0

`define EN_Imm 1'b1
`define EN_Rdata2 1'b0
`define EN_BYTE 1'b1
`define EN_WORD 1'b0
`define EN_NoBypass 2'd0
`define EN_EXEBypass 2'd1
`define EN_MEMBypass 2'd2

// Instruction Number
`define OP_RTYPE 7'b0110011
`define OP_ITYPE 7'b0010011
`define OP_LTYPE 7'b0000011
`define OP_STYPE 7'b0100011
`define OP_BTYPE 7'b1100011
`define OP_LUI 7'b0110111
`define OP_AUIPC 7'b0010111
`define OP_JAL 7'b1101111
`define OP_JALR 7'b1100111
`define OP_SLTU 7'b0110011
`define OP_CSR 7'b1110011
`define OP_INVALID 7'b0000000

`define FUNCT3_ADD 3'b000
`define FUNCT3_AND 3'b111
`define FUNCT3_OR 3'b110
`define FUNCT3_SLL 3'b001
`define FUNCT3_SRL 3'b101
`define FUNCT3_XOR 3'b100
`define FUNCT3_BEQ 3'b000
`define FUNCT3_BNE 3'b001
`define FUNCT3_BYTE 3'b000
`define FUNCT3_WORD 3'b010
`define FUNCT3_SLTU 3'b011
`define FUNCT3_CSRRC 3'b011
`define FUNCT3_CSRRS 3'b010
`define FUNCT3_CSRRW 3'b001
`define FUNCT3_EBREAK 3'b000

`define FUNCT7_ADD 7'b0000000
`define FUNCT7_SUB 7'b0100000
`define FUNCT7_SRL 7'b0000000
`define FUNCT7_SRA 7'b0100000

`define TYPE_R 3'd0
`define TYPE_I 3'd1
`define TYPE_B 3'd2
`define TYPE_U 3'd3
`define TYPE_S 3'd4
`define TYPE_J 3'd5
`define TYPE_C 3'd6

// Alu Operation Number
`define ALU_ADD 4'd0
`define	ALU_SUB 4'd1
`define ALU_AND 4'd2
`define ALU_OR 4'd3
`define ALU_XOR 4'd4
`define ALU_NOT 4'd5
`define ALU_SLL 4'd6
`define ALU_SRL 4'd7
`define ALU_SRA 4'd8
`define ALU_ROL 4'd9
`define ALU_JUMP 4'd10 // J 指令 PC+4
`define ALU_LUI 4'd11
`define ALU_LT 4'd12

// Currently allocated RISC-V machine-level CSR addresses
`define CSR_MTVEC 12'h305
`define CSR_MSTATUS 12'h300
`define CSR_MIE 12'h304
`define CSR_MSCRATCH 12'h340
`define CSR_MEPC 12'h341
`define CSR_MCAUSE 12'h342
`define CSR_MIP 12'h344
`define CSR_SATP 12'h180

`define ECALL 12'h000
`define EBREAK 12'h001
`define MRET 12'h302
`define TIMER 12'hfff

`define MTIME_LOWER_ADDR 32'h0200BFF8
`define MTIME_UPPER_ADDR 32'h0200BFFC
`define MTIMECMP_LOWER_ADDR 32'h02004000
`define MTIMECMP_UPPER_ADDR 32'h02004004
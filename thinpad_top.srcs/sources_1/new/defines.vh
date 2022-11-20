// Constants
`define RstEnable 1'b1
`define RstDisable 1'b0
`define ZeroWord 32'h00000000
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define AluOpBus 7:0
`define AluSelBus 2:0
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Stop 1'b1
`define NoStop 1'b0
`define InDelaySlot 1'b1
`define NotInDelaySlot 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 1'b1
`define TrapNotAssert 1'b0
`define True_v 1'b1
`define False_v 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define StartInstAddr 32'hbfc00000


`define WIDTH_INST_TYPE 2:0
`define WIDTH_ALU_FUNCT 3:0

`define Imm 1'b1;
`define Rdata2 1'b0;

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
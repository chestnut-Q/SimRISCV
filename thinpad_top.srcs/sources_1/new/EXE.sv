`default_nettype none
`include "defines.vh"

module EXE (
    input reg[31:0] inst_i,
    input wire [`WIDTH_INST_TYPE] inst_type_i,
    input reg [31:0] PC_i,
    input reg [31:0] rdata1_i,
    input reg [31:0] rdata2_i,
    input reg alu_src_i,
    input reg [31:0] imm_i,
    input reg [`WIDTH_ALU_FUNCT] alu_funct_i,
    output reg [31:0] alu_result_o
);

  reg [31:0] alu_a;
  reg [31:0] alu_b;
  reg [`WIDTH_ALU_FUNCT] alu_op;
  reg [31:0] alu_result;

  ALU ALU(
    .a(alu_a),
    .b(alu_b),
    .op(alu_op),
    .y(alu_result)
  );

  always_comb begin
    alu_a = (inst_i[6:0] == `OP_AUIPC || inst_type_i == `TYPE_J) ? PC_i : rdata1_i;
    alu_b = (alu_src_i == `EN_Imm) ? imm_i : rdata2_i;
    alu_op = alu_funct_i;
    alu_result_o = alu_result;
  end

endmodule
`default_nettype none
`include "defines.vh"

module ALU (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [`WIDTH_ALU_FUNCT] op,
    output reg [31:0] y,
    output wire zero_o
);

    always_comb begin
        case (op)
            `ALU_ADD: y = a + b;
            `ALU_SUB: y = a - b;
            `ALU_AND: y = a & b;
            `ALU_OR: y = a | b;
            `ALU_XOR: y = a^ b;
            `ALU_NOT: y = ~a;
            `ALU_SLL: y = a << b[4:0];
            `ALU_SRL: y = a >> b[4:0];
            `ALU_SRA: y = $signed(a) >>> b[4:0];
            `ALU_ROL: y = (a << b[4:0]) | (a >> (32 - b[4:0])); 
            `ALU_JUMP: y = a + 4;
            `ALU_LUI: y = b;
            default: y = 32'd0;
        endcase
    end

    assign zero_o = (y == 32'd0);

endmodule
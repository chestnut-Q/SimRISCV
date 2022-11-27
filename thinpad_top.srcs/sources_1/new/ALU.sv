`default_nettype none
`include "defines.vh"

module ALU (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [`WIDTH_ALU_FUNCT] op,
    output reg [31:0] y
);

    //use for CLZ inst
    integer i;
    logic [31:0] count;
    always_comb begin
        for(i = 0; i < 32; i = i + 1) begin
            if((a << i) >> 32'h1F) begin
                count = i;
                break;
            end
        end

        if (!a) begin
            count = 32'd32;
        end
    end

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
            `ALU_LT: y = (a < b);
            `ALU_ANDN: y = a & ~b;
            `ALU_SBCLR: y = a & ~(32'b1 << (b & 32'h1F));
            `ALU_CLZ: y = count;
            default: y = 32'd0;
        endcase
    end

endmodule
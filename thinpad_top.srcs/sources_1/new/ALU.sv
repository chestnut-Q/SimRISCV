`default_nettype none
`include "defines.vh"

module ALU (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [`WIDTH_ALU_FUNCT] op,
    output reg [31:0] y
);

    reg [7:0] elem [3:0];
    reg [7:0] idx [3:0];
    assign elem[0] = a[7:0];
    assign elem[1] = a[15:8];
    assign elem[2] = a[23:16];
    assign elem[3] = a[31:24];
    assign idx[0] = b[7:0];
    assign idx[1] = b[15:8];
    assign idx[2] = b[23:16];
    assign idx[3] = b[31:24];

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
            `ALU_XPERM: begin
                if (idx[0] > 8'd3) begin
                    y[7:0] = 8'd0;
                end
                else begin
                    y[7:0] = elem[idx[0]];
                end

                if (idx[1] > 8'd3) begin
                    y[15:8] = 8'd0;
                end
                else begin
                    y[15:8] = elem[idx[1]];
                end

                if (idx[2] > 8'd3) begin
                    y[23:16] = 8'd0;
                end
                else begin
                    y[23:16] = elem[idx[2]];
                end
                if (idx[3] > 8'd3) begin
                    y[31:24] = 8'd0;
                end
                else begin
                    y[31:24] = elem[idx[3]];
                end
            end
            default: y = 32'd0;
        endcase
    end

endmodule
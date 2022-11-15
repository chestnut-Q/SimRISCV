`default_nettype none

module ALU_32 (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] op,
    output reg [31:0] y,
    output wire zero_o
);

	typedef enum logic [3:0] {
		aluADD = 0,
		aluSUB = 1,
		aluAND = 2,
		aluOR = 3
    } alu_funct_t;

    always_comb begin
        case (op)
            aluADD: y = a + b;
            aluSUB: y = a - b;
            aluAND: y = a & b;
            aluOR: y = a | b;
            default: y = 32'd0;
        endcase
    end

    assign zero_o = (y == 32'd0);

endmodule
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
		aluOR = 3，
        aluXOR = 4,
        aluNOT = 5,
        aluSLL = 6,
        aluSRL = 7,
        aluSRA = 8,
        aluROL = 9,
        jump = 10, //J指令，pc+4
        aluLUI = 11
    } alu_funct_t;

    always_comb begin
        case (op)
            aluADD: y = a + b;
            aluSUB: y = a - b;
            aluAND: y = a & b;
            aluOR: y = a | b;
            aluXOR: y = a^ b;
            aluNOT: y = ~a;
            aluSLL: y = a << b[4:0];
            aluSRL: y = a >> b[4:0];
            aluSRA: y = $signed(a) >>> b[4:0];
            aluROL: y = (a << b[4:0]) | (a >> (32 - b[4:0])); 
            jump: y = a + 4;
            aluLUI: y = b;
            default: y = 32'd0;
        endcase
    end

    assign zero_o = (y == 32'd0);

endmodule
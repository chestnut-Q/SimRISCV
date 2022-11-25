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
		aluOR = 3,
        aluXOR = 4,
        aluNOT = 5,
        aluSLL = 6,
        aluSRL = 7,
        aluSRA = 8,
        aluROL = 9,
        jump = 10, //J-type
        aluLUI = 11,
        aluANDN = 12,
        aluSBCLR = 13,
        aluCLZ = 14
    } alu_funct_t;

    integer i;
    logic [31:0] count;
    always_comb begin
        for(i = 0; i < 32; i = i + 1) begin
            if((a << i) >> 32'h1F) begin
                count = i;
            end
        end

        if (!a) begin
            count = 32'd32;
        end
    end
    

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
            aluANDN: y = a & ~b;
            aluSBCLR: y = a & ~(32'b1 << (b & 32'h1F));
            aluCLZ: y = count;
            default: y = 32'd0;
        endcase
    end

    assign zero_o = (y == 32'd0);

endmodule
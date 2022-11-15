`default_nettype none

module ALU (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [3:0] op,
    output wire [15:0] y
);

logic [15:0] y_reg;

always_comb begin
    case (op)
        4'd1: y_reg = a + b; // ADD
        4'd2: y_reg = a - b; // SUB
        4'd3: y_reg = a & b; // AND
        4'd4: y_reg = a | b; // OR
        4'd5: y_reg = a ^ b; // XOR
        4'd6: y_reg = ~a; // NOT
        4'd7: y_reg = a << b[3:0]; // SLL
        4'd8: y_reg = a >> b[3:0]; // SRL
        4'd9: y_reg = {{16{a[15]}}, a} >> b[3:0]; // SRA
        4'd10: y_reg = (a << b[3:0]) | (a >> (16 - b[3:0])); // ROL
        default: y_reg = 16'd0;
    endcase
end

assign y = y_reg;

endmodule
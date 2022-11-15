`default_nettype none

module controller (
    input wire clk,
    input wire reset,
    input  wire step,
    input  wire [31:0] dip_sw,
    output wire [4:0] waddr,
    output wire we,
    output wire [4:0] raddr_a,
    output wire [4:0] raddr_b,
    output wire [3:0] op,
    output wire [15:0] write_imm,
    output wire write_s, // 1'b0: ALU; 1'b1: imm
    output wire LED_enable
);

logic [31:0] inst_reg;  // 指令寄存器

// 组合逻辑，解析指令中的常用部分，依赖于有效的 inst_reg 值
logic is_rtype, is_itype, is_peek, is_poke;
logic [15:0] imm;
logic [4:0] rd, rs1, rs2;
logic [3:0] opcode;

always_comb begin
    is_rtype = (inst_reg[2:0] == 3'b001);
    is_itype = (inst_reg[2:0] == 3'b010);
    is_peek = is_itype && (inst_reg[6:3] == 4'b0010);
    is_poke = is_itype && (inst_reg[6:3] == 4'b0001);

    imm = inst_reg[31:16];
    rd = inst_reg[11:7];
    rs1 = inst_reg[19:15];
    rs2 = inst_reg[24:20];
    opcode = inst_reg[6:3];
end

typedef enum logic [3:0] {
    ST_INIT,
    ST_DECODE,
    ST_CALC,
    ST_READ_REG,
    ST_WRITE_REG
} state_t;

state_t current_state;
state_t next_state;

// 状态转移
always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= ST_INIT;
    end else begin
        current_state <= next_state;
        if (current_state == ST_INIT && step == 1'b1)
            inst_reg <= dip_sw;
    end
end

// 计算下一状态
always_comb begin
    case(current_state)
        ST_INIT: begin
            next_state = (step == 1'b1) ? ST_DECODE : ST_INIT;
        end
        ST_DECODE: begin
            if (is_rtype) begin
                next_state = ST_CALC;
            end else if (is_poke) begin
                next_state = ST_WRITE_REG; 
            end else if (is_peek) begin
                next_state = ST_READ_REG;
            end else begin
                next_state = ST_INIT;
            end
        end
        ST_CALC: begin
            next_state = ST_WRITE_REG;
        end
        ST_READ_REG: begin
            next_state = ST_INIT;
        end
        ST_WRITE_REG: begin
            next_state = ST_INIT;
        end
        default: begin
            next_state = ST_INIT;
        end
    endcase
end

// 输出信号
assign raddr_a = (current_state == ST_READ_REG) ? rd : rs1;
assign raddr_b = rs2;
assign op = opcode;
assign waddr = rd;
assign we = (current_state == ST_WRITE_REG) ? 1'b1 : 1'b0;
assign write_imm = imm;
assign write_s = is_rtype ? 1'b0 : 1'b1;
assign LED_enable = (current_state == ST_READ_REG) ? 1'b1 : 1'b0;

endmodule
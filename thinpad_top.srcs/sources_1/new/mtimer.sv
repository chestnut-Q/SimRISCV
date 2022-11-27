`default_nettype none
`timescale 1ns/1ps
`include "defines.vh"

module mtimer (
    input wire clk_i,
    input wire rst_i,

    input wire wb_cyc_i,
    input wire wb_stb_i,
    input wire [31:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    input wire [3:0] wb_sel_i,
    input wire wb_we_i,
    output reg [31:0] wb_dat_o,
    output wire wb_ack_o,
    output reg interrupt_o
);

reg [63:0] mtime_reg;
reg [63:0] mtimecmp_reg;
assign interrupt_o = (mtime_reg >= mtimecmp_reg) ? 1'b1 : 1'b0;

typedef enum logic [2:0] {
	STATE_IDLE = 0,
	STATE_READ = 1,
	STATE_WRITE = 3,
	STATE_DONE = 6
} state_t;

state_t current_state, next_state;

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        current_state <= STATE_IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    case (current_state)
        STATE_IDLE: begin
            if (wb_cyc_i && wb_stb_i) begin
                if (wb_we_i) begin
                    next_state = STATE_WRITE;
                end else begin
                    next_state = STATE_READ;
                end
            end else begin
                next_state = STATE_IDLE;
            end
        end
        STATE_READ: begin
            next_state = STATE_DONE;
        end
        STATE_WRITE: begin
            next_state = STATE_DONE;
        end
        STATE_DONE: begin
            next_state = STATE_IDLE;
        end
    endcase
end

assign wb_ack_o = (current_state == STATE_DONE) ? 1'b1 : 1'b0;

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        mtimecmp_reg <= {64{1'b1}};
        mtime_reg <= 64'b0;
        wb_dat_o <= 32'b0;
    end else begin
        mtimecmp_reg <= mtimecmp_reg;
        mtime_reg <= mtime_reg + 1;
        case (current_state)
            STATE_IDLE: begin
            end
            STATE_READ: begin
                case (wb_adr_i)
                    `MTIME_LOWER_ADDR: begin
                        wb_dat_o <= mtime_reg[31:0];
                    end
                    `MTIME_UPPER_ADDR: begin
                        wb_dat_o <= mtime_reg[63:32];
                    end
                    `MTIMECMP_LOWER_ADDR: begin
                         wb_dat_o <= mtimecmp_reg[31:0];
                    end
                    `MTIMECMP_UPPER_ADDR: begin
                         wb_dat_o <= mtimecmp_reg[63:32];
                    end
                endcase
            end
            STATE_WRITE: begin
                case (wb_adr_i)
                    `MTIME_LOWER_ADDR: begin
                        mtime_reg[31:0] <= wb_dat_i;
                    end
                    `MTIME_UPPER_ADDR: begin
                        mtime_reg[63:32] <= wb_dat_i;
                    end
                    `MTIMECMP_LOWER_ADDR: begin
                        mtimecmp_reg[31:0] <= wb_dat_i;
                    end
                    `MTIMECMP_UPPER_ADDR: begin
                        mtimecmp_reg[63:32] <= wb_dat_i;
                    end
                endcase
            end
            STATE_DONE: begin
            end
        endcase
    end
end

endmodule
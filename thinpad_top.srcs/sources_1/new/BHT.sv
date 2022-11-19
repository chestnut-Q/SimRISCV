`timescale 1ps/1ps

module BHT (
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire PC_src_i,
    input wire bht_past_i,
    input wire [2:0] PC_src_type_i,
    input wire PC_src_zero_i,
    output wire [1:0] pred_state_o
);

typedef enum logic [1:0] {
    strongly_not_taken = 2'b00,
    weakly_not_taken = 2'b01,
    weakly_taken = 2'b10,
    strongly_taken = 2'b11
} state_t;

state_t pred_history_reg;

assign pred_state_o = pred_history_reg;

reg pred_valid;
reg pred_succ;

assign pred_valid = (PC_src_type_i == 3'b010);
assign pred_succ = ((PC_src_zero_i == 1'b1) && (bht_past_i == 1'b1)) || ((PC_src_zero_i == 1'b0) && (bht_past_i == 1'b0));

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        pred_history_reg <= strongly_not_taken;
    end else if (stall_i) begin
        pred_history_reg <= pred_history_reg;
    end else begin
        if (pred_valid) begin // prediction valid
            if (pred_succ) begin
                case (pred_history_reg)
                    strongly_taken: begin
                        pred_history_reg <= strongly_taken;
                    end
                    weakly_taken: begin
                        pred_history_reg <= strongly_taken;
                    end
                    weakly_not_taken: begin
                        pred_history_reg <= strongly_not_taken;
                    end
                    strongly_not_taken: begin
                        pred_history_reg <= strongly_not_taken;
                    end
                endcase
            end else begin
                case (pred_history_reg)
                    strongly_taken: begin
                        pred_history_reg <= weakly_taken;
                    end
                    weakly_taken: begin
                        pred_history_reg <= weakly_not_taken;
                    end
                    weakly_not_taken: begin
                        pred_history_reg <= weakly_taken;
                    end
                    strongly_not_taken: begin
                        pred_history_reg <= weakly_not_taken;
                    end
                endcase
            end
        end else begin // prediction invalid
            pred_history_reg <= pred_history_reg;
        end
    end
end

endmodule
`default_nettype none

module trigger (
  input wire clk,
  input wire reset,
  input wire push_btn,
  output wire trigger
);

reg btn_state_reg;
reg trigger_reg;
always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        btn_state_reg <= 1'b0;
        trigger_reg <= 1'b0;
    end else begin
        if (btn_state_reg == 1'b0 && push_btn == 1'b1)
            trigger_reg <= 1'b1;
        else
            trigger_reg <= 1'b0;
        btn_state_reg <= push_btn;
    end
end
assign trigger = trigger_reg;

endmodule

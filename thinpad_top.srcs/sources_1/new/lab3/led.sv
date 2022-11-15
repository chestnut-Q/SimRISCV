`default_nettype none

module LED (
    input wire clk,
    input wire reset,
    input wire [15:0] data,
    input wire enable,
    output wire [15:0] leds
);

logic [15:0] leds_reg;

always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        leds_reg <= 16'd0;
    end else begin
        if (enable)
            leds_reg <= data;
    end
end

assign leds = leds_reg;

endmodule
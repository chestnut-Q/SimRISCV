`default_nettype none

module register_file (
    input wire clk,
    input wire reset,
    input wire [4:0] waddr,
    input wire [15:0] wdata,
    input wire we,
    input wire [4:0] raddr_a,
    output wire [15:0] rdata_a,
    input wire [4:0] raddr_b,
    output wire [15:0] rdata_b
);

reg [15:0] RF_data[31:1];

assign rdata_a = (raddr_a == 5'b00000) ? 16'h0000 : RF_data[raddr_a];
assign rdata_b = (raddr_b == 5'b00000) ? 16'h0000 : RF_data[raddr_b];

integer i;
always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 1; i < 32; i = i + 1) begin
            RF_data[i] <= 16'h0000;
        end
    end else if (we && (waddr != 5'b00000)) begin
        RF_data[waddr] <= wdata;
    end
end

endmodule
`default_nettype none

module register_file_32 (
    input wire clk_i,
    input wire rst_i,
    input wire [4:0] rd_i,
    input wire [31:0] wdata_i,
    input wire we_i,
    input wire [4:0] rs1_i,
    input wire [4:0] rs2_i,
    output wire [31:0] rdata1_o,
    output wire [31:0] rdata2_o
);

    reg [31:0] RF_data[31:1];

    assign rdata1_o = rs1_i == 5'b00000 ? 32'h0 : RF_data[rs1_i];
    assign rdata2_o = rs2_i == 5'b00000 ? 32'h0 : RF_data[rs2_i];

    integer i;
    always_ff @ (posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (i = 1; i < 32; i = i + 1) begin
                RF_data[i] <= 32'h0;
            end
        end else if (we_i && (rd_i != 5'b00000)) begin
            RF_data[rd_i] <= wdata_i;
        end
    end

endmodule
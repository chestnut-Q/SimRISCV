`default_nettype none
`timescale 1ps/1ps

module CSR(
    input wire clk_i,
    input wire rst_i,
    input wire timer_i,

    input wire mtvec_we,
    input wire [31:0] mtvec_i,
    output reg[31:0] mtvec_o,

    input wire mscratch_we,
    input wire [31:0] mscratch_i,
    output reg [31:0] mscratch_o,

    input wire mepc_we,
    input wire [31:0] mepc_i,
    output reg [31:0] mepc_o,

    input wire mcause_we,
    input wire [31:0] mcause_i,
    output reg [31:0] mcause_o,

    input wire mstatus_we,
    input wire [31:0] mstatus_i,
    output reg [31:0] mstatus_o,

    input wire mie_we,
    input wire [31:0] mie_i,
    output reg [31:0] mie_o,

    input wire mip_we,
    input wire [31:0] mip_i,
    output reg [31:0] mip_o,

    input wire satp_we,
    input wire [31:0] satp_i,
    output reg [31:0] satp_o,

    input wire priv_level_we,
    input wire [1:0] priv_level_i,
    output reg [1:0] priv_level_o
);

reg [31:0] mtvec_reg;
reg [31:0] mscratch_reg;
reg [31:0] mepc_reg;
reg [31:0] mcause_reg;
reg [31:0] mstatus_reg;
reg [31:0] mie_reg;
reg [31:0] mip_reg;
reg [1:0] priv_level_reg;
reg [31:0] satp_reg;

always_comb begin
    mtvec_o = mtvec_we ? mtvec_i : mtvec_reg;
    mscratch_o = mscratch_we ? mscratch_i : mscratch_reg;
    mepc_o = mepc_we ? mepc_i : mepc_reg;
    mcause_o = mcause_we ? mcause_i : mcause_reg;
    mstatus_o = mstatus_we ? mstatus_i : mstatus_reg;
    mie_o = mie_we ? mie_i : mie_reg;
    mip_o = mip_we ? mip_i : mip_reg;
    satp_o = satp_we ? satp_i : satp_reg;
    priv_level_o = priv_level_we ? priv_level_i : priv_level_reg;
end

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        mtvec_reg <= 32'b0;
        mscratch_reg <= 32'b0;
        mepc_reg <= 32'b0;
        mcause_reg <= 32'b0;
        mstatus_reg <= 32'b0;
        mie_reg <= 32'b0;
        mip_reg <= 32'b0;
        satp_reg <= 32'b0;
        priv_level_reg <= 2'b11;
    end else begin
        mtvec_reg <= mtvec_we ? mtvec_i : mtvec_reg;
        mscratch_reg <= mscratch_we ? mscratch_i : mscratch_reg;
        mepc_reg <= mepc_we ? mepc_i : mepc_reg;
        mcause_reg <= mcause_we ? mcause_i : mcause_reg;
        mstatus_reg <= mstatus_we ? mstatus_i : mstatus_reg;
        mie_reg <= mie_we ? mie_i : mie_reg;
        mip_reg <= mip_we ? mip_i : {24'b0, timer_i, 7'b0};
        satp_reg <= satp_we ? satp_i : satp_reg;
        priv_level_reg <= priv_level_we ? priv_level_i : priv_level_reg;
    end
end

endmodule
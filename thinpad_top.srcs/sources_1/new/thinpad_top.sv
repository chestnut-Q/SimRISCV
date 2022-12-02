`default_nettype none
`include "defines.vh"

module thinpad_top (
    input wire clk_50M,     // 50MHz 时钟输入
    input wire clk_11M0592, // 11.0592MHz 时钟输入（备用，可不用）

    input wire push_btn,  // BTN5 按钮开关，带消抖电路，按下时为 1
    input wire reset_btn, // BTN6 复位按钮，带消抖电路，按下时为 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4，按钮开关，按下时为 1
    input  wire [31:0] dip_sw,     // 32 位拨码开关，拨到“ON”时为 1
    output wire [15:0] leds,       // 16 位 LED，输出时 1 点亮
    output wire [ 7:0] dpy0,       // 数码管低位信号，包括小数点，输出 1 点亮
    output wire [ 7:0] dpy1,       // 数码管高位信号，包括小数点，输出 1 点亮

    // CPLD 串口控制器信号
    output wire uart_rdn,        // 读串口信号，低有效
    output wire uart_wrn,        // 写串口信号，低有效
    input  wire uart_dataready,  // 串口数据准备好
    input  wire uart_tbre,       // 发送数据标志
    input  wire uart_tsre,       // 数据发送完毕标志

    // BaseRAM 信号
    inout wire [31:0] base_ram_data,  // BaseRAM 数据，低 8 位与 CPLD 串口控制器共享
    output wire [19:0] base_ram_addr,  // BaseRAM 地址
    output wire [3:0] base_ram_be_n,  // BaseRAM 字节使能，低有效。如果不使用字节使能，请保持为 0
    output wire base_ram_ce_n,  // BaseRAM 片选，低有效
    output wire base_ram_oe_n,  // BaseRAM 读使能，低有效
    output wire base_ram_we_n,  // BaseRAM 写使能，低有效

    // ExtRAM 信号
    inout wire [31:0] ext_ram_data,  // ExtRAM 数据
    output wire [19:0] ext_ram_addr,  // ExtRAM 地址
    output wire [3:0] ext_ram_be_n,  // ExtRAM 字节使能，低有效。如果不使用字节使能，请保持为 0
    output wire ext_ram_ce_n,  // ExtRAM 片选，低有效
    output wire ext_ram_oe_n,  // ExtRAM 读使能，低有效
    output wire ext_ram_we_n,  // ExtRAM 写使能，低有效

    // 直连串口信号
    output wire txd,  // 直连串口发送端
    input  wire rxd,  // 直连串口接收端

    // Flash 存储器信号，参考 JS28F640 芯片手册
    output wire [22:0] flash_a,  // Flash 地址，a0 仅在 8bit 模式有效，16bit 模式无意义
    inout wire [15:0] flash_d,  // Flash 数据
    output wire flash_rp_n,  // Flash 复位信号，低有效
    output wire flash_vpen,  // Flash 写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,  // Flash 片选信号，低有效
    output wire flash_oe_n,  // Flash 读使能信号，低有效
    output wire flash_we_n,  // Flash 写使能信号，低有效
    output wire flash_byte_n, // Flash 8bit 模式选择，低有效。在使用 flash 的 16 位模式时请设为 1

    // USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB 数据线与网络控制器的 dm9k_sd[7:0] 共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // 网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // 图像输出信号
    output wire [2:0] video_red,    // 红色像素，3 位
    output wire [2:0] video_green,  // 绿色像素，3 位
    output wire [1:0] video_blue,   // 蓝色像素，2 位
    output wire       video_hsync,  // 行同步（水平同步）信号
    output wire       video_vsync,  // 场同步（垂直同步）信号
    output wire       video_clk,    // 像素时钟输出
    output wire       video_de      // 行数据有效信号，用于区分消隐区
);

  /* =========== Demo code begin =========== */

  // PLL 分频示例
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // 外部时钟输入
      // Clock out ports
      .clk_out1(clk_10M),  // 时钟输出 1，频率在 IP 配置界面中设置
      .clk_out2(clk_20M),  // 时钟输出 2，频率在 IP 配置界面中设置
      // Status and control signals
      .reset(reset_btn),  // PLL 复位输入
      .locked(locked)  // PLL 锁定指示输出，"1"表示时钟稳定，
                       // 后级电路复位信号应当由它生成（见下）
  );

  logic reset_of_clk10M;
  // 异步复位，同步释放，将 locked 信号转为后级电路的复位 reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  // always_ff @(posedge clk_10M or posedge reset_of_clk10M) begin
  //   if (reset_of_clk10M) begin
  //     // Your Code
  //   end else begin
  //     // Your Code
  //   end
  // end

  // 不使用内存、串口时，禁用其使能信号
  // assign base_ram_ce_n = 1'b1;
  // assign base_ram_oe_n = 1'b1;
  // assign base_ram_we_n = 1'b1;

  // assign ext_ram_ce_n = 1'b1;
  // assign ext_ram_oe_n = 1'b1;
  // assign ext_ram_we_n = 1'b1;

  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  // 数码管连接关系示意图，dpy1 同理
  // p=dpy0[0] // ---a---
  // c=dpy0[1] // |     |
  // d=dpy0[2] // f     b
  // e=dpy0[3] // |     |
  // b=dpy0[4] // ---g---
  // a=dpy0[5] // |     |
  // f=dpy0[6] // e     c
  // g=dpy0[7] // |     |
  //           // ---d---  p

  // // 7 段数码管译码器演示，将 number 用 16 进制显示在数码管上面
  // logic [7:0] number;
  // SEG7_LUT segL (
  //     .oSEG1(dpy0),
  //     .iDIG (number[3:0])
  // );  // dpy0 是低位数码管
  // SEG7_LUT segH (
  //     .oSEG1(dpy1),
  //     .iDIG (number[7:4])
  // );  // dpy1 是高位数码管

  // logic [15:0] led_bits;
  // assign leds = led_bits;

  // always_ff @(posedge push_btn or posedge reset_btn) begin
  //   if (reset_btn) begin  // 复位按下，设置 LED 为初始值
  //     led_bits <= 16'h1;
  //   end else begin  // 每次按下按钮开关，LED 循环左移
  //     led_bits <= {led_bits[14:0], led_bits[15]};
  //   end
  // end

  // // 直连串口接收发送演示，从直连串口收到的数据再发送出去
  // logic [7:0] ext_uart_rx;
  // logic [7:0] ext_uart_buffer, ext_uart_tx;
  // logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
  // logic ext_uart_start, ext_uart_avai;

  // assign number = ext_uart_buffer;

  // // 接收模块，9600 无检验位
  // async_receiver #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_r (
  //     .clk           (clk_50M),         // 外部时钟信号
  //     .RxD           (rxd),             // 外部串行信号输入
  //     .RxD_data_ready(ext_uart_ready),  // 数据接收到标志
  //     .RxD_clear     (ext_uart_clear),  // 清除接收标志
  //     .RxD_data      (ext_uart_rx)      // 接收到的一字节数据
  // );

  // assign ext_uart_clear = ext_uart_ready; // 收到数据的同时，清除标志，因为数据已取到 ext_uart_buffer 中
  // always_ff @(posedge clk_50M) begin  // 接收到缓冲区 ext_uart_buffer
  //   if (ext_uart_ready) begin
  //     ext_uart_buffer <= ext_uart_rx;
  //     ext_uart_avai   <= 1;
  //   end else if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_avai <= 0;
  //   end
  // end
  // always_ff @(posedge clk_50M) begin  // 将缓冲区 ext_uart_buffer 发送出去
  //   if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_tx <= ext_uart_buffer;
  //     ext_uart_start <= 1;
  //   end else begin
  //     ext_uart_start <= 0;
  //   end
  // end

  // // 发送模块，9600 无检验位
  // async_transmitter #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_t (
  //     .clk      (clk_50M),         // 外部时钟信号
  //     .TxD      (txd),             // 串行信号输出
  //     .TxD_busy (ext_uart_busy),   // 发送器忙状态指示
  //     .TxD_start(ext_uart_start),  // 开始发送信号
  //     .TxD_data (ext_uart_tx)      // 待发送的数据
  // );

  // // 图像输出演示，分辨率 800x600@75Hz，像素时钟为 50MHz
  // logic [11:0] hdata;
  // assign video_red   = hdata < 266 ? 3'b111 : 0;  // 红色竖条
  // assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0;  // 绿色竖条
  // assign video_blue  = hdata >= 532 ? 2'b11 : 0;  // 蓝色竖条
  // assign video_clk   = clk_50M;
  // vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
  //     .clk        (clk_50M),
  //     .hdata      (hdata),        // 横坐标
  //     .vdata      (),             // 纵坐标
  //     .hsync      (video_hsync),
  //     .vsync      (video_vsync),
  //     .data_enable(video_de)
  // );
  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_10M;
  assign sys_rst = reset_of_clk10M;

   /* =========== CSR module begin =========== */

  //  Machine Trap Vector: 保存发生异常时处理器需要跳转到的地址
  wire csr_mtvec_we;
  wire [31:0] csr_mtvec_i;
  wire [31:0] csr_mtvec_o;
  // Machine Exception PC: 指向发生异常的指令
  wire csr_mepc_we; 
  wire [31:0] csr_mepc_i;
  wire [31:0] csr_mepc_o;
  // Machine Exception Cause: 指示发生异常的种类
  wire csr_mcause_we;
  wire [31:0] csr_mcause_i;
  wire [31:0] csr_mcause_o;
  // Machine Interrupt Enable: 指出处理器目前能处理和必须忽略的中断
  wire csr_mie_we;
  wire [31:0] csr_mie_i;
  wire [31:0] csr_mie_o;
  // Machine Interrupt Pending: 列出目前正准备处理的中断
  wire csr_mip_we;
  wire [31:0] csr_mip_i;
  wire [31:0] csr_mip_o;
  // Machine Trap Value: 保存了陷入（trap） 的附加信息：地址例外中出错的地址、发生非法指令例外的指令本身，对于其他异常，它的值为 0
  // Machine Scratch: 暂时存放一个字大小的数据
  wire csr_mscratch_we;
  wire [31:0] csr_mscratch_i;
  wire [31:0] csr_mscratch_o;
  // Machine Status: 它保存全局中断使能
  wire csr_mstatus_we;
  wire [31:0] csr_mstatus_i;
  wire [31:0] csr_mstatus_o;

  wire csr_satp_we;
  wire [31:0] csr_satp_i;
  wire [31:0] csr_satp_o;

  wire csr_priv_level_we;
  wire [1:0] csr_priv_level_i;
  wire [1:0] csr_priv_level_o;

  CSR CSR (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .timer_i(interrupt),

    .mtvec_we(csr_mtvec_we),
    .mtvec_i(csr_mtvec_i),
    .mtvec_o(csr_mtvec_o),

    .mscratch_we(csr_mscratch_we),
    .mscratch_i(csr_mscratch_i),
    .mscratch_o(csr_mscratch_o),

    .mepc_we(csr_mepc_we),
    .mepc_i(csr_mepc_i),
    .mepc_o(csr_mepc_o),

    .mcause_we(csr_mcause_we),
    .mcause_i(csr_mcause_i),
    .mcause_o(csr_mcause_o),

    .mstatus_we(csr_mstatus_we),
    .mstatus_i(csr_mstatus_i),
    .mstatus_o(csr_mstatus_o),

    .mie_we(csr_mie_we),
    .mie_i(csr_mie_i),
    .mie_o(csr_mie_o),

    .mip_we(csr_mip_we),
    .mip_i(csr_mip_i),
    .mip_o(csr_mip_o),

    .satp_we(csr_satp_we),
    .satp_i(csr_satp_i),
    .satp_o(csr_satp_o),

    .priv_level_we(csr_priv_level_we),
    .priv_level_i(csr_priv_level_i),
    .priv_level_o(csr_priv_level_o)
  );

  /* =========== CSR module end =========== */

  /* =========== IF module begin =========== */

  logic [31:0] if_PC;
  logic [31:0] if_inst;
  logic if_master_already;
  logic if_tlb_flush;

  /* =========== IF module end =========== */

  /* =========== ID module begin =========== */

  logic [31:0] id_PC;
  logic [31:0] id_inst;
  logic id_alu_src;
  logic [3:0] id_alu_funct;
  logic [2:0] id_inst_type;
  logic [31:0] id_imm;
  logic [31:0] id_rf_rdata1;
  logic [31:0] id_rf_rdata2;

  wire id_mtvec_we;
  wire id_mscratch_we;
  wire id_mepc_we;
  wire id_mcause_we;
  wire id_mstatus_we;
  wire id_mie_we;
  wire id_mip_we;
  wire id_satp_we;
  wire id_priv_level_we;

  wire [31:0] id_mtvec_o;
  wire [31:0] id_mscratch_o;
  wire [31:0] id_mepc_o;
  wire [31:0] id_mcause_o;
  wire [31:0] id_mstatus_o;
  wire [31:0] id_mie_o;
  wire [31:0] id_mip_o;
  wire [31:0] id_satp_o;
  wire [1:0] id_priv_level_o;

  wire [6:0] id_alu_opcode;
  wire [11:0] id_csr_addr;
  wire [2:0] id_csr_funct3;
  wire id_csr_branch_flag;
  wire [31:0] id_csr_branch_addr;

  /* =========== ID module end =========== */

  /* =========== EXE module begin =========== */

  logic [31:0] exe_PC;
  logic [31:0] exe_inst;
  logic [2:0] exe_inst_type;
  logic [3:0] exe_alu_funct;
  logic exe_alu_src;
  logic [31:0] exe_imm;
  logic [31:0] exe_rdata1;
  logic [31:0] exe_rdata2;
  logic [31:0] exe_alu_result;
  logic [31:0] exe_csr_result;

  reg exe_mtvec_we;
  reg [31:0] exe_mtvec_i;
  reg exe_mscratch_we;
  reg [31:0] exe_mscratch_i;
  reg exe_mepc_we;
  reg [31:0] exe_mepc_i;
  reg exe_mcause_we;
  reg [31:0] exe_mcause_i;
  reg exe_mstatus_we;
  reg [31:0] exe_mstatus_i;
  reg exe_mie_we;
  reg [31:0] exe_mie_i;
  reg exe_mip_we;
  reg [31:0] exe_mip_i;
  reg exe_satp_we;
  reg [31:0] exe_satp_i;
  reg exe_priv_level_we;
  reg [1:0] exe_priv_level_i;

  wire [6:0] exe_alu_opcode;
  wire [11:0] exe_csr_addr;
  wire [2:0] exe_csr_funct3;

  /* =========== EXE module end =========== */

  /* =========== MEM & WB module begin =========== */

  logic [31:0] mem_inst;
  logic [2:0] mem_inst_type;
  logic mem_PC_src;
  logic [31:0] mem_alu_result;
  logic [31:0] mem_csr_result;
  logic [31:0] mem_branch_addr;
  logic mem_ren;
  logic mem_wen;
  logic [31:0] mem_addr;
  logic [31:0] mem_wdata;
  logic mem_sel_byte;
  logic [31:0] mem_rdata;
  logic mem_master_already;
  logic [31:0] mem_rf_wdata;
  logic [31:0] mem_csr_satp;
  logic [1:0] mem_csr_priv_level;
  logic mem_tlb_flush;

  logic [4:0] wb_rd;
  logic [31:0] wb_rf_wdata;
  logic wb_rf_wen;

  /* =========== MEM & WB module end =========== */

  logic [4:0] stall;
  logic [4:0] flush;
  logic [1:0] rdata1_bypass;
  logic [1:0] rdata2_bypass;
  logic I_cache_already;
  logic D_cache_already;
  logic if_mmu_already;
  logic mem_mmu_already;
  logic [1:0] I_mmu_page_fault;
  logic [1:0] D_mmu_page_fault;

  stall_controller stall_controller (
    .if_master_already_i(if_mmu_already),
    .mem_master_already_i(mem_mmu_already),
    .id_inst_i(id_inst),
    .id_inst_type_i(id_inst_type),
    .exe_inst_i(exe_inst),
    .exe_inst_type_i(exe_inst_type),
    .mem_inst_i(mem_inst),
    .mem_inst_type_i(mem_inst_type),
    .wb_rd_i(wb_rd),
    .wb_rf_wen_i(wb_rf_wen),
    .branch_zero_i(id_rf_rdata1 === id_rf_rdata2),
    .id_csr_branch_flag_i(id_csr_branch_flag),
    .stall_o(stall),
    .flush_o(flush),
    .rdata1_bypass_o(rdata1_bypass),
    .rdata2_bypass_o(rdata2_bypass)
  );

  IF IF (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[0]),
    .id_inst_type_i(id_inst_type),
    .id_inst_i(id_inst),
    .if_inst_i(if_inst),
    .id_rf_rdata1_i(id_rf_rdata1),
    .id_rf_rdata2_i(id_rf_rdata2),
    .id_imm_i(id_imm),
    .id_PC_i(id_PC),
    .id_csr_branch_addr_i(id_csr_branch_addr),
    .id_csr_branch_flag_i(id_csr_branch_flag),
    .if_PC_o(if_PC),
    .tlb_flush_o(if_tlb_flush)
  );

  IF_ID_controller IF_ID_controller(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[1]),
    .flush_i(flush[1]),
    .PC_i(if_PC),
    .inst_i(if_inst),
    .PC_o(id_PC),
    .inst_o(id_inst)
  );

  ID ID (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .inst_i(id_inst),
    .rf_waddr_i(wb_rd),
    .rf_wdata_i(wb_rf_wdata),
    .rf_wen_i(wb_rf_wen),
    .rdata1_bypass_i(rdata1_bypass),
    .rdata2_bypass_i(rdata2_bypass),
    .exe_inst_i(exe_inst),
    .exe_alu_result_i(exe_alu_result),
    .exe_csr_result_i(exe_csr_result),
    .mem_rf_wdata_i(mem_rf_wdata),
    .alu_src_o(id_alu_src),
    .alu_funct_o(id_alu_funct),
    .alu_opcode_o(id_alu_opcode),
    .inst_type_o(id_inst_type),
    .imm_o(id_imm),
    .rf_rdata1_o(id_rf_rdata1),
    .rf_rdata2_o(id_rf_rdata2),

    .csr_addr_o(id_csr_addr),
    .csr_funct3_o(id_csr_funct3),
    .csr_branch_addr_o(id_csr_branch_addr),
    .csr_branch_flag_o(id_csr_branch_flag),

    .mtvec_i(csr_mtvec_o),
    .mtvec_we(id_mtvec_we),
    .mtvec_o(id_mtvec_o),

    .mscratch_i(csr_mscratch_o),
    .mscratch_we(id_mscratch_we),
    .mscratch_o(id_mscratch_o),

    .mepc_i(csr_mepc_o),
    .mepc_we(id_mepc_we),
    .mepc_o(id_mepc_o),

    .mcause_i(csr_mcause_o),
    .mcause_we(id_mcause_we),
    .mcause_o(id_mcause_o),

    .mstatus_i(csr_mstatus_o),
    .mstatus_we(id_mstatus_we),
    .mstatus_o(id_mstatus_o),

    .mie_i(csr_mie_o),
    .mie_we(id_mie_we),
    .mie_o(id_mie_o),

    .mip_i(csr_mip_o),
    .mip_we(id_mip_we),
    .mip_o(id_mip_o),

    .satp_i(csr_satp_o),
    .satp_we(id_satp_we),
    .satp_o(id_satp_o),
    
    .priv_level_i(csr_priv_level_o),
    .priv_level_we(id_priv_level_we),
    .priv_level_o(id_priv_level_o)
  );

  ID_EXE_controller ID_EXE_controller(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[2]),
    .flush_i(flush[2]),
    .PC_i(id_PC),
    .inst_i(id_inst),
    .inst_type_i(id_inst_type),
    .alu_opcode_i(id_alu_opcode),
    .alu_funct_i(id_alu_funct),
    .alu_src_i(id_alu_src),
    .csr_addr_i(id_csr_addr),
    .csr_funct3_i(id_csr_funct3),
    .imm_i(id_imm),
    .rdata1_i(id_rf_rdata1),
    .rdata2_i(id_rf_rdata2),
    .inst_o(exe_inst),
    .inst_type_o(exe_inst_type),
    .alu_opcode_o(exe_alu_opcode),
    .alu_funct_o(exe_alu_funct),
    .alu_src_o(exe_alu_src), 
    .csr_addr_o(exe_csr_addr),
    .csr_funct3_o(exe_csr_funct3),
    .imm_o(exe_imm),
    .rdata1_o(exe_rdata1),
    .rdata2_o(exe_rdata2),
    .PC_o(exe_PC), // AUIPC

    .id_mtvec_we(id_mtvec_we),
    .id_mtvec_i(id_mtvec_o),
    .exe_mtvec_we(exe_mtvec_we),
    .exe_mtvec_o(exe_mtvec_i),

    .id_mscratch_we(id_mscratch_we),
    .id_mscratch_i(id_mscratch_o),
    .exe_mscratch_we(exe_mscratch_we),
    .exe_mscratch_o(exe_mscratch_i),

    .id_mepc_we(id_mepc_we),
    .id_mepc_i(id_mepc_o),
    .exe_mepc_we(exe_mepc_we),
    .exe_mepc_o(exe_mepc_i),

    .id_mcause_we(id_mcause_we),
    .id_mcause_i(id_mcause_o),
    .exe_mcause_we(exe_mcause_we),
    .exe_mcause_o(exe_mcause_i),

    .id_mstatus_we(id_mstatus_we),
    .id_mstatus_i(id_mstatus_o),
    .exe_mstatus_we(exe_mstatus_we),
    .exe_mstatus_o(exe_mstatus_i),

    .id_mie_we(id_mie_we),
    .id_mie_i(id_mie_o),
    .exe_mie_we(exe_mie_we),
    .exe_mie_o(exe_mie_i),

    .id_mip_we(id_mip_we),
    .id_mip_i(id_mip_o),
    .exe_mip_we(exe_mip_we),
    .exe_mip_o(exe_mip_i),

    .id_satp_we(id_satp_we),
    .id_satp_i(id_satp_o),
    .exe_satp_we(exe_satp_we),
    .exe_satp_o(exe_satp_i),

    .id_priv_level_we(id_priv_level_we),
    .id_priv_level_i(id_priv_level_o),
    .exe_priv_level_we(exe_priv_level_we),
    .exe_priv_level_o(exe_priv_level_i)
  );

  EXE EXE (
    .rst_i(sys_rst),
    .inst_i(exe_inst),
    .inst_type_i(exe_inst_type),
    .PC_i(exe_PC),
    .rdata1_i(exe_rdata1),
    .rdata2_i(exe_rdata2),
    .alu_src_i(exe_alu_src),
    .alu_opcode_i(exe_alu_opcode),
    .csr_addr_i(exe_csr_addr),
    .csr_funct3_i(exe_csr_funct3),
    .imm_i(exe_imm),
    .alu_funct_i(exe_alu_funct),
    .alu_result_o(exe_alu_result),
    .csr_result_o(exe_csr_result),

    .mtvec_i(exe_mtvec_i),
    .mtvec_we_i(exe_mtvec_we),
    .mtvec_o(csr_mtvec_i),
    .mtvec_we_o(csr_mtvec_we),

    .mscratch_i(exe_mscratch_i),
    .mscratch_we_i(exe_mscratch_we),
    .mscratch_o(csr_mscratch_i),
    .mscratch_we_o(csr_mscratch_we),

    .mepc_i(exe_mepc_i),
    .mepc_we_i(exe_mepc_we),
    .mepc_o(csr_mepc_i),
    .mepc_we_o(csr_mepc_we),

    .mcause_i(exe_mcause_i),
    .mcause_we_i(exe_mcause_we),
    .mcause_o(csr_mcause_i),
    .mcause_we_o(csr_mcause_we),

    .mstatus_i(exe_mstatus_i),
    .mstatus_we_i(exe_mstatus_we),
    .mstatus_o(csr_mstatus_i),
    .mstatus_we_o(csr_mstatus_we),

    .mie_i(exe_mie_i),
    .mie_we_i(exe_mie_we),
    .mie_o(csr_mie_i),
    .mie_we_o(csr_mie_we),

    .mip_i(exe_mip_i),
    .mip_we_i(exe_mip_we),
    .mip_o(csr_mip_i),
    .mip_we_o(csr_mip_we),

    .satp_i(exe_satp_i),
    .satp_we_i(exe_satp_we),
    .satp_o(csr_satp_i),
    .satp_we_o(csr_satp_we),

    .priv_level_i(exe_priv_level_i),
    .priv_level_we_i(exe_priv_level_we),
    .priv_level_o(csr_priv_level_i),
    .priv_level_we_o(csr_priv_level_we)
  );

  EXE_MEM_controller EXE_MEM_controller(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[3]),
    .flush_i(flush[3]),
    .inst_i(exe_inst),
    .inst_type_i(exe_inst_type),
    .alu_result_i(exe_alu_result),
    .csr_result_i(exe_csr_result),
    .rdata2_i(exe_rdata2),
    .satp_i(exe_satp_i),
    .priv_level_i(exe_priv_level_i),
    .satp_o(mem_csr_satp),
    .priv_level_o(mem_csr_priv_level),
    .inst_o(mem_inst),
    .inst_type_o(mem_inst_type),
    .alu_result_o(mem_alu_result),
    .csr_result_o(mem_csr_result),
    .mem_ren_o(mem_ren), // 是（1）否（0）读 mem
    .mem_wen_o(mem_wen), // 是（1）否（0）写 mem
    .mem_addr_o(mem_addr), 
    .mem_wdata_o(mem_wdata),
    .sel_byte_o(mem_sel_byte),
    .mem_tlb_flush_o(mem_tlb_flush)
  );

  MEM_WB_controller MEM_WB_controller(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[4]),
    .flush_i(flush[4]),
    .inst_i(mem_inst),
	  .inst_type_i(mem_inst_type),
    .alu_result_i(mem_alu_result),
    .csr_result_i(mem_csr_result),
    .mem_read_data_i(mem_rdata), // 读内存的数据
    .logic_rf_wdata_o(mem_rf_wdata),
    .rf_wen_o(wb_rf_wen),
    .rf_wdata_o(wb_rf_wdata),
    .rf_waddr_o(wb_rd)
  );

  logic [31:0] if_mem_req_addr;
  logic [31:0] if_mem_req_data;
  logic if_mem_req_valid;
  logic [31:0] mem_mem_req_addr;
  logic mem_mem_req_ren;
  logic mem_mem_req_wen;
  logic [31:0] mem_mem_req_wdata;
  logic [31:0] mem_mem_req_rdata;
  logic mem_mem_req_sel_byte;
  logic [31:0] if_mmu_req_addr;
  logic [31:0] mem_mmu_req_addr;
  logic mem_mmu_working;

  MMU I_MMU(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .virtual_addr_i(if_PC),
    .satp_i(csr_satp_o),
    .priv_level_i(csr_priv_level_o),
    .mem_req_data_i(if_inst),
    .ren_i(1'b1),
    .wen_i(1'b0),
    .use_mmu_i(1'b1),
    .mem_ack_i(I_cache_already),
    .tlb_flush_i(if_tlb_flush),
    .physical_addr_o(if_mmu_req_addr),
    .mmu_working_o(),
    .already_o(if_mmu_already),
    .page_fault_o(I_mmu_page_fault)
  );

  MMU D_MMU(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .virtual_addr_i(mem_alu_result),
    .satp_i(mem_csr_satp),
    .priv_level_i(mem_csr_priv_level),
    .mem_req_data_i(mem_rdata),
    .ren_i(mem_ren),
    .wen_i(mem_wen),
    .use_mmu_i(mem_ren | mem_wen),
    .mem_ack_i(D_cache_already),
    .tlb_flush_i(mem_tlb_flush),
    .physical_addr_o(mem_mmu_req_addr),
    .mmu_working_o(mem_mmu_working),
    .already_o(mem_mmu_already),
    .page_fault_o(D_mmu_page_fault)
  );

  I_cache #(
    .CACHE_CAPACITY(32)
  ) I_cache(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    //to mem
    .mem_req_addr_o(if_mem_req_addr),
    .mem_req_valid_o(if_mem_req_valid),
    .mem_req_data_i(if_mem_req_data),
    .mem_req_ready_i(if_master_already),
    //to CPU
    .cpu_req_addr_i(if_mmu_req_addr),
    .cpu_req_valid_i(1'b1),
    .cpu_req_data_o(if_inst),
    .already_o(I_cache_already)
  );

  D_cache #(
    .CACHE_CAPACITY(32)
  ) D_cache(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .write_through_all(1'b0),
    .use_dcache(1'b0),
    //to mem
    .mem_req_addr_o(mem_mem_req_addr),
    .mem_req_ren_o(mem_mem_req_ren),
    .mem_req_wen_o(mem_mem_req_wen),
    .mem_req_wdata_o(mem_mem_req_wdata),
    .mem_req_data_i(mem_mem_req_rdata),
    .mem_req_ready_i(mem_master_already),
    .mem_sel_byte_o(mem_mem_req_sel_byte),
    //to CPU
    .cpu_req_addr_i(mem_mmu_req_addr),
    .cpu_req_ren_i(mem_mmu_working ? 1'b1 : mem_ren),
    .cpu_req_wen_i(mem_mmu_working ? 1'b0 : mem_wen),
    .cpu_req_wdata_i(mem_wdata),
    .cpu_sel_byte_i(mem_mmu_working ? `EN_WORD : mem_sel_byte),
    .cpu_req_data_o(mem_rdata),
    .already_o(D_cache_already)
);

  /***********************外设部分开始***************************/ 
  logic wbm0_cyc_o;
  logic wbm0_stb_o;
  logic wbm0_ack_i;
  logic [31:0] wbm0_adr_o;
  logic [31:0] wbm0_dat_o;
  logic [31:0] wbm0_dat_i;
  logic [3:0] wbm0_sel_o;
  logic wbm0_we_o;

  logic wbm1_cyc_o;
  logic wbm1_stb_o;
  logic wbm1_ack_i;
  logic [31:0] wbm1_adr_o;
  logic [31:0] wbm1_dat_o;
  logic [31:0] wbm1_dat_i;
  logic [3:0] wbm1_sel_o;
  logic wbm1_we_o;

  logic [31:0] wbm_adr_o;
  logic [31:0] wbm_dat_o;
  logic [31:0] wbm_dat_i;
  logic wbm_we_o;
  logic [3:0] wbm_sel_o;
  logic wbm_stb_o;
  logic wbm_ack_i;
  logic wbm_cyc_o;

  logic [31:0] wbs0_adr_o;
  logic [31:0] wbs0_dat_i;
  logic [31:0] wbs0_dat_o;
  logic wbs0_we_o;
  logic [3:0] wbs0_sel_o;
  logic wbs0_stb_o;
  logic wbs0_ack_i;
  logic wbs0_cyc_o;

  logic [31:0] wbs00_adr_o;
  logic [31:0] wbs00_dat_i;
  logic [31:0] wbs00_dat_o;
  logic wbs00_we_o;
  logic [3:0] wbs00_sel_o;
  logic wbs00_stb_o;
  logic wbs00_ack_i;
  logic wbs00_cyc_o;

  logic [31:0] wbs01_adr_o;
  logic [31:0] wbs01_dat_i;
  logic [31:0] wbs01_dat_o;
  logic wbs01_we_o;
  logic [3:0] wbs01_sel_o;
  logic wbs01_stb_o;
  logic wbs01_ack_i;
  logic wbs01_cyc_o;

  logic [31:0] wbs10_adr_o;
  logic [31:0] wbs10_dat_i;
  logic [31:0] wbs10_dat_o;
  logic wbs10_we_o;
  logic [3:0] wbs10_sel_o;
  logic wbs10_stb_o;
  logic wbs10_ack_i;
  logic wbs10_cyc_o;

  logic [31:0] wbs11_adr_o;
  logic [31:0] wbs11_dat_i;
  logic [31:0] wbs11_dat_o;
  logic wbs11_we_o;
  logic [3:0] wbs11_sel_o;
  logic wbs11_stb_o;
  logic wbs11_ack_i;
  logic wbs11_cyc_o;

  logic [31:0] wbs1_adr_o;
  logic [31:0] wbs1_dat_i;
  logic [31:0] wbs1_dat_o;
  logic wbs1_we_o;
  logic [3:0] wbs1_sel_o;
  logic wbs1_stb_o;
  logic wbs1_ack_i;
  logic wbs1_cyc_o;

  logic [31:0] wbs2_adr_o;
  logic [31:0] wbs2_dat_i;
  logic [31:0] wbs2_dat_o;
  logic wbs2_we_o;
  logic [3:0] wbs2_sel_o;
  logic wbs2_stb_o;
  logic wbs2_ack_i;
  logic wbs2_cyc_o;

  logic [31:0] wbs3_adr_o;
  logic [31:0] wbs3_dat_i;
  logic [31:0] wbs3_dat_o;
  logic wbs3_we_o;
  logic [3:0] wbs3_sel_o;
  logic wbs3_stb_o;
  logic wbs3_ack_i;
  logic wbs3_cyc_o;

  IF_master #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) cpu_if_master (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall(1'b0),
    .addr_i(if_mem_req_addr),
    .ren_i(if_mem_req_valid),
    .rdata_o(if_mem_req_data),
    .wb_cyc_o(wbm0_cyc_o),
    .wb_stb_o(wbm0_stb_o),
    .wb_ack_i(wbm0_ack_i),
    .wb_adr_o(wbm0_adr_o),
    .wb_dat_o(wbm0_dat_o),
    .wb_dat_i(wbm0_dat_i),
    .wb_sel_o(wbm0_sel_o),
    .wb_we_o (wbm0_we_o),
    .already_o(if_master_already)
  );

  MEM_master #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) cpu_mem_master (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall(1'b0),
    .addr_i(mem_mem_req_addr),
    .wdata_i(mem_mem_req_wdata),
    .wen_i(mem_mem_req_wen),
    .ren_i(mem_mem_req_ren),
    .sel_byte_i(mem_mem_req_sel_byte), // 字节（1）或者字（0）
    .rdata_o(mem_mem_req_rdata),
    .wb_cyc_o(wbm1_cyc_o),
    .wb_stb_o(wbm1_stb_o),
    .wb_ack_i(wbm1_ack_i),
    .wb_adr_o(wbm1_adr_o),
    .wb_dat_o(wbm1_dat_o),
    .wb_dat_i(wbm1_dat_i),
    .wb_sel_o(wbm1_sel_o),
    .wb_we_o (wbm1_we_o),
    .already_o(mem_master_already)
  );

  /* =========== MUX begin =========== */
  wb_mux_2 wb_mux_if (
    .clk(sys_clk),
    .rst(sys_rst),

    // Master interface (to if master)
    .wbm_adr_i(wbm0_adr_o),
    .wbm_dat_i(wbm0_dat_o),
    .wbm_dat_o(wbm0_dat_i),
    .wbm_we_i (wbm0_we_o),
    .wbm_sel_i(wbm0_sel_o),
    .wbm_stb_i(wbm0_stb_o),
    .wbm_ack_o(wbm0_ack_i),
    .wbm_err_o(),
    .wbm_rty_o(),
    .wbm_cyc_i(wbm0_cyc_o),

    // Slave interface 0 (to BaseRAM controller)
    // Address range: 0x8000_0000 ~ 0x803F_FFFF
    .wbs0_addr    (32'h8000_0000),
    .wbs0_addr_msk(32'hFFC0_0000),

    .wbs0_adr_o(wbs00_adr_o),
    .wbs0_dat_i(wbs00_dat_i),
    .wbs0_dat_o(wbs00_dat_o),
    .wbs0_we_o (wbs00_we_o),
    .wbs0_sel_o(wbs00_sel_o),
    .wbs0_stb_o(wbs00_stb_o),
    .wbs0_ack_i(wbs00_ack_i),
    .wbs0_err_i('0),
    .wbs0_rty_i('0),
    .wbs0_cyc_o(wbs00_cyc_o),

    // Slave interface 1 (to ExtRAM controller)
    // Address range: 0x8040_0000 ~ 0x807F_FFFF
    .wbs1_addr    (32'h8040_0000),
    .wbs1_addr_msk(32'hFFC0_0000),

    .wbs1_adr_o(wbs01_adr_o),
    .wbs1_dat_i(wbs01_dat_i),
    .wbs1_dat_o(wbs01_dat_o),
    .wbs1_we_o (wbs01_we_o),
    .wbs1_sel_o(wbs01_sel_o),
    .wbs1_stb_o(wbs01_stb_o),
    .wbs1_ack_i(wbs01_ack_i),
    .wbs1_err_i('0),
    .wbs1_rty_i('0),
    .wbs1_cyc_o(wbs01_cyc_o)
  );


  wb_mux_4 wb_mux_mem (
    .clk(sys_clk),
    .rst(sys_rst),

    // Master interface (to mem master)
    .wbm_adr_i(wbm1_adr_o),
    .wbm_dat_i(wbm1_dat_o),
    .wbm_dat_o(wbm1_dat_i),
    .wbm_we_i (wbm1_we_o),
    .wbm_sel_i(wbm1_sel_o),
    .wbm_stb_i(wbm1_stb_o),
    .wbm_ack_o(wbm1_ack_i),
    .wbm_err_o(),
    .wbm_rty_o(),
    .wbm_cyc_i(wbm1_cyc_o),

    // Slave interface 0 (to BaseRAM controller)
    // Address range: 0x8000_0000 ~ 0x803F_FFFF
    .wbs0_addr    (32'h8000_0000),
    .wbs0_addr_msk(32'hFFC0_0000),

    .wbs0_adr_o(wbs10_adr_o),
    .wbs0_dat_i(wbs10_dat_i),
    .wbs0_dat_o(wbs10_dat_o),
    .wbs0_we_o (wbs10_we_o),
    .wbs0_sel_o(wbs10_sel_o),
    .wbs0_stb_o(wbs10_stb_o),
    .wbs0_ack_i(wbs10_ack_i),
    .wbs0_err_i('0),
    .wbs0_rty_i('0),
    .wbs0_cyc_o(wbs10_cyc_o),

    // Slave interface 1 (to ExtRAM controller)
    // Address range: 0x8040_0000 ~ 0x807F_FFFF
    .wbs1_addr    (32'h8040_0000),
    .wbs1_addr_msk(32'hFFC0_0000),

    .wbs1_adr_o(wbs11_adr_o),
    .wbs1_dat_i(wbs11_dat_i),
    .wbs1_dat_o(wbs11_dat_o),
    .wbs1_we_o (wbs11_we_o),
    .wbs1_sel_o(wbs11_sel_o),
    .wbs1_stb_o(wbs11_stb_o),
    .wbs1_ack_i(wbs11_ack_i),
    .wbs1_err_i('0),
    .wbs1_rty_i('0),
    .wbs1_cyc_o(wbs11_cyc_o),

    // Slave interface 2 (to UART controller)
    // Address range: 0x1000_0000 ~ 0x1000_FFFF
    .wbs2_addr    (32'h1000_0000),
    .wbs2_addr_msk(32'hFFFF_0000),

    .wbs2_adr_o(wbs2_adr_o),
    .wbs2_dat_i(wbs2_dat_i),
    .wbs2_dat_o(wbs2_dat_o),
    .wbs2_we_o (wbs2_we_o),
    .wbs2_sel_o(wbs2_sel_o),
    .wbs2_stb_o(wbs2_stb_o),
    .wbs2_ack_i(wbs2_ack_i),
    .wbs2_err_i('0),
    .wbs2_rty_i('0),
    .wbs2_cyc_o(wbs2_cyc_o),
  
    // Slave interface 3 (to mtime and mtimecmp)
    // Address range: 0x2004000 ~ 0x200BFF8	
    .wbs3_addr    (32'h02004000),
    .wbs3_addr_msk(32'hFFFF_0000),

    .wbs3_adr_o(wbs3_adr_o),
    .wbs3_dat_i(wbs3_dat_i),
    .wbs3_dat_o(wbs3_dat_o),
    .wbs3_we_o (wbs3_we_o),
    .wbs3_sel_o(wbs3_sel_o),
    .wbs3_stb_o(wbs3_stb_o),
    .wbs3_ack_i(wbs3_ack_i),
    .wbs3_err_i('0),
    .wbs3_rty_i('0),
    .wbs3_cyc_o(wbs3_cyc_o)
  );
  /* =========== MUX end =========== */

  /* =========== Arbiter begin =========== */
  wb_arbiter_2 #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .SELECT_WIDTH(4),
    .ARB_TYPE_ROUND_ROBIN(0),
    .ARB_LSB_HIGH_PRIORITY(0) // 设置为 0 的时候 1 号口的优先级更高，设置为 1 的时候 0 号口的优先级会更高
  ) wb_BaseRAM_arbiter_2 (
    .clk(sys_clk),
    .rst(sys_rst),
    // Wishbone master 0 input
    .wbm0_adr_i(wbs00_adr_o),
    .wbm0_dat_i(wbs00_dat_o),
    .wbm0_dat_o(wbs00_dat_i),
    .wbm0_we_i(wbs00_we_o),
    .wbm0_sel_i(wbs00_sel_o),
    .wbm0_stb_i(wbs00_stb_o),
    .wbm0_ack_o(wbs00_ack_i),
    .wbm0_err_o(),
    .wbm0_rty_o(),
    .wbm0_cyc_i(wbs00_cyc_o),
    // Wishbone master 1 input
    .wbm1_adr_i(wbs10_adr_o),
    .wbm1_dat_i(wbs10_dat_o),
    .wbm1_dat_o(wbs10_dat_i),
    .wbm1_we_i(wbs10_we_o),
    .wbm1_sel_i(wbs10_sel_o),
    .wbm1_stb_i(wbs10_stb_o),
    .wbm1_ack_o(wbs10_ack_i),
    .wbm1_err_o(),
    .wbm1_rty_o(),
    .wbm1_cyc_i(wbs10_cyc_o),
    // Wishbone slave output
    .wbs_adr_o(wbs0_adr_o),
    .wbs_dat_i(wbs0_dat_i),
    .wbs_dat_o(wbs0_dat_o),
    .wbs_we_o(wbs0_we_o),
    .wbs_sel_o(wbs0_sel_o),
    .wbs_stb_o(wbs0_stb_o),
    .wbs_ack_i(wbs0_ack_i),
    .wbs_err_i('0),
    .wbs_rty_i('0),
    .wbs_cyc_o(wbs0_cyc_o)
  );

  wb_arbiter_2 #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .SELECT_WIDTH(4),
    .ARB_TYPE_ROUND_ROBIN(0),
    .ARB_LSB_HIGH_PRIORITY(0) // 设置为 0 的时候 1 号口的优先级更高，设置为 1 的时候 0 号口的优先级会更高
  ) wb_ExtRAM_arbiter_2 (
    .clk(sys_clk),
    .rst(sys_rst),
    // Wishbone master 0 input
    .wbm0_adr_i(wbs01_adr_o),
    .wbm0_dat_i(wbs01_dat_o),
    .wbm0_dat_o(wbs01_dat_i),
    .wbm0_we_i(wbs01_we_o),
    .wbm0_sel_i(wbs01_sel_o),
    .wbm0_stb_i(wbs01_stb_o),
    .wbm0_ack_o(wbs01_ack_i),
    .wbm0_err_o(),
    .wbm0_rty_o(),
    .wbm0_cyc_i(wbs01_cyc_o),
    // Wishbone master 1 input
    .wbm1_adr_i(wbs11_adr_o),
    .wbm1_dat_i(wbs11_dat_o),
    .wbm1_dat_o(wbs11_dat_i),
    .wbm1_we_i(wbs11_we_o),
    .wbm1_sel_i(wbs11_sel_o),
    .wbm1_stb_i(wbs11_stb_o),
    .wbm1_ack_o(wbs11_ack_i),
    .wbm1_err_o(),
    .wbm1_rty_o(),
    .wbm1_cyc_i(wbs11_cyc_o),
    // Wishbone slave output
    .wbs_adr_o(wbs1_adr_o),
    .wbs_dat_i(wbs1_dat_i),
    .wbs_dat_o(wbs1_dat_o),
    .wbs_we_o(wbs1_we_o),
    .wbs_sel_o(wbs1_sel_o),
    .wbs_stb_o(wbs1_stb_o),
    .wbs_ack_i(wbs1_ack_i),
    .wbs_err_i('0),
    .wbs_rty_i('0),
    .wbs_cyc_o(wbs1_cyc_o)
  );
  /* =========== Arbiter end =========== */

  /* =========== Slaves begin =========== */
  sram_controller #(
    .SRAM_ADDR_WIDTH(20),
    .SRAM_DATA_WIDTH(32)
  ) sram_controller_base (
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    // Wishbone slave (to MUX)
    .wb_cyc_i(wbs0_cyc_o),
    .wb_stb_i(wbs0_stb_o),
    .wb_ack_o(wbs0_ack_i),
    .wb_adr_i(wbs0_adr_o),
    .wb_dat_i(wbs0_dat_o),
    .wb_dat_o(wbs0_dat_i),
    .wb_sel_i(wbs0_sel_o),
    .wb_we_i (wbs0_we_o),

    // To SRAM chip
    .sram_addr(base_ram_addr),
    .sram_data(base_ram_data),
    .sram_ce_n(base_ram_ce_n),
    .sram_oe_n(base_ram_oe_n),
    .sram_we_n(base_ram_we_n),
    .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
    .SRAM_ADDR_WIDTH(20),
    .SRAM_DATA_WIDTH(32)
  ) sram_controller_ext (
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    // Wishbone slave (to MUX)
    .wb_cyc_i(wbs1_cyc_o),
    .wb_stb_i(wbs1_stb_o),
    .wb_ack_o(wbs1_ack_i),
    .wb_adr_i(wbs1_adr_o),
    .wb_dat_i(wbs1_dat_o),
    .wb_dat_o(wbs1_dat_i),
    .wb_sel_i(wbs1_sel_o),
    .wb_we_i (wbs1_we_o),

    // To SRAM chip
    .sram_addr(ext_ram_addr),
    .sram_data(ext_ram_data),
    .sram_ce_n(ext_ram_ce_n),
    .sram_oe_n(ext_ram_oe_n),
    .sram_we_n(ext_ram_we_n),
    .sram_be_n(ext_ram_be_n)
  );

  // 串口控制器模块
  // NOTE: 如果修改系统时钟频率，也需要修改此处的时钟频率参数
  uart_controller #(
    .CLK_FREQ(10_000_000),
    .BAUD    (115200)
  ) uart_controller (
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    .wb_cyc_i(wbs2_cyc_o),
    .wb_stb_i(wbs2_stb_o),
    .wb_ack_o(wbs2_ack_i),
    .wb_adr_i(wbs2_adr_o),
    .wb_dat_i(wbs2_dat_o),
    .wb_dat_o(wbs2_dat_i),
    .wb_sel_i(wbs2_sel_o),
    .wb_we_i (wbs2_we_o),

    // to UART pins
    .uart_txd_o(txd),
    .uart_rxd_i(rxd)
  );

  wire interrupt;

  wire [63:0] mtime;
  wire [63:0] mtimecmp;

  mtimer u_mtimer (
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    .interrupt_o(interrupt),

    .wb_cyc_i(wbs3_cyc_o),
    .wb_stb_i(wbs3_stb_o),
    .wb_ack_o(wbs3_ack_i),
    .wb_adr_i(wbs3_adr_o),
    .wb_dat_i(wbs3_dat_o),
    .wb_dat_o(wbs3_dat_i),
    .wb_sel_i(wbs3_sel_o),
    .wb_we_i (wbs3_we_o)
  );

  /* =========== Slaves end =========== */

  /***********************外设部分结束***************************/

endmodule

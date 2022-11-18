`default_nettype none

module thinpad_top (
    input wire clk_50M,     // 50MHz ʱ������
    input wire clk_11M0592, // 11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire push_btn,  // BTN5 ��ť���أ���������·������ʱΪ 1
    input wire reset_btn, // BTN6 ��λ��ť����������·������ʱΪ 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4����ť���أ�����ʱΪ 1
    input  wire [31:0] dip_sw,     // 32 λ���뿪�أ�������ON��ʱΪ 1
    output wire [15:0] leds,       // 16 λ LED�����ʱ 1 ����
    output wire [ 7:0] dpy0,       // ����ܵ�λ�źţ�����С���㣬��� 1 ����
    output wire [ 7:0] dpy1,       // ����ܸ�λ�źţ�����С���㣬��� 1 ����

    // CPLD ���ڿ������ź�
    output wire uart_rdn,        // �������źţ�����Ч
    output wire uart_wrn,        // д�����źţ�����Ч
    input  wire uart_dataready,  // ��������׼����
    input  wire uart_tbre,       // �������ݱ�־
    input  wire uart_tsre,       // ���ݷ�����ϱ�־

    // BaseRAM �ź�
    inout wire [31:0] base_ram_data,  // BaseRAM ���ݣ��� 8 λ�� CPLD ���ڿ���������
    output wire [19:0] base_ram_addr,  // BaseRAM ��ַ
    output wire [3:0] base_ram_be_n,  // BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ 0
    output wire base_ram_ce_n,  // BaseRAM Ƭѡ������Ч
    output wire base_ram_oe_n,  // BaseRAM ��ʹ�ܣ�����Ч
    output wire base_ram_we_n,  // BaseRAM дʹ�ܣ�����Ч

    // ExtRAM �ź�
    inout wire [31:0] ext_ram_data,  // ExtRAM ����
    output wire [19:0] ext_ram_addr,  // ExtRAM ��ַ
    output wire [3:0] ext_ram_be_n,  // ExtRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ 0
    output wire ext_ram_ce_n,  // ExtRAM Ƭѡ������Ч
    output wire ext_ram_oe_n,  // ExtRAM ��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,  // ExtRAM дʹ�ܣ�����Ч

    // ֱ�������ź�
    output wire txd,  // ֱ�����ڷ��Ͷ�
    input  wire rxd,  // ֱ�����ڽ��ն�

    // Flash �洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0] flash_a,  // Flash ��ַ��a0 ���� 8bit ģʽ��Ч��16bit ģʽ������
    inout wire [15:0] flash_d,  // Flash ����
    output wire flash_rp_n,  // Flash ��λ�źţ�����Ч
    output wire flash_vpen,  // Flash д�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,  // Flash Ƭѡ�źţ�����Ч
    output wire flash_oe_n,  // Flash ��ʹ���źţ�����Ч
    output wire flash_we_n,  // Flash дʹ���źţ�����Ч
    output wire flash_byte_n, // Flash 8bit ģʽѡ�񣬵���Ч����ʹ�� flash �� 16 λģʽʱ����Ϊ 1

    // USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB ������������������� dm9k_sd[7:0] ����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // ����������źţ��ο� DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // ͼ������ź�
    output wire [2:0] video_red,    // ��ɫ���أ�3 λ
    output wire [2:0] video_green,  // ��ɫ���أ�3 λ
    output wire [1:0] video_blue,   // ��ɫ���أ�2 λ
    output wire       video_hsync,  // ��ͬ����ˮƽͬ�����ź�
    output wire       video_vsync,  // ��ͬ������ֱͬ�����ź�
    output wire       video_clk,    // ����ʱ�����
    output wire       video_de      // ��������Ч�źţ���������������
);

  /* =========== Demo code begin =========== */

  // PLL ��Ƶʾ��
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // �ⲿʱ������
      // Clock out ports
      .clk_out1(clk_10M),  // ʱ����� 1��Ƶ���� IP ���ý���������
      .clk_out2(clk_20M),  // ʱ����� 2��Ƶ���� IP ���ý���������
      // Status and control signals
      .reset(reset_btn),  // PLL ��λ����
      .locked(locked)  // PLL ����ָʾ�����"1"��ʾʱ���ȶ���
                       // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
  );

  logic reset_of_clk10M;
  // �첽��λ��ͬ���ͷţ��� locked �ź�תΪ�󼶵�·�ĸ�λ reset_of_clk10M
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

  // ��ʹ���ڴ桢����ʱ��������ʹ���ź�
  // assign base_ram_ce_n = 1'b1;
  // assign base_ram_oe_n = 1'b1;
  // assign base_ram_we_n = 1'b1;

  // assign ext_ram_ce_n = 1'b1;
  // assign ext_ram_oe_n = 1'b1;
  // assign ext_ram_we_n = 1'b1;

  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  // ��������ӹ�ϵʾ��ͼ��dpy1 ͬ��
  // p=dpy0[0] // ---a---
  // c=dpy0[1] // |     |
  // d=dpy0[2] // f     b
  // e=dpy0[3] // |     |
  // b=dpy0[4] // ---g---
  // a=dpy0[5] // |     |
  // f=dpy0[6] // e     c
  // g=dpy0[7] // |     |
  //           // ---d---  p

  // // 7 ���������������ʾ���� number �� 16 ������ʾ�����������
  // logic [7:0] number;
  // SEG7_LUT segL (
  //     .oSEG1(dpy0),
  //     .iDIG (number[3:0])
  // );  // dpy0 �ǵ�λ�����
  // SEG7_LUT segH (
  //     .oSEG1(dpy1),
  //     .iDIG (number[7:4])
  // );  // dpy1 �Ǹ�λ�����

  // logic [15:0] led_bits;
  // assign leds = led_bits;

  // always_ff @(posedge push_btn or posedge reset_btn) begin
  //   if (reset_btn) begin  // ��λ���£����� LED Ϊ��ʼֵ
  //     led_bits <= 16'h1;
  //   end else begin  // ÿ�ΰ��°�ť���أ�LED ѭ������
  //     led_bits <= {led_bits[14:0], led_bits[15]};
  //   end
  // end

  // // ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
  // logic [7:0] ext_uart_rx;
  // logic [7:0] ext_uart_buffer, ext_uart_tx;
  // logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
  // logic ext_uart_start, ext_uart_avai;

  // assign number = ext_uart_buffer;

  // // ����ģ�飬9600 �޼���λ
  // async_receiver #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_r (
  //     .clk           (clk_50M),         // �ⲿʱ���ź�
  //     .RxD           (rxd),             // �ⲿ�����ź�����
  //     .RxD_data_ready(ext_uart_ready),  // ���ݽ��յ���־
  //     .RxD_clear     (ext_uart_clear),  // ������ձ�־
  //     .RxD_data      (ext_uart_rx)      // ���յ���һ�ֽ�����
  // );

  // assign ext_uart_clear = ext_uart_ready; // �յ����ݵ�ͬʱ�������־����Ϊ������ȡ�� ext_uart_buffer ��
  // always_ff @(posedge clk_50M) begin  // ���յ������� ext_uart_buffer
  //   if (ext_uart_ready) begin
  //     ext_uart_buffer <= ext_uart_rx;
  //     ext_uart_avai   <= 1;
  //   end else if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_avai <= 0;
  //   end
  // end
  // always_ff @(posedge clk_50M) begin  // �������� ext_uart_buffer ���ͳ�ȥ
  //   if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_tx <= ext_uart_buffer;
  //     ext_uart_start <= 1;
  //   end else begin
  //     ext_uart_start <= 0;
  //   end
  // end

  // // ����ģ�飬9600 �޼���λ
  // async_transmitter #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_t (
  //     .clk      (clk_50M),         // �ⲿʱ���ź�
  //     .TxD      (txd),             // �����ź����
  //     .TxD_busy (ext_uart_busy),   // ������æ״ָ̬ʾ
  //     .TxD_start(ext_uart_start),  // ��ʼ�����ź�
  //     .TxD_data (ext_uart_tx)      // �����͵�����
  // );

  // // ͼ�������ʾ���ֱ��� 800x600@75Hz������ʱ��Ϊ 50MHz
  // logic [11:0] hdata;
  // assign video_red   = hdata < 266 ? 3'b111 : 0;  // ��ɫ����
  // assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0;  // ��ɫ����
  // assign video_blue  = hdata >= 532 ? 2'b11 : 0;  // ��ɫ����
  // assign video_clk   = clk_50M;
  // vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
  //     .clk        (clk_50M),
  //     .hdata      (hdata),        // ������
  //     .vdata      (),             // ������
  //     .hsync      (video_hsync),
  //     .vsync      (video_vsync),
  //     .data_enable(video_de)
  // );
  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_10M;
  assign sys_rst = reset_of_clk10M;

  logic [31:0] if_PC;
  logic [31:0] if_inst;
  logic [3:0] if_master_state;
  logic [31:0] id_PC;
  logic [31:0] id_inst;
  logic [4:0] id_rs1;
  logic [4:0] id_rs2;
  logic [4:0] id_rd;
  logic id_alu_src;
  logic [3:0] id_alu_funct;
  logic [2:0] id_inst_type;
  logic [31:0] id_imm;
  logic [31:0] id_rf_rdata1;
  logic [31:0] id_rf_rdata2;
  logic [31:0] exe_PC;
  logic [31:0] exe_inst;
  logic [2:0] exe_inst_type;
  logic [31:0] id_branch_addr;
  logic [3:0] exe_alu_funct;
  logic exe_alu_src; // alu �ĵ� 2 �������� rdata_2��0���� imm��1��
  logic [31:0] exe_imm;
  logic [31:0] exe_rdata1;
  logic [31:0] exe_rdata2;
  logic [31:0] exe_alu_result;
  logic exe_alu_zero;
  logic [31:0] mem_inst;
  logic [2:0] mem_inst_type;
  logic mem_PC_src;
  logic [31:0] mem_alu_result;
  logic [31:0] mem_branch_addr;
  logic mem_ren;
  logic mem_wen;
  logic [31:0] mem_addr;
  logic [31:0] mem_wdata;
  logic mem_sel_byte;
  logic [31:0] mem_rdata;
  logic [3:0] mem_master_state;
  logic [31:0] mem_rf_wdata;
  logic [4:0] wb_rd;
  logic [31:0] wb_rf_wdata;
  logic wb_rf_wen;
  logic [4:0] stall;
  logic [4:0] flush;
  logic [1:0] rdata1_bypass;
  logic [1:0] rdata2_bypass;

  stall_controller stall_controller (
    .if_master_state_i(if_master_state),
    .mem_master_state_i(mem_master_state),
    .mem_master_wen(mem_wen),
    .mem_master_ren(mem_ren),
    .id_inst_i(id_inst),
    .id_inst_type_i(id_inst_type),
    .exe_inst_i(exe_inst),
    .exe_inst_type_i(exe_inst_type),
    .mem_inst_i(mem_inst),
    .mem_inst_type_i(mem_inst_type),
    .wb_rd_i(wb_rd),
    .wb_rf_wen_i(wb_rf_wen),
    .exe_alu_zero_i(exe_alu_zero),
    .id_rs1_data_i(after_bypass_id_rf_rdata1),
    .id_rs2_data_i(after_bypass_id_rf_rdata2),
    .stall_o(stall),
    .flush_o(flush),
    .rdata1_bypass_o(rdata1_bypass),
    .rdata2_bypass_o(rdata2_bypass)
  );

  logic [31:0] after_bypass_id_rf_rdata1;
  logic [31:0] after_bypass_id_rf_rdata2;
  assign after_bypass_id_rf_rdata1 = rdata1_bypass == 2'd0 ? id_rf_rdata1 : (rdata1_bypass == 2'd1 ? exe_alu_result : mem_rf_wdata);
  assign after_bypass_id_rf_rdata2 = rdata2_bypass == 2'd0 ? id_rf_rdata2 : (rdata2_bypass == 2'd1 ? exe_alu_result : mem_rf_wdata);

  logic branch;
  // assign branch = exe_inst_type === 3'b010 && ((exe_inst[14:12] === 3'b000 && exe_alu_zero===1)||(exe_inst[14:12] === 3'b001 && exe_alu_zero===0));
  // assign jump = !branch && (id_inst[6:0] === 7'b1101111 || id_inst[6:0] === 7'b1100111);
  // logic [31:0] jump_addr;
  // assign jump_addr = id_inst[6:0] == 7'b1100111 ? (after_bypass_id_rf_rdata1 + id_imm) & (-2) : id_PC + id_imm; 
  assign branch = flush_o[1];
  assign id_branch_addr = id_inst[6:0] == 7'b1100111 ? (after_bypass_id_rf_rdata1 + id_imm) & (-2) : id_PC + id_imm;

  PC_mux PC_mux(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .rst_addr_i(32'h8000_0000),
    .stall_i(stall[0]),
    .PC_src_i(branch),// BEQ, BNE, J
    .branch_addr_i(id_branch_addr),
    .PC_o(if_PC)
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

  inst_decoder inst_decoder(
    .inst_i(id_inst),
    .rs1_o(id_rs1),
    .rs2_o(id_rs2),
    .rd_o(id_rd),
    .alu_src_o(id_alu_src), // alu �ĵ� 2 �������� rdata_2��0������ imm��1��
    .alu_funct_o(id_alu_funct),
    .inst_type_o(id_inst_type),
    .imm_o(id_imm),
  );

  register_file_32 register_file (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .rd_i(wb_rd),
    .wdata_i(wb_rf_wdata),
    .we_i(wb_rf_wen),
    .rs1_i(id_rs1),
    .rs2_i(id_rs2),
    .rdata1_o(id_rf_rdata1),
    .rdata2_o(id_rf_rdata2)
  );

  ID_EXE_controller ID_EXE_controller(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[2]),
    .flush_i(flush[2]),
    .PC_i(id_PC),
    .inst_i(id_inst),
    .inst_type_i(id_inst_type),
    .alu_funct_i(id_alu_funct),
    .alu_src_i(id_alu_src),
    .imm_i(id_imm),
    .rdata1_i(after_bypass_id_rf_rdata1),
    .rdata2_i(after_bypass_id_rf_rdata2),
    .inst_o(exe_inst),
    .inst_type_o(exe_inst_type),
    .alu_funct_o(exe_alu_funct),
    .alu_src_o(exe_alu_src), 
    .imm_o(exe_imm),
    .rdata1_o(exe_rdata1),
    .rdata2_o(exe_rdata2),
    .PC_o(exe_PC)//AUIPC
  );

  ALU_32 ALU(
    .a((exe_inst[6:0] === 7'b0010111 || exe_inst_type === 3'b101) ? exe_PC : exe_rdata1),//AUIPC
    .b(exe_alu_src ? exe_imm : exe_rdata2),
    .op(exe_alu_funct),
    .y(exe_alu_result),
    .zero_o(exe_alu_zero)
  );

  EXE_MEM_controller EXE_MEM_controller(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[3]),
    .flush_i(flush[3]),
    .inst_i(exe_inst),
    .inst_type_i(exe_inst_type),
    .alu_result_i(exe_alu_result),
    .rdata2_i(exe_rdata2),
    .inst_o(mem_inst),
    .inst_type_o(mem_inst_type),
    .alu_result_o(mem_alu_result),
    .mem_ren_o(mem_ren), // �ǣ�1����0���� mem
    .mem_wen_o(mem_wen), // �ǣ�1����0��д mem
    .mem_addr_o(mem_addr), 
    .mem_wdata_o(mem_wdata),
    .sel_byte_o(mem_sel_byte)
  );

  MEM_WB_controller MEM_WB_controller(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall_i(stall[4]),
    .flush_i(flush[4]),
    .inst_i(mem_inst),
	  .inst_type_i(mem_inst_type),
    .alu_result_i(mem_alu_result),
    .mem_read_data_i(mem_rdata), // ���ڴ������
    .logic_rf_wdata_o(mem_rf_wdata),
    .rf_wen_o(wb_rf_wen),
    .rf_wdata_o(wb_rf_wdata),
    .rf_waddr_o(wb_rd)
  );

  /***********************���貿�ֿ�ʼ***************************/  
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

  master #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) cpu_if_master (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall(stall[0]),
    .addr_i(if_PC),
    .wdata_i('0),
    .wen_i(1'b0),
    .ren_i(1'b1),
    .sel_byte_i(1'b0), // �ֽڣ�1�������֣�0��
    .init(1'b1),
    .rdata_o(if_inst),
    .wb_cyc_o(wbm0_cyc_o),
    .wb_stb_o(wbm0_stb_o),
    .wb_ack_i(wbm0_ack_i),
    .wb_adr_o(wbm0_adr_o),
    .wb_dat_o(wbm0_dat_o),
    .wb_dat_i(wbm0_dat_i),
    .wb_sel_o(wbm0_sel_o),
    .wb_we_o (wbm0_we_o),
    .state_o(if_master_state)
  );

  master #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) cpu_mem_master (
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .stall(stall[3]),
    .addr_i(mem_alu_result),
    .wdata_i(mem_wdata),
    .wen_i(mem_wen),
    .ren_i(mem_ren),
    .sel_byte_i(mem_sel_byte), // �ֽڣ�1�������֣�0��
    .init(1'b0),
    .rdata_o(mem_rdata),
    .wb_cyc_o(wbm1_cyc_o),
    .wb_stb_o(wbm1_stb_o),
    .wb_ack_i(wbm1_ack_i),
    .wb_adr_o(wbm1_adr_o),
    .wb_dat_o(wbm1_dat_o),
    .wb_dat_i(wbm1_dat_i),
    .wb_sel_o(wbm1_sel_o),
    .wb_we_o (wbm1_we_o),
    .state_o(mem_master_state)
  );

  wb_arbiter_2 #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .SELECT_WIDTH(4),
    .ARB_TYPE_ROUND_ROBIN(0),
    .ARB_LSB_HIGH_PRIORITY(0) // ����Ϊ 0 ��ʱ�� 1 �ſڵ����ȼ����ߣ�����Ϊ 1 ��ʱ�� 0 �ſڵ����ȼ������
  ) wb_arbiter_2 (
    .clk(sys_clk),
    .rst(sys_rst),
    // Wishbone master 0 input
    .wbm0_adr_i(wbm0_adr_o),
    .wbm0_dat_i(wbm0_dat_o),
    .wbm0_dat_o(wbm0_dat_i),
    .wbm0_we_i(wbm0_we_o),
    .wbm0_sel_i(wbm0_sel_o),
    .wbm0_stb_i(wbm0_stb_o),
    .wbm0_ack_o(wbm0_ack_i),
    .wbm0_err_o(),
    .wbm0_rty_o(),
    .wbm0_cyc_i(wbm0_cyc_o),
    // Wishbone master 1 input
    .wbm1_adr_i(wbm1_adr_o),
    .wbm1_dat_i(wbm1_dat_o),
    .wbm1_dat_o(wbm1_dat_i),
    .wbm1_we_i(wbm1_we_o),
    .wbm1_sel_i(wbm1_sel_o),
    .wbm1_stb_i(wbm1_stb_o),
    .wbm1_ack_o(wbm1_ack_i),
    .wbm1_err_o(),
    .wbm1_rty_o(),
    .wbm1_cyc_i(wbm1_cyc_o),
    // Wishbone slave output
    .wbs_adr_o(wbm_adr_o),
    .wbs_dat_i(wbm_dat_i),
    .wbs_dat_o(wbm_dat_o),
    .wbs_we_o(wbm_we_o),
    .wbs_sel_o(wbm_sel_o),
    .wbs_stb_o(wbm_stb_o),
    .wbs_ack_i(wbm_ack_i),
    .wbs_err_i('0),
    .wbs_rty_i('0),
    .wbs_cyc_o(wbm_cyc_o)
  );

  /* =========== MUX begin =========== */
  wb_mux_3 wb_mux (
    .clk(sys_clk),
    .rst(sys_rst),

    // Master interface (to arbiter)
    .wbm_adr_i(wbm_adr_o),
    .wbm_dat_i(wbm_dat_o),
    .wbm_dat_o(wbm_dat_i),
    .wbm_we_i (wbm_we_o),
    .wbm_sel_i(wbm_sel_o),
    .wbm_stb_i(wbm_stb_o),
    .wbm_ack_o(wbm_ack_i),
    .wbm_err_o(),
    .wbm_rty_o(),
    .wbm_cyc_i(wbm_cyc_o),

    // Slave interface 0 (to BaseRAM controller)
    // Address range: 0x8000_0000 ~ 0x803F_FFFF
    .wbs0_addr    (32'h8000_0000),
    .wbs0_addr_msk(32'hFFC0_0000),

    .wbs0_adr_o(wbs0_adr_o),
    .wbs0_dat_i(wbs0_dat_i),
    .wbs0_dat_o(wbs0_dat_o),
    .wbs0_we_o (wbs0_we_o),
    .wbs0_sel_o(wbs0_sel_o),
    .wbs0_stb_o(wbs0_stb_o),
    .wbs0_ack_i(wbs0_ack_i),
    .wbs0_err_i('0),
    .wbs0_rty_i('0),
    .wbs0_cyc_o(wbs0_cyc_o),

    // Slave interface 1 (to ExtRAM controller)
    // Address range: 0x8040_0000 ~ 0x807F_FFFF
    .wbs1_addr    (32'h8040_0000),
    .wbs1_addr_msk(32'hFFC0_0000),

    .wbs1_adr_o(wbs1_adr_o),
    .wbs1_dat_i(wbs1_dat_i),
    .wbs1_dat_o(wbs1_dat_o),
    .wbs1_we_o (wbs1_we_o),
    .wbs1_sel_o(wbs1_sel_o),
    .wbs1_stb_o(wbs1_stb_o),
    .wbs1_ack_i(wbs1_ack_i),
    .wbs1_err_i('0),
    .wbs1_rty_i('0),
    .wbs1_cyc_o(wbs1_cyc_o),

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
    .wbs2_cyc_o(wbs2_cyc_o)
  );
  /* =========== MUX end =========== */

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

  // ���ڿ�����ģ��
  // NOTE: ����޸�ϵͳʱ��Ƶ�ʣ�Ҳ��Ҫ�޸Ĵ˴���ʱ��Ƶ�ʲ���
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
  /* =========== Slaves begin =========== */

  /***********************���貿�ֽ���***************************/

endmodule

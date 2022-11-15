`default_nettype none

module counter (
  // ʱ���븴λ�źţ�ÿ��ʱ��ģ�鶼�������
  input wire clk,
  input wire reset,

  // ���������ź�
  input wire trigger,

  // ��ǰ����ֵ
  output wire [3:0] count
);

reg [3:0] count_reg;
always_ff @ (posedge clk or posedge reset) begin
    if(reset) begin
        count_reg <= 4'd0;
    end else begin
        if (trigger && count_reg < 4'd15)
            count_reg <= count_reg + 4'd1;
    end
end
assign count = count_reg;

endmodule

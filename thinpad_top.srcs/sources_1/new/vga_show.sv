module vga_show (
    input wire[11:0] hdata,
    input wire[11:0] vdata,
    output reg[2:0] video_red,
    output reg[2:0] video_green,
    output reg[1:0] video_blue,
    output reg enb,
    output reg[18:0] addrb,
    input wire[7:0] doutb
);

always_comb begin
    enb = 1;
    addrb = 19'b0;
    // if(hdata >= 0 && hdata <= 799 && vdata >= 0 && vdata <= 599) begin
    //     // video_red = show[(vdata - 300) / 16 * 5 + (hdata - 360) / 16] * 7;
    //     // video_green = show[(vdata - 300) / 16 * 5 + (hdata - 360) / 16] * 7;
    //     // video_blue = show[(vdata - 300) / 16 * 5 + (hdata - 360) / 16] * 3;
    //     enb = 1;
    addrb = (hdata - 0) / 2 + (vdata - 0) / 2 * 400  + 1;
    //     video_red = doutb[2:0];
    //     video_green = doutb[5:3];
    //     video_blue = doutb[7:6];
    // end
    

end

assign video_red   = hdata < 266 ? 3'b111 : 0;  // 红色竖条
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0;  // 绿色竖条
assign video_blue  = hdata >= 532 ? 2'b11 : 0;  // 蓝色竖条
    
endmodule
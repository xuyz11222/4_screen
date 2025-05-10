/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2023/03/23
*Module Name:
*File Name:
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.0
*Signal description
*1) I_ input
*2) O_ output
*3) IO_ input output
*4) S_ system internal signal
*5) _n activ low
*6) _dg debug signal 
*7) _r delay or register
*8) _s state mechine
*********************************************************************/
/*********raw10_unpacket_2lane RAW���ݸ�ʽתΪRAW10,֮������λ��ʵ��RAW8***********
--�汾��1.0
*********************************************************************/

module raw10_unpacket_2lane (
    input wire        I_clk,
    input wire        I_rst_n,

    input wire        I_csi_frame_start,//synthesis keep
    input wire        I_csi_frame_end,//synthesis keep
    input wire        I_csi_valid,//synthesis keep
    input wire[31:0]  I_csi_data,//synthesis keep

	input wire[9:0]   I_camera_black_level,

    output reg        O_raw8_frame_start,
    output reg        O_raw8_frame_end,
    output reg        O_raw8_valid,
    output reg [31:0] O_raw8_data
);

    reg        S_csi_valid_1d;//synthesis keep
    reg        S_csi_valid_2d;//synthesis keep
    reg[31:0]  S_csi_data_1d;//synthesis keep
    reg[31:0]  S_csi_data_2d;  //synthesis keep
    reg[2:0]   S_cnt;         //synthesis keep
    reg        S_raw10_wr_en;//synthesis keep
    reg[39:0]  S_raw10_wr_data;//synthesis keep
    wire[9:0]  S_fifo_rd_num;//synthesis keep
    reg        S_fifo_rd_en;//synthesis keep
    wire       S_fifo_empty;//synthesis keep
    reg        S_raw8_valid;//synthesis keep
    reg[39:0]  S_raw8_data;//synthesis keep
    wire[39:0] S_fifo_rd_data;//synthesis keep


//ͬ������MIPI���������I_csi_valid����������ÿ��I_csi_valid ����1��
    always @(posedge I_clk) begin
        O_raw8_frame_start <= I_csi_frame_start;
        O_raw8_frame_end   <= I_csi_frame_end;
        
        S_csi_valid_1d     <=  I_csi_valid;
        S_csi_valid_2d     <=  S_csi_valid_1d;

        S_csi_data_1d      <=  I_csi_data ;
        S_csi_data_2d      <=  S_csi_data_1d;
    end

    always @(posedge I_clk) begin
        if({S_csi_valid_2d,S_csi_valid_1d,I_csi_valid}==3'b101)begin//��S_csi_valid_2d��I_csi_validͬʱ��Ч��S_csi_valid_2d����ǰһ����Ч32Bit I_csi_valid���������µ�32bit
            if(S_cnt == 3'd4) //һ�����ڽ���
                S_cnt <= 3'd0;
            else
                S_cnt <= S_cnt + 3'd1;
        end
        else if({S_csi_valid_2d,S_csi_valid_1d,I_csi_valid}==3'b000)
                S_cnt <= 3'd0;
    end


always @(posedge I_clk) begin
    if({S_csi_valid_2d,S_csi_valid_1d,I_csi_valid}==3'b101)begin
        case(S_cnt)
        3'd0:begin
                S_raw10_wr_en          <= 1'b1;
                S_raw10_wr_data[39:30] <= {S_csi_data_2d[31:24],I_csi_data[25:24]}; ///P0
                S_raw10_wr_data[29:20] <= {S_csi_data_2d[23:16],I_csi_data[27:26]}; ///P1
                S_raw10_wr_data[19:10] <= {S_csi_data_2d[15 :8],I_csi_data[29:28]}; ///P2
                S_raw10_wr_data[9:0]   <= {S_csi_data_2d[7  :0],I_csi_data[31:30]}; ///P3
        end
        3'd1:begin
                S_raw10_wr_en          <= 1'b1;
                S_raw10_wr_data[39:30] <= {S_csi_data_2d[23:16],I_csi_data[17:16]}; ///P4
                S_raw10_wr_data[29:20] <= {S_csi_data_2d[15 :8],I_csi_data[19:18]}; ///P5
                S_raw10_wr_data[19:10] <= {S_csi_data_2d[7  :0],I_csi_data[21:20]}; ///P6
                S_raw10_wr_data[9:0]   <= {I_csi_data   [31:24],I_csi_data[23:22]}; ///P7
        end
        3'd2:begin
                S_raw10_wr_en          <= 1'b1;
                S_raw10_wr_data[39:30] <= {S_csi_data_2d[15 :8],I_csi_data[9:8]};   ///P8
                S_raw10_wr_data[29:20] <= {S_csi_data_2d[7  :0],I_csi_data[11:10]}; ///P9
                S_raw10_wr_data[19:10] <= {I_csi_data   [31:24],I_csi_data[13:12]}; ///P10
                S_raw10_wr_data[9:0]   <= {I_csi_data   [23:16],I_csi_data[15:14]}; ///P11
        end
        3'd3:begin
                S_raw10_wr_en          <= 1'b1;
                S_raw10_wr_data[39:30] <= {S_csi_data_2d[7  :0],I_csi_data[1:0]}; ///P12
                S_raw10_wr_data[29:20] <= {I_csi_data   [31:24],I_csi_data[3:2]}; ///P13
                S_raw10_wr_data[19:10] <= {I_csi_data   [23:16],I_csi_data[5:4]}; ///P14
                S_raw10_wr_data[9:0]   <= {I_csi_data   [15 :8],I_csi_data[7:6]}; ///P15
        end
        3'd4:begin
                S_raw10_wr_en          <= 1'b0;
                S_raw10_wr_data[39:30] <= 'd0;
                S_raw10_wr_data[29:20] <= 'd0;
                S_raw10_wr_data[19:10] <= 'd0;
                S_raw10_wr_data[9:0]   <= 'd0;
        end
        endcase
    end 
    else begin
                S_raw10_wr_en          <= 1'b0;
                S_raw10_wr_data[39:30] <= 'd0;
                S_raw10_wr_data[29:20] <= 'd0;
                S_raw10_wr_data[19:10] <= 'd0;
                S_raw10_wr_data[9:0]   <= 'd0;
    end
end

always @(posedge I_clk ) begin
    O_raw8_data <=  {S_raw10_wr_data[39:32],S_raw10_wr_data[29:22],S_raw10_wr_data[19:12],S_raw10_wr_data[9:2]};
    O_raw8_valid <= S_raw10_wr_en;
end



/*
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            S_fifo_rd_en <= 1'b0;
        else
            if(S_fifo_empty)
                S_fifo_rd_en <= 1'b0;
            else if(S_fifo_rd_num == 'd310)
                S_fifo_rd_en <= 1'b1;
            else
                S_fifo_rd_en <= S_fifo_rd_en;
    end

    always @(posedge I_clk) begin
        S_raw8_valid       <= S_fifo_rd_en & (~S_fifo_empty);
        O_raw8_valid       <= S_raw8_valid;

        S_raw8_data[39:30] <= (S_fifo_rd_data[39:30] - I_camera_black_level) >> 2;
        S_raw8_data[29:20] <= (S_fifo_rd_data[29:20] - I_camera_black_level) >> 2;
        S_raw8_data[19:10] <= (S_fifo_rd_data[19:10] - I_camera_black_level) >> 2;
        S_raw8_data[9:0]   <= (S_fifo_rd_data[9:0]   - I_camera_black_level) >> 2;
    end

reg [11:0]line_cnt;//synthesis keep

    always @(posedge I_clk ) begin
        if((O_raw8_valid==1'b0)&(S_raw8_valid == 1'b1))
            line_cnt <= line_cnt + 1'b1;
        else if(I_csi_frame_start)
            line_cnt <=0;
    end

    assign O_raw8_data = {S_raw8_data[37:30],S_raw8_data[27:20],S_raw8_data[17:10],S_raw8_data[7:0]};

    w40_d512_fifo u_w40_d512_fifo(
        .clk        ( I_clk             ),
        .rst        ( I_csi_frame_start ),

        .we         ( S_raw10_wr_en     ),
        .di         ( S_raw10_wr_data   ),
        .full_flag  (   ),
        .wrusedw    (   ),

        .re         ( S_fifo_rd_en      ),
        .dout       ( S_fifo_rd_data    ),
        .empty_flag ( S_fifo_empty      ),
        .rdusedw    ( S_fifo_rd_num     )
    );
*/

    
endmodule
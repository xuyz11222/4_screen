
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2019/12/17
*Module Name:rgb_to_hdmi
*File Name:rgb_to_hdmi.v
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.1
*Signal description
*1) I_ input
*2) O_ output
*3) IO_ input output
*3) S_ system internal signal
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/

/*********uitpg(video test Pattern Generator)������Ƶ������***********
--�汾��1.1
--��������������Ƶ�uitpg(video test Pattern Generator)������Ƶ������
--1.�����࣬ռ�ü����߼���Դ������ṹ�������߼�����Ͻ�
--2.�ò�����Ƶ������ͨ���������������䡢��ɫ���巽�񣬲�������ͼ��
*********************************************************************/

`timescale 1ns / 1ns//����ʱ��̶�/����

module uitpg
(
input			I_tpg_clk, //ϵͳʱ��
input           I_tpg_rstn,//ϵͳ��λ
input			I_tpg_vs,  //��ͬ������
input           I_tpg_hs,  //��ͬ������
input           I_tpg_de,  //��Ƶ������Ч����	
output			O_tpg_vs,  //��ͬ�����
output          O_tpg_hs,  //��ͬ�����
output          O_tpg_de,  //��Ƶ������Ч���	 
output [23:0]	O_tpg_data //��Ч��������
);

reg         tpg_vs_r   = 1'b0; //��vs�źżĴ�
reg         tpg_hs_r   = 1'b0; //��hs�źżĴ�
reg [7 :0]  grid_data  = 8'd0; //grid�巽��Ĵ���
reg [23:0]  color_bar  = 24'd0;//RGB �����Ĵ���
reg [10:0]  dis_mode   = 11'd0;//��ʾģʽ�Ĵ���
reg [7 :0]  r_reg      = 8'd0; //��Ĵ���
reg [7 :0]  g_reg      = 8'd0; //�̼Ĵ���
reg [7 :0]  b_reg      = 8'd0; //���Ĵ���


always @(posedge I_tpg_clk)begin
    tpg_vs_r <= I_tpg_vs; //��vs�źżĴ�һ��
    tpg_hs_r <= I_tpg_hs; //��hs�źżĴ�һ��
end

reg [11:0]v_cnt = 12'd0; //��Ƶ��ֱ�����м�����
reg [11:0]h_cnt = 12'd0; //��Ƶˮƽ�����м�����

//h_cnt������ģ��
always @(posedge I_tpg_clk)
	h_cnt <= I_tpg_de ? h_cnt + 1'b1 : 12'd0; //��������Ч����,��de��Ч������ h_cnt=0

//v_cnt������ģ��
always @(posedge I_tpg_clk)
  if(I_tpg_vs) //ͨ��vs����ͬ����λ
	v_cnt <= 12'd0; //����v_cnt=0
  else 
	v_cnt <= ((!tpg_hs_r)&&I_tpg_hs) ? v_cnt + 1'b1 : v_cnt; //hs�źŵ������أ�v_cnt���������ַ�ʽ���Բ���hs��Ч�Ǹߵ�ƽ���ǵ͵�ƽ�����,v_cnt ��Ƶ��ֱ�����м�����������������

//��ʾģʽ�л�
always @(posedge I_tpg_clk)
   if(I_tpg_rstn==1'b0)
	dis_mode <= 0;
   else 
    dis_mode <= ((!tpg_vs_r)&&I_tpg_vs) ? dis_mode + 1'b1 : dis_mode;

//grid_data������	
always @(posedge I_tpg_clk)begin
	grid_data <= ((v_cnt[4]==1'b1) ^ (h_cnt[4]==1'b1)) ? 8'h00 : 8'hff; //�����С16*16���ڰ׽���
end

//RGB����������
always @(posedge I_tpg_clk)
begin
	if(h_cnt==260)
	color_bar	<=	24'hff0000;//��
	else if(h_cnt==420)
	color_bar	<=	24'h00ff00;//��
	else if(h_cnt==580)
	color_bar	<=	24'h0000ff;//��
	else if(h_cnt==740)
	color_bar	<=	24'hff00ff;//��
	else if(h_cnt==900)
	color_bar	<=	24'hffff00;//��
	else if(h_cnt==1060)
	color_bar	<=	24'h00ffff;//����
	else if(h_cnt==1220)
	color_bar	<=	24'hffffff;//��
	else if(h_cnt==1380)
	color_bar	<=	24'h000000;//��
	else
	color_bar	<=	color_bar;
end

//����ͼ�����
always @(posedge I_tpg_clk)begin
    case(dis_mode[10:7])//��ȡ��λ�������л���ʾ�ٶ�
        4'd0:begin
			r_reg <= 0; 
			b_reg <= 0;
			g_reg <= 0;
		end
        4'd1:begin
			r_reg <= 8'b11111111;               //��
            g_reg <= 8'b11111111;
            b_reg <= 8'b11111111;
		end
        4'd2,4'd3:begin//��������״̬�����ͬͼ��
			r_reg <= 8'b11111111;              //��
            g_reg <= 0;
            b_reg <= 0;  
		end			  
        4'd4,4'd5:begin//��������״̬�����ͬͼ��
			r_reg <= 0;                         //��
            g_reg <= 8'b11111111;
            b_reg <= 0; 
		end					  
        4'd6:begin     
			r_reg <= 0;                         //��
            g_reg <= 0;
            b_reg <= 8'b11111111;
		end
        4'd7,4'd8:begin  //��������״̬�����ͬͼ��   
			r_reg <= grid_data;                 //����
            g_reg <= grid_data;
            b_reg <= grid_data;
		end					  
        4'd9:begin    
			r_reg <= h_cnt[7:0];                //ˮƽ����
            g_reg <= h_cnt[7:0];
            b_reg <= h_cnt[7:0];
		end
        4'd10,4'd11:begin //��������״̬�����ͬͼ��
			r_reg <= v_cnt[7:0];                 //��ֱ����
            g_reg <= v_cnt[7:0];
            b_reg <= v_cnt[7:0];
		end
        4'd12:begin     
			r_reg <= v_cnt[7:0];                 //�촹ֱ����
            g_reg <= 0;
            b_reg <= 0;
		end
        4'd13:begin     
			r_reg <= 0;                          //�̴�ֱ����
            g_reg <= h_cnt[7:0];
            b_reg <= 0;
		end
        4'd14:begin     
			r_reg <= 0;                          //����ֱ����
            g_reg <= 0;
            b_reg <= h_cnt[7:0];			
		end
        4'd15:begin     
			r_reg <= color_bar[23:16];           //����
            g_reg <= color_bar[15:8];
            b_reg <= color_bar[7:0];			
		end				  
        endcase
end

assign O_tpg_data = {r_reg,g_reg,b_reg};//����ͼ��RGB�������
assign O_tpg_vs = I_tpg_vs;  //VSͬ���ź�
assign O_tpg_hs = I_tpg_hs;  //HSͬ���ź�
assign O_tpg_de = I_tpg_de;  //DE������Ч�ź�

endmodule

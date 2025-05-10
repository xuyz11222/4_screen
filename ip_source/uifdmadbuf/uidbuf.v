
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2021/10/15
*File Name: uidbuf.v
*Description: 
*Declaration:
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 3.1
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

/*********uidbuf(fdma data buffer controller)����FDMA�ź�ʱ��Ļ��������***********
--�汾��3.1
--��������������Ƶ�uidbuf(fdma data buffer controller)����FDMA�ź�ʱ��Ļ��������
--1.�����࣬ռ�ü����߼���Դ������ṹ�������߼�����Ͻ�
--2.��дͨ��������FIFO��С������λ�����������ã��ʺ����ڻ���RGBʱ�����Ƶ���ݻ�������������
*********************************************************************/

`timescale 1ns / 1ns

module uidbuf#(
parameter  integer                   VIDEO_ENABLE   = 1,//ʹ����Ƶ֧֡�ֹ���
parameter  integer                   ENABLE_WRITE   = 1,//ʹ��дͨ��
parameter  integer                   ENABLE_READ    = 1,//ʹ�ܶ�ͨ��

parameter  integer                   AXI_DATA_WIDTH = 128,//AXI��������λ��
parameter  integer                   AXI_ADDR_WIDTH = 32, //AXI���ߵ�ַλ��

parameter  integer                   W_BUFDEPTH     = 2048, //дͨ��AXI����FIFO�����С
parameter  integer                   W_DATAWIDTH    = 32,  //дͨ��AXI��������λ���С
parameter  [AXI_ADDR_WIDTH -1'b1: 0] W_BASEADDR     = 0, //дͨ�������ڴ���ʼ��ַ
parameter  integer                   W_DSIZEBITS    = 24, //дͨ�����û������ݵ�������ַ��С������FDMA DBUF ����֡������ʼ��ַ
parameter  integer                   W_XSIZE        = 1920, //дͨ������X��������ݴ�С��������ÿ��FDMA ��������ݳ���
parameter  integer                   W_XSTRIDE      = 1920, //дͨ������X�����Strideֵ����Ҫ����ͼ�λ���Ӧ��
parameter  integer                   W_YSIZE        = 1080, //дͨ������Y����ֵ�������˽����˶��ٴ�XSIZE����
parameter  integer                   W_XDIV         = 2, //дͨ����X�������ݲ��ΪXDIV�δ��䣬����FIFO��ʹ��
parameter  integer                   W_BUFSIZE      = 3, //дͨ������֡�����С��Ŀǰ���֧��128֡�������޸Ĳ���֧�ָ�������

parameter  integer                   R_BUFDEPTH     = 2048, //��ͨ��AXI����FIFO�����С
parameter  integer                   R_DATAWIDTH    = 32, //��ͨ��AXI��������λ���С
parameter  [AXI_ADDR_WIDTH -1'b1: 0] R_BASEADDR     = 0, //��ͨ�������ڴ���ʼ��ַ
parameter  integer                   R_DSIZEBITS    = 24, //��ͨ�����û������ݵ�������ַ��С������FDMA DBUF ����֡������ʼ��ַ
parameter  integer                   R_XSIZE        = 1920, //��ͨ������X��������ݴ�С��������ÿ��FDMA ��������ݳ���
parameter  integer                   R_XSTRIDE      = 1920, //��ͨ������X�����Strideֵ����Ҫ����ͼ�λ���Ӧ��
parameter  integer                   R_YSIZE        = 1080, //��ͨ������Y����ֵ�������˽����˶��ٴ�XSIZE����
parameter  integer                   R_XDIV         = 2, //��ͨ����X�������ݲ��ΪXDIV�δ��䣬����FIFO��ʹ��
parameter  integer                   R_BUFSIZE      = 3 //��ͨ������֡�����С��Ŀǰ���֧��128֡�������޸Ĳ���֧�ָ�������
)
(
input wire                                  I_ui_clk, //��FDMA AXI����ʱ��һ��
input wire                                  I_ui_rstn, //��FDMA AXI��λһ��
//sensor input -W_FIFO--------------
input wire                                  I_W_clk, //�û�д���ݽӿ�ʱ�� 
input wire                                  I_W_FS, //�û�д���ݽӿ�ͬ���źţ����ڷ���Ƶ֡һ������Ϊ1
input wire                                  I_W_wren, //�û�д����ʹ��
input wire     [W_DATAWIDTH-1'b1 : 0]       I_W_data, //�û�д����
output reg     [7   :0]                     O_W_sync_cnt =0, //дͨ��BUF֡ͬ�����
input  wire    [7   :0]                     I_W_buf, // дͨ��BUF֡ͬ������
output wire                                 O_W_full,

//----------fdma signals write-------       
output wire    [AXI_ADDR_WIDTH-1'b1: 0]     O_fdma_waddr, //FDMAдͨ����ַ
output wire                                 O_fdma_wareq, //FDMAдͨ������
output wire    [15  :0]                     O_fdma_wsize, //FDMAдͨ��һ��FDMA�Ĵ����С                                     
input  wire                                 I_fdma_wbusy, //FDMA����BUSY״̬��AXI��������д����   
output wire    [AXI_DATA_WIDTH-1'b1:0]      O_fdma_wdata, //FDMAд����
input  wire                                 I_fdma_wvalid, //FDMA д��Ч
output wire                                 O_fdma_wready, //FDMAд׼���ã��û�����д����
output reg     [7   :0]                     O_fmda_wbuf =0, //FDMA��д֡��������
output wire                                 O_fdma_wirq, //FDMAһ��д��ɵ����ݴ�����ɺ󣬲����жϡ�   
//----------fdma signals read-------  
input  wire                                 I_R_clk, //�û������ݽӿ�ʱ��
input  wire                                 I_R_FS, //�û������ݽӿ�ͬ���źţ����ڷ���Ƶ֡һ������1
input  wire                                 I_R_rden, //�û�������ʹ��
output wire    [R_DATAWIDTH-1'b1 : 0]       O_R_data, //�û�������
output reg     [7   :0]                     O_R_sync_cnt =0, //��ͨ��BUF֡ͬ�����
input  wire    [7   :0]                     I_R_buf, //дͨ��BUF֡ͬ������
output wire                                 O_R_empty,

output wire    [2*AXI_ADDR_WIDTH-1'b1: 0]     O_fdma_raddr, // FDMA��ͨ����ַ
output wire                                 O_fdma_rareq, // FDMA��ͨ������
output wire    [15: 0]                      O_fdma_rsize, // FDMA��ͨ��һ��FDMA�Ĵ����С                                     
input  wire                                 I_fdma_rbusy, // FDMA����BUSY״̬��AXI�������ڶ�����     
input  wire    [2*AXI_DATA_WIDTH-1'b1:0]      I_fdma_rdata, // FDMA������
input  wire                                 I_fdma_rvalid, // FDMA ����Ч
output wire                                 O_fdma_rready, // FDMA��׼���ã��û����Զ�����
output reg     [7  :0]                      O_fmda_rbuf =0, // FDMA�Ķ�֡��������
output wire                                 O_fdma_rirq // FDMAһ�ζ���ɵ����ݴ�����ɺ󣬲����ж�
); 
   

// ����Log2
function integer clog2;
  input integer value;
  begin 
    for (clog2=0; value>0; clog2=clog2+1)
      value = value>>1;
    end 
  endfunction


//FDMA��д״̬����״ֵ̬��һ��4��״ֵ̬���� 
localparam S_IDLE  =  2'd0;  
localparam S_RST   =  2'd1;  
localparam S_DATA1 =  2'd2;   
localparam S_DATA2 =  2'd3; 

// ͨ������ͨ��ʹ�ܣ������Ż������������
generate  if(ENABLE_WRITE == 1)begin : FDMA_WRITE_ENABLE

localparam WFIFO_DEPTH = W_BUFDEPTH; //дͨ��FIFO���
localparam W_WR_DATA_COUNT_WIDTH = clog2(WFIFO_DEPTH); //����FIFO��дͨ��λ��
localparam W_RD_DATA_COUNT_WIDTH = clog2(WFIFO_DEPTH*W_DATAWIDTH/AXI_DATA_WIDTH);//clog2(WFIFO_DEPTH/(AXI_DATA_WIDTH/W_DATAWIDTH))+1;

localparam WYBUF_SIZE           = (W_BUFSIZE - 1'b1); //дͨ����Ҫ��ɶ��ٴ�XSIZE����
localparam WY_BURST_TIMES       = (W_YSIZE*W_XDIV); //дͨ����Ҫ��ɵ�FDMA burst ����������XDIV���ڰ�XSIZE�ֽ��δ���
localparam FDMA_WX_BURST        = (W_XSIZE*W_DATAWIDTH/AXI_DATA_WIDTH)/W_XDIV; //FDMA BURST һ�εĴ�С
localparam WX_BURST_ADDR_INC    = (W_XSIZE*(W_DATAWIDTH/8))/W_XDIV; //FDMAÿ��burst֮��ĵ�ַ����
localparam WX_LAST_ADDR_INC     = (W_XSTRIDE-W_XSIZE)*(W_DATAWIDTH/8) + WX_BURST_ADDR_INC; //����strideֵ����������һ�ε�ַ

(*mark_debug = "true"*) (* KEEP = "TRUE" *) wire  W_wren_ri = I_W_wren; 

assign                                  O_fdma_wready = 1'b1;
reg                                     O_fdma_wareq_r= 1'b0;
reg                                     W_FIFO_Rst=0; 
(*mark_debug = "true"*) (* KEEP = "TRUE" *)wire                                    W_FS;
(*mark_debug = "true"*) (* KEEP = "TRUE" *)reg [1 :0]                              W_MS=0; 
reg [W_DSIZEBITS-1'b1:0]                W_addr=0; 
(*mark_debug = "true"*) (* KEEP = "TRUE" *)reg [15:0]                              W_bcnt=0; 
(*mark_debug = "true"*) (* KEEP = "TRUE" *)wire[W_RD_DATA_COUNT_WIDTH-1'b1 :0]     W_rcnt;
(*mark_debug = "true"*) (* KEEP = "TRUE" *)reg                                     W_REQ=0; 
(*mark_debug = "true"*) (* KEEP = "TRUE" *)reg [5 :0]                              wirq_dly_cnt =0;
reg [3 :0]                              wdiv_cnt =0;
reg [7 :0]                              wrst_cnt =0;
reg [7 :0]                              O_fmda_wbufn;

(*mark_debug = "true"*) (* KEEP = "TRUE" *) wire wirq= O_fdma_wirq;

assign O_fdma_wsize = FDMA_WX_BURST;
assign O_fdma_wirq = (wirq_dly_cnt>0);

assign O_fdma_waddr = W_BASEADDR + {O_fmda_wbufn,W_addr};//����FPGA�߼����˷��Ƚϸ��ӣ����ͨ�����ø�λ��ַʵ�ֻ�������

reg [1:0] W_MS_r =0;
always @(posedge I_ui_clk) W_MS_r <= W_MS;

//ÿ��FDMA DBUF ���һ֡���ݴ���󣬲����жϣ�����жϳ���60�����ڵ�uiclk,������ӳٱ����㹻ZYNQ IP��ʶ������ж�
always @(posedge I_ui_clk) begin
    if(I_ui_rstn == 1'b0)begin
        wirq_dly_cnt <= 6'd0;
        O_fmda_wbuf <=0;
    end
    else if((W_MS_r == S_DATA2) && (W_MS == S_IDLE))begin
        wirq_dly_cnt <= 60;
        O_fmda_wbuf <= O_fmda_wbufn;
    end
    else if(wirq_dly_cnt >0)
        wirq_dly_cnt <= wirq_dly_cnt - 1'b1;
end

//֡ͬ����������Ƶ��Ч
fs_cap #
(
.VIDEO_ENABLE(VIDEO_ENABLE)
)
fs_cap_W0
(
 .I_clk(I_ui_clk),
 .I_rstn(I_ui_rstn),
 .I_vs(I_W_FS),
 .O_fs_cap(W_FS)
);

assign O_fdma_wareq = O_fdma_wareq_r;

//дͨ��״̬��������4��״ֵ̬����
 always @(posedge I_ui_clk) begin
    if(!I_ui_rstn)begin
        W_MS         <= S_IDLE;
        W_FIFO_Rst   <= 0;
        W_addr       <= 0;
        O_W_sync_cnt <= 0;
        W_bcnt       <= 0;
        wrst_cnt     <= 0;
        wdiv_cnt     <= 0;
        O_fmda_wbufn    <= 0;
        O_fdma_wareq_r <= 1'd0;
    end   
    else begin
      case(W_MS)
        S_IDLE:begin
          W_addr <= 0;
          W_bcnt <= 0;
          wrst_cnt <= 0;
          wdiv_cnt <=0;
          if(W_FS) begin //֡ͬ�������ڷ���Ƶ����һ�㳣��Ϊ1
            W_MS <= S_RST;
            if(O_W_sync_cnt < WYBUF_SIZE) //���֡ͬ��������
                O_W_sync_cnt <= O_W_sync_cnt + 1'b1; 
            else 
                O_W_sync_cnt <= 0;  
          end
       end
       S_RST:begin//֡ͬ�������ڷ���Ƶ����ֱ������,������Ƶ���ݣ���ͬ��ÿһ֡�����Ҹ�λ����FIFO
           O_fmda_wbufn <= I_W_buf;
           wrst_cnt <= wrst_cnt + 1'b1;
           if((VIDEO_ENABLE == 1) && (wrst_cnt < 40))
                W_FIFO_Rst <= 1;
           else if((VIDEO_ENABLE == 1) && (wrst_cnt < 100))
                W_FIFO_Rst <= 0;
           else if(O_fdma_wirq == 1'b0) begin
                W_MS <= S_DATA1;
           end
       end
        S_DATA1:begin //����дFDMA����
          if(I_fdma_wbusy == 1'b0 && W_REQ )begin
             O_fdma_wareq_r  <= 1'b1; 
          end 
          else if(I_fdma_wbusy == 1'b1) begin
             O_fdma_wareq_r  <= 1'b0;
             W_MS    <= S_DATA2;
          end          
         end
        S_DATA2:begin //д��Ч����
            if(I_fdma_wbusy == 1'b0)begin
                if(W_bcnt == WY_BURST_TIMES - 1'b1) //�ж��Ƿ������
                    W_MS <= S_IDLE;
                else begin
                    if(wdiv_cnt < W_XDIV - 1'b1)begin//�����XSIZE���˷ִδ��䣬һ��XSIZEҲ��ҪXDIV��FDMA��ɴ���
                        W_addr <= W_addr +  WX_BURST_ADDR_INC;  //�����ַ����
                        wdiv_cnt <= wdiv_cnt + 1'b1;
                     end
                    else begin
                        W_addr <= W_addr + WX_LAST_ADDR_INC; //�������һ�ε�ַ���������һ�ε�ַ����stride ����
                        wdiv_cnt <= 0;
                    end
                    W_bcnt <= W_bcnt + 1'b1;
                    W_MS    <= S_DATA1;
                end 
            end
         end
         default: W_MS <= S_IDLE; 
       endcase
    end
 end 

//дͨ��������FIFO��������ԭ�����xpm_fifo_async fifo����FIFO�洢��������ֵ�ﵽһ������һ������һ��FDMA��burst���ɷ�������
wire W_rbusy;
always@(posedge I_ui_clk)     
     W_REQ  <= (W_rcnt > FDMA_WX_BURST - 2)&&(~W_rbusy); 


wfifo1 u_wfifo(
.rst((I_ui_rstn == 1'b0) || (W_FIFO_Rst == 1'b1)), //asynchronous port,active hight
.clkw(I_W_clk),  //write clock
.clkr(I_ui_clk),  //read clock
.we(I_W_wren),  //write enable,active hight
.di(I_W_data),  //write data
.re(I_fdma_wvalid),  //read enable,active hight
.dout(O_fdma_wdata),  //read data
//.valid(),  //read data valid flag
.full_flag(O_W_full),  //fifo full flag
//.empty_flag(),  //fifo empty flag
//.afull(),  //fifo almost full flag
//.aempty(),  //fifo almost empty flag
//.wrusedw(W_rcnt),  //stored data number in fifo
.rdusedw(W_rcnt) //available data number for read      
) ;

end
else begin : FDMA_WRITE_DISABLE

//----------fdma signals write-------       
assign O_fdma_waddr = 0;
assign O_fdma_wareq = 0;
assign O_fdma_wsize = 0;                                    
assign O_fdma_wdata = 0;
assign O_fdma_wready = 0;
assign O_fdma_wirq = 0; 
assign O_W_full = 0;

end
endgenerate

generate  if(ENABLE_READ == 1)begin : FDMA_READ// ͨ������ͨ��ʹ�ܣ������Ż������������
localparam RYBUF_SIZE           = (R_BUFSIZE - 1'b1); //��ͨ����Ҫ��ɶ��ٴ�XSIZE����
localparam RY_BURST_TIMES       = (R_YSIZE*R_XDIV); //��ͨ����Ҫ��ɵ�FDMA burst ����������XDIV���ڰ�XSIZE�ֽ��δ���
localparam FDMA_RX_BURST        = (R_XSIZE*R_DATAWIDTH/AXI_DATA_WIDTH)/R_XDIV; //FDMA BURST һ�εĴ�С
localparam RX_BURST_ADDR_INC    = (R_XSIZE*(R_DATAWIDTH/8))/R_XDIV; //FDMAÿ��burst֮��ĵ�ַ����
localparam RX_LAST_ADDR_INC     = (R_XSTRIDE-R_XSIZE)*(R_DATAWIDTH/8) + RX_BURST_ADDR_INC; //����strideֵ����������һ�ε�ַ

localparam RFIFO_DEPTH = R_BUFDEPTH*R_DATAWIDTH/AXI_DATA_WIDTH;//R_BUFDEPTH/(AXI_DATA_WIDTH/R_DATAWIDTH);
localparam R_WR_DATA_COUNT_WIDTH = clog2(RFIFO_DEPTH); //��ͨ��FIFO ���벿�����
localparam R_RD_DATA_COUNT_WIDTH = clog2(R_BUFDEPTH); //дͨ��FIFO����������

assign                                  O_fdma_rready = 1'b1;
reg                                     O_fdma_rareq_r= 1'b0;
reg                                     R_FIFO_Rst=0; 
wire                                    R_FS;
reg [1 :0]                              R_MS=0; 
reg [R_DSIZEBITS-1'b1:0]                R_addr=0; 
reg [15:0]                              R_bcnt=0; 
wire[R_WR_DATA_COUNT_WIDTH-1'b1 :0]     R_wcnt;
reg                                     R_REQ=0; 
reg [5 :0]                              rirq_dly_cnt =0;
reg [3 :0]                              rdiv_cnt =0;
reg [7 :0]                              rrst_cnt =0;
reg [7 :0]                              O_fmda_rbufn;
assign O_fdma_rsize = FDMA_RX_BURST;
assign O_fdma_rirq = (rirq_dly_cnt>0);

assign O_fdma_raddr = R_BASEADDR + {O_fmda_rbufn,R_addr};//����FPGA�߼����˷��Ƚϸ��ӣ����ͨ�����ø�λ��ַʵ�ֻ�������

reg [1:0] R_MS_r =0;
always @(posedge I_ui_clk) R_MS_r <= R_MS;

//ÿ��FDMA DBUF ���һ֡���ݴ���󣬲����жϣ�����жϳ���60�����ڵ�uiclk,������ӳٱ����㹻ZYNQ IP��ʶ������ж�
always @(posedge I_ui_clk) begin
    if(I_ui_rstn == 1'b0)begin
        rirq_dly_cnt <= 6'd0;
        O_fmda_rbuf <=0;
    end
    else if((R_MS_r == S_DATA2) && (R_MS == S_IDLE))begin
        rirq_dly_cnt <= 60;
        O_fmda_rbuf <= O_fmda_rbufn;
    end
    else if(rirq_dly_cnt >0)
        rirq_dly_cnt <= rirq_dly_cnt - 1'b1;
end

//֡ͬ����������Ƶ��Ч
fs_cap #
(
.VIDEO_ENABLE(VIDEO_ENABLE)
)
fs_cap_R0
(
  .I_clk(I_ui_clk),
  .I_rstn(I_ui_rstn),
  .I_vs(I_R_FS),
  .O_fs_cap(R_FS)
);

assign O_fdma_rareq = O_fdma_rareq_r;

//��ͨ��״̬��������4��״ֵ̬����
 always @(posedge I_ui_clk) begin
   if(!I_ui_rstn)begin
        R_MS          <= S_IDLE;
        R_FIFO_Rst   <= 0;
        R_addr       <= 0;
        O_R_sync_cnt <= 0;
        R_bcnt       <= 0;
        rrst_cnt     <= 0;
        rdiv_cnt      <= 0;
        O_fmda_rbufn    <= 0;
        O_fdma_rareq_r  <= 1'd0;
    end   
    else begin
      case(R_MS) //֡ͬ�������ڷ���Ƶ����һ�㳣��Ϊ1
        S_IDLE:begin
          R_addr <= 0;
          R_bcnt <= 0;
          rrst_cnt <= 0;
          rdiv_cnt <=0;
          if(R_FS) begin
            R_MS <= S_RST;
            if(O_R_sync_cnt < RYBUF_SIZE) //���֡ͬ��������������Ҫ�ö�ͨ����֡ͬ����ʱ��ʹ��
                O_R_sync_cnt <= O_R_sync_cnt + 1'b1; 
            else 
                O_R_sync_cnt <= 0;  
          end
       end
       S_RST:begin//֡ͬ�������ڷ���Ƶ����ֱ������,������Ƶ���ݣ���ͬ��ÿһ֡�����Ҹ�λ����FIFO
           O_fmda_rbufn <= I_R_buf;
           rrst_cnt <= rrst_cnt + 1'b1;
           if((VIDEO_ENABLE == 1) && (rrst_cnt < 40))
                R_FIFO_Rst <= 1;
           else if((VIDEO_ENABLE == 1) && (rrst_cnt < 100))
                R_FIFO_Rst <= 0;
           else if(O_fdma_rirq == 1'b0) begin
                R_MS <= S_DATA1;
           end
       end
       S_DATA1:begin 
         if(I_fdma_rbusy == 1'b0 && R_REQ)begin
            O_fdma_rareq_r  <= 1'b1;  
         end
         else if(I_fdma_rbusy == 1'b1) begin
            O_fdma_rareq_r  <= 1'b0;
            R_MS    <= S_DATA2;
         end         
        end
        S_DATA2:begin //д��Ч����
            if(I_fdma_rbusy == 1'b0)begin
                if(R_bcnt == RY_BURST_TIMES - 1'b1) //�ж��Ƿ������
                    R_MS <= S_IDLE;
                else begin
                    if(rdiv_cnt < R_XDIV - 1'b1)begin//�����XSIZE���˷ִδ��䣬һ��XSIZEҲ��ҪXDIV��FDMA��ɴ���
                        R_addr <= R_addr +  RX_BURST_ADDR_INC;  //�����ַ����
                        rdiv_cnt <= rdiv_cnt + 1'b1;
                     end
                    else begin
                        R_addr <= R_addr + RX_LAST_ADDR_INC; //�������һ�ε�ַ���������һ�ε�ַ����stride ����
                        rdiv_cnt <= 0;
                    end
                    R_bcnt <= R_bcnt + 1'b1;
                    R_MS    <= S_DATA1;
                end 
            end
         end
         default:R_MS <= S_IDLE;
      endcase
   end
end 

//��ͨ��������FIFO��������ԭ�����xpm_fifo_async fifo����FIFO�洢�ռ����㹻���࣬����һ��FDMA��burst���ɷ�������
wire R_wbusy;
always@(posedge I_ui_clk)      
     R_REQ  <= (R_wcnt < FDMA_RX_BURST - 2)&&(~R_wbusy);


rfifo1 u_rfifo(
.rst((I_ui_rstn == 1'b0) || (W_FIFO_Rst == 1'b1)), //asynchronous port,active hight
.clkw(I_ui_clk),  //write clock
.clkr(I_R_clk),  //read clock
.we(I_fdma_rvalid),  //write enable,active hight
.di(I_fdma_rdata),  //write data
.re(I_R_rden),  //read enable,active hight
.dout(O_R_data),  //read data
//.valid(),  //read data valid flag
//.full_flag(),  //fifo full flag
.empty_flag(O_R_empty),  //fifo empty flag
//.afull(),  //fifo almost full flag
//.aempty(),  //fifo almost empty flag
.wrusedw(R_wcnt) //stored data number in fifo
//.rdusedw(W_rcnt) //available data number for read      
) ;

end
else begin : FDMA_READ_DISABLE
   
assign O_fdma_raddr = 0;
assign O_fdma_rareq = 0;
assign O_fdma_rsize = 0;                                    
//assign I_fdma_rdata = 0;
assign O_fdma_rready = 0;
assign O_fdma_rirq = 0; 
assign O_R_empty   = 1'b0;

end
endgenerate

endmodule


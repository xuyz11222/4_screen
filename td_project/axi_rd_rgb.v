 
module axi_rgb #( 
parameter  integer                   VIDEO_ENABLE   = 1,//使能视频帧支持功能

parameter  integer                   AXI_DATA_WIDTH = 128,//AXI总线数据位宽
parameter  integer                   AXI_ADDR_WIDTH = 32, //AXI总线地址位
 
parameter  integer                   R_BUFDEPTH     = 2048, //读通道AXI设置FIFO缓存大小
parameter  integer                   R_DATAWIDTH    = 32, //读通道AXI设置数据位宽大小
parameter  [AXI_ADDR_WIDTH -1'b1: 0] R_BASEADDR     = 0, //读通道设置内存起始地址
parameter  integer                   R_DSIZEBITS    = 24, //读通道设置缓存数据的增量地址大小，用于FDMA DBUF 计算帧缓存起始地址
parameter  integer                   R_XSIZE        = 1920, //读通道设置X方向的数据大小，代表了每次FDMA 传输的数据长度
parameter  integer                   R_XSTRIDE      = 1920, //读通道设置X方向的Stride值，主要用于图形缓存应用
parameter  integer                   R_YSIZE        = 1080, //读通道设置Y方向值，代表了进行了多少次XSIZE传输
parameter  integer                   R_XDIV         = 2, //读通道对X方向数据拆分为XDIV次传输，减少FIFO的使用
parameter  integer                   R_BUFSIZE      = 3 //读通道设置帧缓存大小，目前最大支持128帧，可以修改参数支持更缓存数
)(
input wire                                  I_ui_clk, //和FDMA AXI总线时钟一致
input wire                                  I_ui_rstn, //和FDMA AXI复位一致
input wire                                  cs,            
//----------fdma signals read-------  
input  wire                                 I_R_clk, //用户读数据接口时钟
input  wire                                 I_R_FS, //用户读数据接口同步信号，对于非视频帧一般设置1
input  wire                                 I_R_rden, //用户读数据使能
input  wire                             vtc_de_valid,
output reg     [15  :0]       O_R_data, //用户读数据
output reg     [7   :0]                     O_R_sync_cnt =0, //读通道BUF帧同步输出
input  wire    [7   :0]                     I_R_buf, //写通道BUF帧同步输入
output wire                                 O_R_empty,

output wire    [AXI_ADDR_WIDTH-1'b1: 0]     O_fdma_raddr, // FDMA读通道地址
output wire                                 O_fdma_rareq, // FDMA读通道请求
output wire    [15: 0]                      O_fdma_rsize, // FDMA读通道一次FDMA的传输大小                                     
input  wire                                 I_fdma_rbusy, // FDMA处于BUSY状态，AXI总线正在读操作     
input  wire    [AXI_DATA_WIDTH-1'b1:0]      I_fdma_rdata, // FDMA读数据
input  wire                                 I_fdma_rvalid, // FDMA 读有效
output wire                                 O_fdma_rready, // FDMA读准备好，用户可以读数据
output wire                                 O_fdma_rdone, // FDMA读好了，用户可以改变接口
output reg     [7  :0]                      O_fmda_rbuf =0, // FDMA的读帧缓存号输出
output wire                                 O_fdma_rirq, // FDMA一次读完成的数据传输完成后，产生中断

input wire     [26 :0]                      x_add            ,
input wire     [26 :0]                      y_add            ,

input          [11:0]                       col_size         ,
output                                      shift_en






);



function integer clog2;
  input integer value;
  begin 
    for (clog2=0; value>0; clog2=clog2+1)
      value = value>>1;
    end 
  endfunction


//FDMA读写状态机的状态值，一般4个状态值即可 
localparam S_IDLE  =  2'd0;  
localparam S_RST   =  2'd1;  
localparam S_DATA1_1 =  2'd2;   
localparam S_DATA2_1 =  2'd3; 
localparam S_WAIT_1=   3'd5;
localparam S_DATA1_2 =  3'd6;   
localparam S_DATA2_2 =  3'd7; 
localparam S_WAIT_2 =  4'd8;







localparam RYBUF_SIZE           = (R_BUFSIZE - 1'b1); //读通道需要完成多少次XSIZE操作
localparam RY_BURST_TIMES       = (R_YSIZE*R_XDIV); //读通道需要完成的FDMA burst 操作次数，XDIV用于把XSIZE分解多次传输
localparam FDMA_RX_BURST        = (R_XSIZE*R_DATAWIDTH/AXI_DATA_WIDTH)/R_XDIV; //FDMA BURST 一次的大小
localparam RX_BURST_ADDR_INC    = (R_XSIZE*(R_DATAWIDTH/8))/R_XDIV; //FDMA每次burst之后的地址增加
localparam RX_LAST_ADDR_INC     = (R_XSTRIDE-R_XSIZE)*(R_DATAWIDTH/8) + RX_BURST_ADDR_INC; //根据stride值计算出来最后一次地址

localparam RFIFO_DEPTH = R_BUFDEPTH*R_DATAWIDTH/AXI_DATA_WIDTH;//R_BUFDEPTH/(AXI_DATA_WIDTH/R_DATAWIDTH);
localparam R_WR_DATA_COUNT_WIDTH = clog2(RFIFO_DEPTH); //读通道FIFO 输入部分深度
localparam R_RD_DATA_COUNT_WIDTH = clog2(R_BUFDEPTH); //写通道FIFO输出部分深度

reg      [19:0]                           shift_cnt;

assign                                  O_fdma_rready =(R_MS==S_WAIT_1|R_MS==S_WAIT_2)&&( I_fdma_rbusy == 1'b0 && R_REQ);
assign                                  shift_en=(shift_cnt!=0);
reg                                     O_fdma_rareq_r= 1'b0;
reg                                     R_FIFO_Rst=0; 
wire                                    R_FS;
reg [3 :0]                              R_MS=0; 
reg [R_DSIZEBITS-1'b1:0]                R_addr=0; 
reg [15:0]                              R_bcnt=0; 
wire[R_WR_DATA_COUNT_WIDTH-1'b1 :0]     R_wcnt;
reg                                     R_REQ=0; 
reg [5 :0]                              rirq_dly_cnt =0;
reg [3 :0]                              rdiv_cnt =0;
reg [7 :0]                              rrst_cnt =0;
reg [7 :0]                              O_fmda_rbufn;
reg [26 :0]                             x_add1   ;
reg [26 :0]                             y_add1   ;
reg [26 :0]                             x_now    ;
reg [26 :0]                             y_now    ;
reg [26 :0]                             y_inital ;
wire                                   ud_rfifo_en;
reg                                    ud_rfifo_en1;
wire [255:0]                            rd_data;
reg                                     fdma_rdone_r=0;
reg  cs_r;
reg         [11:0]                       col_size_r;




assign O_fdma_rsize = FDMA_RX_BURST;
assign O_fdma_rirq = (rirq_dly_cnt>0);

assign O_fdma_raddr = R_BASEADDR + {O_fmda_rbufn,R_addr};//由于FPGA逻辑做乘法比较复杂，因此通过设置高位地址实现缓存设置


reg [1:0] R_MS_r =0;
always @(posedge I_ui_clk) R_MS_r <= R_MS;

//每次FDMA DBUF 完成一帧数据传输后，产生中断，这个中断持续60个周期的uiclk,这里的延迟必须足够ZYNQ IP核识别到这个中断
always @(posedge I_ui_clk) begin
    if(I_ui_rstn == 1'b0)begin
        rirq_dly_cnt <= 6'd0;
        O_fmda_rbuf <=0;
    end
    else if((R_MS_r == S_DATA2_2) && (R_MS == S_IDLE))begin
        rirq_dly_cnt <= 60;
        O_fmda_rbuf <= O_fmda_rbufn;
    end
    else if(rirq_dly_cnt >0)
        rirq_dly_cnt <= rirq_dly_cnt - 1'b1;
end

always @(posedge I_ui_clk) begin
y_inital <=y_now[26:15]*(R_XSIZE*(R_DATAWIDTH/8));
    
end

always @(posedge I_ui_clk) begin
shift_cnt<={shift_cnt[18:0],R_MS==S_RST};  
    
end











//帧同步，对于视频有效
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
assign O_fdma_rdone = fdma_rdone_r;


//读通道状态机，采用4个状态值描述
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
        fdma_rdone_r    <= 1'b0;
        x_add1  <=0;
        y_add1  <=0;
        y_now   <=0;
        col_size_r<=0;
    end   
    else begin
      case(R_MS) //帧同步，对于非视频数据一般常量为1
        S_IDLE:begin
          fdma_rdone_r    <= 1'b0;
          R_addr <= 0;
          R_bcnt <= 0;
          rrst_cnt <= 0;
          rdiv_cnt <=0;
          
           
          if(R_FS) begin
            R_MS <= S_RST;
            if(O_R_sync_cnt < RYBUF_SIZE) //输出帧同步计数器，当需要用读通道做帧同步的时候使用
                O_R_sync_cnt <= O_R_sync_cnt + 1'b1; 
            else 
                O_R_sync_cnt <= 0;  
          end
       end
       S_RST:begin//帧同步，对于非视频数据直接跳过,对于视频数据，会同步每一帧，并且复位数据FIFO
           O_fmda_rbufn <= I_R_buf;
           x_add1  <=x_add ;    
          y_add1  <=y_add ;    
          y_now   <=y_add ;    
          col_size_r<=col_size;
           
           
           
           
           rrst_cnt <= rrst_cnt + 1'b1;
           if((VIDEO_ENABLE == 1) && (rrst_cnt < 40))
                R_FIFO_Rst <= 1;
           else if((VIDEO_ENABLE == 1) && (rrst_cnt < 100))
                R_FIFO_Rst <= 0;
           else if(O_fdma_rirq == 1'b0) begin
                R_MS <= S_WAIT_1;
           end
       end
       S_DATA1_1:begin 
         if(I_fdma_rbusy == 1'b0 && R_REQ)begin
            O_fdma_rareq_r  <= 1'b1;  
         end
         else if(I_fdma_rbusy == 1'b1) begin
            O_fdma_rareq_r  <= 1'b0;
            R_MS    <=S_DATA2_1;
         end         
        end
        S_DATA2_1:begin //写有效数据
            if(I_fdma_rbusy == 1'b0)begin
            fdma_rdone_r    <= 1'b1;
                if(R_bcnt == col_size_r- 1'b1) //判断是否传输完毕
                    R_MS <= S_IDLE;
                else begin
                    if(rdiv_cnt < R_XDIV - 1'b1)begin//如果对XSIZE做了分次传输，一个XSIZE也需要XDIV次FDMA完成传输
                        R_addr <= R_addr +  RX_BURST_ADDR_INC;  //计算地址增量
                        rdiv_cnt <= rdiv_cnt + 1'b1;
                     
                     end
                    else begin
                        R_addr <=  y_inital; //计算最后一次地址增量，最后一次地址根据stride 计算
                        rdiv_cnt <= 0;
                        y_now    <= y_now + y_add1;
                    end
                    R_bcnt <= R_bcnt + 1'b1;
                    R_MS    <= S_WAIT_1;
                end 
            end
         end
         S_WAIT_1:begin
         if(cs )begin
         R_MS    <=S_DATA1_1;
         fdma_rdone_r    <= 1'b0;    
         end
         end
         S_DATA1_2:begin 
         if(I_fdma_rbusy == 1'b0 && R_REQ)begin
            O_fdma_rareq_r  <= 1'b1;  
         end
         else if(I_fdma_rbusy == 1'b1) begin
            O_fdma_rareq_r  <= 1'b0;
            R_MS    <= S_DATA2_2;
         end         
        end
        S_DATA2_2:begin //写有效数据
            if(I_fdma_rbusy == 1'b0)begin
                fdma_rdone_r    <= 1'b1;   
                if(R_bcnt == col_size_r - 1'b1) //判断是否传输完毕
                    R_MS <= S_IDLE;
                else begin
                    if(rdiv_cnt < R_XDIV - 1'b1)begin//如果对XSIZE做了分次传输，一个XSIZE也需要XDIV次FDMA完成传输
                        R_addr <= R_addr +  RX_BURST_ADDR_INC;  //计算地址增量
                        rdiv_cnt <= rdiv_cnt + 1'b1;
                     
                     end
                    else begin
                        R_addr <= y_inital; //计算最后一次地址增量，最后一次地址根据stride 计算
                        rdiv_cnt <= 0;
                        y_now    <= y_now + y_add1;
                    end
                    R_bcnt <= R_bcnt + 1'b1;
                    R_MS    <= S_WAIT_1;
                end 
            end
         end
         S_WAIT_2:begin
         if(cs )begin
         R_MS    <=S_DATA1_2;
         fdma_rdone_r    <= 1'b0;
         end
         end
         default:R_MS <= S_IDLE;
      endcase
   end
end 

//读通道的数据FIFO，采用了原语调用xpm_fifo_async fifo，当FIFO存储空间有足够空余，满足一次FDMA的burst即可发出请求
wire R_wbusy;
always@(posedge I_ui_clk)      
     R_REQ  <= (R_wcnt <FDMA_RX_BURST - 2);


rfifo1 u_rfifo(
.rst((I_ui_rstn == 1'b0) || (R_FIFO_Rst == 1'b1)), //asynchronous port,active hight
.clkw(I_ui_clk),  //write clock
.clkr(I_R_clk),  //read clock
.we(I_fdma_rvalid),  //write enable,active hight
.di(I_fdma_rdata),  //write data
.re(ud_rfifo_en),  //read enable,active hight
.dout(rd_data),  //read data
//.valid(),  //read data valid flag
//.full_flag(),  //fifo full flag
.empty_flag(O_R_empty),  //fifo empty flag
//.afull(),  //fifo almost full flag
//.aempty(),  //fifo almost empty flag
.wrusedw(R_wcnt) //stored data number in fifo
//.rdusedw(W_rcnt) //available data number for read      
) ;



 //以下代码需要注意时序设计，在正确的时序输出
    reg [15:0] mem [0:15];
    reg [7 :0] ud_rdata_d1;//synthesis keep
   // reg  vtc_user_d1;//synthesis keep
   // reg  vtc_last_d1;//synthesis keep
    reg  I_R_rden_d1; //synthesis keep
    reg [26:0] x_now1 ;

   

 //   always @(posedge I_R_clk) begin
 //           I_R_rden_d1 <= I_R_rden;
 //   end

    // 当I_R_rden = 1 ud_rdata_cnt =1 读1个数据，但是ud_rfifo_en延迟1个周期输出1，fifo再延迟1个周期更新数据

assign   ud_rfifo_en =  (x_now[18:0]+x_add1+x_add1>2**19 -1&&x_now[18:0]+x_add1<=2**19 -1);


    always @(posedge I_R_clk) begin
        x_now1 <= x_now;
    end
    always @(posedge I_R_clk) begin
        ud_rfifo_en1 <= ud_rfifo_en;
    end
    
    always @(posedge I_R_clk) begin
        if(I_R_rden)begin
        O_R_data <= mem[x_now[18:15]];
        end
    end
    
    always @(posedge I_R_clk) begin
            if(I_R_rden)
                x_now <= x_now + x_add1;
            else 
                x_now <= 0;
        end
        
    
    
     always @(posedge I_R_clk) begin
        if(ud_rfifo_en1)begin
        mem[15]<=    rd_data[255:240];
        mem[14]<=    rd_data[239:224];
        mem[13]<=    rd_data[223:208];
        mem[12]<=    rd_data[207:192];
        mem[11]<=    rd_data[191:176];
        mem[10]<=    rd_data[175:160];
        mem[9]<=    rd_data[159:144];
        mem[8]<=    rd_data[143:128];
        mem[7]<=    rd_data[127:112];
        mem[6]<=    rd_data[111: 96];
        mem[5]<=   rd_data[ 95: 80];
        mem[4]<=   rd_data[ 79: 64];
        mem[3]<=   rd_data[ 63: 48];
        mem[2]<=   rd_data[ 47: 32];
        mem[1]<=   rd_data[ 31: 16];
        mem[0]<=   rd_data[ 15:  0];
        
        end
        
        
        
        
        
        
    end



endmodule



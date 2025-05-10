module read_register#(
parameter integer   AXI_ADDR_WIDTH =29,
parameter integer   AXI_DATA_WIDTH =256
)(
    
input               clk             ,
input               rst_n           ,
input               ready1          ,
input               ready2          ,
input               ready3          ,
input               ready4          ,
input               ready5          ,
input               ready6          ,
input               done1           ,
input               done2           ,
input               done3           ,
input               done4           ,
input               done5           ,
input               done6           ,
output reg  [5:0]   cs              ,  

//axi接口
output  reg   [AXI_ADDR_WIDTH-1 : 0]          O_fdma_raddr   ,//synthesis keep// FDMA读通道地址
output  reg                                  O_fdma_rareq   ,//synthesis keep// FDMA读通道请求
output  reg  [15 : 0]                        O_fdma_rsize   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
input                                       i_fdma_rbusy   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 				
input   [AXI_DATA_WIDTH-1 :0]               i_fdma_rdata	 ,//synthesis keep// FDMA读数据
input                                       i_fdma_rvalid  ,//synthesis keep// FDMA 读有效



//app1

input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_raddr1   ,//synthesis keep// FDMA读通道地址
input                                     I_fdma_rareq1   ,//synthesis keep// FDMA读通道请求
input     [15 : 0]                        I_fdma_rsize1   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
output    reg                                O_fdma_rbusy1   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 				
output    reg [AXI_DATA_WIDTH-1 :0]          O_fdma_rdata1	 ,//synthesis keep// FDMA读数据
output    reg                                O_fdma_rvalid1  ,//synthesis keep// FDMA 读有效


//app2

input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_raddr2   ,//synthesis keep// FDMA读通道地址
input                                     I_fdma_rareq2   ,//synthesis keep// FDMA读通道请求
input     [15 : 0]                        I_fdma_rsize2   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
output     reg                               O_fdma_rbusy2   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 				
output   reg [AXI_DATA_WIDTH-1 :0]           O_fdma_rdata2	 ,//synthesis keep// FDMA读数据
output   reg                                 O_fdma_rvalid2 ,//synthesis keep// FDMA 读有效

//app3

input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_raddr3   ,//synthesis keep// FDMA读通道地址
input                                     I_fdma_rareq3   ,//synthesis keep// FDMA读通道请求
input     [15 : 0]                        I_fdma_rsize3   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
output    reg                                O_fdma_rbusy3   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 				
output    reg [AXI_DATA_WIDTH-1 :0]          O_fdma_rdata3	 ,//synthesis keep// FDMA读数据
output    reg                                O_fdma_rvalid3  ,//synthesis keep// FDMA 读有效


//app4

input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_raddr4   ,//synthesis keep// FDMA读通道地址
input                                     I_fdma_rareq4   ,//synthesis keep// FDMA读通道请求
input     [15 : 0]                        I_fdma_rsize4   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
output    reg                                O_fdma_rbusy4   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 				
output    reg [AXI_DATA_WIDTH-1 :0]          O_fdma_rdata4	 ,//synthesis keep// FDMA读数据
output    reg                                O_fdma_rvalid4  ,//synthesis keep// FDMA 读有效


//app5

input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_raddr5   ,//synthesis keep// FDMA读通道地址
input                                     I_fdma_rareq5   ,//synthesis keep// FDMA读通道请求
input     [15 : 0]                        I_fdma_rsize5   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
output    reg                                O_fdma_rbusy5   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 				
output    reg [AXI_DATA_WIDTH-1 :0]          O_fdma_rdata5	 ,//synthesis keep// FDMA读数据
output    reg                                O_fdma_rvalid5  ,//synthesis keep// FDMA 读有效


//app6

input     [AXI_ADDR_WIDTH-1 : 0]          I_fdma_raddr6   ,//synthesis keep// FDMA读通道地址
input                                     I_fdma_rareq6   ,//synthesis keep// FDMA读通道请求
input     [15 : 0]                        I_fdma_rsize6   ,//synthesis keep// FDMA读通道一次FDMA的传输大小                                      
output    reg                                O_fdma_rbusy6   ,//synthesis keep// FDMA处于BUSY状态，AXI总线正在读操作 				
output    reg [AXI_DATA_WIDTH-1 :0]          O_fdma_rdata6	 ,//synthesis keep// FDMA读数据
output    reg                               O_fdma_rvalid6  //synthesis keep// FDMA 读有效



 );
 

 
reg  [4:0]  rd_state;
 
 
localparam S_wait1=4'd0 ;
localparam S_determine1=4'd1 ;
localparam S_read1=4'd2 ;
localparam S_wait2=4'd3;
localparam S_determine2=4'd4 ;
localparam S_read2=4'd5 ; 
localparam S_wait3=4'd6 ;
localparam S_determine3=4'd7 ;
localparam S_read3=4'd8 ;
localparam S_wait4=4'd9;
localparam S_determine4=4'd10 ;
localparam S_read4=4'd11 ;
localparam S_wait5=4'd12 ;
localparam S_determine5=4'd13 ;
localparam S_read5=4'd14 ;
localparam S_wait6=4'd15;
localparam S_determine6=5'd16 ;
localparam S_read6=5'd17 ;

always @(posedge clk) begin
   if(!rst_n)begin
        rd_state          <= S_wait1;
        
    end   
    else begin
    case(rd_state)
    S_wait1:
    begin
    if(ready1)begin
     rd_state          <= S_determine1;
    
    end
     else if(ready2)begin
     rd_state          <= S_determine2;
     

     end
  else if(ready3)begin
  rd_state          <= S_determine3;
  

  end
  else if(ready4)begin
  rd_state          <= S_determine4;
  

  end
  else if(ready5)begin
  rd_state          <= S_determine5;
  

  end
//  else if(ready6)begin
//  rd_state          <= S_determine6;
  

//    end
   

    end
    S_determine1:
    begin
    rd_state          <= S_read1;
    
    
    end
    
    
    S_read1:
    begin
    if  (done1) begin
        rd_state          <= S_wait2;
    end
    
    
    
    end
    
    S_wait2:
    begin
     if(ready2)begin
     rd_state          <= S_determine2;
    
    end
    else if(ready3)begin
    rd_state          <= S_determine3;
    

    end
    else if(ready4)begin
    rd_state          <= S_determine4;
    
  
    end
    else if(ready5)begin
    rd_state          <= S_determine5;
    
 
    end
 //   else if(ready6)begin
 //   rd_state          <= S_determine6;
 //    
 //
 //   end
     else if(ready1)begin
     rd_state          <= S_determine1;
     

     end
     

     
     
   
    
    end
    
    S_determine2:
    begin
    rd_state          <= S_read2;
    
    
    end
    S_read2:
    begin
      if  (done2) begin
        rd_state          <= S_wait3;
    end
    
    
    
    end
    
    S_wait3:
    begin
     if(ready3)begin
     rd_state          <= S_determine3;
    
    end
    else if(ready4)begin
    rd_state          <= S_determine4;
    

    end
    else if(ready5)begin
    rd_state          <= S_determine5;
    

    end
//    else if(ready6)begin
//    rd_state          <= S_determine6;
//    
//
 //    end
     else if(ready1)begin
     rd_state          <= S_determine1;
     

     end
     else if(ready2)begin
     rd_state          <= S_determine2;
     

     end
     

     
     
   
    
    end
    
    S_determine3:
    begin
    rd_state          <= S_read3;
    
    
    end
    S_read3:
    begin
      if  (done3) begin
        rd_state          <= S_wait4;
    end
    
    
    
    end
    
      S_wait4:
    begin
     if(ready4)begin
     rd_state          <= S_determine4;
    
    end
     else if(ready5)begin
     rd_state          <= S_determine5;
     
 
     end
 //    else if(ready6)begin
 //    rd_state          <= S_determine6;
 //    
 //
 //    end
     else if(ready1)begin
     rd_state          <= S_determine1;
     

     end
     else if(ready2)begin
     rd_state          <= S_determine2;
     

     end
     else if(ready3)begin
     rd_state          <= S_determine3;
     

     end
     

     
     
   
    
    end
    
    S_determine4:
    begin
    rd_state          <= S_read4;
    
    
    end
    S_read4:
    begin
      if  (done4) begin
        rd_state          <= S_wait5;
    end
    
    
    
    end
    
     S_wait5:
    begin
     if(ready5)begin
     rd_state          <= S_determine5;
    
    end
   //  else if(ready6)begin
   //  rd_state          <= S_determine6;
   //  
   //
   //  end
     else if(ready1)begin
     rd_state          <= S_determine1;
     

     end
     else if(ready2)begin
     rd_state          <= S_determine2;
     

     end
     else if(ready3)begin
     rd_state          <= S_determine3;
     

     end
     else if(ready4)begin
     rd_state          <= S_determine4;
     

     end
     

     
     
   
    
    end
    
    S_determine5:
    begin
    rd_state          <= S_read5;
    
    
    end
    S_read5:
    begin
      if  (done5) begin
        rd_state          <= S_wait1;
    end
    end
    
     S_wait6:
    begin
     if(ready6)begin
     rd_state          <= S_determine6;
    
    end
     else if(ready1)begin
     rd_state          <= S_determine1;
     

     end
     else if(ready2)begin
     rd_state          <= S_determine2;
     

     end
     else if(ready3)begin
     rd_state          <= S_determine3;
     

     end
     else if(ready4)begin
     rd_state          <= S_determine4;
     

     end
     else if(ready5)begin
     rd_state          <= S_determine5;
     

     end
     

     
     
   
    
    end
    
    S_determine6:
    begin
    rd_state          <= S_read6;
    
    
    end
    S_read6:
    begin
      if  (done6) begin
        rd_state          <= S_wait1;
    end
    end
    
    
    endcase
end 

end 



always @(*) begin
   
    case(rd_state)
    
    
    S_determine1:
    begin
       cs<=6'b00_00_01;
    end
    
    
    
    S_determine2:
    begin
       cs<=6'b00_00_10;
    
    
    end
    S_determine3:
    begin
       cs<=6'b00_01_00;
    end
    
    
    
    S_determine4:
    begin
       cs<=6'b00_10_00;
    
    
    end
    S_determine5:
    begin
       cs<=6'b01_00_00;
    end
    
    
    
    S_determine6:
    begin
       cs<=6'b10_00_00;
    
    
    end
    default :
    begin
    
       cs<=6'b00_00_00;
    
    
    
    end
    
    
    
    endcase
end 

always @(*) begin
   
    case(rd_state)
    
    
    S_read1:
    begin
     O_fdma_raddr <=   I_fdma_raddr1   ;
     O_fdma_rareq <=   I_fdma_rareq1   ;
     O_fdma_rsize <=   I_fdma_rsize1   ;
     O_fdma_rbusy1  <=  i_fdma_rbusy   ;
     O_fdma_rdata1  <=  i_fdma_rdata   ;
     O_fdma_rvalid1 <=  i_fdma_rvalid  ;
     O_fdma_rbusy2  <=  i_fdma_rbusy   ;
     O_fdma_rdata2  <=  1'b0             ; 
     O_fdma_rvalid2 <=  1'b0             ;
     O_fdma_rbusy3  <=  i_fdma_rbusy   ;
     O_fdma_rdata3  <=  1'b0             ; 
     O_fdma_rvalid3 <=  1'b0             ;
     O_fdma_rbusy4  <=  i_fdma_rbusy   ;
     O_fdma_rdata4  <=  1'b0             ; 
     O_fdma_rvalid4 <=  1'b0             ;
     O_fdma_rbusy5  <=  i_fdma_rbusy   ;
     O_fdma_rdata5  <=  1'b0             ; 
     O_fdma_rvalid5 <=  1'b0             ;
     O_fdma_rbusy6  <=  i_fdma_rbusy   ;
     O_fdma_rdata6  <=  1'b0             ; 
     O_fdma_rvalid6 <=  1'b0             ;
 
    end
    
    
    
    S_read2:
    begin
     O_fdma_raddr <=   I_fdma_raddr2   ;
     O_fdma_rareq <=   I_fdma_rareq2   ;
     O_fdma_rsize <=   I_fdma_rsize2   ;
     O_fdma_rbusy2  <=  i_fdma_rbusy   ;
     O_fdma_rdata2  <=  i_fdma_rdata   ;
     O_fdma_rvalid2 <=  i_fdma_rvalid  ;
     O_fdma_rbusy1  <=  i_fdma_rbusy   ;
     O_fdma_rdata1  <=  1'b0             ; 
     O_fdma_rvalid1 <=  1'b0             ; 
     O_fdma_rbusy3  <=  i_fdma_rbusy   ;
     O_fdma_rdata3  <=  1'b0             ; 
     O_fdma_rvalid3 <=  1'b0             ;
     O_fdma_rbusy4  <=  i_fdma_rbusy   ;
     O_fdma_rdata4  <=  1'b0             ; 
     O_fdma_rvalid4 <=  1'b0             ;
     O_fdma_rbusy5  <=  i_fdma_rbusy   ;
     O_fdma_rdata5  <=  1'b0             ; 
     O_fdma_rvalid5 <=  1'b0             ;
     O_fdma_rbusy6  <=  i_fdma_rbusy   ;
     O_fdma_rdata6  <=  1'b0             ; 
     O_fdma_rvalid6 <=  1'b0             ;

    
    
    end
    S_read3:
    begin
     O_fdma_raddr <=   I_fdma_raddr3   ;
     O_fdma_rareq <=   I_fdma_rareq3   ;
     O_fdma_rsize <=   I_fdma_rsize3   ;
     O_fdma_rbusy3  <=  i_fdma_rbusy   ;
     O_fdma_rdata3  <=  i_fdma_rdata   ;
     O_fdma_rvalid3 <=  i_fdma_rvalid  ;
     O_fdma_rbusy1  <=  i_fdma_rbusy   ;
     O_fdma_rdata1  <=  1'b0             ; 
     O_fdma_rvalid1 <=  1'b0             ; 
     O_fdma_rbusy2  <=  i_fdma_rbusy   ;
     O_fdma_rdata2  <=  1'b0             ; 
     O_fdma_rvalid2 <=  1'b0             ;
     O_fdma_rbusy4  <=  i_fdma_rbusy   ;
     O_fdma_rdata4  <=  1'b0             ; 
     O_fdma_rvalid4 <=  1'b0             ;
     O_fdma_rbusy5  <=  i_fdma_rbusy   ;
     O_fdma_rdata5  <=  1'b0             ; 
     O_fdma_rvalid5 <=  1'b0             ;
     O_fdma_rbusy6  <=  i_fdma_rbusy   ;
     O_fdma_rdata6  <=  1'b0             ; 
     O_fdma_rvalid6 <=  1'b0             ;

    
    
    end
    S_read4:
    begin
     O_fdma_raddr <=   I_fdma_raddr4   ;
     O_fdma_rareq <=   I_fdma_rareq4   ;
     O_fdma_rsize <=   I_fdma_rsize4   ;
     O_fdma_rbusy4  <=  i_fdma_rbusy   ;
     O_fdma_rdata4  <=  i_fdma_rdata   ;
     O_fdma_rvalid4 <=  i_fdma_rvalid  ;
     O_fdma_rbusy1  <=  i_fdma_rbusy   ;
     O_fdma_rdata1  <=  1'b0             ; 
     O_fdma_rvalid1 <=  1'b0             ; 
     O_fdma_rbusy2  <=  i_fdma_rbusy   ;
     O_fdma_rdata2  <=  1'b0             ; 
     O_fdma_rvalid2 <=  1'b0             ;
     O_fdma_rbusy3  <=  i_fdma_rbusy   ;
     O_fdma_rdata3  <=  1'b0             ; 
     O_fdma_rvalid3 <=  1'b0             ;
     O_fdma_rbusy5  <=  i_fdma_rbusy   ;
     O_fdma_rdata5  <=  1'b0             ; 
     O_fdma_rvalid5 <=  1'b0             ;
     O_fdma_rbusy6  <=  i_fdma_rbusy   ;
     O_fdma_rdata6  <=  1'b0             ; 
     O_fdma_rvalid6 <=  1'b0             ;

    
    
    end
    S_read5:
    begin
     O_fdma_raddr <=   I_fdma_raddr5   ;
     O_fdma_rareq <=   I_fdma_rareq5   ;
     O_fdma_rsize <=   I_fdma_rsize5   ;
     O_fdma_rbusy5  <=  i_fdma_rbusy   ;
     O_fdma_rdata5  <=  i_fdma_rdata   ;
     O_fdma_rvalid5 <=  i_fdma_rvalid  ;
     O_fdma_rbusy1  <=  i_fdma_rbusy   ;
     O_fdma_rdata1  <=  1'b0             ; 
     O_fdma_rvalid1 <=  1'b0             ; 
     O_fdma_rbusy2  <=  i_fdma_rbusy   ;
     O_fdma_rdata2  <=  1'b0             ; 
     O_fdma_rvalid2 <=  1'b0             ;
     O_fdma_rbusy3  <=  i_fdma_rbusy   ;
     O_fdma_rdata3  <=  1'b0             ; 
     O_fdma_rvalid3 <=  1'b0             ;
     O_fdma_rbusy4  <=  i_fdma_rbusy   ;
     O_fdma_rdata4  <=  1'b0             ; 
     O_fdma_rvalid4 <=  1'b0             ;
     O_fdma_rbusy6  <=  i_fdma_rbusy   ;
     O_fdma_rdata6  <=  1'b0             ; 
     O_fdma_rvalid6 <=  1'b0             ;

    
    
    end
    S_read6:
    begin
     O_fdma_raddr <=   I_fdma_raddr6   ;
     O_fdma_rareq <=   I_fdma_rareq6   ;
     O_fdma_rsize <=   I_fdma_rsize6   ;
     O_fdma_rbusy6  <=  i_fdma_rbusy   ;
     O_fdma_rdata6  <=  i_fdma_rdata   ;
     O_fdma_rvalid6 <=  i_fdma_rvalid  ;
     O_fdma_rbusy1  <=  i_fdma_rbusy   ;
     O_fdma_rdata1  <=  1'b0             ; 
     O_fdma_rvalid1 <=  1'b0             ; 
     O_fdma_rbusy2  <=  i_fdma_rbusy   ;
     O_fdma_rdata2  <=  1'b0             ; 
     O_fdma_rvalid2 <=  1'b0             ;
     O_fdma_rbusy4  <=  i_fdma_rbusy   ;
     O_fdma_rdata4  <=  1'b0             ; 
     O_fdma_rvalid4 <=  1'b0             ;
     O_fdma_rbusy5  <=  i_fdma_rbusy   ;
     O_fdma_rdata5  <=  1'b0             ; 
     O_fdma_rvalid5 <=  1'b0             ;
     O_fdma_rbusy3  <=  i_fdma_rbusy   ;
     O_fdma_rdata3  <=  1'b0             ; 
     O_fdma_rvalid3 <=  1'b0             ;

    
    
    end
    default :
    begin
    O_fdma_raddr <=   1'b0  ;   
    O_fdma_rareq <=   1'b0  ;   
    O_fdma_rsize <=   1'b0  ;   
    O_fdma_rbusy2  <= i_fdma_rbusy   ;   
    O_fdma_rdata2  <= 1'b0  ;   
    O_fdma_rvalid2 <= 1'b0  ;   
    O_fdma_rbusy1  <= i_fdma_rbusy ;   
    O_fdma_rdata1  <=  1'b0             ; 
    O_fdma_rvalid1 <=  1'b0             ; 
    O_fdma_rbusy3  <=  i_fdma_rbusy   ;
     O_fdma_rdata3  <=  1'b0             ; 
     O_fdma_rvalid3 <=  1'b0             ;
     O_fdma_rbusy4  <=  i_fdma_rbusy   ;
     O_fdma_rdata4  <=  1'b0             ; 
     O_fdma_rvalid4 <=  1'b0             ;
     O_fdma_rbusy5  <=  i_fdma_rbusy   ;
     O_fdma_rdata5  <=  1'b0             ; 
     O_fdma_rvalid5 <=  1'b0             ;
     O_fdma_rbusy6  <=  i_fdma_rbusy   ;
     O_fdma_rdata6  <=  1'b0             ; 
     O_fdma_rvalid6 <=  1'b0             ; 

    
    
    
    end
    
    
    
    endcase
end 

           
 
 
 



endmodule

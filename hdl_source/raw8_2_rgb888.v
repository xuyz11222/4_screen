
/*********raw8_2_rgb888 RAW8 ת RGB888***********
ͨ����ʵ��3*3��RAW����Ȼ�����RGB
--�汾��1.0
*********************************************************************/

`timescale 1ns/1ns

module raw8_2_rgb888


(
    //global clock
input   wire        I_clk,            //cmos video pixel clock
input   wire        I_rst_n,          //global reset
input   wire        I_raw_vs,          //Prepared Image data vsync valid signal
input   wire        I_raw_de,          //Prepared Image data href vaild  signal
input   wire[7:0]   I_raw_data,        //Prepared Image data 8 Bit RAW Data
input   wire        size_shift,


output  wire        O_rgb_vs,   //Processed Image data vsync valid signal
output  wire        O_rgb_de,    //Processed Image data href vaild  signal
output  wire[7:0]   O_rgb_r,       //Prepared Image green data to be processed 
output  wire[7:0]   O_rgb_g,     //Prepared Image green data to be processed
output  wire[7:0]   O_rgb_b,       //Prepared Image blue data to be processed

input        [13:0]  h_size, 
input        [13:0]  v_size, 

input   wire        I_data_choice,
output  wire        O_data_choice
);

wire [7:0]raw_v_1_d0;//frame data of the 1th row
wire [7:0]raw_v_2_d0;//frame data of the 2th row
reg  [7:0]raw_v_3_d0;//frame data of the 3th row
reg  [7:0]raw_v_1_d1,raw_v_1_d2;
reg  [7:0]raw_v_2_d1,raw_v_2_d2;
reg  [7:0]raw_v_3_d1,raw_v_3_d2;
reg  raw_de_d1,raw_de_d2,raw_de_d3,raw_de_d4;  
reg  raw_vs_d1,raw_vs_d2,raw_vs_d3,raw_vs_d4;
reg  data_choice_d1,data_choice_d2,data_choice_d3,data_choice_d4;

wire  shift_clk_en = I_raw_de;
                             
reg         [13:0]  H_SIZE   ;
reg         [13:0]  V_SIZE   ;
 
assign   vs_flag =raw_vs_d1 && ~I_raw_vs;
always@(posedge I_clk )begin
    
    if(size_shift)begin
    H_SIZE <=  h_size ;
    V_SIZE <=  v_size ;
    end
        
    
end


Line_Shift_RAM_8Bit#(
.DATA_WIDTH (8          ),
.ADDR_WIDTH (11         ),
.DATA_DEPTH (1920     ),
.DELAY_NUM  (0          )
)
u0_Line_Shift_RAM_8Bit
(
.clk    (I_clk          ),
.rst_n  (I_rst_n        ),
.clken  (shift_clk_en   ),
.data_depth (H_SIZE     ),
.din    (I_raw_data     ),   
.dout   (raw_v_2_d0     )
);

Line_Shift_RAM_8Bit#(
.DATA_WIDTH (8          ),
.ADDR_WIDTH (11         ),
.DATA_DEPTH (1920     ),
.DELAY_NUM  (1          )
)
u1_Line_Shift_RAM_8Bit
(
.clk    (I_clk          ),
.rst_n  (I_rst_n        ),
.clken  (shift_clk_en   ),
.data_depth (H_SIZE     ),
.din    (raw_v_2_d0     ),   
.dout   (raw_v_1_d0     )
);

always@(posedge I_clk)begin
    raw_v_3_d0 <= I_raw_de ? I_raw_data : raw_v_3_d0; 

    raw_v_3_d1 <= raw_v_3_d0;
    raw_v_3_d2 <= raw_v_3_d1;
    raw_v_1_d1 <= raw_v_1_d0;
    raw_v_1_d2 <= raw_v_1_d1;
    raw_v_2_d1 <= raw_v_2_d0;
    raw_v_2_d2 <= raw_v_2_d1;


    raw_de_d1  <= I_raw_de;
    raw_de_d2  <= raw_de_d1;
    raw_de_d3  <= raw_de_d2;
    raw_de_d4  <= raw_de_d3;

    raw_vs_d1  <= I_raw_vs;
    raw_vs_d2  <= raw_vs_d1;
    raw_vs_d3  <= raw_vs_d2;
    raw_vs_d4  <= raw_vs_d3;
    
    data_choice_d1<=I_data_choice ;
    data_choice_d2<=data_choice_d1;
    data_choice_d3<=data_choice_d2;
    data_choice_d4<=data_choice_d3;
    
end

reg  [7:0]raw_v_h_11,raw_v_h_12,raw_v_h_13;
reg  [7:0]raw_v_h_21,raw_v_h_22,raw_v_h_23;
reg  [7:0]raw_v_h_31,raw_v_h_32,raw_v_h_33;
reg     [13:0]  pixel_cnt;
//��1�У����1�м򵥴���
always@(posedge I_clk)begin
  if(raw_de_d1|raw_de_d2)begin 
     pixel_cnt <=  (pixel_cnt < H_SIZE) ? pixel_cnt + 1'b1 : 10'd0;   //Point Counter  
    if(pixel_cnt == 0)begin //��ʼ������raw_de_d2Ϊ�ߵ�ƽ��0���س�ʼ��
        {raw_v_h_11,raw_v_h_12,raw_v_h_13} <= {8'd0,8'd0,8'd0};
        {raw_v_h_21,raw_v_h_22,raw_v_h_23} <= {8'd0,8'd0,8'd0};
        {raw_v_h_31,raw_v_h_32,raw_v_h_33} <= {8'd0,8'd0,8'd0};
    end  
    else if(pixel_cnt == 1)begin//���Ѿ��е�2�����ص����
        {raw_v_h_11,raw_v_h_12,raw_v_h_13} <= {raw_v_1_d0,raw_v_1_d1,raw_v_1_d0};
        {raw_v_h_21,raw_v_h_22,raw_v_h_23} <= {raw_v_2_d0,raw_v_2_d1,raw_v_2_d0};
        {raw_v_h_31,raw_v_h_32,raw_v_h_33} <= {raw_v_3_d0,raw_v_3_d1,raw_v_3_d0};    
    end
    else if(pixel_cnt == H_SIZE)begin//���һ�����أ�raw_de_d2=0�����һ�����أ�raw_de_d3=1��������2�����ص����
        {raw_v_h_11,raw_v_h_12,raw_v_h_13} <= {raw_v_1_d2,raw_v_1_d0,raw_v_1_d2};
        {raw_v_h_21,raw_v_h_22,raw_v_h_23} <= {raw_v_2_d2,raw_v_1_d0,raw_v_1_d2};
        {raw_v_h_31,raw_v_h_32,raw_v_h_33} <= {raw_v_3_d2,raw_v_1_d0,raw_v_1_d2};   
    end
    else begin
        {raw_v_h_11,raw_v_h_12,raw_v_h_13} <= {raw_v_1_d2,raw_v_1_d1,raw_v_1_d0};
        {raw_v_h_21,raw_v_h_22,raw_v_h_23} <= {raw_v_2_d2,raw_v_2_d1,raw_v_2_d0};
        {raw_v_h_31,raw_v_h_32,raw_v_h_33} <= {raw_v_3_d2,raw_v_3_d1,raw_v_3_d0};   
    end
  end
  else begin
        pixel_cnt <= 0;
        {raw_v_h_11,raw_v_h_12,raw_v_h_13} <= {8'd0,8'd0,8'd0};
        {raw_v_h_21,raw_v_h_22,raw_v_h_23} <= {8'd0,8'd0,8'd0};
        {raw_v_h_31,raw_v_h_32,raw_v_h_33} <= {8'd0,8'd0,8'd0};
  end
end


//----------------------------------------
//Count the frame lines
reg [10:0]  v_cnt;
reg [13:0]  h_cnt;
always@(posedge I_clk or negedge I_rst_n)begin
    if(!I_rst_n || I_raw_vs == 0)
        v_cnt <= 0;
    else if((raw_de_d3 == 1) && (raw_de_d2 == 0)) //Frame valid
        v_cnt <= (v_cnt < V_SIZE - 1'b1) ? v_cnt + 1'b1 : 11'd0;
    else 
        v_cnt <= v_cnt;
end

always@(posedge I_clk or negedge I_rst_n)begin
    if(!I_rst_n )
        h_cnt <= 0;
    else if(raw_de_d3 == 1'b1)  //��raw_de_d2��ʼ����
        h_cnt <= (h_cnt < H_SIZE - 1'b1) ? h_cnt + 1'b1 : 11'd0;
    else
        h_cnt <= 0;
end

//Convet RAW 2 RGB888 Format
reg [9:0]   rgb_r,rgb_g,rgb_b;
always@(posedge I_clk or negedge I_rst_n)begin
    if(!I_rst_n)begin
        rgb_r  <=  0;
        rgb_g  <=  0;
        rgb_b  <=  0; 
    end else begin
        case({v_cnt[0], h_cnt[0]})
        2'b11: begin  //odd lines + odd point  //Center Green
            rgb_r  <=  (raw_v_h_12 + raw_v_h_32)>>1;
            rgb_g  <=   raw_v_h_22;     
            rgb_b  <=  (raw_v_h_21 + raw_v_h_23)>>1;
         end
        2'b10: begin  //odd lines + even point //Center Blue
            rgb_r  <=  (raw_v_h_11 + raw_v_h_13 + raw_v_h_31 + raw_v_h_33)>>2;
            rgb_g  <=  (raw_v_h_12 + raw_v_h_21 + raw_v_h_23 + raw_v_h_32)>>2;
            rgb_b  <=   raw_v_h_22;
        end
        2'b01: begin  //even lines + odd point //Center Red
            rgb_r  <=   raw_v_h_22;
            rgb_g  <=  (raw_v_h_12 + raw_v_h_21 + raw_v_h_23 + raw_v_h_32)>>2;
            rgb_b  <=  (raw_v_h_11 + raw_v_h_13 + raw_v_h_31 + raw_v_h_33)>>2;
        end
        2'b00: begin//even lines + even point  //Center Green        
            rgb_r  <=  (raw_v_h_21 + raw_v_h_23)>>1;
            rgb_g  <=   raw_v_h_22;
            rgb_b  <=  (raw_v_h_12 + raw_v_h_32)>>1;
        end 
        endcase
    end
end


assign O_rgb_r    = rgb_r[7:0];
assign O_rgb_g    = rgb_g[7:0];
assign O_rgb_b    = rgb_b[7:0];
assign O_rgb_de   = raw_de_d4;
assign O_rgb_vs   = raw_vs_d4;
assign O_data_choice =data_choice_d4;

endmodule

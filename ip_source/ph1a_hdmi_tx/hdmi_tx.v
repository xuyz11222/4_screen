
/********************************************************************
��IP���Ϻ���·�Ƽ��ṩ
���Ĺ����������£�
HDMI Transmitter������Ҫ����ʱ�ӣ�����ʱ��pixel_clk�ʹ��з���ʱ��serial_clk������ʱ�Ӷ���ͨ��PLL���ɣ�����serial_clk��Ƶ����pixel_clkƵ�ʵ��屶��
HDMI Transmitter�������ӿ�EDID_Read_interface��Video_interface��Audio_interface���ǹ�����pixel_clkʱ�����£�����û��߼���Ҫʹ��pixel_clk����������Ƶ���ݡ�
HDMI Transmitter��pixel_clkƵ�ʺ�serial_clkƵ����Ҫ������ʾ�ֱ��ʽ��м��㡣��1080p60�ķֱ���Ϊ������Ч�ֱ���Ϊ1920x1080���ڼ���Ƶ�ʵ�ʱ����Ҫ������������
ͼ���ܵĳ���Ϊ2200x1125��ÿ��60֡���������ʱ�ӵ�Ƶ��Ϊ��
F_pixel=Htotal��Vtotal��FrameRate
F_pixel=2200��1125��60=148500000Hz=148.5MHz
���з���ʱ��serial_clkƵ��Ϊ����ʱ��Ƶ�ʵ��屶����˴��з���ʱ��Ƶ��Ϊ��
F_serial=5��F_pixel=5��148.5MHz=742.5MHz

1-���֧��1080p60��ʾ�ֱ��ʡ�
2-֧����·��Ƶ���롣
3-֧��RGB444��YUV444��
4-֧���ڲ���Ƶ����Դ��
5-֧��EDID��ȡ��
*********************************************************************/
`timescale 1ns / 1ns //����ʱ��̶�/����


module hdmi_tx#(
    parameter H_ActiveSize  =   1980, //��Ƶʱ�����,����Ƶ�źţ�һ����Ч(��Ҫ��ʾ�Ĳ���)������ռ��ʱ������һ��ʱ�Ӷ�Ӧһ����Ч����
    parameter H_SyncStart   =   1920+88, //��Ƶʱ�����,��ͬ����ʼ��������ʱ������ʼ������ͬ���ź� 
    parameter H_SyncEnd     =   1920+88+44, //��Ƶʱ�����,��ͬ��������������ʱ������ֹͣ������ͬ���źţ�֮���������Ч���ݲ���
    parameter H_FrameSize   =   1920+88+44+148,  //��Ƶʱ�����,����Ƶ�źţ�һ����Ƶ�ź��ܼ�ռ�õ�ʱ����

    parameter V_ActiveSize  =   1080,  //��Ƶʱ�����,����Ƶ�źţ�һ֡ͼ����ռ�õ���Ч(��Ҫ��ʾ�Ĳ���)��������ͨ��˵����Ƶ�ֱ��ʼ�H_ActiveSize*V_ActiveSize
    parameter V_SyncStart   =   1080+4, //��Ƶʱ�����,��ͬ����ʼ��������������ʼ������ͬ���ź� 
    parameter V_SyncEnd     =   1080+4+5,//��Ƶʱ�����,��ͬ�������������к�ֹͣ������ͬ���ź�
    parameter V_FrameSize   =   1080+4+5+36,  //��Ƶʱ�����,����Ƶ�źţ�һ֡��Ƶ�ź��ܼ�ռ�õ�������      
    
    parameter VIDEO_TPG         = "Enable",//"Enable��:ʹ�ܲ�����ƵԴ���ⲿ��Ƶ������Ч;"Disable��:���ò�����ƵԴ
    parameter VIDEO_FORMAT      = "RGB444",//��RGB444��:�ⲿ������Ƶ��ʽΪRGB;��YUV444��:�ⲿ������Ƶ��ʽΪYUV
    parameter VIDEO_VIC         = 16,//VIDEO_VIC���������趨HDMI������Ƶ��Ϣ���е�VIC����,���忴APUG058

    parameter AUDIO_CTS         = 148500,//��Ƶʱ�Ӳ�����CTS��
    parameter AUDIO_N           = 6144,  //��Ƶʱ�Ӳ�����N��
    parameter AUDIO_SAMPLE_RATE = "48K", //��Ƶ������

    parameter IIC_SCL_DIV       = 125   //EDID IICʱ�ӷ�Ƶϵ��
)(
    
    input wire       I_pixel_clk, //����ʱ��
    input wire       I_serial_clk,//���з���ʱ��
    input wire       I_rst, //�첽��λ�źţ��ߵ�ƽ��Ч

    input wire       I_edid_read_trig,//EDID�������ź�
    output wire      O_edid_read_valid,//EDID����Ч�ź�
    output wire[7:0] O_edid_read_data,//EDID������
    
///**********************  video rgb input  *****************************  
    input wire       I_video_rgb_enable,  //�Ƿ�ʹ��RGB����ӿڣ�����1ʹ�ܣ��������stream videoʱ��ӿ�
    input wire       I_video_in_de, //RGB ����de��Ч
    input wire       I_video_in_vs, //RGB ����VS ֡ͬ��
///**********************  video stream input  ***************************
    input wire       I_video_in_user,  //��Ƶ����֡��ʼ�ź�
    input wire       I_video_in_valid, //��Ƶ������Ч�ź�
    input wire       I_video_in_last,  //��Ƶ�����н����ź�
    output wire      O_video_in_ready, //��Ƶ����ready�ź�
    input wire[23:0] I_video_in_data,  //��Ƶ��������
///*********************  audio stream input  ***************************
    input wire       I_audio_valid,     //��Ƶ������Ч�ź�
    input wire[23:0] I_audio_left_data, //��Ƶ����������
    input wire[23:0] I_audio_right_data,//��Ƶ����������

    output wire      O_edid_iic_scl,    //EDID IICʱ���ź�
    inout wire       IO_edid_iic_sda,   //EDID IIC�����ź�

    output           O_hdmi_clk_p, //HDMI���ʱ��P��
    output    [2:0]  O_hdmi_tx_p,  //HDMI�������P��

    output wire      O_tmds_ch0_p, //HDMI����ͨ��0
    output wire      O_tmds_ch1_p, //HDMI����ͨ��1
    output wire      O_tmds_ch2_p, //HDMI����ͨ��2
    output wire      O_tmds_clk_p  //HDMIʱ��ͨ��
);

//���¼�����Ƶ�źŲ���,�Է��ϰ�·IP����
    localparam HTOTAL            = H_FrameSize;  //һ���ܳ��ȣ�����������������Ч����λΪʱ�Ӹ���
    localparam HSA               = H_SyncEnd   - H_SyncStart;//��ͬ�������ȣ���λΪʱ�Ӹ���
    localparam HFP               = H_SyncStart - H_ActiveSize;//����ʾǰ�أ���λΪʱ�Ӹ���
    localparam HBP               = H_FrameSize - H_SyncEnd;//����ʾ���أ���λΪʱ�Ӹ���
    localparam HACTIVE           = H_ActiveSize;//һ����Ч��ʾ���ȣ���λΪʱ�Ӹ���
    
    localparam VTOTAL            = V_FrameSize;//�������������������ͳ���Ч���֣���λΪͼ������
    localparam VSA               = V_SyncEnd - V_SyncStart;//��ͬ�������ȣ���λΪͼ������
    localparam VFP               = V_SyncStart - V_ActiveSize;//����ʾǰ�أ���λΪͼ������
    localparam VBP               = V_FrameSize - V_SyncEnd;//����ʾ���أ���λΪͼ������
    localparam VACTIVE           = V_ActiveSize;//��Ч��������λΪͼ������

//**********************  video stream input  ***************************
//���������RGBʱ����ôתΪstreamʱ�򣬷�������źŴ�һ������
    reg       I_video_in_de_r1;
    reg       I_video_in_vs_r1;
    reg       I_video_in_user_r1,I_video_in_user_r2;
    reg       I_video_in_valid_r1,I_video_in_valid_r2;
    reg       I_video_in_last_r2;
    reg[23:0] I_video_in_data_r1,I_video_in_data_r2;
    reg       O_video_in_ready_r;
    reg       vs_start;
  
    always @(posedge I_pixel_clk)begin
    	I_video_in_de_r1 <= I_video_in_de;
    	I_video_in_vs_r1 <= I_video_in_vs;
    end
      
    always @(posedge I_pixel_clk or posedge I_rst )begin
    	if(I_rst)begin
        	I_video_in_last_r2  <= 1'b0;
            I_video_in_valid_r1 <= 1'b0;
            I_video_in_data_r1  <= 24'd0;
            I_video_in_user_r1  <= 1'b0;
            I_video_in_valid_r2 <= 1'b0;
            I_video_in_data_r2  <= 24'd0;
            I_video_in_user_r2  <= 1'b0;
        end    
    	else if(I_video_rgb_enable == 1'b1)begin
        	I_video_in_last_r2  <= ~I_video_in_de & I_video_in_de_r1; //����stream video last �ӳ�����������2��
            I_video_in_valid_r1 <= I_video_in_de;//I_video_in_valid�ӳ�1��
            I_video_in_data_r1  <= I_video_in_data;//I_video_in_data�ӳ�1��
            I_video_in_user_r1  <= ~I_video_in_user_r1 & vs_start & I_video_in_de;//I_video_in_user�ӳ�1��
            
            I_video_in_valid_r2 <= I_video_in_valid_r1;//I_video_in_valid�������ź��ӳ�2�ģ��Ժ�I_video_in_last_r2�ź�����ͬ��
            I_video_in_data_r2  <= I_video_in_data_r1; //I_video_in_data �������ź��ӳ�2�ģ��Ժ�I_video_in_last_r2�ź�����ͬ��
            I_video_in_user_r2  <= I_video_in_user_r1; //I_video_in_user �������ź��ӳ�2�ģ��Ժ�I_video_in_last_r2�ź�����ͬ�� 
        end     
        else begin
        	I_video_in_last_r2  <= I_video_in_last; //I_video_in_last�������ź�ֱ�ӼĴ�1��
            I_video_in_valid_r2 <= I_video_in_valid;//I_video_in_valid�������ź�ֱ�ӼĴ�1��
            I_video_in_data_r2  <= I_video_in_data;//I_video_in_data�������ź�ֱ�ӼĴ�1��
            I_video_in_user_r2  <= I_video_in_user;//I_video_in_user�������ź�ֱ�ӼĴ�1��      
        end 
    end
    
    always @(posedge I_pixel_clk or posedge I_rst )begin
    	if(I_rst)
        	vs_start <= 1'b0;
    	else if(I_video_in_user_r1)//���VS֡ͬ��
        	vs_start <= 1'b0;
        else if(I_video_in_vs && I_video_in_vs_r1==1'b0)//��I_video_in_vs�����������������һ֡��ʼ
            vs_start <= 1'b1;
    end       	
            
       
    wire[9:0]   S_ch0_tmds_code_data;               
    wire[9:0]   S_ch1_tmds_code_data;               
    wire[9:0]   S_ch2_tmds_code_data;               
    wire[9:0]   S_clk_tmds_code_data;

//��Ƶ����
    hdmi_edid_wrapper #(
        .IIC_SCL_DIV ( IIC_SCL_DIV )
    ) u_hdmi_edid_wrapper(
        .I_clk             ( I_pixel_clk       ),
        .I_rst             ( I_rst             ),
 
        .I_edid_read_trig  ( I_edid_read_trig  ),
        .O_edid_read_valid ( O_edid_read_valid ),
        .O_edid_read_data  ( O_edid_read_data  ),
 
        .O_iic_scl         ( O_edid_iic_scl    ),
        .IO_iic_sda        ( IO_edid_iic_sda   )
    );

//HDMI IP
    hdmi_tx_controller_wrapper #(
        .HTOTAL               ( HTOTAL            ),
        .HSA                  ( HSA               ),
        .HFP                  ( HFP               ),
        .HBP                  ( HBP               ),
        .HACTIVE              ( HACTIVE           ),
        .VTOTAL               ( VTOTAL            ),
        .VSA                  ( VSA               ),
        .VFP                  ( VFP               ),
        .VBP                  ( VBP               ),
        .VACTIVE              ( VACTIVE           ),

        .VIDEO_TPG            ( VIDEO_TPG         ),
        .VIDEO_FORMAT         ( VIDEO_FORMAT      ),
        .VIDEO_VIC            ( VIDEO_VIC         ),
        
        .AUDIO_CTS            ( AUDIO_CTS         ),
        .AUDIO_N              ( AUDIO_N           ),
        .AUDIO_SAMPLE_RATE    ( AUDIO_SAMPLE_RATE )
    )u_hdmi_tx_controller_wrapper(
        .I_pixel_clk          ( I_pixel_clk          ),
        .I_rst                ( I_rst                ),

        .I_video_in_user      ( I_video_in_user_r2   ),
        .I_video_in_valid     ( I_video_in_valid_r2  ),
        .I_video_in_last      ( I_video_in_last_r1   ),
        .I_video_in_data      ( I_video_in_data_r2   ),
        .O_video_in_ready     ( O_video_in_ready     ),

        .I_audio_valid        ( I_audio_valid        ),
        .I_audio_left_data    ( I_audio_left_data    ),
        .I_audio_right_data   ( I_audio_right_data   ),

        .O_ch0_tmds_code_data ( S_ch0_tmds_code_data ),
        .O_ch1_tmds_code_data ( S_ch1_tmds_code_data ),
        .O_ch2_tmds_code_data ( S_ch2_tmds_code_data ),
        .O_clk_tmds_code_data ( S_clk_tmds_code_data )
    );

    
    hdmi_phy_wrapper u_hdmi2phy_wrapper(
        .I_pixel_clk        ( I_pixel_clk          ),
        .I_serial_clk       ( I_serial_clk         ),
        .I_rst              ( I_rst                ),

        .I_tmds_channel_0   ( S_ch0_tmds_code_data ),
        .I_tmds_channel_1   ( S_ch1_tmds_code_data ),
        .I_tmds_channel_2   ( S_ch2_tmds_code_data ),
        .I_tmds_channel_clk ( S_clk_tmds_code_data ),

        .O_tmds_ch0_p       ( O_hdmi_tx_p[0]       ),
        .O_tmds_ch1_p       ( O_hdmi_tx_p[1]       ),
        .O_tmds_ch2_p       ( O_hdmi_tx_p[2]       ),
        .O_tmds_clk_p       ( O_hdmi_clk_p         )
    );



endmodule
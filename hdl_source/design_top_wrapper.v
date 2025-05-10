
`define DRAM_BYTE_NUM 4
`define ALC_MC_32B
`define AXI
//`define STG 
`define APP_ADDR_WIDTH   27



module design_top_wrapper (
    /*
        input 25MHz system clock
    */
    input wire       I_sys_clk_25m,


    /*
        external key trig input 
    */
    input wire       I_key_in,

    /*
        soft mcu jtag interface
    */
    input wire       I_mcu_jtag_tms,
    input wire       I_mcu_jtag_tdi,
    output wire      O_mcu_jtag_tdo,
    input wire       I_mcu_jtag_tck,

    /*
        soft mcu uart
        
    */
    output wire      O_mcu_uart_tx,
    input wire       I_mcu_uart_rx,

    /*
        camera sc2210 iic configure interface
    */
    inout wire       IO_sc2210_scl,
    inout wire       IO_sc2210_sda,
 
    /*
        camera sc2210 24mhz clk
    */
	output wire      O_sc2210_clk_27m,

	output wire      O_sc2210_rst_n,

	inout wire       IO_led,

    ///hdmi tmds channel signal N
	output [2:0]O_hdmi_tx_p, //HDMI输出数据P端
	output [2:0]O_hdmi_tx_n,  //HDMI输出数据N端
    output O_hdmi_clk_p,     //HDMI输出时钟P端
	output O_hdmi_clk_n,     //HDMI输出时钟N端
    
    
    output wire 	 fan_pwm

);
    parameter                           DIFF_THR = 'D50            ;
    parameter                           CLK_FREQ = 'D40_000_000    ;
    parameter                           MIN_DISC = 'd30           ;
    parameter                           H_PIXEL     =   11'd960    ;//水平方向像素个数,用于设置SDRAM缓存大小
    parameter                           V_PIXEL     =   10'd540    ;//垂直方向像素个数,用于设置SDRAM缓存大小
	
	wire        S_sys_clk;
    wire        S_hdmi_clk;
    wire		S_serial_clk;
    wire 		I_ddr_clk;
 
    wire[19:0]  S_user_apb_PADDR;      
    wire        S_user_apb_PSEL;       
    wire        S_user_apb_PENABLE;    
    wire        S_user_apb_PWRITE;     
    wire[31:0]  S_user_apb_PWDATA;     
    wire        S_user_apb_PREADY;    
    wire[31:0]  S_user_apb_PRDATA;    
    wire        S_user_apb_PSLVERROR; 
    wire        S_user_apb_int;       
 
    wire[31:0]  S_mcu_gpio_in;
    wire[31:0]  S_mcu_gpio_out;
    wire[31:0]  S_mcu_gpio_out_en;

    wire        S_clk_70m;

    wire        S_configure_load_en;                
    wire        S_configure_done;                   
    wire[13:0]  S_HTOTAL;                           
    wire[13:0]  S_HSA;                              
    wire[13:0]  S_HFP;                              
    wire[13:0]  S_HBP;                              
    wire[13:0]  S_HACTIVE;                          
    wire[13:0]  S_VTOTAL;                           
    wire[13:0]  S_VSA;                              
    wire[13:0]  S_VFP;                              
    wire[13:0]  S_VBP;                              
    wire[13:0]  S_VACTIVE;                          
    wire        S_hdcp_en;                          
    wire        S_video_test_source_en;                         
    wire[6:0]   S_video_VIC;                               
    wire[1:0]   S_pixel_color_deep;                        
    wire[2:0]   S_video_format;                            
    wire[1:0]   S_pixel_num_per_clock;                 
    wire        S_data_over_sample_en;    
    wire[19:0]  S_audio_clock_regeneration_CTS;            
    wire[19:0]  S_audio_clock_regeneration_N;               
    wire[2:0]   S_audio_channel_number;                    
    wire[2:0]   S_audio_sample_rate;                       

    wire        S_serdes_config_load_en;                 
    wire[1:0]   S_serdes_data_width_sel;                 
    wire[2:0]   S_serdes_tx_rate;                        
    wire[23:0]  S_serdes_ref_clk_freq;                   
    wire[15:0]  S_serdes_line_rate;                      
    wire        S_serdes_mpll_sel;                       
    wire[1:0]   S_serdes_mpll_tx_clk_div;                
    wire[7:0]   S_serdes_mpll_multiplier;                
    wire        S_serdes_config_done;      

    wire        S_serdes_configure_load_en;         
 
	wire        S_pll_lock;

    wire[19:0]  S_awb_r_gain;
    wire[19:0]  S_awb_g_gain;
    wire[19:0]  S_awb_b_gain;
 
    wire[8:0]   S_data_lane3_idelay;
    wire[8:0]   S_data_lane1_idelay;
    wire[8:0]   S_data_lane2_idelay;
    wire[8:0]   S_data_lane0_idelay;
    wire[8:0]   S_clk_lane_idelay;  
    wire[9:0]   S_camera_black_level;
    wire        S_hdmi_tpg_en;

    wire        S_hs_rx_clk1;           //synthesis keep  
    wire        S_hs_rx_valid1;         //synthesis keep  
    wire[31:0]  S_hs_rx_data1;          //synthesis keep
    
    wire        S_hs_rx_clk2;           //synthesis keep  
    wire        S_hs_rx_valid2;         //synthesis keep  
    wire[31:0]  S_hs_rx_data2;          //synthesis keep
    
 
    wire        S_csi_frame_start1;  //synthesis keep      
    wire        S_csi_frame_end1;  //synthesis keep         
    wire        S_csi_valid1;  //synthesis keep           
    wire[31:0]  S_csi_data1;          
 
    wire        S_csi_frame_start2;  //synthesis keep      
    wire        S_csi_frame_end2;  //synthesis keep         
    wire        S_csi_valid2;  //synthesis keep           
    wire[31:0]  S_csi_data2;          
 
 
    wire        S_raw8_frame_start1; 
    wire        S_raw8_frame_end1;   
    wire        S_raw8_valid1;   //synthesis keep    
    wire[31:0]  S_raw8_data1;   //synthesis keep  
    
    
    wire        S_raw8_frame_start2; 
    wire        S_raw8_frame_end2;   
    wire        S_raw8_valid2;   //synthesis keep    
    wire[31:0]  S_raw8_data2;   //synthesis keep    
 
    wire        S_raw8_cut_frame_start1;  
    wire        S_raw8_cut_frame_end1;    
    wire        S_raw8_cut_valid1;        
    wire[31:0]  S_raw8_cut_data1;
    
    wire        S_raw8_cut_frame_start2;  
    wire        S_raw8_cut_frame_end2;    
    wire        S_raw8_cut_valid2;        
    wire[31:0]  S_raw8_cut_data2;       
 
    wire        S_rgb888_frame_start;
    wire        S_rgb888_frame_end;
    wire        S_rgb888_valid;      
    wire[95:0]  S_rgb888_data;        

    wire        S_awb_frame_start;    //synthesis keep
    wire        S_awb_frame_end;      //synthesis keep
    wire        S_awb_valid;          //synthesis keep
    wire[95:0]  S_awb_data;           //synthesis keep

    wire        S_mipi_rx_error;         //synthesis keep

    wire        S_vi_256b_frame_start;   //synthesis keep
    wire        S_vi_256b_valid;         //synthesis keep
    wire[255:0] S_vi_256b_data;       

    wire        S_video_out_rd_busy;
    wire        S_video_in_wr_busy; 
    wire[1:0]   S_video_out_rp;     

    wire        S_ddr_user_wr_en;        //synthesis keep
    wire        S_ddr_user_rd_en;        //synthesis keep
    wire[27:0]  S_ddr_user_addr;         //synthesis keep
    wire[255:0] S_ddr_user_wr_data;      //synthesis keep
    wire        S_ddr_user_ready;        //synthesis keep
    wire        S_ddr_user_rd_valid;     //synthesis keep
    wire[255:0] S_ddr_user_rd_data;      //synthesis keep

    wire        S_vi_ddr_wr_en;   
    wire[27:0]  S_vi_ddr_wr_addr; 
    wire[255:0] S_vi_ddr_wr_data;
    wire        S_vi_ddr_wr_ready;

    wire        S_vo_ddr_rd_en;   
    wire[27:0]  S_vo_ddr_rd_addr; 
    wire        S_vo_ddr_rd_ready;

    wire        S_video_source_vsync;
    wire        S_video_source_user; 
    wire        S_video_source_valid;
    wire        S_video_source_last; 

    wire        S_vdieo_rd_en;  
    wire[95:0]  S_video_rd_data;

    wire        S_mixer_user; 
    wire        S_mixer_valid;  
    wire        S_mixer_last;   
    wire[23:0] S_mixer_data;   

    reg[9:0]    S_hdmi_config_cnt;
    reg         S_serdes_config_done_1d;

    wire        S_ddr_clk;       //synthesis keep

    wire        S_init_calib_complete;  
    wire[27:0]  S_mc_app_addr;          
    wire[2:0]   S_mc_app_cmd;           
    wire        S_mc_app_en;            
    wire[255:0] S_mc_app_wdf_data;      
    wire        S_mc_app_wdf_end;       
    wire[31:0]  S_mc_app_wdf_mask;      
    wire        S_mc_app_wdf_wren;      
    wire[255:0] S_mc_app_rd_data;       
    wire        S_mc_app_rd_data_end;   
    wire        S_mc_app_rd_data_valid; 
    wire        S_mc_app_rdy;           
    wire        S_mc_app_wdf_rdy;       

	wire[3:0]   S_lane_error1;
    wire[3:0]   S_lane_error2;
    
    wire[9:0]   S_ts_tempture;
    
    wire  S_fifo_empty;
    wire  S_fifo_rd_valid;
    wire  S_fifo_frame_start;
    wire[9:0]  S_fifo_rd_num;
    wire[9:0]  S_fifo_wr_num;

    wire [23:0]  S_fifo_rd_data;
    reg         S_fifo_rd_en;
    
    wire 			S_csi_rx_vsync01;//synthesis keep
	wire 			S_csi_rx_hsync01;//synthesis keep
    wire 			S_csi_rx_vsync02;//synthesis keep
	wire 			S_csi_rx_hsync02;//synthesis keep

    wire [7:0] wbuf_sync_o1,rbuf_sync_o1;
    wire [7:0] wbuf_sync_o2,rbuf_sync_o2;
     wire [7:0] wbuf_sync_o3,rbuf_sync_o3;
    wire [7:0] wbuf_sync_o4,rbuf_sync_o4;
     wire [7:0] wbuf_sync_o5,rbuf_sync_o5;
    wire [7:0] wbuf_sync_o6,rbuf_sync_o6;
    
    reg  ud_rfifo_en1;
    reg  ud_rfifo_en2;
    reg  ud_rfifo_en3;
    reg  ud_rfifo_en4;
    reg  ud_rfifo_en5;
    reg  ud_rfifo_en6;
    
    
    wire   vtc_rstn ;
    wire   vtc_clk;
    wire   vtc_vs;//synthesis keep
    wire   vtc_hs;//synthesis keep
    //wire   vtc_user;//synthesis keep
    wire   vtc_de_valid;//synthesis keep
    //wire   vtc_last;////synthesis keep
   
    wire S_rst;
    wire [7 :0]	rgb_r ,rgb_g ,rgb_b;// 定义寄存器保存图像的颜色数据
    assign vtc_clk = S_hdmi_clk; // 内部像素时钟
    assign vtc_rstn = S_pll_lock; //用PLL 的LOCK信号复位
    assign S_rst = ~S_pll_lock;


    wire ud_wclk1,ud_wvs1,ud_wde1;
    wire [31:0] ud_wdata1;//synthesis keep
    
    wire ud_wclk2,ud_wvs2,ud_wde2;
    wire [31:0] ud_wdata2;//synthesis keep
    
    wire ud_wclk3,ud_wvs3,ud_wde3;
    wire [31:0] ud_wdata3;//synthesis keep
    
    wire ud_wclk4,ud_wvs4,ud_wde4;
    wire [31:0] ud_wdata4;//synthesis keep
    
    wire ud_wclk5,ud_wvs5,ud_wde5;
    wire [31:0] ud_wdata5;//synthesis keep
    
    wire ud_wclk6,ud_wvs6,ud_wde6;
    wire [31:0] ud_wdata6;//synthesis keep
    
    
    
    
    
    wire ud_rclk1,ud_rvs1,ud_rde1;
    wire [15:0] ud_rdata1;//synthesis keep
    
    wire ud_rclk2,ud_rvs2,ud_rde2;
    wire [15:0] ud_rdata2;//synthesis keep
    
   
    
    wire ud_rclk3,ud_rvs3,ud_rde3;
    wire [15:0] ud_rdata3;//synthesis keep
    
     wire ud_rclk4,ud_rvs4,ud_rde4;
    wire [15:0] ud_rdata4;//synthesis keep
    
    wire ud_rclk5,ud_rvs5,ud_rde5;
    wire [15:0] ud_rdata5;//synthesis keep
    
     wire ud_rclk6,ud_rvs6,ud_rde6;
    wire [15:0] ud_rdata6;//synthesis keep
    
    
    
    
    wire [23:0] video_hdmi_data;
    
    wire     vtc_de_valid1    ;
    wire     vtc_de_valid2    ;
    wire     vtc_de_valid3    ;
    wire     vtc_de_valid4    ;
    wire     vtc_de_valid5    ;
    wire     vtc_de_valid6    ;
    
    wire   cam_choice1,cam_choice2,cam_choice3;

	PLL U_PLL(
  		.refclk   ( I_sys_clk_25m          ),
  		.lock     ( S_pll_lock             ),
        .reset	  (	~I_key_in			   ), 
 
  		.clk0_out ( O_sc2210_clk_27m             ),
  		.clk1_out ( S_sys_clk              ),
        .clk2_out ( S_clk_70m              ),
        .clk3_out ( S_hdmi_clk       ),  //像素时钟
        .clk4_out (	S_serial_clk			   ),//HDMI IO的serdes 时钟 5倍的像素时钟
        .clk5_out (	I_ddr_clk			   )
	);

	assign O_sc2210_rst_n = 1'b1;
	
    ///led
    assign IO_led = S_mcu_gpio_out_en[0] ? S_mcu_gpio_out[0] : 1'bz;
	assign S_mcu_gpio_in[0] = IO_led;

    ///sc2210 iic scl
    assign IO_sc2210_scl    = S_mcu_gpio_out_en[1] ? S_mcu_gpio_out[1] : 1'bz;
    assign S_mcu_gpio_in[1] = IO_sc2210_scl;

    ///sc2210 iic sda
    assign IO_sc2210_sda    = S_mcu_gpio_out_en[2] ? S_mcu_gpio_out[2] : 1'bz;
    assign S_mcu_gpio_in[2] = IO_sc2210_sda;
    
    ///fan 
    assign fan_pwm = 1'b1;


    soft_ps_wrapper#(
        .SYSCLK               ( 70000000                  ),
        .DEV_SERIES           ( "PH1"                     ),
        .CORE_TYPE            ( "MEDIUM"                  ),
        .TCM0_SIZE            ( 32*1024                   ),
        .TCM0_INITFILE        ( "SC2210_HDMI_1080P.bin.mif" ),
        .TCM0_RAMSTYLE        ( "20K"                     ),
        .UART1_BAUDRATE       ( 115200                    ),
        .MTIME_ENABLE         ( 1'b0                      ),
        .GPIO_PINNUM          ( 32                        ),
        .GPIO_INTENABLE       ( 1'b1                      ),
        .GPIO_INTCFG          ( {45'h0,3'b101,48'h0}      )
    )u_soft_ps_wrapper(
        .I_clk                ( S_clk_70m            ),
        .I_rst                ( S_rst 	             ),//

        .I_mcu_jtag_tms       ( I_mcu_jtag_tms       ),
        .I_mcu_jtag_tdi       ( I_mcu_jtag_tdi       ),
        .O_mcu_jtag_tdo       ( O_mcu_jtag_tdo       ),
        .I_mcu_jtag_tck       ( I_mcu_jtag_tck       ),

        .I_gpio_in            ( S_mcu_gpio_in        ),
        .O_gpio_out           ( S_mcu_gpio_out       ),
        .O_gpio_out_en        ( S_mcu_gpio_out_en    ),
        
        .O_uart1_tx           (         ),
        .I_uart1_rx           (         ),

        .O_user_apb_PADDR     ( S_user_apb_PADDR     ),
        .O_user_apb_PSEL      ( S_user_apb_PSEL      ),
        .O_user_apb_PENABLE   ( S_user_apb_PENABLE   ),
        .O_user_apb_PWRITE    ( S_user_apb_PWRITE    ),
        .O_user_apb_PWDATA    ( S_user_apb_PWDATA    ),
        .I_user_apb_PREADY    ( S_user_apb_PREADY    ),
        .I_user_apb_PRDATA    ( S_user_apb_PRDATA    ),
        .I_user_apb_PSLVERROR ( S_user_apb_PSLVERROR ),
        .I_user_apb_int       ( S_user_apb_int       ),

        .I_spi_miso           (  ),
        .O_spi_mosi           (  ),
        .O_spi_clk            (  ),
        .O_spi_cs             (  ),

        .I_spi2_miso          (  ),
        .O_spi2_mosi          (  ),
        .O_spi2_clk           (  ),
        .O_spi2_cs            (  ),

        .O_uart2_tx           (  ),
        .I_uart2_rx           (  ),

        .IO_i2c_scl           (  ),
        .IO_i2c_sda           (  )
    );


    apd_to_register u_apd_to_register(
        .I_clk               ( S_clk_70m            ),
        .I_rst_n             ( ~S_rst               ),
                             
        .I_apb_paddr         ( S_user_apb_PADDR     ),
        .I_apb_psel          ( S_user_apb_PSEL      ),
        .I_apb_penable       ( S_user_apb_PENABLE   ),
        .I_apb_pwrite        ( S_user_apb_PWRITE    ),
        .I_apb_pwdata        ( S_user_apb_PWDATA    ),
        .O_apb_pready        ( S_user_apb_PREADY    ),
        .O_apb_prdata        ( S_user_apb_PRDATA    ),
        .O_apb_pslverror     ( S_user_apb_PSLVERROR ),
        .O_apb_int           ( S_user_apb_int       ),
                             
        .I_pl_version        ( 32'h20230215         ),
       	.I_ts_tempture		 (	S_ts_tempture		),
        .O_awb_r_gain        ( S_awb_r_gain         ),
        .O_awb_g_gain        ( S_awb_g_gain         ),
        .O_awb_b_gain        ( S_awb_b_gain         ),
    	.O_data_lane3_idelay ( S_data_lane3_idelay  ),
    	.O_data_lane1_idelay ( S_data_lane1_idelay  ),
    	.O_data_lane2_idelay ( S_data_lane2_idelay  ),
    	.O_data_lane0_idelay ( S_data_lane0_idelay  ),
    	.O_clk_lane_idelay   ( S_clk_lane_idelay    ),
        .O_camera_black_level( S_camera_black_level ),
        //.O_hdmi_dp159_oe     ( O_hdmi_tx_en_0       ),
        .O_hdmi_tpg_en       ( S_hdmi_tpg_en        )
    );

localparam  AXI_ADDR_WIDTH = `APP_ADDR_WIDTH +2;
localparam  AXI_DATA_WIDTH = `DRAM_BYTE_NUM*8*8;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr;   //FDMA写通道地址
wire                             fdma_wareq;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata;   //FDMA写数据
wire                             fdma_wvalid;  //FDMA 写有效
wire                             fdma_wready;  //FDMA写准备好，用户可以写数据

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr;   //synthesis keep     //FDMA读通道地址
wire                             fdma_rareq;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata;   //FDMA读数据
wire                             fdma_rvalid;  //FDMA 读有效
wire                             fdma_rready;  //FDMA读准备好，用户可以读数据	
wire                             fdma_rdone ;



wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr1;   //FDMA写通道地址
wire                             fdma_wareq1;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize1;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy1;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata1;   //FDMA写数据
wire                             fdma_wvalid1;  //FDMA 写有效
wire                             fdma_wready1;  //FDMA写准备好，用户可以写数据
wire                             fdma_wdone1;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr2;   //FDMA写通道地址
wire                             fdma_wareq2;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize2;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy2;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata2;   //FDMA写数据
wire                             fdma_wvalid2;  //FDMA 写有效
wire                             fdma_wready2;  //FDMA写准备好，用户可以写数据
wire                             fdma_wdone2;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr3;   //FDMA写通道地址
wire                             fdma_wareq3;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize3;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy3;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata3;   //FDMA写数据
wire                             fdma_wvalid3;  //FDMA 写有效
wire                             fdma_wready3;  //FDMA写准备好，用户可以写数据
wire                             fdma_wdone3;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr4;   //FDMA写通道地址
wire                             fdma_wareq4;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize4;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy4;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata4;   //FDMA写数据
wire                             fdma_wvalid4;  //FDMA 写有效
wire                             fdma_wready4;  //FDMA写准备好，用户可以写数据
wire                             fdma_wdone4;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr5;   //FDMA写通道地址
wire                             fdma_wareq5;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize5;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy5;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata5;   //FDMA写数据
wire                             fdma_wvalid5;  //FDMA 写有效
wire                             fdma_wready5;  //FDMA写准备好，用户可以写数据
wire                             fdma_wdone5;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr6;   //FDMA写通道地址
wire                             fdma_wareq6;   //FDMA写通道请求
wire [15: 0]                     fdma_wsize6;   //FDMA写通道一次FDMA的传输大小                                       
wire                             fdma_wbusy6;   //FDMA处于BUSY状态，AXI总线正在写操作 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata6;   //FDMA写数据
wire                             fdma_wvalid6;  //FDMA 写有效
wire                             fdma_wready6;  //FDMA写准备好，用户可以写数据
wire                             fdma_wdone6;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr1;   //synthesis keep     //FDMA读通道地址
wire                             fdma_rareq1;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize1;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy1;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata1;   //FDMA读数据
wire                             fdma_rvalid1;  //FDMA 读有效
wire                             fdma_rready1;  //FDMA读准备好，用户可以读数据	
wire                             fdma_rdone1 ;


wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr2;   //synthesis keep     //FDMA读通道地址
wire                             fdma_rareq2;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize2;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy2;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata2;   //FDMA读数据
wire                             fdma_rvalid2;  //FDMA 读有效
wire                             fdma_rready2;  //FDMA读准备好，用户可以读数据	
wire                             fdma_rdone2 ;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr3;   //synthesis keep     //FDMA读通道地址
wire                             fdma_rareq3;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize3;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy3;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata3;   //FDMA读数据
wire                             fdma_rvalid3;  //FDMA 读有效
wire                             fdma_rready3;  //FDMA读准备好，用户可以读数据	
wire                             fdma_rdone3 ;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr5;   //synthesis keep     //FDMA读通道地址
wire                             fdma_rareq5;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize5;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy5;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata5;   //FDMA读数据
wire                             fdma_rvalid5;  //FDMA 读有效
wire                             fdma_rready5;  //FDMA读准备好，用户可以读数据	
wire                             fdma_rdone5 ;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr4;   //synthesis keep     //FDMA读通道地址
wire                             fdma_rareq4;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize4;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy4;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata4;   //FDMA读数据
wire                             fdma_rvalid4;  //FDMA 读有效
wire                             fdma_rready4;  //FDMA读准备好，用户可以读数据	
wire                             fdma_rdone4 ;

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr6;   //synthesis keep     //FDMA读通道地址
wire                             fdma_rareq6;   //FDMA读通道请求
wire [15: 0]                     fdma_rsize6;   //FDMA读通道一次FDMA的传输大小                                       
wire                             fdma_rbusy6;   //FDMA处于BUSY状态，AXI总线正在读操作 			
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata6;   //FDMA读数据
wire                             fdma_rvalid6;  //FDMA 读有效
wire                             fdma_rready6;  //FDMA读准备好，用户可以读数据	
wire                             fdma_rdone6 ;


wire [5:0]                         rd_cs;
wire [5:0]                         wr_cs;
wire                               shift_en1 ;
wire                               shift_en2 ;
wire                               shift_en3 ;
wire                               shift_en4 ;
wire                               shift_en5 ;


wire                             O_axi_clk;
wire                             pll_locked;

wire [11:0]                      lcd_xpos   ;
wire [11:0]                      lcd_ypos   ;
//例化APP接口转AXI接口
uifdma_axi_ddr#
(
.SIMULATION      ("TRUE")   ,//"TRUE"   
.APP_ADDR_WIDTH  (`APP_ADDR_WIDTH)     ,  // 128 x 16bit                
.AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH)     ,                                     
.AXI_DATA_WIDTH  (`DRAM_BYTE_NUM*8*8) ,
.APP_DATA_WIDTH  (`DRAM_BYTE_NUM*8*8) ,
.APP_MASK_WIDTH  (`DRAM_BYTE_NUM * 8)  
)
u_uifdma_axi_ddr
(
.I_ddr_clk                       ( I_sys_clk_25m    ),
.I_sys_rstn                      ( ~S_rst         ),
.O_ddr_pll_locked                ( pll_locked   ),

// DDR signals
.ddr_reset_n                     ( ddr_reset_n  ),
.ddr_addr                        ( ddr_addr     ),
.ddr_ba                          ( ddr_ba       ),
.ddr_ck_p                        ( ddr_ck_p     ),
.ddr_ck_n                        ( ddr_ck_n     ),
.ddr_cke                         ( ddr_cke      ),
.ddr_cs_n                        ( ddr_cs_n     ),
.ddr_ras_n                       ( ddr_ras_n    ),
.ddr_cas_n                       ( ddr_cas_n    ),
.ddr_we_n                        ( ddr_we_n     ),
.ddr_odt                         ( ddr_odt      ),
.ddr_dqs_p                       ( ddr_dqs_p    ),
.ddr_dqs_n                       ( ddr_dqs_n    ),
.ddr_dq                          ( ddr_dq       ),
.ddr_dm                          ( ddr_dm       ),

.O_uart_txd                      (O_uart_txd    ),
.I_uart_rxd                      (I_uart_rxd    ),

.O_axi_clk                       (O_axi_clk     ),

.I_fdma_waddr                    (fdma_waddr)    ,// FDMA写通道地址
.I_fdma_wareq                    (fdma_wareq)    ,// FDMA写通道请求
.I_fdma_wsize                    (fdma_wsize)    ,// FDMA写通道一次FDMA的传输大小                                            
.O_fdma_wbusy                    (fdma_wbusy)    ,// FDMA处于BUSY状态，AXI总线正在写操作  
				
.I_fdma_wdata                    (fdma_wdata)    ,// FDMA写数据
.O_fdma_wvalid                   (fdma_wvalid)   ,// FDMA 写有效
.I_fdma_wready                   (1'b1)		     ,// FDMA写准备好，用户可以写数据

.I_fdma_raddr                    (fdma_raddr)    ,// FDMA读通道地址
.I_fdma_rareq                    (fdma_rareq)    ,// FDMA读通道请求
.I_fdma_rsize                    (fdma_rsize)    ,// FDMA读通道一次FDMA的传输大小                                      
.O_fdma_rbusy                    (fdma_rbusy)    ,// FDMA处于BUSY状态，AXI总线正在读操作 
				
.O_fdma_rdata                    (fdma_rdata)    ,// FDMA读数据
.O_fdma_rvalid                   (fdma_rvalid)   ,// FDMA 读有效
.I_fdma_rready                   (1'b1)		     // FDMA读准备好，用户可以读数据
);

    wire 			w_awb_vs1, w_awb_hs1, w_awb_de1; 
    wire 	[7:0] 	w_awb_r1, w_awb_g1, w_awb_b1;
    wire 			w_awb_vs3, w_awb_hs3, w_awb_de3; 
    wire 	[7:0] 	w_awb_r3, w_awb_g3, w_awb_b3;
    
    
      wire                         isp_vsync      ;
      wire                         isp_href       ;
      wire                         isp_1bit_out   ;
      wire                         isp_wr_en      ;
      wire        [  15:0]         isp_data_out   ;
      wire        [   7:0]         img_Y          ;
      wire                         ycbcr_wr_en    ;
      
      
      
      wire                         syn_wr_en     ;
      wire                         syn_hs        ;
      wire                         syn_vs        ;
      wire        [  15:0]         syn_data      ;
      
reg    [31:0]        wdata_d1      ;
reg    [1:0]         wdata_d1_cnt  ; 
reg                  wdata_d1_de   ; 
reg                  wdata_d1_de_r1;
reg                  ycbcr_wr_en_r1;



reg    [31:0]        wdata_d3      ;
reg    [1:0]         wdata_d3_cnt  ; 
reg                  wdata_d3_de   ; 
reg                  wdata_d3_de_r1;

reg    [31:0]        wdata_d4      ;
reg    [1:0]         wdata_d4_cnt  ; 
reg                  wdata_d4_de   ; 
reg                  wdata_d4_de_r1;


 reg [7 :0] ud_rdata_d3;//synthesis keep
 reg [7 :0] ud_rdata_d5;//synthesis keep
 
wire   [15:0]     fusion_rgb565  ;
wire  [23:0]      fusion_rgb888   ;
wire              fusion_hs       ;
wire              fusion_vs       ;
wire              fusion_wr_en    ;
wire  [7:0]       obj_num         ;
  

always @(posedge vtc_clk) begin
 if(!vtc_rstn)begin
  
        
        wdata_d1    <=1'b0;
        wdata_d1_cnt<=1'b0;
        wdata_d1_de <=0;
            
        end
        else begin
        if(ycbcr_wr_en)begin
            if(wdata_d1_cnt==0) begin
            
            wdata_d1    <={wdata_d1[31:8],img_Y};
            wdata_d1_cnt<=1'b1;
            wdata_d1_de <=0;
            end
            else if(wdata_d1_cnt==1) begin
            wdata_d1    <={wdata_d1[31:16],img_Y,wdata_d1[7:0]};
            wdata_d1_cnt<=2;
            wdata_d1_de <=0;
            end
            else if(wdata_d1_cnt==2) begin
            wdata_d1    <={wdata_d1[31:24],img_Y,wdata_d1[15:0]};
            wdata_d1_cnt<=3;
            wdata_d1_de <=0;
            end
            else if(wdata_d1_cnt==3) begin
            wdata_d1    <={img_Y,wdata_d1[23:0]};
            wdata_d1_cnt<=0;
            wdata_d1_de <=1;
            end
        end   
            
        end
        end
  always @(posedge vtc_clk) begin
      wdata_d1_de_r1<=wdata_d1_de;
      ycbcr_wr_en_r1<=ycbcr_wr_en;
end



always @(posedge vtc_clk) begin
 if(!vtc_rstn)begin
  
        
        wdata_d3    <=1'b0;
        wdata_d3_cnt<=1'b0;
        wdata_d3_de <=0;
            
        end
        else begin
        if(fusion_wr_en)begin
            if(wdata_d3_cnt==1'b0) begin
            
            wdata_d3    <={wdata_d3[31:16],fusion_rgb565};
            wdata_d3_cnt<=1'b1;
            wdata_d3_de <=0;
            end
            else if(wdata_d3_cnt==1'b1) begin
            wdata_d3    <={fusion_rgb565 ,wdata_d3[15:0]};
            wdata_d3_cnt<=1'b0;
            wdata_d3_de <=1;
            end
            
        end   
            
        end
        end
  always @(posedge vtc_clk) begin
      wdata_d3_de_r1<=wdata_d3_de;
end




always @(posedge vtc_clk) begin
 if(!vtc_rstn)begin
  
        
        wdata_d4    <=1'b0;
        wdata_d4_cnt<=1'b0;
        wdata_d4_de <=0;
            
        end
        else begin
        if(isp_wr_en)begin
            if(wdata_d4_cnt==1'b0) begin
            
            wdata_d4    <={wdata_d4[31:16],isp_data_out};
            wdata_d4_cnt<=1'b1;
            wdata_d4_de <=0;
            end
            else if(wdata_d4_cnt==1'b1) begin
            wdata_d4    <={isp_data_out ,wdata_d4[15:0]};
            wdata_d4_cnt<=1'b0;
            wdata_d4_de <=1;
            end
            
        end   
            
        end
        end
  always @(posedge vtc_clk) begin
      wdata_d4_de_r1<=wdata_d4_de;
end

assign vtc_de_valid3 = ycbcr_wr_en;




reg  w_awb_vs1_r1;
wire w_awb_vs1_flag;
reg  [1:0] w_awb_vs1_cnt; 
wire  w1_vs;

always @(posedge vtc_clk) begin
      w_awb_vs1_r1<=w_awb_vs1 ;
end
 
assign  w_awb_vs1_flag = ~w_awb_vs1&&w_awb_vs1_r1;

always @(posedge vtc_clk) begin
     if(w_awb_vs1_flag)begin
           if(w_awb_vs1_cnt>=2'b10)begin
            w_awb_vs1_cnt<= 0;
            end
            else begin
            
            w_awb_vs1_cnt<=w_awb_vs1_cnt+1'b1;
            end
      end
end



  
  
  
    


    isp_top
#(
    .DIFF_THR                          (DIFF_THR                  ) 
)
u_isp_top(
    .sys_clk                           (S_hdmi_clk                  ),
    .rst_n                             (vtc_rstn                 ),
    .pre_wr_en                         (w_awb_de1              ),
    .isp_data_in                       ({w_awb_r1[7:3], w_awb_g1[7:2], w_awb_b1[7:3]} ),
    .last_pic                          (ud_rdata_d3        ),//
    .pre_vsync                         (~w_awb_vs1          ),
    .pre_href                          (w_awb_hs1           ),

    .isp_vsync                         (isp_vsync                 ),
    .isp_href                          (isp_href                  ),
    .img_Y                             (img_Y                     ),
    .isp_1bit_out                      (isp_1bit_out              ),
    .isp_wr_en                         (isp_wr_en                 ),
    .isp_data_out                      (isp_data_out              ),
    .ycbcr_wr_en                       (ycbcr_wr_en               )// 
); 


cam_syn u_cam_syn(
    .sys_clk                           (S_hdmi_clk                   ),
    .sys_rst_n                         (vtc_rstn                    ),
    .pre_wr_en                         (w_awb_de1              ),
    .pre_vs                            (w_awb_vs1         ),
    .pre_hs                            (w_awb_hs1          ),
    .cam_data                          ({w_awb_r1[7:3], w_awb_g1[7:2], w_awb_b1[7:3]}            ),
    .syn_wr_en                         (syn_wr_en                 ),
    .syn_hs                            (syn_hs                    ),
    .syn_vs                            (syn_vs                    ),
    .syn_data                          (syn_data                  ) 
);


obj_check_and_boundary#(
    .H_PIXEL                           (H_PIXEL                   ),
    .V_PIXEL                           (V_PIXEL                   ),
    .MIN_DISC                          (MIN_DISC                  ) 
)
u_obj_check_and_boundary(

. vtc_clk                    (vtc_clk                   ),
. vtc_rstn                   (vtc_rstn                  ),
. isp_href                   (isp_href                  ),
. isp_vsync                  (isp_vsync                 ),
. isp_wr_en                  (isp_wr_en                 ),
. isp_1bit_out               (isp_1bit_out              ),
. syn_data                   (syn_data                  ),

. fusion_rgb565              (fusion_rgb565             ), 
. fusion_rgb888              (fusion_rgb888             ), 
. fusion_hs                  (fusion_hs                 ), 
. fusion_vs                  (fusion_vs                 ), 
. fusion_wr_en               (fusion_wr_en              ),    
. obj_num                    (obj_num                   ) 




);




 
    assign ud_wclk1   = S_hs_rx_clk1;//S_hdmi_clk;//S_sys_clk;//S_hs_rx_clk1;
    assign ud_wvs1    = S_csi_rx_vsync01;//S_rgb888_frame_start;//vtc_vs;
    assign ud_wde1    = S_raw8_cut_valid1;//S_fifo_rd_valid;//S_fifo_rd_en & (~S_fifo_empty);////vtc_de;
    assign ud_wdata1  = S_raw8_cut_data1;//pixelcont;//S_raw8_cut_data1;//{8'd0,S_fifo_rd_data};//S_awb_data;//{8'd0,S_fifo_rd_data};//{8'd0,rgb_r,rgb_g,rgb_b};
   
   assign ud_wclk2   = S_hdmi_clk;//S_hdmi_clk;//S_sys_clk;//S_hs_rx_clk1;
   assign ud_wvs2    = fusion_vs;//S_rgb888_frame_start;//vtc_vs;
   assign ud_wde2    = wdata_d3_de&&(~wdata_d3_de_r1);//S_fifo_rd_valid;//S_fifo_rd_en & (~S_fifo_empty);////vtc_de;
   assign ud_wdata2  = wdata_d3;//pixelcont;//S_raw8_cut_data1;//{8'd0,S_fifo_rd_data};//S_awb_data;//{8'd0,S_fifo_rd_data};//{8'd0,rgb_r,rgb_g,rgb_b};
    
   assign ud_wclk3   = S_hdmi_clk;//S_hdmi_clk;//S_sys_clk;//S_hs_rx_clk1;
   assign ud_wvs3    = ~w_awb_vs1;//S_rgb888_frame_start;//vtc_vs;
   assign ud_wde3    = wdata_d1_de&&(~wdata_d1_de_r1);//S_fifo_rd_valid;//S_fifo_rd_en & (~S_fifo_empty);////vtc_de;
   assign ud_wdata3  = wdata_d1;//pixelcont;//S_raw8_cut_data1;//{8'd0,S_fifo_rd_data};//S_awb_data;//{8'd0,S_fifo_rd_data};//{8'd0,rgb_r,rgb_g,rgb_b};
    

     
     assign ud_wclk4   = S_hdmi_clk;//S_hdmi_clk;//S_sys_clk;//S_hs_rx_clk1;
     assign ud_wvs4    = isp_vsync;//S_rgb888_frame_start;//vtc_vs;
     assign ud_wde4    = wdata_d4_de&&(~wdata_d4_de_r1);//S_fifo_rd_valid;//S_fifo_rd_en & (~S_fifo_empty);////vtc_de;
     assign ud_wdata4  = wdata_d4;//pixelcont;//S_raw8_cut_data1;//{8'd0,S_fifo_rd_data};//S_awb_data;//{8'd0,S_fifo_rd_data};//{8'd0,rgb_r,rgb_g,rgb_b};
 
//    assign ud_wclk5   = S_hs_rx_clk1;//S_hdmi_clk;//S_sys_clk;//S_hs_rx_clk1;
//    assign ud_wvs5    = S_csi_rx_vsync01;//S_rgb888_frame_start;//vtc_vs;
//    assign ud_wde5    = S_raw8_cut_valid1;//S_fifo_rd_valid;//S_fifo_rd_en & (~S_fifo_empty);////vtc_de;
//    assign ud_wdata5  = S_raw8_cut_data1;//pixelcont;//S_raw8_cut_data1;//{8'd0,S_fifo_rd_data};//S_awb_data;//{8'd0,S_fifo_rd_data};//{8'd0,rgb_r,rgb_g,rgb_b};
//    
//    assign ud_wclk6   = S_hs_rx_clk1;//S_hdmi_clk;//S_sys_clk;//S_hs_rx_clk1;
//    assign ud_wvs6    = S_csi_rx_vsync01;//S_rgb888_frame_start;//vtc_vs;
//    assign ud_wde6    = S_raw8_cut_valid1;//S_fifo_rd_valid;//S_fifo_rd_en & (~S_fifo_empty);////vtc_de;
/////=/    assign ud_wdata6  = S_raw8_cut_data1;//pixelcont;//S_raw8_cut_data1;//{8'd0,S_fifo_rd_data};//S_awb_data;//{8'd0,S_fifo_rd_data};//{8'd0,rgb_r,rgb_g,rgb_b};


    assign ud_rclk1   = S_hdmi_clk;
    assign ud_rvs1    = vtc_vs;
    assign ud_rde1    = ud_rfifo_en1;//vtc_de_valid_d1;//ud_rfifo_en;\
    assign ud_rclk2   = S_hdmi_clk;
    assign ud_rvs2    = vtc_vs;
    assign ud_rde2    = vtc_de_valid2;//vtc_de_valid_d1;//ud_rfifo_en;
    // assign video_hdmi_data  = ud_rdata[23:0];
    
    
    assign ud_rclk3   = S_hdmi_clk;
    assign ud_rvs3    = w_awb_vs1;
    assign ud_rde3    = ud_rfifo_en3;
    assign ud_rclk4   = S_hdmi_clk;
    assign ud_rvs4    = vtc_vs;
    assign ud_rde4    = vtc_de_valid4;//vtc_de_valid_d1;//ud_rfifo_en;
    
 //   assign ud_rclk4   = S_hdmi_clk;
 //   assign ud_rvs4    = vtc_vs;
 //   assign ud_rde4    = ud_rfifo_en4;
    assign ud_rclk5   = S_hdmi_clk;
    assign ud_rvs5    = w_awb_vs1;
    assign ud_rde5    = ud_rfifo_en5;
    
    
    
write_register#(
. AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
. AXI_DATA_WIDTH (AXI_DATA_WIDTH)
)

u_write_register
(   
.   clk        (O_axi_clk),    
.   rst_n      (pll_locked),    
.   ready1     (fdma_wready1),   
.   ready2     (fdma_wready2),
.   ready3     (fdma_wready3),   
.   ready4     (fdma_wready4),    
.   done1      (fdma_wdone1),    
.   done2      (fdma_wdone2), 
.   done3      (fdma_wdone3),    
.   done4      (fdma_wdone4),  
.   cs         (wr_cs),      

//axi接口
.  O_fdma_raddr     (fdma_waddr)     ,// FDMA读通道地址                
.  O_fdma_rareq     (fdma_wareq)     ,// FDMA读通道请求                
.  O_fdma_rsize     (fdma_wsize)     ,// FDMA读通道一次FDMA的传输大小                                  
. i_fdma_rbusy  	(fdma_wbusy)     ,// FDMA处于BUSY状态，AXI总线正在读操作  		
. O_fdma_rdata	    (fdma_wdata)   ,// FDMA读数据 
. i_fdma_rvalid     (fdma_wvalid)  ,// FDMA 读有效



//app1

.I_fdma_raddr1    (fdma_waddr1) ,
.I_fdma_rareq1    (fdma_wareq1) ,
.I_fdma_rsize1    (fdma_wsize1) ,                           
.O_fdma_rbusy1  	(fdma_wbusy1) ,	
.I_fdma_rdata1	  (fdma_wdata1)	 ,
.O_fdma_rvalid1   (fdma_wvalid1), 


//app2

.  I_fdma_raddr2   (fdma_waddr2) ,    
.  I_fdma_rareq2   (fdma_wareq2) ,    
.  I_fdma_rsize2   (fdma_wsize2) ,                         
.  O_fdma_rbusy2  	  (fdma_wbusy2) ,	 
.  I_fdma_rdata2	(fdma_wdata2)	 ,   
.  O_fdma_rvalid2  (fdma_wvalid2)  ,  
//app3

.  I_fdma_raddr3   (fdma_waddr3) ,    
.  I_fdma_rareq3   (fdma_wareq3) ,    
.  I_fdma_rsize3   (fdma_wsize3) ,                         
.  O_fdma_rbusy3  	  (fdma_wbusy3) ,	 
.  I_fdma_rdata3	(fdma_wdata3)	 ,   
.  O_fdma_rvalid3  (fdma_wvalid3)  ,  
//app4

.  I_fdma_raddr4   (fdma_waddr4) ,    
.  I_fdma_rareq4   (fdma_wareq4) ,    
.  I_fdma_rsize4   (fdma_wsize4) ,                         
.  O_fdma_rbusy4  	  (fdma_wbusy4) ,	 
.  I_fdma_rdata4	(fdma_wdata4)	 ,   
.  O_fdma_rvalid4  (fdma_wvalid4)  



 );    


    //例化uidbuf 控制器 
 axi_wr# (
    .VIDEO_ENABLE(1'b1),  
     
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    .W_BUFDEPTH(1024),
    .W_DATAWIDTH(32),//32
    .W_BASEADDR(0),
    .W_DSIZEBITS(25),//23
    .W_XSIZE(480),
    .W_XSTRIDE(480),
    .W_YSIZE(1080), 
    .W_XDIV(1), //2
    .W_BUFSIZE(1)
    )
    axi_write1
    (
    .I_ui_clk (O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(wr_cs[0]),

    .I_W_FS(ud_wvs1),
    .I_W_clk(ud_wclk1),
    .I_W_wren(ud_wde1),
    .I_W_data(ud_wdata1), 
    .O_W_sync_cnt(wbuf_sync_o1),
    .I_W_buf(0),
    .O_W_full(),

    
        
    .O_fdma_waddr(fdma_waddr1)  ,
    .O_fdma_wareq(fdma_wareq1)  ,
    .O_fdma_wsize(fdma_wsize1)  ,                                     
    .I_fdma_wbusy(fdma_wbusy1)  ,			
    .O_fdma_wdata(fdma_wdata1)	 ,
    .I_fdma_wvalid(fdma_wvalid1),
    .O_fdma_wready(fdma_wready1),
    .O_fdma_wdone (fdma_wdone1),
    .O_fmda_wbuf  (fdma_wbuf),	
    .O_fdma_wirq  (fdma_wirq)
    ); 
    
    axi_wr# (
    .VIDEO_ENABLE(1'b1),  
     
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    .W_BUFDEPTH(1024),
    .W_DATAWIDTH(32),//32
    .W_BASEADDR({7'd1,25'd0}),
    .W_DSIZEBITS(25),//23
    .W_XSIZE(960),
    .W_XSTRIDE(960),
    .W_YSIZE(540), 
    .W_XDIV(1), //2
    .W_BUFSIZE(1)
    )
    axi_write2
    (
    .I_ui_clk (O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(wr_cs[1]),

    .I_W_FS(ud_wvs2),
    .I_W_clk(ud_wclk2),
    .I_W_wren(ud_wde2),
    .I_W_data(ud_wdata2), 
    .O_W_sync_cnt(wbuf_sync_o2),
    .I_W_buf(0),
    .O_W_full(),

    
        
    .O_fdma_waddr(fdma_waddr2)  ,
    .O_fdma_wareq(fdma_wareq2)  ,
    .O_fdma_wsize(fdma_wsize2)  ,                                     
    .I_fdma_wbusy(fdma_wbusy2)  ,			
    .O_fdma_wdata(fdma_wdata2)	 ,
    .I_fdma_wvalid(fdma_wvalid2),
    .O_fdma_wready(fdma_wready2),
    .O_fdma_wdone (fdma_wdone2),
    .O_fmda_wbuf  (fdma_wbuf2),	
    .O_fdma_wirq  (fdma_wirq2)
    ); 
    
  axi_wr# (
    .VIDEO_ENABLE(1'b1),  
     
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    .W_BUFDEPTH(1024),
    .W_DATAWIDTH(32),//32
    .W_BASEADDR({7'd2,25'd0}),
    .W_DSIZEBITS(25),//23
    .W_XSIZE(480),
    .W_XSTRIDE(480),
    .W_YSIZE(1080), 
    .W_XDIV(1), //2
    .W_BUFSIZE(1)
    )
    axi_write3
    (
    .I_ui_clk (O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(wr_cs[2]),

    .I_W_FS(ud_wvs3),
    .I_W_clk(ud_wclk3),
    .I_W_wren(ud_wde3),
    .I_W_data(ud_wdata3), 
    .O_W_sync_cnt(wbuf_sync_o3),
    .I_W_buf(0),
    .O_W_full(),

    
        
    .O_fdma_waddr(fdma_waddr3)  ,
    .O_fdma_wareq(fdma_wareq3)  ,
    .O_fdma_wsize(fdma_wsize3)  ,                                     
    .I_fdma_wbusy(fdma_wbusy3)  ,			
    .O_fdma_wdata(fdma_wdata3)	 ,
    .I_fdma_wvalid(fdma_wvalid3),
    .O_fdma_wready(fdma_wready3),
    .O_fdma_wdone (fdma_wdone3),
    .O_fmda_wbuf  (fdma_wbuf3),	
    .O_fdma_wirq  (fdma_wirq3)
    ); 
    
    axi_wr# (
    .VIDEO_ENABLE(1'b1),  
     
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    .W_BUFDEPTH(1024),
    .W_DATAWIDTH(32),//32
    .W_BASEADDR({7'd4,25'd0}),
    .W_DSIZEBITS(25),//23
    .W_XSIZE(960),
    .W_XSTRIDE(960),
    .W_YSIZE(540), 
    .W_XDIV(1), //2
    .W_BUFSIZE(1)
    )
    axi_write4
    (
    .I_ui_clk (O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(wr_cs[3]),

    .I_W_FS(ud_wvs4),
    .I_W_clk(ud_wclk4),
    .I_W_wren(ud_wde4),
    .I_W_data(ud_wdata4), 
    .O_W_sync_cnt(wbuf_sync_o4),
    .I_W_buf(0),
    .O_W_full(),

    
        
    .O_fdma_waddr(fdma_waddr4)  ,
    .O_fdma_wareq(fdma_wareq4)  ,
    .O_fdma_wsize(fdma_wsize4)  ,                                     
    .I_fdma_wbusy(fdma_wbusy4)  ,			
    .O_fdma_wdata(fdma_wdata4)	 ,
    .I_fdma_wvalid(fdma_wvalid4),
    .O_fdma_wready(fdma_wready4),
    .O_fdma_wdone (fdma_wdone4),
    .O_fmda_wbuf  (fdma_wbuf4),	
    .O_fdma_wirq  (fdma_wirq4)
    ); 
    
    

read_register#(
. AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
. AXI_DATA_WIDTH (AXI_DATA_WIDTH)
)

u_read_register
(   
.   clk        (O_axi_clk),    
.   rst_n      (pll_locked),    
.   ready1     (fdma_rready1),   
.   ready2     (fdma_rready2),
.   ready3     (fdma_rready3),   
.   ready4     (fdma_rready4),
.   ready5     (fdma_rready5),   
.   ready6     (fdma_rready6),   
.   done1      (fdma_rdone1),    
.   done2      (fdma_rdone2), 
.   done3      (fdma_rdone3),    
.   done4      (fdma_rdone4),
.   done5      (fdma_rdone5),    
.   done6      (fdma_rdone6),  
.   cs         (rd_cs),      

//axi接口
.  O_fdma_raddr     (fdma_raddr)    ,// FDMA读通道地址                
.  O_fdma_rareq     (fdma_rareq)    ,// FDMA读通道请求                
.  O_fdma_rsize     (fdma_rsize)    ,// FDMA读通道一次FDMA的传输大小                                  
. i_fdma_rbusy  	(fdma_rbusy)    ,// FDMA处于BUSY状态，AXI总线正在读操作  		
. i_fdma_rdata	    (fdma_rdata)    ,// FDMA读数据 
. i_fdma_rvalid     (fdma_rvalid)   ,// FDMA 读有效



//app1

.I_fdma_raddr1    (fdma_raddr1)  ,
.I_fdma_rareq1    (fdma_rareq1)  ,
.I_fdma_rsize1    (fdma_rsize1)  ,                           
.O_fdma_rbusy1  	(fdma_rbusy1)  ,	
.O_fdma_rdata1	   (fdma_rdata1)	 ,
.O_fdma_rvalid1   (fdma_rvalid1), 


//app2

.  I_fdma_raddr2   (fdma_raddr2)  , 
.  I_fdma_rareq2   (fdma_rareq2)  , 
.  I_fdma_rsize2   (fdma_rsize2)  ,                            
.  O_fdma_rbusy2  	(fdma_rbusy2)  ,   	
.  O_fdma_rdata2	(fdma_rdata2)	 , 
.  O_fdma_rvalid2  (fdma_rvalid2) ,

//app3

.  I_fdma_raddr3   (fdma_raddr3)  , 
.  I_fdma_rareq3   (fdma_rareq3)  , 
.  I_fdma_rsize3   (fdma_rsize3)  ,                            
.  O_fdma_rbusy3  	(fdma_rbusy3)  ,   	
.  O_fdma_rdata3	(fdma_rdata3)	 , 
.  O_fdma_rvalid3  (fdma_rvalid3) ,

//app4

.  I_fdma_raddr4   (fdma_raddr4)  , 
.  I_fdma_rareq4   (fdma_rareq4)  , 
.  I_fdma_rsize4   (fdma_rsize4)  ,                            
.  O_fdma_rbusy4  	(fdma_rbusy4)  ,   	
.  O_fdma_rdata4	(fdma_rdata4)	 , 
.  O_fdma_rvalid4  (fdma_rvalid4) ,


//app5

.  I_fdma_raddr5   (fdma_raddr5)  , 
.  I_fdma_rareq5   (fdma_rareq5)  , 
.  I_fdma_rsize5   (fdma_rsize5)  ,                            
.  O_fdma_rbusy5  	(fdma_rbusy5)  ,   	
.  O_fdma_rdata5	(fdma_rdata5)	 , 
.  O_fdma_rvalid5  (fdma_rvalid5) ,


//app6

.  I_fdma_raddr6   (fdma_raddr6)  , 
.  I_fdma_rareq6   (fdma_rareq6)  , 
.  I_fdma_rsize6   (fdma_rsize6)  ,                            
.  O_fdma_rbusy6  	(fdma_rbusy6)  ,   	
.  O_fdma_rdata6	(fdma_rdata6)	 , 
.  O_fdma_rvalid6  (fdma_rvalid6) 


 );
 
 
 reg [8:0] shift_10;

reg  [19:0] row_size ;
reg  [19:0] col_size ;
wire  [26 :0]  x_add  ;
wire  [26 :0]  y_add  ;
wire           x_done ;
wire           y_done ;

reg  [26 :0]  x_add_r1  ;
reg  [26 :0]  y_add_r1  ;

reg         vtc_vs_valid_d1;
reg         vs_flag_d1;

wire        vs_flag  ;
wire        vtc_vs_valid;

assign vs_flag = ~ vtc_vs_valid&& vtc_vs_valid_d1;
always @(posedge vtc_clk) begin
            vtc_vs_valid_d1 <= vtc_vs_valid;
            vs_flag_d1      <= vs_flag     ;
    end
 
always @(posedge vtc_clk) begin
     if(!vtc_rstn)begin
      row_size    <={12'd960,8'd0}; 
     col_size    <={12'd540,8'd0};
     
     end
//     else  if(vs_flag)begin
//     if (shift_10==2)begin
//     shift_10<=0;
//     if(row_size   =={12'd960,8'd0})begin
//     
//     row_size    <={12'd480,8'd0}; 
//     col_size    <={12'd270,8'd0};
//     
//     end
//     
//     else begin
//     
//      
//     row_size    <=row_size   + {12'd1,8'd0} ;
//     col_size    <=col_size   + {12'd0,8'd144};
//      
//      
//      end
//      end
//      
//      else begin 
//      
//      shift_10<=shift_10+1;
//      
//      end
//       
//              
//     end   
end 


 div u_div1
  (
  .clk         (vtc_clk),
  .denominator ({row_size[19:9],1'b0}),  
  .numerator   ({12'd1920,15'd0}),
  .rst         (!vtc_rstn),
  .start       (vs_flag_d1),
  .done        (x_done),
  .quotient    (x_add)

  );
  
   div u_div2 
  (
  .clk         (vtc_clk),
  .denominator ({col_size[19:9],1'b0} ),
  .numerator   ({12'd1080,15'd0}),
  .rst         (!vtc_rstn),
  .start       (vs_flag_d1),
  .done        (y_done),
  .quotient    (y_add)

  );
  
  always @(posedge vtc_clk) begin
     if(!vtc_rstn)begin
      x_add_r1  <=  256;
      y_add_r1  <=  512;
     end
     else  begin
        if(x_done)begin
        x_add_r1  <=   x_add   ;
        end
        if(y_done)begin
        y_add_r1  <=   y_add   ;
        end
        
           
    end   
end 
  

    
 
axi_rd1# (
    .VIDEO_ENABLE(1'b1),  
    
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    

     .R_BUFDEPTH(1024),
    .R_DATAWIDTH(32),
    .R_BASEADDR(0),
    .R_DSIZEBITS(25),//23
    .R_XSIZE(480),
    .R_XSTRIDE(480),
    .R_YSIZE(1080),
    .R_XDIV(1),//2
    .R_BUFSIZE(1)
    )
    u_axi_rd1
    (
    .I_ui_clk(O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(rd_cs[0]),
    
    .vtc_de_valid(vtc_de_valid1),
    .I_R_FS(ud_rvs1),
    .I_R_clk(ud_rclk1),
    .I_R_rden(ud_rde1),
    .O_R_data(ud_rdata1),
    .O_R_sync_cnt(),
    .I_R_buf(0),
    .O_R_empty(),
        
    
    .O_fdma_raddr (fdma_raddr1)  ,
    .O_fdma_rareq (fdma_rareq1)  ,
    .O_fdma_rsize (fdma_rsize1)  ,                                     
    .I_fdma_rbusy (fdma_rbusy1)  ,			
    .I_fdma_rdata (fdma_rdata1)	 ,
    .I_fdma_rvalid(fdma_rvalid1),
    .O_fdma_rready(fdma_rready1),
    .O_fdma_rdone(fdma_rdone1),
    		
    .O_fmda_rbuf  (fdma_rbuf),	
    .O_fdma_rirq  (fdma_rirq),
    
    .x_add  (x_add_r1[26:0]),
    .y_add  ({y_add_r1[26:0]}),
    .col_size({col_size[19:9],1'b0}),
    .shift_en (shift_en1)
    
    
    ); 
    
    
    axi_rgb# (
    .VIDEO_ENABLE(1'b1),  
    
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    

     .R_BUFDEPTH(1024),
    .R_DATAWIDTH(32),
    .R_BASEADDR({7'd1,25'd0}),
    .R_DSIZEBITS(25),//23
    .R_XSIZE(960),
    .R_XSTRIDE(960),
    .R_YSIZE(540),
    .R_XDIV(1),//2
    .R_BUFSIZE(1)
    )
    u_axi_rd2
    (
    .I_ui_clk(O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(rd_cs[1]),
    
    .vtc_de_valid(vtc_de_valid2),
    .I_R_FS(ud_rvs2),
    .I_R_clk(ud_rclk2),
    .I_R_rden(ud_rde2),
    .O_R_data(ud_rdata2),
    .O_R_sync_cnt(),
    .I_R_buf(0),
    .O_R_empty(),
        
    
    .O_fdma_raddr (fdma_raddr2)  ,
    .O_fdma_rareq (fdma_rareq2)  ,
    .O_fdma_rsize (fdma_rsize2)  ,                                     
    .I_fdma_rbusy (fdma_rbusy2)  ,			
    .I_fdma_rdata (fdma_rdata2)	 ,
    .I_fdma_rvalid(fdma_rvalid2),
    .O_fdma_rready(fdma_rready2),
    .O_fdma_rdone(fdma_rdone2),
    		
    .O_fmda_rbuf  (fdma_rbuf2),	
    .O_fdma_rirq  (fdma_rirq2),
    
    .x_add  ({12'b1,15'b0}),       
    .y_add  ({12'b1,15'b0}),
    .col_size(540),
    .shift_en (shift_en2)
    
    
    ); 
    
    axi_rd1# (
    .VIDEO_ENABLE(1'b1),  
    
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    

     .R_BUFDEPTH(1024),
    .R_DATAWIDTH(32),
    .R_BASEADDR({7'd2,25'd0}),
    .R_DSIZEBITS(25),//23
    .R_XSIZE(480),
    .R_XSTRIDE(480),
    .R_YSIZE(1080),
    .R_XDIV(1),//2
    .R_BUFSIZE(1)
    )
    u_axi_rd3
    (
    .I_ui_clk(O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(rd_cs[2]),
    
    .vtc_de_valid(vtc_de_valid3),
    .I_R_FS(ud_rvs3),
    .I_R_clk(ud_rclk3),
    .I_R_rden(ud_rde3),
    .O_R_data(ud_rdata3),
    .O_R_sync_cnt(),
    .I_R_buf(0),
    .O_R_empty(),
        
    
    .O_fdma_raddr (fdma_raddr3)  ,
    .O_fdma_rareq (fdma_rareq3)  ,
    .O_fdma_rsize (fdma_rsize3)  ,                                     
    .I_fdma_rbusy (fdma_rbusy3)  ,			
    .I_fdma_rdata (fdma_rdata3)	 ,
    .I_fdma_rvalid(fdma_rvalid3),
    .O_fdma_rready(fdma_rready3),
    .O_fdma_rdone(fdma_rdone3),
    		
    .O_fmda_rbuf  (fdma_rbuf3),	
    .O_fdma_rirq  (fdma_rirq3),
    
    .x_add  ({12'd1,15'b0}),       
    .y_add  ({12'd1,15'b0}),
    .col_size(540),
    .shift_en(shift_en3)
    
    
    ); 
    
    axi_rgb# (
    .VIDEO_ENABLE(1'b1),  
    
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    

     .R_BUFDEPTH(1024),
    .R_DATAWIDTH(32),
    .R_BASEADDR({7'd4,25'd0}),
    .R_DSIZEBITS(25),//23
    .R_XSIZE(960),
    .R_XSTRIDE(960),
    .R_YSIZE(540),
    .R_XDIV(1),//2
    .R_BUFSIZE(1)
    )
    u_axi_rd4
    (
    .I_ui_clk(O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(rd_cs[3]),
    
    .vtc_de_valid(vtc_de_valid4),
    .I_R_FS(ud_rvs4),
    .I_R_clk(ud_rclk4),
    .I_R_rden(ud_rde4),
    .O_R_data(ud_rdata4),
    .O_R_sync_cnt(),
    .I_R_buf(0),
    .O_R_empty(),
        
    
    .O_fdma_raddr (fdma_raddr4)  ,
    .O_fdma_rareq (fdma_rareq4)  ,
    .O_fdma_rsize (fdma_rsize4)  ,                                     
    .I_fdma_rbusy (fdma_rbusy4)  ,			
    .I_fdma_rdata (fdma_rdata4)	 ,
    .I_fdma_rvalid(fdma_rvalid4),
    .O_fdma_rready(fdma_rready4),
    .O_fdma_rdone(fdma_rdone4),
    		
    .O_fmda_rbuf  (fdma_rbuf4),	
    .O_fdma_rirq  (fdma_rirq4),
    
    .x_add  ({12'b1,15'b0}),       
    .y_add  ({12'b1,15'b0}),
    .col_size(540),
    .shift_en (shift_en4)
    
    
    ); 
    
    
    axi_rd1# (
    .VIDEO_ENABLE(1'b1),  
    
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

    

     .R_BUFDEPTH(1024),
    .R_DATAWIDTH(32),
    .R_BASEADDR({7'd2,25'd0}),
    .R_DSIZEBITS(25),//23
    .R_XSIZE(480),
    .R_XSTRIDE(480),
    .R_YSIZE(1080),
    .R_XDIV(1),//2
    .R_BUFSIZE(1)
    )
    u_axi_rd5
    (
    .I_ui_clk(O_axi_clk),
    .I_ui_rstn(pll_locked),
    .cs(rd_cs[4]),
    
    .vtc_de_valid(vtc_de_valid5),
    .I_R_FS(ud_rvs5),
    .I_R_clk(ud_rclk5),
    .I_R_rden(ud_rde5),
    .O_R_data(ud_rdata5),
    .O_R_sync_cnt(),
    .I_R_buf(0),
    .O_R_empty(),
        
    
    .O_fdma_raddr (fdma_raddr5)  ,
    .O_fdma_rareq (fdma_rareq5)  ,
    .O_fdma_rsize (fdma_rsize5)  ,                                     
    .I_fdma_rbusy (fdma_rbusy5)  ,			
    .I_fdma_rdata (fdma_rdata5)	 ,
    .I_fdma_rvalid(fdma_rvalid5),
    .O_fdma_rready(fdma_rready5),
    .O_fdma_rdone(fdma_rdone5),
    		
    .O_fmda_rbuf  (fdma_rbuf5),	
    .O_fdma_rirq  (fdma_rirq5),
    
    .x_add  ({12'd1,15'b0}),       
    .y_add  ({12'd1,15'b0}),
    .col_size(540),
    .shift_en(shift_en5)
    
    
    ); 
    
    
    
    
  
    

 //以下代码需要注意时序设计，在正确的时序输出
    reg [0 :0] ud_rdata_cnt1; //synthesis keep
    reg [7 :0] ud_rdata_d1;//synthesis keep
   // reg  vtc_user_d1;//synthesis keep
   // reg  vtc_last_d1;//synthesis keep
    reg  vtc_de_valid_d1; //synthesis keep
    reg  vtc_de_valid_d0; //synthesis keep

    always @(posedge vtc_clk) begin
        if(vtc_de_valid1)
            ud_rdata_cnt1 <= ud_rdata_cnt1 + 'd1;
        else 
            ud_rdata_cnt1 <= 0;
    end

    always @(posedge vtc_clk) begin
           // vtc_user_d1     <= vtc_user;
           // vtc_last_d1     <= vtc_last;
            vtc_de_valid_d1 <= vtc_de_valid1;
    end
    
    always @(posedge vtc_clk) begin
           // vtc_user_d1     <= vtc_user;
           // vtc_last_d1     <= vtc_last;
            vtc_de_valid_d0 <= vtc_de_valid;
    end
    
   
    // 当vtc_de_valid = 1 ud_rdata_cnt =1 读1个数据，但是ud_rfifo_en延迟1个周期输出1，fifo再延迟1个周期更新数据
    always @(posedge vtc_clk) begin
        ud_rfifo_en1 <=  (ud_rdata_cnt1 == 1 )&&vtc_de_valid_d1;
    end

    always @(posedge vtc_clk) begin
        if(vtc_de_valid1)begin
            case(ud_rdata_cnt1)
                
                'd0: ud_rdata_d1 <=  ud_rdata1[15: 8];
                'd1: ud_rdata_d1 <=  ud_rdata1[7 : 0];
            default:
                ud_rdata_d1 <= ud_rdata_d1;
        endcase
        end
        else 
            ud_rdata_d1 <=0;
    end



   reg [0 :0] ud_rdata_cnt2; //synthesis keep
    reg [7 :0] ud_rdata_d2;//synthesis keep
   // reg  vtc_user_d1;//synthesis keep
   // reg  vtc_last_d1;//synthesis keep
    reg  vtc_de_valid_d2; //synthesis keep
    

    

    always @(posedge vtc_clk) begin
           // vtc_user_d1     <= vtc_user;
           // vtc_last_d1     <= vtc_last;
            vtc_de_valid_d2 <= vtc_de_valid2;
    end
    
   
    
   
    
    reg [0 :0] ud_rdata_cnt3; //synthesis keep

    reg  vtc_de_valid_d3; //synthesis keep
    

    always @(posedge vtc_clk) begin
        if(vtc_de_valid3)
            ud_rdata_cnt3 <= ud_rdata_cnt3 + 'd1;
        else 
            ud_rdata_cnt3 <= 0;
    end

    always @(posedge vtc_clk) begin
           // vtc_user_d1     <= vtc_user;
           // vtc_last_d1     <= vtc_last;
            vtc_de_valid_d3 <= vtc_de_valid3;
    end
   
   
    
   
    // 当vtc_de_valid = 1 ud_rdata_cnt =1 读1个数据，但是ud_rfifo_en延迟1个周期输出1，fifo再延迟1个周期更新数据
    always @(posedge vtc_clk) begin
        ud_rfifo_en3 <=  (ud_rdata_cnt3 == 1 )&&vtc_de_valid_d3;
    end

    always @(posedge vtc_clk) begin
        if(vtc_de_valid3)begin
            case(ud_rdata_cnt3)
                
                'd0: ud_rdata_d3 <=  ud_rdata3[15: 8];
                'd1: ud_rdata_d3 <=  ud_rdata3[7 : 0];
            default:
                ud_rdata_d3 <= ud_rdata_d3;
        endcase
        end
        else 
            ud_rdata_d3 <=0;
    end
    
    reg [0 :0] ud_rdata_cnt4; //synthesis keep
    reg [7 :0] ud_rdata_d4;//synthesis keep
   // reg  vtc_user_d1;//synthesis keep
   // reg  vtc_last_d1;//synthesis keep
    reg  vtc_de_valid_d4; //synthesis keep
    

    always @(posedge vtc_clk) begin
        if(vtc_de_valid4)
            ud_rdata_cnt4 <= ud_rdata_cnt4 + 'd1;
        else 
            ud_rdata_cnt4 <= 0;
    end

    always @(posedge vtc_clk) begin
           // vtc_user_d1     <= vtc_user;
           // vtc_last_d1     <= vtc_last;
            vtc_de_valid_d4 <= vtc_de_valid4;
    end
    
   
    
   
    // 当vtc_de_valid = 1 ud_rdata_cnt =1 读1个数据，但是ud_rfifo_en延迟1个周期输出1，fifo再延迟1个周期更新数据
    always @(posedge vtc_clk) begin
        ud_rfifo_en4 <=  (ud_rdata_cnt4 == 1 )&&vtc_de_valid_d4;
    end

    always @(posedge vtc_clk) begin
        if(vtc_de_valid4)begin
            case(ud_rdata_cnt4)
                
                'd0: ud_rdata_d4 <=  ud_rdata4[15: 8];
                'd1: ud_rdata_d4 <=  ud_rdata4[7 : 0];
            default:
                ud_rdata_d4 <= ud_rdata_d4;
        endcase
        end
        else 
            ud_rdata_d4 <=0;
    end
    
    reg [0 :0] ud_rdata_cnt5; //synthesis keep
    
   // reg  vtc_user_d1;//synthesis keep
   // reg  vtc_last_d1;//synthesis keep
    reg  vtc_de_valid_d5; //synthesis keep
    

    always @(posedge vtc_clk) begin
        if(vtc_de_valid5)
            ud_rdata_cnt5 <= ud_rdata_cnt5 + 'd1;
        else 
            ud_rdata_cnt5 <= 0;
    end

    always @(posedge vtc_clk) begin
           // vtc_user_d1     <= vtc_user;
           // vtc_last_d1     <= vtc_last;
            vtc_de_valid_d5 <= vtc_de_valid5;
    end
    
   
    
   
    // 当vtc_de_valid = 1 ud_rdata_cnt =1 读1个数据，但是ud_rfifo_en延迟1个周期输出1，fifo再延迟1个周期更新数据
    always @(posedge vtc_clk) begin
        ud_rfifo_en5 <=  (ud_rdata_cnt5 == 1 )&&vtc_de_valid_d5;
    end

    always @(posedge vtc_clk) begin
        if(vtc_de_valid5)begin
            case(ud_rdata_cnt5)
                
                'd0: ud_rdata_d5 <=  ud_rdata5[15: 8];
                'd1: ud_rdata_d5 <=  ud_rdata5[7 : 0];
            default:
                ud_rdata_d5 <= ud_rdata_d5;
        endcase
        end
        else 
            ud_rdata_d5 <=0;
    end


reg [0 :0] ud_rdata_cnt6; //synthesis keep
    reg [7 :0] ud_rdata_d6;//synthesis keep
   // reg  vtc_user_d1;//synthesis keep
   // reg  vtc_last_d1;//synthesis keep
    reg  vtc_de_valid_d6; //synthesis keep
    

    always @(posedge vtc_clk) begin
        if(vtc_de_valid6)
            ud_rdata_cnt6 <= ud_rdata_cnt6 + 'd1;
        else 
            ud_rdata_cnt6 <= 0;
    end

    always @(posedge vtc_clk) begin
           // vtc_user_d1     <= vtc_user;
           // vtc_last_d1     <= vtc_last;
            vtc_de_valid_d6 <= vtc_de_valid6;
    end
    
   
    
   
    // 当vtc_de_valid = 1 ud_rdata_cnt =1 读1个数据，但是ud_rfifo_en延迟1个周期输出1，fifo再延迟1个周期更新数据
    always @(posedge vtc_clk) begin
        ud_rfifo_en6 <=  (ud_rdata_cnt6 == 1 )&&vtc_de_valid_d6;
    end

    always @(posedge vtc_clk) begin
        if(vtc_de_valid6)begin
            case(ud_rdata_cnt6)
                
                'd0: ud_rdata_d6 <=  ud_rdata6[15: 8];
                'd1: ud_rdata_d6 <=  ud_rdata6[7 : 0];
            default:
                ud_rdata_d6 <= ud_rdata_d6;
        endcase
        end
        else 
            ud_rdata_d6 <=0;
    end
    
    
    




   

    wire 			w_rgb_vsync1, w_rgb_href1; //synthesis keep
    wire 	[7:0] 	w_rgb_r1, w_rgb_g1, w_rgb_b1; 


    raw8_2_rgb888 u_raw8_2_rgb888_1 
    (
    .I_clk	        (vtc_clk),                //cmos video pixel clock
    .I_rst_n	    (vtc_rstn&&(~shift_en1)),              //global reset
            
    //CMOS YCbCr444 data output
    .I_raw_vs	    (~vtc_vs),    //Prepared Image data vsync valid signal. Reset on falling edge. 
    .I_raw_de	    (vtc_de_valid_d1),     //Prepared Image data href vaild  signal
    .I_raw_data	    (ud_rdata_d1),        //Prepared Image data 8 Bit RAW Data
    
    .size_shift     (shift_en1),
    .h_size         ({row_size[19:9],1'b0} ),
    .v_size         ({col_size[19:9],1'b0} ),

    .O_rgb_vs	    (w_rgb_vsync1),   //Processed Image data vsync valid signal
    .O_rgb_de	    (w_rgb_href1),    //Processed Image data href vaild  signal
    .O_rgb_r		(w_rgb_r1),       //Prepared Image green data to be processed 
    .O_rgb_g	    (w_rgb_g1),     //Prepared Image green data to be processed
    .O_rgb_b		(w_rgb_b1),       //Prepared Image blue data to be processed
    
    .I_data_choice  ( vtc_de_valid_d0 ),
    .O_data_choice  ( cam_choice2 )
    );

    wire 			w_rgb_vsync3, w_rgb_href3; //synthesis keep
    wire 	[7:0] 	w_rgb_r3, w_rgb_g3, w_rgb_b3; 


    raw8_2_rgb888 u_raw8_2_rgb888_3
    (
    .I_clk	        (vtc_clk),                //cmos video pixel clock
    .I_rst_n	    (vtc_rstn&&(~shift_en3)),              //global reset
            
    //CMOS YCbCr444 data output
    .I_raw_vs	    (~vtc_vs),    //Prepared Image data vsync valid signal. Reset on falling edge. 
    .I_raw_de	    (vtc_de_valid_d3),     //Prepared Image data href vaild  signal
    .I_raw_data	    (ud_rdata_d3),        //Prepared Image data 8 Bit RAW Data
    
    .size_shift     (shift_en3),
    .h_size         ({row_size[19:9],1'b0} ),
    .v_size         ({col_size[19:9],1'b0} ),

    .O_rgb_vs	    (w_rgb_vsync3),   //Processed Image data vsync valid signal
    .O_rgb_de	    (w_rgb_href3),    //Processed Image data href vaild  signal
    .O_rgb_r		(w_rgb_r3),       //Prepared Image green data to be processed 
    .O_rgb_g	    (w_rgb_g3),     //Prepared Image green data to be processed
    .O_rgb_b		(w_rgb_b3)
    );



    
    

    awb u_awb1 
    (
    .I_clk          (vtc_clk),
    .I_rst_n        (vtc_rstn),

    .I_red_gain     (0),
    .I_green_gain   (0),
    .I_blue_gain    (0),

    .I_awb_vs       (w_rgb_vsync1),
    .I_awb_hs       (w_rgb_href1),
    .I_awb_de       (w_rgb_href1),
    .I_awb_rgb      ({w_rgb_r1, w_rgb_g1, w_rgb_b1}),

    .O_awb_vs       (w_awb_vs1),
    .O_awb_hs       (w_awb_hs1),
    .O_awb_de       (w_awb_de1),
    .O_awb_rgb      ({w_awb_r1, w_awb_g1, w_awb_b1}),
    
    .I_data_choice  ( cam_choice2 ),
    .O_data_choice  ( cam_choice3 )
    
    );
    
    awb u_awb3
    (
    .I_clk          (vtc_clk),
    .I_rst_n        (vtc_rstn),

    .I_red_gain     (0),
    .I_green_gain   (0),
    .I_blue_gain    (0),

    .I_awb_vs       (w_rgb_vsync3),
    .I_awb_hs       (w_rgb_href3),
    .I_awb_de       (w_rgb_href3),
    .I_awb_rgb      ({w_rgb_r3, w_rgb_g3, w_rgb_b3}),

    .O_awb_vs       (w_awb_vs3),
    .O_awb_hs       (w_awb_hs3),
    .O_awb_de       (w_awb_de3),
    .O_awb_rgb      ({w_awb_r3, w_awb_g3, w_awb_b3})
    
    );
    
 wire              delay_de2  ;
 wire [23:0]       delay_rgb2 ;
  wire              delay_de4  ;
 wire [23:0]       delay_rgb4 ;
 wire              delay_de5  ;
 wire [23:0]       delay_rgb5 ;
    
    
delay u_delay2
(
         .I_clk        (vtc_clk), 
         .I_rst_n      (vtc_rstn),
    
   
         .I_de         ( vtc_de_valid_d2       ),
         .I_rgb        ({ud_rdata2[15:11], 3'b0,ud_rdata2[10: 5], 2'b0, ud_rdata2[4: 0], 3'b0}  ) ,
    
        
         .O_de         ( delay_de2    ),
         .O_rgb        ( delay_rgb2   )
    

    
    
);

delay u_delay4
(
         .I_clk        (vtc_clk), 
         .I_rst_n      (vtc_rstn),
    
   
         .I_de         ( vtc_de_valid_d4       ),
         .I_rgb        ({ud_rdata4[15:11], 3'b0,ud_rdata4[10: 5], 2'b0, ud_rdata4[4: 0], 3'b0}  ) ,
    
        
         .O_de         ( delay_de4    ),
         .O_rgb        ( delay_rgb4   )
    

    
    
);

delay u_delay5
(
         .I_clk        (vtc_clk), 
         .I_rst_n      (vtc_rstn),
    
   
         .I_de         ( vtc_de_valid_d5       ),
         .I_rgb        ({ud_rdata_d5, ud_rdata_d5, ud_rdata_d5}  ) ,
    
        
         .O_de         ( delay_de5    ),
         .O_rgb        ( delay_rgb5   )
    

    
    
);

    wire  message_valid_out1;
    wire  message_valid_out2;
    wire  message_valid_out3;
    wire  message_valid_out4;
    reg   cam_choice4;

    wire 			w_crop_vs, w_crop_hs;//synthesis keep 
    wire			w_crop_de;//synthesis keep
    wire 	[23:0] 	w_crop_data;//synthesis keep
    reg 	[23:0]  O_w_crop_data ;
    wire 	[23:0]  O_w_crop_data1 ;
    wire 	[23:0]  O_w_crop_data2 ;
    wire 	[23:0]  O_w_crop_data3 ;
    wire 	[23:0]  O_w_crop_data4 ;
    wire 	[23:0]  O_w_crop_data5 ;
    wire 	[23:0]  O_w_crop_data6 ;
    

    bound_cut u_bound_cut 
    (
    .I_clk		    (vtc_clk),
    .I_awb_vs 		(w_awb_vs),
    .I_awb_hs 		(w_awb_hs),
    .I_awb_de 		(w_awb_de),
    .I_awb_data 	({w_awb_r, w_awb_g, w_awb_b}),
            
    .O_awb_vs 		(w_crop_vs),
    .O_awb_hs 		(w_crop_hs),
    .O_awb_de 		(w_crop_de),
    .O_awb_data     (w_crop_data)
    );
    

  

Window_hdmi u_message_hdmi1(
 .clk            ( vtc_clk           ) ,
 .rst_n          ( vtc_rstn           ) , 
 .start          (vtc_de_valid         ),     
 .message        ({w_awb_r1, w_awb_g1, w_awb_b1}  ) ,
 .lcd_xpos       (lcd_xpos           ),
 .lcd_ypos       (lcd_ypos           ),
 
 .hdmi_vs        (shift_en1    ),
 
 .x_start        ( 11'd480 - row_size[19:9]        ) ,
 .y_start        ( 11'd270 - col_size[19:9]        ) ,
 .x_end          ( 11'd480 +  row_size[19:9]         ) ,
 .y_end          ( 11'd270 +  col_size[19:9]        ) ,
 .valid          ( w_awb_de1       ),
 .message_out    ( O_w_crop_data1           ),
 .data_req_sdram (  vtc_de_valid1   ),
 .message_valid_out(message_valid_out1)
 );
 
 Window_hdmi u_message_hdmi2(
 .clk            ( vtc_clk           ) ,
 .rst_n          ( vtc_rstn           ) , 
 .start          (vtc_de_valid         ),     
 .message        (delay_rgb2 ) ,
 .lcd_xpos       (lcd_xpos           ),
 .lcd_ypos       (lcd_ypos           ),
 
 .hdmi_vs        (shift_en2    ),
 
 .x_start        ( 11'd1440 -row_size[19:9]        ) ,
 .y_start        ( 11'd270  -col_size[19:9]        ) ,
 .x_end          ( 11'd1440 +row_size[19:9]         ) ,
 .y_end          ( 11'd270  +col_size[19:9]      ) ,
 .valid          ( delay_de2       ),
 .message_out    ( O_w_crop_data2           ),
 .data_req_sdram ( vtc_de_valid2    ),
  .message_valid_out(message_valid_out2)
 
 
 );
 
 Window_hdmi u_message_hdmi3(
 .clk            ( vtc_clk           ) ,
 .rst_n          ( vtc_rstn           ) , 
 .start          (vtc_de_valid         ),     
 .message        ( delay_rgb5 ) ,
 .lcd_xpos       (lcd_xpos           ),
 .lcd_ypos       (lcd_ypos           ),
 
 .hdmi_vs        (shift_en5    ),
 
 .x_start        ( 11'd480 - row_size[19:9]        ) ,
 .y_start        ( 11'd810 - col_size[19:9]        ) ,
 .x_end          ( 11'd480  +  row_size[19:9]         ) ,
 .y_end          ( 11'd810 +  col_size[19:9]        ) ,
 .valid          (delay_de5        ),
 .message_out    ( O_w_crop_data3           ),
 .data_req_sdram (  vtc_de_valid5   ),
  .message_valid_out(message_valid_out3)
 );
 

 
 
 Window_hdmi u_message_hdmi4(
 .clk            ( vtc_clk           ) ,
 .rst_n          ( vtc_rstn           ) , 
 .start          (vtc_de_valid         ),     
 .message        ( delay_rgb4 ) ,
 .lcd_xpos       (lcd_xpos           ),
 .lcd_ypos       (lcd_ypos           ),
 
 .hdmi_vs        (shift_en4    ),
 
 .x_start        ( 11'd1440 - row_size[19:9]        ) ,
 .y_start        ( 11'd810 - col_size[19:9]        ) ,
 .x_end          ( 11'd1440 +  row_size[19:9]         ) ,
 .y_end          ( 11'd810 +  col_size[19:9]        ) ,

 .valid          ( delay_de4       ),
 .message_out    ( O_w_crop_data4           ),
 .data_req_sdram (  vtc_de_valid4   ),
  .message_valid_out(message_valid_out4)
 );
 
 reg    hdmi_vs   ;
 reg    hdmi_vs1  ;
 reg    hdmi_vs2  ;
 reg    hdmi_vs3  ;
 reg    hdmi_de   ;
 
 
 always @(posedge vtc_clk) begin
           
      case({message_valid_out1,message_valid_out2,message_valid_out3,message_valid_out4 ,1'b0,1'b0}) 
      6'd1:
      begin
      O_w_crop_data<=O_w_crop_data6;
      end
      6'd2:
      begin
      O_w_crop_data<=O_w_crop_data5;
      end
      6'd4:
      begin
      O_w_crop_data<=O_w_crop_data4;
      end    
      6'd8:
      begin
      O_w_crop_data<=O_w_crop_data3;
      end   
      6'd16:
      begin
      O_w_crop_data<=O_w_crop_data2;
      end  
      6'd32:
      begin
      O_w_crop_data<=O_w_crop_data1;
      end
      default:
      begin
      O_w_crop_data<={8'd255,8'd255,8'd255 };
      end
      
           
           
           
           
     endcase  
     hdmi_vs    <= w_awb_vs1;
     hdmi_vs1   <=hdmi_vs;
     hdmi_vs2   <=hdmi_vs1;
     hdmi_vs3   <=hdmi_vs2;
     cam_choice4<=cam_choice3;
     hdmi_de    <= cam_choice4;    
           
    end



    uivtc#
    (
    .H_ActiveSize       (1920), //视频时间参数,行视频信号，一行有效(需要显示的部分)像素所占的时钟数，一个时钟对应一个有效像素
    .H_SyncStart        (1920+88), //视频时间参数,行同步开始，即多少时钟数后开始产生行同步信号 
    .H_SyncEnd          (1920+88+44),//视频时间参数,行同步结束，即多少时钟数后停止产生行同步信号，之后就是行有效数据部分
    .H_FrameSize        (1920+88+44+148), //视频时间参数,行视频信号，一行视频信号总计占用的时钟数

    .V_ActiveSize       (1080),//视频时间参数,场视频信号，一帧图像所占用的有效(需要显示的部分)行数量，通常说的视频分辨率即H_ActiveSize*V_ActiveSize
    .V_SyncStart        (1080+4),//视频时间参数,场同步开始，即多少行数后开始产生场同步信号 
    .V_SyncEnd          (1080+4+5), //视频时间参数,场同步结束，多少行后停止产生长同步信号  
    .V_FrameSize        (1080+4+5+36) //视频时间参数,场视频信号，一帧视频信号总计占用的行数量       
    )
    uivtc_inst
    (
    .I_vtc_clk(vtc_clk),  //系统时钟 
    .I_vtc_rstn(vtc_rstn),//系统复位
    .O_vtc_vs  (vtc_vs),//场同步输出
    .O_vtc_hs  (vtc_hs),//行同步输出
    .O_vtc_de_valid(vtc_de_valid),//视频数据有效
    .O_vtc_vs_valid(vtc_vs_valid),
    .lcd_xpos      (  lcd_xpos  ),
    .lcd_ypos      (  lcd_ypos  )
                   
    );
    
    
    
    
    
    
    
    
    
    



    //hdmi 输出IP
    hdmi_tx#(
    //HDMI视频参数设置       
    .H_ActiveSize       (1920), //视频时间参数,行视频信号，一行有效(需要显示的部分)像素所占的时钟数，一个时钟对应一个有效像素
    .H_SyncStart        (1920+88), //视频时间参数,行同步开始，即多少时钟数后开始产生行同步信号 
    .H_SyncEnd          (1920+88+44),//视频时间参数,行同步结束，即多少时钟数后停止产生行同步信号，之后就是行有效数据部分
    .H_FrameSize        (1920+88+44+148), //视频时间参数,行视频信号，一行视频信号总计占用的时钟数

    .V_ActiveSize       (1080),//视频时间参数,场视频信号，一帧图像所占用的有效(需要显示的部分)行数量，通常说的视频分辨率即H_ActiveSize*V_ActiveSize
    .V_SyncStart        (1080+4),//视频时间参数,场同步开始，即多少行数后开始产生场同步信号 
    .V_SyncEnd          (1080+4+5), //视频时间参数,场同步结束，多少行后停止产生长同步信号  
    .V_FrameSize        (1080+4+5+36),  //视频时间参数,场视频信号，一帧视频信号总计占用的行数量               
        
    .VIDEO_VIC          ( 16       ),
    .VIDEO_TPG          ( "Disable"),//设置disable，用户数据驱动HDMI接口，否则设置eable产生内部测试图形
    .VIDEO_FORMAT       ( "RGB444" )//设置输入数据格式为RGB格式
    )u_hdmi_tx
    (
    .I_pixel_clk        ( S_hdmi_clk           ),//像素时钟
    .I_serial_clk       ( S_serial_clk           ),//串行发送时钟
    .I_rst              ( S_rst              ),//异步复位信号，高电平有效

    .I_video_rgb_enable (1'b1                ),//是否使能RGB输入接口，设置1使能，否则采用stream video时序接口  
    .I_video_in_vs      (hdmi_vs3            ),//RGB 输入VS 帧同步
    .I_video_in_de      (hdmi_de             ),//RGB 输入de有效
    .I_video_in_data    (O_w_crop_data  ), //视频输入数据     

    .O_hdmi_clk_p       ( O_hdmi_clk_p       ),//HDMI时钟通道
    .O_hdmi_tx_p        ( O_hdmi_tx_p        )//HDMI数据通道
    );


    video_cutting u_video_cutting1(
        .I_clk              ( S_hs_rx_clk1            ),
        .I_rst_n            ( ~S_rst                 ),
    
        .I_raw8_frame_start ( S_raw8_frame_start1     ),
        .I_raw8_frame_end   ( S_raw8_frame_end1       ),
        .I_raw8_valid       ( S_raw8_valid1           ),
        .I_raw8_data        ( S_raw8_data1            ),

        .O_raw8_frame_start ( S_raw8_cut_frame_start1 ),
        .O_raw8_frame_end   ( S_raw8_cut_frame_end1   ),
        .O_raw8_valid       ( S_raw8_cut_valid1       ),
        .O_raw8_data        ( S_raw8_cut_data1        )
    );
    
     video_cutting u_video_cutting2(
        .I_clk              ( S_hs_rx_clk2            ),
        .I_rst_n            ( ~S_rst                 ),
    
        .I_raw8_frame_start ( S_raw8_frame_start2     ),
        .I_raw8_frame_end   ( S_raw8_frame_end2       ),
        .I_raw8_valid       ( S_raw8_valid2           ),
        .I_raw8_data        ( S_raw8_data2            ),

        .O_raw8_frame_start ( S_raw8_cut_frame_start2 ),
        .O_raw8_frame_end   ( S_raw8_cut_frame_end2   ),
        .O_raw8_valid       ( S_raw8_cut_valid2       ),
        .O_raw8_data        ( S_raw8_cut_data2        )
    );


    raw10_unpacket u_raw10_unpacket1(
        .I_clk                ( S_hs_rx_clk1          ), 
        .I_rst_n              ( ~S_rst               ),
                                                     
        .I_csi_frame_start    ( S_csi_frame_start1    ),
        .I_csi_frame_end      ( S_csi_frame_end1      ),
        .I_csi_valid          ( S_csi_valid1          ),
        .I_csi_data           ( S_csi_data1           ),
        
       	.I_camera_black_level ( S_camera_black_level ),

        .O_raw8_frame_start   ( S_raw8_frame_start1   ),
        .O_raw8_frame_end     ( S_raw8_frame_end1     ),
        .O_raw8_valid         ( S_raw8_valid1         ),
        .O_raw8_data          ( S_raw8_data1          )
    );
    
    raw10_unpacket u_raw10_unpacket2(
        .I_clk                ( S_hs_rx_clk2          ), 
        .I_rst_n              ( ~S_rst               ),
                                                     
        .I_csi_frame_start    ( S_csi_frame_start2    ),
        .I_csi_frame_end      ( S_csi_frame_end2      ),
        .I_csi_valid          ( S_csi_valid2          ),
        .I_csi_data           ( S_csi_data2           ),
        
       	.I_camera_black_level ( S_camera_black_level ),

        .O_raw8_frame_start   ( S_raw8_frame_start2   ),
        .O_raw8_frame_end     ( S_raw8_frame_end2     ),
        .O_raw8_valid         ( S_raw8_valid2         ),
        .O_raw8_data          ( S_raw8_data2          )
    );


    csi_unpacket u_csi_unpacket1(
        .I_clk             ( S_hs_rx_clk1      ),
        .I_rst_n           ( ~S_rst            ),

        .I_hs_valid        ( S_hs_rx_valid1     ),
        .I_hs_data         ( S_hs_rx_data1      ),

        .O_csi_frame_start ( S_csi_frame_start1 ),
        .O_csi_frame_end   ( S_csi_frame_end1   ),
        .O_csi_rx_vsync0	( S_csi_rx_vsync01	),
    	.O_csi_rx_hsync0	( S_csi_rx_hsync01	),
        .O_csi_valid       ( S_csi_valid1       ),
        .O_csi_data        ( S_csi_data1        )
    );
    
   csi_unpacket u_csi_unpacket2(
      .I_clk             ( S_hs_rx_clk2      ),
      .I_rst_n           ( ~S_rst            ),

      .I_hs_valid        ( S_hs_rx_valid2     ),
      .I_hs_data         ( S_hs_rx_data2      ),

      .O_csi_frame_start ( S_csi_frame_start2 ),
      .O_csi_frame_end   ( S_csi_frame_end2   ),
      .O_csi_rx_vsync0	( S_csi_rx_vsync02	),
  	.O_csi_rx_hsync0	( S_csi_rx_hsync02	),
      .O_csi_valid       ( S_csi_valid2       ),
      .O_csi_data        ( S_csi_data2        )
  );



    mipi_dphy_rx_ph1a_mipiio_wrapper#(
        .LANE_NUM              ( 4 ),
        .BYTE_NUM              ( 1 )
    )u_mipi_dphy_rx_ph1a_mipiio_wrapper1(
        .I_lp_clk              ( S_clk_70m       ), 
        .I_rst                 ( S_rst           ),
 
        .I_clk_lane_in_delay   ( 9'd0            ),
        .I_data_lane0_in_delay ( 9'd0            ),
        .I_data_lane1_in_delay ( 9'd0            ),
        .I_data_lane2_in_delay ( 9'd0            ),
        .I_data_lane3_in_delay ( 9'd0            ),

        .I_lane_invert         ( 4'b0000         ),//1101 

        .O_hs_rx_clk           ( S_hs_rx_clk1    ),
        .O_hs_rx_valid         ( S_hs_rx_valid1   ),
        .O_hs_rx_data          ( S_hs_rx_data1    ),

        .O_lp_rx_lane0_p       (  ),
        .O_lp_rx_lane0_n       (  ),

        .I_lp_tx_en            ( 1'b0            ),
        .I_lp_tx_lane0_p       ( 1'b0            ),
        .I_lp_tx_lane0_n       ( 1'b0            ),

        .O_lane_error          ( S_lane_error1    )
    );
// mipi_dphy_rx_ph1a_mipiio_wrapper#(
//        .LANE_NUM              ( 4 ),
//        .BYTE_NUM              ( 1 )
//    )u_mipi_dphy_rx_ph1a_mipiio_wrapper2(
//        .I_lp_clk              ( S_clk_70m       ), 
//        .I_rst                 ( S_rst           ),
// 
//        .I_clk_lane_in_delay   ( 9'd0            ),
//        .I_data_lane0_in_delay ( 9'd0            ),
//        .I_data_lane1_in_delay ( 9'd0            ),
//        .I_data_lane2_in_delay ( 9'd0            ),
//        .I_data_lane3_in_delay ( 9'd0            ),
//
//        .I_lane_invert         ( 4'b0000         ),//1101 
//
//        .O_hs_rx_clk           ( S_hs_rx_clk2     ),
//        .O_hs_rx_valid         ( S_hs_rx_valid2   ),
//        .O_hs_rx_data          ( S_hs_rx_data2    ),
//
//        .O_lp_rx_lane0_p       (  ),
//        .O_lp_rx_lane0_n       (  ),
//
//        .I_lp_tx_en            ( 1'b0            ),
//        .I_lp_tx_lane0_p       ( 1'b0            ),
//        .I_lp_tx_lane0_n       ( 1'b0            ),
//
//        .O_lane_error          ( S_lane_error2    )
//    );

    
endmodule
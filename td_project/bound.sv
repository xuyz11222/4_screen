module   obj_check_and_boundary#(
    
 parameter       H_PIXEL      =    11'd960     ,
 parameter       V_PIXEL      =    10'd540   ,
 parameter       MIN_DISC     =    10'd100  

)(

 input                  vtc_clk        ,
 input                  vtc_rstn       ,
 input                  isp_href       ,
 input                  isp_vsync      ,
 input                  isp_wr_en      ,
 input                  isp_1bit_out   ,
 input      [15:0]      syn_data       ,

output      [15:0]      fusion_rgb565  ,
output      [23:0]      fusion_rgb888  ,
output                  fusion_hs      ,
output                  fusion_vs      ,
output                  fusion_wr_en   ,               
output      [7:0]       obj_num        




); 
 
 wire                         mul_hs                      ;
 wire                         mul_vs                      ;
 wire                         mul_wr_en                   ;
wire [42:0] pos_data [15:0];



isp_mul_obj_check
#(
    .H_PIXEL                           (H_PIXEL                   ),
    .V_PIXEL                           (V_PIXEL                   ),
    .MIN_DISC                          (MIN_DISC                  ) 
)
u_isp_mul_obj_check(
    .sys_clk                           (vtc_clk                   ),
    .sys_rst_n                         (vtc_rstn                  ),
    .pre_hs                            (isp_href                  ),
    .pre_vs                            (isp_vsync                 ),
    .pre_wr_en                         (isp_wr_en                 ),
    .pre_1bit                          (isp_1bit_out              ),

    .mul_hs                            (mul_hs                    ),
    .mul_vs                            (mul_vs                    ),
    .mul_wr_en                         (mul_wr_en                 ),
    .pos_data_out                      (pos_data                  ) 
);

boundary_fusion
#(
    .H_PIXEL                           (H_PIXEL                   ),
    .V_PIXEL                           (V_PIXEL                   ) 
)
u_boundary_fusion(
    .sys_clk                           ( vtc_clk                  ),
    .sys_rst_n                         ( vtc_rstn                 ),
    .pre_wr_en                         (mul_wr_en                 ),
    .pre_hs                            (mul_hs                    ),
    .pre_vs                            (mul_vs                    ),
    .pos_data                          (pos_data                  ),
    .cam_data                          (syn_data                  ),

    .fusion_rgb565                     (fusion_rgb565             ),
    .fusion_rgb888                     (fusion_rgb888             ),
    .fusion_hs                         (fusion_hs                 ),
    .fusion_vs                         (fusion_vs                 ),
    .fusion_wr_en                      (fusion_wr_en              ),
    .fusion_r                          (                          ),
    .fusion_g                          (                          ),
    .fusion_b                          (                          ),
    .obj_num                           (obj_num                   ) 
);


endmodule

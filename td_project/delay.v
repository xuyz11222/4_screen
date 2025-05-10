
/*********awb  白平衡算法***********
*********************************************************************/

module delay
(
    input  wire                 I_clk             ,
    input  wire                 I_rst_n           ,
    
    input  wire                 I_vs          ,
    input  wire                 I_hs          ,
    input  wire                 I_de          ,
    input  wire     [23:0]      I_rgb         ,
    
    output reg                  O_vs          ,
    output reg                  O_hs          ,
    output reg                  O_de          ,
    output reg      [23:0]      O_rgb         
    

    
    
);

reg               vs1      ;
reg               hs1      ;
reg               de1      ;
reg   [23:0]      rgb1     ;
reg               vs2      ;
reg               hs2      ;
reg               de2      ;
reg   [23:0]      rgb2     ;
reg               vs3      ;
reg               hs3      ;
reg               de3      ;
reg   [23:0]      rgb3     ;
reg               vs4      ;
reg               hs4      ;
reg               de4      ;
reg   [23:0]      rgb4     ;
reg               vs5      ;
reg               hs5      ;
reg               de5      ;
reg   [23:0]      rgb5     ;





always @(posedge I_clk) begin





vs1        <=    I_vs    ;
hs1        <=    I_hs    ;
de1        <=    I_de    ;
rgb1       <=    I_rgb   ;
vs2        <=    vs1     ;
hs2        <=    hs1     ;
de2        <=    de1     ;
rgb2       <=    rgb1    ;
vs3        <=    vs2     ;
hs3        <=    hs2     ;
de3        <=    de2     ;
rgb3       <=    rgb2    ;
vs4        <=    vs3     ;
hs4        <=    hs3     ;
de4        <=    de3     ;
rgb4       <=    rgb3    ;
vs5        <=    vs4     ;
hs5        <=    hs4     ;
de5        <=    de4     ;
rgb5       <=    rgb4    ;
O_vs       <=    vs5     ;
O_hs       <=    hs5     ;
O_de       <=    de5     ;
O_rgb	   <=    rgb5    ;
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 

end


endmodule

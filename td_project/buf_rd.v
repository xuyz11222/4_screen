module buf_rd#( 
parameter integer X_size  =960,
parameter integer Y_size  =1080
)(
    input          rd_clk,
    input          rst_n,
    input          renew,
    input   [12:0] x_rd_size,
    input   [12:0] y_rd_size,
    output  reg   [19:0] x_add,
    output  reg   [19:0] y_add

);


wire         x_done;
wire  [19:0] x_add1;
wire         y_done;
wire  [19:0] y_add1;



 divider u_divider1
  (
  .clk           (   rd_clk          ),
  .denominator   (   {x_rd_size,8'b0}          ),
  .numerator     (    X_size        ),
  .rst           (   !rst_n          ),
  .start         (    renew         ),
  .done          (    x_done         ),
  .quotient      (    x_add1         )
  
  );

divider u_divider2
  (
  .clk           (   rd_clk          ),
  .denominator   (   {y_rd_size,8'b0}          ),
  .numerator     (    Y_size         ),
  .rst           (   !rst_n          ),
  .start         (    renew         ),
  .done          (    y_done         ),
  .quotient      (    y_add1         )
  
  );

always@(posedge rd_clk) begin  
    if(!rst_n)begin
     x_add <=256;
     y_add <=256;
    end  
    else begin 
      if( x_done)begin
      x_add<=x_add1;
      end
      if( y_done)begin
      y_add<=y_add1;
      end
    end
end













endmodule

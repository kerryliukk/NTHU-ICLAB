module fir1_parallel
#(parameter N=32)
(
input      clk,
input      rst_n,
input      enable,
input      [N-1:0]x0,
input      [N-1:0]x1,
output reg busy,
output reg valid,
output reg [N-1:0]y0,
output reg [N-1:0]y1
);

localparam IDLE = 2'd0,
           EVA  = 2'd1,
           CAL  = 2'd2;

wire signed [N-1:0]a[15:0];
reg signed [N-1:0] y_n0,y_n1;
reg signed [N-1:0] x_tmp0[7:0];
reg signed [N-1:0] x_n0[7:0];
reg signed [N-1:0] x_tmp1[8:0];
reg signed [N-1:0] x_n1[8:0];
reg [1:0] state, state_n;
reg [5:0] cnt_set,cnt_set_n;
reg valid_n;
reg busy_n;
integer i; 
assign a[0] = -157;
assign a[1] = 380;
assign a[2] = -399;
assign a[3] = -838;
assign a[4] = 3466;
assign a[5] = -4548;
assign a[6] = -1987;
assign a[7] = 36857;
assign a[8] = 36857;
assign a[9] = -1987;
assign a[10] = -4548;
assign a[11] = 3466;
assign a[12] = -838;
assign a[13] = -399;
assign a[14] = 380;
assign a[15] = -157;

always@(posedge clk)
begin
  if(~rst_n)begin
    state <= IDLE;
    cnt_set <= 0;
    valid <= 0;
    busy  <= 0;
    y0    <= 1534;
    y1    <= 1534;
    for(i = 0 ; i <= 8; i = i + 1)begin
	x_tmp1[i] <= 0;
    end
    for(i = 0 ; i <= 7; i = i + 1)begin
    	x_tmp0[i] <= 0;
    end	
  end
  else begin
    state <= state_n;
    cnt_set <= cnt_set_n;
    busy  <= busy_n;
    y0    <= y_n0;
    y1	  <= y_n1; 
    
    valid <= valid_n;
    
    for(i = 8 ; i >= 0; i = i - 1)begin
	x_tmp1[i] <= x_n1[i];
    end
    for(i = 7 ; i >= 0; i = i - 1)begin
    	x_tmp0[i] <= x_n0[i];
    end
    
  end
end

always@*
begin
  case(state)
    IDLE : begin
      if (enable) begin
        state_n = EVA;
      end
      else state_n = IDLE;
    end
    EVA  : begin
      if (~enable) begin
        state_n = IDLE;
      end
      else if (enable&&(cnt_set != 7)) begin
        state_n = EVA;
      end
      else if (enable&&(cnt_set == 7)) begin
        state_n = CAL;
      end
      else begin
        state_n = EVA;
      end
    end 
    CAL : begin
      if (~enable) begin
        state_n = IDLE;
      end
      else state_n = CAL; 
    end
      
    default : state_n = IDLE;
  endcase
end

always@*
begin
  if (state == CAL) begin
    y_n1 = ((a[0]*x_tmp0[0]) + (a[2]*x_tmp0[1]) + (a[4]*x_tmp0[2]) + (a[6]*x_tmp0[3]) + (a[8]*x_tmp0[4]) + (a[10]*x_tmp0[5]) + (a[12]*x_tmp0[6]) + (a[14]*x_tmp0[7]) + (a[1]*x_tmp1[1]) + (a[3]*x_tmp1[2]) + (a[5]*x_tmp1[3]) + (a[7]*x_tmp1[4]) + (a[9]*x_tmp1[5]) + (a[11]*x_tmp1[6]) + (a[13]*x_tmp1[7]) + (a[15]*x_tmp1[8]))>>16;
  end
  else y_n1 = 0;
    
end

always@*
begin
  if (state == CAL) begin
    y_n0 = ((a[0]*x_tmp1[0]) + (a[2]*x_tmp1[1]) + (a[4]*x_tmp1[2]) + (a[6]*x_tmp1[3]) + (a[8]*x_tmp1[4]) + (a[10]*x_tmp1[5]) + (a[12]*x_tmp1[6]) + (a[14]*x_tmp1[7]) + (a[1]*x_tmp0[0]) + (a[3]*x_tmp0[1]) + (a[5]*x_tmp0[2]) + (a[7]*x_tmp0[3]) + (a[9]*x_tmp0[4]) + (a[11]*x_tmp0[5]) + (a[13]*x_tmp0[6]) + (a[15]*x_tmp0[7]))>>16;
  end
  else y_n0 = 0;
    
end

always@*
begin
    if(state == CAL && busy) begin
      for (i = 0;i <= 8 ;i = i + 1 ) begin
	x_n1[i] = x_tmp1[i];
      end
      for (i = 0;i <= 7 ;i = i + 1 ) begin
        x_n0[i] = x_tmp0[i];
      end
    end 
    else begin
      for (i = 1;i <= 8 ;i = i + 1 ) begin
	x_n1[i] = x_tmp1[i - 1];
      end
      for (i = 1;i <= 7 ;i = i + 1 ) begin
        x_n0[i] = x_tmp0[i - 1];
      end
	x_n0[0] = x0;
	x_n1[0] = x1;
    end
end


always@*
begin
  if(state == EVA)
    if(cnt_set == 8)
      cnt_set_n = cnt_set;
    else
      cnt_set_n = cnt_set + 1;
  else
    cnt_set_n = 0;
end

always@*
begin
  if((state == CAL))begin
    if(cnt_set == 8)
    	valid_n = 1;
    else
    	valid_n = valid;
  end
  else
    valid_n = 0;
end

always@*
begin
  if(state == EVA)
    busy_n = 0;
  else
    busy_n = 0;
end

endmodule

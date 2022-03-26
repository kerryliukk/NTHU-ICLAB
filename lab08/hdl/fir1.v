module fir1
#(parameter N=32)
(
input      clk,
input      rst_n,
input      enable,
input      [N-1:0]x,
output reg busy,
output reg valid,
output reg [N-1:0]y
);
localparam IDLE = 6'b00,
           EVA  = 6'b01,
           BUSY = 6'b10;

reg [N-1:0] y_n;

// coeff.
wire signed [N-1:0] a[15:0]; 

reg signed [N-1:0] x_n[15:0];
reg signed [N-1:0] x_n_n[15:0];



reg [5:0] state, state_n;
reg [5:0] cnt, cnt_n;
reg [5:0] cnt_s, cnt_s_n;

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
    cnt   <= 0;
    cnt_s   <= 0;
    valid <= 0;
    busy  <= 0;
    y     <= 1534;

    for (i = 0; i < 16; i = i + 1) begin
      x_n_n[i] <= 0;
    end
    
  end
  else begin
    state <= state_n;
    cnt   <= cnt_n;
    cnt_s   <= cnt_s_n;
    valid <= valid_n;
    busy  <= busy_n;
    y     <= y_n;
    
    for (i = 0; i < 16; i = i + 1) begin
      x_n_n[i] <= x_n[i];
    end
  
  end
end

always@*
begin
  case(state)
    IDLE : state_n = enable ? EVA : IDLE;
    EVA  : begin
      if (enable && cnt_s != 15)
        state_n = EVA;
      else if (enable && cnt_s == 15)
        state_n = BUSY;
      else 
        state_n = EVA;
    end
    BUSY:
        state_n = BUSY;
    default : state_n = IDLE;
  endcase
end

always @(*) begin
  if (state == BUSY) begin
    if (cnt == 15) begin
      // shift 16 bit for output
      y_n = (y + x_n_n[cnt] * a[cnt]) >> 16;
    end
    else if (cnt == 0)
      y_n = x_n_n[cnt] * a[cnt];
    else if (cnt == 16)
      y_n = y;
    else
      y_n = y + x_n_n[cnt] * a[cnt];
  end
  else 
    y_n = 0;
    
end

always @(*) begin
  if (state == BUSY && busy) begin
    for (i = 0; i < 16; i = i + 1) begin
      x_n[i] = x_n_n[i];
    end
  end
  else begin
      x_n[15] = x_n_n[14];
      x_n[14] = x_n_n[13];
      x_n[13] = x_n_n[12];	
      x_n[12] = x_n_n[11];
      x_n[11] = x_n_n[10];
      x_n[10] = x_n_n[9];
      x_n[9] = x_n_n[8];
      x_n[8] = x_n_n[7];
      x_n[7] = x_n_n[6];
      x_n[6] = x_n_n[5];
      x_n[5] = x_n_n[4];  
      x_n[4] = x_n_n[3];
      x_n[3] = x_n_n[2];
      x_n[2] = x_n_n[1];
      x_n[1] = x_n_n[0];
      x_n[0] = x;
  end
end

// always @(*) begin
//   if (state == EVA && busy) begin
//     curr_sum = a[idx] * x_n[idx] + prev_sum;
//   end
//   else begin
//     curr_sum = 0;
//   end
// end

// always @(*) begin
//   if(state == EVA)
//     if(idx2 == 16)
//       idx2_n = 0;
//     else
//       idx2_n = idx2 + 1;
//   else
//     idx2_n = 0;
// end

// always @(*) begin
//     // if ()
//     // else
//     // y_n = a[0]*x_n[0] + a[1]*x_n[1] + a[2]*x_n[2] + a[3]*x_n[3] + a[4]*x_n[4] +
//     //         a[5]*x_n[5] + a[6]*x_n[6] + a[7]*x_n[7] + a[8]*x_n[8] + a[9]*x_n[9] +
//     //         a[10]*x_n[10] + a[11]*x_n[11] + a[12]*x_n[12] + a[13]*x_n[13] + a[14]*x_n[14] + a[15]*x_n[15];
// end

always@*
begin
  if(state == EVA)
    if(cnt == 15)
      cnt_s_n = cnt_s;
    else
      cnt_s_n = cnt_s + 1;
  else
    cnt_s_n = 0;
end

always@*
begin
  if(state == BUSY)
    if(cnt == 16)
      cnt_n = 0;
    else
      cnt_n = cnt + 1;
  else
    cnt_n = 0;
end

always@*
begin
  if((state == BUSY) && (cnt == 15))
    valid_n = 1;
  else
    valid_n = 0;
end

always@*
begin
  if(state == EVA && cnt_s == 15 || state == BUSY && cnt != 15)
    busy_n = 1;
  else
    busy_n = 0;
end

endmodule

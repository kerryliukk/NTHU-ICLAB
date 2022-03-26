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
localparam IDLE = 0,
           EVA  = 1;

reg [N-1:0] y_n;

reg [5:0] state, state_n;
reg [5:0] cnt, cnt_n;
reg valid_n;
reg busy_n;

integer i, j;


always@*
begin
  case(state)
    IDLE : state_n = enable ? EVA : IDLE;
    EVA  : state_n = enable ? EVA : IDLE;
    default : state_n = IDLE;
  endcase
end

always@*
begin
  if(state == EVA)
    if(cnt == 16)
      cnt_n = cnt;
    else
      cnt_n = cnt + 1;
  else
    cnt_n = 0;
end

always@*
begin
  if((state == EVA) & (cnt == 16))
    valid_n = 1;
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

wire [32-1:0] num [0:15];
reg [N-1:0] x_val [0:15];

assign num[0] = -32'd157;
assign num[1] = 32'd380;
assign num[2] = -32'd399;
assign num[3] = -32'd838;
assign num[4] = 32'd3466;
assign num[5] = -32'd4548;
assign num[6] = -32'd1987;
assign num[7] = 32'd36857;
assign num[8] = 32'd36857;
assign num[9] = -32'd1987;
assign num[10] = -32'd4548;
assign num[11] = 32'd3466;
assign num[12] = -32'd838;
assign num[13] = -32'd399;
assign num[14] = 32'd380;
assign num[15] = -32'd157;


always @* begin
  y_n = 0;
  for (j = 0; j <= 15; j = j + 1) begin
    y_n = y_n + (x_val[j] * num[j]);
  end
end

always@(posedge clk)
begin
  if(~rst_n)begin
    state <= IDLE;
    cnt   <= 0;
    valid <= 0;
    busy  <= 0;
    y     <= 1534;
    for (i = 0; i < 16; i = i + 1) 
      x_val[i] <= 0;
  end
  else begin
    state <= state_n;
    cnt   <= cnt_n;
    valid <= valid_n;
    busy  <= busy_n;
    y     <= (y_n >> 16);

    x_val[15] <= x_val[14];
    x_val[14] <= x_val[13];
    x_val[13] <= x_val[12];
    x_val[12] <= x_val[11];
    x_val[11] <= x_val[10];
    x_val[10] <= x_val[9];
    x_val[9] <= x_val[8];
    x_val[8] <= x_val[7];
    x_val[7] <= x_val[6];
    x_val[6] <= x_val[5];
    x_val[5] <= x_val[4];
    x_val[4] <= x_val[3];
    x_val[3] <= x_val[2];
    x_val[2] <= x_val[1];
    x_val[1] <= x_val[0];
    x_val[0] <= x;

  end
end

endmodule

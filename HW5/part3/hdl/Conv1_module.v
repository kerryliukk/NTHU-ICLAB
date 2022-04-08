module Conv1_module #(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12,
parameter WEIGHT_PER_ADDR = 9, 
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8
)
(
input clk, rst_n, 
input [4-1:0] state, 
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_weight,  // 9 * 8
input [BIAS_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_bias,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0_in,  // (4 * 4) * 12
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1_in,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2_in,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3_in,
output reg [5:0] sram_raddr_a0, 
output reg [5:0] sram_raddr_a1, 
output reg [5:0] sram_raddr_a2, 
output reg [5:0] sram_raddr_a3, 

output reg [9:0] sram_raddr_weight,       
output reg [5:0] sram_raddr_bias,

output reg sram_wen_b0,
output reg sram_wen_b1,
output reg sram_wen_b2,
output reg sram_wen_b3,

output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b,
output reg [5:0] sram_waddr_b,
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b,  // 4 * 4 * 12

output reg valid
);

integer i;
// global state parameter
parameter IDLE = 4'd0, UNSHUFFLE = 4'd1, CONV1 = 4'd2, CONV2 = 4'd3, CONV3 = 4'd4, FINISH = 4'd5;

// local state parameter
reg [3-1:0] local_state, local_state_next;
localparam WAIT = 3'd0, READ_WEIGHT = 3'd1, READ_BIAS = 3'd2, CAL = 3'd3;
reg valid_next;


reg sram_wen_b0_next;
reg sram_wen_b1_next;
reg sram_wen_b2_next;
reg sram_wen_b3_next;
reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b_next;
reg [5:0] sram_waddr_b_next;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b_next;


reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3;


reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight0_ch0, weight0_ch1, weight0_ch2, weight0_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight1_ch0, weight1_ch1, weight1_ch2, weight1_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight2_ch0, weight2_ch1, weight2_ch2, weight2_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight3_ch0, weight3_ch1, weight3_ch2, weight3_ch3;

reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight0_ch0_next, weight0_ch1_next, weight0_ch2_next, weight0_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight1_ch0_next, weight1_ch1_next, weight1_ch2_next, weight1_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight2_ch0_next, weight2_ch1_next, weight2_ch2_next, weight2_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight3_ch0_next, weight3_ch1_next, weight3_ch2_next, weight3_ch3_next;

reg signed [BW_PER_PARAM-1:0] weight0_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight0_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight0_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight0_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight1_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight1_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight1_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight1_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight2_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight2_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight2_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight2_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight3_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight3_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight3_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight3_ch3_2D [0:WEIGHT_PER_ADDR-1];


reg [5-1:0] read_weight_cnt, read_weight_cnt_next;
reg [3-1:0] read_bias_cnt, read_bias_cnt_next;
reg signed [BIAS_PER_ADDR*BW_PER_PARAM-1:0] bias0, bias1, bias2, bias3;
reg signed [BIAS_PER_ADDR*BW_PER_PARAM-1:0] bias0_next, bias1_next, bias2_next, bias3_next;

reg [5:0] sram_raddr_a0_next, sram_raddr_a1_next, sram_raddr_a2_next, sram_raddr_a3_next;
reg [8-1:0] conv_cnt, conv_cnt_next;

// 3左上角 2右上角 1左下角 0右下角
reg signed [21-1:0] origin_sum3_ch0, origin_sum2_ch0, origin_sum1_ch0, origin_sum0_ch0;
reg signed [21-1:0] origin_sum3_ch1, origin_sum2_ch1, origin_sum1_ch1, origin_sum0_ch1;
reg signed [21-1:0] origin_sum3_ch2, origin_sum2_ch2, origin_sum1_ch2, origin_sum0_ch2;
reg signed [21-1:0] origin_sum3_ch3, origin_sum2_ch3, origin_sum1_ch3, origin_sum0_ch3;

reg signed [21-1:0] sum3_ch0_acc, sum2_ch0_acc, sum1_ch0_acc, sum0_ch0_acc;
reg signed [21-1:0] sum3_ch1_acc, sum2_ch1_acc, sum1_ch1_acc, sum0_ch1_acc;
reg signed [21-1:0] sum3_ch2_acc, sum2_ch2_acc, sum1_ch2_acc, sum0_ch2_acc;
reg signed [21-1:0] sum3_ch3_acc, sum2_ch3_acc, sum1_ch3_acc, sum0_ch3_acc;

reg signed [21-1:0] sum3_ch0_quan_temp, sum2_ch0_quan_temp, sum1_ch0_quan_temp, sum0_ch0_quan_temp;
reg signed [21-1:0] sum3_ch1_quan_temp, sum2_ch1_quan_temp, sum1_ch1_quan_temp, sum0_ch1_quan_temp;
reg signed [21-1:0] sum3_ch2_quan_temp, sum2_ch2_quan_temp, sum1_ch2_quan_temp, sum0_ch2_quan_temp;
reg signed [21-1:0] sum3_ch3_quan_temp, sum2_ch3_quan_temp, sum1_ch3_quan_temp, sum0_ch3_quan_temp;

reg signed [21-1:0] sum3_ch0_quan, sum2_ch0_quan, sum1_ch0_quan, sum0_ch0_quan;
reg signed [21-1:0] sum3_ch1_quan, sum2_ch1_quan, sum1_ch1_quan, sum0_ch1_quan;
reg signed [21-1:0] sum3_ch2_quan, sum2_ch2_quan, sum1_ch2_quan, sum0_ch2_quan;
reg signed [21-1:0] sum3_ch3_quan, sum2_ch3_quan, sum1_ch3_quan, sum0_ch3_quan;

reg signed [BW_PER_ACT-1:0] sum3_ch0_final, sum2_ch0_final, sum1_ch0_final, sum0_ch0_final;
reg signed [BW_PER_ACT-1:0] sum3_ch1_final, sum2_ch1_final, sum1_ch1_final, sum0_ch1_final;
reg signed [BW_PER_ACT-1:0] sum3_ch2_final, sum2_ch2_final, sum1_ch2_final, sum0_ch2_final;
reg signed [BW_PER_ACT-1:0] sum3_ch3_final, sum2_ch3_final, sum1_ch3_final, sum0_ch3_final;

reg signed [12-1:0] ch0_15, ch0_14, ch0_13, ch0_12, ch0_11, ch0_10, ch0_9, ch0_8, ch0_7, ch0_6, ch0_5, ch0_4, ch0_3, ch0_2, ch0_1, ch0_0;
reg signed [12-1:0] ch1_15, ch1_14, ch1_13, ch1_12, ch1_11, ch1_10, ch1_9, ch1_8, ch1_7, ch1_6, ch1_5, ch1_4, ch1_3, ch1_2, ch1_1, ch1_0;
reg signed [12-1:0] ch2_15, ch2_14, ch2_13, ch2_12, ch2_11, ch2_10, ch2_9, ch2_8, ch2_7, ch2_6, ch2_5, ch2_4, ch2_3, ch2_2, ch2_1, ch2_0;
reg signed [12-1:0] ch3_15, ch3_14, ch3_13, ch3_12, ch3_11, ch3_10, ch3_9, ch3_8, ch3_7, ch3_6, ch3_5, ch3_4, ch3_3, ch3_2, ch3_1, ch3_0;

wire [8-1:0] conv_cnt_delay;
assign conv_cnt_delay = conv_cnt - 3;

// set weight value
always @* begin
    weight0_ch0_next = weight0_ch0;
    weight0_ch1_next = weight0_ch1;
    weight0_ch2_next = weight0_ch2;
    weight0_ch3_next = weight0_ch3;
    weight1_ch0_next = weight1_ch0;
    weight1_ch1_next = weight1_ch1;
    weight1_ch2_next = weight1_ch2;
    weight1_ch3_next = weight1_ch3;
    weight2_ch0_next = weight2_ch0;
    weight2_ch1_next = weight2_ch1;
    weight2_ch2_next = weight2_ch2;
    weight2_ch3_next = weight2_ch3;
    weight3_ch0_next = weight3_ch0;
    weight3_ch1_next = weight3_ch1;
    weight3_ch2_next = weight3_ch2;
    weight3_ch3_next = weight3_ch3;
    if (local_state == READ_WEIGHT) begin
        if (read_weight_cnt == 5'd1)
            weight0_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd2)
            weight0_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd3)
            weight0_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd4)
            weight0_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd5)
            weight1_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd6)
            weight1_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd7)
            weight1_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd8)
            weight1_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd9)
            weight2_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd10)
            weight2_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd11)
            weight2_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd12)
            weight2_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd13)
            weight3_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd14)
            weight3_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd15)
            weight3_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 5'd16)
            weight3_ch3_next = sram_rdata_weight;
    end
end

// weight splitter
always @* begin
    for (i = 0; i < 9; i = i + 1) begin
        weight0_ch0_2D[i] = weight0_ch0[8*i+:8];
        weight0_ch1_2D[i] = weight0_ch1[8*i+:8];
        weight0_ch2_2D[i] = weight0_ch2[8*i+:8];
        weight0_ch3_2D[i] = weight0_ch3[8*i+:8];
        weight1_ch0_2D[i] = weight1_ch0[8*i+:8];
        weight1_ch1_2D[i] = weight1_ch1[8*i+:8];
        weight1_ch2_2D[i] = weight1_ch2[8*i+:8];
        weight1_ch3_2D[i] = weight1_ch3[8*i+:8];
        weight2_ch0_2D[i] = weight2_ch0[8*i+:8];
        weight2_ch1_2D[i] = weight2_ch1[8*i+:8];
        weight2_ch2_2D[i] = weight2_ch2[8*i+:8];
        weight2_ch3_2D[i] = weight2_ch3[8*i+:8];
        weight3_ch0_2D[i] = weight3_ch0[8*i+:8];
        weight3_ch1_2D[i] = weight3_ch1[8*i+:8];
        weight3_ch2_2D[i] = weight3_ch2[8*i+:8];
        weight3_ch3_2D[i] = weight3_ch3[8*i+:8];
    end
end

// read weight counter
always @* begin
    if (local_state == READ_WEIGHT) begin
        read_weight_cnt_next = read_weight_cnt + 1;
    end
    else begin
        read_weight_cnt_next = read_weight_cnt;
    end
end

// read weight address
always @* begin
    sram_raddr_weight = read_weight_cnt;
end

// read bias counter
always @* begin
    if (local_state == READ_BIAS) begin
        read_bias_cnt_next = read_bias_cnt + 1;
    end
    else begin
        read_bias_cnt_next = read_bias_cnt;
    end
end

// set bias value
always @* begin
    bias0_next = bias0;
    bias1_next = bias1;
    bias2_next = bias2;
    bias3_next = bias3;
    if (local_state == READ_BIAS) begin
        case (read_bias_cnt)
            3'd1: bias0_next = sram_rdata_bias;
            3'd2: bias1_next = sram_rdata_bias;
            3'd3: bias2_next = sram_rdata_bias;
            3'd4: bias3_next = sram_rdata_bias;
        endcase
    end
end

// read bias address
always @* begin
    sram_raddr_bias = read_bias_cnt;
end

// conv counter
always @* begin
    if (local_state == CAL) begin
        if (conv_cnt != 39) begin
            conv_cnt_next = conv_cnt + 1;
        end
        else begin
            conv_cnt_next = 0;
        end
    end
    else begin
        conv_cnt_next = conv_cnt;
    end
end

// set sram_raddr_a0_next ~ sram_raddr_a3_next
always @* begin
    case (conv_cnt)
        8'd0: begin
            sram_raddr_a0_next = 0;
            sram_raddr_a1_next = 0;
            sram_raddr_a2_next = 0;
            sram_raddr_a3_next = 0;
        end
        8'd1: begin
            sram_raddr_a0_next = 1;
            sram_raddr_a1_next = 0;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 0;
        end
        8'd2: begin
            sram_raddr_a0_next = 1;
            sram_raddr_a1_next = 1;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 1;
        end
        8'd3: begin
            sram_raddr_a0_next = 2;
            sram_raddr_a1_next = 1;
            sram_raddr_a2_next = 2;
            sram_raddr_a3_next = 1;
        end
        8'd4: begin
            sram_raddr_a0_next = 2;
            sram_raddr_a1_next = 2;
            sram_raddr_a2_next = 2;
            sram_raddr_a3_next = 2;
        end
        8'd5: begin
            sram_raddr_a0_next = 3;
            sram_raddr_a1_next = 2;
            sram_raddr_a2_next = 3;
            sram_raddr_a3_next = 2;
        end
        8'd6: begin
            sram_raddr_a0_next = 6;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 0;
            sram_raddr_a3_next = 0;
        end
        8'd7: begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 0;
        end
        8'd8: begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 1;
        end
        8'd9: begin
            sram_raddr_a0_next = 8;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 2;
            sram_raddr_a3_next = 1;
        end
        8'd10: begin
            sram_raddr_a0_next = 8;
            sram_raddr_a1_next = 8;
            sram_raddr_a2_next = 2;
            sram_raddr_a3_next = 2;
        end
        8'd11: begin
            sram_raddr_a0_next = 9;
            sram_raddr_a1_next = 8;
            sram_raddr_a2_next = 3;
            sram_raddr_a3_next = 2;
        end
        8'd12: begin
            sram_raddr_a0_next = 6;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 6;
            sram_raddr_a3_next = 6;
        end
        8'd13: begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 6;
        end
        8'd14: begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 7;
        end
        8'd15: begin
            sram_raddr_a0_next = 8;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 8;
            sram_raddr_a3_next = 7;
        end
        8'd16: begin
            sram_raddr_a0_next = 8;
            sram_raddr_a1_next = 8;
            sram_raddr_a2_next = 8;
            sram_raddr_a3_next = 8;
        end
        8'd17: begin
            sram_raddr_a0_next = 9;
            sram_raddr_a1_next = 8;
            sram_raddr_a2_next = 9;
            sram_raddr_a3_next = 8;
        end
        8'd18: begin
            sram_raddr_a0_next = 12;
            sram_raddr_a1_next = 12;
            sram_raddr_a2_next = 6;
            sram_raddr_a3_next = 6;
        end
        8'd19: begin
            sram_raddr_a0_next = 13;
            sram_raddr_a1_next = 12;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 6;
        end
        8'd20: begin
            sram_raddr_a0_next = 13;
            sram_raddr_a1_next = 13;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 7;
        end
        8'd21: begin
            sram_raddr_a0_next = 14;
            sram_raddr_a1_next = 13;
            sram_raddr_a2_next = 8;
            sram_raddr_a3_next = 7;
        end
        8'd22: begin
            sram_raddr_a0_next = 14;
            sram_raddr_a1_next = 14;
            sram_raddr_a2_next = 8;
            sram_raddr_a3_next = 8;
        end
        8'd23: begin
            sram_raddr_a0_next = 15;
            sram_raddr_a1_next = 14;
            sram_raddr_a2_next = 9;
            sram_raddr_a3_next = 8;
        end
        8'd24: begin
            sram_raddr_a0_next = 12;
            sram_raddr_a1_next = 12;
            sram_raddr_a2_next = 12;
            sram_raddr_a3_next = 12;
        end
        8'd25: begin
            sram_raddr_a0_next = 13;
            sram_raddr_a1_next = 12;
            sram_raddr_a2_next = 13;
            sram_raddr_a3_next = 12;
        end
        8'd26: begin
            sram_raddr_a0_next = 13;
            sram_raddr_a1_next = 13;
            sram_raddr_a2_next = 13;
            sram_raddr_a3_next = 13;
        end
        8'd27: begin
            sram_raddr_a0_next = 14;
            sram_raddr_a1_next = 13;
            sram_raddr_a2_next = 14;
            sram_raddr_a3_next = 13;
        end
        8'd28: begin
            sram_raddr_a0_next = 14;
            sram_raddr_a1_next = 14;
            sram_raddr_a2_next = 14;
            sram_raddr_a3_next = 14;
        end
        8'd29: begin
            sram_raddr_a0_next = 15;
            sram_raddr_a1_next = 14;
            sram_raddr_a2_next = 15;
            sram_raddr_a3_next = 14;
        end
        8'd30: begin
            sram_raddr_a0_next = 18;
            sram_raddr_a1_next = 18;
            sram_raddr_a2_next = 12;
            sram_raddr_a3_next = 12;
        end
        8'd31: begin
            sram_raddr_a0_next = 19;
            sram_raddr_a1_next = 18;
            sram_raddr_a2_next = 13;
            sram_raddr_a3_next = 12;
        end
        8'd32: begin
            sram_raddr_a0_next = 19;
            sram_raddr_a1_next = 19;
            sram_raddr_a2_next = 13;
            sram_raddr_a3_next = 13;
        end
        8'd33: begin
            sram_raddr_a0_next = 20;
            sram_raddr_a1_next = 19;
            sram_raddr_a2_next = 14;
            sram_raddr_a3_next = 13;
        end
        8'd34: begin
            sram_raddr_a0_next = 20;
            sram_raddr_a1_next = 20;
            sram_raddr_a2_next = 14;
            sram_raddr_a3_next = 14;
        end
        8'd35: begin
            sram_raddr_a0_next = 21;
            sram_raddr_a1_next = 20;
            sram_raddr_a2_next = 15;
            sram_raddr_a3_next = 14;
        end
        default: begin
            sram_raddr_a0_next = 0;
            sram_raddr_a1_next = 0;
            sram_raddr_a2_next = 0;
            sram_raddr_a3_next = 0;
        end
    endcase
end

// quan + relu
always @* begin
    sum3_ch0_acc = (origin_sum3_ch0 + (bias0 <<< 8)) > 0 ? origin_sum3_ch0 + (bias0 <<< 8) : 0;
    sum2_ch0_acc = (origin_sum2_ch0 + (bias0 <<< 8)) > 0 ? origin_sum2_ch0 + (bias0 <<< 8) : 0;
    sum1_ch0_acc = (origin_sum1_ch0 + (bias0 <<< 8)) > 0 ? origin_sum1_ch0 + (bias0 <<< 8) : 0;
    sum0_ch0_acc = (origin_sum0_ch0 + (bias0 <<< 8)) > 0 ? origin_sum0_ch0 + (bias0 <<< 8) : 0;

    sum3_ch1_acc = (origin_sum3_ch1 + (bias1 <<< 8)) > 0 ? origin_sum3_ch1 + (bias1 <<< 8) : 0;
    sum2_ch1_acc = (origin_sum2_ch1 + (bias1 <<< 8)) > 0 ? origin_sum2_ch1 + (bias1 <<< 8) : 0;
    sum1_ch1_acc = (origin_sum1_ch1 + (bias1 <<< 8)) > 0 ? origin_sum1_ch1 + (bias1 <<< 8) : 0;
    sum0_ch1_acc = (origin_sum0_ch1 + (bias1 <<< 8)) > 0 ? origin_sum0_ch1 + (bias1 <<< 8) : 0;

    sum3_ch2_acc = (origin_sum3_ch2 + (bias2 <<< 8)) > 0 ? origin_sum3_ch2 + (bias2 <<< 8) : 0;
    sum2_ch2_acc = (origin_sum2_ch2 + (bias2 <<< 8)) > 0 ? origin_sum2_ch2 + (bias2 <<< 8) : 0;
    sum1_ch2_acc = (origin_sum1_ch2 + (bias2 <<< 8)) > 0 ? origin_sum1_ch2 + (bias2 <<< 8) : 0;
    sum0_ch2_acc = (origin_sum0_ch2 + (bias2 <<< 8)) > 0 ? origin_sum0_ch2 + (bias2 <<< 8) : 0;

    sum3_ch3_acc = (origin_sum3_ch3 + (bias3 <<< 8)) > 0 ? origin_sum3_ch3 + (bias3 <<< 8) : 0;
    sum2_ch3_acc = (origin_sum2_ch3 + (bias3 <<< 8)) > 0 ? origin_sum2_ch3 + (bias3 <<< 8) : 0;
    sum1_ch3_acc = (origin_sum1_ch3 + (bias3 <<< 8)) > 0 ? origin_sum1_ch3 + (bias3 <<< 8) : 0;
    sum0_ch3_acc = (origin_sum0_ch3 + (bias3 <<< 8)) > 0 ? origin_sum0_ch3 + (bias3 <<< 8) : 0;

    sum3_ch0_quan_temp = (sum3_ch0_acc + {14'd0, 1'd1, 6'd0});
    sum2_ch0_quan_temp = (sum2_ch0_acc + {14'd0, 1'd1, 6'd0});
    sum1_ch0_quan_temp = (sum1_ch0_acc + {14'd0, 1'd1, 6'd0});
    sum0_ch0_quan_temp = (sum0_ch0_acc + {14'd0, 1'd1, 6'd0});

    sum3_ch1_quan_temp = (sum3_ch1_acc + {14'd0, 1'd1, 6'd0});
    sum2_ch1_quan_temp = (sum2_ch1_acc + {14'd0, 1'd1, 6'd0});
    sum1_ch1_quan_temp = (sum1_ch1_acc + {14'd0, 1'd1, 6'd0});
    sum0_ch1_quan_temp = (sum0_ch1_acc + {14'd0, 1'd1, 6'd0});

    sum3_ch2_quan_temp = (sum3_ch2_acc + {14'd0, 1'd1, 6'd0});
    sum2_ch2_quan_temp = (sum2_ch2_acc + {14'd0, 1'd1, 6'd0});
    sum1_ch2_quan_temp = (sum1_ch2_acc + {14'd0, 1'd1, 6'd0});
    sum0_ch2_quan_temp = (sum0_ch2_acc + {14'd0, 1'd1, 6'd0});

    sum3_ch3_quan_temp = (sum3_ch3_acc + {14'd0, 1'd1, 6'd0});
    sum2_ch3_quan_temp = (sum2_ch3_acc + {14'd0, 1'd1, 6'd0});
    sum1_ch3_quan_temp = (sum1_ch3_acc + {14'd0, 1'd1, 6'd0});
    sum0_ch3_quan_temp = (sum0_ch3_acc + {14'd0, 1'd1, 6'd0});

    sum3_ch0_quan = sum3_ch0_quan_temp >>> 7;
    sum2_ch0_quan = sum2_ch0_quan_temp >>> 7;
    sum1_ch0_quan = sum1_ch0_quan_temp >>> 7;
    sum0_ch0_quan = sum0_ch0_quan_temp >>> 7;

    sum3_ch1_quan = sum3_ch1_quan_temp >>> 7;
    sum2_ch1_quan = sum2_ch1_quan_temp >>> 7;
    sum1_ch1_quan = sum1_ch1_quan_temp >>> 7;
    sum0_ch1_quan = sum0_ch1_quan_temp >>> 7;

    sum3_ch2_quan = sum3_ch2_quan_temp >>> 7;
    sum2_ch2_quan = sum2_ch2_quan_temp >>> 7;
    sum1_ch2_quan = sum1_ch2_quan_temp >>> 7;
    sum0_ch2_quan = sum0_ch2_quan_temp >>> 7;

    sum3_ch3_quan = sum3_ch3_quan_temp >>> 7;
    sum2_ch3_quan = sum2_ch3_quan_temp >>> 7;
    sum1_ch3_quan = sum1_ch3_quan_temp >>> 7;
    sum0_ch3_quan = sum0_ch3_quan_temp >>> 7;

    if (sum3_ch0_quan > 2047) begin
        sum3_ch0_final = 2047;
    end
    else if (sum3_ch0_quan < -2048) begin
        sum3_ch0_final = -2048;
    end
    else begin
        sum3_ch0_final = sum3_ch0_quan[11:0];
    end
    if (sum2_ch0_quan > 2047) begin
        sum2_ch0_final = 2047;
    end
    else if (sum2_ch0_quan < -2048) begin
        sum2_ch0_final = -2048;
    end
    else begin
        sum2_ch0_final = sum2_ch0_quan[11:0];
    end
    if (sum1_ch0_quan > 2047) begin
        sum1_ch0_final = 2047;
    end
    else if (sum1_ch0_quan < -2048) begin
        sum1_ch0_final = -2048;
    end
    else begin
        sum1_ch0_final = sum1_ch0_quan[11:0];
    end
    if (sum0_ch0_quan > 2047) begin
        sum0_ch0_final = 2047;
    end
    else if (sum0_ch0_quan < -2048) begin
        sum0_ch0_final = -2048;
    end
    else begin
        sum0_ch0_final = sum0_ch0_quan[11:0];
    end



    if (sum3_ch1_quan > 2047) begin
        sum3_ch1_final = 2047;
    end
    else if (sum3_ch1_quan < -2048) begin
        sum3_ch1_final = -2048;
    end
    else begin
        sum3_ch1_final = sum3_ch1_quan[11:0];
    end
    if (sum2_ch1_quan > 2047) begin
        sum2_ch1_final = 2047;
    end
    else if (sum2_ch1_quan < -2048) begin
        sum2_ch1_final = -2048;
    end
    else begin
        sum2_ch1_final = sum2_ch1_quan[11:0];
    end
    if (sum1_ch1_quan > 2047) begin
        sum1_ch1_final = 2047;
    end
    else if (sum1_ch1_quan < -2048) begin
        sum1_ch1_final = -2048;
    end
    else begin
        sum1_ch1_final = sum1_ch1_quan[11:0];
    end
    if (sum0_ch1_quan > 2047) begin
        sum0_ch1_final = 2047;
    end
    else if (sum0_ch1_quan < -2048) begin
        sum0_ch1_final = -2048;
    end
    else begin
        sum0_ch1_final = sum0_ch1_quan[11:0];
    end




    if (sum3_ch2_quan > 2047) begin
        sum3_ch2_final = 2047;
    end
    else if (sum3_ch2_quan < -2048) begin
        sum3_ch2_final = -2048;
    end
    else begin
        sum3_ch2_final = sum3_ch2_quan[11:0];
    end
    if (sum2_ch2_quan > 2047) begin
        sum2_ch2_final = 2047;
    end
    else if (sum2_ch2_quan < -2048) begin
        sum2_ch2_final = -2048;
    end
    else begin
        sum2_ch2_final = sum2_ch2_quan[11:0];
    end
    if (sum1_ch2_quan > 2047) begin
        sum1_ch2_final = 2047;
    end
    else if (sum1_ch2_quan < -2048) begin
        sum1_ch2_final = -2048;
    end
    else begin
        sum1_ch2_final = sum1_ch2_quan[11:0];
    end
    if (sum0_ch2_quan > 2047) begin
        sum0_ch2_final = 2047;
    end
    else if (sum0_ch2_quan < -2048) begin
        sum0_ch2_final = -2048;
    end
    else begin
        sum0_ch2_final = sum0_ch2_quan[11:0];
    end


    if (sum3_ch3_quan > 2047) begin
        sum3_ch3_final = 2047;
    end
    else if (sum3_ch3_quan < -2048) begin
        sum3_ch3_final = -2048;
    end
    else begin
        sum3_ch3_final = sum3_ch3_quan[11:0];
    end
    if (sum2_ch3_quan > 2047) begin
        sum2_ch3_final = 2047;
    end
    else if (sum2_ch3_quan < -2048) begin
        sum2_ch3_final = -2048;
    end
    else begin
        sum2_ch3_final = sum2_ch3_quan[11:0];
    end
    if (sum1_ch3_quan > 2047) begin
        sum1_ch3_final = 2047;
    end
    else if (sum1_ch3_quan < -2048) begin
        sum1_ch3_final = -2048;
    end
    else begin
        sum1_ch3_final = sum1_ch3_quan[11:0];
    end
    if (sum0_ch3_quan > 2047) begin
        sum0_ch3_final = 2047;
    end
    else if (sum0_ch3_quan < -2048) begin
        sum0_ch3_final = -2048;
    end
    else begin
        sum0_ch3_final = sum0_ch3_quan[11:0];
    end
end

// sram data splitter and write enable next
always @* begin
    sram_wen_b0_next = sram_wen_b0;
    sram_wen_b1_next = sram_wen_b1;
    sram_wen_b2_next = sram_wen_b2;
    sram_wen_b3_next = sram_wen_b3;
    if (conv_cnt_delay == 0 || conv_cnt_delay == 2 || conv_cnt_delay == 4 || conv_cnt_delay == 12 || conv_cnt_delay == 14 || conv_cnt_delay == 16 || conv_cnt_delay == 24 || conv_cnt_delay == 26 || conv_cnt_delay == 28) begin
        sram_wen_b0_next = 0;
        sram_wen_b1_next = 1;
        sram_wen_b2_next = 1;
        sram_wen_b3_next = 1;

        ch0_15 = sram_rdata_a0[191:180];
        ch0_14 = sram_rdata_a0[179:168];
        ch0_13 = sram_rdata_a1[191:180];
        ch0_12 = sram_rdata_a1[179:168];
        ch0_11 = sram_rdata_a0[167:156];
        ch0_10 = sram_rdata_a0[155:144];
        ch0_9  = sram_rdata_a1[167:156];
        ch0_8  = sram_rdata_a1[155:144];
        ch0_7  = sram_rdata_a2[191:180];
        ch0_6  = sram_rdata_a2[179:168];
        ch0_5  = sram_rdata_a3[191:180];
        ch0_4  = sram_rdata_a3[179:168];
        ch0_3  = sram_rdata_a2[167:156];
        ch0_2  = sram_rdata_a2[155:144];
        ch0_1  = sram_rdata_a3[167:156];
        ch0_0  = sram_rdata_a3[155:144];

        ch1_15 = sram_rdata_a0[191-48:180-48];
        ch1_14 = sram_rdata_a0[179-48:168-48];
        ch1_13 = sram_rdata_a1[191-48:180-48];
        ch1_12 = sram_rdata_a1[179-48:168-48];
        ch1_11 = sram_rdata_a0[167-48:156-48];
        ch1_10 = sram_rdata_a0[155-48:144-48];
        ch1_9  = sram_rdata_a1[167-48:156-48];
        ch1_8  = sram_rdata_a1[155-48:144-48];
        ch1_7  = sram_rdata_a2[191-48:180-48];
        ch1_6  = sram_rdata_a2[179-48:168-48];
        ch1_5  = sram_rdata_a3[191-48:180-48];
        ch1_4  = sram_rdata_a3[179-48:168-48];
        ch1_3  = sram_rdata_a2[167-48:156-48];
        ch1_2  = sram_rdata_a2[155-48:144-48];
        ch1_1  = sram_rdata_a3[167-48:156-48];
        ch1_0  = sram_rdata_a3[155-48:144-48];

        ch2_15 = sram_rdata_a0[191-96:180-96];
        ch2_14 = sram_rdata_a0[179-96:168-96];
        ch2_13 = sram_rdata_a1[191-96:180-96];
        ch2_12 = sram_rdata_a1[179-96:168-96];
        ch2_11 = sram_rdata_a0[167-96:156-96];
        ch2_10 = sram_rdata_a0[155-96:144-96];
        ch2_9  = sram_rdata_a1[167-96:156-96];
        ch2_8  = sram_rdata_a1[155-96:144-96];
        ch2_7  = sram_rdata_a2[191-96:180-96];
        ch2_6  = sram_rdata_a2[179-96:168-96];
        ch2_5  = sram_rdata_a3[191-96:180-96];
        ch2_4  = sram_rdata_a3[179-96:168-96];
        ch2_3  = sram_rdata_a2[167-96:156-96];
        ch2_2  = sram_rdata_a2[155-96:144-96];
        ch2_1  = sram_rdata_a3[167-96:156-96];
        ch2_0  = sram_rdata_a3[155-96:144-96];

        ch3_15 = sram_rdata_a0[191-144:180-144];
        ch3_14 = sram_rdata_a0[179-144:168-144];
        ch3_13 = sram_rdata_a1[191-144:180-144];
        ch3_12 = sram_rdata_a1[179-144:168-144];
        ch3_11 = sram_rdata_a0[167-144:156-144];
        ch3_10 = sram_rdata_a0[155-144:144-144];
        ch3_9  = sram_rdata_a1[167-144:156-144];
        ch3_8  = sram_rdata_a1[155-144:144-144];
        ch3_7  = sram_rdata_a2[191-144:180-144];
        ch3_6  = sram_rdata_a2[179-144:168-144];
        ch3_5  = sram_rdata_a3[191-144:180-144];
        ch3_4  = sram_rdata_a3[179-144:168-144];
        ch3_3  = sram_rdata_a2[167-144:156-144];
        ch3_2  = sram_rdata_a2[155-144:144-144];
        ch3_1  = sram_rdata_a3[167-144:156-144];
        ch3_0  = sram_rdata_a3[155-144:144-144];
    end
    else if (conv_cnt_delay == 1 || conv_cnt_delay == 3 || conv_cnt_delay == 5 || conv_cnt_delay == 13 || conv_cnt_delay == 15 || conv_cnt_delay == 17 || conv_cnt_delay == 25 || conv_cnt_delay == 27 || conv_cnt_delay == 29) begin
        sram_wen_b0_next = 1;
        sram_wen_b1_next = 0;
        sram_wen_b2_next = 1;
        sram_wen_b3_next = 1;

        ch0_15 = sram_rdata_a1[191:180];
        ch0_14 = sram_rdata_a1[179:168];
        ch0_13 = sram_rdata_a0[191:180];
        ch0_12 = sram_rdata_a0[179:168];
        ch0_11 = sram_rdata_a1[167:156];
        ch0_10 = sram_rdata_a1[155:144];
        ch0_9  = sram_rdata_a0[167:156];
        ch0_8  = sram_rdata_a0[155:144];
        ch0_7  = sram_rdata_a3[191:180];
        ch0_6  = sram_rdata_a3[179:168];
        ch0_5  = sram_rdata_a2[191:180];
        ch0_4  = sram_rdata_a2[179:168];
        ch0_3  = sram_rdata_a3[167:156];
        ch0_2  = sram_rdata_a3[155:144];
        ch0_1  = sram_rdata_a2[167:156];
        ch0_0  = sram_rdata_a2[155:144];

        ch1_15 = sram_rdata_a1[191-48:180-48];
        ch1_14 = sram_rdata_a1[179-48:168-48];
        ch1_13 = sram_rdata_a0[191-48:180-48];
        ch1_12 = sram_rdata_a0[179-48:168-48];
        ch1_11 = sram_rdata_a1[167-48:156-48];
        ch1_10 = sram_rdata_a1[155-48:144-48];
        ch1_9  = sram_rdata_a0[167-48:156-48];
        ch1_8  = sram_rdata_a0[155-48:144-48];
        ch1_7  = sram_rdata_a3[191-48:180-48];
        ch1_6  = sram_rdata_a3[179-48:168-48];
        ch1_5  = sram_rdata_a2[191-48:180-48];
        ch1_4  = sram_rdata_a2[179-48:168-48];
        ch1_3  = sram_rdata_a3[167-48:156-48];
        ch1_2  = sram_rdata_a3[155-48:144-48];
        ch1_1  = sram_rdata_a2[167-48:156-48];
        ch1_0  = sram_rdata_a2[155-48:144-48];

        ch2_15 = sram_rdata_a1[191-96:180-96];
        ch2_14 = sram_rdata_a1[179-96:168-96];
        ch2_13 = sram_rdata_a0[191-96:180-96];
        ch2_12 = sram_rdata_a0[179-96:168-96];
        ch2_11 = sram_rdata_a1[167-96:156-96];
        ch2_10 = sram_rdata_a1[155-96:144-96];
        ch2_9  = sram_rdata_a0[167-96:156-96];
        ch2_8  = sram_rdata_a0[155-96:144-96];
        ch2_7  = sram_rdata_a3[191-96:180-96];
        ch2_6  = sram_rdata_a3[179-96:168-96];
        ch2_5  = sram_rdata_a2[191-96:180-96];
        ch2_4  = sram_rdata_a2[179-96:168-96];
        ch2_3  = sram_rdata_a3[167-96:156-96];
        ch2_2  = sram_rdata_a3[155-96:144-96];
        ch2_1  = sram_rdata_a2[167-96:156-96];
        ch2_0  = sram_rdata_a2[155-96:144-96];

        ch3_15 = sram_rdata_a1[191-144:180-144];
        ch3_14 = sram_rdata_a1[179-144:168-144];
        ch3_13 = sram_rdata_a0[191-144:180-144];
        ch3_12 = sram_rdata_a0[179-144:168-144];
        ch3_11 = sram_rdata_a1[167-144:156-144];
        ch3_10 = sram_rdata_a1[155-144:144-144];
        ch3_9  = sram_rdata_a0[167-144:156-144];
        ch3_8  = sram_rdata_a0[155-144:144-144];
        ch3_7  = sram_rdata_a3[191-144:180-144];
        ch3_6  = sram_rdata_a3[179-144:168-144];
        ch3_5  = sram_rdata_a2[191-144:180-144];
        ch3_4  = sram_rdata_a2[179-144:168-144];
        ch3_3  = sram_rdata_a3[167-144:156-144];
        ch3_2  = sram_rdata_a3[155-144:144-144];
        ch3_1  = sram_rdata_a2[167-144:156-144];
        ch3_0  = sram_rdata_a2[155-144:144-144];
    end
    else if (conv_cnt_delay == 6 || conv_cnt_delay == 8 || conv_cnt_delay == 10 || conv_cnt_delay == 18 || conv_cnt_delay == 20 || conv_cnt_delay == 22 || conv_cnt_delay == 30 || conv_cnt_delay == 32 || conv_cnt_delay == 34) begin
        sram_wen_b0_next = 1;
        sram_wen_b1_next = 1;
        sram_wen_b2_next = 0;
        sram_wen_b3_next = 1;

        ch0_15 = sram_rdata_a2[191:180];
        ch0_14 = sram_rdata_a2[179:168];
        ch0_13 = sram_rdata_a3[191:180];
        ch0_12 = sram_rdata_a3[179:168];
        ch0_11 = sram_rdata_a2[167:156];
        ch0_10 = sram_rdata_a2[155:144];
        ch0_9  = sram_rdata_a3[167:156];
        ch0_8  = sram_rdata_a3[155:144];
        ch0_7  = sram_rdata_a0[191:180];
        ch0_6  = sram_rdata_a0[179:168];
        ch0_5  = sram_rdata_a1[191:180];
        ch0_4  = sram_rdata_a1[179:168];
        ch0_3  = sram_rdata_a0[167:156];
        ch0_2  = sram_rdata_a0[155:144];
        ch0_1  = sram_rdata_a1[167:156];
        ch0_0  = sram_rdata_a1[155:144];

        ch1_15 = sram_rdata_a2[191-48:180-48];
        ch1_14 = sram_rdata_a2[179-48:168-48];
        ch1_13 = sram_rdata_a3[191-48:180-48];
        ch1_12 = sram_rdata_a3[179-48:168-48];
        ch1_11 = sram_rdata_a2[167-48:156-48];
        ch1_10 = sram_rdata_a2[155-48:144-48];
        ch1_9  = sram_rdata_a3[167-48:156-48];
        ch1_8  = sram_rdata_a3[155-48:144-48];
        ch1_7  = sram_rdata_a0[191-48:180-48];
        ch1_6  = sram_rdata_a0[179-48:168-48];
        ch1_5  = sram_rdata_a1[191-48:180-48];
        ch1_4  = sram_rdata_a1[179-48:168-48];
        ch1_3  = sram_rdata_a0[167-48:156-48];
        ch1_2  = sram_rdata_a0[155-48:144-48];
        ch1_1  = sram_rdata_a1[167-48:156-48];
        ch1_0  = sram_rdata_a1[155-48:144-48];

        ch2_15 = sram_rdata_a2[191-96:180-96];
        ch2_14 = sram_rdata_a2[179-96:168-96];
        ch2_13 = sram_rdata_a3[191-96:180-96];
        ch2_12 = sram_rdata_a3[179-96:168-96];
        ch2_11 = sram_rdata_a2[167-96:156-96];
        ch2_10 = sram_rdata_a2[155-96:144-96];
        ch2_9  = sram_rdata_a3[167-96:156-96];
        ch2_8  = sram_rdata_a3[155-96:144-96];
        ch2_7  = sram_rdata_a0[191-96:180-96];
        ch2_6  = sram_rdata_a0[179-96:168-96];
        ch2_5  = sram_rdata_a1[191-96:180-96];
        ch2_4  = sram_rdata_a1[179-96:168-96];
        ch2_3  = sram_rdata_a0[167-96:156-96];
        ch2_2  = sram_rdata_a0[155-96:144-96];
        ch2_1  = sram_rdata_a1[167-96:156-96];
        ch2_0  = sram_rdata_a1[155-96:144-96];

        ch3_15 = sram_rdata_a2[191-144:180-144];
        ch3_14 = sram_rdata_a2[179-144:168-144];
        ch3_13 = sram_rdata_a3[191-144:180-144];
        ch3_12 = sram_rdata_a3[179-144:168-144];
        ch3_11 = sram_rdata_a2[167-144:156-144];
        ch3_10 = sram_rdata_a2[155-144:144-144];
        ch3_9  = sram_rdata_a3[167-144:156-144];
        ch3_8  = sram_rdata_a3[155-144:144-144];
        ch3_7  = sram_rdata_a0[191-144:180-144];
        ch3_6  = sram_rdata_a0[179-144:168-144];
        ch3_5  = sram_rdata_a1[191-144:180-144];
        ch3_4  = sram_rdata_a1[179-144:168-144];
        ch3_3  = sram_rdata_a0[167-144:156-144];
        ch3_2  = sram_rdata_a0[155-144:144-144];
        ch3_1  = sram_rdata_a1[167-144:156-144];
        ch3_0  = sram_rdata_a1[155-144:144-144];
    end
    else if (conv_cnt_delay == 7 || conv_cnt_delay == 9 || conv_cnt_delay == 11 || conv_cnt_delay == 19 || conv_cnt_delay == 21 || conv_cnt_delay == 23 || conv_cnt_delay == 31 || conv_cnt_delay == 33 || conv_cnt_delay == 35) begin
        sram_wen_b0_next = 1;
        sram_wen_b1_next = 1;
        sram_wen_b2_next = 1;
        sram_wen_b3_next = 0;

        ch0_15 = sram_rdata_a3[191:180];
        ch0_14 = sram_rdata_a3[179:168];
        ch0_13 = sram_rdata_a2[191:180];
        ch0_12 = sram_rdata_a2[179:168];
        ch0_11 = sram_rdata_a3[167:156];
        ch0_10 = sram_rdata_a3[155:144];
        ch0_9  = sram_rdata_a2[167:156];
        ch0_8  = sram_rdata_a2[155:144];
        ch0_7  = sram_rdata_a1[191:180];
        ch0_6  = sram_rdata_a1[179:168];
        ch0_5  = sram_rdata_a0[191:180];
        ch0_4  = sram_rdata_a0[179:168];
        ch0_3  = sram_rdata_a1[167:156];
        ch0_2  = sram_rdata_a1[155:144];
        ch0_1  = sram_rdata_a0[167:156];
        ch0_0  = sram_rdata_a0[155:144];

        ch1_15 = sram_rdata_a3[191-48:180-48];
        ch1_14 = sram_rdata_a3[179-48:168-48];
        ch1_13 = sram_rdata_a2[191-48:180-48];
        ch1_12 = sram_rdata_a2[179-48:168-48];
        ch1_11 = sram_rdata_a3[167-48:156-48];
        ch1_10 = sram_rdata_a3[155-48:144-48];
        ch1_9  = sram_rdata_a2[167-48:156-48];
        ch1_8  = sram_rdata_a2[155-48:144-48];
        ch1_7  = sram_rdata_a1[191-48:180-48];
        ch1_6  = sram_rdata_a1[179-48:168-48];
        ch1_5  = sram_rdata_a0[191-48:180-48];
        ch1_4  = sram_rdata_a0[179-48:168-48];
        ch1_3  = sram_rdata_a1[167-48:156-48];
        ch1_2  = sram_rdata_a1[155-48:144-48];
        ch1_1  = sram_rdata_a0[167-48:156-48];
        ch1_0  = sram_rdata_a0[155-48:144-48];

        ch2_15 = sram_rdata_a3[191-96:180-96];
        ch2_14 = sram_rdata_a3[179-96:168-96];
        ch2_13 = sram_rdata_a2[191-96:180-96];
        ch2_12 = sram_rdata_a2[179-96:168-96];
        ch2_11 = sram_rdata_a3[167-96:156-96];
        ch2_10 = sram_rdata_a3[155-96:144-96];
        ch2_9  = sram_rdata_a2[167-96:156-96];
        ch2_8  = sram_rdata_a2[155-96:144-96];
        ch2_7  = sram_rdata_a1[191-96:180-96];
        ch2_6  = sram_rdata_a1[179-96:168-96];
        ch2_5  = sram_rdata_a0[191-96:180-96];
        ch2_4  = sram_rdata_a0[179-96:168-96];
        ch2_3  = sram_rdata_a1[167-96:156-96];
        ch2_2  = sram_rdata_a1[155-96:144-96];
        ch2_1  = sram_rdata_a0[167-96:156-96];
        ch2_0  = sram_rdata_a0[155-96:144-96];

        ch3_15 = sram_rdata_a3[191-144:180-144];
        ch3_14 = sram_rdata_a3[179-144:168-144];
        ch3_13 = sram_rdata_a2[191-144:180-144];
        ch3_12 = sram_rdata_a2[179-144:168-144];
        ch3_11 = sram_rdata_a3[167-144:156-144];
        ch3_10 = sram_rdata_a3[155-144:144-144];
        ch3_9  = sram_rdata_a2[167-144:156-144];
        ch3_8  = sram_rdata_a2[155-144:144-144];
        ch3_7  = sram_rdata_a1[191-144:180-144];
        ch3_6  = sram_rdata_a1[179-144:168-144];
        ch3_5  = sram_rdata_a0[191-144:180-144];
        ch3_4  = sram_rdata_a0[179-144:168-144];
        ch3_3  = sram_rdata_a1[167-144:156-144];
        ch3_2  = sram_rdata_a1[155-144:144-144];
        ch3_1  = sram_rdata_a0[167-144:156-144];
        ch3_0  = sram_rdata_a0[155-144:144-144];
    end
    // avoid latch
    else begin
        sram_wen_b0_next = 0;
        sram_wen_b1_next = 1;
        sram_wen_b2_next = 1;
        sram_wen_b3_next = 1;

        ch0_15 = sram_rdata_a0[191:180];
        ch0_14 = sram_rdata_a0[179:168];
        ch0_13 = sram_rdata_a1[191:180];
        ch0_12 = sram_rdata_a1[179:168];
        ch0_11 = sram_rdata_a0[167:156];
        ch0_10 = sram_rdata_a0[155:144];
        ch0_9  = sram_rdata_a1[167:156];
        ch0_8  = sram_rdata_a1[155:144];
        ch0_7  = sram_rdata_a2[191:180];
        ch0_6  = sram_rdata_a2[179:168];
        ch0_5  = sram_rdata_a3[191:180];
        ch0_4  = sram_rdata_a3[179:168];
        ch0_3  = sram_rdata_a2[167:156];
        ch0_2  = sram_rdata_a2[155:144];
        ch0_1  = sram_rdata_a3[167:156];
        ch0_0  = sram_rdata_a3[155:144];

        ch1_15 = sram_rdata_a0[191-48:180-48];
        ch1_14 = sram_rdata_a0[179-48:168-48];
        ch1_13 = sram_rdata_a1[191-48:180-48];
        ch1_12 = sram_rdata_a1[179-48:168-48];
        ch1_11 = sram_rdata_a0[167-48:156-48];
        ch1_10 = sram_rdata_a0[155-48:144-48];
        ch1_9  = sram_rdata_a1[167-48:156-48];
        ch1_8  = sram_rdata_a1[155-48:144-48];
        ch1_7  = sram_rdata_a2[191-48:180-48];
        ch1_6  = sram_rdata_a2[179-48:168-48];
        ch1_5  = sram_rdata_a3[191-48:180-48];
        ch1_4  = sram_rdata_a3[179-48:168-48];
        ch1_3  = sram_rdata_a2[167-48:156-48];
        ch1_2  = sram_rdata_a2[155-48:144-48];
        ch1_1  = sram_rdata_a3[167-48:156-48];
        ch1_0  = sram_rdata_a3[155-48:144-48];

        ch2_15 = sram_rdata_a0[191-96:180-96];
        ch2_14 = sram_rdata_a0[179-96:168-96];
        ch2_13 = sram_rdata_a1[191-96:180-96];
        ch2_12 = sram_rdata_a1[179-96:168-96];
        ch2_11 = sram_rdata_a0[167-96:156-96];
        ch2_10 = sram_rdata_a0[155-96:144-96];
        ch2_9  = sram_rdata_a1[167-96:156-96];
        ch2_8  = sram_rdata_a1[155-96:144-96];
        ch2_7  = sram_rdata_a2[191-96:180-96];
        ch2_6  = sram_rdata_a2[179-96:168-96];
        ch2_5  = sram_rdata_a3[191-96:180-96];
        ch2_4  = sram_rdata_a3[179-96:168-96];
        ch2_3  = sram_rdata_a2[167-96:156-96];
        ch2_2  = sram_rdata_a2[155-96:144-96];
        ch2_1  = sram_rdata_a3[167-96:156-96];
        ch2_0  = sram_rdata_a3[155-96:144-96];

        ch3_15 = sram_rdata_a0[191-144:180-144];
        ch3_14 = sram_rdata_a0[179-144:168-144];
        ch3_13 = sram_rdata_a1[191-144:180-144];
        ch3_12 = sram_rdata_a1[179-144:168-144];
        ch3_11 = sram_rdata_a0[167-144:156-144];
        ch3_10 = sram_rdata_a0[155-144:144-144];
        ch3_9  = sram_rdata_a1[167-144:156-144];
        ch3_8  = sram_rdata_a1[155-144:144-144];
        ch3_7  = sram_rdata_a2[191-144:180-144];
        ch3_6  = sram_rdata_a2[179-144:168-144];
        ch3_5  = sram_rdata_a3[191-144:180-144];
        ch3_4  = sram_rdata_a3[179-144:168-144];
        ch3_3  = sram_rdata_a2[167-144:156-144];
        ch3_2  = sram_rdata_a2[155-144:144-144];
        ch3_1  = sram_rdata_a3[167-144:156-144];
        ch3_0  = sram_rdata_a3[155-144:144-144];
    end
end

// convolution
always @* begin
    origin_sum3_ch0 = ch0_15 * weight0_ch0_2D[8] + ch0_14 * weight0_ch0_2D[7] + ch0_13 * weight0_ch0_2D[6]
                    + ch0_11 * weight0_ch0_2D[5] + ch0_10 * weight0_ch0_2D[4] + ch0_9  * weight0_ch0_2D[3]
                    + ch0_7  * weight0_ch0_2D[2] + ch0_6  * weight0_ch0_2D[1] + ch0_5  * weight0_ch0_2D[0]
                    + ch1_15 * weight0_ch1_2D[8] + ch1_14 * weight0_ch1_2D[7] + ch1_13 * weight0_ch1_2D[6]
                    + ch1_11 * weight0_ch1_2D[5] + ch1_10 * weight0_ch1_2D[4] + ch1_9  * weight0_ch1_2D[3]
                    + ch1_7  * weight0_ch1_2D[2] + ch1_6  * weight0_ch1_2D[1] + ch1_5  * weight0_ch1_2D[0]
                    + ch2_15 * weight0_ch2_2D[8] + ch2_14 * weight0_ch2_2D[7] + ch2_13 * weight0_ch2_2D[6]
                    + ch2_11 * weight0_ch2_2D[5] + ch2_10 * weight0_ch2_2D[4] + ch2_9  * weight0_ch2_2D[3]
                    + ch2_7  * weight0_ch2_2D[2] + ch2_6  * weight0_ch2_2D[1] + ch2_5  * weight0_ch2_2D[0]
                    + ch3_15 * weight0_ch3_2D[8] + ch3_14 * weight0_ch3_2D[7] + ch3_13 * weight0_ch3_2D[6]
                    + ch3_11 * weight0_ch3_2D[5] + ch3_10 * weight0_ch3_2D[4] + ch3_9  * weight0_ch3_2D[3]
                    + ch3_7  * weight0_ch3_2D[2] + ch3_6  * weight0_ch3_2D[1] + ch3_5  * weight0_ch3_2D[0];

    origin_sum2_ch0 = ch0_14 * weight0_ch0_2D[8] + ch0_13 * weight0_ch0_2D[7] + ch0_12 * weight0_ch0_2D[6]
                    + ch0_10 * weight0_ch0_2D[5] + ch0_9  * weight0_ch0_2D[4] + ch0_8  * weight0_ch0_2D[3]
                    + ch0_6  * weight0_ch0_2D[2] + ch0_5  * weight0_ch0_2D[1] + ch0_4  * weight0_ch0_2D[0]
                    + ch1_14 * weight0_ch1_2D[8] + ch1_13 * weight0_ch1_2D[7] + ch1_12 * weight0_ch1_2D[6]
                    + ch1_10 * weight0_ch1_2D[5] + ch1_9  * weight0_ch1_2D[4] + ch1_8  * weight0_ch1_2D[3]
                    + ch1_6  * weight0_ch1_2D[2] + ch1_5  * weight0_ch1_2D[1] + ch1_4  * weight0_ch1_2D[0]
                    + ch2_14 * weight0_ch2_2D[8] + ch2_13 * weight0_ch2_2D[7] + ch2_12 * weight0_ch2_2D[6]
                    + ch2_10 * weight0_ch2_2D[5] + ch2_9  * weight0_ch2_2D[4] + ch2_8  * weight0_ch2_2D[3]
                    + ch2_6  * weight0_ch2_2D[2] + ch2_5  * weight0_ch2_2D[1] + ch2_4  * weight0_ch2_2D[0]
                    + ch3_14 * weight0_ch3_2D[8] + ch3_13 * weight0_ch3_2D[7] + ch3_12 * weight0_ch3_2D[6]
                    + ch3_10 * weight0_ch3_2D[5] + ch3_9  * weight0_ch3_2D[4] + ch3_8  * weight0_ch3_2D[3]
                    + ch3_6  * weight0_ch3_2D[2] + ch3_5  * weight0_ch3_2D[1] + ch3_4  * weight0_ch3_2D[0];

    origin_sum1_ch0 = ch0_11 * weight0_ch0_2D[8] + ch0_10 * weight0_ch0_2D[7] + ch0_9  * weight0_ch0_2D[6]
                    + ch0_7  * weight0_ch0_2D[5] + ch0_6  * weight0_ch0_2D[4] + ch0_5  * weight0_ch0_2D[3]
                    + ch0_3  * weight0_ch0_2D[2] + ch0_2  * weight0_ch0_2D[1] + ch0_1  * weight0_ch0_2D[0]
                    + ch1_11 * weight0_ch1_2D[8] + ch1_10 * weight0_ch1_2D[7] + ch1_9  * weight0_ch1_2D[6]
                    + ch1_7  * weight0_ch1_2D[5] + ch1_6  * weight0_ch1_2D[4] + ch1_5  * weight0_ch1_2D[3]
                    + ch1_3  * weight0_ch1_2D[2] + ch1_2  * weight0_ch1_2D[1] + ch1_1  * weight0_ch1_2D[0]
                    + ch2_11 * weight0_ch2_2D[8] + ch2_10 * weight0_ch2_2D[7] + ch2_9  * weight0_ch2_2D[6]
                    + ch2_7  * weight0_ch2_2D[5] + ch2_6  * weight0_ch2_2D[4] + ch2_5  * weight0_ch2_2D[3]
                    + ch2_3  * weight0_ch2_2D[2] + ch2_2  * weight0_ch2_2D[1] + ch2_1  * weight0_ch2_2D[0]
                    + ch3_11 * weight0_ch3_2D[8] + ch3_10 * weight0_ch3_2D[7] + ch3_9  * weight0_ch3_2D[6]
                    + ch3_7  * weight0_ch3_2D[5] + ch3_6  * weight0_ch3_2D[4] + ch3_5  * weight0_ch3_2D[3]
                    + ch3_3  * weight0_ch3_2D[2] + ch3_2  * weight0_ch3_2D[1] + ch3_1  * weight0_ch3_2D[0];

    origin_sum0_ch0 = ch0_10 * weight0_ch0_2D[8] + ch0_9  * weight0_ch0_2D[7] + ch0_8  * weight0_ch0_2D[6]
                    + ch0_6  * weight0_ch0_2D[5] + ch0_5  * weight0_ch0_2D[4] + ch0_4  * weight0_ch0_2D[3]
                    + ch0_2  * weight0_ch0_2D[2] + ch0_1  * weight0_ch0_2D[1] + ch0_0  * weight0_ch0_2D[0]
                    + ch1_10 * weight0_ch1_2D[8] + ch1_9  * weight0_ch1_2D[7] + ch1_8  * weight0_ch1_2D[6]
                    + ch1_6  * weight0_ch1_2D[5] + ch1_5  * weight0_ch1_2D[4] + ch1_4  * weight0_ch1_2D[3]
                    + ch1_2  * weight0_ch1_2D[2] + ch1_1  * weight0_ch1_2D[1] + ch1_0  * weight0_ch1_2D[0]
                    + ch2_10 * weight0_ch2_2D[8] + ch2_9  * weight0_ch2_2D[7] + ch2_8  * weight0_ch2_2D[6]
                    + ch2_6  * weight0_ch2_2D[5] + ch2_5  * weight0_ch2_2D[4] + ch2_4  * weight0_ch2_2D[3]
                    + ch2_2  * weight0_ch2_2D[2] + ch2_1  * weight0_ch2_2D[1] + ch2_0  * weight0_ch2_2D[0]
                    + ch3_10 * weight0_ch3_2D[8] + ch3_9  * weight0_ch3_2D[7] + ch3_8  * weight0_ch3_2D[6]
                    + ch3_6  * weight0_ch3_2D[5] + ch3_5  * weight0_ch3_2D[4] + ch3_4  * weight0_ch3_2D[3]
                    + ch3_2  * weight0_ch3_2D[2] + ch3_1  * weight0_ch3_2D[1] + ch3_0  * weight0_ch3_2D[0];

    origin_sum3_ch1 = ch0_15 * weight1_ch0_2D[8] + ch0_14 * weight1_ch0_2D[7] + ch0_13 * weight1_ch0_2D[6]
                    + ch0_11 * weight1_ch0_2D[5] + ch0_10 * weight1_ch0_2D[4] + ch0_9  * weight1_ch0_2D[3]
                    + ch0_7  * weight1_ch0_2D[2] + ch0_6  * weight1_ch0_2D[1] + ch0_5  * weight1_ch0_2D[0]
                    + ch1_15 * weight1_ch1_2D[8] + ch1_14 * weight1_ch1_2D[7] + ch1_13 * weight1_ch1_2D[6]
                    + ch1_11 * weight1_ch1_2D[5] + ch1_10 * weight1_ch1_2D[4] + ch1_9  * weight1_ch1_2D[3]
                    + ch1_7  * weight1_ch1_2D[2] + ch1_6  * weight1_ch1_2D[1] + ch1_5  * weight1_ch1_2D[0]
                    + ch2_15 * weight1_ch2_2D[8] + ch2_14 * weight1_ch2_2D[7] + ch2_13 * weight1_ch2_2D[6]
                    + ch2_11 * weight1_ch2_2D[5] + ch2_10 * weight1_ch2_2D[4] + ch2_9  * weight1_ch2_2D[3]
                    + ch2_7  * weight1_ch2_2D[2] + ch2_6  * weight1_ch2_2D[1] + ch2_5  * weight1_ch2_2D[0]
                    + ch3_15 * weight1_ch3_2D[8] + ch3_14 * weight1_ch3_2D[7] + ch3_13 * weight1_ch3_2D[6]
                    + ch3_11 * weight1_ch3_2D[5] + ch3_10 * weight1_ch3_2D[4] + ch3_9  * weight1_ch3_2D[3]
                    + ch3_7  * weight1_ch3_2D[2] + ch3_6  * weight1_ch3_2D[1] + ch3_5  * weight1_ch3_2D[0];

    origin_sum2_ch1 = ch0_14 * weight1_ch0_2D[8] + ch0_13 * weight1_ch0_2D[7] + ch0_12 * weight1_ch0_2D[6]
                    + ch0_10 * weight1_ch0_2D[5] + ch0_9  * weight1_ch0_2D[4] + ch0_8  * weight1_ch0_2D[3]
                    + ch0_6  * weight1_ch0_2D[2] + ch0_5  * weight1_ch0_2D[1] + ch0_4  * weight1_ch0_2D[0]
                    + ch1_14 * weight1_ch1_2D[8] + ch1_13 * weight1_ch1_2D[7] + ch1_12 * weight1_ch1_2D[6]
                    + ch1_10 * weight1_ch1_2D[5] + ch1_9  * weight1_ch1_2D[4] + ch1_8  * weight1_ch1_2D[3]
                    + ch1_6  * weight1_ch1_2D[2] + ch1_5  * weight1_ch1_2D[1] + ch1_4  * weight1_ch1_2D[0]
                    + ch2_14 * weight1_ch2_2D[8] + ch2_13 * weight1_ch2_2D[7] + ch2_12 * weight1_ch2_2D[6]
                    + ch2_10 * weight1_ch2_2D[5] + ch2_9  * weight1_ch2_2D[4] + ch2_8  * weight1_ch2_2D[3]
                    + ch2_6  * weight1_ch2_2D[2] + ch2_5  * weight1_ch2_2D[1] + ch2_4  * weight1_ch2_2D[0]
                    + ch3_14 * weight1_ch3_2D[8] + ch3_13 * weight1_ch3_2D[7] + ch3_12 * weight1_ch3_2D[6]
                    + ch3_10 * weight1_ch3_2D[5] + ch3_9  * weight1_ch3_2D[4] + ch3_8  * weight1_ch3_2D[3]
                    + ch3_6  * weight1_ch3_2D[2] + ch3_5  * weight1_ch3_2D[1] + ch3_4  * weight1_ch3_2D[0];

    origin_sum1_ch1 = ch0_11 * weight1_ch0_2D[8] + ch0_10 * weight1_ch0_2D[7] + ch0_9  * weight1_ch0_2D[6]
                    + ch0_7  * weight1_ch0_2D[5] + ch0_6  * weight1_ch0_2D[4] + ch0_5  * weight1_ch0_2D[3]
                    + ch0_3  * weight1_ch0_2D[2] + ch0_2  * weight1_ch0_2D[1] + ch0_1  * weight1_ch0_2D[0]
                    + ch1_11 * weight1_ch1_2D[8] + ch1_10 * weight1_ch1_2D[7] + ch1_9  * weight1_ch1_2D[6]
                    + ch1_7  * weight1_ch1_2D[5] + ch1_6  * weight1_ch1_2D[4] + ch1_5  * weight1_ch1_2D[3]
                    + ch1_3  * weight1_ch1_2D[2] + ch1_2  * weight1_ch1_2D[1] + ch1_1  * weight1_ch1_2D[0]
                    + ch2_11 * weight1_ch2_2D[8] + ch2_10 * weight1_ch2_2D[7] + ch2_9  * weight1_ch2_2D[6]
                    + ch2_7  * weight1_ch2_2D[5] + ch2_6  * weight1_ch2_2D[4] + ch2_5  * weight1_ch2_2D[3]
                    + ch2_3  * weight1_ch2_2D[2] + ch2_2  * weight1_ch2_2D[1] + ch2_1  * weight1_ch2_2D[0]
                    + ch3_11 * weight1_ch3_2D[8] + ch3_10 * weight1_ch3_2D[7] + ch3_9  * weight1_ch3_2D[6]
                    + ch3_7  * weight1_ch3_2D[5] + ch3_6  * weight1_ch3_2D[4] + ch3_5  * weight1_ch3_2D[3]
                    + ch3_3  * weight1_ch3_2D[2] + ch3_2  * weight1_ch3_2D[1] + ch3_1  * weight1_ch3_2D[0];

    origin_sum0_ch1 = ch0_10 * weight1_ch0_2D[8] + ch0_9  * weight1_ch0_2D[7] + ch0_8  * weight1_ch0_2D[6]
                    + ch0_6  * weight1_ch0_2D[5] + ch0_5  * weight1_ch0_2D[4] + ch0_4  * weight1_ch0_2D[3]
                    + ch0_2  * weight1_ch0_2D[2] + ch0_1  * weight1_ch0_2D[1] + ch0_0  * weight1_ch0_2D[0]
                    + ch1_10 * weight1_ch1_2D[8] + ch1_9  * weight1_ch1_2D[7] + ch1_8  * weight1_ch1_2D[6]
                    + ch1_6  * weight1_ch1_2D[5] + ch1_5  * weight1_ch1_2D[4] + ch1_4  * weight1_ch1_2D[3]
                    + ch1_2  * weight1_ch1_2D[2] + ch1_1  * weight1_ch1_2D[1] + ch1_0  * weight1_ch1_2D[0]
                    + ch2_10 * weight1_ch2_2D[8] + ch2_9  * weight1_ch2_2D[7] + ch2_8  * weight1_ch2_2D[6]
                    + ch2_6  * weight1_ch2_2D[5] + ch2_5  * weight1_ch2_2D[4] + ch2_4  * weight1_ch2_2D[3]
                    + ch2_2  * weight1_ch2_2D[2] + ch2_1  * weight1_ch2_2D[1] + ch2_0  * weight1_ch2_2D[0]
                    + ch3_10 * weight1_ch3_2D[8] + ch3_9  * weight1_ch3_2D[7] + ch3_8  * weight1_ch3_2D[6]
                    + ch3_6  * weight1_ch3_2D[5] + ch3_5  * weight1_ch3_2D[4] + ch3_4  * weight1_ch3_2D[3]
                    + ch3_2  * weight1_ch3_2D[2] + ch3_1  * weight1_ch3_2D[1] + ch3_0  * weight1_ch3_2D[0];

    origin_sum3_ch2 = ch0_15 * weight2_ch0_2D[8] + ch0_14 * weight2_ch0_2D[7] + ch0_13 * weight2_ch0_2D[6]
                    + ch0_11 * weight2_ch0_2D[5] + ch0_10 * weight2_ch0_2D[4] + ch0_9  * weight2_ch0_2D[3]
                    + ch0_7  * weight2_ch0_2D[2] + ch0_6  * weight2_ch0_2D[1] + ch0_5  * weight2_ch0_2D[0]
                    + ch1_15 * weight2_ch1_2D[8] + ch1_14 * weight2_ch1_2D[7] + ch1_13 * weight2_ch1_2D[6]
                    + ch1_11 * weight2_ch1_2D[5] + ch1_10 * weight2_ch1_2D[4] + ch1_9  * weight2_ch1_2D[3]
                    + ch1_7  * weight2_ch1_2D[2] + ch1_6  * weight2_ch1_2D[1] + ch1_5  * weight2_ch1_2D[0]
                    + ch2_15 * weight2_ch2_2D[8] + ch2_14 * weight2_ch2_2D[7] + ch2_13 * weight2_ch2_2D[6]
                    + ch2_11 * weight2_ch2_2D[5] + ch2_10 * weight2_ch2_2D[4] + ch2_9  * weight2_ch2_2D[3]
                    + ch2_7  * weight2_ch2_2D[2] + ch2_6  * weight2_ch2_2D[1] + ch2_5  * weight2_ch2_2D[0]
                    + ch3_15 * weight2_ch3_2D[8] + ch3_14 * weight2_ch3_2D[7] + ch3_13 * weight2_ch3_2D[6]
                    + ch3_11 * weight2_ch3_2D[5] + ch3_10 * weight2_ch3_2D[4] + ch3_9  * weight2_ch3_2D[3]
                    + ch3_7  * weight2_ch3_2D[2] + ch3_6  * weight2_ch3_2D[1] + ch3_5  * weight2_ch3_2D[0];

    origin_sum2_ch2 = ch0_14 * weight2_ch0_2D[8] + ch0_13 * weight2_ch0_2D[7] + ch0_12 * weight2_ch0_2D[6]
                    + ch0_10 * weight2_ch0_2D[5] + ch0_9  * weight2_ch0_2D[4] + ch0_8  * weight2_ch0_2D[3]
                    + ch0_6  * weight2_ch0_2D[2] + ch0_5  * weight2_ch0_2D[1] + ch0_4  * weight2_ch0_2D[0]
                    + ch1_14 * weight2_ch1_2D[8] + ch1_13 * weight2_ch1_2D[7] + ch1_12 * weight2_ch1_2D[6]
                    + ch1_10 * weight2_ch1_2D[5] + ch1_9  * weight2_ch1_2D[4] + ch1_8  * weight2_ch1_2D[3]
                    + ch1_6  * weight2_ch1_2D[2] + ch1_5  * weight2_ch1_2D[1] + ch1_4  * weight2_ch1_2D[0]
                    + ch2_14 * weight2_ch2_2D[8] + ch2_13 * weight2_ch2_2D[7] + ch2_12 * weight2_ch2_2D[6]
                    + ch2_10 * weight2_ch2_2D[5] + ch2_9  * weight2_ch2_2D[4] + ch2_8  * weight2_ch2_2D[3]
                    + ch2_6  * weight2_ch2_2D[2] + ch2_5  * weight2_ch2_2D[1] + ch2_4  * weight2_ch2_2D[0]
                    + ch3_14 * weight2_ch3_2D[8] + ch3_13 * weight2_ch3_2D[7] + ch3_12 * weight2_ch3_2D[6]
                    + ch3_10 * weight2_ch3_2D[5] + ch3_9  * weight2_ch3_2D[4] + ch3_8  * weight2_ch3_2D[3]
                    + ch3_6  * weight2_ch3_2D[2] + ch3_5  * weight2_ch3_2D[1] + ch3_4  * weight2_ch3_2D[0];

    origin_sum1_ch2 = ch0_11 * weight2_ch0_2D[8] + ch0_10 * weight2_ch0_2D[7] + ch0_9  * weight2_ch0_2D[6]
                    + ch0_7  * weight2_ch0_2D[5] + ch0_6  * weight2_ch0_2D[4] + ch0_5  * weight2_ch0_2D[3]
                    + ch0_3  * weight2_ch0_2D[2] + ch0_2  * weight2_ch0_2D[1] + ch0_1  * weight2_ch0_2D[0]
                    + ch1_11 * weight2_ch1_2D[8] + ch1_10 * weight2_ch1_2D[7] + ch1_9  * weight2_ch1_2D[6]
                    + ch1_7  * weight2_ch1_2D[5] + ch1_6  * weight2_ch1_2D[4] + ch1_5  * weight2_ch1_2D[3]
                    + ch1_3  * weight2_ch1_2D[2] + ch1_2  * weight2_ch1_2D[1] + ch1_1  * weight2_ch1_2D[0]
                    + ch2_11 * weight2_ch2_2D[8] + ch2_10 * weight2_ch2_2D[7] + ch2_9  * weight2_ch2_2D[6]
                    + ch2_7  * weight2_ch2_2D[5] + ch2_6  * weight2_ch2_2D[4] + ch2_5  * weight2_ch2_2D[3]
                    + ch2_3  * weight2_ch2_2D[2] + ch2_2  * weight2_ch2_2D[1] + ch2_1  * weight2_ch2_2D[0]
                    + ch3_11 * weight2_ch3_2D[8] + ch3_10 * weight2_ch3_2D[7] + ch3_9  * weight2_ch3_2D[6]
                    + ch3_7  * weight2_ch3_2D[5] + ch3_6  * weight2_ch3_2D[4] + ch3_5  * weight2_ch3_2D[3]
                    + ch3_3  * weight2_ch3_2D[2] + ch3_2  * weight2_ch3_2D[1] + ch3_1  * weight2_ch3_2D[0];

    origin_sum0_ch2 = ch0_10 * weight2_ch0_2D[8] + ch0_9  * weight2_ch0_2D[7] + ch0_8  * weight2_ch0_2D[6]
                    + ch0_6  * weight2_ch0_2D[5] + ch0_5  * weight2_ch0_2D[4] + ch0_4  * weight2_ch0_2D[3]
                    + ch0_2  * weight2_ch0_2D[2] + ch0_1  * weight2_ch0_2D[1] + ch0_0  * weight2_ch0_2D[0]
                    + ch1_10 * weight2_ch1_2D[8] + ch1_9  * weight2_ch1_2D[7] + ch1_8  * weight2_ch1_2D[6]
                    + ch1_6  * weight2_ch1_2D[5] + ch1_5  * weight2_ch1_2D[4] + ch1_4  * weight2_ch1_2D[3]
                    + ch1_2  * weight2_ch1_2D[2] + ch1_1  * weight2_ch1_2D[1] + ch1_0  * weight2_ch1_2D[0]
                    + ch2_10 * weight2_ch2_2D[8] + ch2_9  * weight2_ch2_2D[7] + ch2_8  * weight2_ch2_2D[6]
                    + ch2_6  * weight2_ch2_2D[5] + ch2_5  * weight2_ch2_2D[4] + ch2_4  * weight2_ch2_2D[3]
                    + ch2_2  * weight2_ch2_2D[2] + ch2_1  * weight2_ch2_2D[1] + ch2_0  * weight2_ch2_2D[0]
                    + ch3_10 * weight2_ch3_2D[8] + ch3_9  * weight2_ch3_2D[7] + ch3_8  * weight2_ch3_2D[6]
                    + ch3_6  * weight2_ch3_2D[5] + ch3_5  * weight2_ch3_2D[4] + ch3_4  * weight2_ch3_2D[3]
                    + ch3_2  * weight2_ch3_2D[2] + ch3_1  * weight2_ch3_2D[1] + ch3_0  * weight2_ch3_2D[0];

    origin_sum3_ch3 = ch0_15 * weight3_ch0_2D[8] + ch0_14 * weight3_ch0_2D[7] + ch0_13 * weight3_ch0_2D[6]
                    + ch0_11 * weight3_ch0_2D[5] + ch0_10 * weight3_ch0_2D[4] + ch0_9  * weight3_ch0_2D[3]
                    + ch0_7  * weight3_ch0_2D[2] + ch0_6  * weight3_ch0_2D[1] + ch0_5  * weight3_ch0_2D[0]
                    + ch1_15 * weight3_ch1_2D[8] + ch1_14 * weight3_ch1_2D[7] + ch1_13 * weight3_ch1_2D[6]
                    + ch1_11 * weight3_ch1_2D[5] + ch1_10 * weight3_ch1_2D[4] + ch1_9  * weight3_ch1_2D[3]
                    + ch1_7  * weight3_ch1_2D[2] + ch1_6  * weight3_ch1_2D[1] + ch1_5  * weight3_ch1_2D[0]
                    + ch2_15 * weight3_ch2_2D[8] + ch2_14 * weight3_ch2_2D[7] + ch2_13 * weight3_ch2_2D[6]
                    + ch2_11 * weight3_ch2_2D[5] + ch2_10 * weight3_ch2_2D[4] + ch2_9  * weight3_ch2_2D[3]
                    + ch2_7  * weight3_ch2_2D[2] + ch2_6  * weight3_ch2_2D[1] + ch2_5  * weight3_ch2_2D[0]
                    + ch3_15 * weight3_ch3_2D[8] + ch3_14 * weight3_ch3_2D[7] + ch3_13 * weight3_ch3_2D[6]
                    + ch3_11 * weight3_ch3_2D[5] + ch3_10 * weight3_ch3_2D[4] + ch3_9  * weight3_ch3_2D[3]
                    + ch3_7  * weight3_ch3_2D[2] + ch3_6  * weight3_ch3_2D[1] + ch3_5  * weight3_ch3_2D[0];

    origin_sum2_ch3 = ch0_14 * weight3_ch0_2D[8] + ch0_13 * weight3_ch0_2D[7] + ch0_12 * weight3_ch0_2D[6]
                    + ch0_10 * weight3_ch0_2D[5] + ch0_9  * weight3_ch0_2D[4] + ch0_8  * weight3_ch0_2D[3]
                    + ch0_6  * weight3_ch0_2D[2] + ch0_5  * weight3_ch0_2D[1] + ch0_4  * weight3_ch0_2D[0]
                    + ch1_14 * weight3_ch1_2D[8] + ch1_13 * weight3_ch1_2D[7] + ch1_12 * weight3_ch1_2D[6]
                    + ch1_10 * weight3_ch1_2D[5] + ch1_9  * weight3_ch1_2D[4] + ch1_8  * weight3_ch1_2D[3]
                    + ch1_6  * weight3_ch1_2D[2] + ch1_5  * weight3_ch1_2D[1] + ch1_4  * weight3_ch1_2D[0]
                    + ch2_14 * weight3_ch2_2D[8] + ch2_13 * weight3_ch2_2D[7] + ch2_12 * weight3_ch2_2D[6]
                    + ch2_10 * weight3_ch2_2D[5] + ch2_9  * weight3_ch2_2D[4] + ch2_8  * weight3_ch2_2D[3]
                    + ch2_6  * weight3_ch2_2D[2] + ch2_5  * weight3_ch2_2D[1] + ch2_4  * weight3_ch2_2D[0]
                    + ch3_14 * weight3_ch3_2D[8] + ch3_13 * weight3_ch3_2D[7] + ch3_12 * weight3_ch3_2D[6]
                    + ch3_10 * weight3_ch3_2D[5] + ch3_9  * weight3_ch3_2D[4] + ch3_8  * weight3_ch3_2D[3]
                    + ch3_6  * weight3_ch3_2D[2] + ch3_5  * weight3_ch3_2D[1] + ch3_4  * weight3_ch3_2D[0];

    origin_sum1_ch3 = ch0_11 * weight3_ch0_2D[8] + ch0_10 * weight3_ch0_2D[7] + ch0_9  * weight3_ch0_2D[6]
                    + ch0_7  * weight3_ch0_2D[5] + ch0_6  * weight3_ch0_2D[4] + ch0_5  * weight3_ch0_2D[3]
                    + ch0_3  * weight3_ch0_2D[2] + ch0_2  * weight3_ch0_2D[1] + ch0_1  * weight3_ch0_2D[0]
                    + ch1_11 * weight3_ch1_2D[8] + ch1_10 * weight3_ch1_2D[7] + ch1_9  * weight3_ch1_2D[6]
                    + ch1_7  * weight3_ch1_2D[5] + ch1_6  * weight3_ch1_2D[4] + ch1_5  * weight3_ch1_2D[3]
                    + ch1_3  * weight3_ch1_2D[2] + ch1_2  * weight3_ch1_2D[1] + ch1_1  * weight3_ch1_2D[0]
                    + ch2_11 * weight3_ch2_2D[8] + ch2_10 * weight3_ch2_2D[7] + ch2_9  * weight3_ch2_2D[6]
                    + ch2_7  * weight3_ch2_2D[5] + ch2_6  * weight3_ch2_2D[4] + ch2_5  * weight3_ch2_2D[3]
                    + ch2_3  * weight3_ch2_2D[2] + ch2_2  * weight3_ch2_2D[1] + ch2_1  * weight3_ch2_2D[0]
                    + ch3_11 * weight3_ch3_2D[8] + ch3_10 * weight3_ch3_2D[7] + ch3_9  * weight3_ch3_2D[6]
                    + ch3_7  * weight3_ch3_2D[5] + ch3_6  * weight3_ch3_2D[4] + ch3_5  * weight3_ch3_2D[3]
                    + ch3_3  * weight3_ch3_2D[2] + ch3_2  * weight3_ch3_2D[1] + ch3_1  * weight3_ch3_2D[0];

    origin_sum0_ch3 = ch0_10 * weight3_ch0_2D[8] + ch0_9  * weight3_ch0_2D[7] + ch0_8  * weight3_ch0_2D[6]
                    + ch0_6  * weight3_ch0_2D[5] + ch0_5  * weight3_ch0_2D[4] + ch0_4  * weight3_ch0_2D[3]
                    + ch0_2  * weight3_ch0_2D[2] + ch0_1  * weight3_ch0_2D[1] + ch0_0  * weight3_ch0_2D[0]
                    + ch1_10 * weight3_ch1_2D[8] + ch1_9  * weight3_ch1_2D[7] + ch1_8  * weight3_ch1_2D[6]
                    + ch1_6  * weight3_ch1_2D[5] + ch1_5  * weight3_ch1_2D[4] + ch1_4  * weight3_ch1_2D[3]
                    + ch1_2  * weight3_ch1_2D[2] + ch1_1  * weight3_ch1_2D[1] + ch1_0  * weight3_ch1_2D[0]
                    + ch2_10 * weight3_ch2_2D[8] + ch2_9  * weight3_ch2_2D[7] + ch2_8  * weight3_ch2_2D[6]
                    + ch2_6  * weight3_ch2_2D[5] + ch2_5  * weight3_ch2_2D[4] + ch2_4  * weight3_ch2_2D[3]
                    + ch2_2  * weight3_ch2_2D[2] + ch2_1  * weight3_ch2_2D[1] + ch2_0  * weight3_ch2_2D[0]
                    + ch3_10 * weight3_ch3_2D[8] + ch3_9  * weight3_ch3_2D[7] + ch3_8  * weight3_ch3_2D[6]
                    + ch3_6  * weight3_ch3_2D[5] + ch3_5  * weight3_ch3_2D[4] + ch3_4  * weight3_ch3_2D[3]
                    + ch3_2  * weight3_ch3_2D[2] + ch3_1  * weight3_ch3_2D[1] + ch3_0  * weight3_ch3_2D[0];

end

// set sram_wdata_b_next
always @* begin
    sram_wdata_b_next = {sum3_ch0_final, sum2_ch0_final, sum1_ch0_final, sum0_ch0_final, 
                         sum3_ch1_final, sum2_ch1_final, sum1_ch1_final, sum0_ch1_final,
                         sum3_ch2_final, sum2_ch2_final, sum1_ch2_final, sum0_ch2_final, 
                         sum3_ch3_final, sum2_ch3_final, sum1_ch3_final, sum0_ch3_final};
end

// set sram_wordmask_b_next
always @* begin
    if (conv_cnt_delay >= 0 && conv_cnt_delay <= 35) begin
        sram_wordmask_b_next = 16'b0000_0000_0000_0000;
    end
    else begin
        sram_wordmask_b_next = 16'b1111_1111_1111_1111;
    end
end

// set sram_waddr_b_next
always @* begin
    sram_waddr_b_next = sram_waddr_b;
    case (conv_cnt_delay) 
        8'd0: sram_waddr_b_next = 0;
        8'd1: sram_waddr_b_next = 0;
        8'd2: sram_waddr_b_next = 1;
        8'd3: sram_waddr_b_next = 1;
        8'd4: sram_waddr_b_next = 2;
        8'd5: sram_waddr_b_next = 2;
        8'd6: sram_waddr_b_next = 0;
        8'd7: sram_waddr_b_next = 0;
        8'd8: sram_waddr_b_next = 1;
        8'd9: sram_waddr_b_next = 1;
        8'd10: sram_waddr_b_next = 2;
        8'd11: sram_waddr_b_next = 2;
        8'd12: sram_waddr_b_next = 6;
        8'd13: sram_waddr_b_next = 6;
        8'd14: sram_waddr_b_next = 7;
        8'd15: sram_waddr_b_next = 7;
        8'd16: sram_waddr_b_next = 8;
        8'd17: sram_waddr_b_next = 8;
        8'd18: sram_waddr_b_next = 6;
        8'd19: sram_waddr_b_next = 6;
        8'd20: sram_waddr_b_next = 7;
        8'd21: sram_waddr_b_next = 7;
        8'd22: sram_waddr_b_next = 8;
        8'd23: sram_waddr_b_next = 8;
        8'd24: sram_waddr_b_next = 12;
        8'd25: sram_waddr_b_next = 12;
        8'd26: sram_waddr_b_next = 13;
        8'd27: sram_waddr_b_next = 13;
        8'd28: sram_waddr_b_next = 14;
        8'd29: sram_waddr_b_next = 14;
        8'd30: sram_waddr_b_next = 12;
        8'd31: sram_waddr_b_next = 12;
        8'd32: sram_waddr_b_next = 13;
        8'd33: sram_waddr_b_next = 13;
        8'd34: sram_waddr_b_next = 14;
        8'd35: sram_waddr_b_next = 14;

    endcase
end

// set valid_next
always @* begin
    if (conv_cnt_delay == 36) begin
        valid_next = 1;
    end
    else if (valid == 1) begin
        valid_next = 1;
    end
    else begin
        valid_next = 0;
    end
end

// local FSM
always @* begin
    case (local_state)
        WAIT: begin
            if (state == CONV1) begin
                local_state_next = READ_WEIGHT;
            end
            else begin
                local_state_next = WAIT;
            end
        end
        READ_WEIGHT: begin
            if (read_weight_cnt == 16) begin
                local_state_next = READ_BIAS;
            end
            else begin
                local_state_next = READ_WEIGHT;
            end
        end
        READ_BIAS: begin
            if (read_bias_cnt == 4) begin
                local_state_next = CAL;
            end
            else begin
                local_state_next = READ_BIAS;
            end
        end
        CAL: begin
            local_state_next = CAL;
        end
        default: local_state_next = WAIT;
    endcase
end

// FF
always @(posedge clk) begin
    if (~rst_n) begin
        local_state <= WAIT;
        read_weight_cnt <= 0;
        read_bias_cnt <= 0;

        weight0_ch0 <= 0;
        weight0_ch1 <= 0;
        weight0_ch2 <= 0;
        weight0_ch3 <= 0;
        weight1_ch0 <= 0;
        weight1_ch1 <= 0;
        weight1_ch2 <= 0;
        weight1_ch3 <= 0;
        weight2_ch0 <= 0;
        weight2_ch1 <= 0;
        weight2_ch2 <= 0;
        weight2_ch3 <= 0;
        weight3_ch0 <= 0;
        weight3_ch1 <= 0;
        weight3_ch2 <= 0;
        weight3_ch3 <= 0;

        bias0 <= 0;
        bias1 <= 0;
        bias2 <= 0;
        bias3 <= 0;

        conv_cnt <= 0;
        sram_raddr_a0 <= 0;
        sram_raddr_a1 <= 0;
        sram_raddr_a2 <= 0;
        sram_raddr_a3 <= 0;

        sram_rdata_a0 <= 0;
        sram_rdata_a1 <= 0;
        sram_rdata_a2 <= 0;
        sram_rdata_a3 <= 0;

        sram_wdata_b <= 0;
        sram_waddr_b <= 0;
        sram_wordmask_b <= 16'b1111_1111_1111_1111;
        sram_wen_b0 <= 1;
        sram_wen_b1 <= 1;
        sram_wen_b2 <= 1;
        sram_wen_b3 <= 1;

        valid <= 0;
        
    end
    else begin
        local_state <= local_state_next;
        read_weight_cnt <= read_weight_cnt_next;
        read_bias_cnt <= read_bias_cnt_next;

        weight0_ch0 <= weight0_ch0_next;
        weight0_ch1 <= weight0_ch1_next;
        weight0_ch2 <= weight0_ch2_next;
        weight0_ch3 <= weight0_ch3_next;
        weight1_ch0 <= weight1_ch0_next;
        weight1_ch1 <= weight1_ch1_next;
        weight1_ch2 <= weight1_ch2_next;
        weight1_ch3 <= weight1_ch3_next;
        weight2_ch0 <= weight2_ch0_next;
        weight2_ch1 <= weight2_ch1_next;
        weight2_ch2 <= weight2_ch2_next;
        weight2_ch3 <= weight2_ch3_next;
        weight3_ch0 <= weight3_ch0_next;
        weight3_ch1 <= weight3_ch1_next;
        weight3_ch2 <= weight3_ch2_next;
        weight3_ch3 <= weight3_ch3_next;

        bias0 <= bias0_next;
        bias1 <= bias1_next;
        bias2 <= bias2_next;
        bias3 <= bias3_next;

        conv_cnt <= conv_cnt_next;
        sram_raddr_a0 <= sram_raddr_a0_next;
        sram_raddr_a1 <= sram_raddr_a1_next;
        sram_raddr_a2 <= sram_raddr_a2_next;
        sram_raddr_a3 <= sram_raddr_a3_next;

        sram_rdata_a0 <= sram_rdata_a0_in;
        sram_rdata_a1 <= sram_rdata_a1_in;
        sram_rdata_a2 <= sram_rdata_a2_in;
        sram_rdata_a3 <= sram_rdata_a3_in;

        sram_wdata_b <= sram_wdata_b_next;
        sram_waddr_b <= sram_waddr_b_next;
        sram_wordmask_b <= sram_wordmask_b_next;
        sram_wen_b0 <= sram_wen_b0_next;
        sram_wen_b1 <= sram_wen_b1_next;
        sram_wen_b2 <= sram_wen_b2_next;
        sram_wen_b3 <= sram_wen_b3_next;

        valid <= valid_next;
    end
end

endmodule
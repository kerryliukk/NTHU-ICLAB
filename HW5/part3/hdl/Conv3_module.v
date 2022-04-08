// 讀A寫B
module Conv3_module #(
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

reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3;

reg [5:0] sram_raddr_a0_next;
reg [5:0] sram_raddr_a1_next;
reg [5:0] sram_raddr_a2_next;
reg [5:0] sram_raddr_a3_next;

reg [6-1:0] conv_cnt, conv_cnt_next;
reg [6-1:0] wait_cnt, wait_cnt_next;    // count from 0 ~ 47
reg [8-1:0] input_cnt, input_cnt_next;  // count from 0 ~ 15

wire [6-1:0] wait_finish;
assign wait_finish = 6'd13;


reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight_ch00, weight_ch01, weight_ch02, weight_ch03, weight_ch04, weight_ch05, weight_ch06, weight_ch07, weight_ch08, weight_ch09, weight_ch10, weight_ch11;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight_ch00_next, weight_ch01_next, weight_ch02_next, weight_ch03_next, weight_ch04_next, weight_ch05_next, weight_ch06_next, weight_ch07_next, weight_ch08_next, weight_ch09_next, weight_ch10_next, weight_ch11_next;
reg signed [BIAS_PER_ADDR*BW_PER_PARAM-1:0] bias, bias_next;

reg signed [BW_PER_PARAM-1:0] weight_ch00_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch01_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch02_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch03_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch04_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch05_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch06_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch07_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch08_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch09_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch10_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight_ch11_2D [0:WEIGHT_PER_ADDR-1];


reg signed [12-1:0] ch00_15, ch00_14, ch00_13, ch00_12, ch00_11, ch00_10, ch00_9, ch00_8, ch00_7, ch00_6, ch00_5, ch00_4, ch00_3, ch00_2, ch00_1, ch00_0;
reg signed [12-1:0] ch01_15, ch01_14, ch01_13, ch01_12, ch01_11, ch01_10, ch01_9, ch01_8, ch01_7, ch01_6, ch01_5, ch01_4, ch01_3, ch01_2, ch01_1, ch01_0;
reg signed [12-1:0] ch02_15, ch02_14, ch02_13, ch02_12, ch02_11, ch02_10, ch02_9, ch02_8, ch02_7, ch02_6, ch02_5, ch02_4, ch02_3, ch02_2, ch02_1, ch02_0;
reg signed [12-1:0] ch03_15, ch03_14, ch03_13, ch03_12, ch03_11, ch03_10, ch03_9, ch03_8, ch03_7, ch03_6, ch03_5, ch03_4, ch03_3, ch03_2, ch03_1, ch03_0;
reg signed [12-1:0] ch04_15, ch04_14, ch04_13, ch04_12, ch04_11, ch04_10, ch04_9, ch04_8, ch04_7, ch04_6, ch04_5, ch04_4, ch04_3, ch04_2, ch04_1, ch04_0;
reg signed [12-1:0] ch05_15, ch05_14, ch05_13, ch05_12, ch05_11, ch05_10, ch05_9, ch05_8, ch05_7, ch05_6, ch05_5, ch05_4, ch05_3, ch05_2, ch05_1, ch05_0;
reg signed [12-1:0] ch06_15, ch06_14, ch06_13, ch06_12, ch06_11, ch06_10, ch06_9, ch06_8, ch06_7, ch06_6, ch06_5, ch06_4, ch06_3, ch06_2, ch06_1, ch06_0;
reg signed [12-1:0] ch07_15, ch07_14, ch07_13, ch07_12, ch07_11, ch07_10, ch07_9, ch07_8, ch07_7, ch07_6, ch07_5, ch07_4, ch07_3, ch07_2, ch07_1, ch07_0;
reg signed [12-1:0] ch08_15, ch08_14, ch08_13, ch08_12, ch08_11, ch08_10, ch08_9, ch08_8, ch08_7, ch08_6, ch08_5, ch08_4, ch08_3, ch08_2, ch08_1, ch08_0;
reg signed [12-1:0] ch09_15, ch09_14, ch09_13, ch09_12, ch09_11, ch09_10, ch09_9, ch09_8, ch09_7, ch09_6, ch09_5, ch09_4, ch09_3, ch09_2, ch09_1, ch09_0;
reg signed [12-1:0] ch10_15, ch10_14, ch10_13, ch10_12, ch10_11, ch10_10, ch10_9, ch10_8, ch10_7, ch10_6, ch10_5, ch10_4, ch10_3, ch10_2, ch10_1, ch10_0;
reg signed [12-1:0] ch11_15, ch11_14, ch11_13, ch11_12, ch11_11, ch11_10, ch11_9, ch11_8, ch11_7, ch11_6, ch11_5, ch11_4, ch11_3, ch11_2, ch11_1, ch11_0;

reg signed [12-1:0] ch00_15_next, ch00_14_next, ch00_13_next, ch00_12_next, ch00_11_next, ch00_10_next, ch00_9_next, ch00_8_next, ch00_7_next, ch00_6_next, ch00_5_next, ch00_4_next, ch00_3_next, ch00_2_next, ch00_1_next, ch00_0_next;
reg signed [12-1:0] ch01_15_next, ch01_14_next, ch01_13_next, ch01_12_next, ch01_11_next, ch01_10_next, ch01_9_next, ch01_8_next, ch01_7_next, ch01_6_next, ch01_5_next, ch01_4_next, ch01_3_next, ch01_2_next, ch01_1_next, ch01_0_next;
reg signed [12-1:0] ch02_15_next, ch02_14_next, ch02_13_next, ch02_12_next, ch02_11_next, ch02_10_next, ch02_9_next, ch02_8_next, ch02_7_next, ch02_6_next, ch02_5_next, ch02_4_next, ch02_3_next, ch02_2_next, ch02_1_next, ch02_0_next;
reg signed [12-1:0] ch03_15_next, ch03_14_next, ch03_13_next, ch03_12_next, ch03_11_next, ch03_10_next, ch03_9_next, ch03_8_next, ch03_7_next, ch03_6_next, ch03_5_next, ch03_4_next, ch03_3_next, ch03_2_next, ch03_1_next, ch03_0_next;
reg signed [12-1:0] ch04_15_next, ch04_14_next, ch04_13_next, ch04_12_next, ch04_11_next, ch04_10_next, ch04_9_next, ch04_8_next, ch04_7_next, ch04_6_next, ch04_5_next, ch04_4_next, ch04_3_next, ch04_2_next, ch04_1_next, ch04_0_next;
reg signed [12-1:0] ch05_15_next, ch05_14_next, ch05_13_next, ch05_12_next, ch05_11_next, ch05_10_next, ch05_9_next, ch05_8_next, ch05_7_next, ch05_6_next, ch05_5_next, ch05_4_next, ch05_3_next, ch05_2_next, ch05_1_next, ch05_0_next;
reg signed [12-1:0] ch06_15_next, ch06_14_next, ch06_13_next, ch06_12_next, ch06_11_next, ch06_10_next, ch06_9_next, ch06_8_next, ch06_7_next, ch06_6_next, ch06_5_next, ch06_4_next, ch06_3_next, ch06_2_next, ch06_1_next, ch06_0_next;
reg signed [12-1:0] ch07_15_next, ch07_14_next, ch07_13_next, ch07_12_next, ch07_11_next, ch07_10_next, ch07_9_next, ch07_8_next, ch07_7_next, ch07_6_next, ch07_5_next, ch07_4_next, ch07_3_next, ch07_2_next, ch07_1_next, ch07_0_next;
reg signed [12-1:0] ch08_15_next, ch08_14_next, ch08_13_next, ch08_12_next, ch08_11_next, ch08_10_next, ch08_9_next, ch08_8_next, ch08_7_next, ch08_6_next, ch08_5_next, ch08_4_next, ch08_3_next, ch08_2_next, ch08_1_next, ch08_0_next;
reg signed [12-1:0] ch09_15_next, ch09_14_next, ch09_13_next, ch09_12_next, ch09_11_next, ch09_10_next, ch09_9_next, ch09_8_next, ch09_7_next, ch09_6_next, ch09_5_next, ch09_4_next, ch09_3_next, ch09_2_next, ch09_1_next, ch09_0_next;
reg signed [12-1:0] ch10_15_next, ch10_14_next, ch10_13_next, ch10_12_next, ch10_11_next, ch10_10_next, ch10_9_next, ch10_8_next, ch10_7_next, ch10_6_next, ch10_5_next, ch10_4_next, ch10_3_next, ch10_2_next, ch10_1_next, ch10_0_next;
reg signed [12-1:0] ch11_15_next, ch11_14_next, ch11_13_next, ch11_12_next, ch11_11_next, ch11_10_next, ch11_9_next, ch11_8_next, ch11_7_next, ch11_6_next, ch11_5_next, ch11_4_next, ch11_3_next, ch11_2_next, ch11_1_next, ch11_0_next;

// 3左上角 2右上角 1左下角 0右下角
reg signed [21-1:0] origin_sum3, origin_sum2, origin_sum1, origin_sum0;
reg signed [21-1:0] sum3_acc, sum2_acc, sum1_acc, sum0_acc;
reg signed [21-1:0] average, average_quan_temp, average_quan;
reg signed [BW_PER_ACT-1:0] average_final;


reg sram_wen_b0_next;
reg sram_wen_b1_next;
reg sram_wen_b2_next;
reg sram_wen_b3_next;

reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b_next;
reg [5:0] sram_waddr_b_next;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b_next;
reg valid_next;

// set conv_cnt_next
always @* begin
    if (local_state == CAL && wait_cnt == wait_finish && conv_cnt != 47) begin
        conv_cnt_next = conv_cnt + 1;
    end
    else if (local_state == CAL && wait_cnt == wait_finish && conv_cnt == 47) begin
        conv_cnt_next = 0;
    end
    else begin
        conv_cnt_next = conv_cnt;
    end
end

// set wait_cnt_next
always @* begin
    if (local_state == CAL && wait_cnt != wait_finish) begin
        wait_cnt_next = wait_cnt + 1;
    end
    else if (local_state == CAL && wait_cnt == wait_finish) begin
        wait_cnt_next = 0;
    end
    else begin
        wait_cnt_next = wait_cnt;
    end
end

// set input_cnt_next
always @* begin
    if (conv_cnt == 47 && wait_cnt == wait_finish)
        input_cnt_next = input_cnt + 1;
    else 
        input_cnt_next = input_cnt;
end

// set sram_raddr_weight
always @* begin
    sram_raddr_weight = 12 * conv_cnt + wait_cnt + 64;
end

// set weight value
always @* begin
    weight_ch00_next = weight_ch00;
    weight_ch01_next = weight_ch01;
    weight_ch02_next = weight_ch02;
    weight_ch03_next = weight_ch03;
    weight_ch04_next = weight_ch04;
    weight_ch05_next = weight_ch05;
    weight_ch06_next = weight_ch06;
    weight_ch07_next = weight_ch07;
    weight_ch08_next = weight_ch08;
    weight_ch09_next = weight_ch09;
    weight_ch10_next = weight_ch10;
    weight_ch11_next = weight_ch11;
    if (wait_cnt == 6'd1)
        weight_ch00_next = sram_rdata_weight;
    if (wait_cnt == 6'd2)
        weight_ch01_next = sram_rdata_weight;
    if (wait_cnt == 6'd3)
        weight_ch02_next = sram_rdata_weight;
    if (wait_cnt == 6'd4)
        weight_ch03_next = sram_rdata_weight;
    if (wait_cnt == 6'd5)
        weight_ch04_next = sram_rdata_weight;
    if (wait_cnt == 6'd6)
        weight_ch05_next = sram_rdata_weight;
    if (wait_cnt == 6'd7)
        weight_ch06_next = sram_rdata_weight;
    if (wait_cnt == 6'd8)
        weight_ch07_next = sram_rdata_weight;
    if (wait_cnt == 6'd9)
        weight_ch08_next = sram_rdata_weight;
    if (wait_cnt == 6'd10)
        weight_ch09_next = sram_rdata_weight;
    if (wait_cnt == 6'd11)
        weight_ch10_next = sram_rdata_weight;
    if (wait_cnt == 6'd12)
        weight_ch11_next = sram_rdata_weight;
end

// weight splitter
always @* begin
    for (i = 0; i < 9; i = i + 1) begin
        weight_ch00_2D[i] = weight_ch00[8*i+:8];
        weight_ch01_2D[i] = weight_ch01[8*i+:8];
        weight_ch02_2D[i] = weight_ch02[8*i+:8];
        weight_ch03_2D[i] = weight_ch03[8*i+:8];
        weight_ch04_2D[i] = weight_ch04[8*i+:8];
        weight_ch05_2D[i] = weight_ch05[8*i+:8];
        weight_ch06_2D[i] = weight_ch06[8*i+:8];
        weight_ch07_2D[i] = weight_ch07[8*i+:8];
        weight_ch08_2D[i] = weight_ch08[8*i+:8];
        weight_ch09_2D[i] = weight_ch09[8*i+:8];
        weight_ch10_2D[i] = weight_ch10[8*i+:8];
        weight_ch11_2D[i] = weight_ch11[8*i+:8];
    end
end

// read bias address
always @* begin
    sram_raddr_bias = conv_cnt + 16;
end

// set bias value
always @* begin
    if (wait_cnt == 2)
        bias_next = sram_rdata_bias;
    else 
        bias_next = bias;
end

// set sram_raddr_a0_next ~ sram_raddr_a3_next
always @* begin
    sram_raddr_a0_next = sram_raddr_a0;
    sram_raddr_a1_next = sram_raddr_a1;
    sram_raddr_a2_next = sram_raddr_a2;
    sram_raddr_a3_next = sram_raddr_a3;
    if (input_cnt == 0) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 0;
            sram_raddr_a1_next = 0;
            sram_raddr_a2_next = 0;
            sram_raddr_a3_next = 0;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 3;
            sram_raddr_a1_next = 3;
            sram_raddr_a2_next = 3;
            sram_raddr_a3_next = 3;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 18;
            sram_raddr_a1_next = 18;
            sram_raddr_a2_next = 18;
            sram_raddr_a3_next = 18;
        end
    end
    else if (input_cnt == 1) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 1;
            sram_raddr_a1_next = 0;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 0;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 4;
            sram_raddr_a1_next = 3;
            sram_raddr_a2_next = 4;
            sram_raddr_a3_next = 3;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 19;
            sram_raddr_a1_next = 18;
            sram_raddr_a2_next = 19;
            sram_raddr_a3_next = 18;
        end
    end
    else if (input_cnt == 2) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 1;
            sram_raddr_a1_next = 1;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 1;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 4;
            sram_raddr_a1_next = 4;
            sram_raddr_a2_next = 4;
            sram_raddr_a3_next = 4;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 19;
            sram_raddr_a1_next = 19;
            sram_raddr_a2_next = 19;
            sram_raddr_a3_next = 19;
        end
    end
    else if (input_cnt == 3) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 2;
            sram_raddr_a1_next = 1;
            sram_raddr_a2_next = 2;
            sram_raddr_a3_next = 1;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 5;
            sram_raddr_a1_next = 4;
            sram_raddr_a2_next = 5;
            sram_raddr_a3_next = 4;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 20;
            sram_raddr_a1_next = 19;
            sram_raddr_a2_next = 20;
            sram_raddr_a3_next = 19;
        end
    end
    else if (input_cnt == 4) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 6;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 0;
            sram_raddr_a3_next = 0;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 9;
            sram_raddr_a1_next = 9;
            sram_raddr_a2_next = 3;
            sram_raddr_a3_next = 3;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 24;
            sram_raddr_a1_next = 24;
            sram_raddr_a2_next = 18;
            sram_raddr_a3_next = 18;
        end
    end
    else if (input_cnt == 5) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 0;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 10;
            sram_raddr_a1_next = 9;
            sram_raddr_a2_next = 4;
            sram_raddr_a3_next = 3;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 25;
            sram_raddr_a1_next = 24;
            sram_raddr_a2_next = 19;
            sram_raddr_a3_next = 18;
        end
    end
    else if (input_cnt == 6) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 1;
            sram_raddr_a3_next = 1;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 10;
            sram_raddr_a1_next = 10;
            sram_raddr_a2_next = 4;
            sram_raddr_a3_next = 4;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 25;
            sram_raddr_a1_next = 25;
            sram_raddr_a2_next = 19;
            sram_raddr_a3_next = 19;
        end
    end
    else if (input_cnt == 7) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 8;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 2;
            sram_raddr_a3_next = 1;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 11;
            sram_raddr_a1_next = 10;
            sram_raddr_a2_next = 5;
            sram_raddr_a3_next = 4;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 26;
            sram_raddr_a1_next = 25;
            sram_raddr_a2_next = 20;
            sram_raddr_a3_next = 19;
        end
    end
    else if (input_cnt == 8) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 6;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 6;
            sram_raddr_a3_next = 6;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 9;
            sram_raddr_a1_next = 9;
            sram_raddr_a2_next = 9;
            sram_raddr_a3_next = 9;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 24;
            sram_raddr_a1_next = 24;
            sram_raddr_a2_next = 24;
            sram_raddr_a3_next = 24;
        end
    end
    else if (input_cnt == 9) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 6;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 6;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 10;
            sram_raddr_a1_next = 9;
            sram_raddr_a2_next = 10;
            sram_raddr_a3_next = 9;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 25;
            sram_raddr_a1_next = 24;
            sram_raddr_a2_next = 25;
            sram_raddr_a3_next = 24;
        end
    end
    else if (input_cnt == 10) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 7;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 7;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 10;
            sram_raddr_a1_next = 10;
            sram_raddr_a2_next = 10;
            sram_raddr_a3_next = 10;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 25;
            sram_raddr_a1_next = 25;
            sram_raddr_a2_next = 25;
            sram_raddr_a3_next = 25;
        end
    end
    else if (input_cnt == 11) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 8;
            sram_raddr_a1_next = 7;
            sram_raddr_a2_next = 8;
            sram_raddr_a3_next = 7;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 11;
            sram_raddr_a1_next = 10;
            sram_raddr_a2_next = 11;
            sram_raddr_a3_next = 10;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 26;
            sram_raddr_a1_next = 25;
            sram_raddr_a2_next = 26;
            sram_raddr_a3_next = 25;
        end
    end
    else if (input_cnt == 12) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 12;
            sram_raddr_a1_next = 12;
            sram_raddr_a2_next = 6;
            sram_raddr_a3_next = 6;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 15;
            sram_raddr_a1_next = 15;
            sram_raddr_a2_next = 9;
            sram_raddr_a3_next = 9;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 30;
            sram_raddr_a1_next = 30;
            sram_raddr_a2_next = 24;
            sram_raddr_a3_next = 24;
        end
    end
    else if (input_cnt == 13) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 13;
            sram_raddr_a1_next = 12;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 6;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 16;
            sram_raddr_a1_next = 15;
            sram_raddr_a2_next = 10;
            sram_raddr_a3_next = 9;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 31;
            sram_raddr_a1_next = 30;
            sram_raddr_a2_next = 25;
            sram_raddr_a3_next = 24;
        end
    end
    else if (input_cnt == 14) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 13;
            sram_raddr_a1_next = 13;
            sram_raddr_a2_next = 7;
            sram_raddr_a3_next = 7;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 16;
            sram_raddr_a1_next = 16;
            sram_raddr_a2_next = 10;
            sram_raddr_a3_next = 10;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 31;
            sram_raddr_a1_next = 31;
            sram_raddr_a2_next = 25;
            sram_raddr_a3_next = 25;
        end
    end
    else if (input_cnt == 15) begin
        if (wait_cnt == 0) begin
            sram_raddr_a0_next = 14;
            sram_raddr_a1_next = 13;
            sram_raddr_a2_next = 8;
            sram_raddr_a3_next = 7;
        end
        else if (wait_cnt == 1) begin
            sram_raddr_a0_next = 17;
            sram_raddr_a1_next = 16;
            sram_raddr_a2_next = 11;
            sram_raddr_a3_next = 10;
        end
        else if (wait_cnt == 2) begin
            sram_raddr_a0_next = 32;
            sram_raddr_a1_next = 31;
            sram_raddr_a2_next = 26;
            sram_raddr_a3_next = 25;
        end
    end
end

// set ch value
always @* begin
    ch00_0_next = ch00_0;
    ch00_1_next = ch00_1;
    ch00_2_next = ch00_2;
    ch00_3_next = ch00_3;
    ch00_4_next = ch00_4;
    ch00_5_next = ch00_5;
    ch00_6_next = ch00_6;
    ch00_7_next = ch00_7;
    ch00_8_next = ch00_8;
    ch00_9_next = ch00_9;
    ch00_10_next = ch00_10;
    ch00_11_next = ch00_11;
    ch00_12_next = ch00_12;
    ch00_13_next = ch00_13;
    ch00_14_next = ch00_14;
    ch00_15_next = ch00_15;
    ch01_0_next = ch01_0;
    ch01_1_next = ch01_1;
    ch01_2_next = ch01_2;
    ch01_3_next = ch01_3;
    ch01_4_next = ch01_4;
    ch01_5_next = ch01_5;
    ch01_6_next = ch01_6;
    ch01_7_next = ch01_7;
    ch01_8_next = ch01_8;
    ch01_9_next = ch01_9;
    ch01_10_next = ch01_10;
    ch01_11_next = ch01_11;
    ch01_12_next = ch01_12;
    ch01_13_next = ch01_13;
    ch01_14_next = ch01_14;
    ch01_15_next = ch01_15;
    ch02_0_next = ch02_0;
    ch02_1_next = ch02_1;
    ch02_2_next = ch02_2;
    ch02_3_next = ch02_3;
    ch02_4_next = ch02_4;
    ch02_5_next = ch02_5;
    ch02_6_next = ch02_6;
    ch02_7_next = ch02_7;
    ch02_8_next = ch02_8;
    ch02_9_next = ch02_9;
    ch02_10_next = ch02_10;
    ch02_11_next = ch02_11;
    ch02_12_next = ch02_12;
    ch02_13_next = ch02_13;
    ch02_14_next = ch02_14;
    ch02_15_next = ch02_15;
    ch03_0_next = ch03_0;
    ch03_1_next = ch03_1;
    ch03_2_next = ch03_2;
    ch03_3_next = ch03_3;
    ch03_4_next = ch03_4;
    ch03_5_next = ch03_5;
    ch03_6_next = ch03_6;
    ch03_7_next = ch03_7;
    ch03_8_next = ch03_8;
    ch03_9_next = ch03_9;
    ch03_10_next = ch03_10;
    ch03_11_next = ch03_11;
    ch03_12_next = ch03_12;
    ch03_13_next = ch03_13;
    ch03_14_next = ch03_14;
    ch03_15_next = ch03_15;
    ch04_0_next = ch04_0;
    ch04_1_next = ch04_1;
    ch04_2_next = ch04_2;
    ch04_3_next = ch04_3;
    ch04_4_next = ch04_4;
    ch04_5_next = ch04_5;
    ch04_6_next = ch04_6;
    ch04_7_next = ch04_7;
    ch04_8_next = ch04_8;
    ch04_9_next = ch04_9;
    ch04_10_next = ch04_10;
    ch04_11_next = ch04_11;
    ch04_12_next = ch04_12;
    ch04_13_next = ch04_13;
    ch04_14_next = ch04_14;
    ch04_15_next = ch04_15;
    ch05_0_next = ch05_0;
    ch05_1_next = ch05_1;
    ch05_2_next = ch05_2;
    ch05_3_next = ch05_3;
    ch05_4_next = ch05_4;
    ch05_5_next = ch05_5;
    ch05_6_next = ch05_6;
    ch05_7_next = ch05_7;
    ch05_8_next = ch05_8;
    ch05_9_next = ch05_9;
    ch05_10_next = ch05_10;
    ch05_11_next = ch05_11;
    ch05_12_next = ch05_12;
    ch05_13_next = ch05_13;
    ch05_14_next = ch05_14;
    ch05_15_next = ch05_15;
    ch06_0_next = ch06_0;
    ch06_1_next = ch06_1;
    ch06_2_next = ch06_2;
    ch06_3_next = ch06_3;
    ch06_4_next = ch06_4;
    ch06_5_next = ch06_5;
    ch06_6_next = ch06_6;
    ch06_7_next = ch06_7;
    ch06_8_next = ch06_8;
    ch06_9_next = ch06_9;
    ch06_10_next = ch06_10;
    ch06_11_next = ch06_11;
    ch06_12_next = ch06_12;
    ch06_13_next = ch06_13;
    ch06_14_next = ch06_14;
    ch06_15_next = ch06_15;
    ch07_0_next = ch07_0;
    ch07_1_next = ch07_1;
    ch07_2_next = ch07_2;
    ch07_3_next = ch07_3;
    ch07_4_next = ch07_4;
    ch07_5_next = ch07_5;
    ch07_6_next = ch07_6;
    ch07_7_next = ch07_7;
    ch07_8_next = ch07_8;
    ch07_9_next = ch07_9;
    ch07_10_next = ch07_10;
    ch07_11_next = ch07_11;
    ch07_12_next = ch07_12;
    ch07_13_next = ch07_13;
    ch07_14_next = ch07_14;
    ch07_15_next = ch07_15;
    ch08_0_next = ch08_0;
    ch08_1_next = ch08_1;
    ch08_2_next = ch08_2;
    ch08_3_next = ch08_3;
    ch08_4_next = ch08_4;
    ch08_5_next = ch08_5;
    ch08_6_next = ch08_6;
    ch08_7_next = ch08_7;
    ch08_8_next = ch08_8;
    ch08_9_next = ch08_9;
    ch08_10_next = ch08_10;
    ch08_11_next = ch08_11;
    ch08_12_next = ch08_12;
    ch08_13_next = ch08_13;
    ch08_14_next = ch08_14;
    ch08_15_next = ch08_15;
    ch09_0_next = ch09_0;
    ch09_1_next = ch09_1;
    ch09_2_next = ch09_2;
    ch09_3_next = ch09_3;
    ch09_4_next = ch09_4;
    ch09_5_next = ch09_5;
    ch09_6_next = ch09_6;
    ch09_7_next = ch09_7;
    ch09_8_next = ch09_8;
    ch09_9_next = ch09_9;
    ch09_10_next = ch09_10;
    ch09_11_next = ch09_11;
    ch09_12_next = ch09_12;
    ch09_13_next = ch09_13;
    ch09_14_next = ch09_14;
    ch09_15_next = ch09_15;
    ch10_0_next = ch10_0;
    ch10_1_next = ch10_1;
    ch10_2_next = ch10_2;
    ch10_3_next = ch10_3;
    ch10_4_next = ch10_4;
    ch10_5_next = ch10_5;
    ch10_6_next = ch10_6;
    ch10_7_next = ch10_7;
    ch10_8_next = ch10_8;
    ch10_9_next = ch10_9;
    ch10_10_next = ch10_10;
    ch10_11_next = ch10_11;
    ch10_12_next = ch10_12;
    ch10_13_next = ch10_13;
    ch10_14_next = ch10_14;
    ch10_15_next = ch10_15;
    ch11_0_next = ch11_0;
    ch11_1_next = ch11_1;
    ch11_2_next = ch11_2;
    ch11_3_next = ch11_3;
    ch11_4_next = ch11_4;
    ch11_5_next = ch11_5;
    ch11_6_next = ch11_6;
    ch11_7_next = ch11_7;
    ch11_8_next = ch11_8;
    ch11_9_next = ch11_9;
    ch11_10_next = ch11_10;
    ch11_11_next = ch11_11;
    ch11_12_next = ch11_12;
    ch11_13_next = ch11_13;
    ch11_14_next = ch11_14;
    ch11_15_next = ch11_15;
    if (input_cnt == 0 || input_cnt == 2 || input_cnt == 8 || input_cnt == 10) begin
        if (wait_cnt == 3) begin
            ch00_15_next = sram_rdata_a0[191:180];
            ch00_14_next = sram_rdata_a0[179:168];
            ch00_13_next = sram_rdata_a1[191:180];
            ch00_12_next = sram_rdata_a1[179:168];
            ch00_11_next = sram_rdata_a0[167:156];
            ch00_10_next = sram_rdata_a0[155:144];
            ch00_9_next = sram_rdata_a1[167:156];
            ch00_8_next = sram_rdata_a1[155:144];
            ch00_7_next = sram_rdata_a2[191:180];
            ch00_6_next = sram_rdata_a2[179:168];
            ch00_5_next = sram_rdata_a3[191:180];
            ch00_4_next = sram_rdata_a3[179:168];
            ch00_3_next = sram_rdata_a2[167:156];
            ch00_2_next = sram_rdata_a2[155:144];
            ch00_1_next = sram_rdata_a3[167:156];
            ch00_0_next = sram_rdata_a3[155:144];

            ch01_15_next = sram_rdata_a0[191-48:180-48];
            ch01_14_next = sram_rdata_a0[179-48:168-48];
            ch01_13_next = sram_rdata_a1[191-48:180-48];
            ch01_12_next = sram_rdata_a1[179-48:168-48];
            ch01_11_next = sram_rdata_a0[167-48:156-48];
            ch01_10_next = sram_rdata_a0[155-48:144-48];
            ch01_9_next = sram_rdata_a1[167-48:156-48];
            ch01_8_next = sram_rdata_a1[155-48:144-48];
            ch01_7_next = sram_rdata_a2[191-48:180-48];
            ch01_6_next = sram_rdata_a2[179-48:168-48];
            ch01_5_next = sram_rdata_a3[191-48:180-48];
            ch01_4_next = sram_rdata_a3[179-48:168-48];
            ch01_3_next = sram_rdata_a2[167-48:156-48];
            ch01_2_next = sram_rdata_a2[155-48:144-48];
            ch01_1_next = sram_rdata_a3[167-48:156-48];
            ch01_0_next = sram_rdata_a3[155-48:144-48];

            ch02_15_next = sram_rdata_a0[191-96:180-96];
            ch02_14_next = sram_rdata_a0[179-96:168-96];
            ch02_13_next = sram_rdata_a1[191-96:180-96];
            ch02_12_next = sram_rdata_a1[179-96:168-96];
            ch02_11_next = sram_rdata_a0[167-96:156-96];
            ch02_10_next = sram_rdata_a0[155-96:144-96];
            ch02_9_next = sram_rdata_a1[167-96:156-96];
            ch02_8_next = sram_rdata_a1[155-96:144-96];
            ch02_7_next = sram_rdata_a2[191-96:180-96];
            ch02_6_next = sram_rdata_a2[179-96:168-96];
            ch02_5_next = sram_rdata_a3[191-96:180-96];
            ch02_4_next = sram_rdata_a3[179-96:168-96];
            ch02_3_next = sram_rdata_a2[167-96:156-96];
            ch02_2_next = sram_rdata_a2[155-96:144-96];
            ch02_1_next = sram_rdata_a3[167-96:156-96];
            ch02_0_next = sram_rdata_a3[155-96:144-96];

            ch03_15_next = sram_rdata_a0[191-144:180-144];
            ch03_14_next = sram_rdata_a0[179-144:168-144];
            ch03_13_next = sram_rdata_a1[191-144:180-144];
            ch03_12_next = sram_rdata_a1[179-144:168-144];
            ch03_11_next = sram_rdata_a0[167-144:156-144];
            ch03_10_next = sram_rdata_a0[155-144:144-144];
            ch03_9_next = sram_rdata_a1[167-144:156-144];
            ch03_8_next = sram_rdata_a1[155-144:144-144];
            ch03_7_next = sram_rdata_a2[191-144:180-144];
            ch03_6_next = sram_rdata_a2[179-144:168-144];
            ch03_5_next = sram_rdata_a3[191-144:180-144];
            ch03_4_next = sram_rdata_a3[179-144:168-144];
            ch03_3_next = sram_rdata_a2[167-144:156-144];
            ch03_2_next = sram_rdata_a2[155-144:144-144];
            ch03_1_next = sram_rdata_a3[167-144:156-144];
            ch03_0_next = sram_rdata_a3[155-144:144-144];
        end
        else if (wait_cnt == 4) begin
            ch04_15_next = sram_rdata_a0[191:180];
            ch04_14_next = sram_rdata_a0[179:168];
            ch04_13_next = sram_rdata_a1[191:180];
            ch04_12_next = sram_rdata_a1[179:168];
            ch04_11_next = sram_rdata_a0[167:156];
            ch04_10_next = sram_rdata_a0[155:144];
            ch04_9_next = sram_rdata_a1[167:156];
            ch04_8_next = sram_rdata_a1[155:144];
            ch04_7_next = sram_rdata_a2[191:180];
            ch04_6_next = sram_rdata_a2[179:168];
            ch04_5_next = sram_rdata_a3[191:180];
            ch04_4_next = sram_rdata_a3[179:168];
            ch04_3_next = sram_rdata_a2[167:156];
            ch04_2_next = sram_rdata_a2[155:144];
            ch04_1_next = sram_rdata_a3[167:156];
            ch04_0_next = sram_rdata_a3[155:144];

            ch05_15_next = sram_rdata_a0[191-48:180-48];
            ch05_14_next = sram_rdata_a0[179-48:168-48];
            ch05_13_next = sram_rdata_a1[191-48:180-48];
            ch05_12_next = sram_rdata_a1[179-48:168-48];
            ch05_11_next = sram_rdata_a0[167-48:156-48];
            ch05_10_next = sram_rdata_a0[155-48:144-48];
            ch05_9_next = sram_rdata_a1[167-48:156-48];
            ch05_8_next = sram_rdata_a1[155-48:144-48];
            ch05_7_next = sram_rdata_a2[191-48:180-48];
            ch05_6_next = sram_rdata_a2[179-48:168-48];
            ch05_5_next = sram_rdata_a3[191-48:180-48];
            ch05_4_next = sram_rdata_a3[179-48:168-48];
            ch05_3_next = sram_rdata_a2[167-48:156-48];
            ch05_2_next = sram_rdata_a2[155-48:144-48];
            ch05_1_next = sram_rdata_a3[167-48:156-48];
            ch05_0_next = sram_rdata_a3[155-48:144-48];

            ch06_15_next = sram_rdata_a0[191-96:180-96];
            ch06_14_next = sram_rdata_a0[179-96:168-96];
            ch06_13_next = sram_rdata_a1[191-96:180-96];
            ch06_12_next = sram_rdata_a1[179-96:168-96];
            ch06_11_next = sram_rdata_a0[167-96:156-96];
            ch06_10_next = sram_rdata_a0[155-96:144-96];
            ch06_9_next = sram_rdata_a1[167-96:156-96];
            ch06_8_next = sram_rdata_a1[155-96:144-96];
            ch06_7_next = sram_rdata_a2[191-96:180-96];
            ch06_6_next = sram_rdata_a2[179-96:168-96];
            ch06_5_next = sram_rdata_a3[191-96:180-96];
            ch06_4_next = sram_rdata_a3[179-96:168-96];
            ch06_3_next = sram_rdata_a2[167-96:156-96];
            ch06_2_next = sram_rdata_a2[155-96:144-96];
            ch06_1_next = sram_rdata_a3[167-96:156-96];
            ch06_0_next = sram_rdata_a3[155-96:144-96];

            ch07_15_next = sram_rdata_a0[191-144:180-144];
            ch07_14_next = sram_rdata_a0[179-144:168-144];
            ch07_13_next = sram_rdata_a1[191-144:180-144];
            ch07_12_next = sram_rdata_a1[179-144:168-144];
            ch07_11_next = sram_rdata_a0[167-144:156-144];
            ch07_10_next = sram_rdata_a0[155-144:144-144];
            ch07_9_next = sram_rdata_a1[167-144:156-144];
            ch07_8_next = sram_rdata_a1[155-144:144-144];
            ch07_7_next = sram_rdata_a2[191-144:180-144];
            ch07_6_next = sram_rdata_a2[179-144:168-144];
            ch07_5_next = sram_rdata_a3[191-144:180-144];
            ch07_4_next = sram_rdata_a3[179-144:168-144];
            ch07_3_next = sram_rdata_a2[167-144:156-144];
            ch07_2_next = sram_rdata_a2[155-144:144-144];
            ch07_1_next = sram_rdata_a3[167-144:156-144];
            ch07_0_next = sram_rdata_a3[155-144:144-144];
        end
        else if (wait_cnt == 5) begin
            ch08_15_next = sram_rdata_a0[191:180];
            ch08_14_next = sram_rdata_a0[179:168];
            ch08_13_next = sram_rdata_a1[191:180];
            ch08_12_next = sram_rdata_a1[179:168];
            ch08_11_next = sram_rdata_a0[167:156];
            ch08_10_next = sram_rdata_a0[155:144];
            ch08_9_next = sram_rdata_a1[167:156];
            ch08_8_next = sram_rdata_a1[155:144];
            ch08_7_next = sram_rdata_a2[191:180];
            ch08_6_next = sram_rdata_a2[179:168];
            ch08_5_next = sram_rdata_a3[191:180];
            ch08_4_next = sram_rdata_a3[179:168];
            ch08_3_next = sram_rdata_a2[167:156];
            ch08_2_next = sram_rdata_a2[155:144];
            ch08_1_next = sram_rdata_a3[167:156];
            ch08_0_next = sram_rdata_a3[155:144];

            ch09_15_next = sram_rdata_a0[191-48:180-48];
            ch09_14_next = sram_rdata_a0[179-48:168-48];
            ch09_13_next = sram_rdata_a1[191-48:180-48];
            ch09_12_next = sram_rdata_a1[179-48:168-48];
            ch09_11_next = sram_rdata_a0[167-48:156-48];
            ch09_10_next = sram_rdata_a0[155-48:144-48];
            ch09_9_next = sram_rdata_a1[167-48:156-48];
            ch09_8_next = sram_rdata_a1[155-48:144-48];
            ch09_7_next = sram_rdata_a2[191-48:180-48];
            ch09_6_next = sram_rdata_a2[179-48:168-48];
            ch09_5_next = sram_rdata_a3[191-48:180-48];
            ch09_4_next = sram_rdata_a3[179-48:168-48];
            ch09_3_next = sram_rdata_a2[167-48:156-48];
            ch09_2_next = sram_rdata_a2[155-48:144-48];
            ch09_1_next = sram_rdata_a3[167-48:156-48];
            ch09_0_next = sram_rdata_a3[155-48:144-48];

            ch10_15_next = sram_rdata_a0[191-96:180-96];
            ch10_14_next = sram_rdata_a0[179-96:168-96];
            ch10_13_next = sram_rdata_a1[191-96:180-96];
            ch10_12_next = sram_rdata_a1[179-96:168-96];
            ch10_11_next = sram_rdata_a0[167-96:156-96];
            ch10_10_next = sram_rdata_a0[155-96:144-96];
            ch10_9_next = sram_rdata_a1[167-96:156-96];
            ch10_8_next = sram_rdata_a1[155-96:144-96];
            ch10_7_next = sram_rdata_a2[191-96:180-96];
            ch10_6_next = sram_rdata_a2[179-96:168-96];
            ch10_5_next = sram_rdata_a3[191-96:180-96];
            ch10_4_next = sram_rdata_a3[179-96:168-96];
            ch10_3_next = sram_rdata_a2[167-96:156-96];
            ch10_2_next = sram_rdata_a2[155-96:144-96];
            ch10_1_next = sram_rdata_a3[167-96:156-96];
            ch10_0_next = sram_rdata_a3[155-96:144-96];

            ch11_15_next = sram_rdata_a0[191-144:180-144];
            ch11_14_next = sram_rdata_a0[179-144:168-144];
            ch11_13_next = sram_rdata_a1[191-144:180-144];
            ch11_12_next = sram_rdata_a1[179-144:168-144];
            ch11_11_next = sram_rdata_a0[167-144:156-144];
            ch11_10_next = sram_rdata_a0[155-144:144-144];
            ch11_9_next = sram_rdata_a1[167-144:156-144];
            ch11_8_next = sram_rdata_a1[155-144:144-144];
            ch11_7_next = sram_rdata_a2[191-144:180-144];
            ch11_6_next = sram_rdata_a2[179-144:168-144];
            ch11_5_next = sram_rdata_a3[191-144:180-144];
            ch11_4_next = sram_rdata_a3[179-144:168-144];
            ch11_3_next = sram_rdata_a2[167-144:156-144];
            ch11_2_next = sram_rdata_a2[155-144:144-144];
            ch11_1_next = sram_rdata_a3[167-144:156-144];
            ch11_0_next = sram_rdata_a3[155-144:144-144];
        end
    end
    else if (input_cnt == 1 || input_cnt == 3 || input_cnt == 9 || input_cnt == 11) begin
        if (wait_cnt == 3) begin
            ch00_15_next = sram_rdata_a1[191:180];
            ch00_14_next = sram_rdata_a1[179:168];
            ch00_13_next = sram_rdata_a0[191:180];
            ch00_12_next = sram_rdata_a0[179:168];
            ch00_11_next = sram_rdata_a1[167:156];
            ch00_10_next = sram_rdata_a1[155:144];
            ch00_9_next = sram_rdata_a0[167:156];
            ch00_8_next = sram_rdata_a0[155:144];
            ch00_7_next = sram_rdata_a3[191:180];
            ch00_6_next = sram_rdata_a3[179:168];
            ch00_5_next = sram_rdata_a2[191:180];
            ch00_4_next = sram_rdata_a2[179:168];
            ch00_3_next = sram_rdata_a3[167:156];
            ch00_2_next = sram_rdata_a3[155:144];
            ch00_1_next = sram_rdata_a2[167:156];
            ch00_0_next = sram_rdata_a2[155:144];

            ch01_15_next = sram_rdata_a1[191-48:180-48];
            ch01_14_next = sram_rdata_a1[179-48:168-48];
            ch01_13_next = sram_rdata_a0[191-48:180-48];
            ch01_12_next = sram_rdata_a0[179-48:168-48];
            ch01_11_next = sram_rdata_a1[167-48:156-48];
            ch01_10_next = sram_rdata_a1[155-48:144-48];
            ch01_9_next = sram_rdata_a0[167-48:156-48];
            ch01_8_next = sram_rdata_a0[155-48:144-48];
            ch01_7_next = sram_rdata_a3[191-48:180-48];
            ch01_6_next = sram_rdata_a3[179-48:168-48];
            ch01_5_next = sram_rdata_a2[191-48:180-48];
            ch01_4_next = sram_rdata_a2[179-48:168-48];
            ch01_3_next = sram_rdata_a3[167-48:156-48];
            ch01_2_next = sram_rdata_a3[155-48:144-48];
            ch01_1_next = sram_rdata_a2[167-48:156-48];
            ch01_0_next = sram_rdata_a2[155-48:144-48];

            ch02_15_next = sram_rdata_a1[191-96:180-96];
            ch02_14_next = sram_rdata_a1[179-96:168-96];
            ch02_13_next = sram_rdata_a0[191-96:180-96];
            ch02_12_next = sram_rdata_a0[179-96:168-96];
            ch02_11_next = sram_rdata_a1[167-96:156-96];
            ch02_10_next = sram_rdata_a1[155-96:144-96];
            ch02_9_next = sram_rdata_a0[167-96:156-96];
            ch02_8_next = sram_rdata_a0[155-96:144-96];
            ch02_7_next = sram_rdata_a3[191-96:180-96];
            ch02_6_next = sram_rdata_a3[179-96:168-96];
            ch02_5_next = sram_rdata_a2[191-96:180-96];
            ch02_4_next = sram_rdata_a2[179-96:168-96];
            ch02_3_next = sram_rdata_a3[167-96:156-96];
            ch02_2_next = sram_rdata_a3[155-96:144-96];
            ch02_1_next = sram_rdata_a2[167-96:156-96];
            ch02_0_next = sram_rdata_a2[155-96:144-96];

            ch03_15_next = sram_rdata_a1[191-144:180-144];
            ch03_14_next = sram_rdata_a1[179-144:168-144];
            ch03_13_next = sram_rdata_a0[191-144:180-144];
            ch03_12_next = sram_rdata_a0[179-144:168-144];
            ch03_11_next = sram_rdata_a1[167-144:156-144];
            ch03_10_next = sram_rdata_a1[155-144:144-144];
            ch03_9_next = sram_rdata_a0[167-144:156-144];
            ch03_8_next = sram_rdata_a0[155-144:144-144];
            ch03_7_next = sram_rdata_a3[191-144:180-144];
            ch03_6_next = sram_rdata_a3[179-144:168-144];
            ch03_5_next = sram_rdata_a2[191-144:180-144];
            ch03_4_next = sram_rdata_a2[179-144:168-144];
            ch03_3_next = sram_rdata_a3[167-144:156-144];
            ch03_2_next = sram_rdata_a3[155-144:144-144];
            ch03_1_next = sram_rdata_a2[167-144:156-144];
            ch03_0_next = sram_rdata_a2[155-144:144-144];
        end
        else if (wait_cnt == 4) begin
            ch04_15_next = sram_rdata_a1[191:180];
            ch04_14_next = sram_rdata_a1[179:168];
            ch04_13_next = sram_rdata_a0[191:180];
            ch04_12_next = sram_rdata_a0[179:168];
            ch04_11_next = sram_rdata_a1[167:156];
            ch04_10_next = sram_rdata_a1[155:144];
            ch04_9_next = sram_rdata_a0[167:156];
            ch04_8_next = sram_rdata_a0[155:144];
            ch04_7_next = sram_rdata_a3[191:180];
            ch04_6_next = sram_rdata_a3[179:168];
            ch04_5_next = sram_rdata_a2[191:180];
            ch04_4_next = sram_rdata_a2[179:168];
            ch04_3_next = sram_rdata_a3[167:156];
            ch04_2_next = sram_rdata_a3[155:144];
            ch04_1_next = sram_rdata_a2[167:156];
            ch04_0_next = sram_rdata_a2[155:144];

            ch05_15_next = sram_rdata_a1[191-48:180-48];
            ch05_14_next = sram_rdata_a1[179-48:168-48];
            ch05_13_next = sram_rdata_a0[191-48:180-48];
            ch05_12_next = sram_rdata_a0[179-48:168-48];
            ch05_11_next = sram_rdata_a1[167-48:156-48];
            ch05_10_next = sram_rdata_a1[155-48:144-48];
            ch05_9_next = sram_rdata_a0[167-48:156-48];
            ch05_8_next = sram_rdata_a0[155-48:144-48];
            ch05_7_next = sram_rdata_a3[191-48:180-48];
            ch05_6_next = sram_rdata_a3[179-48:168-48];
            ch05_5_next = sram_rdata_a2[191-48:180-48];
            ch05_4_next = sram_rdata_a2[179-48:168-48];
            ch05_3_next = sram_rdata_a3[167-48:156-48];
            ch05_2_next = sram_rdata_a3[155-48:144-48];
            ch05_1_next = sram_rdata_a2[167-48:156-48];
            ch05_0_next = sram_rdata_a2[155-48:144-48];

            ch06_15_next = sram_rdata_a1[191-96:180-96];
            ch06_14_next = sram_rdata_a1[179-96:168-96];
            ch06_13_next = sram_rdata_a0[191-96:180-96];
            ch06_12_next = sram_rdata_a0[179-96:168-96];
            ch06_11_next = sram_rdata_a1[167-96:156-96];
            ch06_10_next = sram_rdata_a1[155-96:144-96];
            ch06_9_next = sram_rdata_a0[167-96:156-96];
            ch06_8_next = sram_rdata_a0[155-96:144-96];
            ch06_7_next = sram_rdata_a3[191-96:180-96];
            ch06_6_next = sram_rdata_a3[179-96:168-96];
            ch06_5_next = sram_rdata_a2[191-96:180-96];
            ch06_4_next = sram_rdata_a2[179-96:168-96];
            ch06_3_next = sram_rdata_a3[167-96:156-96];
            ch06_2_next = sram_rdata_a3[155-96:144-96];
            ch06_1_next = sram_rdata_a2[167-96:156-96];
            ch06_0_next = sram_rdata_a2[155-96:144-96];

            ch07_15_next = sram_rdata_a1[191-144:180-144];
            ch07_14_next = sram_rdata_a1[179-144:168-144];
            ch07_13_next = sram_rdata_a0[191-144:180-144];
            ch07_12_next = sram_rdata_a0[179-144:168-144];
            ch07_11_next = sram_rdata_a1[167-144:156-144];
            ch07_10_next = sram_rdata_a1[155-144:144-144];
            ch07_9_next = sram_rdata_a0[167-144:156-144];
            ch07_8_next = sram_rdata_a0[155-144:144-144];
            ch07_7_next = sram_rdata_a3[191-144:180-144];
            ch07_6_next = sram_rdata_a3[179-144:168-144];
            ch07_5_next = sram_rdata_a2[191-144:180-144];
            ch07_4_next = sram_rdata_a2[179-144:168-144];
            ch07_3_next = sram_rdata_a3[167-144:156-144];
            ch07_2_next = sram_rdata_a3[155-144:144-144];
            ch07_1_next = sram_rdata_a2[167-144:156-144];
            ch07_0_next = sram_rdata_a2[155-144:144-144];
        end
        else if (wait_cnt == 5) begin
            ch08_15_next = sram_rdata_a1[191:180];
            ch08_14_next = sram_rdata_a1[179:168];
            ch08_13_next = sram_rdata_a0[191:180];
            ch08_12_next = sram_rdata_a0[179:168];
            ch08_11_next = sram_rdata_a1[167:156];
            ch08_10_next = sram_rdata_a1[155:144];
            ch08_9_next = sram_rdata_a0[167:156];
            ch08_8_next = sram_rdata_a0[155:144];
            ch08_7_next = sram_rdata_a3[191:180];
            ch08_6_next = sram_rdata_a3[179:168];
            ch08_5_next = sram_rdata_a2[191:180];
            ch08_4_next = sram_rdata_a2[179:168];
            ch08_3_next = sram_rdata_a3[167:156];
            ch08_2_next = sram_rdata_a3[155:144];
            ch08_1_next = sram_rdata_a2[167:156];
            ch08_0_next = sram_rdata_a2[155:144];

            ch09_15_next = sram_rdata_a1[191-48:180-48];
            ch09_14_next = sram_rdata_a1[179-48:168-48];
            ch09_13_next = sram_rdata_a0[191-48:180-48];
            ch09_12_next = sram_rdata_a0[179-48:168-48];
            ch09_11_next = sram_rdata_a1[167-48:156-48];
            ch09_10_next = sram_rdata_a1[155-48:144-48];
            ch09_9_next = sram_rdata_a0[167-48:156-48];
            ch09_8_next = sram_rdata_a0[155-48:144-48];
            ch09_7_next = sram_rdata_a3[191-48:180-48];
            ch09_6_next = sram_rdata_a3[179-48:168-48];
            ch09_5_next = sram_rdata_a2[191-48:180-48];
            ch09_4_next = sram_rdata_a2[179-48:168-48];
            ch09_3_next = sram_rdata_a3[167-48:156-48];
            ch09_2_next = sram_rdata_a3[155-48:144-48];
            ch09_1_next = sram_rdata_a2[167-48:156-48];
            ch09_0_next = sram_rdata_a2[155-48:144-48];

            ch10_15_next = sram_rdata_a1[191-96:180-96];
            ch10_14_next = sram_rdata_a1[179-96:168-96];
            ch10_13_next = sram_rdata_a0[191-96:180-96];
            ch10_12_next = sram_rdata_a0[179-96:168-96];
            ch10_11_next = sram_rdata_a1[167-96:156-96];
            ch10_10_next = sram_rdata_a1[155-96:144-96];
            ch10_9_next = sram_rdata_a0[167-96:156-96];
            ch10_8_next = sram_rdata_a0[155-96:144-96];
            ch10_7_next = sram_rdata_a3[191-96:180-96];
            ch10_6_next = sram_rdata_a3[179-96:168-96];
            ch10_5_next = sram_rdata_a2[191-96:180-96];
            ch10_4_next = sram_rdata_a2[179-96:168-96];
            ch10_3_next = sram_rdata_a3[167-96:156-96];
            ch10_2_next = sram_rdata_a3[155-96:144-96];
            ch10_1_next = sram_rdata_a2[167-96:156-96];
            ch10_0_next = sram_rdata_a2[155-96:144-96];

            ch11_15_next = sram_rdata_a1[191-144:180-144];
            ch11_14_next = sram_rdata_a1[179-144:168-144];
            ch11_13_next = sram_rdata_a0[191-144:180-144];
            ch11_12_next = sram_rdata_a0[179-144:168-144];
            ch11_11_next = sram_rdata_a1[167-144:156-144];
            ch11_10_next = sram_rdata_a1[155-144:144-144];
            ch11_9_next = sram_rdata_a0[167-144:156-144];
            ch11_8_next = sram_rdata_a0[155-144:144-144];
            ch11_7_next = sram_rdata_a3[191-144:180-144];
            ch11_6_next = sram_rdata_a3[179-144:168-144];
            ch11_5_next = sram_rdata_a2[191-144:180-144];
            ch11_4_next = sram_rdata_a2[179-144:168-144];
            ch11_3_next = sram_rdata_a3[167-144:156-144];
            ch11_2_next = sram_rdata_a3[155-144:144-144];
            ch11_1_next = sram_rdata_a2[167-144:156-144];
            ch11_0_next = sram_rdata_a2[155-144:144-144];
        end
    end
    else if (input_cnt == 4 || input_cnt == 6 || input_cnt == 12 || input_cnt == 14) begin
        if (wait_cnt == 3) begin
            ch00_15_next = sram_rdata_a2[191:180];
            ch00_14_next = sram_rdata_a2[179:168];
            ch00_13_next = sram_rdata_a3[191:180];
            ch00_12_next = sram_rdata_a3[179:168];
            ch00_11_next = sram_rdata_a2[167:156];
            ch00_10_next = sram_rdata_a2[155:144];
            ch00_9_next = sram_rdata_a3[167:156];
            ch00_8_next = sram_rdata_a3[155:144];
            ch00_7_next = sram_rdata_a0[191:180];
            ch00_6_next = sram_rdata_a0[179:168];
            ch00_5_next = sram_rdata_a1[191:180];
            ch00_4_next = sram_rdata_a1[179:168];
            ch00_3_next = sram_rdata_a0[167:156];
            ch00_2_next = sram_rdata_a0[155:144];
            ch00_1_next = sram_rdata_a1[167:156];
            ch00_0_next = sram_rdata_a1[155:144];

            ch01_15_next = sram_rdata_a2[191-48:180-48];
            ch01_14_next = sram_rdata_a2[179-48:168-48];
            ch01_13_next = sram_rdata_a3[191-48:180-48];
            ch01_12_next = sram_rdata_a3[179-48:168-48];
            ch01_11_next = sram_rdata_a2[167-48:156-48];
            ch01_10_next = sram_rdata_a2[155-48:144-48];
            ch01_9_next = sram_rdata_a3[167-48:156-48];
            ch01_8_next = sram_rdata_a3[155-48:144-48];
            ch01_7_next = sram_rdata_a0[191-48:180-48];
            ch01_6_next = sram_rdata_a0[179-48:168-48];
            ch01_5_next = sram_rdata_a1[191-48:180-48];
            ch01_4_next = sram_rdata_a1[179-48:168-48];
            ch01_3_next = sram_rdata_a0[167-48:156-48];
            ch01_2_next = sram_rdata_a0[155-48:144-48];
            ch01_1_next = sram_rdata_a1[167-48:156-48];
            ch01_0_next = sram_rdata_a1[155-48:144-48];

            ch02_15_next = sram_rdata_a2[191-96:180-96];
            ch02_14_next = sram_rdata_a2[179-96:168-96];
            ch02_13_next = sram_rdata_a3[191-96:180-96];
            ch02_12_next = sram_rdata_a3[179-96:168-96];
            ch02_11_next = sram_rdata_a2[167-96:156-96];
            ch02_10_next = sram_rdata_a2[155-96:144-96];
            ch02_9_next = sram_rdata_a3[167-96:156-96];
            ch02_8_next = sram_rdata_a3[155-96:144-96];
            ch02_7_next = sram_rdata_a0[191-96:180-96];
            ch02_6_next = sram_rdata_a0[179-96:168-96];
            ch02_5_next = sram_rdata_a1[191-96:180-96];
            ch02_4_next = sram_rdata_a1[179-96:168-96];
            ch02_3_next = sram_rdata_a0[167-96:156-96];
            ch02_2_next = sram_rdata_a0[155-96:144-96];
            ch02_1_next = sram_rdata_a1[167-96:156-96];
            ch02_0_next = sram_rdata_a1[155-96:144-96];

            ch03_15_next = sram_rdata_a2[191-144:180-144];
            ch03_14_next = sram_rdata_a2[179-144:168-144];
            ch03_13_next = sram_rdata_a3[191-144:180-144];
            ch03_12_next = sram_rdata_a3[179-144:168-144];
            ch03_11_next = sram_rdata_a2[167-144:156-144];
            ch03_10_next = sram_rdata_a2[155-144:144-144];
            ch03_9_next = sram_rdata_a3[167-144:156-144];
            ch03_8_next = sram_rdata_a3[155-144:144-144];
            ch03_7_next = sram_rdata_a0[191-144:180-144];
            ch03_6_next = sram_rdata_a0[179-144:168-144];
            ch03_5_next = sram_rdata_a1[191-144:180-144];
            ch03_4_next = sram_rdata_a1[179-144:168-144];
            ch03_3_next = sram_rdata_a0[167-144:156-144];
            ch03_2_next = sram_rdata_a0[155-144:144-144];
            ch03_1_next = sram_rdata_a1[167-144:156-144];
            ch03_0_next = sram_rdata_a1[155-144:144-144];
        end
        else if (wait_cnt == 4) begin
            ch04_15_next = sram_rdata_a2[191:180];
            ch04_14_next = sram_rdata_a2[179:168];
            ch04_13_next = sram_rdata_a3[191:180];
            ch04_12_next = sram_rdata_a3[179:168];
            ch04_11_next = sram_rdata_a2[167:156];
            ch04_10_next = sram_rdata_a2[155:144];
            ch04_9_next = sram_rdata_a3[167:156];
            ch04_8_next = sram_rdata_a3[155:144];
            ch04_7_next = sram_rdata_a0[191:180];
            ch04_6_next = sram_rdata_a0[179:168];
            ch04_5_next = sram_rdata_a1[191:180];
            ch04_4_next = sram_rdata_a1[179:168];
            ch04_3_next = sram_rdata_a0[167:156];
            ch04_2_next = sram_rdata_a0[155:144];
            ch04_1_next = sram_rdata_a1[167:156];
            ch04_0_next = sram_rdata_a1[155:144];

            ch05_15_next = sram_rdata_a2[191-48:180-48];
            ch05_14_next = sram_rdata_a2[179-48:168-48];
            ch05_13_next = sram_rdata_a3[191-48:180-48];
            ch05_12_next = sram_rdata_a3[179-48:168-48];
            ch05_11_next = sram_rdata_a2[167-48:156-48];
            ch05_10_next = sram_rdata_a2[155-48:144-48];
            ch05_9_next = sram_rdata_a3[167-48:156-48];
            ch05_8_next = sram_rdata_a3[155-48:144-48];
            ch05_7_next = sram_rdata_a0[191-48:180-48];
            ch05_6_next = sram_rdata_a0[179-48:168-48];
            ch05_5_next = sram_rdata_a1[191-48:180-48];
            ch05_4_next = sram_rdata_a1[179-48:168-48];
            ch05_3_next = sram_rdata_a0[167-48:156-48];
            ch05_2_next = sram_rdata_a0[155-48:144-48];
            ch05_1_next = sram_rdata_a1[167-48:156-48];
            ch05_0_next = sram_rdata_a1[155-48:144-48];

            ch06_15_next = sram_rdata_a2[191-96:180-96];
            ch06_14_next = sram_rdata_a2[179-96:168-96];
            ch06_13_next = sram_rdata_a3[191-96:180-96];
            ch06_12_next = sram_rdata_a3[179-96:168-96];
            ch06_11_next = sram_rdata_a2[167-96:156-96];
            ch06_10_next = sram_rdata_a2[155-96:144-96];
            ch06_9_next = sram_rdata_a3[167-96:156-96];
            ch06_8_next = sram_rdata_a3[155-96:144-96];
            ch06_7_next = sram_rdata_a0[191-96:180-96];
            ch06_6_next = sram_rdata_a0[179-96:168-96];
            ch06_5_next = sram_rdata_a1[191-96:180-96];
            ch06_4_next = sram_rdata_a1[179-96:168-96];
            ch06_3_next = sram_rdata_a0[167-96:156-96];
            ch06_2_next = sram_rdata_a0[155-96:144-96];
            ch06_1_next = sram_rdata_a1[167-96:156-96];
            ch06_0_next = sram_rdata_a1[155-96:144-96];

            ch07_15_next = sram_rdata_a2[191-144:180-144];
            ch07_14_next = sram_rdata_a2[179-144:168-144];
            ch07_13_next = sram_rdata_a3[191-144:180-144];
            ch07_12_next = sram_rdata_a3[179-144:168-144];
            ch07_11_next = sram_rdata_a2[167-144:156-144];
            ch07_10_next = sram_rdata_a2[155-144:144-144];
            ch07_9_next = sram_rdata_a3[167-144:156-144];
            ch07_8_next = sram_rdata_a3[155-144:144-144];
            ch07_7_next = sram_rdata_a0[191-144:180-144];
            ch07_6_next = sram_rdata_a0[179-144:168-144];
            ch07_5_next = sram_rdata_a1[191-144:180-144];
            ch07_4_next = sram_rdata_a1[179-144:168-144];
            ch07_3_next = sram_rdata_a0[167-144:156-144];
            ch07_2_next = sram_rdata_a0[155-144:144-144];
            ch07_1_next = sram_rdata_a1[167-144:156-144];
            ch07_0_next = sram_rdata_a1[155-144:144-144];
        end
        else if (wait_cnt == 5) begin
            ch08_15_next = sram_rdata_a2[191:180];
            ch08_14_next = sram_rdata_a2[179:168];
            ch08_13_next = sram_rdata_a3[191:180];
            ch08_12_next = sram_rdata_a3[179:168];
            ch08_11_next = sram_rdata_a2[167:156];
            ch08_10_next = sram_rdata_a2[155:144];
            ch08_9_next = sram_rdata_a3[167:156];
            ch08_8_next = sram_rdata_a3[155:144];
            ch08_7_next = sram_rdata_a0[191:180];
            ch08_6_next = sram_rdata_a0[179:168];
            ch08_5_next = sram_rdata_a1[191:180];
            ch08_4_next = sram_rdata_a1[179:168];
            ch08_3_next = sram_rdata_a0[167:156];
            ch08_2_next = sram_rdata_a0[155:144];
            ch08_1_next = sram_rdata_a1[167:156];
            ch08_0_next = sram_rdata_a1[155:144];

            ch09_15_next = sram_rdata_a2[191-48:180-48];
            ch09_14_next = sram_rdata_a2[179-48:168-48];
            ch09_13_next = sram_rdata_a3[191-48:180-48];
            ch09_12_next = sram_rdata_a3[179-48:168-48];
            ch09_11_next = sram_rdata_a2[167-48:156-48];
            ch09_10_next = sram_rdata_a2[155-48:144-48];
            ch09_9_next = sram_rdata_a3[167-48:156-48];
            ch09_8_next = sram_rdata_a3[155-48:144-48];
            ch09_7_next = sram_rdata_a0[191-48:180-48];
            ch09_6_next = sram_rdata_a0[179-48:168-48];
            ch09_5_next = sram_rdata_a1[191-48:180-48];
            ch09_4_next = sram_rdata_a1[179-48:168-48];
            ch09_3_next = sram_rdata_a0[167-48:156-48];
            ch09_2_next = sram_rdata_a0[155-48:144-48];
            ch09_1_next = sram_rdata_a1[167-48:156-48];
            ch09_0_next = sram_rdata_a1[155-48:144-48];

            ch10_15_next = sram_rdata_a2[191-96:180-96];
            ch10_14_next = sram_rdata_a2[179-96:168-96];
            ch10_13_next = sram_rdata_a3[191-96:180-96];
            ch10_12_next = sram_rdata_a3[179-96:168-96];
            ch10_11_next = sram_rdata_a2[167-96:156-96];
            ch10_10_next = sram_rdata_a2[155-96:144-96];
            ch10_9_next = sram_rdata_a3[167-96:156-96];
            ch10_8_next = sram_rdata_a3[155-96:144-96];
            ch10_7_next = sram_rdata_a0[191-96:180-96];
            ch10_6_next = sram_rdata_a0[179-96:168-96];
            ch10_5_next = sram_rdata_a1[191-96:180-96];
            ch10_4_next = sram_rdata_a1[179-96:168-96];
            ch10_3_next = sram_rdata_a0[167-96:156-96];
            ch10_2_next = sram_rdata_a0[155-96:144-96];
            ch10_1_next = sram_rdata_a1[167-96:156-96];
            ch10_0_next = sram_rdata_a1[155-96:144-96];

            ch11_15_next = sram_rdata_a2[191-144:180-144];
            ch11_14_next = sram_rdata_a2[179-144:168-144];
            ch11_13_next = sram_rdata_a3[191-144:180-144];
            ch11_12_next = sram_rdata_a3[179-144:168-144];
            ch11_11_next = sram_rdata_a2[167-144:156-144];
            ch11_10_next = sram_rdata_a2[155-144:144-144];
            ch11_9_next = sram_rdata_a3[167-144:156-144];
            ch11_8_next = sram_rdata_a3[155-144:144-144];
            ch11_7_next = sram_rdata_a0[191-144:180-144];
            ch11_6_next = sram_rdata_a0[179-144:168-144];
            ch11_5_next = sram_rdata_a1[191-144:180-144];
            ch11_4_next = sram_rdata_a1[179-144:168-144];
            ch11_3_next = sram_rdata_a0[167-144:156-144];
            ch11_2_next = sram_rdata_a0[155-144:144-144];
            ch11_1_next = sram_rdata_a1[167-144:156-144];
            ch11_0_next = sram_rdata_a1[155-144:144-144];
        end
    end
    else if (input_cnt == 5 || input_cnt == 7 || input_cnt == 13 || input_cnt == 15) begin
        if (wait_cnt == 3) begin
            ch00_15_next = sram_rdata_a3[191:180];
            ch00_14_next = sram_rdata_a3[179:168];
            ch00_13_next = sram_rdata_a2[191:180];
            ch00_12_next = sram_rdata_a2[179:168];
            ch00_11_next = sram_rdata_a3[167:156];
            ch00_10_next = sram_rdata_a3[155:144];
            ch00_9_next = sram_rdata_a2[167:156];
            ch00_8_next = sram_rdata_a2[155:144];
            ch00_7_next = sram_rdata_a1[191:180];
            ch00_6_next = sram_rdata_a1[179:168];
            ch00_5_next = sram_rdata_a0[191:180];
            ch00_4_next = sram_rdata_a0[179:168];
            ch00_3_next = sram_rdata_a1[167:156];
            ch00_2_next = sram_rdata_a1[155:144];
            ch00_1_next = sram_rdata_a0[167:156];
            ch00_0_next = sram_rdata_a0[155:144];

            ch01_15_next = sram_rdata_a3[191-48:180-48];
            ch01_14_next = sram_rdata_a3[179-48:168-48];
            ch01_13_next = sram_rdata_a2[191-48:180-48];
            ch01_12_next = sram_rdata_a2[179-48:168-48];
            ch01_11_next = sram_rdata_a3[167-48:156-48];
            ch01_10_next = sram_rdata_a3[155-48:144-48];
            ch01_9_next = sram_rdata_a2[167-48:156-48];
            ch01_8_next = sram_rdata_a2[155-48:144-48];
            ch01_7_next = sram_rdata_a1[191-48:180-48];
            ch01_6_next = sram_rdata_a1[179-48:168-48];
            ch01_5_next = sram_rdata_a0[191-48:180-48];
            ch01_4_next = sram_rdata_a0[179-48:168-48];
            ch01_3_next = sram_rdata_a1[167-48:156-48];
            ch01_2_next = sram_rdata_a1[155-48:144-48];
            ch01_1_next = sram_rdata_a0[167-48:156-48];
            ch01_0_next = sram_rdata_a0[155-48:144-48];

            ch02_15_next = sram_rdata_a3[191-96:180-96];
            ch02_14_next = sram_rdata_a3[179-96:168-96];
            ch02_13_next = sram_rdata_a2[191-96:180-96];
            ch02_12_next = sram_rdata_a2[179-96:168-96];
            ch02_11_next = sram_rdata_a3[167-96:156-96];
            ch02_10_next = sram_rdata_a3[155-96:144-96];
            ch02_9_next = sram_rdata_a2[167-96:156-96];
            ch02_8_next = sram_rdata_a2[155-96:144-96];
            ch02_7_next = sram_rdata_a1[191-96:180-96];
            ch02_6_next = sram_rdata_a1[179-96:168-96];
            ch02_5_next = sram_rdata_a0[191-96:180-96];
            ch02_4_next = sram_rdata_a0[179-96:168-96];
            ch02_3_next = sram_rdata_a1[167-96:156-96];
            ch02_2_next = sram_rdata_a1[155-96:144-96];
            ch02_1_next = sram_rdata_a0[167-96:156-96];
            ch02_0_next = sram_rdata_a0[155-96:144-96];

            ch03_15_next = sram_rdata_a3[191-144:180-144];
            ch03_14_next = sram_rdata_a3[179-144:168-144];
            ch03_13_next = sram_rdata_a2[191-144:180-144];
            ch03_12_next = sram_rdata_a2[179-144:168-144];
            ch03_11_next = sram_rdata_a3[167-144:156-144];
            ch03_10_next = sram_rdata_a3[155-144:144-144];
            ch03_9_next = sram_rdata_a2[167-144:156-144];
            ch03_8_next = sram_rdata_a2[155-144:144-144];
            ch03_7_next = sram_rdata_a1[191-144:180-144];
            ch03_6_next = sram_rdata_a1[179-144:168-144];
            ch03_5_next = sram_rdata_a0[191-144:180-144];
            ch03_4_next = sram_rdata_a0[179-144:168-144];
            ch03_3_next = sram_rdata_a1[167-144:156-144];
            ch03_2_next = sram_rdata_a1[155-144:144-144];
            ch03_1_next = sram_rdata_a0[167-144:156-144];
            ch03_0_next = sram_rdata_a0[155-144:144-144];
        end
        else if (wait_cnt == 4) begin
            ch04_15_next = sram_rdata_a3[191:180];
            ch04_14_next = sram_rdata_a3[179:168];
            ch04_13_next = sram_rdata_a2[191:180];
            ch04_12_next = sram_rdata_a2[179:168];
            ch04_11_next = sram_rdata_a3[167:156];
            ch04_10_next = sram_rdata_a3[155:144];
            ch04_9_next = sram_rdata_a2[167:156];
            ch04_8_next = sram_rdata_a2[155:144];
            ch04_7_next = sram_rdata_a1[191:180];
            ch04_6_next = sram_rdata_a1[179:168];
            ch04_5_next = sram_rdata_a0[191:180];
            ch04_4_next = sram_rdata_a0[179:168];
            ch04_3_next = sram_rdata_a1[167:156];
            ch04_2_next = sram_rdata_a1[155:144];
            ch04_1_next = sram_rdata_a0[167:156];
            ch04_0_next = sram_rdata_a0[155:144];

            ch05_15_next = sram_rdata_a3[191-48:180-48];
            ch05_14_next = sram_rdata_a3[179-48:168-48];
            ch05_13_next = sram_rdata_a2[191-48:180-48];
            ch05_12_next = sram_rdata_a2[179-48:168-48];
            ch05_11_next = sram_rdata_a3[167-48:156-48];
            ch05_10_next = sram_rdata_a3[155-48:144-48];
            ch05_9_next = sram_rdata_a2[167-48:156-48];
            ch05_8_next = sram_rdata_a2[155-48:144-48];
            ch05_7_next = sram_rdata_a1[191-48:180-48];
            ch05_6_next = sram_rdata_a1[179-48:168-48];
            ch05_5_next = sram_rdata_a0[191-48:180-48];
            ch05_4_next = sram_rdata_a0[179-48:168-48];
            ch05_3_next = sram_rdata_a1[167-48:156-48];
            ch05_2_next = sram_rdata_a1[155-48:144-48];
            ch05_1_next = sram_rdata_a0[167-48:156-48];
            ch05_0_next = sram_rdata_a0[155-48:144-48];

            ch06_15_next = sram_rdata_a3[191-96:180-96];
            ch06_14_next = sram_rdata_a3[179-96:168-96];
            ch06_13_next = sram_rdata_a2[191-96:180-96];
            ch06_12_next = sram_rdata_a2[179-96:168-96];
            ch06_11_next = sram_rdata_a3[167-96:156-96];
            ch06_10_next = sram_rdata_a3[155-96:144-96];
            ch06_9_next = sram_rdata_a2[167-96:156-96];
            ch06_8_next = sram_rdata_a2[155-96:144-96];
            ch06_7_next = sram_rdata_a1[191-96:180-96];
            ch06_6_next = sram_rdata_a1[179-96:168-96];
            ch06_5_next = sram_rdata_a0[191-96:180-96];
            ch06_4_next = sram_rdata_a0[179-96:168-96];
            ch06_3_next = sram_rdata_a1[167-96:156-96];
            ch06_2_next = sram_rdata_a1[155-96:144-96];
            ch06_1_next = sram_rdata_a0[167-96:156-96];
            ch06_0_next = sram_rdata_a0[155-96:144-96];

            ch07_15_next = sram_rdata_a3[191-144:180-144];
            ch07_14_next = sram_rdata_a3[179-144:168-144];
            ch07_13_next = sram_rdata_a2[191-144:180-144];
            ch07_12_next = sram_rdata_a2[179-144:168-144];
            ch07_11_next = sram_rdata_a3[167-144:156-144];
            ch07_10_next = sram_rdata_a3[155-144:144-144];
            ch07_9_next = sram_rdata_a2[167-144:156-144];
            ch07_8_next = sram_rdata_a2[155-144:144-144];
            ch07_7_next = sram_rdata_a1[191-144:180-144];
            ch07_6_next = sram_rdata_a1[179-144:168-144];
            ch07_5_next = sram_rdata_a0[191-144:180-144];
            ch07_4_next = sram_rdata_a0[179-144:168-144];
            ch07_3_next = sram_rdata_a1[167-144:156-144];
            ch07_2_next = sram_rdata_a1[155-144:144-144];
            ch07_1_next = sram_rdata_a0[167-144:156-144];
            ch07_0_next = sram_rdata_a0[155-144:144-144];
        end
        else if (wait_cnt == 5) begin
            ch08_15_next = sram_rdata_a3[191:180];
            ch08_14_next = sram_rdata_a3[179:168];
            ch08_13_next = sram_rdata_a2[191:180];
            ch08_12_next = sram_rdata_a2[179:168];
            ch08_11_next = sram_rdata_a3[167:156];
            ch08_10_next = sram_rdata_a3[155:144];
            ch08_9_next = sram_rdata_a2[167:156];
            ch08_8_next = sram_rdata_a2[155:144];
            ch08_7_next = sram_rdata_a1[191:180];
            ch08_6_next = sram_rdata_a1[179:168];
            ch08_5_next = sram_rdata_a0[191:180];
            ch08_4_next = sram_rdata_a0[179:168];
            ch08_3_next = sram_rdata_a1[167:156];
            ch08_2_next = sram_rdata_a1[155:144];
            ch08_1_next = sram_rdata_a0[167:156];
            ch08_0_next = sram_rdata_a0[155:144];

            ch09_15_next = sram_rdata_a3[191-48:180-48];
            ch09_14_next = sram_rdata_a3[179-48:168-48];
            ch09_13_next = sram_rdata_a2[191-48:180-48];
            ch09_12_next = sram_rdata_a2[179-48:168-48];
            ch09_11_next = sram_rdata_a3[167-48:156-48];
            ch09_10_next = sram_rdata_a3[155-48:144-48];
            ch09_9_next = sram_rdata_a2[167-48:156-48];
            ch09_8_next = sram_rdata_a2[155-48:144-48];
            ch09_7_next = sram_rdata_a1[191-48:180-48];
            ch09_6_next = sram_rdata_a1[179-48:168-48];
            ch09_5_next = sram_rdata_a0[191-48:180-48];
            ch09_4_next = sram_rdata_a0[179-48:168-48];
            ch09_3_next = sram_rdata_a1[167-48:156-48];
            ch09_2_next = sram_rdata_a1[155-48:144-48];
            ch09_1_next = sram_rdata_a0[167-48:156-48];
            ch09_0_next = sram_rdata_a0[155-48:144-48];

            ch10_15_next = sram_rdata_a3[191-96:180-96];
            ch10_14_next = sram_rdata_a3[179-96:168-96];
            ch10_13_next = sram_rdata_a2[191-96:180-96];
            ch10_12_next = sram_rdata_a2[179-96:168-96];
            ch10_11_next = sram_rdata_a3[167-96:156-96];
            ch10_10_next = sram_rdata_a3[155-96:144-96];
            ch10_9_next = sram_rdata_a2[167-96:156-96];
            ch10_8_next = sram_rdata_a2[155-96:144-96];
            ch10_7_next = sram_rdata_a1[191-96:180-96];
            ch10_6_next = sram_rdata_a1[179-96:168-96];
            ch10_5_next = sram_rdata_a0[191-96:180-96];
            ch10_4_next = sram_rdata_a0[179-96:168-96];
            ch10_3_next = sram_rdata_a1[167-96:156-96];
            ch10_2_next = sram_rdata_a1[155-96:144-96];
            ch10_1_next = sram_rdata_a0[167-96:156-96];
            ch10_0_next = sram_rdata_a0[155-96:144-96];

            ch11_15_next = sram_rdata_a3[191-144:180-144];
            ch11_14_next = sram_rdata_a3[179-144:168-144];
            ch11_13_next = sram_rdata_a2[191-144:180-144];
            ch11_12_next = sram_rdata_a2[179-144:168-144];
            ch11_11_next = sram_rdata_a3[167-144:156-144];
            ch11_10_next = sram_rdata_a3[155-144:144-144];
            ch11_9_next = sram_rdata_a2[167-144:156-144];
            ch11_8_next = sram_rdata_a2[155-144:144-144];
            ch11_7_next = sram_rdata_a1[191-144:180-144];
            ch11_6_next = sram_rdata_a1[179-144:168-144];
            ch11_5_next = sram_rdata_a0[191-144:180-144];
            ch11_4_next = sram_rdata_a0[179-144:168-144];
            ch11_3_next = sram_rdata_a1[167-144:156-144];
            ch11_2_next = sram_rdata_a1[155-144:144-144];
            ch11_1_next = sram_rdata_a0[167-144:156-144];
            ch11_0_next = sram_rdata_a0[155-144:144-144];
        end
    end
end


// conv
always @* begin
    origin_sum3 = ch00_15 * weight_ch00_2D[8] + ch00_14 * weight_ch00_2D[7] + ch00_13 * weight_ch00_2D[6]
                + ch00_11 * weight_ch00_2D[5] + ch00_10 * weight_ch00_2D[4] + ch00_9  * weight_ch00_2D[3]
                + ch00_7  * weight_ch00_2D[2] + ch00_6  * weight_ch00_2D[1] + ch00_5  * weight_ch00_2D[0]
                + ch01_15 * weight_ch01_2D[8] + ch01_14 * weight_ch01_2D[7] + ch01_13 * weight_ch01_2D[6]
                + ch01_11 * weight_ch01_2D[5] + ch01_10 * weight_ch01_2D[4] + ch01_9  * weight_ch01_2D[3]
                + ch01_7  * weight_ch01_2D[2] + ch01_6  * weight_ch01_2D[1] + ch01_5  * weight_ch01_2D[0]
                + ch02_15 * weight_ch02_2D[8] + ch02_14 * weight_ch02_2D[7] + ch02_13 * weight_ch02_2D[6]
                + ch02_11 * weight_ch02_2D[5] + ch02_10 * weight_ch02_2D[4] + ch02_9  * weight_ch02_2D[3]
                + ch02_7  * weight_ch02_2D[2] + ch02_6  * weight_ch02_2D[1] + ch02_5  * weight_ch02_2D[0]
                + ch03_15 * weight_ch03_2D[8] + ch03_14 * weight_ch03_2D[7] + ch03_13 * weight_ch03_2D[6]
                + ch03_11 * weight_ch03_2D[5] + ch03_10 * weight_ch03_2D[4] + ch03_9  * weight_ch03_2D[3]
                + ch03_7  * weight_ch03_2D[2] + ch03_6  * weight_ch03_2D[1] + ch03_5  * weight_ch03_2D[0]
                + ch04_15 * weight_ch04_2D[8] + ch04_14 * weight_ch04_2D[7] + ch04_13 * weight_ch04_2D[6]
                + ch04_11 * weight_ch04_2D[5] + ch04_10 * weight_ch04_2D[4] + ch04_9  * weight_ch04_2D[3]
                + ch04_7  * weight_ch04_2D[2] + ch04_6  * weight_ch04_2D[1] + ch04_5  * weight_ch04_2D[0]
                + ch05_15 * weight_ch05_2D[8] + ch05_14 * weight_ch05_2D[7] + ch05_13 * weight_ch05_2D[6]
                + ch05_11 * weight_ch05_2D[5] + ch05_10 * weight_ch05_2D[4] + ch05_9  * weight_ch05_2D[3]
                + ch05_7  * weight_ch05_2D[2] + ch05_6  * weight_ch05_2D[1] + ch05_5  * weight_ch05_2D[0]
                + ch06_15 * weight_ch06_2D[8] + ch06_14 * weight_ch06_2D[7] + ch06_13 * weight_ch06_2D[6]
                + ch06_11 * weight_ch06_2D[5] + ch06_10 * weight_ch06_2D[4] + ch06_9  * weight_ch06_2D[3]
                + ch06_7  * weight_ch06_2D[2] + ch06_6  * weight_ch06_2D[1] + ch06_5  * weight_ch06_2D[0]
                + ch07_15 * weight_ch07_2D[8] + ch07_14 * weight_ch07_2D[7] + ch07_13 * weight_ch07_2D[6]
                + ch07_11 * weight_ch07_2D[5] + ch07_10 * weight_ch07_2D[4] + ch07_9  * weight_ch07_2D[3]
                + ch07_7  * weight_ch07_2D[2] + ch07_6  * weight_ch07_2D[1] + ch07_5  * weight_ch07_2D[0]
                + ch08_15 * weight_ch08_2D[8] + ch08_14 * weight_ch08_2D[7] + ch08_13 * weight_ch08_2D[6]
                + ch08_11 * weight_ch08_2D[5] + ch08_10 * weight_ch08_2D[4] + ch08_9  * weight_ch08_2D[3]
                + ch08_7  * weight_ch08_2D[2] + ch08_6  * weight_ch08_2D[1] + ch08_5  * weight_ch08_2D[0]
                + ch09_15 * weight_ch09_2D[8] + ch09_14 * weight_ch09_2D[7] + ch09_13 * weight_ch09_2D[6]
                + ch09_11 * weight_ch09_2D[5] + ch09_10 * weight_ch09_2D[4] + ch09_9  * weight_ch09_2D[3]
                + ch09_7  * weight_ch09_2D[2] + ch09_6  * weight_ch09_2D[1] + ch09_5  * weight_ch09_2D[0]
                + ch10_15 * weight_ch10_2D[8] + ch10_14 * weight_ch10_2D[7] + ch10_13 * weight_ch10_2D[6]
                + ch10_11 * weight_ch10_2D[5] + ch10_10 * weight_ch10_2D[4] + ch10_9  * weight_ch10_2D[3]
                + ch10_7  * weight_ch10_2D[2] + ch10_6  * weight_ch10_2D[1] + ch10_5  * weight_ch10_2D[0]
                + ch11_15 * weight_ch11_2D[8] + ch11_14 * weight_ch11_2D[7] + ch11_13 * weight_ch11_2D[6]
                + ch11_11 * weight_ch11_2D[5] + ch11_10 * weight_ch11_2D[4] + ch11_9  * weight_ch11_2D[3]
                + ch11_7  * weight_ch11_2D[2] + ch11_6  * weight_ch11_2D[1] + ch11_5  * weight_ch11_2D[0];
    
    origin_sum2 = ch00_14 * weight_ch00_2D[8] + ch00_13 * weight_ch00_2D[7] + ch00_12 * weight_ch00_2D[6]
                + ch00_10 * weight_ch00_2D[5] + ch00_9  * weight_ch00_2D[4] + ch00_8  * weight_ch00_2D[3]
                + ch00_6  * weight_ch00_2D[2] + ch00_5  * weight_ch00_2D[1] + ch00_4  * weight_ch00_2D[0]
                + ch01_14 * weight_ch01_2D[8] + ch01_13 * weight_ch01_2D[7] + ch01_12 * weight_ch01_2D[6]
                + ch01_10 * weight_ch01_2D[5] + ch01_9  * weight_ch01_2D[4] + ch01_8  * weight_ch01_2D[3]
                + ch01_6  * weight_ch01_2D[2] + ch01_5  * weight_ch01_2D[1] + ch01_4  * weight_ch01_2D[0]
                + ch02_14 * weight_ch02_2D[8] + ch02_13 * weight_ch02_2D[7] + ch02_12 * weight_ch02_2D[6]
                + ch02_10 * weight_ch02_2D[5] + ch02_9  * weight_ch02_2D[4] + ch02_8  * weight_ch02_2D[3]
                + ch02_6  * weight_ch02_2D[2] + ch02_5  * weight_ch02_2D[1] + ch02_4  * weight_ch02_2D[0]
                + ch03_14 * weight_ch03_2D[8] + ch03_13 * weight_ch03_2D[7] + ch03_12 * weight_ch03_2D[6]
                + ch03_10 * weight_ch03_2D[5] + ch03_9  * weight_ch03_2D[4] + ch03_8  * weight_ch03_2D[3]
                + ch03_6  * weight_ch03_2D[2] + ch03_5  * weight_ch03_2D[1] + ch03_4  * weight_ch03_2D[0]
                + ch04_14 * weight_ch04_2D[8] + ch04_13 * weight_ch04_2D[7] + ch04_12 * weight_ch04_2D[6]
                + ch04_10 * weight_ch04_2D[5] + ch04_9  * weight_ch04_2D[4] + ch04_8  * weight_ch04_2D[3]
                + ch04_6  * weight_ch04_2D[2] + ch04_5  * weight_ch04_2D[1] + ch04_4  * weight_ch04_2D[0]
                + ch05_14 * weight_ch05_2D[8] + ch05_13 * weight_ch05_2D[7] + ch05_12 * weight_ch05_2D[6]
                + ch05_10 * weight_ch05_2D[5] + ch05_9  * weight_ch05_2D[4] + ch05_8  * weight_ch05_2D[3]
                + ch05_6  * weight_ch05_2D[2] + ch05_5  * weight_ch05_2D[1] + ch05_4  * weight_ch05_2D[0]
                + ch06_14 * weight_ch06_2D[8] + ch06_13 * weight_ch06_2D[7] + ch06_12 * weight_ch06_2D[6]
                + ch06_10 * weight_ch06_2D[5] + ch06_9  * weight_ch06_2D[4] + ch06_8  * weight_ch06_2D[3]
                + ch06_6  * weight_ch06_2D[2] + ch06_5  * weight_ch06_2D[1] + ch06_4  * weight_ch06_2D[0]
                + ch07_14 * weight_ch07_2D[8] + ch07_13 * weight_ch07_2D[7] + ch07_12 * weight_ch07_2D[6]
                + ch07_10 * weight_ch07_2D[5] + ch07_9  * weight_ch07_2D[4] + ch07_8  * weight_ch07_2D[3]
                + ch07_6  * weight_ch07_2D[2] + ch07_5  * weight_ch07_2D[1] + ch07_4  * weight_ch07_2D[0]
                + ch08_14 * weight_ch08_2D[8] + ch08_13 * weight_ch08_2D[7] + ch08_12 * weight_ch08_2D[6]
                + ch08_10 * weight_ch08_2D[5] + ch08_9  * weight_ch08_2D[4] + ch08_8  * weight_ch08_2D[3]
                + ch08_6  * weight_ch08_2D[2] + ch08_5  * weight_ch08_2D[1] + ch08_4  * weight_ch08_2D[0]
                + ch09_14 * weight_ch09_2D[8] + ch09_13 * weight_ch09_2D[7] + ch09_12 * weight_ch09_2D[6]
                + ch09_10 * weight_ch09_2D[5] + ch09_9  * weight_ch09_2D[4] + ch09_8  * weight_ch09_2D[3]
                + ch09_6  * weight_ch09_2D[2] + ch09_5  * weight_ch09_2D[1] + ch09_4  * weight_ch09_2D[0]
                + ch10_14 * weight_ch10_2D[8] + ch10_13 * weight_ch10_2D[7] + ch10_12 * weight_ch10_2D[6]
                + ch10_10 * weight_ch10_2D[5] + ch10_9  * weight_ch10_2D[4] + ch10_8  * weight_ch10_2D[3]
                + ch10_6  * weight_ch10_2D[2] + ch10_5  * weight_ch10_2D[1] + ch10_4  * weight_ch10_2D[0]
                + ch11_14 * weight_ch11_2D[8] + ch11_13 * weight_ch11_2D[7] + ch11_12 * weight_ch11_2D[6]
                + ch11_10 * weight_ch11_2D[5] + ch11_9  * weight_ch11_2D[4] + ch11_8  * weight_ch11_2D[3]
                + ch11_6  * weight_ch11_2D[2] + ch11_5  * weight_ch11_2D[1] + ch11_4  * weight_ch11_2D[0];
    
    origin_sum1 = ch00_11 * weight_ch00_2D[8] + ch00_10 * weight_ch00_2D[7] + ch00_9  * weight_ch00_2D[6]
                + ch00_7  * weight_ch00_2D[5] + ch00_6  * weight_ch00_2D[4] + ch00_5  * weight_ch00_2D[3]
                + ch00_3  * weight_ch00_2D[2] + ch00_2  * weight_ch00_2D[1] + ch00_1  * weight_ch00_2D[0]
                + ch01_11 * weight_ch01_2D[8] + ch01_10 * weight_ch01_2D[7] + ch01_9  * weight_ch01_2D[6]
                + ch01_7  * weight_ch01_2D[5] + ch01_6  * weight_ch01_2D[4] + ch01_5  * weight_ch01_2D[3]
                + ch01_3  * weight_ch01_2D[2] + ch01_2  * weight_ch01_2D[1] + ch01_1  * weight_ch01_2D[0]
                + ch02_11 * weight_ch02_2D[8] + ch02_10 * weight_ch02_2D[7] + ch02_9  * weight_ch02_2D[6]
                + ch02_7  * weight_ch02_2D[5] + ch02_6  * weight_ch02_2D[4] + ch02_5  * weight_ch02_2D[3]
                + ch02_3  * weight_ch02_2D[2] + ch02_2  * weight_ch02_2D[1] + ch02_1  * weight_ch02_2D[0]
                + ch03_11 * weight_ch03_2D[8] + ch03_10 * weight_ch03_2D[7] + ch03_9  * weight_ch03_2D[6]
                + ch03_7  * weight_ch03_2D[5] + ch03_6  * weight_ch03_2D[4] + ch03_5  * weight_ch03_2D[3]
                + ch03_3  * weight_ch03_2D[2] + ch03_2  * weight_ch03_2D[1] + ch03_1  * weight_ch03_2D[0]
                + ch04_11 * weight_ch04_2D[8] + ch04_10 * weight_ch04_2D[7] + ch04_9  * weight_ch04_2D[6]
                + ch04_7  * weight_ch04_2D[5] + ch04_6  * weight_ch04_2D[4] + ch04_5  * weight_ch04_2D[3]
                + ch04_3  * weight_ch04_2D[2] + ch04_2  * weight_ch04_2D[1] + ch04_1  * weight_ch04_2D[0]
                + ch05_11 * weight_ch05_2D[8] + ch05_10 * weight_ch05_2D[7] + ch05_9  * weight_ch05_2D[6]
                + ch05_7  * weight_ch05_2D[5] + ch05_6  * weight_ch05_2D[4] + ch05_5  * weight_ch05_2D[3]
                + ch05_3  * weight_ch05_2D[2] + ch05_2  * weight_ch05_2D[1] + ch05_1  * weight_ch05_2D[0]
                + ch06_11 * weight_ch06_2D[8] + ch06_10 * weight_ch06_2D[7] + ch06_9  * weight_ch06_2D[6]
                + ch06_7  * weight_ch06_2D[5] + ch06_6  * weight_ch06_2D[4] + ch06_5  * weight_ch06_2D[3]
                + ch06_3  * weight_ch06_2D[2] + ch06_2  * weight_ch06_2D[1] + ch06_1  * weight_ch06_2D[0]
                + ch07_11 * weight_ch07_2D[8] + ch07_10 * weight_ch07_2D[7] + ch07_9  * weight_ch07_2D[6]
                + ch07_7  * weight_ch07_2D[5] + ch07_6  * weight_ch07_2D[4] + ch07_5  * weight_ch07_2D[3]
                + ch07_3  * weight_ch07_2D[2] + ch07_2  * weight_ch07_2D[1] + ch07_1  * weight_ch07_2D[0]
                + ch08_11 * weight_ch08_2D[8] + ch08_10 * weight_ch08_2D[7] + ch08_9  * weight_ch08_2D[6]
                + ch08_7  * weight_ch08_2D[5] + ch08_6  * weight_ch08_2D[4] + ch08_5  * weight_ch08_2D[3]
                + ch08_3  * weight_ch08_2D[2] + ch08_2  * weight_ch08_2D[1] + ch08_1  * weight_ch08_2D[0]
                + ch09_11 * weight_ch09_2D[8] + ch09_10 * weight_ch09_2D[7] + ch09_9  * weight_ch09_2D[6]
                + ch09_7  * weight_ch09_2D[5] + ch09_6  * weight_ch09_2D[4] + ch09_5  * weight_ch09_2D[3]
                + ch09_3  * weight_ch09_2D[2] + ch09_2  * weight_ch09_2D[1] + ch09_1  * weight_ch09_2D[0]
                + ch10_11 * weight_ch10_2D[8] + ch10_10 * weight_ch10_2D[7] + ch10_9  * weight_ch10_2D[6]
                + ch10_7  * weight_ch10_2D[5] + ch10_6  * weight_ch10_2D[4] + ch10_5  * weight_ch10_2D[3]
                + ch10_3  * weight_ch10_2D[2] + ch10_2  * weight_ch10_2D[1] + ch10_1  * weight_ch10_2D[0]
                + ch11_11 * weight_ch11_2D[8] + ch11_10 * weight_ch11_2D[7] + ch11_9  * weight_ch11_2D[6]
                + ch11_7  * weight_ch11_2D[5] + ch11_6  * weight_ch11_2D[4] + ch11_5  * weight_ch11_2D[3]
                + ch11_3  * weight_ch11_2D[2] + ch11_2  * weight_ch11_2D[1] + ch11_1  * weight_ch11_2D[0];
    
    origin_sum0 = ch00_10 * weight_ch00_2D[8] + ch00_9  * weight_ch00_2D[7] + ch00_8  * weight_ch00_2D[6]
                + ch00_6  * weight_ch00_2D[5] + ch00_5  * weight_ch00_2D[4] + ch00_4  * weight_ch00_2D[3]
                + ch00_2  * weight_ch00_2D[2] + ch00_1  * weight_ch00_2D[1] + ch00_0  * weight_ch00_2D[0]
                + ch01_10 * weight_ch01_2D[8] + ch01_9  * weight_ch01_2D[7] + ch01_8  * weight_ch01_2D[6]
                + ch01_6  * weight_ch01_2D[5] + ch01_5  * weight_ch01_2D[4] + ch01_4  * weight_ch01_2D[3]
                + ch01_2  * weight_ch01_2D[2] + ch01_1  * weight_ch01_2D[1] + ch01_0  * weight_ch01_2D[0]
                + ch02_10 * weight_ch02_2D[8] + ch02_9  * weight_ch02_2D[7] + ch02_8  * weight_ch02_2D[6]
                + ch02_6  * weight_ch02_2D[5] + ch02_5  * weight_ch02_2D[4] + ch02_4  * weight_ch02_2D[3]
                + ch02_2  * weight_ch02_2D[2] + ch02_1  * weight_ch02_2D[1] + ch02_0  * weight_ch02_2D[0]
                + ch03_10 * weight_ch03_2D[8] + ch03_9  * weight_ch03_2D[7] + ch03_8  * weight_ch03_2D[6]
                + ch03_6  * weight_ch03_2D[5] + ch03_5  * weight_ch03_2D[4] + ch03_4  * weight_ch03_2D[3]
                + ch03_2  * weight_ch03_2D[2] + ch03_1  * weight_ch03_2D[1] + ch03_0  * weight_ch03_2D[0]
                + ch04_10 * weight_ch04_2D[8] + ch04_9  * weight_ch04_2D[7] + ch04_8  * weight_ch04_2D[6]
                + ch04_6  * weight_ch04_2D[5] + ch04_5  * weight_ch04_2D[4] + ch04_4  * weight_ch04_2D[3]
                + ch04_2  * weight_ch04_2D[2] + ch04_1  * weight_ch04_2D[1] + ch04_0  * weight_ch04_2D[0]
                + ch05_10 * weight_ch05_2D[8] + ch05_9  * weight_ch05_2D[7] + ch05_8  * weight_ch05_2D[6]
                + ch05_6  * weight_ch05_2D[5] + ch05_5  * weight_ch05_2D[4] + ch05_4  * weight_ch05_2D[3]
                + ch05_2  * weight_ch05_2D[2] + ch05_1  * weight_ch05_2D[1] + ch05_0  * weight_ch05_2D[0]
                + ch06_10 * weight_ch06_2D[8] + ch06_9  * weight_ch06_2D[7] + ch06_8  * weight_ch06_2D[6]
                + ch06_6  * weight_ch06_2D[5] + ch06_5  * weight_ch06_2D[4] + ch06_4  * weight_ch06_2D[3]
                + ch06_2  * weight_ch06_2D[2] + ch06_1  * weight_ch06_2D[1] + ch06_0  * weight_ch06_2D[0]
                + ch07_10 * weight_ch07_2D[8] + ch07_9  * weight_ch07_2D[7] + ch07_8  * weight_ch07_2D[6]
                + ch07_6  * weight_ch07_2D[5] + ch07_5  * weight_ch07_2D[4] + ch07_4  * weight_ch07_2D[3]
                + ch07_2  * weight_ch07_2D[2] + ch07_1  * weight_ch07_2D[1] + ch07_0  * weight_ch07_2D[0]
                + ch08_10 * weight_ch08_2D[8] + ch08_9  * weight_ch08_2D[7] + ch08_8  * weight_ch08_2D[6]
                + ch08_6  * weight_ch08_2D[5] + ch08_5  * weight_ch08_2D[4] + ch08_4  * weight_ch08_2D[3]
                + ch08_2  * weight_ch08_2D[2] + ch08_1  * weight_ch08_2D[1] + ch08_0  * weight_ch08_2D[0]
                + ch09_10 * weight_ch09_2D[8] + ch09_9  * weight_ch09_2D[7] + ch09_8  * weight_ch09_2D[6]
                + ch09_6  * weight_ch09_2D[5] + ch09_5  * weight_ch09_2D[4] + ch09_4  * weight_ch09_2D[3]
                + ch09_2  * weight_ch09_2D[2] + ch09_1  * weight_ch09_2D[1] + ch09_0  * weight_ch09_2D[0]
                + ch10_10 * weight_ch10_2D[8] + ch10_9  * weight_ch10_2D[7] + ch10_8  * weight_ch10_2D[6]
                + ch10_6  * weight_ch10_2D[5] + ch10_5  * weight_ch10_2D[4] + ch10_4  * weight_ch10_2D[3]
                + ch10_2  * weight_ch10_2D[2] + ch10_1  * weight_ch10_2D[1] + ch10_0  * weight_ch10_2D[0]
                + ch11_10 * weight_ch11_2D[8] + ch11_9  * weight_ch11_2D[7] + ch11_8  * weight_ch11_2D[6]
                + ch11_6  * weight_ch11_2D[5] + ch11_5  * weight_ch11_2D[4] + ch11_4  * weight_ch11_2D[3]
                + ch11_2  * weight_ch11_2D[2] + ch11_1  * weight_ch11_2D[1] + ch11_0  * weight_ch11_2D[0];
end

// bias + relu
always @* begin
    sum3_acc = (origin_sum3 + (bias <<< 8)) > 0 ? (origin_sum3 + (bias <<< 8)) : 0;
    sum2_acc = (origin_sum2 + (bias <<< 8)) > 0 ? (origin_sum2 + (bias <<< 8)) : 0;
    sum1_acc = (origin_sum1 + (bias <<< 8)) > 0 ? (origin_sum1 + (bias <<< 8)) : 0;
    sum0_acc = (origin_sum0 + (bias <<< 8)) > 0 ? (origin_sum0 + (bias <<< 8)) : 0;
end

// average pooling
always @* begin
    average = (sum3_acc + sum2_acc + sum1_acc + sum0_acc) / 4;
end

// quan
always @* begin
    average_quan_temp = (average + {14'd0, 1'd1, 6'd0});
    average_quan = average_quan_temp >>> 7;
    if (average_quan > 2047) begin
        average_final = 2047;
    end
    else if (average_quan < -2048) begin
        average_final = -2048;
    end
    else begin
        average_final = average_quan[11:0];
    end
end


// set sram_wdata_b_next
always @* begin
    for (i = 0; i < 16; i = i + 1) begin
        sram_wdata_b_next[i*12 +:12] = average_final;
    end
end

// set sram_wordmask_b_next
always @* begin
    sram_wordmask_b_next = sram_wordmask_b;
    if (wait_cnt != 13) begin
        sram_wordmask_b_next = 16'b1111_1111_1111_1111;
    end
    else if (local_state == CAL && wait_cnt == 13) begin
        if (input_cnt == 0 || input_cnt == 2 || input_cnt == 8 || input_cnt == 10) begin
            case (conv_cnt % 4)
                0: sram_wordmask_b_next = 16'b0111_1111_1111_1111;
                1: sram_wordmask_b_next = 16'b1111_0111_1111_1111;
                2: sram_wordmask_b_next = 16'b1111_1111_0111_1111;
                3: sram_wordmask_b_next = 16'b1111_1111_1111_0111;
                default: sram_wordmask_b_next = 16'b1111_1111_1111_1111;
            endcase
        end
        else if (input_cnt == 1 || input_cnt == 3 || input_cnt == 9 || input_cnt == 11) begin
            case (conv_cnt % 4)
                0: sram_wordmask_b_next = 16'b1011_1111_1111_1111;
                1: sram_wordmask_b_next = 16'b1111_1011_1111_1111;
                2: sram_wordmask_b_next = 16'b1111_1111_1011_1111;
                3: sram_wordmask_b_next = 16'b1111_1111_1111_1011;
                default: sram_wordmask_b_next = 16'b1111_1111_1111_1111;
            endcase
        end
        else if (input_cnt == 4 || input_cnt == 6 || input_cnt == 12 || input_cnt == 14) begin
            case (conv_cnt % 4)
                0: sram_wordmask_b_next = 16'b1101_1111_1111_1111;
                1: sram_wordmask_b_next = 16'b1111_1101_1111_1111;
                2: sram_wordmask_b_next = 16'b1111_1111_1101_1111;
                3: sram_wordmask_b_next = 16'b1111_1111_1111_1101;
                default: sram_wordmask_b_next = 16'b1111_1111_1111_1111;
            endcase
        end
        else if (input_cnt == 5 || input_cnt == 7 || input_cnt == 13 || input_cnt == 15) begin
            case (conv_cnt % 4)
                0: sram_wordmask_b_next = 16'b1110_1111_1111_1111;
                1: sram_wordmask_b_next = 16'b1111_1110_1111_1111;
                2: sram_wordmask_b_next = 16'b1111_1111_1110_1111;
                3: sram_wordmask_b_next = 16'b1111_1111_1111_1110;
                default: sram_wordmask_b_next = 16'b1111_1111_1111_1111;
            endcase
        end
    end
end

// sram_waddr_b_next
always @* begin
    sram_waddr_b_next = conv_cnt / 4;
end

// set sram_wen_b0_next ~ sram_wen_b3_next
always @* begin
    sram_wen_b0_next = sram_wen_b0;
    sram_wen_b1_next = sram_wen_b1;
    sram_wen_b2_next = sram_wen_b2;
    sram_wen_b3_next = sram_wen_b3;
    if (input_cnt == 0 || input_cnt == 1 || input_cnt == 4 || input_cnt == 5) begin
        sram_wen_b0_next = 0;
        sram_wen_b1_next = 1;
        sram_wen_b2_next = 1;
        sram_wen_b3_next = 1;
    end
    else if (input_cnt == 2 || input_cnt == 3 || input_cnt == 6 || input_cnt == 7) begin
        sram_wen_b0_next = 1;
        sram_wen_b1_next = 0;
        sram_wen_b2_next = 1;
        sram_wen_b3_next = 1;
    end
    else if (input_cnt == 8 || input_cnt == 9 || input_cnt == 12 || input_cnt == 13) begin
        sram_wen_b0_next = 1;
        sram_wen_b1_next = 1;
        sram_wen_b2_next = 0;
        sram_wen_b3_next = 1;
    end
    else if (input_cnt == 10 || input_cnt == 11 || input_cnt == 14 || input_cnt == 15) begin
        sram_wen_b0_next = 1;
        sram_wen_b1_next = 1;
        sram_wen_b2_next = 1;
        sram_wen_b3_next = 0;
    end
end

// set valid_next
always @* begin
    if (input_cnt == 16) begin
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
            if (state == CONV3) begin
                local_state_next = CAL;
            end
            else begin
                local_state_next = WAIT;
            end
        end
        CAL: local_state_next = CAL;
        default: local_state_next = WAIT;
    endcase
end


// FF
always @(posedge clk) begin
    if (~rst_n) begin
        conv_cnt <= 0;
        wait_cnt <= 0;
        input_cnt <= 0;
        local_state <= WAIT;

        weight_ch00 <= 0;
        weight_ch01 <= 0;
        weight_ch02 <= 0;
        weight_ch03 <= 0;
        weight_ch04 <= 0;
        weight_ch05 <= 0;
        weight_ch06 <= 0;
        weight_ch07 <= 0;
        weight_ch08 <= 0;
        weight_ch09 <= 0;
        weight_ch10 <= 0;
        weight_ch11 <= 0;
        bias <= 0;

        sram_raddr_a0 <= 0;
        sram_raddr_a1 <= 0;
        sram_raddr_a2 <= 0;
        sram_raddr_a3 <= 0;

        sram_rdata_a0 <= 0;
        sram_rdata_a1 <= 0;
        sram_rdata_a2 <= 0;
        sram_rdata_a3 <= 0;

        ch00_0 <= 0;
        ch00_1 <= 0;
        ch00_2 <= 0;
        ch00_3 <= 0;
        ch00_4 <= 0;
        ch00_5 <= 0;
        ch00_6 <= 0;
        ch00_7 <= 0;
        ch00_8 <= 0;
        ch00_9 <= 0;
        ch00_10 <= 0;
        ch00_11 <= 0;
        ch00_12 <= 0;
        ch00_13 <= 0;
        ch00_14 <= 0;
        ch00_15 <= 0;
        ch01_0 <= 0;
        ch01_1 <= 0;
        ch01_2 <= 0;
        ch01_3 <= 0;
        ch01_4 <= 0;
        ch01_5 <= 0;
        ch01_6 <= 0;
        ch01_7 <= 0;
        ch01_8 <= 0;
        ch01_9 <= 0;
        ch01_10 <= 0;
        ch01_11 <= 0;
        ch01_12 <= 0;
        ch01_13 <= 0;
        ch01_14 <= 0;
        ch01_15 <= 0;
        ch02_0 <= 0;
        ch02_1 <= 0;
        ch02_2 <= 0;
        ch02_3 <= 0;
        ch02_4 <= 0;
        ch02_5 <= 0;
        ch02_6 <= 0;
        ch02_7 <= 0;
        ch02_8 <= 0;
        ch02_9 <= 0;
        ch02_10 <= 0;
        ch02_11 <= 0;
        ch02_12 <= 0;
        ch02_13 <= 0;
        ch02_14 <= 0;
        ch02_15 <= 0;
        ch03_0 <= 0;
        ch03_1 <= 0;
        ch03_2 <= 0;
        ch03_3 <= 0;
        ch03_4 <= 0;
        ch03_5 <= 0;
        ch03_6 <= 0;
        ch03_7 <= 0;
        ch03_8 <= 0;
        ch03_9 <= 0;
        ch03_10 <= 0;
        ch03_11 <= 0;
        ch03_12 <= 0;
        ch03_13 <= 0;
        ch03_14 <= 0;
        ch03_15 <= 0;
        ch04_0 <= 0;
        ch04_1 <= 0;
        ch04_2 <= 0;
        ch04_3 <= 0;
        ch04_4 <= 0;
        ch04_5 <= 0;
        ch04_6 <= 0;
        ch04_7 <= 0;
        ch04_8 <= 0;
        ch04_9 <= 0;
        ch04_10 <= 0;
        ch04_11 <= 0;
        ch04_12 <= 0;
        ch04_13 <= 0;
        ch04_14 <= 0;
        ch04_15 <= 0;
        ch05_0 <= 0;
        ch05_1 <= 0;
        ch05_2 <= 0;
        ch05_3 <= 0;
        ch05_4 <= 0;
        ch05_5 <= 0;
        ch05_6 <= 0;
        ch05_7 <= 0;
        ch05_8 <= 0;
        ch05_9 <= 0;
        ch05_10 <= 0;
        ch05_11 <= 0;
        ch05_12 <= 0;
        ch05_13 <= 0;
        ch05_14 <= 0;
        ch05_15 <= 0;
        ch06_0 <= 0;
        ch06_1 <= 0;
        ch06_2 <= 0;
        ch06_3 <= 0;
        ch06_4 <= 0;
        ch06_5 <= 0;
        ch06_6 <= 0;
        ch06_7 <= 0;
        ch06_8 <= 0;
        ch06_9 <= 0;
        ch06_10 <= 0;
        ch06_11 <= 0;
        ch06_12 <= 0;
        ch06_13 <= 0;
        ch06_14 <= 0;
        ch06_15 <= 0;
        ch07_0 <= 0;
        ch07_1 <= 0;
        ch07_2 <= 0;
        ch07_3 <= 0;
        ch07_4 <= 0;
        ch07_5 <= 0;
        ch07_6 <= 0;
        ch07_7 <= 0;
        ch07_8 <= 0;
        ch07_9 <= 0;
        ch07_10 <= 0;
        ch07_11 <= 0;
        ch07_12 <= 0;
        ch07_13 <= 0;
        ch07_14 <= 0;
        ch07_15 <= 0;
        ch08_0 <= 0;
        ch08_1 <= 0;
        ch08_2 <= 0;
        ch08_3 <= 0;
        ch08_4 <= 0;
        ch08_5 <= 0;
        ch08_6 <= 0;
        ch08_7 <= 0;
        ch08_8 <= 0;
        ch08_9 <= 0;
        ch08_10 <= 0;
        ch08_11 <= 0;
        ch08_12 <= 0;
        ch08_13 <= 0;
        ch08_14 <= 0;
        ch08_15 <= 0;
        ch09_0 <= 0;
        ch09_1 <= 0;
        ch09_2 <= 0;
        ch09_3 <= 0;
        ch09_4 <= 0;
        ch09_5 <= 0;
        ch09_6 <= 0;
        ch09_7 <= 0;
        ch09_8 <= 0;
        ch09_9 <= 0;
        ch09_10 <= 0;
        ch09_11 <= 0;
        ch09_12 <= 0;
        ch09_13 <= 0;
        ch09_14 <= 0;
        ch09_15 <= 0;
        ch10_0 <= 0;
        ch10_1 <= 0;
        ch10_2 <= 0;
        ch10_3 <= 0;
        ch10_4 <= 0;
        ch10_5 <= 0;
        ch10_6 <= 0;
        ch10_7 <= 0;
        ch10_8 <= 0;
        ch10_9 <= 0;
        ch10_10 <= 0;
        ch10_11 <= 0;
        ch10_12 <= 0;
        ch10_13 <= 0;
        ch10_14 <= 0;
        ch10_15 <= 0;
        ch11_0 <= 0;
        ch11_1 <= 0;
        ch11_2 <= 0;
        ch11_3 <= 0;
        ch11_4 <= 0;
        ch11_5 <= 0;
        ch11_6 <= 0;
        ch11_7 <= 0;
        ch11_8 <= 0;
        ch11_9 <= 0;
        ch11_10 <= 0;
        ch11_11 <= 0;
        ch11_12 <= 0;
        ch11_13 <= 0;
        ch11_14 <= 0;
        ch11_15 <= 0;

        sram_wordmask_b <= 16'b1111_1111_1111_1111;
        sram_waddr_b <= 0;
        sram_wdata_b <= 0;
        sram_wen_b0 <= 1;
        sram_wen_b1 <= 1;
        sram_wen_b2 <= 1;
        sram_wen_b3 <= 1;
        valid <= 0;

    end
    else begin
        conv_cnt <= conv_cnt_next;
        wait_cnt <= wait_cnt_next;
        input_cnt <= input_cnt_next;
        local_state <= local_state_next;

        weight_ch00 <= weight_ch00_next;
        weight_ch01 <= weight_ch01_next;
        weight_ch02 <= weight_ch02_next;
        weight_ch03 <= weight_ch03_next;
        weight_ch04 <= weight_ch04_next;
        weight_ch05 <= weight_ch05_next;
        weight_ch06 <= weight_ch06_next;
        weight_ch07 <= weight_ch07_next;
        weight_ch08 <= weight_ch08_next;
        weight_ch09 <= weight_ch09_next;
        weight_ch10 <= weight_ch10_next;
        weight_ch11 <= weight_ch11_next;
        bias <= bias_next;

        sram_raddr_a0 <= sram_raddr_a0_next;
        sram_raddr_a1 <= sram_raddr_a1_next;
        sram_raddr_a2 <= sram_raddr_a2_next;
        sram_raddr_a3 <= sram_raddr_a3_next;

        sram_rdata_a0 <= sram_rdata_a0_in;
        sram_rdata_a1 <= sram_rdata_a1_in;
        sram_rdata_a2 <= sram_rdata_a2_in;
        sram_rdata_a3 <= sram_rdata_a3_in;

        ch00_0 <= ch00_0_next;
        ch00_1 <= ch00_1_next;
        ch00_2 <= ch00_2_next;
        ch00_3 <= ch00_3_next;
        ch00_4 <= ch00_4_next;
        ch00_5 <= ch00_5_next;
        ch00_6 <= ch00_6_next;
        ch00_7 <= ch00_7_next;
        ch00_8 <= ch00_8_next;
        ch00_9 <= ch00_9_next;
        ch00_10 <= ch00_10_next;
        ch00_11 <= ch00_11_next;
        ch00_12 <= ch00_12_next;
        ch00_13 <= ch00_13_next;
        ch00_14 <= ch00_14_next;
        ch00_15 <= ch00_15_next;
        ch01_0 <= ch01_0_next;
        ch01_1 <= ch01_1_next;
        ch01_2 <= ch01_2_next;
        ch01_3 <= ch01_3_next;
        ch01_4 <= ch01_4_next;
        ch01_5 <= ch01_5_next;
        ch01_6 <= ch01_6_next;
        ch01_7 <= ch01_7_next;
        ch01_8 <= ch01_8_next;
        ch01_9 <= ch01_9_next;
        ch01_10 <= ch01_10_next;
        ch01_11 <= ch01_11_next;
        ch01_12 <= ch01_12_next;
        ch01_13 <= ch01_13_next;
        ch01_14 <= ch01_14_next;
        ch01_15 <= ch01_15_next;
        ch02_0 <= ch02_0_next;
        ch02_1 <= ch02_1_next;
        ch02_2 <= ch02_2_next;
        ch02_3 <= ch02_3_next;
        ch02_4 <= ch02_4_next;
        ch02_5 <= ch02_5_next;
        ch02_6 <= ch02_6_next;
        ch02_7 <= ch02_7_next;
        ch02_8 <= ch02_8_next;
        ch02_9 <= ch02_9_next;
        ch02_10 <= ch02_10_next;
        ch02_11 <= ch02_11_next;
        ch02_12 <= ch02_12_next;
        ch02_13 <= ch02_13_next;
        ch02_14 <= ch02_14_next;
        ch02_15 <= ch02_15_next;
        ch03_0 <= ch03_0_next;
        ch03_1 <= ch03_1_next;
        ch03_2 <= ch03_2_next;
        ch03_3 <= ch03_3_next;
        ch03_4 <= ch03_4_next;
        ch03_5 <= ch03_5_next;
        ch03_6 <= ch03_6_next;
        ch03_7 <= ch03_7_next;
        ch03_8 <= ch03_8_next;
        ch03_9 <= ch03_9_next;
        ch03_10 <= ch03_10_next;
        ch03_11 <= ch03_11_next;
        ch03_12 <= ch03_12_next;
        ch03_13 <= ch03_13_next;
        ch03_14 <= ch03_14_next;
        ch03_15 <= ch03_15_next;
        ch04_0 <= ch04_0_next;
        ch04_1 <= ch04_1_next;
        ch04_2 <= ch04_2_next;
        ch04_3 <= ch04_3_next;
        ch04_4 <= ch04_4_next;
        ch04_5 <= ch04_5_next;
        ch04_6 <= ch04_6_next;
        ch04_7 <= ch04_7_next;
        ch04_8 <= ch04_8_next;
        ch04_9 <= ch04_9_next;
        ch04_10 <= ch04_10_next;
        ch04_11 <= ch04_11_next;
        ch04_12 <= ch04_12_next;
        ch04_13 <= ch04_13_next;
        ch04_14 <= ch04_14_next;
        ch04_15 <= ch04_15_next;
        ch05_0 <= ch05_0_next;
        ch05_1 <= ch05_1_next;
        ch05_2 <= ch05_2_next;
        ch05_3 <= ch05_3_next;
        ch05_4 <= ch05_4_next;
        ch05_5 <= ch05_5_next;
        ch05_6 <= ch05_6_next;
        ch05_7 <= ch05_7_next;
        ch05_8 <= ch05_8_next;
        ch05_9 <= ch05_9_next;
        ch05_10 <= ch05_10_next;
        ch05_11 <= ch05_11_next;
        ch05_12 <= ch05_12_next;
        ch05_13 <= ch05_13_next;
        ch05_14 <= ch05_14_next;
        ch05_15 <= ch05_15_next;
        ch06_0 <= ch06_0_next;
        ch06_1 <= ch06_1_next;
        ch06_2 <= ch06_2_next;
        ch06_3 <= ch06_3_next;
        ch06_4 <= ch06_4_next;
        ch06_5 <= ch06_5_next;
        ch06_6 <= ch06_6_next;
        ch06_7 <= ch06_7_next;
        ch06_8 <= ch06_8_next;
        ch06_9 <= ch06_9_next;
        ch06_10 <= ch06_10_next;
        ch06_11 <= ch06_11_next;
        ch06_12 <= ch06_12_next;
        ch06_13 <= ch06_13_next;
        ch06_14 <= ch06_14_next;
        ch06_15 <= ch06_15_next;
        ch07_0 <= ch07_0_next;
        ch07_1 <= ch07_1_next;
        ch07_2 <= ch07_2_next;
        ch07_3 <= ch07_3_next;
        ch07_4 <= ch07_4_next;
        ch07_5 <= ch07_5_next;
        ch07_6 <= ch07_6_next;
        ch07_7 <= ch07_7_next;
        ch07_8 <= ch07_8_next;
        ch07_9 <= ch07_9_next;
        ch07_10 <= ch07_10_next;
        ch07_11 <= ch07_11_next;
        ch07_12 <= ch07_12_next;
        ch07_13 <= ch07_13_next;
        ch07_14 <= ch07_14_next;
        ch07_15 <= ch07_15_next;
        ch08_0 <= ch08_0_next;
        ch08_1 <= ch08_1_next;
        ch08_2 <= ch08_2_next;
        ch08_3 <= ch08_3_next;
        ch08_4 <= ch08_4_next;
        ch08_5 <= ch08_5_next;
        ch08_6 <= ch08_6_next;
        ch08_7 <= ch08_7_next;
        ch08_8 <= ch08_8_next;
        ch08_9 <= ch08_9_next;
        ch08_10 <= ch08_10_next;
        ch08_11 <= ch08_11_next;
        ch08_12 <= ch08_12_next;
        ch08_13 <= ch08_13_next;
        ch08_14 <= ch08_14_next;
        ch08_15 <= ch08_15_next;
        ch09_0 <= ch09_0_next;
        ch09_1 <= ch09_1_next;
        ch09_2 <= ch09_2_next;
        ch09_3 <= ch09_3_next;
        ch09_4 <= ch09_4_next;
        ch09_5 <= ch09_5_next;
        ch09_6 <= ch09_6_next;
        ch09_7 <= ch09_7_next;
        ch09_8 <= ch09_8_next;
        ch09_9 <= ch09_9_next;
        ch09_10 <= ch09_10_next;
        ch09_11 <= ch09_11_next;
        ch09_12 <= ch09_12_next;
        ch09_13 <= ch09_13_next;
        ch09_14 <= ch09_14_next;
        ch09_15 <= ch09_15_next;
        ch10_0 <= ch10_0_next;
        ch10_1 <= ch10_1_next;
        ch10_2 <= ch10_2_next;
        ch10_3 <= ch10_3_next;
        ch10_4 <= ch10_4_next;
        ch10_5 <= ch10_5_next;
        ch10_6 <= ch10_6_next;
        ch10_7 <= ch10_7_next;
        ch10_8 <= ch10_8_next;
        ch10_9 <= ch10_9_next;
        ch10_10 <= ch10_10_next;
        ch10_11 <= ch10_11_next;
        ch10_12 <= ch10_12_next;
        ch10_13 <= ch10_13_next;
        ch10_14 <= ch10_14_next;
        ch10_15 <= ch10_15_next;
        ch11_0 <= ch11_0_next;
        ch11_1 <= ch11_1_next;
        ch11_2 <= ch11_2_next;
        ch11_3 <= ch11_3_next;
        ch11_4 <= ch11_4_next;
        ch11_5 <= ch11_5_next;
        ch11_6 <= ch11_6_next;
        ch11_7 <= ch11_7_next;
        ch11_8 <= ch11_8_next;
        ch11_9 <= ch11_9_next;
        ch11_10 <= ch11_10_next;
        ch11_11 <= ch11_11_next;
        ch11_12 <= ch11_12_next;
        ch11_13 <= ch11_13_next;
        ch11_14 <= ch11_14_next;
        ch11_15 <= ch11_15_next;

        sram_wordmask_b <= sram_wordmask_b_next;
        sram_waddr_b <= sram_waddr_b_next;
        sram_wdata_b <= sram_wdata_b_next;
        sram_wen_b0 <= sram_wen_b0_next;
        sram_wen_b1 <= sram_wen_b1_next;
        sram_wen_b2 <= sram_wen_b2_next;
        sram_wen_b3 <= sram_wen_b3_next;
        valid <= valid_next;

    end
end

endmodule
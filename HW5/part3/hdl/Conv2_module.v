// 讀B寫A
module Conv2_module #(
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
// read data from SRAM group B
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b0_in,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b1_in,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b2_in,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b3_in,
// read address to parameter SRAM
output reg [9:0] sram_raddr_weight,
output reg [5:0] sram_raddr_bias,
// read address to SRAM group B
output reg [5:0] sram_raddr_b0,
output reg [5:0] sram_raddr_b1,
output reg [5:0] sram_raddr_b2,
output reg [5:0] sram_raddr_b3,
// write enable for SRAM groups A
output reg sram_wen_a0,
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,

output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a,
output reg [5:0] sram_waddr_a,
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a,
output reg valid
);

integer i;
// global state parameter
parameter IDLE = 4'd0, UNSHUFFLE = 4'd1, CONV1 = 4'd2, CONV2 = 4'd3, CONV3 = 4'd4, FINISH = 4'd5;

// local state parameter
reg [3-1:0] local_state, local_state_next;
localparam WAIT = 3'd0, READ_WEIGHT = 3'd1, READ_BIAS = 3'd2, CAL = 3'd3;

// input FF variables
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b0;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b1;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b2;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b3;

reg [6-1:0] read_weight_cnt, read_weight_cnt_next;
reg [4-1:0] read_bias_cnt, read_bias_cnt_next;
reg signed [BIAS_PER_ADDR*BW_PER_PARAM-1:0] bias00, bias01, bias02, bias03, bias04, bias05, bias06, bias07, bias08, bias09, bias10, bias11;
reg signed [BIAS_PER_ADDR*BW_PER_PARAM-1:0] bias00_next, bias01_next, bias02_next, bias03_next, bias04_next, bias05_next, bias06_next, bias07_next, bias08_next, bias09_next, bias10_next, bias11_next;

reg [8-1:0] conv_cnt, conv_cnt_next;
reg [2-1:0] three_cycle_cnt, three_cycle_cnt_next;
reg [5:0] sram_raddr_b0_next, sram_raddr_b1_next, sram_raddr_b2_next, sram_raddr_b3_next;
reg sram_wen_a0_next, sram_wen_a1_next, sram_wen_a2_next, sram_wen_a3_next;
reg valid_next;


reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight00_ch0, weight00_ch1, weight00_ch2, weight00_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight01_ch0, weight01_ch1, weight01_ch2, weight01_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight02_ch0, weight02_ch1, weight02_ch2, weight02_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight03_ch0, weight03_ch1, weight03_ch2, weight03_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight04_ch0, weight04_ch1, weight04_ch2, weight04_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight05_ch0, weight05_ch1, weight05_ch2, weight05_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight06_ch0, weight06_ch1, weight06_ch2, weight06_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight07_ch0, weight07_ch1, weight07_ch2, weight07_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight08_ch0, weight08_ch1, weight08_ch2, weight08_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight09_ch0, weight09_ch1, weight09_ch2, weight09_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight10_ch0, weight10_ch1, weight10_ch2, weight10_ch3;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight11_ch0, weight11_ch1, weight11_ch2, weight11_ch3;

reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight00_ch0_next, weight00_ch1_next, weight00_ch2_next, weight00_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight01_ch0_next, weight01_ch1_next, weight01_ch2_next, weight01_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight02_ch0_next, weight02_ch1_next, weight02_ch2_next, weight02_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight03_ch0_next, weight03_ch1_next, weight03_ch2_next, weight03_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight04_ch0_next, weight04_ch1_next, weight04_ch2_next, weight04_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight05_ch0_next, weight05_ch1_next, weight05_ch2_next, weight05_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight06_ch0_next, weight06_ch1_next, weight06_ch2_next, weight06_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight07_ch0_next, weight07_ch1_next, weight07_ch2_next, weight07_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight08_ch0_next, weight08_ch1_next, weight08_ch2_next, weight08_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight09_ch0_next, weight09_ch1_next, weight09_ch2_next, weight09_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight10_ch0_next, weight10_ch1_next, weight10_ch2_next, weight10_ch3_next;
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] weight11_ch0_next, weight11_ch1_next, weight11_ch2_next, weight11_ch3_next;

reg signed [BW_PER_PARAM-1:0] weight00_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight00_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight00_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight00_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight01_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight01_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight01_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight01_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight02_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight02_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight02_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight02_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight03_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight03_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight03_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight03_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight04_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight04_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight04_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight04_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight05_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight05_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight05_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight05_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight06_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight06_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight06_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight06_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight07_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight07_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight07_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight07_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight08_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight08_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight08_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight08_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight09_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight09_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight09_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight09_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight10_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight10_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight10_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight10_ch3_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight11_ch0_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight11_ch1_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight11_ch2_2D [0:WEIGHT_PER_ADDR-1];
reg signed [BW_PER_PARAM-1:0] weight11_ch3_2D [0:WEIGHT_PER_ADDR-1];

reg signed [12-1:0] ch0_15, ch0_14, ch0_13, ch0_12, ch0_11, ch0_10, ch0_9, ch0_8, ch0_7, ch0_6, ch0_5, ch0_4, ch0_3, ch0_2, ch0_1, ch0_0;
reg signed [12-1:0] ch1_15, ch1_14, ch1_13, ch1_12, ch1_11, ch1_10, ch1_9, ch1_8, ch1_7, ch1_6, ch1_5, ch1_4, ch1_3, ch1_2, ch1_1, ch1_0;
reg signed [12-1:0] ch2_15, ch2_14, ch2_13, ch2_12, ch2_11, ch2_10, ch2_9, ch2_8, ch2_7, ch2_6, ch2_5, ch2_4, ch2_3, ch2_2, ch2_1, ch2_0;
reg signed [12-1:0] ch3_15, ch3_14, ch3_13, ch3_12, ch3_11, ch3_10, ch3_9, ch3_8, ch3_7, ch3_6, ch3_5, ch3_4, ch3_3, ch3_2, ch3_1, ch3_0;

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

wire [8-1:0] conv_cnt_delay;
assign conv_cnt_delay = conv_cnt - 1;

reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_next;
reg [5:0] sram_waddr_a_next;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a_next;

// read weight counter
always @* begin
    if (local_state == READ_WEIGHT) begin
        read_weight_cnt_next = read_weight_cnt + 1;
    end
    else begin
        read_weight_cnt_next = read_weight_cnt;
    end
end

// set weight value
always @* begin
    weight00_ch0_next = weight00_ch0;
    weight00_ch1_next = weight00_ch1;
    weight00_ch2_next = weight00_ch2;
    weight00_ch3_next = weight00_ch3;
    weight01_ch0_next = weight01_ch0;
    weight01_ch1_next = weight01_ch1;
    weight01_ch2_next = weight01_ch2;
    weight01_ch3_next = weight01_ch3;
    weight02_ch0_next = weight02_ch0;
    weight02_ch1_next = weight02_ch1;
    weight02_ch2_next = weight02_ch2;
    weight02_ch3_next = weight02_ch3;
    weight03_ch0_next = weight03_ch0;
    weight03_ch1_next = weight03_ch1;
    weight03_ch2_next = weight03_ch2;
    weight03_ch3_next = weight03_ch3;
    weight04_ch0_next = weight04_ch0;
    weight04_ch1_next = weight04_ch1;
    weight04_ch2_next = weight04_ch2;
    weight04_ch3_next = weight04_ch3;
    weight05_ch0_next = weight05_ch0;
    weight05_ch1_next = weight05_ch1;
    weight05_ch2_next = weight05_ch2;
    weight05_ch3_next = weight05_ch3;
    weight06_ch0_next = weight06_ch0;
    weight06_ch1_next = weight06_ch1;
    weight06_ch2_next = weight06_ch2;
    weight06_ch3_next = weight06_ch3;
    weight07_ch0_next = weight07_ch0;
    weight07_ch1_next = weight07_ch1;
    weight07_ch2_next = weight07_ch2;
    weight07_ch3_next = weight07_ch3;
    weight08_ch0_next = weight08_ch0;
    weight08_ch1_next = weight08_ch1;
    weight08_ch2_next = weight08_ch2;
    weight08_ch3_next = weight08_ch3;
    weight09_ch0_next = weight09_ch0;
    weight09_ch1_next = weight09_ch1;
    weight09_ch2_next = weight09_ch2;
    weight09_ch3_next = weight09_ch3;
    weight10_ch0_next = weight10_ch0;
    weight10_ch1_next = weight10_ch1;
    weight10_ch2_next = weight10_ch2;
    weight10_ch3_next = weight10_ch3;
    weight11_ch0_next = weight11_ch0;
    weight11_ch1_next = weight11_ch1;
    weight11_ch2_next = weight11_ch2;
    weight11_ch3_next = weight11_ch3;

    if (local_state == READ_WEIGHT) begin
        if (read_weight_cnt == 6'd1)
            weight00_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd2)
            weight00_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd3)
            weight00_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd4)
            weight00_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd5)
            weight01_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd6)
            weight01_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd7)
            weight01_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd8)
            weight01_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd9)
            weight02_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd10)
            weight02_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd11)
            weight02_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd12)
            weight02_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd13)
            weight03_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd14)
            weight03_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd15)
            weight03_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd16)
            weight03_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd17)
            weight04_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd18)
            weight04_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd19)
            weight04_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd20)
            weight04_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd21)
            weight05_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd22)
            weight05_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd23)
            weight05_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd24)
            weight05_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd25)
            weight06_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd26)
            weight06_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd27)
            weight06_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd28)
            weight06_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd29)
            weight07_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd30)
            weight07_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd31)
            weight07_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd32)
            weight07_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd33)
            weight08_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd34)
            weight08_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd35)
            weight08_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd36)
            weight08_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd37)
            weight09_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd38)
            weight09_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd39)
            weight09_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd40)
            weight09_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd41)
            weight10_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd42)
            weight10_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd43)
            weight10_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd44)
            weight10_ch3_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd45)
            weight11_ch0_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd46)
            weight11_ch1_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd47)
            weight11_ch2_next = sram_rdata_weight;
        else if (read_weight_cnt == 6'd48)
            weight11_ch3_next = sram_rdata_weight;



    end
end

// read weight address
always @* begin
    sram_raddr_weight = read_weight_cnt + 16;
end


// weight splitter
always @* begin
    for (i = 0; i < 9; i = i + 1) begin
        weight00_ch0_2D[i] = weight00_ch0[8*i+:8];
        weight00_ch1_2D[i] = weight00_ch1[8*i+:8];
        weight00_ch2_2D[i] = weight00_ch2[8*i+:8];
        weight00_ch3_2D[i] = weight00_ch3[8*i+:8];
        weight01_ch0_2D[i] = weight01_ch0[8*i+:8];
        weight01_ch1_2D[i] = weight01_ch1[8*i+:8];
        weight01_ch2_2D[i] = weight01_ch2[8*i+:8];
        weight01_ch3_2D[i] = weight01_ch3[8*i+:8];
        weight02_ch0_2D[i] = weight02_ch0[8*i+:8];
        weight02_ch1_2D[i] = weight02_ch1[8*i+:8];
        weight02_ch2_2D[i] = weight02_ch2[8*i+:8];
        weight02_ch3_2D[i] = weight02_ch3[8*i+:8];
        weight03_ch0_2D[i] = weight03_ch0[8*i+:8];
        weight03_ch1_2D[i] = weight03_ch1[8*i+:8];
        weight03_ch2_2D[i] = weight03_ch2[8*i+:8];
        weight03_ch3_2D[i] = weight03_ch3[8*i+:8];
        weight04_ch0_2D[i] = weight04_ch0[8*i+:8];
        weight04_ch1_2D[i] = weight04_ch1[8*i+:8];
        weight04_ch2_2D[i] = weight04_ch2[8*i+:8];
        weight04_ch3_2D[i] = weight04_ch3[8*i+:8];
        weight05_ch0_2D[i] = weight05_ch0[8*i+:8];
        weight05_ch1_2D[i] = weight05_ch1[8*i+:8];
        weight05_ch2_2D[i] = weight05_ch2[8*i+:8];
        weight05_ch3_2D[i] = weight05_ch3[8*i+:8];
        weight06_ch0_2D[i] = weight06_ch0[8*i+:8];
        weight06_ch1_2D[i] = weight06_ch1[8*i+:8];
        weight06_ch2_2D[i] = weight06_ch2[8*i+:8];
        weight06_ch3_2D[i] = weight06_ch3[8*i+:8];
        weight07_ch0_2D[i] = weight07_ch0[8*i+:8];
        weight07_ch1_2D[i] = weight07_ch1[8*i+:8];
        weight07_ch2_2D[i] = weight07_ch2[8*i+:8];
        weight07_ch3_2D[i] = weight07_ch3[8*i+:8];
        weight08_ch0_2D[i] = weight08_ch0[8*i+:8];
        weight08_ch1_2D[i] = weight08_ch1[8*i+:8];
        weight08_ch2_2D[i] = weight08_ch2[8*i+:8];
        weight08_ch3_2D[i] = weight08_ch3[8*i+:8];
        weight09_ch0_2D[i] = weight09_ch0[8*i+:8];
        weight09_ch1_2D[i] = weight09_ch1[8*i+:8];
        weight09_ch2_2D[i] = weight09_ch2[8*i+:8];
        weight09_ch3_2D[i] = weight09_ch3[8*i+:8];
        weight10_ch0_2D[i] = weight10_ch0[8*i+:8];
        weight10_ch1_2D[i] = weight10_ch1[8*i+:8];
        weight10_ch2_2D[i] = weight10_ch2[8*i+:8];
        weight10_ch3_2D[i] = weight10_ch3[8*i+:8];
        weight11_ch0_2D[i] = weight11_ch0[8*i+:8];
        weight11_ch1_2D[i] = weight11_ch1[8*i+:8];
        weight11_ch2_2D[i] = weight11_ch2[8*i+:8];
        weight11_ch3_2D[i] = weight11_ch3[8*i+:8];
    end
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

// read bias address
always @* begin
    sram_raddr_bias = read_bias_cnt + 4;
end

// set bias value
always @* begin
    bias00_next = bias00;
    bias01_next = bias01;
    bias02_next = bias02;
    bias03_next = bias03;
    bias04_next = bias04;
    bias05_next = bias05;
    bias06_next = bias06;
    bias07_next = bias07;
    bias08_next = bias08;
    bias09_next = bias09;
    bias10_next = bias10;
    bias11_next = bias11;
    if (local_state == READ_BIAS) begin
        case (read_bias_cnt)
            4'd1: bias00_next = sram_rdata_bias;
            4'd2: bias01_next = sram_rdata_bias;
            4'd3: bias02_next = sram_rdata_bias;
            4'd4: bias03_next = sram_rdata_bias;
            4'd5: bias04_next = sram_rdata_bias;
            4'd6: bias05_next = sram_rdata_bias;
            4'd7: bias06_next = sram_rdata_bias;
            4'd8: bias07_next = sram_rdata_bias;
            4'd9: bias08_next = sram_rdata_bias;
            4'd10: bias09_next = sram_rdata_bias;
            4'd11: bias10_next = sram_rdata_bias;
            4'd12: bias11_next = sram_rdata_bias;
        endcase
    end
end

// conv counter
always @* begin
    if (local_state == CAL) begin
        if (three_cycle_cnt == 2) begin
            conv_cnt_next = conv_cnt + 1;
        end
        else begin
            conv_cnt_next = conv_cnt;
        end
    end
    else begin
        conv_cnt_next = conv_cnt;
    end
end

// three cycle counter
always @* begin
    if (local_state == CAL) begin
        if (three_cycle_cnt == 2) begin
            three_cycle_cnt_next = 0;
        end
        else begin
            three_cycle_cnt_next = three_cycle_cnt + 1;
        end
    end
    else begin
        three_cycle_cnt_next = three_cycle_cnt;
    end
end

// set sram_raddr_b0_next ~ sram_raddr_b3_next
always @* begin
    case (conv_cnt) 
        8'd0: begin
            sram_raddr_b0_next = 0;
            sram_raddr_b1_next = 0;
            sram_raddr_b2_next = 0;
            sram_raddr_b3_next = 0;
        end
        8'd1: begin
            sram_raddr_b0_next = 1;
            sram_raddr_b1_next = 0;
            sram_raddr_b2_next = 1;
            sram_raddr_b3_next = 0;
        end
        8'd2: begin
            sram_raddr_b0_next = 1;
            sram_raddr_b1_next = 1;
            sram_raddr_b2_next = 1;
            sram_raddr_b3_next = 1;
        end
        8'd3: begin
            sram_raddr_b0_next = 2;
            sram_raddr_b1_next = 1;
            sram_raddr_b2_next = 2;
            sram_raddr_b3_next = 1;
        end
        8'd4: begin
            sram_raddr_b0_next = 2;
            sram_raddr_b1_next = 2;
            sram_raddr_b2_next = 2;
            sram_raddr_b3_next = 2;
        end
        8'd5: begin
            sram_raddr_b0_next = 6;
            sram_raddr_b1_next = 6;
            sram_raddr_b2_next = 0;
            sram_raddr_b3_next = 0;
        end
        8'd6: begin
            sram_raddr_b0_next = 7;
            sram_raddr_b1_next = 6;
            sram_raddr_b2_next = 1;
            sram_raddr_b3_next = 0;
        end
        8'd7: begin
            sram_raddr_b0_next = 7;
            sram_raddr_b1_next = 7;
            sram_raddr_b2_next = 1;
            sram_raddr_b3_next = 1;
        end
        8'd8: begin
            sram_raddr_b0_next = 8;
            sram_raddr_b1_next = 7;
            sram_raddr_b2_next = 2;
            sram_raddr_b3_next = 1;
        end
        8'd9: begin
            sram_raddr_b0_next = 8;
            sram_raddr_b1_next = 8;
            sram_raddr_b2_next = 2;
            sram_raddr_b3_next = 2;
        end
        8'd10: begin
            sram_raddr_b0_next = 6;
            sram_raddr_b1_next = 6;
            sram_raddr_b2_next = 6;
            sram_raddr_b3_next = 6;
        end
        8'd11: begin
            sram_raddr_b0_next = 7;
            sram_raddr_b1_next = 6;
            sram_raddr_b2_next = 7;
            sram_raddr_b3_next = 6;
        end
        8'd12: begin
            sram_raddr_b0_next = 7;
            sram_raddr_b1_next = 7;
            sram_raddr_b2_next = 7;
            sram_raddr_b3_next = 7;
        end
        8'd13: begin
            sram_raddr_b0_next = 8;
            sram_raddr_b1_next = 7;
            sram_raddr_b2_next = 8;
            sram_raddr_b3_next = 7;
        end
        8'd14: begin
            sram_raddr_b0_next = 8;
            sram_raddr_b1_next = 8;
            sram_raddr_b2_next = 8;
            sram_raddr_b3_next = 8;
        end
        8'd15: begin
            sram_raddr_b0_next = 12;
            sram_raddr_b1_next = 12;
            sram_raddr_b2_next = 6;
            sram_raddr_b3_next = 6;
        end
        8'd16: begin
            sram_raddr_b0_next = 13;
            sram_raddr_b1_next = 12;
            sram_raddr_b2_next = 7;
            sram_raddr_b3_next = 6;
        end
        8'd17: begin
            sram_raddr_b0_next = 13;
            sram_raddr_b1_next = 13;
            sram_raddr_b2_next = 7;
            sram_raddr_b3_next = 7;
        end
        8'd18: begin
            sram_raddr_b0_next = 14;
            sram_raddr_b1_next = 13;
            sram_raddr_b2_next = 8;
            sram_raddr_b3_next = 7;
        end
        8'd19: begin
            sram_raddr_b0_next = 14;
            sram_raddr_b1_next = 14;
            sram_raddr_b2_next = 8;
            sram_raddr_b3_next = 8;
        end
        8'd20: begin
            sram_raddr_b0_next = 12;
            sram_raddr_b1_next = 12;
            sram_raddr_b2_next = 12;
            sram_raddr_b3_next = 12;
        end
        8'd21: begin
            sram_raddr_b0_next = 13;
            sram_raddr_b1_next = 12;
            sram_raddr_b2_next = 13;
            sram_raddr_b3_next = 12;
        end
        8'd22: begin
            sram_raddr_b0_next = 13;
            sram_raddr_b1_next = 13;
            sram_raddr_b2_next = 13;
            sram_raddr_b3_next = 13;
        end
        8'd23: begin
            sram_raddr_b0_next = 14;
            sram_raddr_b1_next = 13;
            sram_raddr_b2_next = 14;
            sram_raddr_b3_next = 13;
        end
        8'd24: begin
            sram_raddr_b0_next = 14;
            sram_raddr_b1_next = 14;
            sram_raddr_b2_next = 14;
            sram_raddr_b3_next = 14;
        end
        default: begin
            sram_raddr_b0_next = 0;
            sram_raddr_b1_next = 0;
            sram_raddr_b2_next = 0;
            sram_raddr_b3_next = 0;
        end

    endcase
end

// sram data splitter and write enable next
always @* begin
    sram_wen_a0_next = sram_wen_a0;
    sram_wen_a1_next = sram_wen_a1;
    sram_wen_a2_next = sram_wen_a2;
    sram_wen_a3_next = sram_wen_a3;
    if (conv_cnt_delay == 0 || conv_cnt_delay == 2 || conv_cnt_delay == 4 || conv_cnt_delay == 10 || conv_cnt_delay == 12 || conv_cnt_delay == 14 || conv_cnt_delay == 20 || conv_cnt_delay == 22 || conv_cnt_delay == 24) begin
        sram_wen_a0_next = 0;
        sram_wen_a1_next = 1;
        sram_wen_a2_next = 1;
        sram_wen_a3_next = 1;

        ch0_15 = sram_rdata_b0[191:180];
        ch0_14 = sram_rdata_b0[179:168];
        ch0_13 = sram_rdata_b1[191:180];
        ch0_12 = sram_rdata_b1[179:168];
        ch0_11 = sram_rdata_b0[167:156];
        ch0_10 = sram_rdata_b0[155:144];
        ch0_9  = sram_rdata_b1[167:156];
        ch0_8  = sram_rdata_b1[155:144];
        ch0_7  = sram_rdata_b2[191:180];
        ch0_6  = sram_rdata_b2[179:168];
        ch0_5  = sram_rdata_b3[191:180];
        ch0_4  = sram_rdata_b3[179:168];
        ch0_3  = sram_rdata_b2[167:156];
        ch0_2  = sram_rdata_b2[155:144];
        ch0_1  = sram_rdata_b3[167:156];
        ch0_0  = sram_rdata_b3[155:144];

        ch1_15 = sram_rdata_b0[191-48:180-48];
        ch1_14 = sram_rdata_b0[179-48:168-48];
        ch1_13 = sram_rdata_b1[191-48:180-48];
        ch1_12 = sram_rdata_b1[179-48:168-48];
        ch1_11 = sram_rdata_b0[167-48:156-48];
        ch1_10 = sram_rdata_b0[155-48:144-48];
        ch1_9  = sram_rdata_b1[167-48:156-48];
        ch1_8  = sram_rdata_b1[155-48:144-48];
        ch1_7  = sram_rdata_b2[191-48:180-48];
        ch1_6  = sram_rdata_b2[179-48:168-48];
        ch1_5  = sram_rdata_b3[191-48:180-48];
        ch1_4  = sram_rdata_b3[179-48:168-48];
        ch1_3  = sram_rdata_b2[167-48:156-48];
        ch1_2  = sram_rdata_b2[155-48:144-48];
        ch1_1  = sram_rdata_b3[167-48:156-48];
        ch1_0  = sram_rdata_b3[155-48:144-48];

        ch2_15 = sram_rdata_b0[191-96:180-96];
        ch2_14 = sram_rdata_b0[179-96:168-96];
        ch2_13 = sram_rdata_b1[191-96:180-96];
        ch2_12 = sram_rdata_b1[179-96:168-96];
        ch2_11 = sram_rdata_b0[167-96:156-96];
        ch2_10 = sram_rdata_b0[155-96:144-96];
        ch2_9  = sram_rdata_b1[167-96:156-96];
        ch2_8  = sram_rdata_b1[155-96:144-96];
        ch2_7  = sram_rdata_b2[191-96:180-96];
        ch2_6  = sram_rdata_b2[179-96:168-96];
        ch2_5  = sram_rdata_b3[191-96:180-96];
        ch2_4  = sram_rdata_b3[179-96:168-96];
        ch2_3  = sram_rdata_b2[167-96:156-96];
        ch2_2  = sram_rdata_b2[155-96:144-96];
        ch2_1  = sram_rdata_b3[167-96:156-96];
        ch2_0  = sram_rdata_b3[155-96:144-96];

        ch3_15 = sram_rdata_b0[191-144:180-144];
        ch3_14 = sram_rdata_b0[179-144:168-144];
        ch3_13 = sram_rdata_b1[191-144:180-144];
        ch3_12 = sram_rdata_b1[179-144:168-144];
        ch3_11 = sram_rdata_b0[167-144:156-144];
        ch3_10 = sram_rdata_b0[155-144:144-144];
        ch3_9  = sram_rdata_b1[167-144:156-144];
        ch3_8  = sram_rdata_b1[155-144:144-144];
        ch3_7  = sram_rdata_b2[191-144:180-144];
        ch3_6  = sram_rdata_b2[179-144:168-144];
        ch3_5  = sram_rdata_b3[191-144:180-144];
        ch3_4  = sram_rdata_b3[179-144:168-144];
        ch3_3  = sram_rdata_b2[167-144:156-144];
        ch3_2  = sram_rdata_b2[155-144:144-144];
        ch3_1  = sram_rdata_b3[167-144:156-144];
        ch3_0  = sram_rdata_b3[155-144:144-144];
    end
    else if (conv_cnt_delay == 1 || conv_cnt_delay == 3 || conv_cnt_delay == 11 || conv_cnt_delay == 13 || conv_cnt_delay == 21 || conv_cnt_delay == 23) begin
        sram_wen_a0_next = 1;
        sram_wen_a1_next = 0;
        sram_wen_a2_next = 1;
        sram_wen_a3_next = 1;

        ch0_15 = sram_rdata_b1[191:180];
        ch0_14 = sram_rdata_b1[179:168];
        ch0_13 = sram_rdata_b0[191:180];
        ch0_12 = sram_rdata_b0[179:168];
        ch0_11 = sram_rdata_b1[167:156];
        ch0_10 = sram_rdata_b1[155:144];
        ch0_9  = sram_rdata_b0[167:156];
        ch0_8  = sram_rdata_b0[155:144];
        ch0_7  = sram_rdata_b3[191:180];
        ch0_6  = sram_rdata_b3[179:168];
        ch0_5  = sram_rdata_b2[191:180];
        ch0_4  = sram_rdata_b2[179:168];
        ch0_3  = sram_rdata_b3[167:156];
        ch0_2  = sram_rdata_b3[155:144];
        ch0_1  = sram_rdata_b2[167:156];
        ch0_0  = sram_rdata_b2[155:144];

        ch1_15 = sram_rdata_b1[191-48:180-48];
        ch1_14 = sram_rdata_b1[179-48:168-48];
        ch1_13 = sram_rdata_b0[191-48:180-48];
        ch1_12 = sram_rdata_b0[179-48:168-48];
        ch1_11 = sram_rdata_b1[167-48:156-48];
        ch1_10 = sram_rdata_b1[155-48:144-48];
        ch1_9  = sram_rdata_b0[167-48:156-48];
        ch1_8  = sram_rdata_b0[155-48:144-48];
        ch1_7  = sram_rdata_b3[191-48:180-48];
        ch1_6  = sram_rdata_b3[179-48:168-48];
        ch1_5  = sram_rdata_b2[191-48:180-48];
        ch1_4  = sram_rdata_b2[179-48:168-48];
        ch1_3  = sram_rdata_b3[167-48:156-48];
        ch1_2  = sram_rdata_b3[155-48:144-48];
        ch1_1  = sram_rdata_b2[167-48:156-48];
        ch1_0  = sram_rdata_b2[155-48:144-48];

        ch2_15 = sram_rdata_b1[191-96:180-96];
        ch2_14 = sram_rdata_b1[179-96:168-96];
        ch2_13 = sram_rdata_b0[191-96:180-96];
        ch2_12 = sram_rdata_b0[179-96:168-96];
        ch2_11 = sram_rdata_b1[167-96:156-96];
        ch2_10 = sram_rdata_b1[155-96:144-96];
        ch2_9  = sram_rdata_b0[167-96:156-96];
        ch2_8  = sram_rdata_b0[155-96:144-96];
        ch2_7  = sram_rdata_b3[191-96:180-96];
        ch2_6  = sram_rdata_b3[179-96:168-96];
        ch2_5  = sram_rdata_b2[191-96:180-96];
        ch2_4  = sram_rdata_b2[179-96:168-96];
        ch2_3  = sram_rdata_b3[167-96:156-96];
        ch2_2  = sram_rdata_b3[155-96:144-96];
        ch2_1  = sram_rdata_b2[167-96:156-96];
        ch2_0  = sram_rdata_b2[155-96:144-96];

        ch3_15 = sram_rdata_b1[191-144:180-144];
        ch3_14 = sram_rdata_b1[179-144:168-144];
        ch3_13 = sram_rdata_b0[191-144:180-144];
        ch3_12 = sram_rdata_b0[179-144:168-144];
        ch3_11 = sram_rdata_b1[167-144:156-144];
        ch3_10 = sram_rdata_b1[155-144:144-144];
        ch3_9  = sram_rdata_b0[167-144:156-144];
        ch3_8  = sram_rdata_b0[155-144:144-144];
        ch3_7  = sram_rdata_b3[191-144:180-144];
        ch3_6  = sram_rdata_b3[179-144:168-144];
        ch3_5  = sram_rdata_b2[191-144:180-144];
        ch3_4  = sram_rdata_b2[179-144:168-144];
        ch3_3  = sram_rdata_b3[167-144:156-144];
        ch3_2  = sram_rdata_b3[155-144:144-144];
        ch3_1  = sram_rdata_b2[167-144:156-144];
        ch3_0  = sram_rdata_b2[155-144:144-144];
    end
    else if (conv_cnt_delay == 5 || conv_cnt_delay == 7 || conv_cnt_delay == 9 || conv_cnt_delay == 15 || conv_cnt_delay == 17 || conv_cnt_delay == 19) begin
        sram_wen_a0_next = 1;
        sram_wen_a1_next = 1;
        sram_wen_a2_next = 0;
        sram_wen_a3_next = 1;

        ch0_15 = sram_rdata_b2[191:180];
        ch0_14 = sram_rdata_b2[179:168];
        ch0_13 = sram_rdata_b3[191:180];
        ch0_12 = sram_rdata_b3[179:168];
        ch0_11 = sram_rdata_b2[167:156];
        ch0_10 = sram_rdata_b2[155:144];
        ch0_9  = sram_rdata_b3[167:156];
        ch0_8  = sram_rdata_b3[155:144];
        ch0_7  = sram_rdata_b0[191:180];
        ch0_6  = sram_rdata_b0[179:168];
        ch0_5  = sram_rdata_b1[191:180];
        ch0_4  = sram_rdata_b1[179:168];
        ch0_3  = sram_rdata_b0[167:156];
        ch0_2  = sram_rdata_b0[155:144];
        ch0_1  = sram_rdata_b1[167:156];
        ch0_0  = sram_rdata_b1[155:144];

        ch1_15 = sram_rdata_b2[191-48:180-48];
        ch1_14 = sram_rdata_b2[179-48:168-48];
        ch1_13 = sram_rdata_b3[191-48:180-48];
        ch1_12 = sram_rdata_b3[179-48:168-48];
        ch1_11 = sram_rdata_b2[167-48:156-48];
        ch1_10 = sram_rdata_b2[155-48:144-48];
        ch1_9  = sram_rdata_b3[167-48:156-48];
        ch1_8  = sram_rdata_b3[155-48:144-48];
        ch1_7  = sram_rdata_b0[191-48:180-48];
        ch1_6  = sram_rdata_b0[179-48:168-48];
        ch1_5  = sram_rdata_b1[191-48:180-48];
        ch1_4  = sram_rdata_b1[179-48:168-48];
        ch1_3  = sram_rdata_b0[167-48:156-48];
        ch1_2  = sram_rdata_b0[155-48:144-48];
        ch1_1  = sram_rdata_b1[167-48:156-48];
        ch1_0  = sram_rdata_b1[155-48:144-48];

        ch2_15 = sram_rdata_b2[191-96:180-96];
        ch2_14 = sram_rdata_b2[179-96:168-96];
        ch2_13 = sram_rdata_b3[191-96:180-96];
        ch2_12 = sram_rdata_b3[179-96:168-96];
        ch2_11 = sram_rdata_b2[167-96:156-96];
        ch2_10 = sram_rdata_b2[155-96:144-96];
        ch2_9  = sram_rdata_b3[167-96:156-96];
        ch2_8  = sram_rdata_b3[155-96:144-96];
        ch2_7  = sram_rdata_b0[191-96:180-96];
        ch2_6  = sram_rdata_b0[179-96:168-96];
        ch2_5  = sram_rdata_b1[191-96:180-96];
        ch2_4  = sram_rdata_b1[179-96:168-96];
        ch2_3  = sram_rdata_b0[167-96:156-96];
        ch2_2  = sram_rdata_b0[155-96:144-96];
        ch2_1  = sram_rdata_b1[167-96:156-96];
        ch2_0  = sram_rdata_b1[155-96:144-96];

        ch3_15 = sram_rdata_b2[191-144:180-144];
        ch3_14 = sram_rdata_b2[179-144:168-144];
        ch3_13 = sram_rdata_b3[191-144:180-144];
        ch3_12 = sram_rdata_b3[179-144:168-144];
        ch3_11 = sram_rdata_b2[167-144:156-144];
        ch3_10 = sram_rdata_b2[155-144:144-144];
        ch3_9  = sram_rdata_b3[167-144:156-144];
        ch3_8  = sram_rdata_b3[155-144:144-144];
        ch3_7  = sram_rdata_b0[191-144:180-144];
        ch3_6  = sram_rdata_b0[179-144:168-144];
        ch3_5  = sram_rdata_b1[191-144:180-144];
        ch3_4  = sram_rdata_b1[179-144:168-144];
        ch3_3  = sram_rdata_b0[167-144:156-144];
        ch3_2  = sram_rdata_b0[155-144:144-144];
        ch3_1  = sram_rdata_b1[167-144:156-144];
        ch3_0  = sram_rdata_b1[155-144:144-144];
    end
    else if (conv_cnt_delay == 6 || conv_cnt_delay == 8 || conv_cnt_delay == 16 || conv_cnt_delay == 18) begin
        sram_wen_a0_next = 1;
        sram_wen_a1_next = 1;
        sram_wen_a2_next = 1;
        sram_wen_a3_next = 0;

        ch0_15 = sram_rdata_b3[191:180];
        ch0_14 = sram_rdata_b3[179:168];
        ch0_13 = sram_rdata_b2[191:180];
        ch0_12 = sram_rdata_b2[179:168];
        ch0_11 = sram_rdata_b3[167:156];
        ch0_10 = sram_rdata_b3[155:144];
        ch0_9  = sram_rdata_b2[167:156];
        ch0_8  = sram_rdata_b2[155:144];
        ch0_7  = sram_rdata_b1[191:180];
        ch0_6  = sram_rdata_b1[179:168];
        ch0_5  = sram_rdata_b0[191:180];
        ch0_4  = sram_rdata_b0[179:168];
        ch0_3  = sram_rdata_b1[167:156];
        ch0_2  = sram_rdata_b1[155:144];
        ch0_1  = sram_rdata_b0[167:156];
        ch0_0  = sram_rdata_b0[155:144];

        ch1_15 = sram_rdata_b3[191-48:180-48];
        ch1_14 = sram_rdata_b3[179-48:168-48];
        ch1_13 = sram_rdata_b2[191-48:180-48];
        ch1_12 = sram_rdata_b2[179-48:168-48];
        ch1_11 = sram_rdata_b3[167-48:156-48];
        ch1_10 = sram_rdata_b3[155-48:144-48];
        ch1_9  = sram_rdata_b2[167-48:156-48];
        ch1_8  = sram_rdata_b2[155-48:144-48];
        ch1_7  = sram_rdata_b1[191-48:180-48];
        ch1_6  = sram_rdata_b1[179-48:168-48];
        ch1_5  = sram_rdata_b0[191-48:180-48];
        ch1_4  = sram_rdata_b0[179-48:168-48];
        ch1_3  = sram_rdata_b1[167-48:156-48];
        ch1_2  = sram_rdata_b1[155-48:144-48];
        ch1_1  = sram_rdata_b0[167-48:156-48];
        ch1_0  = sram_rdata_b0[155-48:144-48];

        ch2_15 = sram_rdata_b3[191-96:180-96];
        ch2_14 = sram_rdata_b3[179-96:168-96];
        ch2_13 = sram_rdata_b2[191-96:180-96];
        ch2_12 = sram_rdata_b2[179-96:168-96];
        ch2_11 = sram_rdata_b3[167-96:156-96];
        ch2_10 = sram_rdata_b3[155-96:144-96];
        ch2_9  = sram_rdata_b2[167-96:156-96];
        ch2_8  = sram_rdata_b2[155-96:144-96];
        ch2_7  = sram_rdata_b1[191-96:180-96];
        ch2_6  = sram_rdata_b1[179-96:168-96];
        ch2_5  = sram_rdata_b0[191-96:180-96];
        ch2_4  = sram_rdata_b0[179-96:168-96];
        ch2_3  = sram_rdata_b1[167-96:156-96];
        ch2_2  = sram_rdata_b1[155-96:144-96];
        ch2_1  = sram_rdata_b0[167-96:156-96];
        ch2_0  = sram_rdata_b0[155-96:144-96];

        ch3_15 = sram_rdata_b3[191-144:180-144];
        ch3_14 = sram_rdata_b3[179-144:168-144];
        ch3_13 = sram_rdata_b2[191-144:180-144];
        ch3_12 = sram_rdata_b2[179-144:168-144];
        ch3_11 = sram_rdata_b3[167-144:156-144];
        ch3_10 = sram_rdata_b3[155-144:144-144];
        ch3_9  = sram_rdata_b2[167-144:156-144];
        ch3_8  = sram_rdata_b2[155-144:144-144];
        ch3_7  = sram_rdata_b1[191-144:180-144];
        ch3_6  = sram_rdata_b1[179-144:168-144];
        ch3_5  = sram_rdata_b0[191-144:180-144];
        ch3_4  = sram_rdata_b0[179-144:168-144];
        ch3_3  = sram_rdata_b1[167-144:156-144];
        ch3_2  = sram_rdata_b1[155-144:144-144];
        ch3_1  = sram_rdata_b0[167-144:156-144];
        ch3_0  = sram_rdata_b0[155-144:144-144];
    end
    // avoid latch
    else begin
        sram_wen_a0_next = 0;
        sram_wen_a1_next = 1;
        sram_wen_a2_next = 1;
        sram_wen_a3_next = 1;

        ch0_15 = sram_rdata_b0[191:180];
        ch0_14 = sram_rdata_b0[179:168];
        ch0_13 = sram_rdata_b1[191:180];
        ch0_12 = sram_rdata_b1[179:168];
        ch0_11 = sram_rdata_b0[167:156];
        ch0_10 = sram_rdata_b0[155:144];
        ch0_9  = sram_rdata_b1[167:156];
        ch0_8  = sram_rdata_b1[155:144];
        ch0_7  = sram_rdata_b2[191:180];
        ch0_6  = sram_rdata_b2[179:168];
        ch0_5  = sram_rdata_b3[191:180];
        ch0_4  = sram_rdata_b3[179:168];
        ch0_3  = sram_rdata_b2[167:156];
        ch0_2  = sram_rdata_b2[155:144];
        ch0_1  = sram_rdata_b3[167:156];
        ch0_0  = sram_rdata_b3[155:144];

        ch1_15 = sram_rdata_b0[191-48:180-48];
        ch1_14 = sram_rdata_b0[179-48:168-48];
        ch1_13 = sram_rdata_b1[191-48:180-48];
        ch1_12 = sram_rdata_b1[179-48:168-48];
        ch1_11 = sram_rdata_b0[167-48:156-48];
        ch1_10 = sram_rdata_b0[155-48:144-48];
        ch1_9  = sram_rdata_b1[167-48:156-48];
        ch1_8  = sram_rdata_b1[155-48:144-48];
        ch1_7  = sram_rdata_b2[191-48:180-48];
        ch1_6  = sram_rdata_b2[179-48:168-48];
        ch1_5  = sram_rdata_b3[191-48:180-48];
        ch1_4  = sram_rdata_b3[179-48:168-48];
        ch1_3  = sram_rdata_b2[167-48:156-48];
        ch1_2  = sram_rdata_b2[155-48:144-48];
        ch1_1  = sram_rdata_b3[167-48:156-48];
        ch1_0  = sram_rdata_b3[155-48:144-48];

        ch2_15 = sram_rdata_b0[191-96:180-96];
        ch2_14 = sram_rdata_b0[179-96:168-96];
        ch2_13 = sram_rdata_b1[191-96:180-96];
        ch2_12 = sram_rdata_b1[179-96:168-96];
        ch2_11 = sram_rdata_b0[167-96:156-96];
        ch2_10 = sram_rdata_b0[155-96:144-96];
        ch2_9  = sram_rdata_b1[167-96:156-96];
        ch2_8  = sram_rdata_b1[155-96:144-96];
        ch2_7  = sram_rdata_b2[191-96:180-96];
        ch2_6  = sram_rdata_b2[179-96:168-96];
        ch2_5  = sram_rdata_b3[191-96:180-96];
        ch2_4  = sram_rdata_b3[179-96:168-96];
        ch2_3  = sram_rdata_b2[167-96:156-96];
        ch2_2  = sram_rdata_b2[155-96:144-96];
        ch2_1  = sram_rdata_b3[167-96:156-96];
        ch2_0  = sram_rdata_b3[155-96:144-96];

        ch3_15 = sram_rdata_b0[191-144:180-144];
        ch3_14 = sram_rdata_b0[179-144:168-144];
        ch3_13 = sram_rdata_b1[191-144:180-144];
        ch3_12 = sram_rdata_b1[179-144:168-144];
        ch3_11 = sram_rdata_b0[167-144:156-144];
        ch3_10 = sram_rdata_b0[155-144:144-144];
        ch3_9  = sram_rdata_b1[167-144:156-144];
        ch3_8  = sram_rdata_b1[155-144:144-144];
        ch3_7  = sram_rdata_b2[191-144:180-144];
        ch3_6  = sram_rdata_b2[179-144:168-144];
        ch3_5  = sram_rdata_b3[191-144:180-144];
        ch3_4  = sram_rdata_b3[179-144:168-144];
        ch3_3  = sram_rdata_b2[167-144:156-144];
        ch3_2  = sram_rdata_b2[155-144:144-144];
        ch3_1  = sram_rdata_b3[167-144:156-144];
        ch3_0  = sram_rdata_b3[155-144:144-144];
    end
end


// convolution
always @* begin
    case (three_cycle_cnt)
        2'd0: begin
            origin_sum3_ch0 = ch0_15 * weight00_ch0_2D[8] + ch0_14 * weight00_ch0_2D[7] + ch0_13 * weight00_ch0_2D[6]
                            + ch0_11 * weight00_ch0_2D[5] + ch0_10 * weight00_ch0_2D[4] + ch0_9  * weight00_ch0_2D[3]
                            + ch0_7  * weight00_ch0_2D[2] + ch0_6  * weight00_ch0_2D[1] + ch0_5  * weight00_ch0_2D[0]
                            + ch1_15 * weight00_ch1_2D[8] + ch1_14 * weight00_ch1_2D[7] + ch1_13 * weight00_ch1_2D[6]
                            + ch1_11 * weight00_ch1_2D[5] + ch1_10 * weight00_ch1_2D[4] + ch1_9  * weight00_ch1_2D[3]
                            + ch1_7  * weight00_ch1_2D[2] + ch1_6  * weight00_ch1_2D[1] + ch1_5  * weight00_ch1_2D[0]
                            + ch2_15 * weight00_ch2_2D[8] + ch2_14 * weight00_ch2_2D[7] + ch2_13 * weight00_ch2_2D[6]
                            + ch2_11 * weight00_ch2_2D[5] + ch2_10 * weight00_ch2_2D[4] + ch2_9  * weight00_ch2_2D[3]
                            + ch2_7  * weight00_ch2_2D[2] + ch2_6  * weight00_ch2_2D[1] + ch2_5  * weight00_ch2_2D[0]
                            + ch3_15 * weight00_ch3_2D[8] + ch3_14 * weight00_ch3_2D[7] + ch3_13 * weight00_ch3_2D[6]
                            + ch3_11 * weight00_ch3_2D[5] + ch3_10 * weight00_ch3_2D[4] + ch3_9  * weight00_ch3_2D[3]
                            + ch3_7  * weight00_ch3_2D[2] + ch3_6  * weight00_ch3_2D[1] + ch3_5  * weight00_ch3_2D[0];

            origin_sum2_ch0 = ch0_14 * weight00_ch0_2D[8] + ch0_13 * weight00_ch0_2D[7] + ch0_12 * weight00_ch0_2D[6]
                            + ch0_10 * weight00_ch0_2D[5] + ch0_9  * weight00_ch0_2D[4] + ch0_8  * weight00_ch0_2D[3]
                            + ch0_6  * weight00_ch0_2D[2] + ch0_5  * weight00_ch0_2D[1] + ch0_4  * weight00_ch0_2D[0]
                            + ch1_14 * weight00_ch1_2D[8] + ch1_13 * weight00_ch1_2D[7] + ch1_12 * weight00_ch1_2D[6]
                            + ch1_10 * weight00_ch1_2D[5] + ch1_9  * weight00_ch1_2D[4] + ch1_8  * weight00_ch1_2D[3]
                            + ch1_6  * weight00_ch1_2D[2] + ch1_5  * weight00_ch1_2D[1] + ch1_4  * weight00_ch1_2D[0]
                            + ch2_14 * weight00_ch2_2D[8] + ch2_13 * weight00_ch2_2D[7] + ch2_12 * weight00_ch2_2D[6]
                            + ch2_10 * weight00_ch2_2D[5] + ch2_9  * weight00_ch2_2D[4] + ch2_8  * weight00_ch2_2D[3]
                            + ch2_6  * weight00_ch2_2D[2] + ch2_5  * weight00_ch2_2D[1] + ch2_4  * weight00_ch2_2D[0]
                            + ch3_14 * weight00_ch3_2D[8] + ch3_13 * weight00_ch3_2D[7] + ch3_12 * weight00_ch3_2D[6]
                            + ch3_10 * weight00_ch3_2D[5] + ch3_9  * weight00_ch3_2D[4] + ch3_8  * weight00_ch3_2D[3]
                            + ch3_6  * weight00_ch3_2D[2] + ch3_5  * weight00_ch3_2D[1] + ch3_4  * weight00_ch3_2D[0];

            origin_sum1_ch0 = ch0_11 * weight00_ch0_2D[8] + ch0_10 * weight00_ch0_2D[7] + ch0_9  * weight00_ch0_2D[6]
                            + ch0_7  * weight00_ch0_2D[5] + ch0_6  * weight00_ch0_2D[4] + ch0_5  * weight00_ch0_2D[3]
                            + ch0_3  * weight00_ch0_2D[2] + ch0_2  * weight00_ch0_2D[1] + ch0_1  * weight00_ch0_2D[0]
                            + ch1_11 * weight00_ch1_2D[8] + ch1_10 * weight00_ch1_2D[7] + ch1_9  * weight00_ch1_2D[6]
                            + ch1_7  * weight00_ch1_2D[5] + ch1_6  * weight00_ch1_2D[4] + ch1_5  * weight00_ch1_2D[3]
                            + ch1_3  * weight00_ch1_2D[2] + ch1_2  * weight00_ch1_2D[1] + ch1_1  * weight00_ch1_2D[0]
                            + ch2_11 * weight00_ch2_2D[8] + ch2_10 * weight00_ch2_2D[7] + ch2_9  * weight00_ch2_2D[6]
                            + ch2_7  * weight00_ch2_2D[5] + ch2_6  * weight00_ch2_2D[4] + ch2_5  * weight00_ch2_2D[3]
                            + ch2_3  * weight00_ch2_2D[2] + ch2_2  * weight00_ch2_2D[1] + ch2_1  * weight00_ch2_2D[0]
                            + ch3_11 * weight00_ch3_2D[8] + ch3_10 * weight00_ch3_2D[7] + ch3_9  * weight00_ch3_2D[6]
                            + ch3_7  * weight00_ch3_2D[5] + ch3_6  * weight00_ch3_2D[4] + ch3_5  * weight00_ch3_2D[3]
                            + ch3_3  * weight00_ch3_2D[2] + ch3_2  * weight00_ch3_2D[1] + ch3_1  * weight00_ch3_2D[0];

            origin_sum0_ch0 = ch0_10 * weight00_ch0_2D[8] + ch0_9  * weight00_ch0_2D[7] + ch0_8  * weight00_ch0_2D[6]
                            + ch0_6  * weight00_ch0_2D[5] + ch0_5  * weight00_ch0_2D[4] + ch0_4  * weight00_ch0_2D[3]
                            + ch0_2  * weight00_ch0_2D[2] + ch0_1  * weight00_ch0_2D[1] + ch0_0  * weight00_ch0_2D[0]
                            + ch1_10 * weight00_ch1_2D[8] + ch1_9  * weight00_ch1_2D[7] + ch1_8  * weight00_ch1_2D[6]
                            + ch1_6  * weight00_ch1_2D[5] + ch1_5  * weight00_ch1_2D[4] + ch1_4  * weight00_ch1_2D[3]
                            + ch1_2  * weight00_ch1_2D[2] + ch1_1  * weight00_ch1_2D[1] + ch1_0  * weight00_ch1_2D[0]
                            + ch2_10 * weight00_ch2_2D[8] + ch2_9  * weight00_ch2_2D[7] + ch2_8  * weight00_ch2_2D[6]
                            + ch2_6  * weight00_ch2_2D[5] + ch2_5  * weight00_ch2_2D[4] + ch2_4  * weight00_ch2_2D[3]
                            + ch2_2  * weight00_ch2_2D[2] + ch2_1  * weight00_ch2_2D[1] + ch2_0  * weight00_ch2_2D[0]
                            + ch3_10 * weight00_ch3_2D[8] + ch3_9  * weight00_ch3_2D[7] + ch3_8  * weight00_ch3_2D[6]
                            + ch3_6  * weight00_ch3_2D[5] + ch3_5  * weight00_ch3_2D[4] + ch3_4  * weight00_ch3_2D[3]
                            + ch3_2  * weight00_ch3_2D[2] + ch3_1  * weight00_ch3_2D[1] + ch3_0  * weight00_ch3_2D[0];

            origin_sum3_ch1 = ch0_15 * weight01_ch0_2D[8] + ch0_14 * weight01_ch0_2D[7] + ch0_13 * weight01_ch0_2D[6]
                            + ch0_11 * weight01_ch0_2D[5] + ch0_10 * weight01_ch0_2D[4] + ch0_9  * weight01_ch0_2D[3]
                            + ch0_7  * weight01_ch0_2D[2] + ch0_6  * weight01_ch0_2D[1] + ch0_5  * weight01_ch0_2D[0]
                            + ch1_15 * weight01_ch1_2D[8] + ch1_14 * weight01_ch1_2D[7] + ch1_13 * weight01_ch1_2D[6]
                            + ch1_11 * weight01_ch1_2D[5] + ch1_10 * weight01_ch1_2D[4] + ch1_9  * weight01_ch1_2D[3]
                            + ch1_7  * weight01_ch1_2D[2] + ch1_6  * weight01_ch1_2D[1] + ch1_5  * weight01_ch1_2D[0]
                            + ch2_15 * weight01_ch2_2D[8] + ch2_14 * weight01_ch2_2D[7] + ch2_13 * weight01_ch2_2D[6]
                            + ch2_11 * weight01_ch2_2D[5] + ch2_10 * weight01_ch2_2D[4] + ch2_9  * weight01_ch2_2D[3]
                            + ch2_7  * weight01_ch2_2D[2] + ch2_6  * weight01_ch2_2D[1] + ch2_5  * weight01_ch2_2D[0]
                            + ch3_15 * weight01_ch3_2D[8] + ch3_14 * weight01_ch3_2D[7] + ch3_13 * weight01_ch3_2D[6]
                            + ch3_11 * weight01_ch3_2D[5] + ch3_10 * weight01_ch3_2D[4] + ch3_9  * weight01_ch3_2D[3]
                            + ch3_7  * weight01_ch3_2D[2] + ch3_6  * weight01_ch3_2D[1] + ch3_5  * weight01_ch3_2D[0];

            origin_sum2_ch1 = ch0_14 * weight01_ch0_2D[8] + ch0_13 * weight01_ch0_2D[7] + ch0_12 * weight01_ch0_2D[6]
                            + ch0_10 * weight01_ch0_2D[5] + ch0_9  * weight01_ch0_2D[4] + ch0_8  * weight01_ch0_2D[3]
                            + ch0_6  * weight01_ch0_2D[2] + ch0_5  * weight01_ch0_2D[1] + ch0_4  * weight01_ch0_2D[0]
                            + ch1_14 * weight01_ch1_2D[8] + ch1_13 * weight01_ch1_2D[7] + ch1_12 * weight01_ch1_2D[6]
                            + ch1_10 * weight01_ch1_2D[5] + ch1_9  * weight01_ch1_2D[4] + ch1_8  * weight01_ch1_2D[3]
                            + ch1_6  * weight01_ch1_2D[2] + ch1_5  * weight01_ch1_2D[1] + ch1_4  * weight01_ch1_2D[0]
                            + ch2_14 * weight01_ch2_2D[8] + ch2_13 * weight01_ch2_2D[7] + ch2_12 * weight01_ch2_2D[6]
                            + ch2_10 * weight01_ch2_2D[5] + ch2_9  * weight01_ch2_2D[4] + ch2_8  * weight01_ch2_2D[3]
                            + ch2_6  * weight01_ch2_2D[2] + ch2_5  * weight01_ch2_2D[1] + ch2_4  * weight01_ch2_2D[0]
                            + ch3_14 * weight01_ch3_2D[8] + ch3_13 * weight01_ch3_2D[7] + ch3_12 * weight01_ch3_2D[6]
                            + ch3_10 * weight01_ch3_2D[5] + ch3_9  * weight01_ch3_2D[4] + ch3_8  * weight01_ch3_2D[3]
                            + ch3_6  * weight01_ch3_2D[2] + ch3_5  * weight01_ch3_2D[1] + ch3_4  * weight01_ch3_2D[0];

            origin_sum1_ch1 = ch0_11 * weight01_ch0_2D[8] + ch0_10 * weight01_ch0_2D[7] + ch0_9  * weight01_ch0_2D[6]
                            + ch0_7  * weight01_ch0_2D[5] + ch0_6  * weight01_ch0_2D[4] + ch0_5  * weight01_ch0_2D[3]
                            + ch0_3  * weight01_ch0_2D[2] + ch0_2  * weight01_ch0_2D[1] + ch0_1  * weight01_ch0_2D[0]
                            + ch1_11 * weight01_ch1_2D[8] + ch1_10 * weight01_ch1_2D[7] + ch1_9  * weight01_ch1_2D[6]
                            + ch1_7  * weight01_ch1_2D[5] + ch1_6  * weight01_ch1_2D[4] + ch1_5  * weight01_ch1_2D[3]
                            + ch1_3  * weight01_ch1_2D[2] + ch1_2  * weight01_ch1_2D[1] + ch1_1  * weight01_ch1_2D[0]
                            + ch2_11 * weight01_ch2_2D[8] + ch2_10 * weight01_ch2_2D[7] + ch2_9  * weight01_ch2_2D[6]
                            + ch2_7  * weight01_ch2_2D[5] + ch2_6  * weight01_ch2_2D[4] + ch2_5  * weight01_ch2_2D[3]
                            + ch2_3  * weight01_ch2_2D[2] + ch2_2  * weight01_ch2_2D[1] + ch2_1  * weight01_ch2_2D[0]
                            + ch3_11 * weight01_ch3_2D[8] + ch3_10 * weight01_ch3_2D[7] + ch3_9  * weight01_ch3_2D[6]
                            + ch3_7  * weight01_ch3_2D[5] + ch3_6  * weight01_ch3_2D[4] + ch3_5  * weight01_ch3_2D[3]
                            + ch3_3  * weight01_ch3_2D[2] + ch3_2  * weight01_ch3_2D[1] + ch3_1  * weight01_ch3_2D[0];

            origin_sum0_ch1 = ch0_10 * weight01_ch0_2D[8] + ch0_9  * weight01_ch0_2D[7] + ch0_8  * weight01_ch0_2D[6]
                            + ch0_6  * weight01_ch0_2D[5] + ch0_5  * weight01_ch0_2D[4] + ch0_4  * weight01_ch0_2D[3]
                            + ch0_2  * weight01_ch0_2D[2] + ch0_1  * weight01_ch0_2D[1] + ch0_0  * weight01_ch0_2D[0]
                            + ch1_10 * weight01_ch1_2D[8] + ch1_9  * weight01_ch1_2D[7] + ch1_8  * weight01_ch1_2D[6]
                            + ch1_6  * weight01_ch1_2D[5] + ch1_5  * weight01_ch1_2D[4] + ch1_4  * weight01_ch1_2D[3]
                            + ch1_2  * weight01_ch1_2D[2] + ch1_1  * weight01_ch1_2D[1] + ch1_0  * weight01_ch1_2D[0]
                            + ch2_10 * weight01_ch2_2D[8] + ch2_9  * weight01_ch2_2D[7] + ch2_8  * weight01_ch2_2D[6]
                            + ch2_6  * weight01_ch2_2D[5] + ch2_5  * weight01_ch2_2D[4] + ch2_4  * weight01_ch2_2D[3]
                            + ch2_2  * weight01_ch2_2D[2] + ch2_1  * weight01_ch2_2D[1] + ch2_0  * weight01_ch2_2D[0]
                            + ch3_10 * weight01_ch3_2D[8] + ch3_9  * weight01_ch3_2D[7] + ch3_8  * weight01_ch3_2D[6]
                            + ch3_6  * weight01_ch3_2D[5] + ch3_5  * weight01_ch3_2D[4] + ch3_4  * weight01_ch3_2D[3]
                            + ch3_2  * weight01_ch3_2D[2] + ch3_1  * weight01_ch3_2D[1] + ch3_0  * weight01_ch3_2D[0];

            origin_sum3_ch2 = ch0_15 * weight02_ch0_2D[8] + ch0_14 * weight02_ch0_2D[7] + ch0_13 * weight02_ch0_2D[6]
                            + ch0_11 * weight02_ch0_2D[5] + ch0_10 * weight02_ch0_2D[4] + ch0_9  * weight02_ch0_2D[3]
                            + ch0_7  * weight02_ch0_2D[2] + ch0_6  * weight02_ch0_2D[1] + ch0_5  * weight02_ch0_2D[0]
                            + ch1_15 * weight02_ch1_2D[8] + ch1_14 * weight02_ch1_2D[7] + ch1_13 * weight02_ch1_2D[6]
                            + ch1_11 * weight02_ch1_2D[5] + ch1_10 * weight02_ch1_2D[4] + ch1_9  * weight02_ch1_2D[3]
                            + ch1_7  * weight02_ch1_2D[2] + ch1_6  * weight02_ch1_2D[1] + ch1_5  * weight02_ch1_2D[0]
                            + ch2_15 * weight02_ch2_2D[8] + ch2_14 * weight02_ch2_2D[7] + ch2_13 * weight02_ch2_2D[6]
                            + ch2_11 * weight02_ch2_2D[5] + ch2_10 * weight02_ch2_2D[4] + ch2_9  * weight02_ch2_2D[3]
                            + ch2_7  * weight02_ch2_2D[2] + ch2_6  * weight02_ch2_2D[1] + ch2_5  * weight02_ch2_2D[0]
                            + ch3_15 * weight02_ch3_2D[8] + ch3_14 * weight02_ch3_2D[7] + ch3_13 * weight02_ch3_2D[6]
                            + ch3_11 * weight02_ch3_2D[5] + ch3_10 * weight02_ch3_2D[4] + ch3_9  * weight02_ch3_2D[3]
                            + ch3_7  * weight02_ch3_2D[2] + ch3_6  * weight02_ch3_2D[1] + ch3_5  * weight02_ch3_2D[0];

            origin_sum2_ch2 = ch0_14 * weight02_ch0_2D[8] + ch0_13 * weight02_ch0_2D[7] + ch0_12 * weight02_ch0_2D[6]
                            + ch0_10 * weight02_ch0_2D[5] + ch0_9  * weight02_ch0_2D[4] + ch0_8  * weight02_ch0_2D[3]
                            + ch0_6  * weight02_ch0_2D[2] + ch0_5  * weight02_ch0_2D[1] + ch0_4  * weight02_ch0_2D[0]
                            + ch1_14 * weight02_ch1_2D[8] + ch1_13 * weight02_ch1_2D[7] + ch1_12 * weight02_ch1_2D[6]
                            + ch1_10 * weight02_ch1_2D[5] + ch1_9  * weight02_ch1_2D[4] + ch1_8  * weight02_ch1_2D[3]
                            + ch1_6  * weight02_ch1_2D[2] + ch1_5  * weight02_ch1_2D[1] + ch1_4  * weight02_ch1_2D[0]
                            + ch2_14 * weight02_ch2_2D[8] + ch2_13 * weight02_ch2_2D[7] + ch2_12 * weight02_ch2_2D[6]
                            + ch2_10 * weight02_ch2_2D[5] + ch2_9  * weight02_ch2_2D[4] + ch2_8  * weight02_ch2_2D[3]
                            + ch2_6  * weight02_ch2_2D[2] + ch2_5  * weight02_ch2_2D[1] + ch2_4  * weight02_ch2_2D[0]
                            + ch3_14 * weight02_ch3_2D[8] + ch3_13 * weight02_ch3_2D[7] + ch3_12 * weight02_ch3_2D[6]
                            + ch3_10 * weight02_ch3_2D[5] + ch3_9  * weight02_ch3_2D[4] + ch3_8  * weight02_ch3_2D[3]
                            + ch3_6  * weight02_ch3_2D[2] + ch3_5  * weight02_ch3_2D[1] + ch3_4  * weight02_ch3_2D[0];

            origin_sum1_ch2 = ch0_11 * weight02_ch0_2D[8] + ch0_10 * weight02_ch0_2D[7] + ch0_9  * weight02_ch0_2D[6]
                            + ch0_7  * weight02_ch0_2D[5] + ch0_6  * weight02_ch0_2D[4] + ch0_5  * weight02_ch0_2D[3]
                            + ch0_3  * weight02_ch0_2D[2] + ch0_2  * weight02_ch0_2D[1] + ch0_1  * weight02_ch0_2D[0]
                            + ch1_11 * weight02_ch1_2D[8] + ch1_10 * weight02_ch1_2D[7] + ch1_9  * weight02_ch1_2D[6]
                            + ch1_7  * weight02_ch1_2D[5] + ch1_6  * weight02_ch1_2D[4] + ch1_5  * weight02_ch1_2D[3]
                            + ch1_3  * weight02_ch1_2D[2] + ch1_2  * weight02_ch1_2D[1] + ch1_1  * weight02_ch1_2D[0]
                            + ch2_11 * weight02_ch2_2D[8] + ch2_10 * weight02_ch2_2D[7] + ch2_9  * weight02_ch2_2D[6]
                            + ch2_7  * weight02_ch2_2D[5] + ch2_6  * weight02_ch2_2D[4] + ch2_5  * weight02_ch2_2D[3]
                            + ch2_3  * weight02_ch2_2D[2] + ch2_2  * weight02_ch2_2D[1] + ch2_1  * weight02_ch2_2D[0]
                            + ch3_11 * weight02_ch3_2D[8] + ch3_10 * weight02_ch3_2D[7] + ch3_9  * weight02_ch3_2D[6]
                            + ch3_7  * weight02_ch3_2D[5] + ch3_6  * weight02_ch3_2D[4] + ch3_5  * weight02_ch3_2D[3]
                            + ch3_3  * weight02_ch3_2D[2] + ch3_2  * weight02_ch3_2D[1] + ch3_1  * weight02_ch3_2D[0];

            origin_sum0_ch2 = ch0_10 * weight02_ch0_2D[8] + ch0_9  * weight02_ch0_2D[7] + ch0_8  * weight02_ch0_2D[6]
                            + ch0_6  * weight02_ch0_2D[5] + ch0_5  * weight02_ch0_2D[4] + ch0_4  * weight02_ch0_2D[3]
                            + ch0_2  * weight02_ch0_2D[2] + ch0_1  * weight02_ch0_2D[1] + ch0_0  * weight02_ch0_2D[0]
                            + ch1_10 * weight02_ch1_2D[8] + ch1_9  * weight02_ch1_2D[7] + ch1_8  * weight02_ch1_2D[6]
                            + ch1_6  * weight02_ch1_2D[5] + ch1_5  * weight02_ch1_2D[4] + ch1_4  * weight02_ch1_2D[3]
                            + ch1_2  * weight02_ch1_2D[2] + ch1_1  * weight02_ch1_2D[1] + ch1_0  * weight02_ch1_2D[0]
                            + ch2_10 * weight02_ch2_2D[8] + ch2_9  * weight02_ch2_2D[7] + ch2_8  * weight02_ch2_2D[6]
                            + ch2_6  * weight02_ch2_2D[5] + ch2_5  * weight02_ch2_2D[4] + ch2_4  * weight02_ch2_2D[3]
                            + ch2_2  * weight02_ch2_2D[2] + ch2_1  * weight02_ch2_2D[1] + ch2_0  * weight02_ch2_2D[0]
                            + ch3_10 * weight02_ch3_2D[8] + ch3_9  * weight02_ch3_2D[7] + ch3_8  * weight02_ch3_2D[6]
                            + ch3_6  * weight02_ch3_2D[5] + ch3_5  * weight02_ch3_2D[4] + ch3_4  * weight02_ch3_2D[3]
                            + ch3_2  * weight02_ch3_2D[2] + ch3_1  * weight02_ch3_2D[1] + ch3_0  * weight02_ch3_2D[0];

            origin_sum3_ch3 = ch0_15 * weight03_ch0_2D[8] + ch0_14 * weight03_ch0_2D[7] + ch0_13 * weight03_ch0_2D[6]
                            + ch0_11 * weight03_ch0_2D[5] + ch0_10 * weight03_ch0_2D[4] + ch0_9  * weight03_ch0_2D[3]
                            + ch0_7  * weight03_ch0_2D[2] + ch0_6  * weight03_ch0_2D[1] + ch0_5  * weight03_ch0_2D[0]
                            + ch1_15 * weight03_ch1_2D[8] + ch1_14 * weight03_ch1_2D[7] + ch1_13 * weight03_ch1_2D[6]
                            + ch1_11 * weight03_ch1_2D[5] + ch1_10 * weight03_ch1_2D[4] + ch1_9  * weight03_ch1_2D[3]
                            + ch1_7  * weight03_ch1_2D[2] + ch1_6  * weight03_ch1_2D[1] + ch1_5  * weight03_ch1_2D[0]
                            + ch2_15 * weight03_ch2_2D[8] + ch2_14 * weight03_ch2_2D[7] + ch2_13 * weight03_ch2_2D[6]
                            + ch2_11 * weight03_ch2_2D[5] + ch2_10 * weight03_ch2_2D[4] + ch2_9  * weight03_ch2_2D[3]
                            + ch2_7  * weight03_ch2_2D[2] + ch2_6  * weight03_ch2_2D[1] + ch2_5  * weight03_ch2_2D[0]
                            + ch3_15 * weight03_ch3_2D[8] + ch3_14 * weight03_ch3_2D[7] + ch3_13 * weight03_ch3_2D[6]
                            + ch3_11 * weight03_ch3_2D[5] + ch3_10 * weight03_ch3_2D[4] + ch3_9  * weight03_ch3_2D[3]
                            + ch3_7  * weight03_ch3_2D[2] + ch3_6  * weight03_ch3_2D[1] + ch3_5  * weight03_ch3_2D[0];

            origin_sum2_ch3 = ch0_14 * weight03_ch0_2D[8] + ch0_13 * weight03_ch0_2D[7] + ch0_12 * weight03_ch0_2D[6]
                            + ch0_10 * weight03_ch0_2D[5] + ch0_9  * weight03_ch0_2D[4] + ch0_8  * weight03_ch0_2D[3]
                            + ch0_6  * weight03_ch0_2D[2] + ch0_5  * weight03_ch0_2D[1] + ch0_4  * weight03_ch0_2D[0]
                            + ch1_14 * weight03_ch1_2D[8] + ch1_13 * weight03_ch1_2D[7] + ch1_12 * weight03_ch1_2D[6]
                            + ch1_10 * weight03_ch1_2D[5] + ch1_9  * weight03_ch1_2D[4] + ch1_8  * weight03_ch1_2D[3]
                            + ch1_6  * weight03_ch1_2D[2] + ch1_5  * weight03_ch1_2D[1] + ch1_4  * weight03_ch1_2D[0]
                            + ch2_14 * weight03_ch2_2D[8] + ch2_13 * weight03_ch2_2D[7] + ch2_12 * weight03_ch2_2D[6]
                            + ch2_10 * weight03_ch2_2D[5] + ch2_9  * weight03_ch2_2D[4] + ch2_8  * weight03_ch2_2D[3]
                            + ch2_6  * weight03_ch2_2D[2] + ch2_5  * weight03_ch2_2D[1] + ch2_4  * weight03_ch2_2D[0]
                            + ch3_14 * weight03_ch3_2D[8] + ch3_13 * weight03_ch3_2D[7] + ch3_12 * weight03_ch3_2D[6]
                            + ch3_10 * weight03_ch3_2D[5] + ch3_9  * weight03_ch3_2D[4] + ch3_8  * weight03_ch3_2D[3]
                            + ch3_6  * weight03_ch3_2D[2] + ch3_5  * weight03_ch3_2D[1] + ch3_4  * weight03_ch3_2D[0];

            origin_sum1_ch3 = ch0_11 * weight03_ch0_2D[8] + ch0_10 * weight03_ch0_2D[7] + ch0_9  * weight03_ch0_2D[6]
                            + ch0_7  * weight03_ch0_2D[5] + ch0_6  * weight03_ch0_2D[4] + ch0_5  * weight03_ch0_2D[3]
                            + ch0_3  * weight03_ch0_2D[2] + ch0_2  * weight03_ch0_2D[1] + ch0_1  * weight03_ch0_2D[0]
                            + ch1_11 * weight03_ch1_2D[8] + ch1_10 * weight03_ch1_2D[7] + ch1_9  * weight03_ch1_2D[6]
                            + ch1_7  * weight03_ch1_2D[5] + ch1_6  * weight03_ch1_2D[4] + ch1_5  * weight03_ch1_2D[3]
                            + ch1_3  * weight03_ch1_2D[2] + ch1_2  * weight03_ch1_2D[1] + ch1_1  * weight03_ch1_2D[0]
                            + ch2_11 * weight03_ch2_2D[8] + ch2_10 * weight03_ch2_2D[7] + ch2_9  * weight03_ch2_2D[6]
                            + ch2_7  * weight03_ch2_2D[5] + ch2_6  * weight03_ch2_2D[4] + ch2_5  * weight03_ch2_2D[3]
                            + ch2_3  * weight03_ch2_2D[2] + ch2_2  * weight03_ch2_2D[1] + ch2_1  * weight03_ch2_2D[0]
                            + ch3_11 * weight03_ch3_2D[8] + ch3_10 * weight03_ch3_2D[7] + ch3_9  * weight03_ch3_2D[6]
                            + ch3_7  * weight03_ch3_2D[5] + ch3_6  * weight03_ch3_2D[4] + ch3_5  * weight03_ch3_2D[3]
                            + ch3_3  * weight03_ch3_2D[2] + ch3_2  * weight03_ch3_2D[1] + ch3_1  * weight03_ch3_2D[0];

            origin_sum0_ch3 = ch0_10 * weight03_ch0_2D[8] + ch0_9  * weight03_ch0_2D[7] + ch0_8  * weight03_ch0_2D[6]
                            + ch0_6  * weight03_ch0_2D[5] + ch0_5  * weight03_ch0_2D[4] + ch0_4  * weight03_ch0_2D[3]
                            + ch0_2  * weight03_ch0_2D[2] + ch0_1  * weight03_ch0_2D[1] + ch0_0  * weight03_ch0_2D[0]
                            + ch1_10 * weight03_ch1_2D[8] + ch1_9  * weight03_ch1_2D[7] + ch1_8  * weight03_ch1_2D[6]
                            + ch1_6  * weight03_ch1_2D[5] + ch1_5  * weight03_ch1_2D[4] + ch1_4  * weight03_ch1_2D[3]
                            + ch1_2  * weight03_ch1_2D[2] + ch1_1  * weight03_ch1_2D[1] + ch1_0  * weight03_ch1_2D[0]
                            + ch2_10 * weight03_ch2_2D[8] + ch2_9  * weight03_ch2_2D[7] + ch2_8  * weight03_ch2_2D[6]
                            + ch2_6  * weight03_ch2_2D[5] + ch2_5  * weight03_ch2_2D[4] + ch2_4  * weight03_ch2_2D[3]
                            + ch2_2  * weight03_ch2_2D[2] + ch2_1  * weight03_ch2_2D[1] + ch2_0  * weight03_ch2_2D[0]
                            + ch3_10 * weight03_ch3_2D[8] + ch3_9  * weight03_ch3_2D[7] + ch3_8  * weight03_ch3_2D[6]
                            + ch3_6  * weight03_ch3_2D[5] + ch3_5  * weight03_ch3_2D[4] + ch3_4  * weight03_ch3_2D[3]
                            + ch3_2  * weight03_ch3_2D[2] + ch3_1  * weight03_ch3_2D[1] + ch3_0  * weight03_ch3_2D[0];
        end
        2'd1: begin
            origin_sum3_ch0 = ch0_15 * weight04_ch0_2D[8] + ch0_14 * weight04_ch0_2D[7] + ch0_13 * weight04_ch0_2D[6]
                            + ch0_11 * weight04_ch0_2D[5] + ch0_10 * weight04_ch0_2D[4] + ch0_9  * weight04_ch0_2D[3]
                            + ch0_7  * weight04_ch0_2D[2] + ch0_6  * weight04_ch0_2D[1] + ch0_5  * weight04_ch0_2D[0]
                            + ch1_15 * weight04_ch1_2D[8] + ch1_14 * weight04_ch1_2D[7] + ch1_13 * weight04_ch1_2D[6]
                            + ch1_11 * weight04_ch1_2D[5] + ch1_10 * weight04_ch1_2D[4] + ch1_9  * weight04_ch1_2D[3]
                            + ch1_7  * weight04_ch1_2D[2] + ch1_6  * weight04_ch1_2D[1] + ch1_5  * weight04_ch1_2D[0]
                            + ch2_15 * weight04_ch2_2D[8] + ch2_14 * weight04_ch2_2D[7] + ch2_13 * weight04_ch2_2D[6]
                            + ch2_11 * weight04_ch2_2D[5] + ch2_10 * weight04_ch2_2D[4] + ch2_9  * weight04_ch2_2D[3]
                            + ch2_7  * weight04_ch2_2D[2] + ch2_6  * weight04_ch2_2D[1] + ch2_5  * weight04_ch2_2D[0]
                            + ch3_15 * weight04_ch3_2D[8] + ch3_14 * weight04_ch3_2D[7] + ch3_13 * weight04_ch3_2D[6]
                            + ch3_11 * weight04_ch3_2D[5] + ch3_10 * weight04_ch3_2D[4] + ch3_9  * weight04_ch3_2D[3]
                            + ch3_7  * weight04_ch3_2D[2] + ch3_6  * weight04_ch3_2D[1] + ch3_5  * weight04_ch3_2D[0];

            origin_sum2_ch0 = ch0_14 * weight04_ch0_2D[8] + ch0_13 * weight04_ch0_2D[7] + ch0_12 * weight04_ch0_2D[6]
                            + ch0_10 * weight04_ch0_2D[5] + ch0_9  * weight04_ch0_2D[4] + ch0_8  * weight04_ch0_2D[3]
                            + ch0_6  * weight04_ch0_2D[2] + ch0_5  * weight04_ch0_2D[1] + ch0_4  * weight04_ch0_2D[0]
                            + ch1_14 * weight04_ch1_2D[8] + ch1_13 * weight04_ch1_2D[7] + ch1_12 * weight04_ch1_2D[6]
                            + ch1_10 * weight04_ch1_2D[5] + ch1_9  * weight04_ch1_2D[4] + ch1_8  * weight04_ch1_2D[3]
                            + ch1_6  * weight04_ch1_2D[2] + ch1_5  * weight04_ch1_2D[1] + ch1_4  * weight04_ch1_2D[0]
                            + ch2_14 * weight04_ch2_2D[8] + ch2_13 * weight04_ch2_2D[7] + ch2_12 * weight04_ch2_2D[6]
                            + ch2_10 * weight04_ch2_2D[5] + ch2_9  * weight04_ch2_2D[4] + ch2_8  * weight04_ch2_2D[3]
                            + ch2_6  * weight04_ch2_2D[2] + ch2_5  * weight04_ch2_2D[1] + ch2_4  * weight04_ch2_2D[0]
                            + ch3_14 * weight04_ch3_2D[8] + ch3_13 * weight04_ch3_2D[7] + ch3_12 * weight04_ch3_2D[6]
                            + ch3_10 * weight04_ch3_2D[5] + ch3_9  * weight04_ch3_2D[4] + ch3_8  * weight04_ch3_2D[3]
                            + ch3_6  * weight04_ch3_2D[2] + ch3_5  * weight04_ch3_2D[1] + ch3_4  * weight04_ch3_2D[0];

            origin_sum1_ch0 = ch0_11 * weight04_ch0_2D[8] + ch0_10 * weight04_ch0_2D[7] + ch0_9  * weight04_ch0_2D[6]
                            + ch0_7  * weight04_ch0_2D[5] + ch0_6  * weight04_ch0_2D[4] + ch0_5  * weight04_ch0_2D[3]
                            + ch0_3  * weight04_ch0_2D[2] + ch0_2  * weight04_ch0_2D[1] + ch0_1  * weight04_ch0_2D[0]
                            + ch1_11 * weight04_ch1_2D[8] + ch1_10 * weight04_ch1_2D[7] + ch1_9  * weight04_ch1_2D[6]
                            + ch1_7  * weight04_ch1_2D[5] + ch1_6  * weight04_ch1_2D[4] + ch1_5  * weight04_ch1_2D[3]
                            + ch1_3  * weight04_ch1_2D[2] + ch1_2  * weight04_ch1_2D[1] + ch1_1  * weight04_ch1_2D[0]
                            + ch2_11 * weight04_ch2_2D[8] + ch2_10 * weight04_ch2_2D[7] + ch2_9  * weight04_ch2_2D[6]
                            + ch2_7  * weight04_ch2_2D[5] + ch2_6  * weight04_ch2_2D[4] + ch2_5  * weight04_ch2_2D[3]
                            + ch2_3  * weight04_ch2_2D[2] + ch2_2  * weight04_ch2_2D[1] + ch2_1  * weight04_ch2_2D[0]
                            + ch3_11 * weight04_ch3_2D[8] + ch3_10 * weight04_ch3_2D[7] + ch3_9  * weight04_ch3_2D[6]
                            + ch3_7  * weight04_ch3_2D[5] + ch3_6  * weight04_ch3_2D[4] + ch3_5  * weight04_ch3_2D[3]
                            + ch3_3  * weight04_ch3_2D[2] + ch3_2  * weight04_ch3_2D[1] + ch3_1  * weight04_ch3_2D[0];

            origin_sum0_ch0 = ch0_10 * weight04_ch0_2D[8] + ch0_9  * weight04_ch0_2D[7] + ch0_8  * weight04_ch0_2D[6]
                            + ch0_6  * weight04_ch0_2D[5] + ch0_5  * weight04_ch0_2D[4] + ch0_4  * weight04_ch0_2D[3]
                            + ch0_2  * weight04_ch0_2D[2] + ch0_1  * weight04_ch0_2D[1] + ch0_0  * weight04_ch0_2D[0]
                            + ch1_10 * weight04_ch1_2D[8] + ch1_9  * weight04_ch1_2D[7] + ch1_8  * weight04_ch1_2D[6]
                            + ch1_6  * weight04_ch1_2D[5] + ch1_5  * weight04_ch1_2D[4] + ch1_4  * weight04_ch1_2D[3]
                            + ch1_2  * weight04_ch1_2D[2] + ch1_1  * weight04_ch1_2D[1] + ch1_0  * weight04_ch1_2D[0]
                            + ch2_10 * weight04_ch2_2D[8] + ch2_9  * weight04_ch2_2D[7] + ch2_8  * weight04_ch2_2D[6]
                            + ch2_6  * weight04_ch2_2D[5] + ch2_5  * weight04_ch2_2D[4] + ch2_4  * weight04_ch2_2D[3]
                            + ch2_2  * weight04_ch2_2D[2] + ch2_1  * weight04_ch2_2D[1] + ch2_0  * weight04_ch2_2D[0]
                            + ch3_10 * weight04_ch3_2D[8] + ch3_9  * weight04_ch3_2D[7] + ch3_8  * weight04_ch3_2D[6]
                            + ch3_6  * weight04_ch3_2D[5] + ch3_5  * weight04_ch3_2D[4] + ch3_4  * weight04_ch3_2D[3]
                            + ch3_2  * weight04_ch3_2D[2] + ch3_1  * weight04_ch3_2D[1] + ch3_0  * weight04_ch3_2D[0];

            origin_sum3_ch1 = ch0_15 * weight05_ch0_2D[8] + ch0_14 * weight05_ch0_2D[7] + ch0_13 * weight05_ch0_2D[6]
                            + ch0_11 * weight05_ch0_2D[5] + ch0_10 * weight05_ch0_2D[4] + ch0_9  * weight05_ch0_2D[3]
                            + ch0_7  * weight05_ch0_2D[2] + ch0_6  * weight05_ch0_2D[1] + ch0_5  * weight05_ch0_2D[0]
                            + ch1_15 * weight05_ch1_2D[8] + ch1_14 * weight05_ch1_2D[7] + ch1_13 * weight05_ch1_2D[6]
                            + ch1_11 * weight05_ch1_2D[5] + ch1_10 * weight05_ch1_2D[4] + ch1_9  * weight05_ch1_2D[3]
                            + ch1_7  * weight05_ch1_2D[2] + ch1_6  * weight05_ch1_2D[1] + ch1_5  * weight05_ch1_2D[0]
                            + ch2_15 * weight05_ch2_2D[8] + ch2_14 * weight05_ch2_2D[7] + ch2_13 * weight05_ch2_2D[6]
                            + ch2_11 * weight05_ch2_2D[5] + ch2_10 * weight05_ch2_2D[4] + ch2_9  * weight05_ch2_2D[3]
                            + ch2_7  * weight05_ch2_2D[2] + ch2_6  * weight05_ch2_2D[1] + ch2_5  * weight05_ch2_2D[0]
                            + ch3_15 * weight05_ch3_2D[8] + ch3_14 * weight05_ch3_2D[7] + ch3_13 * weight05_ch3_2D[6]
                            + ch3_11 * weight05_ch3_2D[5] + ch3_10 * weight05_ch3_2D[4] + ch3_9  * weight05_ch3_2D[3]
                            + ch3_7  * weight05_ch3_2D[2] + ch3_6  * weight05_ch3_2D[1] + ch3_5  * weight05_ch3_2D[0];

            origin_sum2_ch1 = ch0_14 * weight05_ch0_2D[8] + ch0_13 * weight05_ch0_2D[7] + ch0_12 * weight05_ch0_2D[6]
                            + ch0_10 * weight05_ch0_2D[5] + ch0_9  * weight05_ch0_2D[4] + ch0_8  * weight05_ch0_2D[3]
                            + ch0_6  * weight05_ch0_2D[2] + ch0_5  * weight05_ch0_2D[1] + ch0_4  * weight05_ch0_2D[0]
                            + ch1_14 * weight05_ch1_2D[8] + ch1_13 * weight05_ch1_2D[7] + ch1_12 * weight05_ch1_2D[6]
                            + ch1_10 * weight05_ch1_2D[5] + ch1_9  * weight05_ch1_2D[4] + ch1_8  * weight05_ch1_2D[3]
                            + ch1_6  * weight05_ch1_2D[2] + ch1_5  * weight05_ch1_2D[1] + ch1_4  * weight05_ch1_2D[0]
                            + ch2_14 * weight05_ch2_2D[8] + ch2_13 * weight05_ch2_2D[7] + ch2_12 * weight05_ch2_2D[6]
                            + ch2_10 * weight05_ch2_2D[5] + ch2_9  * weight05_ch2_2D[4] + ch2_8  * weight05_ch2_2D[3]
                            + ch2_6  * weight05_ch2_2D[2] + ch2_5  * weight05_ch2_2D[1] + ch2_4  * weight05_ch2_2D[0]
                            + ch3_14 * weight05_ch3_2D[8] + ch3_13 * weight05_ch3_2D[7] + ch3_12 * weight05_ch3_2D[6]
                            + ch3_10 * weight05_ch3_2D[5] + ch3_9  * weight05_ch3_2D[4] + ch3_8  * weight05_ch3_2D[3]
                            + ch3_6  * weight05_ch3_2D[2] + ch3_5  * weight05_ch3_2D[1] + ch3_4  * weight05_ch3_2D[0];

            origin_sum1_ch1 = ch0_11 * weight05_ch0_2D[8] + ch0_10 * weight05_ch0_2D[7] + ch0_9  * weight05_ch0_2D[6]
                            + ch0_7  * weight05_ch0_2D[5] + ch0_6  * weight05_ch0_2D[4] + ch0_5  * weight05_ch0_2D[3]
                            + ch0_3  * weight05_ch0_2D[2] + ch0_2  * weight05_ch0_2D[1] + ch0_1  * weight05_ch0_2D[0]
                            + ch1_11 * weight05_ch1_2D[8] + ch1_10 * weight05_ch1_2D[7] + ch1_9  * weight05_ch1_2D[6]
                            + ch1_7  * weight05_ch1_2D[5] + ch1_6  * weight05_ch1_2D[4] + ch1_5  * weight05_ch1_2D[3]
                            + ch1_3  * weight05_ch1_2D[2] + ch1_2  * weight05_ch1_2D[1] + ch1_1  * weight05_ch1_2D[0]
                            + ch2_11 * weight05_ch2_2D[8] + ch2_10 * weight05_ch2_2D[7] + ch2_9  * weight05_ch2_2D[6]
                            + ch2_7  * weight05_ch2_2D[5] + ch2_6  * weight05_ch2_2D[4] + ch2_5  * weight05_ch2_2D[3]
                            + ch2_3  * weight05_ch2_2D[2] + ch2_2  * weight05_ch2_2D[1] + ch2_1  * weight05_ch2_2D[0]
                            + ch3_11 * weight05_ch3_2D[8] + ch3_10 * weight05_ch3_2D[7] + ch3_9  * weight05_ch3_2D[6]
                            + ch3_7  * weight05_ch3_2D[5] + ch3_6  * weight05_ch3_2D[4] + ch3_5  * weight05_ch3_2D[3]
                            + ch3_3  * weight05_ch3_2D[2] + ch3_2  * weight05_ch3_2D[1] + ch3_1  * weight05_ch3_2D[0];

            origin_sum0_ch1 = ch0_10 * weight05_ch0_2D[8] + ch0_9  * weight05_ch0_2D[7] + ch0_8  * weight05_ch0_2D[6]
                            + ch0_6  * weight05_ch0_2D[5] + ch0_5  * weight05_ch0_2D[4] + ch0_4  * weight05_ch0_2D[3]
                            + ch0_2  * weight05_ch0_2D[2] + ch0_1  * weight05_ch0_2D[1] + ch0_0  * weight05_ch0_2D[0]
                            + ch1_10 * weight05_ch1_2D[8] + ch1_9  * weight05_ch1_2D[7] + ch1_8  * weight05_ch1_2D[6]
                            + ch1_6  * weight05_ch1_2D[5] + ch1_5  * weight05_ch1_2D[4] + ch1_4  * weight05_ch1_2D[3]
                            + ch1_2  * weight05_ch1_2D[2] + ch1_1  * weight05_ch1_2D[1] + ch1_0  * weight05_ch1_2D[0]
                            + ch2_10 * weight05_ch2_2D[8] + ch2_9  * weight05_ch2_2D[7] + ch2_8  * weight05_ch2_2D[6]
                            + ch2_6  * weight05_ch2_2D[5] + ch2_5  * weight05_ch2_2D[4] + ch2_4  * weight05_ch2_2D[3]
                            + ch2_2  * weight05_ch2_2D[2] + ch2_1  * weight05_ch2_2D[1] + ch2_0  * weight05_ch2_2D[0]
                            + ch3_10 * weight05_ch3_2D[8] + ch3_9  * weight05_ch3_2D[7] + ch3_8  * weight05_ch3_2D[6]
                            + ch3_6  * weight05_ch3_2D[5] + ch3_5  * weight05_ch3_2D[4] + ch3_4  * weight05_ch3_2D[3]
                            + ch3_2  * weight05_ch3_2D[2] + ch3_1  * weight05_ch3_2D[1] + ch3_0  * weight05_ch3_2D[0];

            origin_sum3_ch2 = ch0_15 * weight06_ch0_2D[8] + ch0_14 * weight06_ch0_2D[7] + ch0_13 * weight06_ch0_2D[6]
                            + ch0_11 * weight06_ch0_2D[5] + ch0_10 * weight06_ch0_2D[4] + ch0_9  * weight06_ch0_2D[3]
                            + ch0_7  * weight06_ch0_2D[2] + ch0_6  * weight06_ch0_2D[1] + ch0_5  * weight06_ch0_2D[0]
                            + ch1_15 * weight06_ch1_2D[8] + ch1_14 * weight06_ch1_2D[7] + ch1_13 * weight06_ch1_2D[6]
                            + ch1_11 * weight06_ch1_2D[5] + ch1_10 * weight06_ch1_2D[4] + ch1_9  * weight06_ch1_2D[3]
                            + ch1_7  * weight06_ch1_2D[2] + ch1_6  * weight06_ch1_2D[1] + ch1_5  * weight06_ch1_2D[0]
                            + ch2_15 * weight06_ch2_2D[8] + ch2_14 * weight06_ch2_2D[7] + ch2_13 * weight06_ch2_2D[6]
                            + ch2_11 * weight06_ch2_2D[5] + ch2_10 * weight06_ch2_2D[4] + ch2_9  * weight06_ch2_2D[3]
                            + ch2_7  * weight06_ch2_2D[2] + ch2_6  * weight06_ch2_2D[1] + ch2_5  * weight06_ch2_2D[0]
                            + ch3_15 * weight06_ch3_2D[8] + ch3_14 * weight06_ch3_2D[7] + ch3_13 * weight06_ch3_2D[6]
                            + ch3_11 * weight06_ch3_2D[5] + ch3_10 * weight06_ch3_2D[4] + ch3_9  * weight06_ch3_2D[3]
                            + ch3_7  * weight06_ch3_2D[2] + ch3_6  * weight06_ch3_2D[1] + ch3_5  * weight06_ch3_2D[0];

            origin_sum2_ch2 = ch0_14 * weight06_ch0_2D[8] + ch0_13 * weight06_ch0_2D[7] + ch0_12 * weight06_ch0_2D[6]
                            + ch0_10 * weight06_ch0_2D[5] + ch0_9  * weight06_ch0_2D[4] + ch0_8  * weight06_ch0_2D[3]
                            + ch0_6  * weight06_ch0_2D[2] + ch0_5  * weight06_ch0_2D[1] + ch0_4  * weight06_ch0_2D[0]
                            + ch1_14 * weight06_ch1_2D[8] + ch1_13 * weight06_ch1_2D[7] + ch1_12 * weight06_ch1_2D[6]
                            + ch1_10 * weight06_ch1_2D[5] + ch1_9  * weight06_ch1_2D[4] + ch1_8  * weight06_ch1_2D[3]
                            + ch1_6  * weight06_ch1_2D[2] + ch1_5  * weight06_ch1_2D[1] + ch1_4  * weight06_ch1_2D[0]
                            + ch2_14 * weight06_ch2_2D[8] + ch2_13 * weight06_ch2_2D[7] + ch2_12 * weight06_ch2_2D[6]
                            + ch2_10 * weight06_ch2_2D[5] + ch2_9  * weight06_ch2_2D[4] + ch2_8  * weight06_ch2_2D[3]
                            + ch2_6  * weight06_ch2_2D[2] + ch2_5  * weight06_ch2_2D[1] + ch2_4  * weight06_ch2_2D[0]
                            + ch3_14 * weight06_ch3_2D[8] + ch3_13 * weight06_ch3_2D[7] + ch3_12 * weight06_ch3_2D[6]
                            + ch3_10 * weight06_ch3_2D[5] + ch3_9  * weight06_ch3_2D[4] + ch3_8  * weight06_ch3_2D[3]
                            + ch3_6  * weight06_ch3_2D[2] + ch3_5  * weight06_ch3_2D[1] + ch3_4  * weight06_ch3_2D[0];

            origin_sum1_ch2 = ch0_11 * weight06_ch0_2D[8] + ch0_10 * weight06_ch0_2D[7] + ch0_9  * weight06_ch0_2D[6]
                            + ch0_7  * weight06_ch0_2D[5] + ch0_6  * weight06_ch0_2D[4] + ch0_5  * weight06_ch0_2D[3]
                            + ch0_3  * weight06_ch0_2D[2] + ch0_2  * weight06_ch0_2D[1] + ch0_1  * weight06_ch0_2D[0]
                            + ch1_11 * weight06_ch1_2D[8] + ch1_10 * weight06_ch1_2D[7] + ch1_9  * weight06_ch1_2D[6]
                            + ch1_7  * weight06_ch1_2D[5] + ch1_6  * weight06_ch1_2D[4] + ch1_5  * weight06_ch1_2D[3]
                            + ch1_3  * weight06_ch1_2D[2] + ch1_2  * weight06_ch1_2D[1] + ch1_1  * weight06_ch1_2D[0]
                            + ch2_11 * weight06_ch2_2D[8] + ch2_10 * weight06_ch2_2D[7] + ch2_9  * weight06_ch2_2D[6]
                            + ch2_7  * weight06_ch2_2D[5] + ch2_6  * weight06_ch2_2D[4] + ch2_5  * weight06_ch2_2D[3]
                            + ch2_3  * weight06_ch2_2D[2] + ch2_2  * weight06_ch2_2D[1] + ch2_1  * weight06_ch2_2D[0]
                            + ch3_11 * weight06_ch3_2D[8] + ch3_10 * weight06_ch3_2D[7] + ch3_9  * weight06_ch3_2D[6]
                            + ch3_7  * weight06_ch3_2D[5] + ch3_6  * weight06_ch3_2D[4] + ch3_5  * weight06_ch3_2D[3]
                            + ch3_3  * weight06_ch3_2D[2] + ch3_2  * weight06_ch3_2D[1] + ch3_1  * weight06_ch3_2D[0];

            origin_sum0_ch2 = ch0_10 * weight06_ch0_2D[8] + ch0_9  * weight06_ch0_2D[7] + ch0_8  * weight06_ch0_2D[6]
                            + ch0_6  * weight06_ch0_2D[5] + ch0_5  * weight06_ch0_2D[4] + ch0_4  * weight06_ch0_2D[3]
                            + ch0_2  * weight06_ch0_2D[2] + ch0_1  * weight06_ch0_2D[1] + ch0_0  * weight06_ch0_2D[0]
                            + ch1_10 * weight06_ch1_2D[8] + ch1_9  * weight06_ch1_2D[7] + ch1_8  * weight06_ch1_2D[6]
                            + ch1_6  * weight06_ch1_2D[5] + ch1_5  * weight06_ch1_2D[4] + ch1_4  * weight06_ch1_2D[3]
                            + ch1_2  * weight06_ch1_2D[2] + ch1_1  * weight06_ch1_2D[1] + ch1_0  * weight06_ch1_2D[0]
                            + ch2_10 * weight06_ch2_2D[8] + ch2_9  * weight06_ch2_2D[7] + ch2_8  * weight06_ch2_2D[6]
                            + ch2_6  * weight06_ch2_2D[5] + ch2_5  * weight06_ch2_2D[4] + ch2_4  * weight06_ch2_2D[3]
                            + ch2_2  * weight06_ch2_2D[2] + ch2_1  * weight06_ch2_2D[1] + ch2_0  * weight06_ch2_2D[0]
                            + ch3_10 * weight06_ch3_2D[8] + ch3_9  * weight06_ch3_2D[7] + ch3_8  * weight06_ch3_2D[6]
                            + ch3_6  * weight06_ch3_2D[5] + ch3_5  * weight06_ch3_2D[4] + ch3_4  * weight06_ch3_2D[3]
                            + ch3_2  * weight06_ch3_2D[2] + ch3_1  * weight06_ch3_2D[1] + ch3_0  * weight06_ch3_2D[0];

            origin_sum3_ch3 = ch0_15 * weight07_ch0_2D[8] + ch0_14 * weight07_ch0_2D[7] + ch0_13 * weight07_ch0_2D[6]
                            + ch0_11 * weight07_ch0_2D[5] + ch0_10 * weight07_ch0_2D[4] + ch0_9  * weight07_ch0_2D[3]
                            + ch0_7  * weight07_ch0_2D[2] + ch0_6  * weight07_ch0_2D[1] + ch0_5  * weight07_ch0_2D[0]
                            + ch1_15 * weight07_ch1_2D[8] + ch1_14 * weight07_ch1_2D[7] + ch1_13 * weight07_ch1_2D[6]
                            + ch1_11 * weight07_ch1_2D[5] + ch1_10 * weight07_ch1_2D[4] + ch1_9  * weight07_ch1_2D[3]
                            + ch1_7  * weight07_ch1_2D[2] + ch1_6  * weight07_ch1_2D[1] + ch1_5  * weight07_ch1_2D[0]
                            + ch2_15 * weight07_ch2_2D[8] + ch2_14 * weight07_ch2_2D[7] + ch2_13 * weight07_ch2_2D[6]
                            + ch2_11 * weight07_ch2_2D[5] + ch2_10 * weight07_ch2_2D[4] + ch2_9  * weight07_ch2_2D[3]
                            + ch2_7  * weight07_ch2_2D[2] + ch2_6  * weight07_ch2_2D[1] + ch2_5  * weight07_ch2_2D[0]
                            + ch3_15 * weight07_ch3_2D[8] + ch3_14 * weight07_ch3_2D[7] + ch3_13 * weight07_ch3_2D[6]
                            + ch3_11 * weight07_ch3_2D[5] + ch3_10 * weight07_ch3_2D[4] + ch3_9  * weight07_ch3_2D[3]
                            + ch3_7  * weight07_ch3_2D[2] + ch3_6  * weight07_ch3_2D[1] + ch3_5  * weight07_ch3_2D[0];

            origin_sum2_ch3 = ch0_14 * weight07_ch0_2D[8] + ch0_13 * weight07_ch0_2D[7] + ch0_12 * weight07_ch0_2D[6]
                            + ch0_10 * weight07_ch0_2D[5] + ch0_9  * weight07_ch0_2D[4] + ch0_8  * weight07_ch0_2D[3]
                            + ch0_6  * weight07_ch0_2D[2] + ch0_5  * weight07_ch0_2D[1] + ch0_4  * weight07_ch0_2D[0]
                            + ch1_14 * weight07_ch1_2D[8] + ch1_13 * weight07_ch1_2D[7] + ch1_12 * weight07_ch1_2D[6]
                            + ch1_10 * weight07_ch1_2D[5] + ch1_9  * weight07_ch1_2D[4] + ch1_8  * weight07_ch1_2D[3]
                            + ch1_6  * weight07_ch1_2D[2] + ch1_5  * weight07_ch1_2D[1] + ch1_4  * weight07_ch1_2D[0]
                            + ch2_14 * weight07_ch2_2D[8] + ch2_13 * weight07_ch2_2D[7] + ch2_12 * weight07_ch2_2D[6]
                            + ch2_10 * weight07_ch2_2D[5] + ch2_9  * weight07_ch2_2D[4] + ch2_8  * weight07_ch2_2D[3]
                            + ch2_6  * weight07_ch2_2D[2] + ch2_5  * weight07_ch2_2D[1] + ch2_4  * weight07_ch2_2D[0]
                            + ch3_14 * weight07_ch3_2D[8] + ch3_13 * weight07_ch3_2D[7] + ch3_12 * weight07_ch3_2D[6]
                            + ch3_10 * weight07_ch3_2D[5] + ch3_9  * weight07_ch3_2D[4] + ch3_8  * weight07_ch3_2D[3]
                            + ch3_6  * weight07_ch3_2D[2] + ch3_5  * weight07_ch3_2D[1] + ch3_4  * weight07_ch3_2D[0];

            origin_sum1_ch3 = ch0_11 * weight07_ch0_2D[8] + ch0_10 * weight07_ch0_2D[7] + ch0_9  * weight07_ch0_2D[6]
                            + ch0_7  * weight07_ch0_2D[5] + ch0_6  * weight07_ch0_2D[4] + ch0_5  * weight07_ch0_2D[3]
                            + ch0_3  * weight07_ch0_2D[2] + ch0_2  * weight07_ch0_2D[1] + ch0_1  * weight07_ch0_2D[0]
                            + ch1_11 * weight07_ch1_2D[8] + ch1_10 * weight07_ch1_2D[7] + ch1_9  * weight07_ch1_2D[6]
                            + ch1_7  * weight07_ch1_2D[5] + ch1_6  * weight07_ch1_2D[4] + ch1_5  * weight07_ch1_2D[3]
                            + ch1_3  * weight07_ch1_2D[2] + ch1_2  * weight07_ch1_2D[1] + ch1_1  * weight07_ch1_2D[0]
                            + ch2_11 * weight07_ch2_2D[8] + ch2_10 * weight07_ch2_2D[7] + ch2_9  * weight07_ch2_2D[6]
                            + ch2_7  * weight07_ch2_2D[5] + ch2_6  * weight07_ch2_2D[4] + ch2_5  * weight07_ch2_2D[3]
                            + ch2_3  * weight07_ch2_2D[2] + ch2_2  * weight07_ch2_2D[1] + ch2_1  * weight07_ch2_2D[0]
                            + ch3_11 * weight07_ch3_2D[8] + ch3_10 * weight07_ch3_2D[7] + ch3_9  * weight07_ch3_2D[6]
                            + ch3_7  * weight07_ch3_2D[5] + ch3_6  * weight07_ch3_2D[4] + ch3_5  * weight07_ch3_2D[3]
                            + ch3_3  * weight07_ch3_2D[2] + ch3_2  * weight07_ch3_2D[1] + ch3_1  * weight07_ch3_2D[0];

            origin_sum0_ch3 = ch0_10 * weight07_ch0_2D[8] + ch0_9  * weight07_ch0_2D[7] + ch0_8  * weight07_ch0_2D[6]
                            + ch0_6  * weight07_ch0_2D[5] + ch0_5  * weight07_ch0_2D[4] + ch0_4  * weight07_ch0_2D[3]
                            + ch0_2  * weight07_ch0_2D[2] + ch0_1  * weight07_ch0_2D[1] + ch0_0  * weight07_ch0_2D[0]
                            + ch1_10 * weight07_ch1_2D[8] + ch1_9  * weight07_ch1_2D[7] + ch1_8  * weight07_ch1_2D[6]
                            + ch1_6  * weight07_ch1_2D[5] + ch1_5  * weight07_ch1_2D[4] + ch1_4  * weight07_ch1_2D[3]
                            + ch1_2  * weight07_ch1_2D[2] + ch1_1  * weight07_ch1_2D[1] + ch1_0  * weight07_ch1_2D[0]
                            + ch2_10 * weight07_ch2_2D[8] + ch2_9  * weight07_ch2_2D[7] + ch2_8  * weight07_ch2_2D[6]
                            + ch2_6  * weight07_ch2_2D[5] + ch2_5  * weight07_ch2_2D[4] + ch2_4  * weight07_ch2_2D[3]
                            + ch2_2  * weight07_ch2_2D[2] + ch2_1  * weight07_ch2_2D[1] + ch2_0  * weight07_ch2_2D[0]
                            + ch3_10 * weight07_ch3_2D[8] + ch3_9  * weight07_ch3_2D[7] + ch3_8  * weight07_ch3_2D[6]
                            + ch3_6  * weight07_ch3_2D[5] + ch3_5  * weight07_ch3_2D[4] + ch3_4  * weight07_ch3_2D[3]
                            + ch3_2  * weight07_ch3_2D[2] + ch3_1  * weight07_ch3_2D[1] + ch3_0  * weight07_ch3_2D[0];
        end
        2'd2: begin
            origin_sum3_ch0 = ch0_15 * weight08_ch0_2D[8] + ch0_14 * weight08_ch0_2D[7] + ch0_13 * weight08_ch0_2D[6]
                            + ch0_11 * weight08_ch0_2D[5] + ch0_10 * weight08_ch0_2D[4] + ch0_9  * weight08_ch0_2D[3]
                            + ch0_7  * weight08_ch0_2D[2] + ch0_6  * weight08_ch0_2D[1] + ch0_5  * weight08_ch0_2D[0]
                            + ch1_15 * weight08_ch1_2D[8] + ch1_14 * weight08_ch1_2D[7] + ch1_13 * weight08_ch1_2D[6]
                            + ch1_11 * weight08_ch1_2D[5] + ch1_10 * weight08_ch1_2D[4] + ch1_9  * weight08_ch1_2D[3]
                            + ch1_7  * weight08_ch1_2D[2] + ch1_6  * weight08_ch1_2D[1] + ch1_5  * weight08_ch1_2D[0]
                            + ch2_15 * weight08_ch2_2D[8] + ch2_14 * weight08_ch2_2D[7] + ch2_13 * weight08_ch2_2D[6]
                            + ch2_11 * weight08_ch2_2D[5] + ch2_10 * weight08_ch2_2D[4] + ch2_9  * weight08_ch2_2D[3]
                            + ch2_7  * weight08_ch2_2D[2] + ch2_6  * weight08_ch2_2D[1] + ch2_5  * weight08_ch2_2D[0]
                            + ch3_15 * weight08_ch3_2D[8] + ch3_14 * weight08_ch3_2D[7] + ch3_13 * weight08_ch3_2D[6]
                            + ch3_11 * weight08_ch3_2D[5] + ch3_10 * weight08_ch3_2D[4] + ch3_9  * weight08_ch3_2D[3]
                            + ch3_7  * weight08_ch3_2D[2] + ch3_6  * weight08_ch3_2D[1] + ch3_5  * weight08_ch3_2D[0];

            origin_sum2_ch0 = ch0_14 * weight08_ch0_2D[8] + ch0_13 * weight08_ch0_2D[7] + ch0_12 * weight08_ch0_2D[6]
                            + ch0_10 * weight08_ch0_2D[5] + ch0_9  * weight08_ch0_2D[4] + ch0_8  * weight08_ch0_2D[3]
                            + ch0_6  * weight08_ch0_2D[2] + ch0_5  * weight08_ch0_2D[1] + ch0_4  * weight08_ch0_2D[0]
                            + ch1_14 * weight08_ch1_2D[8] + ch1_13 * weight08_ch1_2D[7] + ch1_12 * weight08_ch1_2D[6]
                            + ch1_10 * weight08_ch1_2D[5] + ch1_9  * weight08_ch1_2D[4] + ch1_8  * weight08_ch1_2D[3]
                            + ch1_6  * weight08_ch1_2D[2] + ch1_5  * weight08_ch1_2D[1] + ch1_4  * weight08_ch1_2D[0]
                            + ch2_14 * weight08_ch2_2D[8] + ch2_13 * weight08_ch2_2D[7] + ch2_12 * weight08_ch2_2D[6]
                            + ch2_10 * weight08_ch2_2D[5] + ch2_9  * weight08_ch2_2D[4] + ch2_8  * weight08_ch2_2D[3]
                            + ch2_6  * weight08_ch2_2D[2] + ch2_5  * weight08_ch2_2D[1] + ch2_4  * weight08_ch2_2D[0]
                            + ch3_14 * weight08_ch3_2D[8] + ch3_13 * weight08_ch3_2D[7] + ch3_12 * weight08_ch3_2D[6]
                            + ch3_10 * weight08_ch3_2D[5] + ch3_9  * weight08_ch3_2D[4] + ch3_8  * weight08_ch3_2D[3]
                            + ch3_6  * weight08_ch3_2D[2] + ch3_5  * weight08_ch3_2D[1] + ch3_4  * weight08_ch3_2D[0];

            origin_sum1_ch0 = ch0_11 * weight08_ch0_2D[8] + ch0_10 * weight08_ch0_2D[7] + ch0_9  * weight08_ch0_2D[6]
                            + ch0_7  * weight08_ch0_2D[5] + ch0_6  * weight08_ch0_2D[4] + ch0_5  * weight08_ch0_2D[3]
                            + ch0_3  * weight08_ch0_2D[2] + ch0_2  * weight08_ch0_2D[1] + ch0_1  * weight08_ch0_2D[0]
                            + ch1_11 * weight08_ch1_2D[8] + ch1_10 * weight08_ch1_2D[7] + ch1_9  * weight08_ch1_2D[6]
                            + ch1_7  * weight08_ch1_2D[5] + ch1_6  * weight08_ch1_2D[4] + ch1_5  * weight08_ch1_2D[3]
                            + ch1_3  * weight08_ch1_2D[2] + ch1_2  * weight08_ch1_2D[1] + ch1_1  * weight08_ch1_2D[0]
                            + ch2_11 * weight08_ch2_2D[8] + ch2_10 * weight08_ch2_2D[7] + ch2_9  * weight08_ch2_2D[6]
                            + ch2_7  * weight08_ch2_2D[5] + ch2_6  * weight08_ch2_2D[4] + ch2_5  * weight08_ch2_2D[3]
                            + ch2_3  * weight08_ch2_2D[2] + ch2_2  * weight08_ch2_2D[1] + ch2_1  * weight08_ch2_2D[0]
                            + ch3_11 * weight08_ch3_2D[8] + ch3_10 * weight08_ch3_2D[7] + ch3_9  * weight08_ch3_2D[6]
                            + ch3_7  * weight08_ch3_2D[5] + ch3_6  * weight08_ch3_2D[4] + ch3_5  * weight08_ch3_2D[3]
                            + ch3_3  * weight08_ch3_2D[2] + ch3_2  * weight08_ch3_2D[1] + ch3_1  * weight08_ch3_2D[0];

            origin_sum0_ch0 = ch0_10 * weight08_ch0_2D[8] + ch0_9  * weight08_ch0_2D[7] + ch0_8  * weight08_ch0_2D[6]
                            + ch0_6  * weight08_ch0_2D[5] + ch0_5  * weight08_ch0_2D[4] + ch0_4  * weight08_ch0_2D[3]
                            + ch0_2  * weight08_ch0_2D[2] + ch0_1  * weight08_ch0_2D[1] + ch0_0  * weight08_ch0_2D[0]
                            + ch1_10 * weight08_ch1_2D[8] + ch1_9  * weight08_ch1_2D[7] + ch1_8  * weight08_ch1_2D[6]
                            + ch1_6  * weight08_ch1_2D[5] + ch1_5  * weight08_ch1_2D[4] + ch1_4  * weight08_ch1_2D[3]
                            + ch1_2  * weight08_ch1_2D[2] + ch1_1  * weight08_ch1_2D[1] + ch1_0  * weight08_ch1_2D[0]
                            + ch2_10 * weight08_ch2_2D[8] + ch2_9  * weight08_ch2_2D[7] + ch2_8  * weight08_ch2_2D[6]
                            + ch2_6  * weight08_ch2_2D[5] + ch2_5  * weight08_ch2_2D[4] + ch2_4  * weight08_ch2_2D[3]
                            + ch2_2  * weight08_ch2_2D[2] + ch2_1  * weight08_ch2_2D[1] + ch2_0  * weight08_ch2_2D[0]
                            + ch3_10 * weight08_ch3_2D[8] + ch3_9  * weight08_ch3_2D[7] + ch3_8  * weight08_ch3_2D[6]
                            + ch3_6  * weight08_ch3_2D[5] + ch3_5  * weight08_ch3_2D[4] + ch3_4  * weight08_ch3_2D[3]
                            + ch3_2  * weight08_ch3_2D[2] + ch3_1  * weight08_ch3_2D[1] + ch3_0  * weight08_ch3_2D[0];

            origin_sum3_ch1 = ch0_15 * weight09_ch0_2D[8] + ch0_14 * weight09_ch0_2D[7] + ch0_13 * weight09_ch0_2D[6]
                            + ch0_11 * weight09_ch0_2D[5] + ch0_10 * weight09_ch0_2D[4] + ch0_9  * weight09_ch0_2D[3]
                            + ch0_7  * weight09_ch0_2D[2] + ch0_6  * weight09_ch0_2D[1] + ch0_5  * weight09_ch0_2D[0]
                            + ch1_15 * weight09_ch1_2D[8] + ch1_14 * weight09_ch1_2D[7] + ch1_13 * weight09_ch1_2D[6]
                            + ch1_11 * weight09_ch1_2D[5] + ch1_10 * weight09_ch1_2D[4] + ch1_9  * weight09_ch1_2D[3]
                            + ch1_7  * weight09_ch1_2D[2] + ch1_6  * weight09_ch1_2D[1] + ch1_5  * weight09_ch1_2D[0]
                            + ch2_15 * weight09_ch2_2D[8] + ch2_14 * weight09_ch2_2D[7] + ch2_13 * weight09_ch2_2D[6]
                            + ch2_11 * weight09_ch2_2D[5] + ch2_10 * weight09_ch2_2D[4] + ch2_9  * weight09_ch2_2D[3]
                            + ch2_7  * weight09_ch2_2D[2] + ch2_6  * weight09_ch2_2D[1] + ch2_5  * weight09_ch2_2D[0]
                            + ch3_15 * weight09_ch3_2D[8] + ch3_14 * weight09_ch3_2D[7] + ch3_13 * weight09_ch3_2D[6]
                            + ch3_11 * weight09_ch3_2D[5] + ch3_10 * weight09_ch3_2D[4] + ch3_9  * weight09_ch3_2D[3]
                            + ch3_7  * weight09_ch3_2D[2] + ch3_6  * weight09_ch3_2D[1] + ch3_5  * weight09_ch3_2D[0];

            origin_sum2_ch1 = ch0_14 * weight09_ch0_2D[8] + ch0_13 * weight09_ch0_2D[7] + ch0_12 * weight09_ch0_2D[6]
                            + ch0_10 * weight09_ch0_2D[5] + ch0_9  * weight09_ch0_2D[4] + ch0_8  * weight09_ch0_2D[3]
                            + ch0_6  * weight09_ch0_2D[2] + ch0_5  * weight09_ch0_2D[1] + ch0_4  * weight09_ch0_2D[0]
                            + ch1_14 * weight09_ch1_2D[8] + ch1_13 * weight09_ch1_2D[7] + ch1_12 * weight09_ch1_2D[6]
                            + ch1_10 * weight09_ch1_2D[5] + ch1_9  * weight09_ch1_2D[4] + ch1_8  * weight09_ch1_2D[3]
                            + ch1_6  * weight09_ch1_2D[2] + ch1_5  * weight09_ch1_2D[1] + ch1_4  * weight09_ch1_2D[0]
                            + ch2_14 * weight09_ch2_2D[8] + ch2_13 * weight09_ch2_2D[7] + ch2_12 * weight09_ch2_2D[6]
                            + ch2_10 * weight09_ch2_2D[5] + ch2_9  * weight09_ch2_2D[4] + ch2_8  * weight09_ch2_2D[3]
                            + ch2_6  * weight09_ch2_2D[2] + ch2_5  * weight09_ch2_2D[1] + ch2_4  * weight09_ch2_2D[0]
                            + ch3_14 * weight09_ch3_2D[8] + ch3_13 * weight09_ch3_2D[7] + ch3_12 * weight09_ch3_2D[6]
                            + ch3_10 * weight09_ch3_2D[5] + ch3_9  * weight09_ch3_2D[4] + ch3_8  * weight09_ch3_2D[3]
                            + ch3_6  * weight09_ch3_2D[2] + ch3_5  * weight09_ch3_2D[1] + ch3_4  * weight09_ch3_2D[0];

            origin_sum1_ch1 = ch0_11 * weight09_ch0_2D[8] + ch0_10 * weight09_ch0_2D[7] + ch0_9  * weight09_ch0_2D[6]
                            + ch0_7  * weight09_ch0_2D[5] + ch0_6  * weight09_ch0_2D[4] + ch0_5  * weight09_ch0_2D[3]
                            + ch0_3  * weight09_ch0_2D[2] + ch0_2  * weight09_ch0_2D[1] + ch0_1  * weight09_ch0_2D[0]
                            + ch1_11 * weight09_ch1_2D[8] + ch1_10 * weight09_ch1_2D[7] + ch1_9  * weight09_ch1_2D[6]
                            + ch1_7  * weight09_ch1_2D[5] + ch1_6  * weight09_ch1_2D[4] + ch1_5  * weight09_ch1_2D[3]
                            + ch1_3  * weight09_ch1_2D[2] + ch1_2  * weight09_ch1_2D[1] + ch1_1  * weight09_ch1_2D[0]
                            + ch2_11 * weight09_ch2_2D[8] + ch2_10 * weight09_ch2_2D[7] + ch2_9  * weight09_ch2_2D[6]
                            + ch2_7  * weight09_ch2_2D[5] + ch2_6  * weight09_ch2_2D[4] + ch2_5  * weight09_ch2_2D[3]
                            + ch2_3  * weight09_ch2_2D[2] + ch2_2  * weight09_ch2_2D[1] + ch2_1  * weight09_ch2_2D[0]
                            + ch3_11 * weight09_ch3_2D[8] + ch3_10 * weight09_ch3_2D[7] + ch3_9  * weight09_ch3_2D[6]
                            + ch3_7  * weight09_ch3_2D[5] + ch3_6  * weight09_ch3_2D[4] + ch3_5  * weight09_ch3_2D[3]
                            + ch3_3  * weight09_ch3_2D[2] + ch3_2  * weight09_ch3_2D[1] + ch3_1  * weight09_ch3_2D[0];

            origin_sum0_ch1 = ch0_10 * weight09_ch0_2D[8] + ch0_9  * weight09_ch0_2D[7] + ch0_8  * weight09_ch0_2D[6]
                            + ch0_6  * weight09_ch0_2D[5] + ch0_5  * weight09_ch0_2D[4] + ch0_4  * weight09_ch0_2D[3]
                            + ch0_2  * weight09_ch0_2D[2] + ch0_1  * weight09_ch0_2D[1] + ch0_0  * weight09_ch0_2D[0]
                            + ch1_10 * weight09_ch1_2D[8] + ch1_9  * weight09_ch1_2D[7] + ch1_8  * weight09_ch1_2D[6]
                            + ch1_6  * weight09_ch1_2D[5] + ch1_5  * weight09_ch1_2D[4] + ch1_4  * weight09_ch1_2D[3]
                            + ch1_2  * weight09_ch1_2D[2] + ch1_1  * weight09_ch1_2D[1] + ch1_0  * weight09_ch1_2D[0]
                            + ch2_10 * weight09_ch2_2D[8] + ch2_9  * weight09_ch2_2D[7] + ch2_8  * weight09_ch2_2D[6]
                            + ch2_6  * weight09_ch2_2D[5] + ch2_5  * weight09_ch2_2D[4] + ch2_4  * weight09_ch2_2D[3]
                            + ch2_2  * weight09_ch2_2D[2] + ch2_1  * weight09_ch2_2D[1] + ch2_0  * weight09_ch2_2D[0]
                            + ch3_10 * weight09_ch3_2D[8] + ch3_9  * weight09_ch3_2D[7] + ch3_8  * weight09_ch3_2D[6]
                            + ch3_6  * weight09_ch3_2D[5] + ch3_5  * weight09_ch3_2D[4] + ch3_4  * weight09_ch3_2D[3]
                            + ch3_2  * weight09_ch3_2D[2] + ch3_1  * weight09_ch3_2D[1] + ch3_0  * weight09_ch3_2D[0];

            origin_sum3_ch2 = ch0_15 * weight10_ch0_2D[8] + ch0_14 * weight10_ch0_2D[7] + ch0_13 * weight10_ch0_2D[6]
                            + ch0_11 * weight10_ch0_2D[5] + ch0_10 * weight10_ch0_2D[4] + ch0_9  * weight10_ch0_2D[3]
                            + ch0_7  * weight10_ch0_2D[2] + ch0_6  * weight10_ch0_2D[1] + ch0_5  * weight10_ch0_2D[0]
                            + ch1_15 * weight10_ch1_2D[8] + ch1_14 * weight10_ch1_2D[7] + ch1_13 * weight10_ch1_2D[6]
                            + ch1_11 * weight10_ch1_2D[5] + ch1_10 * weight10_ch1_2D[4] + ch1_9  * weight10_ch1_2D[3]
                            + ch1_7  * weight10_ch1_2D[2] + ch1_6  * weight10_ch1_2D[1] + ch1_5  * weight10_ch1_2D[0]
                            + ch2_15 * weight10_ch2_2D[8] + ch2_14 * weight10_ch2_2D[7] + ch2_13 * weight10_ch2_2D[6]
                            + ch2_11 * weight10_ch2_2D[5] + ch2_10 * weight10_ch2_2D[4] + ch2_9  * weight10_ch2_2D[3]
                            + ch2_7  * weight10_ch2_2D[2] + ch2_6  * weight10_ch2_2D[1] + ch2_5  * weight10_ch2_2D[0]
                            + ch3_15 * weight10_ch3_2D[8] + ch3_14 * weight10_ch3_2D[7] + ch3_13 * weight10_ch3_2D[6]
                            + ch3_11 * weight10_ch3_2D[5] + ch3_10 * weight10_ch3_2D[4] + ch3_9  * weight10_ch3_2D[3]
                            + ch3_7  * weight10_ch3_2D[2] + ch3_6  * weight10_ch3_2D[1] + ch3_5  * weight10_ch3_2D[0];

            origin_sum2_ch2 = ch0_14 * weight10_ch0_2D[8] + ch0_13 * weight10_ch0_2D[7] + ch0_12 * weight10_ch0_2D[6]
                            + ch0_10 * weight10_ch0_2D[5] + ch0_9  * weight10_ch0_2D[4] + ch0_8  * weight10_ch0_2D[3]
                            + ch0_6  * weight10_ch0_2D[2] + ch0_5  * weight10_ch0_2D[1] + ch0_4  * weight10_ch0_2D[0]
                            + ch1_14 * weight10_ch1_2D[8] + ch1_13 * weight10_ch1_2D[7] + ch1_12 * weight10_ch1_2D[6]
                            + ch1_10 * weight10_ch1_2D[5] + ch1_9  * weight10_ch1_2D[4] + ch1_8  * weight10_ch1_2D[3]
                            + ch1_6  * weight10_ch1_2D[2] + ch1_5  * weight10_ch1_2D[1] + ch1_4  * weight10_ch1_2D[0]
                            + ch2_14 * weight10_ch2_2D[8] + ch2_13 * weight10_ch2_2D[7] + ch2_12 * weight10_ch2_2D[6]
                            + ch2_10 * weight10_ch2_2D[5] + ch2_9  * weight10_ch2_2D[4] + ch2_8  * weight10_ch2_2D[3]
                            + ch2_6  * weight10_ch2_2D[2] + ch2_5  * weight10_ch2_2D[1] + ch2_4  * weight10_ch2_2D[0]
                            + ch3_14 * weight10_ch3_2D[8] + ch3_13 * weight10_ch3_2D[7] + ch3_12 * weight10_ch3_2D[6]
                            + ch3_10 * weight10_ch3_2D[5] + ch3_9  * weight10_ch3_2D[4] + ch3_8  * weight10_ch3_2D[3]
                            + ch3_6  * weight10_ch3_2D[2] + ch3_5  * weight10_ch3_2D[1] + ch3_4  * weight10_ch3_2D[0];

            origin_sum1_ch2 = ch0_11 * weight10_ch0_2D[8] + ch0_10 * weight10_ch0_2D[7] + ch0_9  * weight10_ch0_2D[6]
                            + ch0_7  * weight10_ch0_2D[5] + ch0_6  * weight10_ch0_2D[4] + ch0_5  * weight10_ch0_2D[3]
                            + ch0_3  * weight10_ch0_2D[2] + ch0_2  * weight10_ch0_2D[1] + ch0_1  * weight10_ch0_2D[0]
                            + ch1_11 * weight10_ch1_2D[8] + ch1_10 * weight10_ch1_2D[7] + ch1_9  * weight10_ch1_2D[6]
                            + ch1_7  * weight10_ch1_2D[5] + ch1_6  * weight10_ch1_2D[4] + ch1_5  * weight10_ch1_2D[3]
                            + ch1_3  * weight10_ch1_2D[2] + ch1_2  * weight10_ch1_2D[1] + ch1_1  * weight10_ch1_2D[0]
                            + ch2_11 * weight10_ch2_2D[8] + ch2_10 * weight10_ch2_2D[7] + ch2_9  * weight10_ch2_2D[6]
                            + ch2_7  * weight10_ch2_2D[5] + ch2_6  * weight10_ch2_2D[4] + ch2_5  * weight10_ch2_2D[3]
                            + ch2_3  * weight10_ch2_2D[2] + ch2_2  * weight10_ch2_2D[1] + ch2_1  * weight10_ch2_2D[0]
                            + ch3_11 * weight10_ch3_2D[8] + ch3_10 * weight10_ch3_2D[7] + ch3_9  * weight10_ch3_2D[6]
                            + ch3_7  * weight10_ch3_2D[5] + ch3_6  * weight10_ch3_2D[4] + ch3_5  * weight10_ch3_2D[3]
                            + ch3_3  * weight10_ch3_2D[2] + ch3_2  * weight10_ch3_2D[1] + ch3_1  * weight10_ch3_2D[0];

            origin_sum0_ch2 = ch0_10 * weight10_ch0_2D[8] + ch0_9  * weight10_ch0_2D[7] + ch0_8  * weight10_ch0_2D[6]
                            + ch0_6  * weight10_ch0_2D[5] + ch0_5  * weight10_ch0_2D[4] + ch0_4  * weight10_ch0_2D[3]
                            + ch0_2  * weight10_ch0_2D[2] + ch0_1  * weight10_ch0_2D[1] + ch0_0  * weight10_ch0_2D[0]
                            + ch1_10 * weight10_ch1_2D[8] + ch1_9  * weight10_ch1_2D[7] + ch1_8  * weight10_ch1_2D[6]
                            + ch1_6  * weight10_ch1_2D[5] + ch1_5  * weight10_ch1_2D[4] + ch1_4  * weight10_ch1_2D[3]
                            + ch1_2  * weight10_ch1_2D[2] + ch1_1  * weight10_ch1_2D[1] + ch1_0  * weight10_ch1_2D[0]
                            + ch2_10 * weight10_ch2_2D[8] + ch2_9  * weight10_ch2_2D[7] + ch2_8  * weight10_ch2_2D[6]
                            + ch2_6  * weight10_ch2_2D[5] + ch2_5  * weight10_ch2_2D[4] + ch2_4  * weight10_ch2_2D[3]
                            + ch2_2  * weight10_ch2_2D[2] + ch2_1  * weight10_ch2_2D[1] + ch2_0  * weight10_ch2_2D[0]
                            + ch3_10 * weight10_ch3_2D[8] + ch3_9  * weight10_ch3_2D[7] + ch3_8  * weight10_ch3_2D[6]
                            + ch3_6  * weight10_ch3_2D[5] + ch3_5  * weight10_ch3_2D[4] + ch3_4  * weight10_ch3_2D[3]
                            + ch3_2  * weight10_ch3_2D[2] + ch3_1  * weight10_ch3_2D[1] + ch3_0  * weight10_ch3_2D[0];

            origin_sum3_ch3 = ch0_15 * weight11_ch0_2D[8] + ch0_14 * weight11_ch0_2D[7] + ch0_13 * weight11_ch0_2D[6]
                            + ch0_11 * weight11_ch0_2D[5] + ch0_10 * weight11_ch0_2D[4] + ch0_9  * weight11_ch0_2D[3]
                            + ch0_7  * weight11_ch0_2D[2] + ch0_6  * weight11_ch0_2D[1] + ch0_5  * weight11_ch0_2D[0]
                            + ch1_15 * weight11_ch1_2D[8] + ch1_14 * weight11_ch1_2D[7] + ch1_13 * weight11_ch1_2D[6]
                            + ch1_11 * weight11_ch1_2D[5] + ch1_10 * weight11_ch1_2D[4] + ch1_9  * weight11_ch1_2D[3]
                            + ch1_7  * weight11_ch1_2D[2] + ch1_6  * weight11_ch1_2D[1] + ch1_5  * weight11_ch1_2D[0]
                            + ch2_15 * weight11_ch2_2D[8] + ch2_14 * weight11_ch2_2D[7] + ch2_13 * weight11_ch2_2D[6]
                            + ch2_11 * weight11_ch2_2D[5] + ch2_10 * weight11_ch2_2D[4] + ch2_9  * weight11_ch2_2D[3]
                            + ch2_7  * weight11_ch2_2D[2] + ch2_6  * weight11_ch2_2D[1] + ch2_5  * weight11_ch2_2D[0]
                            + ch3_15 * weight11_ch3_2D[8] + ch3_14 * weight11_ch3_2D[7] + ch3_13 * weight11_ch3_2D[6]
                            + ch3_11 * weight11_ch3_2D[5] + ch3_10 * weight11_ch3_2D[4] + ch3_9  * weight11_ch3_2D[3]
                            + ch3_7  * weight11_ch3_2D[2] + ch3_6  * weight11_ch3_2D[1] + ch3_5  * weight11_ch3_2D[0];

            origin_sum2_ch3 = ch0_14 * weight11_ch0_2D[8] + ch0_13 * weight11_ch0_2D[7] + ch0_12 * weight11_ch0_2D[6]
                            + ch0_10 * weight11_ch0_2D[5] + ch0_9  * weight11_ch0_2D[4] + ch0_8  * weight11_ch0_2D[3]
                            + ch0_6  * weight11_ch0_2D[2] + ch0_5  * weight11_ch0_2D[1] + ch0_4  * weight11_ch0_2D[0]
                            + ch1_14 * weight11_ch1_2D[8] + ch1_13 * weight11_ch1_2D[7] + ch1_12 * weight11_ch1_2D[6]
                            + ch1_10 * weight11_ch1_2D[5] + ch1_9  * weight11_ch1_2D[4] + ch1_8  * weight11_ch1_2D[3]
                            + ch1_6  * weight11_ch1_2D[2] + ch1_5  * weight11_ch1_2D[1] + ch1_4  * weight11_ch1_2D[0]
                            + ch2_14 * weight11_ch2_2D[8] + ch2_13 * weight11_ch2_2D[7] + ch2_12 * weight11_ch2_2D[6]
                            + ch2_10 * weight11_ch2_2D[5] + ch2_9  * weight11_ch2_2D[4] + ch2_8  * weight11_ch2_2D[3]
                            + ch2_6  * weight11_ch2_2D[2] + ch2_5  * weight11_ch2_2D[1] + ch2_4  * weight11_ch2_2D[0]
                            + ch3_14 * weight11_ch3_2D[8] + ch3_13 * weight11_ch3_2D[7] + ch3_12 * weight11_ch3_2D[6]
                            + ch3_10 * weight11_ch3_2D[5] + ch3_9  * weight11_ch3_2D[4] + ch3_8  * weight11_ch3_2D[3]
                            + ch3_6  * weight11_ch3_2D[2] + ch3_5  * weight11_ch3_2D[1] + ch3_4  * weight11_ch3_2D[0];

            origin_sum1_ch3 = ch0_11 * weight11_ch0_2D[8] + ch0_10 * weight11_ch0_2D[7] + ch0_9  * weight11_ch0_2D[6]
                            + ch0_7  * weight11_ch0_2D[5] + ch0_6  * weight11_ch0_2D[4] + ch0_5  * weight11_ch0_2D[3]
                            + ch0_3  * weight11_ch0_2D[2] + ch0_2  * weight11_ch0_2D[1] + ch0_1  * weight11_ch0_2D[0]
                            + ch1_11 * weight11_ch1_2D[8] + ch1_10 * weight11_ch1_2D[7] + ch1_9  * weight11_ch1_2D[6]
                            + ch1_7  * weight11_ch1_2D[5] + ch1_6  * weight11_ch1_2D[4] + ch1_5  * weight11_ch1_2D[3]
                            + ch1_3  * weight11_ch1_2D[2] + ch1_2  * weight11_ch1_2D[1] + ch1_1  * weight11_ch1_2D[0]
                            + ch2_11 * weight11_ch2_2D[8] + ch2_10 * weight11_ch2_2D[7] + ch2_9  * weight11_ch2_2D[6]
                            + ch2_7  * weight11_ch2_2D[5] + ch2_6  * weight11_ch2_2D[4] + ch2_5  * weight11_ch2_2D[3]
                            + ch2_3  * weight11_ch2_2D[2] + ch2_2  * weight11_ch2_2D[1] + ch2_1  * weight11_ch2_2D[0]
                            + ch3_11 * weight11_ch3_2D[8] + ch3_10 * weight11_ch3_2D[7] + ch3_9  * weight11_ch3_2D[6]
                            + ch3_7  * weight11_ch3_2D[5] + ch3_6  * weight11_ch3_2D[4] + ch3_5  * weight11_ch3_2D[3]
                            + ch3_3  * weight11_ch3_2D[2] + ch3_2  * weight11_ch3_2D[1] + ch3_1  * weight11_ch3_2D[0];

            origin_sum0_ch3 = ch0_10 * weight11_ch0_2D[8] + ch0_9  * weight11_ch0_2D[7] + ch0_8  * weight11_ch0_2D[6]
                            + ch0_6  * weight11_ch0_2D[5] + ch0_5  * weight11_ch0_2D[4] + ch0_4  * weight11_ch0_2D[3]
                            + ch0_2  * weight11_ch0_2D[2] + ch0_1  * weight11_ch0_2D[1] + ch0_0  * weight11_ch0_2D[0]
                            + ch1_10 * weight11_ch1_2D[8] + ch1_9  * weight11_ch1_2D[7] + ch1_8  * weight11_ch1_2D[6]
                            + ch1_6  * weight11_ch1_2D[5] + ch1_5  * weight11_ch1_2D[4] + ch1_4  * weight11_ch1_2D[3]
                            + ch1_2  * weight11_ch1_2D[2] + ch1_1  * weight11_ch1_2D[1] + ch1_0  * weight11_ch1_2D[0]
                            + ch2_10 * weight11_ch2_2D[8] + ch2_9  * weight11_ch2_2D[7] + ch2_8  * weight11_ch2_2D[6]
                            + ch2_6  * weight11_ch2_2D[5] + ch2_5  * weight11_ch2_2D[4] + ch2_4  * weight11_ch2_2D[3]
                            + ch2_2  * weight11_ch2_2D[2] + ch2_1  * weight11_ch2_2D[1] + ch2_0  * weight11_ch2_2D[0]
                            + ch3_10 * weight11_ch3_2D[8] + ch3_9  * weight11_ch3_2D[7] + ch3_8  * weight11_ch3_2D[6]
                            + ch3_6  * weight11_ch3_2D[5] + ch3_5  * weight11_ch3_2D[4] + ch3_4  * weight11_ch3_2D[3]
                            + ch3_2  * weight11_ch3_2D[2] + ch3_1  * weight11_ch3_2D[1] + ch3_0  * weight11_ch3_2D[0];
        end
        default: begin
            origin_sum3_ch0 = ch0_15 * weight00_ch0_2D[8] + ch0_14 * weight00_ch0_2D[7] + ch0_13 * weight00_ch0_2D[6]
                            + ch0_11 * weight00_ch0_2D[5] + ch0_10 * weight00_ch0_2D[4] + ch0_9  * weight00_ch0_2D[3]
                            + ch0_7  * weight00_ch0_2D[2] + ch0_6  * weight00_ch0_2D[1] + ch0_5  * weight00_ch0_2D[0]
                            + ch1_15 * weight00_ch1_2D[8] + ch1_14 * weight00_ch1_2D[7] + ch1_13 * weight00_ch1_2D[6]
                            + ch1_11 * weight00_ch1_2D[5] + ch1_10 * weight00_ch1_2D[4] + ch1_9  * weight00_ch1_2D[3]
                            + ch1_7  * weight00_ch1_2D[2] + ch1_6  * weight00_ch1_2D[1] + ch1_5  * weight00_ch1_2D[0]
                            + ch2_15 * weight00_ch2_2D[8] + ch2_14 * weight00_ch2_2D[7] + ch2_13 * weight00_ch2_2D[6]
                            + ch2_11 * weight00_ch2_2D[5] + ch2_10 * weight00_ch2_2D[4] + ch2_9  * weight00_ch2_2D[3]
                            + ch2_7  * weight00_ch2_2D[2] + ch2_6  * weight00_ch2_2D[1] + ch2_5  * weight00_ch2_2D[0]
                            + ch3_15 * weight00_ch3_2D[8] + ch3_14 * weight00_ch3_2D[7] + ch3_13 * weight00_ch3_2D[6]
                            + ch3_11 * weight00_ch3_2D[5] + ch3_10 * weight00_ch3_2D[4] + ch3_9  * weight00_ch3_2D[3]
                            + ch3_7  * weight00_ch3_2D[2] + ch3_6  * weight00_ch3_2D[1] + ch3_5  * weight00_ch3_2D[0];

            origin_sum2_ch0 = ch0_14 * weight00_ch0_2D[8] + ch0_13 * weight00_ch0_2D[7] + ch0_12 * weight00_ch0_2D[6]
                            + ch0_10 * weight00_ch0_2D[5] + ch0_9  * weight00_ch0_2D[4] + ch0_8  * weight00_ch0_2D[3]
                            + ch0_6  * weight00_ch0_2D[2] + ch0_5  * weight00_ch0_2D[1] + ch0_4  * weight00_ch0_2D[0]
                            + ch1_14 * weight00_ch1_2D[8] + ch1_13 * weight00_ch1_2D[7] + ch1_12 * weight00_ch1_2D[6]
                            + ch1_10 * weight00_ch1_2D[5] + ch1_9  * weight00_ch1_2D[4] + ch1_8  * weight00_ch1_2D[3]
                            + ch1_6  * weight00_ch1_2D[2] + ch1_5  * weight00_ch1_2D[1] + ch1_4  * weight00_ch1_2D[0]
                            + ch2_14 * weight00_ch2_2D[8] + ch2_13 * weight00_ch2_2D[7] + ch2_12 * weight00_ch2_2D[6]
                            + ch2_10 * weight00_ch2_2D[5] + ch2_9  * weight00_ch2_2D[4] + ch2_8  * weight00_ch2_2D[3]
                            + ch2_6  * weight00_ch2_2D[2] + ch2_5  * weight00_ch2_2D[1] + ch2_4  * weight00_ch2_2D[0]
                            + ch3_14 * weight00_ch3_2D[8] + ch3_13 * weight00_ch3_2D[7] + ch3_12 * weight00_ch3_2D[6]
                            + ch3_10 * weight00_ch3_2D[5] + ch3_9  * weight00_ch3_2D[4] + ch3_8  * weight00_ch3_2D[3]
                            + ch3_6  * weight00_ch3_2D[2] + ch3_5  * weight00_ch3_2D[1] + ch3_4  * weight00_ch3_2D[0];

            origin_sum1_ch0 = ch0_11 * weight00_ch0_2D[8] + ch0_10 * weight00_ch0_2D[7] + ch0_9  * weight00_ch0_2D[6]
                            + ch0_7  * weight00_ch0_2D[5] + ch0_6  * weight00_ch0_2D[4] + ch0_5  * weight00_ch0_2D[3]
                            + ch0_3  * weight00_ch0_2D[2] + ch0_2  * weight00_ch0_2D[1] + ch0_1  * weight00_ch0_2D[0]
                            + ch1_11 * weight00_ch1_2D[8] + ch1_10 * weight00_ch1_2D[7] + ch1_9  * weight00_ch1_2D[6]
                            + ch1_7  * weight00_ch1_2D[5] + ch1_6  * weight00_ch1_2D[4] + ch1_5  * weight00_ch1_2D[3]
                            + ch1_3  * weight00_ch1_2D[2] + ch1_2  * weight00_ch1_2D[1] + ch1_1  * weight00_ch1_2D[0]
                            + ch2_11 * weight00_ch2_2D[8] + ch2_10 * weight00_ch2_2D[7] + ch2_9  * weight00_ch2_2D[6]
                            + ch2_7  * weight00_ch2_2D[5] + ch2_6  * weight00_ch2_2D[4] + ch2_5  * weight00_ch2_2D[3]
                            + ch2_3  * weight00_ch2_2D[2] + ch2_2  * weight00_ch2_2D[1] + ch2_1  * weight00_ch2_2D[0]
                            + ch3_11 * weight00_ch3_2D[8] + ch3_10 * weight00_ch3_2D[7] + ch3_9  * weight00_ch3_2D[6]
                            + ch3_7  * weight00_ch3_2D[5] + ch3_6  * weight00_ch3_2D[4] + ch3_5  * weight00_ch3_2D[3]
                            + ch3_3  * weight00_ch3_2D[2] + ch3_2  * weight00_ch3_2D[1] + ch3_1  * weight00_ch3_2D[0];

            origin_sum0_ch0 = ch0_10 * weight00_ch0_2D[8] + ch0_9  * weight00_ch0_2D[7] + ch0_8  * weight00_ch0_2D[6]
                            + ch0_6  * weight00_ch0_2D[5] + ch0_5  * weight00_ch0_2D[4] + ch0_4  * weight00_ch0_2D[3]
                            + ch0_2  * weight00_ch0_2D[2] + ch0_1  * weight00_ch0_2D[1] + ch0_0  * weight00_ch0_2D[0]
                            + ch1_10 * weight00_ch1_2D[8] + ch1_9  * weight00_ch1_2D[7] + ch1_8  * weight00_ch1_2D[6]
                            + ch1_6  * weight00_ch1_2D[5] + ch1_5  * weight00_ch1_2D[4] + ch1_4  * weight00_ch1_2D[3]
                            + ch1_2  * weight00_ch1_2D[2] + ch1_1  * weight00_ch1_2D[1] + ch1_0  * weight00_ch1_2D[0]
                            + ch2_10 * weight00_ch2_2D[8] + ch2_9  * weight00_ch2_2D[7] + ch2_8  * weight00_ch2_2D[6]
                            + ch2_6  * weight00_ch2_2D[5] + ch2_5  * weight00_ch2_2D[4] + ch2_4  * weight00_ch2_2D[3]
                            + ch2_2  * weight00_ch2_2D[2] + ch2_1  * weight00_ch2_2D[1] + ch2_0  * weight00_ch2_2D[0]
                            + ch3_10 * weight00_ch3_2D[8] + ch3_9  * weight00_ch3_2D[7] + ch3_8  * weight00_ch3_2D[6]
                            + ch3_6  * weight00_ch3_2D[5] + ch3_5  * weight00_ch3_2D[4] + ch3_4  * weight00_ch3_2D[3]
                            + ch3_2  * weight00_ch3_2D[2] + ch3_1  * weight00_ch3_2D[1] + ch3_0  * weight00_ch3_2D[0];

            origin_sum3_ch1 = ch0_15 * weight01_ch0_2D[8] + ch0_14 * weight01_ch0_2D[7] + ch0_13 * weight01_ch0_2D[6]
                            + ch0_11 * weight01_ch0_2D[5] + ch0_10 * weight01_ch0_2D[4] + ch0_9  * weight01_ch0_2D[3]
                            + ch0_7  * weight01_ch0_2D[2] + ch0_6  * weight01_ch0_2D[1] + ch0_5  * weight01_ch0_2D[0]
                            + ch1_15 * weight01_ch1_2D[8] + ch1_14 * weight01_ch1_2D[7] + ch1_13 * weight01_ch1_2D[6]
                            + ch1_11 * weight01_ch1_2D[5] + ch1_10 * weight01_ch1_2D[4] + ch1_9  * weight01_ch1_2D[3]
                            + ch1_7  * weight01_ch1_2D[2] + ch1_6  * weight01_ch1_2D[1] + ch1_5  * weight01_ch1_2D[0]
                            + ch2_15 * weight01_ch2_2D[8] + ch2_14 * weight01_ch2_2D[7] + ch2_13 * weight01_ch2_2D[6]
                            + ch2_11 * weight01_ch2_2D[5] + ch2_10 * weight01_ch2_2D[4] + ch2_9  * weight01_ch2_2D[3]
                            + ch2_7  * weight01_ch2_2D[2] + ch2_6  * weight01_ch2_2D[1] + ch2_5  * weight01_ch2_2D[0]
                            + ch3_15 * weight01_ch3_2D[8] + ch3_14 * weight01_ch3_2D[7] + ch3_13 * weight01_ch3_2D[6]
                            + ch3_11 * weight01_ch3_2D[5] + ch3_10 * weight01_ch3_2D[4] + ch3_9  * weight01_ch3_2D[3]
                            + ch3_7  * weight01_ch3_2D[2] + ch3_6  * weight01_ch3_2D[1] + ch3_5  * weight01_ch3_2D[0];

            origin_sum2_ch1 = ch0_14 * weight01_ch0_2D[8] + ch0_13 * weight01_ch0_2D[7] + ch0_12 * weight01_ch0_2D[6]
                            + ch0_10 * weight01_ch0_2D[5] + ch0_9  * weight01_ch0_2D[4] + ch0_8  * weight01_ch0_2D[3]
                            + ch0_6  * weight01_ch0_2D[2] + ch0_5  * weight01_ch0_2D[1] + ch0_4  * weight01_ch0_2D[0]
                            + ch1_14 * weight01_ch1_2D[8] + ch1_13 * weight01_ch1_2D[7] + ch1_12 * weight01_ch1_2D[6]
                            + ch1_10 * weight01_ch1_2D[5] + ch1_9  * weight01_ch1_2D[4] + ch1_8  * weight01_ch1_2D[3]
                            + ch1_6  * weight01_ch1_2D[2] + ch1_5  * weight01_ch1_2D[1] + ch1_4  * weight01_ch1_2D[0]
                            + ch2_14 * weight01_ch2_2D[8] + ch2_13 * weight01_ch2_2D[7] + ch2_12 * weight01_ch2_2D[6]
                            + ch2_10 * weight01_ch2_2D[5] + ch2_9  * weight01_ch2_2D[4] + ch2_8  * weight01_ch2_2D[3]
                            + ch2_6  * weight01_ch2_2D[2] + ch2_5  * weight01_ch2_2D[1] + ch2_4  * weight01_ch2_2D[0]
                            + ch3_14 * weight01_ch3_2D[8] + ch3_13 * weight01_ch3_2D[7] + ch3_12 * weight01_ch3_2D[6]
                            + ch3_10 * weight01_ch3_2D[5] + ch3_9  * weight01_ch3_2D[4] + ch3_8  * weight01_ch3_2D[3]
                            + ch3_6  * weight01_ch3_2D[2] + ch3_5  * weight01_ch3_2D[1] + ch3_4  * weight01_ch3_2D[0];

            origin_sum1_ch1 = ch0_11 * weight01_ch0_2D[8] + ch0_10 * weight01_ch0_2D[7] + ch0_9  * weight01_ch0_2D[6]
                            + ch0_7  * weight01_ch0_2D[5] + ch0_6  * weight01_ch0_2D[4] + ch0_5  * weight01_ch0_2D[3]
                            + ch0_3  * weight01_ch0_2D[2] + ch0_2  * weight01_ch0_2D[1] + ch0_1  * weight01_ch0_2D[0]
                            + ch1_11 * weight01_ch1_2D[8] + ch1_10 * weight01_ch1_2D[7] + ch1_9  * weight01_ch1_2D[6]
                            + ch1_7  * weight01_ch1_2D[5] + ch1_6  * weight01_ch1_2D[4] + ch1_5  * weight01_ch1_2D[3]
                            + ch1_3  * weight01_ch1_2D[2] + ch1_2  * weight01_ch1_2D[1] + ch1_1  * weight01_ch1_2D[0]
                            + ch2_11 * weight01_ch2_2D[8] + ch2_10 * weight01_ch2_2D[7] + ch2_9  * weight01_ch2_2D[6]
                            + ch2_7  * weight01_ch2_2D[5] + ch2_6  * weight01_ch2_2D[4] + ch2_5  * weight01_ch2_2D[3]
                            + ch2_3  * weight01_ch2_2D[2] + ch2_2  * weight01_ch2_2D[1] + ch2_1  * weight01_ch2_2D[0]
                            + ch3_11 * weight01_ch3_2D[8] + ch3_10 * weight01_ch3_2D[7] + ch3_9  * weight01_ch3_2D[6]
                            + ch3_7  * weight01_ch3_2D[5] + ch3_6  * weight01_ch3_2D[4] + ch3_5  * weight01_ch3_2D[3]
                            + ch3_3  * weight01_ch3_2D[2] + ch3_2  * weight01_ch3_2D[1] + ch3_1  * weight01_ch3_2D[0];

            origin_sum0_ch1 = ch0_10 * weight01_ch0_2D[8] + ch0_9  * weight01_ch0_2D[7] + ch0_8  * weight01_ch0_2D[6]
                            + ch0_6  * weight01_ch0_2D[5] + ch0_5  * weight01_ch0_2D[4] + ch0_4  * weight01_ch0_2D[3]
                            + ch0_2  * weight01_ch0_2D[2] + ch0_1  * weight01_ch0_2D[1] + ch0_0  * weight01_ch0_2D[0]
                            + ch1_10 * weight01_ch1_2D[8] + ch1_9  * weight01_ch1_2D[7] + ch1_8  * weight01_ch1_2D[6]
                            + ch1_6  * weight01_ch1_2D[5] + ch1_5  * weight01_ch1_2D[4] + ch1_4  * weight01_ch1_2D[3]
                            + ch1_2  * weight01_ch1_2D[2] + ch1_1  * weight01_ch1_2D[1] + ch1_0  * weight01_ch1_2D[0]
                            + ch2_10 * weight01_ch2_2D[8] + ch2_9  * weight01_ch2_2D[7] + ch2_8  * weight01_ch2_2D[6]
                            + ch2_6  * weight01_ch2_2D[5] + ch2_5  * weight01_ch2_2D[4] + ch2_4  * weight01_ch2_2D[3]
                            + ch2_2  * weight01_ch2_2D[2] + ch2_1  * weight01_ch2_2D[1] + ch2_0  * weight01_ch2_2D[0]
                            + ch3_10 * weight01_ch3_2D[8] + ch3_9  * weight01_ch3_2D[7] + ch3_8  * weight01_ch3_2D[6]
                            + ch3_6  * weight01_ch3_2D[5] + ch3_5  * weight01_ch3_2D[4] + ch3_4  * weight01_ch3_2D[3]
                            + ch3_2  * weight01_ch3_2D[2] + ch3_1  * weight01_ch3_2D[1] + ch3_0  * weight01_ch3_2D[0];

            origin_sum3_ch2 = ch0_15 * weight02_ch0_2D[8] + ch0_14 * weight02_ch0_2D[7] + ch0_13 * weight02_ch0_2D[6]
                            + ch0_11 * weight02_ch0_2D[5] + ch0_10 * weight02_ch0_2D[4] + ch0_9  * weight02_ch0_2D[3]
                            + ch0_7  * weight02_ch0_2D[2] + ch0_6  * weight02_ch0_2D[1] + ch0_5  * weight02_ch0_2D[0]
                            + ch1_15 * weight02_ch1_2D[8] + ch1_14 * weight02_ch1_2D[7] + ch1_13 * weight02_ch1_2D[6]
                            + ch1_11 * weight02_ch1_2D[5] + ch1_10 * weight02_ch1_2D[4] + ch1_9  * weight02_ch1_2D[3]
                            + ch1_7  * weight02_ch1_2D[2] + ch1_6  * weight02_ch1_2D[1] + ch1_5  * weight02_ch1_2D[0]
                            + ch2_15 * weight02_ch2_2D[8] + ch2_14 * weight02_ch2_2D[7] + ch2_13 * weight02_ch2_2D[6]
                            + ch2_11 * weight02_ch2_2D[5] + ch2_10 * weight02_ch2_2D[4] + ch2_9  * weight02_ch2_2D[3]
                            + ch2_7  * weight02_ch2_2D[2] + ch2_6  * weight02_ch2_2D[1] + ch2_5  * weight02_ch2_2D[0]
                            + ch3_15 * weight02_ch3_2D[8] + ch3_14 * weight02_ch3_2D[7] + ch3_13 * weight02_ch3_2D[6]
                            + ch3_11 * weight02_ch3_2D[5] + ch3_10 * weight02_ch3_2D[4] + ch3_9  * weight02_ch3_2D[3]
                            + ch3_7  * weight02_ch3_2D[2] + ch3_6  * weight02_ch3_2D[1] + ch3_5  * weight02_ch3_2D[0];

            origin_sum2_ch2 = ch0_14 * weight02_ch0_2D[8] + ch0_13 * weight02_ch0_2D[7] + ch0_12 * weight02_ch0_2D[6]
                            + ch0_10 * weight02_ch0_2D[5] + ch0_9  * weight02_ch0_2D[4] + ch0_8  * weight02_ch0_2D[3]
                            + ch0_6  * weight02_ch0_2D[2] + ch0_5  * weight02_ch0_2D[1] + ch0_4  * weight02_ch0_2D[0]
                            + ch1_14 * weight02_ch1_2D[8] + ch1_13 * weight02_ch1_2D[7] + ch1_12 * weight02_ch1_2D[6]
                            + ch1_10 * weight02_ch1_2D[5] + ch1_9  * weight02_ch1_2D[4] + ch1_8  * weight02_ch1_2D[3]
                            + ch1_6  * weight02_ch1_2D[2] + ch1_5  * weight02_ch1_2D[1] + ch1_4  * weight02_ch1_2D[0]
                            + ch2_14 * weight02_ch2_2D[8] + ch2_13 * weight02_ch2_2D[7] + ch2_12 * weight02_ch2_2D[6]
                            + ch2_10 * weight02_ch2_2D[5] + ch2_9  * weight02_ch2_2D[4] + ch2_8  * weight02_ch2_2D[3]
                            + ch2_6  * weight02_ch2_2D[2] + ch2_5  * weight02_ch2_2D[1] + ch2_4  * weight02_ch2_2D[0]
                            + ch3_14 * weight02_ch3_2D[8] + ch3_13 * weight02_ch3_2D[7] + ch3_12 * weight02_ch3_2D[6]
                            + ch3_10 * weight02_ch3_2D[5] + ch3_9  * weight02_ch3_2D[4] + ch3_8  * weight02_ch3_2D[3]
                            + ch3_6  * weight02_ch3_2D[2] + ch3_5  * weight02_ch3_2D[1] + ch3_4  * weight02_ch3_2D[0];

            origin_sum1_ch2 = ch0_11 * weight02_ch0_2D[8] + ch0_10 * weight02_ch0_2D[7] + ch0_9  * weight02_ch0_2D[6]
                            + ch0_7  * weight02_ch0_2D[5] + ch0_6  * weight02_ch0_2D[4] + ch0_5  * weight02_ch0_2D[3]
                            + ch0_3  * weight02_ch0_2D[2] + ch0_2  * weight02_ch0_2D[1] + ch0_1  * weight02_ch0_2D[0]
                            + ch1_11 * weight02_ch1_2D[8] + ch1_10 * weight02_ch1_2D[7] + ch1_9  * weight02_ch1_2D[6]
                            + ch1_7  * weight02_ch1_2D[5] + ch1_6  * weight02_ch1_2D[4] + ch1_5  * weight02_ch1_2D[3]
                            + ch1_3  * weight02_ch1_2D[2] + ch1_2  * weight02_ch1_2D[1] + ch1_1  * weight02_ch1_2D[0]
                            + ch2_11 * weight02_ch2_2D[8] + ch2_10 * weight02_ch2_2D[7] + ch2_9  * weight02_ch2_2D[6]
                            + ch2_7  * weight02_ch2_2D[5] + ch2_6  * weight02_ch2_2D[4] + ch2_5  * weight02_ch2_2D[3]
                            + ch2_3  * weight02_ch2_2D[2] + ch2_2  * weight02_ch2_2D[1] + ch2_1  * weight02_ch2_2D[0]
                            + ch3_11 * weight02_ch3_2D[8] + ch3_10 * weight02_ch3_2D[7] + ch3_9  * weight02_ch3_2D[6]
                            + ch3_7  * weight02_ch3_2D[5] + ch3_6  * weight02_ch3_2D[4] + ch3_5  * weight02_ch3_2D[3]
                            + ch3_3  * weight02_ch3_2D[2] + ch3_2  * weight02_ch3_2D[1] + ch3_1  * weight02_ch3_2D[0];

            origin_sum0_ch2 = ch0_10 * weight02_ch0_2D[8] + ch0_9  * weight02_ch0_2D[7] + ch0_8  * weight02_ch0_2D[6]
                            + ch0_6  * weight02_ch0_2D[5] + ch0_5  * weight02_ch0_2D[4] + ch0_4  * weight02_ch0_2D[3]
                            + ch0_2  * weight02_ch0_2D[2] + ch0_1  * weight02_ch0_2D[1] + ch0_0  * weight02_ch0_2D[0]
                            + ch1_10 * weight02_ch1_2D[8] + ch1_9  * weight02_ch1_2D[7] + ch1_8  * weight02_ch1_2D[6]
                            + ch1_6  * weight02_ch1_2D[5] + ch1_5  * weight02_ch1_2D[4] + ch1_4  * weight02_ch1_2D[3]
                            + ch1_2  * weight02_ch1_2D[2] + ch1_1  * weight02_ch1_2D[1] + ch1_0  * weight02_ch1_2D[0]
                            + ch2_10 * weight02_ch2_2D[8] + ch2_9  * weight02_ch2_2D[7] + ch2_8  * weight02_ch2_2D[6]
                            + ch2_6  * weight02_ch2_2D[5] + ch2_5  * weight02_ch2_2D[4] + ch2_4  * weight02_ch2_2D[3]
                            + ch2_2  * weight02_ch2_2D[2] + ch2_1  * weight02_ch2_2D[1] + ch2_0  * weight02_ch2_2D[0]
                            + ch3_10 * weight02_ch3_2D[8] + ch3_9  * weight02_ch3_2D[7] + ch3_8  * weight02_ch3_2D[6]
                            + ch3_6  * weight02_ch3_2D[5] + ch3_5  * weight02_ch3_2D[4] + ch3_4  * weight02_ch3_2D[3]
                            + ch3_2  * weight02_ch3_2D[2] + ch3_1  * weight02_ch3_2D[1] + ch3_0  * weight02_ch3_2D[0];

            origin_sum3_ch3 = ch0_15 * weight03_ch0_2D[8] + ch0_14 * weight03_ch0_2D[7] + ch0_13 * weight03_ch0_2D[6]
                            + ch0_11 * weight03_ch0_2D[5] + ch0_10 * weight03_ch0_2D[4] + ch0_9  * weight03_ch0_2D[3]
                            + ch0_7  * weight03_ch0_2D[2] + ch0_6  * weight03_ch0_2D[1] + ch0_5  * weight03_ch0_2D[0]
                            + ch1_15 * weight03_ch1_2D[8] + ch1_14 * weight03_ch1_2D[7] + ch1_13 * weight03_ch1_2D[6]
                            + ch1_11 * weight03_ch1_2D[5] + ch1_10 * weight03_ch1_2D[4] + ch1_9  * weight03_ch1_2D[3]
                            + ch1_7  * weight03_ch1_2D[2] + ch1_6  * weight03_ch1_2D[1] + ch1_5  * weight03_ch1_2D[0]
                            + ch2_15 * weight03_ch2_2D[8] + ch2_14 * weight03_ch2_2D[7] + ch2_13 * weight03_ch2_2D[6]
                            + ch2_11 * weight03_ch2_2D[5] + ch2_10 * weight03_ch2_2D[4] + ch2_9  * weight03_ch2_2D[3]
                            + ch2_7  * weight03_ch2_2D[2] + ch2_6  * weight03_ch2_2D[1] + ch2_5  * weight03_ch2_2D[0]
                            + ch3_15 * weight03_ch3_2D[8] + ch3_14 * weight03_ch3_2D[7] + ch3_13 * weight03_ch3_2D[6]
                            + ch3_11 * weight03_ch3_2D[5] + ch3_10 * weight03_ch3_2D[4] + ch3_9  * weight03_ch3_2D[3]
                            + ch3_7  * weight03_ch3_2D[2] + ch3_6  * weight03_ch3_2D[1] + ch3_5  * weight03_ch3_2D[0];

            origin_sum2_ch3 = ch0_14 * weight03_ch0_2D[8] + ch0_13 * weight03_ch0_2D[7] + ch0_12 * weight03_ch0_2D[6]
                            + ch0_10 * weight03_ch0_2D[5] + ch0_9  * weight03_ch0_2D[4] + ch0_8  * weight03_ch0_2D[3]
                            + ch0_6  * weight03_ch0_2D[2] + ch0_5  * weight03_ch0_2D[1] + ch0_4  * weight03_ch0_2D[0]
                            + ch1_14 * weight03_ch1_2D[8] + ch1_13 * weight03_ch1_2D[7] + ch1_12 * weight03_ch1_2D[6]
                            + ch1_10 * weight03_ch1_2D[5] + ch1_9  * weight03_ch1_2D[4] + ch1_8  * weight03_ch1_2D[3]
                            + ch1_6  * weight03_ch1_2D[2] + ch1_5  * weight03_ch1_2D[1] + ch1_4  * weight03_ch1_2D[0]
                            + ch2_14 * weight03_ch2_2D[8] + ch2_13 * weight03_ch2_2D[7] + ch2_12 * weight03_ch2_2D[6]
                            + ch2_10 * weight03_ch2_2D[5] + ch2_9  * weight03_ch2_2D[4] + ch2_8  * weight03_ch2_2D[3]
                            + ch2_6  * weight03_ch2_2D[2] + ch2_5  * weight03_ch2_2D[1] + ch2_4  * weight03_ch2_2D[0]
                            + ch3_14 * weight03_ch3_2D[8] + ch3_13 * weight03_ch3_2D[7] + ch3_12 * weight03_ch3_2D[6]
                            + ch3_10 * weight03_ch3_2D[5] + ch3_9  * weight03_ch3_2D[4] + ch3_8  * weight03_ch3_2D[3]
                            + ch3_6  * weight03_ch3_2D[2] + ch3_5  * weight03_ch3_2D[1] + ch3_4  * weight03_ch3_2D[0];

            origin_sum1_ch3 = ch0_11 * weight03_ch0_2D[8] + ch0_10 * weight03_ch0_2D[7] + ch0_9  * weight03_ch0_2D[6]
                            + ch0_7  * weight03_ch0_2D[5] + ch0_6  * weight03_ch0_2D[4] + ch0_5  * weight03_ch0_2D[3]
                            + ch0_3  * weight03_ch0_2D[2] + ch0_2  * weight03_ch0_2D[1] + ch0_1  * weight03_ch0_2D[0]
                            + ch1_11 * weight03_ch1_2D[8] + ch1_10 * weight03_ch1_2D[7] + ch1_9  * weight03_ch1_2D[6]
                            + ch1_7  * weight03_ch1_2D[5] + ch1_6  * weight03_ch1_2D[4] + ch1_5  * weight03_ch1_2D[3]
                            + ch1_3  * weight03_ch1_2D[2] + ch1_2  * weight03_ch1_2D[1] + ch1_1  * weight03_ch1_2D[0]
                            + ch2_11 * weight03_ch2_2D[8] + ch2_10 * weight03_ch2_2D[7] + ch2_9  * weight03_ch2_2D[6]
                            + ch2_7  * weight03_ch2_2D[5] + ch2_6  * weight03_ch2_2D[4] + ch2_5  * weight03_ch2_2D[3]
                            + ch2_3  * weight03_ch2_2D[2] + ch2_2  * weight03_ch2_2D[1] + ch2_1  * weight03_ch2_2D[0]
                            + ch3_11 * weight03_ch3_2D[8] + ch3_10 * weight03_ch3_2D[7] + ch3_9  * weight03_ch3_2D[6]
                            + ch3_7  * weight03_ch3_2D[5] + ch3_6  * weight03_ch3_2D[4] + ch3_5  * weight03_ch3_2D[3]
                            + ch3_3  * weight03_ch3_2D[2] + ch3_2  * weight03_ch3_2D[1] + ch3_1  * weight03_ch3_2D[0];

            origin_sum0_ch3 = ch0_10 * weight03_ch0_2D[8] + ch0_9  * weight03_ch0_2D[7] + ch0_8  * weight03_ch0_2D[6]
                            + ch0_6  * weight03_ch0_2D[5] + ch0_5  * weight03_ch0_2D[4] + ch0_4  * weight03_ch0_2D[3]
                            + ch0_2  * weight03_ch0_2D[2] + ch0_1  * weight03_ch0_2D[1] + ch0_0  * weight03_ch0_2D[0]
                            + ch1_10 * weight03_ch1_2D[8] + ch1_9  * weight03_ch1_2D[7] + ch1_8  * weight03_ch1_2D[6]
                            + ch1_6  * weight03_ch1_2D[5] + ch1_5  * weight03_ch1_2D[4] + ch1_4  * weight03_ch1_2D[3]
                            + ch1_2  * weight03_ch1_2D[2] + ch1_1  * weight03_ch1_2D[1] + ch1_0  * weight03_ch1_2D[0]
                            + ch2_10 * weight03_ch2_2D[8] + ch2_9  * weight03_ch2_2D[7] + ch2_8  * weight03_ch2_2D[6]
                            + ch2_6  * weight03_ch2_2D[5] + ch2_5  * weight03_ch2_2D[4] + ch2_4  * weight03_ch2_2D[3]
                            + ch2_2  * weight03_ch2_2D[2] + ch2_1  * weight03_ch2_2D[1] + ch2_0  * weight03_ch2_2D[0]
                            + ch3_10 * weight03_ch3_2D[8] + ch3_9  * weight03_ch3_2D[7] + ch3_8  * weight03_ch3_2D[6]
                            + ch3_6  * weight03_ch3_2D[5] + ch3_5  * weight03_ch3_2D[4] + ch3_4  * weight03_ch3_2D[3]
                            + ch3_2  * weight03_ch3_2D[2] + ch3_1  * weight03_ch3_2D[1] + ch3_0  * weight03_ch3_2D[0];
        end
    endcase

end


// quan + relu
always @* begin
    case (three_cycle_cnt)
        2'd0: begin
            sum3_ch0_acc = (origin_sum3_ch0 + (bias00 <<< 8)) > 0 ? origin_sum3_ch0 + (bias00 <<< 8) : 0;
            sum2_ch0_acc = (origin_sum2_ch0 + (bias00 <<< 8)) > 0 ? origin_sum2_ch0 + (bias00 <<< 8) : 0;
            sum1_ch0_acc = (origin_sum1_ch0 + (bias00 <<< 8)) > 0 ? origin_sum1_ch0 + (bias00 <<< 8) : 0;
            sum0_ch0_acc = (origin_sum0_ch0 + (bias00 <<< 8)) > 0 ? origin_sum0_ch0 + (bias00 <<< 8) : 0;

            sum3_ch1_acc = (origin_sum3_ch1 + (bias01 <<< 8)) > 0 ? origin_sum3_ch1 + (bias01 <<< 8) : 0;
            sum2_ch1_acc = (origin_sum2_ch1 + (bias01 <<< 8)) > 0 ? origin_sum2_ch1 + (bias01 <<< 8) : 0;
            sum1_ch1_acc = (origin_sum1_ch1 + (bias01 <<< 8)) > 0 ? origin_sum1_ch1 + (bias01 <<< 8) : 0;
            sum0_ch1_acc = (origin_sum0_ch1 + (bias01 <<< 8)) > 0 ? origin_sum0_ch1 + (bias01 <<< 8) : 0;

            sum3_ch2_acc = (origin_sum3_ch2 + (bias02 <<< 8)) > 0 ? origin_sum3_ch2 + (bias02 <<< 8) : 0;
            sum2_ch2_acc = (origin_sum2_ch2 + (bias02 <<< 8)) > 0 ? origin_sum2_ch2 + (bias02 <<< 8) : 0;
            sum1_ch2_acc = (origin_sum1_ch2 + (bias02 <<< 8)) > 0 ? origin_sum1_ch2 + (bias02 <<< 8) : 0;
            sum0_ch2_acc = (origin_sum0_ch2 + (bias02 <<< 8)) > 0 ? origin_sum0_ch2 + (bias02 <<< 8) : 0;

            sum3_ch3_acc = (origin_sum3_ch3 + (bias03 <<< 8)) > 0 ? origin_sum3_ch3 + (bias03 <<< 8) : 0;
            sum2_ch3_acc = (origin_sum2_ch3 + (bias03 <<< 8)) > 0 ? origin_sum2_ch3 + (bias03 <<< 8) : 0;
            sum1_ch3_acc = (origin_sum1_ch3 + (bias03 <<< 8)) > 0 ? origin_sum1_ch3 + (bias03 <<< 8) : 0;
            sum0_ch3_acc = (origin_sum0_ch3 + (bias03 <<< 8)) > 0 ? origin_sum0_ch3 + (bias03 <<< 8) : 0;
        end
        2'd1: begin
            sum3_ch0_acc = (origin_sum3_ch0 + (bias04 <<< 8)) > 0 ? origin_sum3_ch0 + (bias04 <<< 8) : 0;
            sum2_ch0_acc = (origin_sum2_ch0 + (bias04 <<< 8)) > 0 ? origin_sum2_ch0 + (bias04 <<< 8) : 0;
            sum1_ch0_acc = (origin_sum1_ch0 + (bias04 <<< 8)) > 0 ? origin_sum1_ch0 + (bias04 <<< 8) : 0;
            sum0_ch0_acc = (origin_sum0_ch0 + (bias04 <<< 8)) > 0 ? origin_sum0_ch0 + (bias04 <<< 8) : 0;

            sum3_ch1_acc = (origin_sum3_ch1 + (bias05 <<< 8)) > 0 ? origin_sum3_ch1 + (bias05 <<< 8) : 0;
            sum2_ch1_acc = (origin_sum2_ch1 + (bias05 <<< 8)) > 0 ? origin_sum2_ch1 + (bias05 <<< 8) : 0;
            sum1_ch1_acc = (origin_sum1_ch1 + (bias05 <<< 8)) > 0 ? origin_sum1_ch1 + (bias05 <<< 8) : 0;
            sum0_ch1_acc = (origin_sum0_ch1 + (bias05 <<< 8)) > 0 ? origin_sum0_ch1 + (bias05 <<< 8) : 0;

            sum3_ch2_acc = (origin_sum3_ch2 + (bias06 <<< 8)) > 0 ? origin_sum3_ch2 + (bias06 <<< 8) : 0;
            sum2_ch2_acc = (origin_sum2_ch2 + (bias06 <<< 8)) > 0 ? origin_sum2_ch2 + (bias06 <<< 8) : 0;
            sum1_ch2_acc = (origin_sum1_ch2 + (bias06 <<< 8)) > 0 ? origin_sum1_ch2 + (bias06 <<< 8) : 0;
            sum0_ch2_acc = (origin_sum0_ch2 + (bias06 <<< 8)) > 0 ? origin_sum0_ch2 + (bias06 <<< 8) : 0;

            sum3_ch3_acc = (origin_sum3_ch3 + (bias07 <<< 8)) > 0 ? origin_sum3_ch3 + (bias07 <<< 8) : 0;
            sum2_ch3_acc = (origin_sum2_ch3 + (bias07 <<< 8)) > 0 ? origin_sum2_ch3 + (bias07 <<< 8) : 0;
            sum1_ch3_acc = (origin_sum1_ch3 + (bias07 <<< 8)) > 0 ? origin_sum1_ch3 + (bias07 <<< 8) : 0;
            sum0_ch3_acc = (origin_sum0_ch3 + (bias07 <<< 8)) > 0 ? origin_sum0_ch3 + (bias07 <<< 8) : 0;
        end
        2'd2: begin
            sum3_ch0_acc = (origin_sum3_ch0 + (bias08 <<< 8)) > 0 ? origin_sum3_ch0 + (bias08 <<< 8) : 0;
            sum2_ch0_acc = (origin_sum2_ch0 + (bias08 <<< 8)) > 0 ? origin_sum2_ch0 + (bias08 <<< 8) : 0;
            sum1_ch0_acc = (origin_sum1_ch0 + (bias08 <<< 8)) > 0 ? origin_sum1_ch0 + (bias08 <<< 8) : 0;
            sum0_ch0_acc = (origin_sum0_ch0 + (bias08 <<< 8)) > 0 ? origin_sum0_ch0 + (bias08 <<< 8) : 0;

            sum3_ch1_acc = (origin_sum3_ch1 + (bias09 <<< 8)) > 0 ? origin_sum3_ch1 + (bias09 <<< 8) : 0;
            sum2_ch1_acc = (origin_sum2_ch1 + (bias09 <<< 8)) > 0 ? origin_sum2_ch1 + (bias09 <<< 8) : 0;
            sum1_ch1_acc = (origin_sum1_ch1 + (bias09 <<< 8)) > 0 ? origin_sum1_ch1 + (bias09 <<< 8) : 0;
            sum0_ch1_acc = (origin_sum0_ch1 + (bias09 <<< 8)) > 0 ? origin_sum0_ch1 + (bias09 <<< 8) : 0;

            sum3_ch2_acc = (origin_sum3_ch2 + (bias10 <<< 8)) > 0 ? origin_sum3_ch2 + (bias10 <<< 8) : 0;
            sum2_ch2_acc = (origin_sum2_ch2 + (bias10 <<< 8)) > 0 ? origin_sum2_ch2 + (bias10 <<< 8) : 0;
            sum1_ch2_acc = (origin_sum1_ch2 + (bias10 <<< 8)) > 0 ? origin_sum1_ch2 + (bias10 <<< 8) : 0;
            sum0_ch2_acc = (origin_sum0_ch2 + (bias10 <<< 8)) > 0 ? origin_sum0_ch2 + (bias10 <<< 8) : 0;

            sum3_ch3_acc = (origin_sum3_ch3 + (bias11 <<< 8)) > 0 ? origin_sum3_ch3 + (bias11 <<< 8) : 0;
            sum2_ch3_acc = (origin_sum2_ch3 + (bias11 <<< 8)) > 0 ? origin_sum2_ch3 + (bias11 <<< 8) : 0;
            sum1_ch3_acc = (origin_sum1_ch3 + (bias11 <<< 8)) > 0 ? origin_sum1_ch3 + (bias11 <<< 8) : 0;
            sum0_ch3_acc = (origin_sum0_ch3 + (bias11 <<< 8)) > 0 ? origin_sum0_ch3 + (bias11 <<< 8) : 0;
        end
        default: begin
            sum3_ch0_acc = (origin_sum3_ch0 + (bias00 <<< 8)) > 0 ? origin_sum3_ch0 + (bias00 <<< 8) : 0;
            sum2_ch0_acc = (origin_sum2_ch0 + (bias00 <<< 8)) > 0 ? origin_sum2_ch0 + (bias00 <<< 8) : 0;
            sum1_ch0_acc = (origin_sum1_ch0 + (bias00 <<< 8)) > 0 ? origin_sum1_ch0 + (bias00 <<< 8) : 0;
            sum0_ch0_acc = (origin_sum0_ch0 + (bias00 <<< 8)) > 0 ? origin_sum0_ch0 + (bias00 <<< 8) : 0;

            sum3_ch1_acc = (origin_sum3_ch1 + (bias01 <<< 8)) > 0 ? origin_sum3_ch1 + (bias01 <<< 8) : 0;
            sum2_ch1_acc = (origin_sum2_ch1 + (bias01 <<< 8)) > 0 ? origin_sum2_ch1 + (bias01 <<< 8) : 0;
            sum1_ch1_acc = (origin_sum1_ch1 + (bias01 <<< 8)) > 0 ? origin_sum1_ch1 + (bias01 <<< 8) : 0;
            sum0_ch1_acc = (origin_sum0_ch1 + (bias01 <<< 8)) > 0 ? origin_sum0_ch1 + (bias01 <<< 8) : 0;

            sum3_ch2_acc = (origin_sum3_ch2 + (bias02 <<< 8)) > 0 ? origin_sum3_ch2 + (bias02 <<< 8) : 0;
            sum2_ch2_acc = (origin_sum2_ch2 + (bias02 <<< 8)) > 0 ? origin_sum2_ch2 + (bias02 <<< 8) : 0;
            sum1_ch2_acc = (origin_sum1_ch2 + (bias02 <<< 8)) > 0 ? origin_sum1_ch2 + (bias02 <<< 8) : 0;
            sum0_ch2_acc = (origin_sum0_ch2 + (bias02 <<< 8)) > 0 ? origin_sum0_ch2 + (bias02 <<< 8) : 0;

            sum3_ch3_acc = (origin_sum3_ch3 + (bias03 <<< 8)) > 0 ? origin_sum3_ch3 + (bias03 <<< 8) : 0;
            sum2_ch3_acc = (origin_sum2_ch3 + (bias03 <<< 8)) > 0 ? origin_sum2_ch3 + (bias03 <<< 8) : 0;
            sum1_ch3_acc = (origin_sum1_ch3 + (bias03 <<< 8)) > 0 ? origin_sum1_ch3 + (bias03 <<< 8) : 0;
            sum0_ch3_acc = (origin_sum0_ch3 + (bias03 <<< 8)) > 0 ? origin_sum0_ch3 + (bias03 <<< 8) : 0;
        end
    endcase

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

// set sram_wdata_a_next
always @* begin
    sram_wdata_a_next = {sum3_ch0_final, sum2_ch0_final, sum1_ch0_final, sum0_ch0_final, 
                         sum3_ch1_final, sum2_ch1_final, sum1_ch1_final, sum0_ch1_final,
                         sum3_ch2_final, sum2_ch2_final, sum1_ch2_final, sum0_ch2_final, 
                         sum3_ch3_final, sum2_ch3_final, sum1_ch3_final, sum0_ch3_final};
end

// set sram_waddr_a_next
always @* begin
    sram_waddr_a_next = sram_waddr_a;
    if (conv_cnt_delay == 0) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 0;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 3;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 18;
        else
            sram_waddr_a_next = 0;
    end
    else if (conv_cnt_delay == 1) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 0;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 3;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 18;
        else
            sram_waddr_a_next = 0;
    end
    else if (conv_cnt_delay == 2) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 1;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 4;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 19;
        else
            sram_waddr_a_next = 1;
    end
    else if (conv_cnt_delay == 3) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 1;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 4;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 19;
        else
            sram_waddr_a_next = 1;
    end
    else if (conv_cnt_delay == 4) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 2;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 5;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 20;
        else
            sram_waddr_a_next = 2;
    end
    else if (conv_cnt_delay == 5) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 0;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 3;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 18;
        else
            sram_waddr_a_next = 0;
    end
    else if (conv_cnt_delay == 6) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 0;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 3;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 18;
        else
            sram_waddr_a_next = 0;
    end
    else if (conv_cnt_delay == 7) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 1;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 4;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 19;
        else
            sram_waddr_a_next = 1;
    end
    else if (conv_cnt_delay == 8) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 1;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 4;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 19;
        else
            sram_waddr_a_next = 1;
    end
    else if (conv_cnt_delay == 9) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 2;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 5;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 20;
        else
            sram_waddr_a_next = 2;
    end
    else if (conv_cnt_delay == 10) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 6;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 9;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 24;
        else
            sram_waddr_a_next = 6;
    end
    else if (conv_cnt_delay == 11) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 6;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 9;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 24;
        else
            sram_waddr_a_next = 6;
    end
    else if (conv_cnt_delay == 12) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 7;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 10;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 25;
        else
            sram_waddr_a_next = 7;
    end
    else if (conv_cnt_delay == 13) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 7;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 10;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 25;
        else
            sram_waddr_a_next = 7;
    end
    else if (conv_cnt_delay == 14) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 8;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 11;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 26;
        else
            sram_waddr_a_next = 8;
    end
    else if (conv_cnt_delay == 15) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 6;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 9;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 24;
        else
            sram_waddr_a_next = 6;
    end
    else if (conv_cnt_delay == 16) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 6;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 9;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 24;
        else
            sram_waddr_a_next = 6;
    end
    else if (conv_cnt_delay == 17) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 7;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 10;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 25;
        else
            sram_waddr_a_next = 7;
    end
    else if (conv_cnt_delay == 18) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 7;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 10;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 25;
        else
            sram_waddr_a_next = 7;
    end
    else if (conv_cnt_delay == 19) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 8;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 11;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 26;
        else
            sram_waddr_a_next = 8;
    end
    else if (conv_cnt_delay == 20) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 12;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 15;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 30;
        else
            sram_waddr_a_next = 12;
    end
    else if (conv_cnt_delay == 21) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 12;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 15;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 30;
        else
            sram_waddr_a_next = 12;
    end
    else if (conv_cnt_delay == 22) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 13;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 16;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 31;
        else
            sram_waddr_a_next = 13;
    end
    else if (conv_cnt_delay == 23) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 13;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 16;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 31;
        else
            sram_waddr_a_next = 13;
    end
    else if (conv_cnt_delay == 24) begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 14;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 17;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 32;
        else
            sram_waddr_a_next = 14;
    end
    else begin
        if (three_cycle_cnt == 0)
            sram_waddr_a_next = 0;
        else if (three_cycle_cnt == 1)
            sram_waddr_a_next = 3;
        else if (three_cycle_cnt == 2)
            sram_waddr_a_next = 18;
        else
            sram_waddr_a_next = 0;
    end
end

// set sram_wordmask_a_next
always @* begin
    if (conv_cnt_delay >= 0 && conv_cnt_delay <= 24) begin
        sram_wordmask_a_next = 16'b0000_0000_0000_0000;
    end
    else if (conv_cnt_delay == 24 && three_cycle_cnt == 2) begin
        sram_wordmask_a_next = 16'b1111_1111_1111_1111;
    end
    else begin
        sram_wordmask_a_next = 16'b1111_1111_1111_1111;
    end
end

// set valid_next
always @* begin 
    if (conv_cnt == 26) begin
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
            if (state == CONV2) begin
                local_state_next = READ_WEIGHT;
            end
            else begin
                local_state_next = WAIT;
            end
        end
        READ_WEIGHT: begin
            if (read_weight_cnt == 48) begin
                local_state_next = READ_BIAS;
            end
            else begin
                local_state_next = READ_WEIGHT;
            end
        end
        READ_BIAS: begin
            if (read_bias_cnt == 12) begin
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

        sram_rdata_b0 <= 0;
        sram_rdata_b1 <= 0;
        sram_rdata_b2 <= 0;
        sram_rdata_b3 <= 0;
        read_weight_cnt <= 0;

        weight00_ch0 <= 0;
        weight00_ch1 <= 0;
        weight00_ch2 <= 0;
        weight00_ch3 <= 0;
        weight01_ch0 <= 0;
        weight01_ch1 <= 0;
        weight01_ch2 <= 0;
        weight01_ch3 <= 0;
        weight02_ch0 <= 0;
        weight02_ch1 <= 0;
        weight02_ch2 <= 0;
        weight02_ch3 <= 0;
        weight03_ch0 <= 0;
        weight03_ch1 <= 0;
        weight03_ch2 <= 0;
        weight03_ch3 <= 0;
        weight04_ch0 <= 0;
        weight04_ch1 <= 0;
        weight04_ch2 <= 0;
        weight04_ch3 <= 0;
        weight05_ch0 <= 0;
        weight05_ch1 <= 0;
        weight05_ch2 <= 0;
        weight05_ch3 <= 0;
        weight06_ch0 <= 0;
        weight06_ch1 <= 0;
        weight06_ch2 <= 0;
        weight06_ch3 <= 0;
        weight07_ch0 <= 0;
        weight07_ch1 <= 0;
        weight07_ch2 <= 0;
        weight07_ch3 <= 0;
        weight08_ch0 <= 0;
        weight08_ch1 <= 0;
        weight08_ch2 <= 0;
        weight08_ch3 <= 0;
        weight09_ch0 <= 0;
        weight09_ch1 <= 0;
        weight09_ch2 <= 0;
        weight09_ch3 <= 0;
        weight10_ch0 <= 0;
        weight10_ch1 <= 0;
        weight10_ch2 <= 0;
        weight10_ch3 <= 0;
        weight11_ch0 <= 0;
        weight11_ch1 <= 0;
        weight11_ch2 <= 0;
        weight11_ch3 <= 0;

        read_bias_cnt <= 0;

        bias00 <= 0;
        bias01 <= 0;
        bias02 <= 0;
        bias03 <= 0;
        bias04 <= 0;
        bias05 <= 0;
        bias06 <= 0;
        bias07 <= 0;
        bias08 <= 0;
        bias09 <= 0;
        bias10 <= 0;
        bias11 <= 0;

        conv_cnt <= 0;
        three_cycle_cnt <= 0;

        sram_raddr_b0 <= 0;
        sram_raddr_b1 <= 0;
        sram_raddr_b2 <= 0;
        sram_raddr_b3 <= 0;

        sram_wdata_a <= 0;
        sram_waddr_a <= 0;
        sram_wordmask_a <= 16'b1111_1111_1111_1111;
        sram_wen_a0 <= 1;
        sram_wen_a1 <= 1;
        sram_wen_a2 <= 1;
        sram_wen_a3 <= 1;

        valid <= 0;
    end
    else begin
        local_state <= local_state_next;

        sram_rdata_b0 <= sram_rdata_b0_in;
        sram_rdata_b1 <= sram_rdata_b1_in;
        sram_rdata_b2 <= sram_rdata_b2_in;
        sram_rdata_b3 <= sram_rdata_b3_in;
        read_weight_cnt <= read_weight_cnt_next;

        weight00_ch0 <= weight00_ch0_next;
        weight00_ch1 <= weight00_ch1_next;
        weight00_ch2 <= weight00_ch2_next;
        weight00_ch3 <= weight00_ch3_next;
        weight01_ch0 <= weight01_ch0_next;
        weight01_ch1 <= weight01_ch1_next;
        weight01_ch2 <= weight01_ch2_next;
        weight01_ch3 <= weight01_ch3_next;
        weight02_ch0 <= weight02_ch0_next;
        weight02_ch1 <= weight02_ch1_next;
        weight02_ch2 <= weight02_ch2_next;
        weight02_ch3 <= weight02_ch3_next;
        weight03_ch0 <= weight03_ch0_next;
        weight03_ch1 <= weight03_ch1_next;
        weight03_ch2 <= weight03_ch2_next;
        weight03_ch3 <= weight03_ch3_next;
        weight04_ch0 <= weight04_ch0_next;
        weight04_ch1 <= weight04_ch1_next;
        weight04_ch2 <= weight04_ch2_next;
        weight04_ch3 <= weight04_ch3_next;
        weight05_ch0 <= weight05_ch0_next;
        weight05_ch1 <= weight05_ch1_next;
        weight05_ch2 <= weight05_ch2_next;
        weight05_ch3 <= weight05_ch3_next;
        weight06_ch0 <= weight06_ch0_next;
        weight06_ch1 <= weight06_ch1_next;
        weight06_ch2 <= weight06_ch2_next;
        weight06_ch3 <= weight06_ch3_next;
        weight07_ch0 <= weight07_ch0_next;
        weight07_ch1 <= weight07_ch1_next;
        weight07_ch2 <= weight07_ch2_next;
        weight07_ch3 <= weight07_ch3_next;
        weight08_ch0 <= weight08_ch0_next;
        weight08_ch1 <= weight08_ch1_next;
        weight08_ch2 <= weight08_ch2_next;
        weight08_ch3 <= weight08_ch3_next;
        weight09_ch0 <= weight09_ch0_next;
        weight09_ch1 <= weight09_ch1_next;
        weight09_ch2 <= weight09_ch2_next;
        weight09_ch3 <= weight09_ch3_next;
        weight10_ch0 <= weight10_ch0_next;
        weight10_ch1 <= weight10_ch1_next;
        weight10_ch2 <= weight10_ch2_next;
        weight10_ch3 <= weight10_ch3_next;
        weight11_ch0 <= weight11_ch0_next;
        weight11_ch1 <= weight11_ch1_next;
        weight11_ch2 <= weight11_ch2_next;
        weight11_ch3 <= weight11_ch3_next;

        read_bias_cnt <= read_bias_cnt_next;

        bias00 <= bias00_next;
        bias01 <= bias01_next;
        bias02 <= bias02_next;
        bias03 <= bias03_next;
        bias04 <= bias04_next;
        bias05 <= bias05_next;
        bias06 <= bias06_next;
        bias07 <= bias07_next;
        bias08 <= bias08_next;
        bias09 <= bias09_next;
        bias10 <= bias10_next;
        bias11 <= bias11_next;

        conv_cnt <= conv_cnt_next;
        three_cycle_cnt <= three_cycle_cnt_next;

        sram_raddr_b0 <= sram_raddr_b0_next;
        sram_raddr_b1 <= sram_raddr_b1_next;
        sram_raddr_b2 <= sram_raddr_b2_next;
        sram_raddr_b3 <= sram_raddr_b3_next;

        sram_wdata_a <= sram_wdata_a_next;
        sram_waddr_a <= sram_waddr_a_next;
        sram_wordmask_a <= sram_wordmask_a_next;
        sram_wen_a0 <= sram_wen_a0_next;
        sram_wen_a1 <= sram_wen_a1_next;
        sram_wen_a2 <= sram_wen_a2_next;
        sram_wen_a3 <= sram_wen_a3_next;

        valid <= valid_next;
    end
end

endmodule
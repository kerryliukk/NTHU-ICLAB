module Convnet_top #(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12,
parameter WEIGHT_PER_ADDR = 9, 
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8
)
(
input clk,                          
input rst_n,  // synchronous reset (active low)
input enable, // start sending image from testbanch
output busy,  // control signal for stopping loading input image
output valid, // output valid for testbench to check answers in corresponding SRAM groups
input [BW_PER_ACT-1:0] input_data, // input image data
// read data from SRAM group A
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3,
// read data from SRAM group B
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b0,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b1,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b2,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b3,
// read data from parameter SRAM
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_weight,  
input [BIAS_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_bias,     
// read address to SRAM group A
output reg [5:0] sram_raddr_a0,
output reg [5:0] sram_raddr_a1,
output reg [5:0] sram_raddr_a2,
output reg [5:0] sram_raddr_a3,
// read address to SRAM group B
output reg [5:0] sram_raddr_b0,
output reg [5:0] sram_raddr_b1,
output reg [5:0] sram_raddr_b2,
output reg [5:0] sram_raddr_b3,
// read address to parameter SRAM
output reg [9:0] sram_raddr_weight,       
output reg [5:0] sram_raddr_bias,         
// write enable for SRAM groups A & B
output reg sram_wen_a0,
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,
output reg sram_wen_b0,
output reg sram_wen_b1,
output reg sram_wen_b2,
output reg sram_wen_b3,
// word mask for SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a,
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b,
// write addrress to SRAM groups A & B
output reg [5:0] sram_waddr_a,
output reg [5:0] sram_waddr_b,
// write data to SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a,
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b
);

parameter IDLE = 4'd0, UNSHUFFLE = 4'd1, CONV1 = 4'd2, CONV2 = 4'd3, CONV3 = 4'd4, FINISH = 4'd5;

wire unshuffle_valid, conv1_valid, conv2_valid, conv3_valid;
wire [4-1:0] state;


wire sram_wen_a0_unshuffle, sram_wen_a1_unshuffle, sram_wen_a2_unshuffle, sram_wen_a3_unshuffle;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_unshuffle;
wire [5:0] sram_waddr_a_unshuffle;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a_unshuffle;

wire [5:0] sram_raddr_a0_conv1, sram_raddr_a1_conv1, sram_raddr_a2_conv1, sram_raddr_a3_conv1;
wire sram_wen_b0_conv1, sram_wen_b1_conv1, sram_wen_b2_conv1, sram_wen_b3_conv1;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b_conv1;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b_conv1;
wire [5:0] sram_waddr_b_conv1;
wire [9:0] sram_raddr_weight_conv1;       
wire [5:0] sram_raddr_bias_conv1;

wire [5:0] sram_raddr_b0_conv2, sram_raddr_b1_conv2, sram_raddr_b2_conv2, sram_raddr_b3_conv2;
wire sram_wen_a0_conv2, sram_wen_a1_conv2, sram_wen_a2_conv2, sram_wen_a3_conv2;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_conv2;
wire [5:0] sram_waddr_a_conv2;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a_conv2;
wire [9:0] sram_raddr_weight_conv2;       
wire [5:0] sram_raddr_bias_conv2;


wire [5:0] sram_raddr_a0_conv3, sram_raddr_a1_conv3, sram_raddr_a2_conv3, sram_raddr_a3_conv3;
wire [9:0] sram_raddr_weight_conv3;       
wire [5:0] sram_raddr_bias_conv3;
wire sram_wen_b0_conv3, sram_wen_b1_conv3, sram_wen_b2_conv3, sram_wen_b3_conv3;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b_conv3;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b_conv3;
wire [5:0] sram_waddr_b_conv3;




assign valid = conv3_valid;

FSM U0 (
.clk(clk),
.rst_n(rst_n), 
.enable(enable),
.unshuffle_valid(unshuffle_valid), 
.conv1_valid(conv1_valid), 
.conv2_valid(conv2_valid), 
.conv3_valid(conv3_valid), 
.state(state)
);

Unshuffle_module #(.CH_NUM(CH_NUM), .ACT_PER_ADDR(ACT_PER_ADDR), .BW_PER_ACT(BW_PER_ACT)) U1 (
.clk(clk),
.rst_n(rst_n),  
.enable(enable),
.busy(busy),
.valid(unshuffle_valid),
.input_data(input_data),

.state(state), 

.sram_wen_a0(sram_wen_a0_unshuffle),
.sram_wen_a1(sram_wen_a1_unshuffle),
.sram_wen_a2(sram_wen_a2_unshuffle),
.sram_wen_a3(sram_wen_a3_unshuffle),
.sram_wordmask_a(sram_wordmask_a_unshuffle),
.sram_waddr_a(sram_waddr_a_unshuffle),
.sram_wdata_a(sram_wdata_a_unshuffle)
);

Conv1_module #(.CH_NUM(CH_NUM),
.ACT_PER_ADDR(ACT_PER_ADDR),
.BW_PER_ACT(BW_PER_ACT),
.WEIGHT_PER_ADDR(WEIGHT_PER_ADDR), 
.BIAS_PER_ADDR(BIAS_PER_ADDR),
.BW_PER_PARAM(BW_PER_PARAM)
) U2 (
.clk(clk), 
.rst_n(rst_n), 
.state(state), 
.sram_rdata_weight(sram_rdata_weight),
.sram_rdata_bias(sram_rdata_bias),
.sram_rdata_a0_in(sram_rdata_a0), 
.sram_rdata_a1_in(sram_rdata_a1), 
.sram_rdata_a2_in(sram_rdata_a2), 
.sram_rdata_a3_in(sram_rdata_a3), 
.sram_raddr_a0(sram_raddr_a0_conv1),
.sram_raddr_a1(sram_raddr_a1_conv1), 
.sram_raddr_a2(sram_raddr_a2_conv1), 
.sram_raddr_a3(sram_raddr_a3_conv1), 

.sram_raddr_weight(sram_raddr_weight_conv1),       
.sram_raddr_bias(sram_raddr_bias_conv1),

.sram_wen_b0(sram_wen_b0_conv1),
.sram_wen_b1(sram_wen_b1_conv1),
.sram_wen_b2(sram_wen_b2_conv1),
.sram_wen_b3(sram_wen_b3_conv1),

.sram_wordmask_b(sram_wordmask_b_conv1),
.sram_waddr_b(sram_waddr_b_conv1),
.sram_wdata_b(sram_wdata_b_conv1),

.valid(conv1_valid)
);

Conv2_module #(
.CH_NUM(CH_NUM),
.ACT_PER_ADDR(ACT_PER_ADDR),
.BW_PER_ACT(BW_PER_ACT),
.WEIGHT_PER_ADDR(WEIGHT_PER_ADDR), 
.BIAS_PER_ADDR(BIAS_PER_ADDR),
.BW_PER_PARAM(BW_PER_PARAM)
) U3 (
.clk(clk), 
.rst_n(rst_n), 
.state(state), 
.sram_rdata_weight(sram_rdata_weight),
.sram_rdata_bias(sram_rdata_bias),
.sram_rdata_b0_in(sram_rdata_b0),
.sram_rdata_b1_in(sram_rdata_b1),
.sram_rdata_b2_in(sram_rdata_b2),
.sram_rdata_b3_in(sram_rdata_b3),

.sram_raddr_weight(sram_raddr_weight_conv2),       
.sram_raddr_bias(sram_raddr_bias_conv2),
 
.sram_raddr_b0(sram_raddr_b0_conv2),
.sram_raddr_b1(sram_raddr_b1_conv2),
.sram_raddr_b2(sram_raddr_b2_conv2),
.sram_raddr_b3(sram_raddr_b3_conv2),

.sram_wen_a0(sram_wen_a0_conv2),
.sram_wen_a1(sram_wen_a1_conv2),
.sram_wen_a2(sram_wen_a2_conv2),
.sram_wen_a3(sram_wen_a3_conv2),

.sram_wordmask_a(sram_wordmask_a_conv2),
.sram_waddr_a(sram_waddr_a_conv2),
.sram_wdata_a(sram_wdata_a_conv2),
.valid(conv2_valid)
);


Conv3_module #(.CH_NUM(CH_NUM),
.ACT_PER_ADDR(ACT_PER_ADDR),
.BW_PER_ACT(BW_PER_ACT),
.WEIGHT_PER_ADDR(WEIGHT_PER_ADDR), 
.BIAS_PER_ADDR(BIAS_PER_ADDR),
.BW_PER_PARAM(BW_PER_PARAM)
) U4 (
.clk(clk), 
.rst_n(rst_n), 
.state(state), 
.sram_rdata_weight(sram_rdata_weight),
.sram_rdata_bias(sram_rdata_bias),
.sram_rdata_a0_in(sram_rdata_a0), 
.sram_rdata_a1_in(sram_rdata_a1), 
.sram_rdata_a2_in(sram_rdata_a2), 
.sram_rdata_a3_in(sram_rdata_a3), 
.sram_raddr_a0(sram_raddr_a0_conv3),
.sram_raddr_a1(sram_raddr_a1_conv3), 
.sram_raddr_a2(sram_raddr_a2_conv3), 
.sram_raddr_a3(sram_raddr_a3_conv3), 

.sram_raddr_weight(sram_raddr_weight_conv3),
.sram_raddr_bias(sram_raddr_bias_conv3),

.sram_wen_b0(sram_wen_b0_conv3),
.sram_wen_b1(sram_wen_b1_conv3),
.sram_wen_b2(sram_wen_b2_conv3),
.sram_wen_b3(sram_wen_b3_conv3),

.sram_wordmask_b(sram_wordmask_b_conv3),
.sram_waddr_b(sram_waddr_b_conv3),
.sram_wdata_b(sram_wdata_b_conv3),

.valid(conv3_valid)
);



// choose sram_raddr_weight
always @* begin
    case (state)
        CONV1: begin
            sram_raddr_weight = sram_raddr_weight_conv1;
        end
        CONV2: begin
            sram_raddr_weight = sram_raddr_weight_conv2;
        end
        CONV3: begin
            sram_raddr_weight = sram_raddr_weight_conv3;
        end
        default: begin
            sram_raddr_weight = 0;
        end
    endcase
end


// choose sram_raddr_bias
always @* begin
    case (state)
        CONV1: begin
            sram_raddr_bias = sram_raddr_bias_conv1;
        end
        CONV2: begin
            sram_raddr_bias = sram_raddr_bias_conv2;
        end
        CONV3: begin
            sram_raddr_bias = sram_raddr_bias_conv3;
        end
        default: begin
            sram_raddr_bias = 0;
        end
    endcase
end

// choose sram_waddr_b
always @* begin
    case (state)
        CONV1: begin
            sram_waddr_b = sram_waddr_b_conv1;
        end
        CONV3: begin
            sram_waddr_b = sram_waddr_b_conv3;
        end
        default: begin
            sram_waddr_b = 0;
        end
    endcase
end

// choose sram_wen_a0 ~ sram_wen_a3
always @* begin
    case (state)
        UNSHUFFLE: begin
            sram_wen_a0 = sram_wen_a0_unshuffle;
            sram_wen_a1 = sram_wen_a1_unshuffle;
            sram_wen_a2 = sram_wen_a2_unshuffle;
            sram_wen_a3 = sram_wen_a3_unshuffle;
        end
        CONV2: begin
            sram_wen_a0 = sram_wen_a0_conv2;
            sram_wen_a1 = sram_wen_a1_conv2;
            sram_wen_a2 = sram_wen_a2_conv2;
            sram_wen_a3 = sram_wen_a3_conv2;
        end
        default: begin
            sram_wen_a0 = 1;
            sram_wen_a1 = 1;
            sram_wen_a2 = 1;
            sram_wen_a3 = 1;
        end
    endcase
end

// choose sram_wen_b0 ~ sram_wen_b3
always @* begin
    case (state)
        CONV1: begin
            sram_wen_b0 = sram_wen_b0_conv1;
            sram_wen_b1 = sram_wen_b1_conv1;
            sram_wen_b2 = sram_wen_b2_conv1;
            sram_wen_b3 = sram_wen_b3_conv1;
        end
        CONV3: begin
            sram_wen_b0 = sram_wen_b0_conv3;
            sram_wen_b1 = sram_wen_b1_conv3;
            sram_wen_b2 = sram_wen_b2_conv3;
            sram_wen_b3 = sram_wen_b3_conv3;
        end
        default: begin
            sram_wen_b0 = 1;
            sram_wen_b1 = 1;
            sram_wen_b2 = 1;
            sram_wen_b3 = 1;
        end
    endcase
end


// choose sram_wordmask_a
always @* begin
    case (state)
        UNSHUFFLE: begin
            sram_wordmask_a = sram_wordmask_a_unshuffle;
        end
        CONV2: begin
            sram_wordmask_a = sram_wordmask_a_conv2;
        end
        default: begin
            sram_wordmask_a = 16'b1111_1111_1111_1111;
        end
    endcase
end


// choose sram_wordmask_b
always @* begin
    case (state)
        CONV1: begin
            sram_wordmask_b = sram_wordmask_b_conv1;
        end
        CONV3: begin
            sram_wordmask_b = sram_wordmask_b_conv3;
        end
        default: begin
            sram_wordmask_b = 16'b1111_1111_1111_1111;
        end
    endcase
end


// choose sram_waddr_a
always @* begin
    case (state)
        UNSHUFFLE: begin
            sram_waddr_a = sram_waddr_a_unshuffle;
        end
        CONV2: begin
            sram_waddr_a = sram_waddr_a_conv2;
        end
        default: begin
            sram_waddr_a = 0;
        end
    endcase
end

// choose sram_wdata_a
always @* begin
    case (state)
        UNSHUFFLE: begin
            sram_wdata_a = sram_wdata_a_unshuffle;
        end
        CONV2: begin
            sram_wdata_a = sram_wdata_a_conv2;
        end
        default: begin
            sram_wdata_a = 0;
        end
    endcase
end


// choose sram_raddr_a0 ~ sram_raddr_a3
always @* begin
    case (state)
        CONV1: begin
            sram_raddr_a0 = sram_raddr_a0_conv1;
            sram_raddr_a1 = sram_raddr_a1_conv1;
            sram_raddr_a2 = sram_raddr_a2_conv1;
            sram_raddr_a3 = sram_raddr_a3_conv1;
        end
        CONV3: begin
            sram_raddr_a0 = sram_raddr_a0_conv3;
            sram_raddr_a1 = sram_raddr_a1_conv3;
            sram_raddr_a2 = sram_raddr_a2_conv3;
            sram_raddr_a3 = sram_raddr_a3_conv3;
        end
        default: begin
            sram_raddr_a0 = 0;
            sram_raddr_a1 = 0;
            sram_raddr_a2 = 0;
            sram_raddr_a3 = 0;
        end
    endcase
end

// choose sram_raddr_b0 ~ sram_raddr_b3
always @* begin
    case (state)
        CONV2: begin
            sram_raddr_b0 = sram_raddr_b0_conv2;
            sram_raddr_b1 = sram_raddr_b1_conv2;
            sram_raddr_b2 = sram_raddr_b2_conv2;
            sram_raddr_b3 = sram_raddr_b3_conv2;
        end
        default: begin
            sram_raddr_b0 = 0;
            sram_raddr_b1 = 0;
            sram_raddr_b2 = 0;
            sram_raddr_b3 = 0;
        end
    endcase
end

// choose sram_wdata_b
always @* begin
    case (state)
        CONV1: begin
            sram_wdata_b = sram_wdata_b_conv1;
        end
        CONV3: begin
            sram_wdata_b = sram_wdata_b_conv3;
        end
        default: begin
            sram_wdata_b = 0;
        end
    endcase
end

endmodule
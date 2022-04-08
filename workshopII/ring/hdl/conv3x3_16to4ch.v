//====================================================================================
//  Module Description: 16 channel to 4 channel 3x3 convolution for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module conv3x3_16to4ch #(
    parameter GROUP_CHANNEL = 16,
    parameter BW_MATMUL = 2*`BITWIDTH+$clog2(4/`N),
    parameter BW_CONV1x1 = BW_MATMUL+2,
    parameter BW_ACCU = BW_CONV1x1+4,
    parameter BW_BIAS = BW_ACCU+1
)(
    input clk,
    input [GROUP_CHANNEL*9*`BITWIDTH-1:0] feature,
    input [4*GROUP_CHANNEL/`N*9*`BITWIDTH-1:0] weight,
    input [4*`BITWIDTH-1:0] bias,
    input [4*`BW_FL-1:0] ftr_fl,
    input [`BW_FL-1:0] wgt_fl,
    input [`BW_FL-1:0] bias_fl,
    output reg [BW_BIAS*4-1:0] conv3x3_4chout
);

// input reorder
reg [16*`BITWIDTH-1:0] feature_1x1 [0:8];
reg [16*`BITWIDTH-1:0] feature_1pix;
reg [`BITWIDTH-1:0] ftr_1ch_1pix;
integer ftr_pix_idx, ftr_ch_idx;
always@*begin
    for(ftr_pix_idx=0;ftr_pix_idx<9;ftr_pix_idx=ftr_pix_idx+1)begin
        feature_1pix=0;
        for(ftr_ch_idx=0;ftr_ch_idx<16;ftr_ch_idx=ftr_ch_idx+1)begin
            ftr_1ch_1pix = feature[((15-ftr_ch_idx)*9+(8-ftr_pix_idx))*`BITWIDTH +:`BITWIDTH];
            feature_1pix[(15-ftr_ch_idx)*`BITWIDTH +:`BITWIDTH] = ftr_1ch_1pix;
        end
        feature_1x1[ftr_pix_idx] = feature_1pix;
    end
end

reg [4*16/`N*`BITWIDTH-1:0] weight_1x1 [0:8];
reg [4*16/`N*`BITWIDTH-1:0] weight_1pix;
reg [`BITWIDTH-1:0] wgt_1ch_1pix;
integer wgt_pix_idx, wgt_chi_idx, wgt_cho_idx;
always@*begin
    for(wgt_pix_idx=0;wgt_pix_idx<9;wgt_pix_idx=wgt_pix_idx+1)begin
        weight_1pix = 0;
        for(wgt_cho_idx=0;wgt_cho_idx<4;wgt_cho_idx=wgt_cho_idx+1)begin
            for(wgt_chi_idx=0;wgt_chi_idx<16;wgt_chi_idx=wgt_chi_idx+1)begin
                wgt_1ch_1pix = weight[(((3-wgt_cho_idx)*16+(15-wgt_chi_idx))*9+(8-wgt_pix_idx))*`BITWIDTH +:`BITWIDTH];
                weight_1pix[((3-wgt_cho_idx)*16+(15-wgt_chi_idx))*`BITWIDTH +:`BITWIDTH] = wgt_1ch_1pix;
            end
        end
        weight_1x1[wgt_pix_idx] = weight_1pix;
    end
end

// 1x1 convolutions
wire [4*BW_CONV1x1-1:0] conv1x1_pix0, conv1x1_pix1, conv1x1_pix2, conv1x1_pix3, conv1x1_pix4, conv1x1_pix5, conv1x1_pix6, conv1x1_pix7, conv1x1_pix8;
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u0(
    .feature(feature_1x1[0]),
    .weight(weight_1x1[0]),
    .conv1x1_4chout(conv1x1_pix0)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u1(
    .feature(feature_1x1[1]),
    .weight(weight_1x1[1]),
    .conv1x1_4chout(conv1x1_pix1)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u2(
    .feature(feature_1x1[2]),
    .weight(weight_1x1[2]),
    .conv1x1_4chout(conv1x1_pix2)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u3(
    .feature(feature_1x1[3]),
    .weight(weight_1x1[3]),
    .conv1x1_4chout(conv1x1_pix3)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u4(
    .feature(feature_1x1[4]),
    .weight(weight_1x1[4]),
    .conv1x1_4chout(conv1x1_pix4)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u5(
    .feature(feature_1x1[5]),
    .weight(weight_1x1[5]),
    .conv1x1_4chout(conv1x1_pix5)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u6(
    .feature(feature_1x1[6]),
    .weight(weight_1x1[6]),
    .conv1x1_4chout(conv1x1_pix6)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u7(
    .feature(feature_1x1[7]),
    .weight(weight_1x1[7]),
    .conv1x1_4chout(conv1x1_pix7)
);
conv1x1_16to4ch#(.BW_MATMUL(BW_MATMUL), .BW_CONV1x1(BW_CONV1x1))
conv1x1_u8(
    .feature(feature_1x1[8]),
    .weight(weight_1x1[8]),
    .conv1x1_4chout(conv1x1_pix8)
);

// 1x1 conv to 3x3 wiring 
wire signed [BW_CONV1x1-1:0] conv1x1_c0_p0, conv1x1_c0_p1, conv1x1_c0_p2, conv1x1_c0_p3, conv1x1_c0_p4, conv1x1_c0_p5, conv1x1_c0_p6, conv1x1_c0_p7, conv1x1_c0_p8;
wire signed [BW_CONV1x1-1:0] conv1x1_c1_p0, conv1x1_c1_p1, conv1x1_c1_p2, conv1x1_c1_p3, conv1x1_c1_p4, conv1x1_c1_p5, conv1x1_c1_p6, conv1x1_c1_p7, conv1x1_c1_p8;
wire signed [BW_CONV1x1-1:0] conv1x1_c2_p0, conv1x1_c2_p1, conv1x1_c2_p2, conv1x1_c2_p3, conv1x1_c2_p4, conv1x1_c2_p5, conv1x1_c2_p6, conv1x1_c2_p7, conv1x1_c2_p8;
wire signed [BW_CONV1x1-1:0] conv1x1_c3_p0, conv1x1_c3_p1, conv1x1_c3_p2, conv1x1_c3_p3, conv1x1_c3_p4, conv1x1_c3_p5, conv1x1_c3_p6, conv1x1_c3_p7, conv1x1_c3_p8;
assign {conv1x1_c0_p0, conv1x1_c1_p0, conv1x1_c2_p0, conv1x1_c3_p0} = conv1x1_pix0;
assign {conv1x1_c0_p1, conv1x1_c1_p1, conv1x1_c2_p1, conv1x1_c3_p1} = conv1x1_pix1;
assign {conv1x1_c0_p2, conv1x1_c1_p2, conv1x1_c2_p2, conv1x1_c3_p2} = conv1x1_pix2;
assign {conv1x1_c0_p3, conv1x1_c1_p3, conv1x1_c2_p3, conv1x1_c3_p3} = conv1x1_pix3;
assign {conv1x1_c0_p4, conv1x1_c1_p4, conv1x1_c2_p4, conv1x1_c3_p4} = conv1x1_pix4;
assign {conv1x1_c0_p5, conv1x1_c1_p5, conv1x1_c2_p5, conv1x1_c3_p5} = conv1x1_pix5;
assign {conv1x1_c0_p6, conv1x1_c1_p6, conv1x1_c2_p6, conv1x1_c3_p6} = conv1x1_pix6;
assign {conv1x1_c0_p7, conv1x1_c1_p7, conv1x1_c2_p7, conv1x1_c3_p7} = conv1x1_pix7;
assign {conv1x1_c0_p8, conv1x1_c1_p8, conv1x1_c2_p8, conv1x1_c3_p8} = conv1x1_pix8;

wire signed [9*BW_CONV1x1-1:0] conv_9pix_ch0, conv_9pix_ch1, conv_9pix_ch2, conv_9pix_ch3;
assign conv_9pix_ch0 = {conv1x1_c0_p0,conv1x1_c0_p1,conv1x1_c0_p2,conv1x1_c0_p3,conv1x1_c0_p4,conv1x1_c0_p5,conv1x1_c0_p6,conv1x1_c0_p7,conv1x1_c0_p8};
assign conv_9pix_ch1 = {conv1x1_c1_p0,conv1x1_c1_p1,conv1x1_c1_p2,conv1x1_c1_p3,conv1x1_c1_p4,conv1x1_c1_p5,conv1x1_c1_p6,conv1x1_c1_p7,conv1x1_c1_p8};
assign conv_9pix_ch2 = {conv1x1_c2_p0,conv1x1_c2_p1,conv1x1_c2_p2,conv1x1_c2_p3,conv1x1_c2_p4,conv1x1_c2_p5,conv1x1_c2_p6,conv1x1_c2_p7,conv1x1_c2_p8};
assign conv_9pix_ch3 = {conv1x1_c3_p0,conv1x1_c3_p1,conv1x1_c3_p2,conv1x1_c3_p3,conv1x1_c3_p4,conv1x1_c3_p5,conv1x1_c3_p6,conv1x1_c3_p7,conv1x1_c3_p8};

// sum 9 pixels and add bias
wire [BW_BIAS-1:0] conv_adder_out_ch0, conv_adder_out_ch1, conv_adder_out_ch2, conv_adder_out_ch3;
wire [4*BW_BIAS-1:0] conv3x3_4chout_n = {conv_adder_out_ch0, conv_adder_out_ch1, conv_adder_out_ch2, conv_adder_out_ch3};
always@(posedge clk)begin
    conv3x3_4chout <= conv3x3_4chout_n;
end
wire [`BW_FL-1:0] ftr_fl_ch0, ftr_fl_ch1, ftr_fl_ch2, ftr_fl_ch3;
assign {ftr_fl_ch0, ftr_fl_ch1, ftr_fl_ch2, ftr_fl_ch3} = ftr_fl;
wire [`BITWIDTH-1:0] bias_ch0, bias_ch1, bias_ch2, bias_ch3;
assign {bias_ch0, bias_ch1, bias_ch2, bias_ch3} = bias;

conv_adder #(.BW_CONV1x1(BW_CONV1x1), .BW_BIAS(BW_BIAS))
conv_adder_U0(
    .add_in(conv_9pix_ch0),
    .bias(bias_ch0),
    .ftr_fl(ftr_fl_ch0),
    .wgt_fl(wgt_fl),
    .bias_fl(bias_fl),
    .add_out(conv_adder_out_ch0)
);
conv_adder #(.BW_CONV1x1(BW_CONV1x1), .BW_BIAS(BW_BIAS))
conv_adder_U1(
    .add_in(conv_9pix_ch1),
    .bias(bias_ch1),
    .ftr_fl(ftr_fl_ch1),
    .wgt_fl(wgt_fl),
    .bias_fl(bias_fl),
    .add_out(conv_adder_out_ch1)
);
conv_adder #(.BW_CONV1x1(BW_CONV1x1), .BW_BIAS(BW_BIAS))
conv_adder_U2(
    .add_in(conv_9pix_ch2),
    .bias(bias_ch2),
    .ftr_fl(ftr_fl_ch2),
    .wgt_fl(wgt_fl),
    .bias_fl(bias_fl),
    .add_out(conv_adder_out_ch2)
);
conv_adder #(.BW_CONV1x1(BW_CONV1x1), .BW_BIAS(BW_BIAS))
conv_adder_U3(
    .add_in(conv_9pix_ch3),
    .bias(bias_ch3),
    .ftr_fl(ftr_fl_ch3),
    .wgt_fl(wgt_fl),
    .bias_fl(bias_fl),
    .add_out(conv_adder_out_ch3)
);

endmodule
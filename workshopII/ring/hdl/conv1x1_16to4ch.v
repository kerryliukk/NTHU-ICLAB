//====================================================================================
//  Module Description: 1x1 convolution with 16 channel input and 4 channel output for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module conv1x1_16to4ch #(
    parameter GROUP_CHANNEL = 16,
    parameter BW_MATMUL = 2*`BITWIDTH+$clog2(4/`N),
    parameter BW_CONV1x1 = BW_MATMUL+2
)(
    input [16*`BITWIDTH-1:0] feature,
    input [4*16/`N*`BITWIDTH-1:0] weight,
    output signed [4*BW_CONV1x1-1:0] conv1x1_4chout
);

// input reorder
wire signed [4*`BITWIDTH-1:0] feature0, feature1, feature2, feature3;
assign {feature0, feature1, feature2, feature3} = feature;
    
wire [`BITWIDTH-1:0] wgt_o0_i00, wgt_o0_i01, wgt_o0_i02, wgt_o0_i03;

wire [`BITWIDTH-1:0] wgt_o1_i00, wgt_o1_i01, wgt_o1_i02, wgt_o1_i03;

wire [`BITWIDTH-1:0] wgt_o2_i00, wgt_o2_i01, wgt_o2_i02, wgt_o2_i03;

wire [`BITWIDTH-1:0] wgt_o3_i00, wgt_o3_i01, wgt_o3_i02, wgt_o3_i03;

assign {wgt_o0_i00, wgt_o0_i01, wgt_o0_i02, wgt_o0_i03, 
        wgt_o1_i00, wgt_o1_i01, wgt_o1_i02, wgt_o1_i03,
        wgt_o2_i00, wgt_o2_i01, wgt_o2_i02, wgt_o2_i03,
        wgt_o3_i00, wgt_o3_i01, wgt_o3_i02, wgt_o3_i03} = weight;

wire [GROUP_CHANNEL/`N*`BITWIDTH-1:0] weight0, weight1, weight2, weight3;
assign weight0 = {wgt_o0_i00, wgt_o1_i00, wgt_o2_i00, wgt_o3_i00};
assign weight1 = {wgt_o0_i01, wgt_o1_i01, wgt_o2_i01, wgt_o3_i01};
assign weight2 = {wgt_o0_i02, wgt_o1_i02, wgt_o2_i02, wgt_o3_i02};
assign weight3 = {wgt_o0_i03, wgt_o1_i03, wgt_o2_i03, wgt_o3_i03};

wire signed [4*BW_MATMUL-1:0] matmul_out0, matmul_out1, matmul_out2, matmul_out3;
wire signed [BW_MATMUL-1:0] matmul0_ch0, matmul0_ch1, matmul0_ch2, matmul0_ch3; 
wire signed [BW_MATMUL-1:0] matmul1_ch0, matmul1_ch1, matmul1_ch2, matmul1_ch3; 
wire signed [BW_MATMUL-1:0] matmul2_ch0, matmul2_ch1, matmul2_ch2, matmul2_ch3; 
wire signed [BW_MATMUL-1:0] matmul3_ch0, matmul3_ch1, matmul3_ch2, matmul3_ch3; 
assign {matmul0_ch0, matmul0_ch1, matmul0_ch2, matmul0_ch3} = matmul_out0;
assign {matmul1_ch0, matmul1_ch1, matmul1_ch2, matmul1_ch3} = matmul_out1;
assign {matmul2_ch0, matmul2_ch1, matmul2_ch2, matmul2_ch3} = matmul_out2;
assign {matmul3_ch0, matmul3_ch1, matmul3_ch2, matmul3_ch3} = matmul_out3;

reg signed [BW_CONV1x1-1:0] conv1x1_0, conv1x1_1, conv1x1_2, conv1x1_3;
assign conv1x1_4chout = {conv1x1_0, conv1x1_1, conv1x1_2 ,conv1x1_3};

// matrix multiplication
matmul#(.BW_MATMUL(BW_MATMUL))
mm_U0(
    .feature(feature0),
    .weight(weight0),
    .matmul_out(matmul_out0)
);

matmul#(.BW_MATMUL(BW_MATMUL))
mm_U1(
    .feature(feature1),
    .weight(weight1),
    .matmul_out(matmul_out1)
);

matmul#(.BW_MATMUL(BW_MATMUL))
mm_U2(
    .feature(feature2),
    .weight(weight2),
    .matmul_out(matmul_out2)
);

matmul#(.BW_MATMUL(BW_MATMUL))
mm_U3(
    .feature(feature3),
    .weight(weight3),
    .matmul_out(matmul_out3)
);

// calculate 4channel output
always@*begin
    conv1x1_0 = matmul0_ch0 + matmul1_ch0 + matmul2_ch0 + matmul3_ch0;
    conv1x1_1 = matmul0_ch1 + matmul1_ch1 + matmul2_ch1 + matmul3_ch1;
    conv1x1_2 = matmul0_ch2 + matmul1_ch2 + matmul2_ch2 + matmul3_ch2;
    conv1x1_3 = matmul0_ch3 + matmul1_ch3 + matmul2_ch3 + matmul3_ch3;
end

endmodule
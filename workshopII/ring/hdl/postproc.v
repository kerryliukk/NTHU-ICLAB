//====================================================================================
//  Module Description: Post CONV layer processing for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module postproc #(
    parameter GROUP_CHANNEL = 16,
    parameter BW_BIAS = 2*`BITWIDTH+4+$clog2(GROUP_CHANNEL)+1, 
    parameter BW_RELU = 2*`BITWIDTH+4+$clog2(GROUP_CHANNEL)+10
)(
    input clk,
    input [`OUT_CHANNEL*BW_BIAS-1:0] post_in,
    input relu,
    input [`OUT_CHANNEL*`BITWIDTH-1:0] identity,
    input residual,
    input [4*`BW_FL-1:0] ftr_fl, // input feature map fractinal length (fl)
    input [`BW_FL-1:0] wgt_fl, // weight fractinal length (fl)
    input [4*`BW_FL-1:0] idt_fl, // identity fractinal length (fl)
    input [4*`BW_FL-1:0] out_fl, // output feature map fractinal length (fl)
    output reg [`OUT_CHANNEL*`BITWIDTH-1:0] post_out
);

// module connection
wire [`OUT_CHANNEL*BW_RELU-1:0] relu_out; // concatenated ReLU inputs
wire [BW_RELU-1:0] relu_ch0, relu_ch1, relu_ch2, relu_ch3;
assign {relu_ch0, relu_ch1, relu_ch2, relu_ch3} = relu_out;
wire [BW_RELU-1:0] residual_out_ch0, residual_out_ch1, residual_out_ch2, residual_out_ch3; // concatenated short-cut addition outputs
wire [`BITWIDTH-1:0] quantizer_out_ch0, quantizer_out_ch1, quantizer_out_ch2, quantizer_out_ch3;          // concatenated Quantization outputs
wire signed [`BITWIDTH-1:0] idt_ch0, idt_ch1, idt_ch2, idt_ch3;
assign {idt_ch0, idt_ch1, idt_ch2, idt_ch3} = identity;

always@(posedge clk) begin
  post_out <= {quantizer_out_ch0, quantizer_out_ch1, quantizer_out_ch2, quantizer_out_ch3};
end

// calculate the shift amount of residual connectin and quantization
wire [`BW_FL-1:0] relu_shift_ch0;
wire [`BW_FL-1:0] relu_shift_ch1;
wire [`BW_FL-1:0] relu_shift_ch2;
wire [`BW_FL-1:0] relu_shift_ch3;

wire [`BW_FL-1:0] residual_shift_ch0;
wire [`BW_FL-1:0] residual_shift_ch1;
wire [`BW_FL-1:0] residual_shift_ch2;
wire [`BW_FL-1:0] residual_shift_ch3;

wire [`BW_FL-1:0] quantizer_shift_ch0;
wire [`BW_FL-1:0] quantizer_shift_ch1;
wire [`BW_FL-1:0] quantizer_shift_ch2;
wire [`BW_FL-1:0] quantizer_shift_ch3;

shift_ctrl 
shift_ctrl_U0(
    .ftr_fl(ftr_fl),
    .wgt_fl(wgt_fl),
    .idt_fl(idt_fl),
    .out_fl(out_fl),
    .relu_shift_ch0(relu_shift_ch0),
    .relu_shift_ch1(relu_shift_ch1),
    .relu_shift_ch2(relu_shift_ch2),
    .relu_shift_ch3(relu_shift_ch3),
    .residual_shift_ch0(residual_shift_ch0),
    .residual_shift_ch1(residual_shift_ch1),
    .residual_shift_ch2(residual_shift_ch2),
    .residual_shift_ch3(residual_shift_ch3),
    .quantizer_shift_ch0(quantizer_shift_ch0),
    .quantizer_shift_ch1(quantizer_shift_ch1),
    .quantizer_shift_ch2(quantizer_shift_ch2),
    .quantizer_shift_ch3(quantizer_shift_ch3)
);

// ReLU
ReLU #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_BIAS(BW_BIAS), .BW_RELU(BW_RELU))
ReLU_U0 (
    .relu_in(post_in),
    .relu(relu),
    .relu_shift_ch0(relu_shift_ch0),
    .relu_shift_ch1(relu_shift_ch1),
    .relu_shift_ch2(relu_shift_ch2),
    .relu_shift_ch3(relu_shift_ch3),
    .relu_out(relu_out)
);

// residual connection
residual_add #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
residual_add_U0(
    .res_in(relu_ch0),
    .residual(residual),
    .idt(idt_ch0),
    .shift(residual_shift_ch0),
    .res_out(residual_out_ch0)
);

residual_add #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
residual_add_U1(
    .res_in(relu_ch1),
    .residual(residual),
    .idt(idt_ch1),
    .shift(residual_shift_ch1),
    .res_out(residual_out_ch1)
);

residual_add #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
residual_add_U2(
    .res_in(relu_ch2),
    .residual(residual),
    .idt(idt_ch2),
    .shift(residual_shift_ch2),
    .res_out(residual_out_ch2)
);

residual_add #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
residual_add_U3(
    .res_in(relu_ch3),
    .residual(residual),
    .idt(idt_ch3),
    .shift(residual_shift_ch3),
    .res_out(residual_out_ch3)
);

// quantization
quantization_1ch #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
quantization_1ch_U0 (
  .in_val(residual_out_ch0),
  .shift(quantizer_shift_ch0),
  .out_val(quantizer_out_ch0)
);    
quantization_1ch #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
quantization_1ch_U1 (
  .in_val(residual_out_ch1),
  .shift(quantizer_shift_ch1),
  .out_val(quantizer_out_ch1)
);    
quantization_1ch #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
quantization_1ch_U2 (
  .in_val(residual_out_ch2),
  .shift(quantizer_shift_ch2),
  .out_val(quantizer_out_ch2)
);    
quantization_1ch #(.GROUP_CHANNEL(GROUP_CHANNEL), .BW_RELU(BW_RELU))
quantization_1ch_U3 (
  .in_val(residual_out_ch3),
  .shift(quantizer_shift_ch3),
  .out_val(quantizer_out_ch3)
);    

endmodule
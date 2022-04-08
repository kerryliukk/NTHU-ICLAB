//====================================================================================
//  Module Description: ReLU for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module ReLU #(
    parameter GROUP_CHANNEL = 16,
    parameter BW_BIAS = 2*`BITWIDTH+4+$clog2(GROUP_CHANNEL)+1, 
    parameter BW_RELU = 2*`BITWIDTH+4+$clog2(GROUP_CHANNEL)+10
)(
    input [`OUT_CHANNEL*BW_BIAS-1:0] relu_in, // ReLU layer input
    input relu, // Output ReLU value if relu is 1'b1 
    input [`BW_FL-1:0] relu_shift_ch0, // shift amount of relu tuple 0
    input [`BW_FL-1:0] relu_shift_ch1, // shift amount of relu tuple 1
    input [`BW_FL-1:0] relu_shift_ch2, // shift amount of relu tuple 2
    input [`BW_FL-1:0] relu_shift_ch3, // shift amount of relu tuple 3
    output [`OUT_CHANNEL*BW_RELU-1:0] relu_out
);

wire signed [BW_BIAS-1:0] y0, y1, y2, y3;
assign {y0, y1, y2, y3} = relu_in;

reg signed [BW_RELU-1:0] x0, x1, x2, x3;
assign relu_out = {x0, x1, x2, x3};

////////////////////////////////////////////////////
// Workshop II: replace with directional ReLU     //
//     Note: Do not implement sequential circuit. //
////////////////////////////////////////////////////

reg signed [BW_RELU-1:0] y0_shift, y1_shift, y2_shift, y3_shift;
reg signed [BW_RELU-1:0] temp0, temp1, temp2, temp3;
reg signed [BW_RELU-1:0] temp0_relu, temp1_relu, temp2_relu, temp3_relu;

always @* begin
    y0_shift = y0 <<< relu_shift_ch0;
    y1_shift = y1 <<< relu_shift_ch1;
    y2_shift = y2 <<< relu_shift_ch2;
    y3_shift = y3 <<< relu_shift_ch3;
end

always @* begin
    temp0 = y0_shift + y1_shift + y2_shift + y3_shift;
    temp1 = y0_shift - y1_shift + y2_shift - y3_shift;
    temp2 = y0_shift + y1_shift - y2_shift - y3_shift;
    temp3 = y0_shift - y1_shift - y2_shift + y3_shift;
end

always @* begin
    temp0_relu = temp0 >= 0 ? temp0 : 0;
    temp1_relu = temp1 >= 0 ? temp1 : 0;
    temp2_relu = temp2 >= 0 ? temp2 : 0;
    temp3_relu = temp3 >= 0 ? temp3 : 0;
end

always @* begin
    if (relu) begin
        x0 = temp0_relu + temp1_relu + temp2_relu + temp3_relu;
        x1 = temp0_relu - temp1_relu + temp2_relu - temp3_relu;
        x2 = temp0_relu + temp1_relu - temp2_relu - temp3_relu;
        x3 = temp0_relu - temp1_relu - temp2_relu + temp3_relu;
    end
    else begin
        x0 = y0_shift;
        x1 = y1_shift;
        x2 = y2_shift;
        x3 = y3_shift;
    end
end

endmodule
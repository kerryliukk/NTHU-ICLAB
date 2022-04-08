//====================================================================================
//  Module Description: Sum 9 pixels and add bias for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module conv_adder #(
    parameter GROUP_CHANNEL = 16,
    parameter BW_CONV1x1 = 2*`BITWIDTH+4,
    parameter BW_BIAS = BW_CONV1x1+4+1
)(
    input signed [9*BW_CONV1x1-1:0] add_in,
    input signed [`BITWIDTH-1:0] bias,
    input [`BW_FL-1:0] ftr_fl, // input feature map fractional length (fl)
    input [`BW_FL-1:0] wgt_fl, // weight fractional length (fl)
    input [`BW_FL-1:0] bias_fl, // bias fractional length (fl)
    output reg signed [BW_BIAS-1:0] add_out
);
    
wire signed [BW_CONV1x1-1:0] conv1x1_pix0, conv1x1_pix1, conv1x1_pix2, conv1x1_pix3, conv1x1_pix4, conv1x1_pix5, conv1x1_pix6, conv1x1_pix7, conv1x1_pix8;
assign {conv1x1_pix0, conv1x1_pix1, conv1x1_pix2, conv1x1_pix3, conv1x1_pix4, conv1x1_pix5, conv1x1_pix6, conv1x1_pix7, conv1x1_pix8} = add_in;

///////////////////////////////////////////////////////////////////////////
// Workshop I:                                                           //
//     1. Sum 9 conv1x1 output.                                          //
//     2. Align the augend and adden accroding to fractional length      //
//     Note: Do not implement sequential circuit.                        //
///////////////////////////////////////////////////////////////////////////
reg signed [BW_CONV1x1+3:0] sum_3x3;
always@*begin
    sum_3x3 = conv1x1_pix0+ conv1x1_pix1+ conv1x1_pix2+ conv1x1_pix3+ conv1x1_pix4+ conv1x1_pix5+ conv1x1_pix6+ conv1x1_pix7+ conv1x1_pix8;
end

wire [`BW_FL:0] shift = ftr_fl+wgt_fl-bias_fl; 
reg signed [BW_CONV1x1:0] shifted_bias;

always@* begin
    shifted_bias = bias<<<shift;
    add_out = sum_3x3 + shifted_bias;
end
    
endmodule
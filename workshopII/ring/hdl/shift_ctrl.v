//====================================================================================
//  Module Description: Shift amount controller for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module shift_ctrl 
(
    input [4*`BW_FL-1:0] ftr_fl, // input feature map fractional length (fl) 
    input [`BW_FL-1:0] wgt_fl, // weight fractional length (fl)
    input [4*`BW_FL-1:0] idt_fl, // identity fractional length (fl)
    input [4*`BW_FL-1:0] out_fl, // output feature map fractional length (fl)
    // shift amount of directinal ReLU layer 
    output reg [`BW_FL-1:0] relu_shift_ch0,
    output reg [`BW_FL-1:0] relu_shift_ch1,
    output reg [`BW_FL-1:0] relu_shift_ch2,
    output reg [`BW_FL-1:0] relu_shift_ch3,
    // shift amount of residual connection
    output reg [`BW_FL-1:0] residual_shift_ch0,
    output reg [`BW_FL-1:0] residual_shift_ch1,
    output reg [`BW_FL-1:0] residual_shift_ch2,
    output reg [`BW_FL-1:0] residual_shift_ch3,
    // shift amount of quantization
    output reg [`BW_FL-1:0] quantizer_shift_ch0,
    output reg [`BW_FL-1:0] quantizer_shift_ch1,
    output reg [`BW_FL-1:0] quantizer_shift_ch2,
    output reg [`BW_FL-1:0] quantizer_shift_ch3
);

wire [`BW_FL-1:0] ftr_fl_ch0, ftr_fl_ch1, ftr_fl_ch2, ftr_fl_ch3;
wire [`BW_FL-1:0] idt_fl_ch0, idt_fl_ch1, idt_fl_ch2, idt_fl_ch3;
wire [`BW_FL-1:0] out_fl_ch0, out_fl_ch1, out_fl_ch2, out_fl_ch3;
assign {ftr_fl_ch0, ftr_fl_ch1, ftr_fl_ch2, ftr_fl_ch3} = ftr_fl;
assign {idt_fl_ch0, idt_fl_ch1, idt_fl_ch2, idt_fl_ch3} = idt_fl;
assign {out_fl_ch0, out_fl_ch1, out_fl_ch2, out_fl_ch3} = out_fl;

/////////////////////////////////////////////////////////////////////////////////
// WorkshopI : Calculate shifht amount for postprocessing operations.          //
// WorkshopII: Align four tuples for directional ReLU and modify shift amount. //
//     Note: Do not implement sequential circuit.                              //
/////////////////////////////////////////////////////////////////////////////////

always @* begin
    if (ftr_fl_ch0 >= ftr_fl_ch1 && ftr_fl_ch0 >= ftr_fl_ch2 && ftr_fl_ch0 >= ftr_fl_ch3) begin
        relu_shift_ch0 = 0;
        relu_shift_ch1 = ftr_fl_ch0 - ftr_fl_ch1;
        relu_shift_ch2 = ftr_fl_ch0 - ftr_fl_ch2;
        relu_shift_ch3 = ftr_fl_ch0 - ftr_fl_ch3;

        residual_shift_ch0 = ftr_fl_ch0 + wgt_fl - idt_fl_ch0;
        residual_shift_ch1 = ftr_fl_ch0 + wgt_fl - idt_fl_ch1;
        residual_shift_ch2 = ftr_fl_ch0 + wgt_fl - idt_fl_ch2;
        residual_shift_ch3 = ftr_fl_ch0 + wgt_fl - idt_fl_ch3;

        quantizer_shift_ch0 = ftr_fl_ch0 + wgt_fl - out_fl_ch0 -1;
        quantizer_shift_ch1 = ftr_fl_ch0 + wgt_fl - out_fl_ch1 -1;
        quantizer_shift_ch2 = ftr_fl_ch0 + wgt_fl - out_fl_ch2 -1;
        quantizer_shift_ch3 = ftr_fl_ch0 + wgt_fl - out_fl_ch3 -1;
    end
    else if (ftr_fl_ch1 >= ftr_fl_ch0 && ftr_fl_ch1 >= ftr_fl_ch2 && ftr_fl_ch1 >= ftr_fl_ch3) begin
        relu_shift_ch0 = ftr_fl_ch1 - ftr_fl_ch0;
        relu_shift_ch1 = 0;
        relu_shift_ch2 = ftr_fl_ch1 - ftr_fl_ch2;
        relu_shift_ch3 = ftr_fl_ch1 - ftr_fl_ch3;

        residual_shift_ch0 = ftr_fl_ch1 + wgt_fl - idt_fl_ch0;
        residual_shift_ch1 = ftr_fl_ch1 + wgt_fl - idt_fl_ch1;
        residual_shift_ch2 = ftr_fl_ch1 + wgt_fl - idt_fl_ch2;
        residual_shift_ch3 = ftr_fl_ch1 + wgt_fl - idt_fl_ch3;

        quantizer_shift_ch0 = ftr_fl_ch1 + wgt_fl - out_fl_ch0 -1;
        quantizer_shift_ch1 = ftr_fl_ch1 + wgt_fl - out_fl_ch1 -1;
        quantizer_shift_ch2 = ftr_fl_ch1 + wgt_fl - out_fl_ch2 -1;
        quantizer_shift_ch3 = ftr_fl_ch1 + wgt_fl - out_fl_ch3 -1;
    end
    else if (ftr_fl_ch2 >= ftr_fl_ch0 && ftr_fl_ch2 >= ftr_fl_ch1 && ftr_fl_ch2 >= ftr_fl_ch3) begin
        relu_shift_ch0 = ftr_fl_ch2 - ftr_fl_ch0;
        relu_shift_ch1 = ftr_fl_ch2 - ftr_fl_ch1;
        relu_shift_ch2 = 0;
        relu_shift_ch3 = ftr_fl_ch2 - ftr_fl_ch3;

        residual_shift_ch0 = ftr_fl_ch2 + wgt_fl - idt_fl_ch0;
        residual_shift_ch1 = ftr_fl_ch2 + wgt_fl - idt_fl_ch1;
        residual_shift_ch2 = ftr_fl_ch2 + wgt_fl - idt_fl_ch2;
        residual_shift_ch3 = ftr_fl_ch2 + wgt_fl - idt_fl_ch3;

        quantizer_shift_ch0 = ftr_fl_ch2 + wgt_fl - out_fl_ch0 -1;
        quantizer_shift_ch1 = ftr_fl_ch2 + wgt_fl - out_fl_ch1 -1;
        quantizer_shift_ch2 = ftr_fl_ch2 + wgt_fl - out_fl_ch2 -1;
        quantizer_shift_ch3 = ftr_fl_ch2 + wgt_fl - out_fl_ch3 -1;
    end
    else begin
        relu_shift_ch0 = ftr_fl_ch3 - ftr_fl_ch0;
        relu_shift_ch1 = ftr_fl_ch3 - ftr_fl_ch1;
        relu_shift_ch2 = ftr_fl_ch3 - ftr_fl_ch2;
        relu_shift_ch3 = 0;

        residual_shift_ch0 = ftr_fl_ch3 + wgt_fl - idt_fl_ch0;
        residual_shift_ch1 = ftr_fl_ch3 + wgt_fl - idt_fl_ch1;
        residual_shift_ch2 = ftr_fl_ch3 + wgt_fl - idt_fl_ch2;
        residual_shift_ch3 = ftr_fl_ch3 + wgt_fl - idt_fl_ch3;

        quantizer_shift_ch0 = ftr_fl_ch3 + wgt_fl - out_fl_ch0 -1;
        quantizer_shift_ch1 = ftr_fl_ch3 + wgt_fl - out_fl_ch1 -1;
        quantizer_shift_ch2 = ftr_fl_ch3 + wgt_fl - out_fl_ch2 -1;
        quantizer_shift_ch3 = ftr_fl_ch3 + wgt_fl - out_fl_ch3 -1;
    end
end


// always@*begin
//     residual_shift_ch0 = ftr_fl_ch0 + wgt_fl - idt_fl_ch0;
//     residual_shift_ch1 = ftr_fl_ch1 + wgt_fl - idt_fl_ch1;
//     residual_shift_ch2 = ftr_fl_ch2 + wgt_fl - idt_fl_ch2;
//     residual_shift_ch3 = ftr_fl_ch3 + wgt_fl - idt_fl_ch3;

//     quantizer_shift_ch0 = ftr_fl_ch0 + wgt_fl - out_fl_ch0 -1;
//     quantizer_shift_ch1 = ftr_fl_ch1 + wgt_fl - out_fl_ch1 -1;
//     quantizer_shift_ch2 = ftr_fl_ch2 + wgt_fl - out_fl_ch2 -1;
//     quantizer_shift_ch3 = ftr_fl_ch3 + wgt_fl - out_fl_ch3 -1;
// end

endmodule
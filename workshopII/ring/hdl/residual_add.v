//====================================================================================
//  Module Description: 1 channel short-cut addition for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module residual_add #(
    parameter GROUP_CHANNEL = 16,
    parameter BW_RELU = 2*`BITWIDTH+4+$clog2(GROUP_CHANNEL)+1
)(
    input signed [BW_RELU-1:0] res_in,
    input residual, // add identity when residual is 1'b1
    input signed [`BITWIDTH-1:0] idt, // identity
    input [`BW_FL-1:0] shift, // shift amount of residual connection
    output reg signed [BW_RELU-1:0] res_out
);

///////////////////////////////////////////////////////////////////////////
// Workshop I: Align the augend and adden accroding to fractional length //
//     Note: Do not implement sequential circuit.                        //
///////////////////////////////////////////////////////////////////////////

wire signed [BW_RELU-1:0] shift_idt;
assign shift_idt = idt<<<shift;

always@*begin
    if(residual)begin
        res_out = res_in + shift_idt;
    end else begin
        res_out = res_in;
    end
end

endmodule

//====================================================================================
//  Module Description: 4x4 matrix multiplxiation for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
module matmul #(
    parameter BW_MATMUL = 2*`BITWIDTH+$clog2(4/`N)
)(
    input [4*`BITWIDTH-1:0] feature,
    input [4*4/`N*`BITWIDTH-1:0] weight,
    output signed [BW_MATMUL*4-1:0] matmul_out
);

wire signed [`BITWIDTH-1:0] weight00;
wire signed [`BITWIDTH-1:0] weight11;
wire signed [`BITWIDTH-1:0] weight22;
wire signed [`BITWIDTH-1:0] weight33;
assign {weight00, weight11, weight22, weight33} = weight;

wire signed [`BITWIDTH-1:0] feature0, feature1, feature2, feature3;
assign {feature0, feature1, feature2, feature3} = feature;

reg signed [BW_MATMUL-1:0] product0, product1, product2, product3;
assign matmul_out = {product0, product1, product2, product3};

///////////////////////////////////////////////////////////////////
// WorkshopII: implement hardware-efficient ring multiplication. //
//     Note: Do not implement sequential circuit.                //
///////////////////////////////////////////////////////////////////

always @* begin
    product0 = weight00 * feature0;
    product1 = weight11 * feature1;
    product2 = weight22 * feature2;
    product3 = weight33 * feature3;
end


endmodule
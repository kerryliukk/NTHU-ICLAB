module MUX #(
	parameter BITWIDTH = 8
)(
    input mode, // 0: median , 1: gaussian
    input [BITWIDTH*9-1:0] M_denoise_block_out_0, M_denoise_block_out_1, M_denoise_block_out_2, M_denoise_block_out_3,
    input [BITWIDTH*9-1:0] G_denoise_block_out_0, G_denoise_block_out_1, G_denoise_block_out_2, G_denoise_block_out_3, 
    output reg [BITWIDTH*9-1:0] denoise_block_out_0, denoise_block_out_1, denoise_block_out_2, denoise_block_out_3
);

always @(*) begin
    if(!mode) begin
        denoise_block_out_0 = M_denoise_block_out_0;
        denoise_block_out_1 = M_denoise_block_out_1;
        denoise_block_out_2 = M_denoise_block_out_2;
        denoise_block_out_3 = M_denoise_block_out_3;

    end
    else begin
        denoise_block_out_0 = G_denoise_block_out_0;
        denoise_block_out_1 = G_denoise_block_out_1;
        denoise_block_out_2 = G_denoise_block_out_2;
        denoise_block_out_3 = G_denoise_block_out_3;
    end
end

endmodule
module top(
    input clk, 
    input rst_n, 
    input mode, 
    input [8*70-1:0] pixel_in,
    output valid,
    // output [8*9-1:0] block_out_0, 
    // output [8*9-1:0] block_out_1, 
    // output [8*9-1:0] block_out_2, 
    // output [8*9-1:0] block_out_3
    output [12*9-1:0] block_out_0, 
    output [12*9-1:0] block_out_1, 
    output [12*9-1:0] block_out_2, 
    output [12*9-1:0] block_out_3
    // output [(2*8+4)*9-1:0] block_out_0, 
    // output [(2*8+4)*9-1:0] block_out_1, 
    // output [(2*8+4)*9-1:0] block_out_2, 
    // output [(2*8+4)*9-1:0] block_out_3
);


reg [8*70-1:0] pixel_in_r;
reg mode_r;

wire denoise_valid, median_valid, gaussian_valid, HOG_valid;
assign denoise_valid = mode_r == 0 ? median_valid : gaussian_valid;
wire [8-1:0] cnt_row; 
wire [6-1:0] cnt_col;
wire [8*9-1:0] M_denoise_block_out_0, M_denoise_block_out_1, M_denoise_block_out_2, M_denoise_block_out_3;
wire [8*9-1:0] G_denoise_block_out_0, G_denoise_block_out_1, G_denoise_block_out_2, G_denoise_block_out_3;
wire [8*9-1:0] denoise_block_out_0, denoise_block_out_1, denoise_block_out_2, denoise_block_out_3;
wire [20*9-1:0] HOG_block_out_0, HOG_block_out_1, HOG_block_out_2, HOG_block_out_3;

// set valid signal
    // HOG means final valid!
    // denoise means temporary valid
assign valid = HOG_valid;


denoise #(
    .BIT_WIDTH(8)
) U0
(
    .clk(clk),
    .rst_n(rst_n),
    .pix_in(pixel_in_r),
    // .block_out_0(block_out_0),
    // .block_out_1(block_out_1),
    // .block_out_2(block_out_2),
    // .block_out_3(block_out_3),
    .block_out_0(M_denoise_block_out_0),
    .block_out_1(M_denoise_block_out_1),
    .block_out_2(M_denoise_block_out_2),
    .block_out_3(M_denoise_block_out_3),
    .valid(median_valid)
);

Gaussian #(
    .BIT_WIDTH(8)
) U0_g
(
    .clk(clk),
    .rst_n(rst_n),
    .pix_in(pixel_in_r),
    //.block_out_0(block_out_0),
    //.block_out_1(block_out_1),
    //.block_out_2(block_out_2),
    //.block_out_3(block_out_3),
    .block_out_0(G_denoise_block_out_0),
    .block_out_1(G_denoise_block_out_1),
    .block_out_2(G_denoise_block_out_2),
    .block_out_3(G_denoise_block_out_3),
    .valid(gaussian_valid)
);

MUX #(
    .BITWIDTH(8)
) U0_m
(
    .mode(mode_r), // 0: median , 1: gaussian
    .M_denoise_block_out_0(M_denoise_block_out_0),
    .M_denoise_block_out_1(M_denoise_block_out_1),
    .M_denoise_block_out_2(M_denoise_block_out_2),
    .M_denoise_block_out_3(M_denoise_block_out_3),
    .G_denoise_block_out_0(G_denoise_block_out_0),
    .G_denoise_block_out_1(G_denoise_block_out_1),
    .G_denoise_block_out_2(G_denoise_block_out_2),
    .G_denoise_block_out_3(G_denoise_block_out_3),
    /////////////// output ////////////////////
    .denoise_block_out_0(denoise_block_out_0), 
	.denoise_block_out_1(denoise_block_out_1), 
	.denoise_block_out_2(denoise_block_out_2), 
	.denoise_block_out_3(denoise_block_out_3)
);

HOG #(
	.BITWIDTH(8)
) U1
(	
	.clk(clk),
	.rst_n(rst_n),
	.cnt_row(cnt_row), // 0 - 159
	.cnt_col(cnt_col), // 0 - 52
	.block0(denoise_block_out_0), 
	.block1(denoise_block_out_1), 
	.block2(denoise_block_out_2), 
	.block3(denoise_block_out_3), // 3*3*BITWIDTH // 71:0
	.HOG_out0(HOG_block_out_0), 
	.HOG_out1(HOG_block_out_1), 
	.HOG_out2(HOG_block_out_2), 
	.HOG_out3(HOG_block_out_3), 
    .valid(HOG_valid)
);


hog_counter U2 (
    .clk(clk),
    .rst_n(rst_n), 
    .start(denoise_valid),
    .cnt_row(cnt_row), 
    .cnt_col(cnt_col)
);

// block 0
sqrt U3(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*9-1-:20]), 
    .sqrt_num(block_out_0[12*9-1-:12])
);
sqrt U4(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*8-1-:20]), 
    .sqrt_num(block_out_0[12*8-1-:12])
);
sqrt U5(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*7-1-:20]), 
    .sqrt_num(block_out_0[12*7-1-:12])
);
sqrt U6(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*6-1-:20]), 
    .sqrt_num(block_out_0[12*6-1-:12])
);
sqrt U7(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*5-1-:20]), 
    .sqrt_num(block_out_0[12*5-1-:12])
);
sqrt U8(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*4-1-:20]), 
    .sqrt_num(block_out_0[12*4-1-:12])
);
sqrt U9(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*3-1-:20]), 
    .sqrt_num(block_out_0[12*3-1-:12])
);
sqrt U10(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*2-1-:20]), 
    .sqrt_num(block_out_0[12*2-1-:12])
);
sqrt U11(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_0[20*1-1-:20]), 
    .sqrt_num(block_out_0[12*1-1-:12])
);


// block 1
sqrt U12(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*9-1-:20]), 
    .sqrt_num(block_out_1[12*9-1-:12])
);
sqrt U13(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*8-1-:20]), 
    .sqrt_num(block_out_1[12*8-1-:12])
);
sqrt U14(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*7-1-:20]), 
    .sqrt_num(block_out_1[12*7-1-:12])
);
sqrt U15(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*6-1-:20]), 
    .sqrt_num(block_out_1[12*6-1-:12])
);
sqrt U16(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*5-1-:20]), 
    .sqrt_num(block_out_1[12*5-1-:12])
);
sqrt U17(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*4-1-:20]), 
    .sqrt_num(block_out_1[12*4-1-:12])
);
sqrt U18(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*3-1-:20]), 
    .sqrt_num(block_out_1[12*3-1-:12])
);
sqrt U19(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*2-1-:20]), 
    .sqrt_num(block_out_1[12*2-1-:12])
);
sqrt U20(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_1[20*1-1-:20]), 
    .sqrt_num(block_out_1[12*1-1-:12])
);



// block 2
sqrt U21(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*9-1-:20]), 
    .sqrt_num(block_out_2[12*9-1-:12])
);
sqrt U22(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*8-1-:20]), 
    .sqrt_num(block_out_2[12*8-1-:12])
);
sqrt U23(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*7-1-:20]), 
    .sqrt_num(block_out_2[12*7-1-:12])
);
sqrt U24(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*6-1-:20]), 
    .sqrt_num(block_out_2[12*6-1-:12])
);
sqrt U25(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*5-1-:20]), 
    .sqrt_num(block_out_2[12*5-1-:12])
);
sqrt U26(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*4-1-:20]), 
    .sqrt_num(block_out_2[12*4-1-:12])
);
sqrt U27(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*3-1-:20]), 
    .sqrt_num(block_out_2[12*3-1-:12])
);
sqrt U28(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*2-1-:20]), 
    .sqrt_num(block_out_2[12*2-1-:12])
);
sqrt U29(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_2[20*1-1-:20]), 
    .sqrt_num(block_out_2[12*1-1-:12])
);



// block 3
sqrt U30(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*9-1-:20]), 
    .sqrt_num(block_out_3[12*9-1-:12])
);
sqrt U31(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*8-1-:20]), 
    .sqrt_num(block_out_3[12*8-1-:12])
);
sqrt U32(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*7-1-:20]), 
    .sqrt_num(block_out_3[12*7-1-:12])
);
sqrt U33(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*6-1-:20]), 
    .sqrt_num(block_out_3[12*6-1-:12])
);
sqrt U34(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*5-1-:20]), 
    .sqrt_num(block_out_3[12*5-1-:12])
);
sqrt U35(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*4-1-:20]), 
    .sqrt_num(block_out_3[12*4-1-:12])
);
sqrt U36(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*3-1-:20]), 
    .sqrt_num(block_out_3[12*3-1-:12])
);
sqrt U37(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*2-1-:20]), 
    .sqrt_num(block_out_3[12*2-1-:12])
);
sqrt U38(
    .clk(clk),
    .rst_n(rst_n), 
    .num(HOG_block_out_3[20*1-1-:20]), 
    .sqrt_num(block_out_3[12*1-1-:12])
);



always @(posedge clk) begin
    if (~rst_n) begin
        pixel_in_r <= 0;
	    mode_r <= 0;
    end
    else begin
        pixel_in_r <= pixel_in;
	    mode_r <= mode;
    end
end

endmodule

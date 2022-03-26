`timescale 1ns/100ps

module test_top;

localparam END_CYCLES = 50000; // you can enlarge the cycle count limit for longer simulation
real CYCLE = 10;
integer i, j, k;
integer error;
integer start_row, start_col;
integer ans_start_row, ans_start_col;

reg clk, rst_n;
reg [8*70-1:0] pixel_in;
reg mode;
wire valid;
// wire [20*9-1:0] block_out_0, block_out_1, block_out_2, block_out_3;
// wire [8*9-1:0] block_out_0, block_out_1, block_out_2, block_out_3;
wire [12*9-1:0] block_out_0, block_out_1, block_out_2, block_out_3;
// reg [20*9-1:0] ans_block_out_0, ans_block_out_1, ans_block_out_2, ans_block_out_3;
reg [12*9-1:0] ans_block_out_0, ans_block_out_1, ans_block_out_2, ans_block_out_3;
// reg [8*9-1:0] ans_block_out_0, ans_block_out_1, ans_block_out_2, ans_block_out_3;

// reg [8-1:0] block_out_0_2D [0:9-1];
// reg [8-1:0] block_out_1_2D [0:9-1];
// reg [8-1:0] block_out_2_2D [0:9-1];
// reg [8-1:0] block_out_3_2D [0:9-1];

// wire [8-1:0] cnt_row; 
// wire [6-1:0] cnt_col;


// reg [20-1:0] block_out_0_2D [0:9-1];
// reg [20-1:0] block_out_1_2D [0:9-1];
// reg [20-1:0] block_out_2_2D [0:9-1];
// reg [20-1:0] block_out_3_2D [0:9-1];


// reg [20-1:0] ans_block_out_0_2D [0:9-1];
// reg [20-1:0] ans_block_out_1_2D [0:9-1];
// reg [20-1:0] ans_block_out_2_2D [0:9-1];
// reg [20-1:0] ans_block_out_3_2D [0:9-1];


// always @* begin
//     for (k = 8; k >= 0; k = k - 1) begin
//         // block_out_0_2D[k] = block_out_0[8*(k+1)-1-:8];
//         // block_out_1_2D[k] = block_out_1[8*(k+1)-1-:8];
//         // block_out_2_2D[k] = block_out_2[8*(k+1)-1-:8];
//         // block_out_3_2D[k] = block_out_3[8*(k+1)-1-:8];
//         block_out_0_2D[k] = block_out_0[20*(k+1)-1-:20];
//         block_out_1_2D[k] = block_out_1[20*(k+1)-1-:20];
//         block_out_2_2D[k] = block_out_2[20*(k+1)-1-:20];
//         block_out_3_2D[k] = block_out_3[20*(k+1)-1-:20];

//         ans_block_out_0_2D[k] = ans_block_out_0[20*(k+1)-1-:20];
//         ans_block_out_1_2D[k] = ans_block_out_1[20*(k+1)-1-:20];
//         ans_block_out_2_2D[k] = ans_block_out_2[20*(k+1)-1-:20];
//         ans_block_out_3_2D[k] = ans_block_out_3[20*(k+1)-1-:20];
//     end
// end

reg [638*8-1:0] picture [0:482-1];


`define SDFFILE "../syn/netlist/top_syn.sdf"
`ifdef SDF
    initial $sdf_annotate(`SDFFILE, mytop);
    top mytop(
        .clk(clk), 
        .rst_n(rst_n), 
        .mode(mode), 
        .pixel_in(pixel_in), 
        .valid(valid), 
        .block_out_0(block_out_0), 
        .block_out_1(block_out_1), 
        .block_out_2(block_out_2), 
        .block_out_3(block_out_3)
    );

`else
    top mytop(
        .clk(clk), 
        .rst_n(rst_n), 
        .mode(mode), 
        .pixel_in(pixel_in), 
        .valid(valid), 
        .block_out_0(block_out_0), 
        .block_out_1(block_out_1), 
        .block_out_2(block_out_2), 
        .block_out_3(block_out_3)
    );
`endif



initial begin
    clk = 0;
    rst_n = 1;
    pixel_in = 0;
    #(CYCLE) rst_n = 0;
    #(CYCLE) rst_n = 1;
end

always #(CYCLE/2) clk = ~clk;

integer cycle_cnt = 0;

initial begin
    wait(rst_n == 0);
    wait(rst_n == 1);
    @(negedge clk)

    while(1) begin 
        cycle_cnt = cycle_cnt + 1;
        @(negedge clk);
    end

end

initial begin
    $readmemh("pix/noise_638_482.txt", picture);
    wait(rst_n == 0);
    wait(rst_n == 1);
    // 0: median, 1: gaussian
    `ifdef MED
        mode = 0;
        $display("Mode: Median filter");
    `elsif GAUSS
        mode = 1;
        $display("Mode: Gaussian filter");
    `else
        mode = 0;
        $display("Mode: Median filter");
    `endif
    // mode = 1; // change this line to select mode
    for (start_row = 0; start_row <= 477; start_row = start_row + 3) begin
        for (start_col = 637; start_col >= 13; start_col = start_col - 12) begin
            @(negedge clk)
                pixel_in = {picture[start_row][8*(start_col+1)-1-:14*8], 
                            picture[start_row+1][8*(start_col+1)-1-:14*8], 
                            picture[start_row+2][8*(start_col+1)-1-:14*8], 
                            picture[start_row+3][8*(start_col+1)-1-:14*8], 
                            picture[start_row+4][8*(start_col+1)-1-:14*8]};
        end
    end

end


reg [636*8-1:0] denoise_golden [0:480-1];
// reg [636*20-1:0] HOG_golden [0:480-1];
reg [640*20-1:0] HOG_golden [0:480-1];
reg [640*12-1:0] sqrt_golden [0:480-1];
reg [640*12-1:0] sqrt_golden2 [0:480-1];




// answer check
initial begin
    $readmemh("golden/med_of_med_636_480.txt", denoise_golden);
    // $readmemh("golden/gaussian_denoise_636_480.txt", denoise_golden);
    $readmemh("golden/denoise_hog_no_sqrt_636_480.txt", HOG_golden);
    $readmemh("golden/denoise_hog_with_sqrt_636_480.txt", sqrt_golden);
    $readmemh("golden/gaussian_hog_with_sqrt_636_480.txt", sqrt_golden2);
    error = 0;
    wait(valid == 1);
    // for denoise
    // for (ans_start_row = 0; ans_start_row <= 477; ans_start_row = ans_start_row + 3) begin
    //     for (ans_start_col = 635; ans_start_col >= 11; ans_start_col = ans_start_col - 12) begin
    //         @(negedge clk);
    //         ans_block_out_0 = {denoise_golden[ans_start_row][(ans_start_col+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+1][(ans_start_col+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+2][(ans_start_col+1)*8-1-:24]};
    //         ans_block_out_1 = {denoise_golden[ans_start_row][(ans_start_col-3+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+1][(ans_start_col-3+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+2][(ans_start_col-3+1)*8-1-:24]};
    //         ans_block_out_2 = {denoise_golden[ans_start_row][(ans_start_col-6+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+1][(ans_start_col-6+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+2][(ans_start_col-6+1)*8-1-:24]};
    //         ans_block_out_3 = {denoise_golden[ans_start_row][(ans_start_col-9+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+1][(ans_start_col-9+1)*8-1-:24], 
    //                            denoise_golden[ans_start_row+2][(ans_start_col-9+1)*8-1-:24]};
    //         if (block_out_0 === ans_block_out_0 && block_out_1 === ans_block_out_1 && block_out_2 === ans_block_out_2 && block_out_3 === ans_block_out_3) begin
    //             $display("Position at (%3d, %3d) correct!", ans_start_row, ans_start_col);
    //         end
    //         else begin
    //             $display("Position at (%3d, %3d) WRONG! (block0) de noise_golden = %h, result = %h", ans_start_row, ans_start_col, ans_block_out_0, block_out_0);
    //             error = error + 1;
    //         end
    //     end
    // end
    
    // for only median + HOG
    // for (ans_start_row = -1; ans_start_row <= 476; ans_start_row = ans_start_row + 3) begin
    //     for (ans_start_col = 636; ans_start_col >= 12; ans_start_col = ans_start_col - 12) begin
    //         @(negedge clk);
    //         ans_block_out_0 = {HOG_golden[ans_start_row][(ans_start_col+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+1][(ans_start_col+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+2][(ans_start_col+1)*20-1-:60]};
    //         ans_block_out_1 = {HOG_golden[ans_start_row][(ans_start_col-3+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+1][(ans_start_col-3+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+2][(ans_start_col-3+1)*20-1-:60]};
    //         ans_block_out_2 = {HOG_golden[ans_start_row][(ans_start_col-6+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+1][(ans_start_col-6+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+2][(ans_start_col-6+1)*20-1-:60]};
    //         ans_block_out_3 = {HOG_golden[ans_start_row][(ans_start_col-9+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+1][(ans_start_col-9+1)*20-1-:60], 
    //                            HOG_golden[ans_start_row+2][(ans_start_col-9+1)*20-1-:60]};
    //         if (ans_start_row == -1 && ans_start_col == 636) begin
    //             if (ans_block_out_0[20-1:0] === block_out_0[20-1:0]
    //             && ans_block_out_1[20*3-1:0] === block_out_1[20*3-1:0] 
    //             && ans_block_out_2[20*3-1:0] === block_out_2[20*3-1:0]
    //             && ans_block_out_3[20*3-1:0] === block_out_3[20*3-1:0]) begin
    //                 $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
    //             end
    //             else begin
    //                 $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
    //                 error = error + 1;
    //             end
    //         end
    //         else if (ans_start_row == -1) begin
    //             if (ans_block_out_0[20*3-1:0] === block_out_0[20*3-1:0]
    //             && ans_block_out_1[20*3-1:0] === block_out_1[20*3-1:0] 
    //             && ans_block_out_2[20*3-1:0] === block_out_2[20*3-1:0]
    //             && ans_block_out_3[20*3-1:0] === block_out_3[20*3-1:0]) begin
    //                 $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
    //             end
    //             else begin
    //                 $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
    //                 error = error + 1;
    //             end
    //         end
    //         else if (ans_start_col == 636) begin
    //             if (ans_block_out_0[20*7-1-:20] === block_out_0[20*7-1-:20]
    //             && ans_block_out_0[20*4-1-:20] === block_out_0[20*4-1-:20]
    //             && ans_block_out_0[20*1-1-:20] === block_out_0[20*1-1-:20]
    //             && ans_block_out_1 === block_out_1 
    //             && ans_block_out_2 === block_out_2
    //             && ans_block_out_3 === block_out_3) begin
    //                 $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
    //             end
    //             else begin
    //                 $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
    //                 error = error + 1;
    //             end
    //         end
    //         else begin
    //             if (ans_block_out_0 === block_out_0
    //             && ans_block_out_1 === block_out_1 
    //             && ans_block_out_2 === block_out_2
    //             && ans_block_out_3 === block_out_3) begin
    //                 $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
    //             end
    //             else begin
    //                 $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
    //                 error = error + 1;
    //             end
    //         end
    //     end
    // end

    // for median + HOG + sqrt
    for (ans_start_row = -1; ans_start_row <= 476; ans_start_row = ans_start_row + 3) begin
        for (ans_start_col = 636; ans_start_col >= 12; ans_start_col = ans_start_col - 12) begin
            @(negedge clk);
            if (mode == 0) begin
                ans_block_out_0 = {sqrt_golden[ans_start_row][(ans_start_col+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+1][(ans_start_col+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+2][(ans_start_col+1)*12-1-:36]};
                ans_block_out_1 = {sqrt_golden[ans_start_row][(ans_start_col-3+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+1][(ans_start_col-3+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+2][(ans_start_col-3+1)*12-1-:36]};
                ans_block_out_2 = {sqrt_golden[ans_start_row][(ans_start_col-6+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+1][(ans_start_col-6+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+2][(ans_start_col-6+1)*12-1-:36]};
                ans_block_out_3 = {sqrt_golden[ans_start_row][(ans_start_col-9+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+1][(ans_start_col-9+1)*12-1-:36], 
                                sqrt_golden[ans_start_row+2][(ans_start_col-9+1)*12-1-:36]};
                if (ans_start_row == -1 && ans_start_col == 636) begin
                    if (ans_block_out_0[12-1:0] === block_out_0[12-1:0]
                    && ans_block_out_1[12*3-1:0] === block_out_1[12*3-1:0] 
                    && ans_block_out_2[12*3-1:0] === block_out_2[12*3-1:0]
                    && ans_block_out_3[12*3-1:0] === block_out_3[12*3-1:0]) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
                else if (ans_start_row == -1) begin
                    if (ans_block_out_0[12*3-1:0] === block_out_0[12*3-1:0]
                    && ans_block_out_1[12*3-1:0] === block_out_1[12*3-1:0] 
                    && ans_block_out_2[12*3-1:0] === block_out_2[12*3-1:0]
                    && ans_block_out_3[12*3-1:0] === block_out_3[12*3-1:0]) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
                else if (ans_start_col == 636) begin
                    if (ans_block_out_0[12*7-1-:12] === block_out_0[12*7-1-:12]
                    && ans_block_out_0[12*4-1-:12] === block_out_0[12*4-1-:12]
                    && ans_block_out_0[12*1-1-:12] === block_out_0[12*1-1-:12]
                    && ans_block_out_1 === block_out_1 
                    && ans_block_out_2 === block_out_2
                    && ans_block_out_3 === block_out_3) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
                else begin
                    if (ans_block_out_0 === block_out_0
                    && ans_block_out_1 === block_out_1 
                    && ans_block_out_2 === block_out_2
                    && ans_block_out_3 === block_out_3) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
            end
            else begin
                ans_block_out_0 = {sqrt_golden2[ans_start_row][(ans_start_col+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+1][(ans_start_col+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+2][(ans_start_col+1)*12-1-:36]};
                ans_block_out_1 = {sqrt_golden2[ans_start_row][(ans_start_col-3+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+1][(ans_start_col-3+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+2][(ans_start_col-3+1)*12-1-:36]};
                ans_block_out_2 = {sqrt_golden2[ans_start_row][(ans_start_col-6+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+1][(ans_start_col-6+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+2][(ans_start_col-6+1)*12-1-:36]};
                ans_block_out_3 = {sqrt_golden2[ans_start_row][(ans_start_col-9+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+1][(ans_start_col-9+1)*12-1-:36], 
                                sqrt_golden2[ans_start_row+2][(ans_start_col-9+1)*12-1-:36]};
                if (ans_start_row == -1 && ans_start_col == 636) begin
                    if (ans_block_out_0[12-1:0] === block_out_0[12-1:0]
                    && ans_block_out_1[12*3-1:0] === block_out_1[12*3-1:0] 
                    && ans_block_out_2[12*3-1:0] === block_out_2[12*3-1:0]
                    && ans_block_out_3[12*3-1:0] === block_out_3[12*3-1:0]) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
                else if (ans_start_row == -1) begin
                    if (ans_block_out_0[12*3-1:0] === block_out_0[12*3-1:0]
                    && ans_block_out_1[12*3-1:0] === block_out_1[12*3-1:0] 
                    && ans_block_out_2[12*3-1:0] === block_out_2[12*3-1:0]
                    && ans_block_out_3[12*3-1:0] === block_out_3[12*3-1:0]) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
                else if (ans_start_col == 636) begin
                    if (ans_block_out_0[12*7-1-:12] === block_out_0[12*7-1-:12]
                    && ans_block_out_0[12*4-1-:12] === block_out_0[12*4-1-:12]
                    && ans_block_out_0[12*1-1-:12] === block_out_0[12*1-1-:12]
                    && ans_block_out_1 === block_out_1 
                    && ans_block_out_2 === block_out_2
                    && ans_block_out_3 === block_out_3) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
                else begin
                    if (ans_block_out_0 === block_out_0
                    && ans_block_out_1 === block_out_1 
                    && ans_block_out_2 === block_out_2
                    && ans_block_out_3 === block_out_3) begin
                        $display("Position at (%3d, %3d) correct!", ans_start_row + 1, ans_start_col - 1);
                    end
                    else begin
                        $display("Position at (%3d, %3d) WRONG! (block0) hog_golden = %h, result = %h", ans_start_row + 1, ans_start_col - 1, ans_block_out_0, block_out_0);
                        error = error + 1;
                    end
                end
            end
        end
    end

    if (mode == 0)
        $display("Mode: Median filter");
    else
        $display("Mode: Gaussian filter");

    if (error == 0) begin
        $display("Congratulations! Total error = %4d\nAll results are correct!", error);
        $display("Total cycle count = %0d", cycle_cnt);
        $finish;
    end
    else begin
        $display("total error = %4d", error);
        $finish;
    end
end

initial begin
    #(CYCLE*END_CYCLES);
    $display("\n========================================================");
    $display("Time limit exceeded!");
    $display("\n========================================================");
    $finish;
end

initial begin
    `ifdef MED
    	$fsdbDumpfile("final_MED.fsdb");
    `elsif GAUSS
	$fsdbDumpfile("final_GAUSS.fsdb");
    `else
	$fsdbDumpfile("final_MED.fsdb");
    `endif

    $fsdbDumpvars("+mda");
end

endmodule

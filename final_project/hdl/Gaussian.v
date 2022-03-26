module Gaussian
#(
    parameter BIT_WIDTH = 8
)
(
    input clk,
    input rst_n,
    input [5*14*BIT_WIDTH-1:0] pix_in, // 70*8-1 = 559
    output reg valid,
    output [9*BIT_WIDTH-1:0] block_out_0,
    output [9*BIT_WIDTH-1:0] block_out_1,
    output [9*BIT_WIDTH-1:0] block_out_2,
    output [9*BIT_WIDTH-1:0] block_out_3
);
integer i;

reg [1:0] cnt, n_cnt;
reg n_valid;
reg [5*14*BIT_WIDTH-1:0] pix_in_DFF;
reg [BIT_WIDTH-1:0] block_in_0[0:24];
reg [BIT_WIDTH-1:0] block_in_1[0:24];
reg [BIT_WIDTH-1:0] block_in_2[0:24];
reg [BIT_WIDTH-1:0] block_in_3[0:24];
reg [BIT_WIDTH-1:0] n_blk_out0[0:8], blk_out0[0:8];
reg [BIT_WIDTH-1:0] n_blk_out1[0:8], blk_out1[0:8];
reg [BIT_WIDTH-1:0] n_blk_out2[0:8], blk_out2[0:8];
reg [BIT_WIDTH-1:0] n_blk_out3[0:8], blk_out3[0:8];
reg [11:0] temp_out0[0:8];
reg [11:0] temp_out1[0:8];
reg [11:0] temp_out2[0:8];
reg [11:0] temp_out3[0:8];

always @(*) begin
    block_in_0[0] = pix_in_DFF[559:552];
    block_in_0[1] = pix_in_DFF[551:544];
    block_in_0[2] = pix_in_DFF[543:536];
    block_in_0[3] = pix_in_DFF[535:528];
    block_in_0[4] = pix_in_DFF[527:520];
    block_in_0[5] = pix_in_DFF[447:440];
    block_in_0[6] = pix_in_DFF[439:432];
    block_in_0[7] = pix_in_DFF[431:424];
    block_in_0[8] = pix_in_DFF[423:416];
    block_in_0[9] = pix_in_DFF[415:408];
    block_in_0[10] = pix_in_DFF[335:328];
    block_in_0[11] = pix_in_DFF[327:320];
    block_in_0[12] = pix_in_DFF[319:312];
    block_in_0[13] = pix_in_DFF[311:304];
    block_in_0[14] = pix_in_DFF[303:296];
    block_in_0[15] = pix_in_DFF[223:216];
    block_in_0[16] = pix_in_DFF[215:208];
    block_in_0[17] = pix_in_DFF[207:200];
    block_in_0[18] = pix_in_DFF[199:192];
    block_in_0[19] = pix_in_DFF[191:184];
    block_in_0[20] = pix_in_DFF[111:104];
    block_in_0[21] = pix_in_DFF[103:96];
    block_in_0[22] = pix_in_DFF[95:88];
    block_in_0[23] = pix_in_DFF[87:80];
    block_in_0[24] = pix_in_DFF[79:72];

    block_in_1[0] = pix_in_DFF[535:528];
    block_in_1[1] = pix_in_DFF[527:520];
    block_in_1[2] = pix_in_DFF[519:512];
    block_in_1[3] = pix_in_DFF[511:504];
    block_in_1[4] = pix_in_DFF[503:496];
    block_in_1[5] = pix_in_DFF[423:416];
    block_in_1[6] = pix_in_DFF[415:408];
    block_in_1[7] = pix_in_DFF[407:400];
    block_in_1[8] = pix_in_DFF[399:392];
    block_in_1[9] = pix_in_DFF[391:384];
    block_in_1[10] = pix_in_DFF[311:304];
    block_in_1[11] = pix_in_DFF[303:296];
    block_in_1[12] = pix_in_DFF[295:288];
    block_in_1[13] = pix_in_DFF[287:280];
    block_in_1[14] = pix_in_DFF[279:272];
    block_in_1[15] = pix_in_DFF[199:192];
    block_in_1[16] = pix_in_DFF[191:184];
    block_in_1[17] = pix_in_DFF[183:176];
    block_in_1[18] = pix_in_DFF[175:168];
    block_in_1[19] = pix_in_DFF[167:160];
    block_in_1[20] = pix_in_DFF[87:80];
    block_in_1[21] = pix_in_DFF[79:72];
    block_in_1[22] = pix_in_DFF[71:64];
    block_in_1[23] = pix_in_DFF[63:56];
    block_in_1[24] = pix_in_DFF[55:48];

    block_in_2[0] = pix_in_DFF[511:504];
    block_in_2[1] = pix_in_DFF[503:496];
    block_in_2[2] = pix_in_DFF[495:488];
    block_in_2[3] = pix_in_DFF[487:480];
    block_in_2[4] = pix_in_DFF[479:472];
    block_in_2[5] = pix_in_DFF[399:392];
    block_in_2[6] = pix_in_DFF[391:384];
    block_in_2[7] = pix_in_DFF[383:376];
    block_in_2[8] = pix_in_DFF[375:368];
    block_in_2[9] = pix_in_DFF[367:360];
    block_in_2[10] = pix_in_DFF[287:280];
    block_in_2[11] = pix_in_DFF[279:272];
    block_in_2[12] = pix_in_DFF[271:264];
    block_in_2[13] = pix_in_DFF[263:256];
    block_in_2[14] = pix_in_DFF[255:248];
    block_in_2[15] = pix_in_DFF[175:168];
    block_in_2[16] = pix_in_DFF[167:160];
    block_in_2[17] = pix_in_DFF[159:152];
    block_in_2[18] = pix_in_DFF[151:144];
    block_in_2[19] = pix_in_DFF[143:136];
    block_in_2[20] = pix_in_DFF[63:56];
    block_in_2[21] = pix_in_DFF[55:48];
    block_in_2[22] = pix_in_DFF[47:40];
    block_in_2[23] = pix_in_DFF[39:32];
    block_in_2[24] = pix_in_DFF[31:24];

    block_in_3[0] = pix_in_DFF[487:480];
    block_in_3[1] = pix_in_DFF[479:472];
    block_in_3[2] = pix_in_DFF[471:464];
    block_in_3[3] = pix_in_DFF[463:456];
    block_in_3[4] = pix_in_DFF[455:448];
    block_in_3[5] = pix_in_DFF[375:368];
    block_in_3[6] = pix_in_DFF[367:360];
    block_in_3[7] = pix_in_DFF[359:352];
    block_in_3[8] = pix_in_DFF[351:344];
    block_in_3[9] = pix_in_DFF[343:336];
    block_in_3[10] = pix_in_DFF[263:256];
    block_in_3[11] = pix_in_DFF[255:248];
    block_in_3[12] = pix_in_DFF[247:240];
    block_in_3[13] = pix_in_DFF[239:232];
    block_in_3[14] = pix_in_DFF[231:224];
    block_in_3[15] = pix_in_DFF[151:144];
    block_in_3[16] = pix_in_DFF[143:136];
    block_in_3[17] = pix_in_DFF[135:128];
    block_in_3[18] = pix_in_DFF[127:120];
    block_in_3[19] = pix_in_DFF[119:112];
    block_in_3[20] = pix_in_DFF[39:32];
    block_in_3[21] = pix_in_DFF[31:24];
    block_in_3[22] = pix_in_DFF[23:16];
    block_in_3[23] = pix_in_DFF[15:8];
    block_in_3[24] = pix_in_DFF[7:0];
end

always @(*) begin
    temp_out0[0] = block_in_0[0] + {block_in_0[1],1'b0} + block_in_0[2] + {block_in_0[5],1'b0} + {block_in_0[6],2'b0}
                   + {block_in_0[7],1'b0} + block_in_0[10] + {block_in_0[11],1'b0} + block_in_0[12];
    temp_out0[1] = block_in_0[1] + {block_in_0[2],1'b0} + block_in_0[3] + {block_in_0[6],1'b0} + {block_in_0[7],2'b0}
                   + {block_in_0[8],1'b0} + block_in_0[11] + {block_in_0[12],1'b0} + block_in_0[13];
    temp_out0[2] = block_in_0[2] + {block_in_0[3],1'b0} + block_in_0[4] + {block_in_0[7],1'b0} + {block_in_0[8],2'b0}
                   + {block_in_0[9],1'b0} + block_in_0[12] + {block_in_0[13],1'b0} + block_in_0[14];
    temp_out0[3] = block_in_0[5] + {block_in_0[6],1'b0} + block_in_0[7] + {block_in_0[10],1'b0} + {block_in_0[11],2'b0}
                   + {block_in_0[12],1'b0} + block_in_0[15] + {block_in_0[16],1'b0} + block_in_0[17];
    temp_out0[4] = block_in_0[6] + {block_in_0[7],1'b0} + block_in_0[8] + {block_in_0[11],1'b0} + {block_in_0[12],2'b0}
                   + {block_in_0[13],1'b0} + block_in_0[16] + {block_in_0[17],1'b0} + block_in_0[18];
    temp_out0[5] = block_in_0[7] + {block_in_0[8],1'b0} + block_in_0[9] + {block_in_0[12],1'b0} + {block_in_0[13],2'b0}
                   + {block_in_0[14],1'b0} + block_in_0[17] + {block_in_0[18],1'b0} + block_in_0[19];
    temp_out0[6] = block_in_0[10] + {block_in_0[11],1'b0} + block_in_0[12] + {block_in_0[15],1'b0} + {block_in_0[16],2'b0}
                   + {block_in_0[17],1'b0} + block_in_0[20] + {block_in_0[21],1'b0} + block_in_0[22];
    temp_out0[7] = block_in_0[11] + {block_in_0[12],1'b0} + block_in_0[13] + {block_in_0[16],1'b0} + {block_in_0[17],2'b0}
                   + {block_in_0[18],1'b0} + block_in_0[21] + {block_in_0[22],1'b0} + block_in_0[23];
    temp_out0[8] = block_in_0[12] + {block_in_0[13],1'b0} + block_in_0[14] + {block_in_0[17],1'b0} + {block_in_0[18],2'b0}
                   + {block_in_0[19],1'b0} + block_in_0[22] + {block_in_0[23],1'b0} + block_in_0[24];
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    temp_out1[0] = block_in_1[0] + {block_in_1[1],1'b0} + block_in_1[2] + {block_in_1[5],1'b0} + {block_in_1[6],2'b0}
                   + {block_in_1[7],1'b0} + block_in_1[10] + {block_in_1[11],1'b0} + block_in_1[12];
    temp_out1[1] = block_in_1[1] + {block_in_1[2],1'b0} + block_in_1[3] + {block_in_1[6],1'b0} + {block_in_1[7],2'b0}
                   + {block_in_1[8],1'b0} + block_in_1[11] + {block_in_1[12],1'b0} + block_in_1[13];
    temp_out1[2] = block_in_1[2] + {block_in_1[3],1'b0} + block_in_1[4] + {block_in_1[7],1'b0} + {block_in_1[8],2'b0}
                   + {block_in_1[9],1'b0} + block_in_1[12] + {block_in_1[13],1'b0} + block_in_1[14];
    temp_out1[3] = block_in_1[5] + {block_in_1[6],1'b0} + block_in_1[7] + {block_in_1[10],1'b0} + {block_in_1[11],2'b0}
                   + {block_in_1[12],1'b0} + block_in_1[15] + {block_in_1[16],1'b0} + block_in_1[17];
    temp_out1[4] = block_in_1[6] + {block_in_1[7],1'b0} + block_in_1[8] + {block_in_1[11],1'b0} + {block_in_1[12],2'b0}
                   + {block_in_1[13],1'b0} + block_in_1[16] + {block_in_1[17],1'b0} + block_in_1[18];
    temp_out1[5] = block_in_1[7] + {block_in_1[8],1'b0} + block_in_1[9] + {block_in_1[12],1'b0} + {block_in_1[13],2'b0}
                   + {block_in_1[14],1'b0} + block_in_1[17] + {block_in_1[18],1'b0} + block_in_1[19];
    temp_out1[6] = block_in_1[10] + {block_in_1[11],1'b0} + block_in_1[12] + {block_in_1[15],1'b0} + {block_in_1[16],2'b0}
                   + {block_in_1[17],1'b0} + block_in_1[20] + {block_in_1[21],1'b0} + block_in_1[22];
    temp_out1[7] = block_in_1[11] + {block_in_1[12],1'b0} + block_in_1[13] + {block_in_1[16],1'b0} + {block_in_1[17],2'b0}
                   + {block_in_1[18],1'b0} + block_in_1[21] + {block_in_1[22],1'b0} + block_in_1[23];
    temp_out1[8] = block_in_1[12] + {block_in_1[13],1'b0} + block_in_1[14] + {block_in_1[17],1'b0} + {block_in_1[18],2'b0}
                   + {block_in_1[19],1'b0} + block_in_1[22] + {block_in_1[23],1'b0} + block_in_1[24];
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    temp_out2[0] = block_in_2[0] + {block_in_2[1],1'b0} + block_in_2[2] + {block_in_2[5],1'b0} + {block_in_2[6],2'b0}
                   + {block_in_2[7],1'b0} + block_in_2[10] + {block_in_2[11],1'b0} + block_in_2[12];
    temp_out2[1] = block_in_2[1] + {block_in_2[2],1'b0} + block_in_2[3] + {block_in_2[6],1'b0} + {block_in_2[7],2'b0}
                   + {block_in_2[8],1'b0} + block_in_2[11] + {block_in_2[12],1'b0} + block_in_2[13];
    temp_out2[2] = block_in_2[2] + {block_in_2[3],1'b0} + block_in_2[4] + {block_in_2[7],1'b0} + {block_in_2[8],2'b0}
                   + {block_in_2[9],1'b0} + block_in_2[12] + {block_in_2[13],1'b0} + block_in_2[14];
    temp_out2[3] = block_in_2[5] + {block_in_2[6],1'b0} + block_in_2[7] + {block_in_2[10],1'b0} + {block_in_2[11],2'b0}
                   + {block_in_2[12],1'b0} + block_in_2[15] + {block_in_2[16],1'b0} + block_in_2[17];
    temp_out2[4] = block_in_2[6] + {block_in_2[7],1'b0} + block_in_2[8] + {block_in_2[11],1'b0} + {block_in_2[12],2'b0}
                   + {block_in_2[13],1'b0} + block_in_2[16] + {block_in_2[17],1'b0} + block_in_2[18];
    temp_out2[5] = block_in_2[7] + {block_in_2[8],1'b0} + block_in_2[9] + {block_in_2[12],1'b0} + {block_in_2[13],2'b0}
                   + {block_in_2[14],1'b0} + block_in_2[17] + {block_in_2[18],1'b0} + block_in_2[19];
    temp_out2[6] = block_in_2[10] + {block_in_2[11],1'b0} + block_in_2[12] + {block_in_2[15],1'b0} + {block_in_2[16],2'b0}
                   + {block_in_2[17],1'b0} + block_in_2[20] + {block_in_2[21],1'b0} + block_in_2[22];
    temp_out2[7] = block_in_2[11] + {block_in_2[12],1'b0} + block_in_2[13] + {block_in_2[16],1'b0} + {block_in_2[17],2'b0}
                   + {block_in_2[18],1'b0} + block_in_2[21] + {block_in_2[22],1'b0} + block_in_2[23];
    temp_out2[8] = block_in_2[12] + {block_in_2[13],1'b0} + block_in_2[14] + {block_in_2[17],1'b0} + {block_in_2[18],2'b0}
                   + {block_in_2[19],1'b0} + block_in_2[22] + {block_in_2[23],1'b0} + block_in_2[24];
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    temp_out3[0] = block_in_3[0] + {block_in_3[1],1'b0} + block_in_3[2] + {block_in_3[5],1'b0} + {block_in_3[6],2'b0}
                   + {block_in_3[7],1'b0} + block_in_3[10] + {block_in_3[11],1'b0} + block_in_3[12];
    temp_out3[1] = block_in_3[1] + {block_in_3[2],1'b0} + block_in_3[3] + {block_in_3[6],1'b0} + {block_in_3[7],2'b0}
                   + {block_in_3[8],1'b0} + block_in_3[11] + {block_in_3[12],1'b0} + block_in_3[13];
    temp_out3[2] = block_in_3[2] + {block_in_3[3],1'b0} + block_in_3[4] + {block_in_3[7],1'b0} + {block_in_3[8],2'b0}
                   + {block_in_3[9],1'b0} + block_in_3[12] + {block_in_3[13],1'b0} + block_in_3[14];
    temp_out3[3] = block_in_3[5] + {block_in_3[6],1'b0} + block_in_3[7] + {block_in_3[10],1'b0} + {block_in_3[11],2'b0}
                   + {block_in_3[12],1'b0} + block_in_3[15] + {block_in_3[16],1'b0} + block_in_3[17];
    temp_out3[4] = block_in_3[6] + {block_in_3[7],1'b0} + block_in_3[8] + {block_in_3[11],1'b0} + {block_in_3[12],2'b0}
                   + {block_in_3[13],1'b0} + block_in_3[16] + {block_in_3[17],1'b0} + block_in_3[18];
    temp_out3[5] = block_in_3[7] + {block_in_3[8],1'b0} + block_in_3[9] + {block_in_3[12],1'b0} + {block_in_3[13],2'b0}
                   + {block_in_3[14],1'b0} + block_in_3[17] + {block_in_3[18],1'b0} + block_in_3[19];
    temp_out3[6] = block_in_3[10] + {block_in_3[11],1'b0} + block_in_3[12] + {block_in_3[15],1'b0} + {block_in_3[16],2'b0}
                   + {block_in_3[17],1'b0} + block_in_3[20] + {block_in_3[21],1'b0} + block_in_3[22];
    temp_out3[7] = block_in_3[11] + {block_in_3[12],1'b0} + block_in_3[13] + {block_in_3[16],1'b0} + {block_in_3[17],2'b0}
                   + {block_in_3[18],1'b0} + block_in_3[21] + {block_in_3[22],1'b0} + block_in_3[23];
    temp_out3[8] = block_in_3[12] + {block_in_3[13],1'b0} + block_in_3[14] + {block_in_3[17],1'b0} + {block_in_3[18],2'b0}
                   + {block_in_3[19],1'b0} + block_in_3[22] + {block_in_3[23],1'b0} + block_in_3[24];
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    for(i=0;i<9;i=i+1) begin 
        n_blk_out0[i] = temp_out0[i][11:4];
        n_blk_out1[i] = temp_out1[i][11:4];
        n_blk_out2[i] = temp_out2[i][11:4];
        n_blk_out3[i] = temp_out3[i][11:4];
    end
end

// always @(*) begin
assign block_out_0 = {blk_out0[0], blk_out0[1], blk_out0[2], blk_out0[3], blk_out0[4], blk_out0[5], blk_out0[6], blk_out0[7], blk_out0[8]};
assign block_out_1 = {blk_out1[0], blk_out1[1], blk_out1[2], blk_out1[3], blk_out1[4], blk_out1[5], blk_out1[6], blk_out1[7], blk_out1[8]};
assign block_out_2 = {blk_out2[0], blk_out2[1], blk_out2[2], blk_out2[3], blk_out2[4], blk_out2[5], blk_out2[6], blk_out2[7], blk_out2[8]};
assign block_out_3 = {blk_out3[0], blk_out3[1], blk_out3[2], blk_out3[3], blk_out3[4], blk_out3[5], blk_out3[6], blk_out3[7], blk_out3[8]};
// end

always @(*) begin
    if(cnt == 3)
        n_cnt = cnt;
    else
        n_cnt = cnt + 1;
end

always @(*) begin
    if(cnt == 3)
        n_valid = 1;
    else 
        n_valid = 0;
end

always @(posedge clk) begin
    if(~rst_n) begin
        pix_in_DFF <= 0;
        valid <= 0;
        cnt <= 0;
        for(i=0;i<9;i=i+1) begin
            blk_out0[i] <= 0;
            blk_out1[i] <= 0;
            blk_out2[i] <= 0;
            blk_out3[i] <= 0;
        end
    end
    else begin
        pix_in_DFF <= pix_in;
        valid <= n_valid;
        cnt <= n_cnt;
        for(i=0;i<9;i=i+1) begin
            blk_out0[i] <= n_blk_out0[i];
            blk_out1[i] <= n_blk_out1[i];
            blk_out2[i] <= n_blk_out2[i];
            blk_out3[i] <= n_blk_out3[i];
        end
    end
end

endmodule

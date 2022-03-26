module HOG #(
	parameter BITWIDTH = 8
)(	
	input clk,
	input rst_n,
	input [7:0]cnt_row, // 0 - 159
	input [5:0]cnt_col, // 0 - 52
	input [9*BITWIDTH-1:0] block0, 
	input [9*BITWIDTH-1:0] block1, 
	input [9*BITWIDTH-1:0] block2, 
	input [9*BITWIDTH-1:0] block3, // 3*3*BITWIDTH // 71:0
	output reg [9*(2*BITWIDTH + 4)-1:0] HOG_out0, 
	output reg [9*(2*BITWIDTH + 4)-1:0] HOG_out1, 
	output reg [9*(2*BITWIDTH + 4)-1:0] HOG_out2, 
	output reg [9*(2*BITWIDTH + 4)-1:0] HOG_out3, 
	output reg valid
);


// reg signed [8:0] store0_row[0:52][0:11], n_store0_row[0:52][0:11];
reg signed [8:0] store0_row_0[0:52];
reg signed [8:0] store0_row_1[0:52];
reg signed [8:0] store0_row_2[0:52];
reg signed [8:0] store0_row_3[0:52];
reg signed [8:0] store0_row_4[0:52];
reg signed [8:0] store0_row_5[0:52];
reg signed [8:0] store0_row_6[0:52];
reg signed [8:0] store0_row_7[0:52];
reg signed [8:0] store0_row_8[0:52];
reg signed [8:0] store0_row_9[0:52];
reg signed [8:0] store0_row_10[0:52];
reg signed [8:0] store0_row_11[0:52];

reg signed [8:0] n_store0_row_0[0:52];
reg signed [8:0] n_store0_row_1[0:52];
reg signed [8:0] n_store0_row_2[0:52];
reg signed [8:0] n_store0_row_3[0:52];
reg signed [8:0] n_store0_row_4[0:52];
reg signed [8:0] n_store0_row_5[0:52];
reg signed [8:0] n_store0_row_6[0:52];
reg signed [8:0] n_store0_row_7[0:52];
reg signed [8:0] n_store0_row_8[0:52];
reg signed [8:0] n_store0_row_9[0:52];
reg signed [8:0] n_store0_row_10[0:52];
reg signed [8:0] n_store0_row_11[0:52];

// reg signed [8:0] store1_row[0:52][0:11], n_store1_row[0:52][0:11];
reg signed [8:0] store1_row_0[0:52];
reg signed [8:0] store1_row_1[0:52];
reg signed [8:0] store1_row_2[0:52];
reg signed [8:0] store1_row_3[0:52];
reg signed [8:0] store1_row_4[0:52];
reg signed [8:0] store1_row_5[0:52];
reg signed [8:0] store1_row_6[0:52];
reg signed [8:0] store1_row_7[0:52];
reg signed [8:0] store1_row_8[0:52];
reg signed [8:0] store1_row_9[0:52];
reg signed [8:0] store1_row_10[0:52];
reg signed [8:0] store1_row_11[0:52];

reg signed [8:0] n_store1_row_0[0:52];
reg signed [8:0] n_store1_row_1[0:52];
reg signed [8:0] n_store1_row_2[0:52];
reg signed [8:0] n_store1_row_3[0:52];
reg signed [8:0] n_store1_row_4[0:52];
reg signed [8:0] n_store1_row_5[0:52];
reg signed [8:0] n_store1_row_6[0:52];
reg signed [8:0] n_store1_row_7[0:52];
reg signed [8:0] n_store1_row_8[0:52];
reg signed [8:0] n_store1_row_9[0:52];
reg signed [8:0] n_store1_row_10[0:52];
reg signed [8:0] n_store1_row_11[0:52];


reg signed [8:0] store0_d11[0:52], store1_d10[0:52], store1_d11[0:52];
reg signed [8:0] n_store0_d11[0:52], n_store1_d10[0:52], n_store1_d11[0:52];
reg signed [8:0] store0_col[0:2] , n_store0_col[0:2];
reg signed [8:0] store1_col[0:2] , n_store1_col[0:2];
reg signed [8:0] blk0[0:8];
reg signed [8:0] blk1[0:8];
reg signed [8:0] blk2[0:8];
reg signed [8:0] blk3[0:8];
reg signed [8:0] sum_y[0:11][0:2], n_sum_y[0:11][0:2], temp_y[0:11][0:2];
reg signed [8:0] sum_x[0:11][0:2], n_sum_x[0:11][0:2], temp_x[0:11][0:2];
reg [15:0] square_y[0:11][0:2], n_square_y[0:11][0:2];
reg [15:0] square_x[0:11][0:2], n_square_x[0:11][0:2];
reg [19:0] square_sum0[0:8], n_square_sum0[0:8];
reg [19:0] square_sum1[0:8], n_square_sum1[0:8];
reg [19:0] square_sum2[0:8], n_square_sum2[0:8];
reg [19:0] square_sum3[0:8], n_square_sum3[0:8];
reg valid_next;

integer i,j;

///////////////// output data //////////////////
always @(*) begin
	HOG_out0 = {square_sum0[8],square_sum0[7],square_sum0[6],square_sum0[5],square_sum0[4],square_sum0[3],
				square_sum0[2],square_sum0[1],square_sum0[0]};
	HOG_out1 = {square_sum1[8],square_sum1[7],square_sum1[6],square_sum1[5],square_sum1[4],square_sum1[3],
				square_sum1[2],square_sum1[1],square_sum1[0]};
	HOG_out2 = {square_sum2[8],square_sum2[7],square_sum2[6],square_sum2[5],square_sum2[4],square_sum2[3],
				square_sum2[2],square_sum2[1],square_sum2[0]};
	HOG_out3 = {square_sum3[8],square_sum3[7],square_sum3[6],square_sum3[5],square_sum3[4],square_sum3[3],
				square_sum3[2],square_sum3[1],square_sum3[0]};
end
//////////// change input format ////////////
always @(*) begin
	blk0[8] = {1'b0, block0[71:64]};
	blk0[7] = {1'b0, block0[63:56]};
	blk0[6] = {1'b0, block0[55:48]};
	blk0[5] = {1'b0, block0[47:40]};
	blk0[4] = {1'b0, block0[39:32]};
	blk0[3] = {1'b0, block0[31:24]};
	blk0[2] = {1'b0, block0[23:16]};
	blk0[1] = {1'b0, block0[15:8]};
	blk0[0] = {1'b0, block0[7:0]};
	//////////////////////////////////
	blk1[8] = {1'b0, block1[71:64]};
	blk1[7] = {1'b0, block1[63:56]};
	blk1[6] = {1'b0, block1[55:48]};
	blk1[5] = {1'b0, block1[47:40]};
	blk1[4] = {1'b0, block1[39:32]};
	blk1[3] = {1'b0, block1[31:24]};
	blk1[2] = {1'b0, block1[23:16]};
	blk1[1] = {1'b0, block1[15:8]};
	blk1[0] = {1'b0, block1[7:0]};
	//////////////////////////////////
	blk2[8] = {1'b0, block2[71:64]};
	blk2[7] = {1'b0, block2[63:56]};
	blk2[6] = {1'b0, block2[55:48]};
	blk2[5] = {1'b0, block2[47:40]};
	blk2[4] = {1'b0, block2[39:32]};
	blk2[3] = {1'b0, block2[31:24]};
	blk2[2] = {1'b0, block2[23:16]};
	blk2[1] = {1'b0, block2[15:8]};
	blk2[0] = {1'b0, block2[7:0]};
	//////////////////////////////////
	blk3[8] = {1'b0, block3[71:64]};
	blk3[7] = {1'b0, block3[63:56]};
	blk3[6] = {1'b0, block3[55:48]};
	blk3[5] = {1'b0, block3[47:40]};
	blk3[4] = {1'b0, block3[39:32]};
	blk3[3] = {1'b0, block3[31:24]};
	blk3[2] = {1'b0, block3[23:16]};
	blk3[1] = {1'b0, block3[15:8]};
	blk3[0] = {1'b0, block3[7:0]};
end
////////// store data in register ////////////
always @(*) begin  /// may not be synthesizable , -> use case
	for(i=0;i<53;i=i+1) begin
		n_store0_row_0[i] = store0_row_0[i];
		n_store0_row_1[i] = store0_row_1[i];
		n_store0_row_2[i] = store0_row_2[i];
		n_store0_row_3[i] = store0_row_3[i];
		n_store0_row_4[i] = store0_row_4[i];
		n_store0_row_5[i] = store0_row_5[i];
		n_store0_row_6[i] = store0_row_6[i];
		n_store0_row_7[i] = store0_row_7[i];
		n_store0_row_8[i] = store0_row_8[i];
		n_store0_row_9[i] = store0_row_9[i];
		n_store0_row_10[i] = store0_row_10[i];
		n_store0_row_11[i] = store0_row_11[i];

		n_store1_row_0[i] = store1_row_0[i];
		n_store1_row_1[i] = store1_row_1[i];
		n_store1_row_2[i] = store1_row_2[i];
		n_store1_row_3[i] = store1_row_3[i];
		n_store1_row_4[i] = store1_row_4[i];
		n_store1_row_5[i] = store1_row_5[i];
		n_store1_row_6[i] = store1_row_6[i];
		n_store1_row_7[i] = store1_row_7[i];
		n_store1_row_8[i] = store1_row_8[i];
		n_store1_row_9[i] = store1_row_9[i];
		n_store1_row_10[i] = store1_row_10[i];
		n_store1_row_11[i] = store1_row_11[i];
	end
	n_store0_row_0[cnt_col] = blk0[5];
	n_store0_row_1[cnt_col] = blk0[4];
	n_store0_row_2[cnt_col] = blk0[3];
	n_store0_row_3[cnt_col] = blk1[5];
	n_store0_row_4[cnt_col] = blk1[4];
	n_store0_row_5[cnt_col] = blk1[3];
	n_store0_row_6[cnt_col] = blk2[5];
	n_store0_row_7[cnt_col] = blk2[4];
	n_store0_row_8[cnt_col] = blk2[3];
	n_store0_row_9[cnt_col] = blk3[5];
	n_store0_row_10[cnt_col] = blk3[4];
	n_store0_row_11[cnt_col] = blk3[3];
	/////////////////////////
	n_store1_row_0[cnt_col] = blk0[2];
	n_store1_row_1[cnt_col] = blk0[1];
	n_store1_row_2[cnt_col] = blk0[0];
	n_store1_row_3[cnt_col] = blk1[2];
	n_store1_row_4[cnt_col] = blk1[1];
	n_store1_row_5[cnt_col] = blk1[0];
	n_store1_row_6[cnt_col] = blk2[2];
	n_store1_row_7[cnt_col] = blk2[1];
	n_store1_row_8[cnt_col] = blk2[0];
	n_store1_row_9[cnt_col] = blk3[2];
	n_store1_row_10[cnt_col] = blk3[1];
	n_store1_row_11[cnt_col] = blk3[0];
	//////////////////////// prevent data vanish //////////////////
	for(i=0;i<53;i=i+1) begin
		n_store0_d11[i] = store0_row_11[i];
		n_store1_d10[i] = store1_row_10[i];
		n_store1_d11[i] = store1_row_11[i];
	end
	n_store0_d11[cnt_col] = store0_row_11[cnt_col];
	n_store1_d10[cnt_col] = store1_row_10[cnt_col];
	n_store1_d11[cnt_col] = store1_row_11[cnt_col];
	////////////////////////
	n_store0_col[2] = blk3[7];
	n_store0_col[1] = blk3[4];
	n_store0_col[0] = blk3[1];
	////////////////////////
	n_store1_col[2] = blk3[6];
	n_store1_col[1] = blk3[3];
	n_store1_col[0] = blk3[0];
end
/////////// get gy^2 /////////////
always @(*) begin
	temp_y[0][2] = store0_d11[cnt_col - 1] - store1_col[2]; // 0-3 for first row
	temp_y[0][1] = store0_row_0[cnt_col] - blk0[8];
	temp_y[0][0] = store0_row_1[cnt_col] - blk0[7];
	temp_y[1][2] = store0_row_2[cnt_col] - blk0[6];
	temp_y[1][1] = store0_row_3[cnt_col] - blk1[8];
	temp_y[1][0] = store0_row_4[cnt_col] - blk1[7];
	temp_y[2][2] = store0_row_5[cnt_col] - blk1[6];
	temp_y[2][1] = store0_row_6[cnt_col] - blk2[8];
	temp_y[2][0] = store0_row_7[cnt_col] - blk2[7];
	temp_y[3][2] = store0_row_8[cnt_col] - blk2[6];
	temp_y[3][1] = store0_row_9[cnt_col] - blk3[8];
	temp_y[3][0] = store0_row_10[cnt_col] - blk3[7];
	/////////////////////////////////////////  4-7 for second row
	temp_y[4][2] = store1_d11[cnt_col - 1] - store1_col[1];
	temp_y[4][1] = store1_row_0[cnt_col] - blk0[5];
	temp_y[4][0] = store1_row_1[cnt_col] - blk0[4];
	temp_y[5][2] = store1_row_2[cnt_col] - blk0[3];
	temp_y[5][1] = store1_row_3[cnt_col] - blk1[5];
	temp_y[5][0] = store1_row_4[cnt_col] - blk1[4];
	temp_y[6][2] = store1_row_5[cnt_col] - blk1[3];
	temp_y[6][1] = store1_row_6[cnt_col] - blk2[5];
	temp_y[6][0] = store1_row_7[cnt_col] - blk2[4];
	temp_y[7][2] = store1_row_8[cnt_col] - blk2[3];
	temp_y[7][1] = store1_row_9[cnt_col] - blk3[5];
	temp_y[7][0] = store1_row_10[cnt_col] - blk3[4];
	/////////////////////////////////////////  8-11 for third row
	temp_y[8][2] = store1_col[2] - store1_col[0];
	temp_y[8][1] = blk0[8] - blk0[2];
	temp_y[8][0] = blk0[7] - blk0[1];
	temp_y[9][2] = blk0[6] - blk0[0];
	temp_y[9][1] = blk1[8] - blk1[2];
	temp_y[9][0] = blk1[7] - blk1[1];
	temp_y[10][2] = blk1[6] - blk1[0];
	temp_y[10][1] = blk2[8] - blk2[2];
	temp_y[10][0] = blk2[7] - blk2[1];
	temp_y[11][2] = blk2[6] - blk2[0];
	temp_y[11][1] = blk3[8] - blk3[2];
	temp_y[11][0] = blk3[7] - blk3[1];
end

//////////// select n_sum_y ////////////////
always @(*) begin
	if(cnt_row == 0) begin
		//////////////////
		n_sum_y[0][2] = 0;
		n_sum_y[0][1] = 0;
		n_sum_y[0][0] = 0;
		n_sum_y[1][2] = 0;
		n_sum_y[1][1] = 0;
		n_sum_y[1][0] = 0;
		n_sum_y[2][2] = 0;
		n_sum_y[2][1] = 0;
		n_sum_y[2][0] = 0;
		n_sum_y[3][2] = 0;
		n_sum_y[3][1] = 0;
		n_sum_y[3][0] = 0;
		//////////////////
		n_sum_y[4][2] = blk0[5]; 
		n_sum_y[4][1] = blk0[4];
		n_sum_y[4][0] = blk0[3];
		n_sum_y[5][2] = blk1[5];
		n_sum_y[5][1] = blk1[4];
		n_sum_y[5][0] = blk1[3];
		n_sum_y[6][2] = blk2[5];
		n_sum_y[6][1] = blk2[4];
		n_sum_y[6][0] = blk2[3];
		n_sum_y[7][2] = blk3[5];
		n_sum_y[7][1] = blk3[4];
		n_sum_y[7][0] = blk3[3];
		////////////////////////
		n_sum_y[8][2]  = temp_y[8][2];
		n_sum_y[8][1]  = temp_y[8][1];
		n_sum_y[8][0]  = temp_y[8][0];
		n_sum_y[9][2]  = temp_y[9][2];
		n_sum_y[9][1]  = temp_y[9][1];
		n_sum_y[9][0]  = temp_y[9][0];
		n_sum_y[10][2] = temp_y[10][2];
		n_sum_y[10][1] = temp_y[10][1];
		n_sum_y[10][0] = temp_y[10][0];
		n_sum_y[11][2] = temp_y[11][2];
		n_sum_y[11][1] = temp_y[11][1];
		n_sum_y[11][0] = temp_y[11][0];
	end
	else begin
	  for(i=0;i<12;i=i+1) begin
		for(j=0;j<3;j=j+1) begin
			n_sum_y[i][j] = temp_y[i][j];
		end
	  end
	end
end

always @(*) begin
	n_square_y[0][2] = sum_y[0][2] * sum_y[0][2];
	n_square_y[0][1] = sum_y[0][1] * sum_y[0][1];
	n_square_y[0][0] = sum_y[0][0] * sum_y[0][0];
	n_square_y[1][2] = sum_y[1][2] * sum_y[1][2];
	n_square_y[1][1] = sum_y[1][1] * sum_y[1][1];
	n_square_y[1][0] = sum_y[1][0] * sum_y[1][0];
	n_square_y[2][2] = sum_y[2][2] * sum_y[2][2];
	n_square_y[2][1] = sum_y[2][1] * sum_y[2][1];
	n_square_y[2][0] = sum_y[2][0] * sum_y[2][0];
	n_square_y[3][2] = sum_y[3][2] * sum_y[3][2];
	n_square_y[3][1] = sum_y[3][1] * sum_y[3][1];
	n_square_y[3][0] = sum_y[3][0] * sum_y[3][0];
	/////////////////////////////////////////////
	n_square_y[4][2] = sum_y[4][2] * sum_y[4][2];
	n_square_y[4][1] = sum_y[4][1] * sum_y[4][1];
	n_square_y[4][0] = sum_y[4][0] * sum_y[4][0];
	n_square_y[5][2] = sum_y[5][2] * sum_y[5][2];
	n_square_y[5][1] = sum_y[5][1] * sum_y[5][1];
	n_square_y[5][0] = sum_y[5][0] * sum_y[5][0];
	n_square_y[6][2] = sum_y[6][2] * sum_y[6][2];
	n_square_y[6][1] = sum_y[6][1] * sum_y[6][1];
	n_square_y[6][0] = sum_y[6][0] * sum_y[6][0];
	n_square_y[7][2] = sum_y[7][2] * sum_y[7][2];
	n_square_y[7][1] = sum_y[7][1] * sum_y[7][1];
	n_square_y[7][0] = sum_y[7][0] * sum_y[7][0];
	/////////////////////////////////////////////
	n_square_y[8][2] = sum_y[8][2] * sum_y[8][2];
	n_square_y[8][1] = sum_y[8][1] * sum_y[8][1];
	n_square_y[8][0] = sum_y[8][0] * sum_y[8][0];
	n_square_y[9][2] = sum_y[9][2] * sum_y[9][2];
	n_square_y[9][1] = sum_y[9][1] * sum_y[9][1];
	n_square_y[9][0] = sum_y[9][0] * sum_y[9][0];
	n_square_y[10][2] = sum_y[10][2] * sum_y[10][2];
	n_square_y[10][1] = sum_y[10][1] * sum_y[10][1];
	n_square_y[10][0] = sum_y[10][0] * sum_y[10][0];
	n_square_y[11][2] = sum_y[11][2] * sum_y[11][2];
	n_square_y[11][1] = sum_y[11][1] * sum_y[11][1];
	n_square_y[11][0] = sum_y[11][0] * sum_y[11][0];
end
///////////// get gx^2 ////////////////////////

always @(*) begin
	temp_x[0][2] = store1_row_0[cnt_col] - store1_d10[cnt_col - 1];
	temp_x[0][1] = blk0[8] - store0_col[2];
	temp_x[0][0] = blk0[5] - store0_col[1];
	////////////////////////////////////////
	temp_x[1][2] = store1_row_1[cnt_col] - store1_d11[cnt_col - 1];
	temp_x[1][1] = blk0[7] - store1_col[2];
	temp_x[1][0] = blk0[4] - store1_col[1];
	////////////////////////////////////////
	temp_x[2][2] = store1_row_2[cnt_col] - store1_row_0[cnt_col];
	temp_x[2][1] = blk0[6] - blk0[8];
	temp_x[2][0] = blk0[3] - blk0[5];
	////////////////////////////////////////
	temp_x[3][2] = store1_row_3[cnt_col] - store1_row_1[cnt_col];
	temp_x[3][1] = blk1[8] - blk0[7];                              
	temp_x[3][0] = blk1[5] - blk0[4];                              
	////////////////////////////////////////
	temp_x[4][2] = store1_row_4[cnt_col] - store1_row_2[cnt_col];
	temp_x[4][1] = blk1[7] - blk0[6];                              
	temp_x[4][0] = blk1[4] - blk0[3];                              
	////////////////////////////////////////
	temp_x[5][2] = store1_row_5[cnt_col] - store1_row_3[cnt_col];
	temp_x[5][1] = blk1[6] - blk1[8];                              
	temp_x[5][0] = blk1[3] - blk1[5];                              
	////////////////////////////////////////
	temp_x[6][2] = store1_row_6[cnt_col] - store1_row_4[cnt_col];
	temp_x[6][1] = blk2[8] - blk1[7];                              
	temp_x[6][0] = blk2[5] - blk1[4];                              
	////////////////////////////////////////
	temp_x[7][2] = store1_row_7[cnt_col] - store1_row_5[cnt_col];
	temp_x[7][1] = blk2[7] - blk1[6];                              
	temp_x[7][0] = blk2[4] - blk1[3];                              
	////////////////////////////////////////
	temp_x[8][2] = store1_row_8[cnt_col] - store1_row_6[cnt_col];
	temp_x[8][1] = blk2[6] - blk2[8];                              
	temp_x[8][0] = blk2[3] - blk2[5];                              
	////////////////////////////////////////
	temp_x[9][2] = store1_row_9[cnt_col] - store1_row_7[cnt_col];
	temp_x[9][1] = blk3[8] - blk2[7];                              
	temp_x[9][0] = blk3[5] - blk2[4];                              
	////////////////////////////////////////
	temp_x[10][2] = store1_row_10[cnt_col] - store1_row_8[cnt_col];
	temp_x[10][1] = blk3[7] - blk2[6];                              
	temp_x[10][0] = blk3[4] - blk2[3];                              
	////////////////////////////////////////
	temp_x[11][2] = store1_row_11[cnt_col] - store1_row_9[cnt_col];
	temp_x[11][1] = blk3[6] - blk3[8];                              
	temp_x[11][0] = blk3[3] - blk3[5];                              
end


//////////// select n_sum_x ////////////////
always @(*) begin
	if(cnt_col == 0) begin
	  n_sum_x[0][2] = 0;
	  n_sum_x[0][1] = 0;
	  n_sum_x[0][0] = 0;
	  ///////////////////////
	  n_sum_x[1][2] = blk0[7];
	  n_sum_x[1][1] = blk0[4];
	  n_sum_x[1][0] = blk0[1];
	  ///////////////////////
	  for(i=2;i<12;i=i+1) begin
		for(j=0;j<3;j=j+1) begin
			n_sum_x[i][j] = temp_x[i][j];
		end
	  end
	end
	else begin
	  for(i=0;i<12;i=i+1) begin
		for(j=0;j<3;j=j+1) begin
			n_sum_x[i][j] = temp_x[i][j];
		end
	  end
	end
end

always @(*) begin
	n_square_x[0][2] = sum_x[0][2] * sum_x[0][2];
	n_square_x[0][1] = sum_x[0][1] * sum_x[0][1];
	n_square_x[0][0] = sum_x[0][0] * sum_x[0][0];
	n_square_x[1][2] = sum_x[1][2] * sum_x[1][2];
	n_square_x[1][1] = sum_x[1][1] * sum_x[1][1];
	n_square_x[1][0] = sum_x[1][0] * sum_x[1][0];
	n_square_x[2][2] = sum_x[2][2] * sum_x[2][2];
	n_square_x[2][1] = sum_x[2][1] * sum_x[2][1];
	n_square_x[2][0] = sum_x[2][0] * sum_x[2][0];
	n_square_x[3][2] = sum_x[3][2] * sum_x[3][2];
	n_square_x[3][1] = sum_x[3][1] * sum_x[3][1];
	n_square_x[3][0] = sum_x[3][0] * sum_x[3][0];
	n_square_x[4][2] = sum_x[4][2] * sum_x[4][2];
	n_square_x[4][1] = sum_x[4][1] * sum_x[4][1];
	n_square_x[4][0] = sum_x[4][0] * sum_x[4][0];
	n_square_x[5][2] = sum_x[5][2] * sum_x[5][2];
	n_square_x[5][1] = sum_x[5][1] * sum_x[5][1];
	n_square_x[5][0] = sum_x[5][0] * sum_x[5][0];
	n_square_x[6][2] = sum_x[6][2] * sum_x[6][2];
	n_square_x[6][1] = sum_x[6][1] * sum_x[6][1];
	n_square_x[6][0] = sum_x[6][0] * sum_x[6][0];
	n_square_x[7][2] = sum_x[7][2] * sum_x[7][2];
	n_square_x[7][1] = sum_x[7][1] * sum_x[7][1];
	n_square_x[7][0] = sum_x[7][0] * sum_x[7][0];
	n_square_x[8][2] = sum_x[8][2] * sum_x[8][2];
	n_square_x[8][1] = sum_x[8][1] * sum_x[8][1];
	n_square_x[8][0] = sum_x[8][0] * sum_x[8][0];
	n_square_x[9][2] = sum_x[9][2] * sum_x[9][2];
	n_square_x[9][1] = sum_x[9][1] * sum_x[9][1];
	n_square_x[9][0] = sum_x[9][0] * sum_x[9][0];
	n_square_x[10][2] = sum_x[10][2] * sum_x[10][2];
	n_square_x[10][1] = sum_x[10][1] * sum_x[10][1];
	n_square_x[10][0] = sum_x[10][0] * sum_x[10][0];
	n_square_x[11][2] = sum_x[11][2] * sum_x[11][2];
	n_square_x[11][1] = sum_x[11][1] * sum_x[11][1];
	n_square_x[11][0] = sum_x[11][0] * sum_x[11][0];
end

///////////// gx^2 + gy^2 ///////////////
always @(*) begin
	n_square_sum0[8] = square_y[0][2] + square_x[0][2];
	n_square_sum0[7] = square_y[0][1] + square_x[1][2];
	n_square_sum0[6] = square_y[0][0] + square_x[2][2];
	n_square_sum0[5] = square_y[4][2] + square_x[0][1];
	n_square_sum0[4] = square_y[4][1] + square_x[1][1];
	n_square_sum0[3] = square_y[4][0] + square_x[2][1];
	n_square_sum0[2] = square_y[8][2] + square_x[0][0];
	n_square_sum0[1] = square_y[8][1] + square_x[1][0];
	n_square_sum0[0] = square_y[8][0] + square_x[2][0];
	/////////////////////////////////////////////////
	n_square_sum1[8] = square_y[1][2] + square_x[3][2];
	n_square_sum1[7] = square_y[1][1] + square_x[4][2];
	n_square_sum1[6] = square_y[1][0] + square_x[5][2];
	n_square_sum1[5] = square_y[5][2] + square_x[3][1];
	n_square_sum1[4] = square_y[5][1] + square_x[4][1];
	n_square_sum1[3] = square_y[5][0] + square_x[5][1];
	n_square_sum1[2] = square_y[9][2] + square_x[3][0];
	n_square_sum1[1] = square_y[9][1] + square_x[4][0];
	n_square_sum1[0] = square_y[9][0] + square_x[5][0];
	/////////////////////////////////////////////////
	n_square_sum2[8] = square_y[2][2] + square_x[6][2];
	n_square_sum2[7] = square_y[2][1] + square_x[7][2];
	n_square_sum2[6] = square_y[2][0] + square_x[8][2];
	n_square_sum2[5] = square_y[6][2] + square_x[6][1];
	n_square_sum2[4] = square_y[6][1] + square_x[7][1];
	n_square_sum2[3] = square_y[6][0] + square_x[8][1];
	n_square_sum2[2] = square_y[10][2] + square_x[6][0];
	n_square_sum2[1] = square_y[10][1] + square_x[7][0];
	n_square_sum2[0] = square_y[10][0] + square_x[8][0];
	///////////////////////////////////////////////////
	n_square_sum3[8] = square_y[3][2] + square_x[9][2];
	n_square_sum3[7] = square_y[3][1] + square_x[10][2];
	n_square_sum3[6] = square_y[3][0] + square_x[11][2];
	n_square_sum3[5] = square_y[7][2] + square_x[9][1];
	n_square_sum3[4] = square_y[7][1] + square_x[10][1];
	n_square_sum3[3] = square_y[7][0] + square_x[11][1];
	n_square_sum3[2] = square_y[11][2] + square_x[9][0];
	n_square_sum3[1] = square_y[11][1] + square_x[10][0];
	n_square_sum3[0] = square_y[11][0] + square_x[11][0];
end

always @* begin
	// if (cnt_row == 0 && cnt_col == 2)
	if (cnt_row == 0 && cnt_col == 3)
		valid_next = 1;
	else if (valid == 1)
		valid_next = 1;
	else
		valid_next = 0;
end

always @(posedge clk) begin
	if(~rst_n) begin
	  for(i=0;i<53;i=i+1) begin
		store0_row_0[i] <= 0;
		store0_row_1[i] <= 0;
		store0_row_2[i] <= 0;
		store0_row_3[i] <= 0;
		store0_row_4[i] <= 0;
		store0_row_5[i] <= 0;
		store0_row_6[i] <= 0;
		store0_row_7[i] <= 0;
		store0_row_8[i] <= 0;
		store0_row_9[i] <= 0;
		store0_row_10[i] <= 0;
		store0_row_11[i] <= 0;
		store1_row_0[i] <= 0;
		store1_row_1[i] <= 0;
		store1_row_2[i] <= 0;
		store1_row_3[i] <= 0;
		store1_row_4[i] <= 0;
		store1_row_5[i] <= 0;
		store1_row_6[i] <= 0;
		store1_row_7[i] <= 0;
		store1_row_8[i] <= 0;
		store1_row_9[i] <= 0;
		store1_row_10[i] <= 0;
		store1_row_11[i] <= 0;
	  end
	  for(i=0;i<3;i=i+1) begin
		store0_col[i] <= 0;
		store1_col[i] <= 0;
	  end
	  for(i=0;i<12;i=i+1) begin
		for(j=0;j<3;j=j+1) begin
			sum_y[i][j] <= 0;
			sum_x[i][j] <= 0;
		end
	  end
	  for(i=0;i<12;i=i+1) begin
		for(j=0;j<3;j=j+1) begin
			square_y[i][j] <= 0;
			square_x[i][j] <= 0;
		end
	  end
	  for(i=0;i<9;i=i+1) begin
		square_sum0[i] <= 0;
		square_sum1[i] <= 0;
		square_sum2[i] <= 0;
		square_sum3[i] <= 0;
	  end
	  for(i=0;i<53;i=i+1) begin
		  store0_d11[i] <= 0;
		  store1_d10[i] <= 0;
		  store1_d11[i] <= 0;
	  end
	  valid <= 0;
	end
	else begin
	  for(i=0;i<53;i=i+1) begin
		// store0_row[i][j] <= n_store0_row[i][j];
		store0_row_0[i] <= n_store0_row_0[i];
		store0_row_1[i] <= n_store0_row_1[i];
		store0_row_2[i] <= n_store0_row_2[i];
		store0_row_3[i] <= n_store0_row_3[i];
		store0_row_4[i] <= n_store0_row_4[i];
		store0_row_5[i] <= n_store0_row_5[i];
		store0_row_6[i] <= n_store0_row_6[i];
		store0_row_7[i] <= n_store0_row_7[i];
		store0_row_8[i] <= n_store0_row_8[i];
		store0_row_9[i] <= n_store0_row_9[i];
		store0_row_10[i] <= n_store0_row_10[i];
		store0_row_11[i] <= n_store0_row_11[i];

		store1_row_0[i] <= n_store1_row_0[i];
		store1_row_1[i] <= n_store1_row_1[i];
		store1_row_2[i] <= n_store1_row_2[i];
		store1_row_3[i] <= n_store1_row_3[i];
		store1_row_4[i] <= n_store1_row_4[i];
		store1_row_5[i] <= n_store1_row_5[i];
		store1_row_6[i] <= n_store1_row_6[i];
		store1_row_7[i] <= n_store1_row_7[i];
		store1_row_8[i] <= n_store1_row_8[i];
		store1_row_9[i] <= n_store1_row_9[i];
		store1_row_10[i] <= n_store1_row_10[i];
		store1_row_11[i] <= n_store1_row_11[i];
	  end
	  for(i=0;i<3;i=i+1) begin
		store0_col[i] <= n_store0_col[i];
		store1_col[i] <= n_store1_col[i];
	  end
	  for(i=0;i<12;i=i+1) begin
		for(j=0;j<3;j=j+1) begin
			sum_y[i][j] <= n_sum_y[i][j];
			sum_x[i][j] <= n_sum_x[i][j];
		end
	  end
	  for(i=0;i<12;i=i+1) begin
		for(j=0;j<3;j=j+1) begin
			square_y[i][j] <= n_square_y[i][j];
			square_x[i][j] <= n_square_x[i][j];
		end
	  end
	  for(i=0;i<9;i=i+1) begin
		square_sum0[i] <= n_square_sum0[i];
		square_sum1[i] <= n_square_sum1[i];
		square_sum2[i] <= n_square_sum2[i];
		square_sum3[i] <= n_square_sum3[i];
	  end
	  for(i=0;i<53;i=i+1) begin
		  store0_d11[i] <= n_store0_d11[i];
		  store1_d10[i] <= n_store1_d10[i];
		  store1_d11[i] <= n_store1_d11[i];
	  end
	  valid <= valid_next;
	end
end

endmodule
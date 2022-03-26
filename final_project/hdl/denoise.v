module denoise
#(
    parameter BIT_WIDTH = 8
)
(
    input clk,
    input rst_n,
    input [5*14*BIT_WIDTH-1:0] pix_in, // 70*8-1 = 559
    output [9*BIT_WIDTH-1:0] block_out_0,
    output [9*BIT_WIDTH-1:0] block_out_1,
    output [9*BIT_WIDTH-1:0] block_out_2,
    output [9*BIT_WIDTH-1:0] block_out_3, 
    // output reg [9*20-1:0] hog_block_out_0,
    // output reg [9*20-1:0] hog_block_out_1,
    // output reg [9*20-1:0] hog_block_out_2,
    // output reg [9*20-1:0] hog_block_out_3,

    output reg valid
);

reg [2:0] cnt, cnt_n;

reg [8-1:0] block_in_0[0:24];
reg [8-1:0] block_in_1[0:24];
reg [8-1:0] block_in_2[0:24];
reg [8-1:0] block_in_3[0:24];

reg [9*BIT_WIDTH-1:0] block_out_0_n;
reg [9*BIT_WIDTH-1:0] block_out_1_n;
reg [9*BIT_WIDTH-1:0] block_out_2_n;
reg [9*BIT_WIDTH-1:0] block_out_3_n;

// **** for block 0 **** //
wire [8-1:0] b0_m0, b0_m1, b0_m2;
wire [8-1:0] b0_m3, b0_m4, b0_m5;
wire [8-1:0] b0_m6, b0_m7, b0_m8;
wire [8-1:0] b0_m9, b0_m10, b0_m11;
wire [8-1:0] b0_m12, b0_m13, b0_m14;

wire [8-1:0] b0_out0, b0_out1, b0_out2;
wire [8-1:0] b0_out3, b0_out4, b0_out5;
wire [8-1:0] b0_out6, b0_out7, b0_out8;

// 0, 0
median Ua000(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[0]), .val_1(block_in_0[1]), .val_2(block_in_0[2]), .med(b0_m0));
median Ua001(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[5]), .val_1(block_in_0[6]), .val_2(block_in_0[7]), .med(b0_m1));
median Ua002(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[10]), .val_1(block_in_0[11]), .val_2(block_in_0[12]), .med(b0_m2));
median Ua003(.clk(clk), .rst_n(rst_n), .val_0(b0_m0), .val_1(b0_m1), .val_2(b0_m2), .med(b0_out0)); // one of 9
// 0, 1
median Ua010(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[1]), .val_1(block_in_0[2]), .val_2(block_in_0[3]), .med(b0_m3));
median Ua011(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[6]), .val_1(block_in_0[7]), .val_2(block_in_0[8]), .med(b0_m4));
median Ua012(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[11]), .val_1(block_in_0[12]), .val_2(block_in_0[13]), .med(b0_m5));
median Ua013(.clk(clk), .rst_n(rst_n), .val_0(b0_m3), .val_1(b0_m4), .val_2(b0_m5), .med(b0_out1)); // one of 9
// 0, 2
median Ua020(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[2]), .val_1(block_in_0[3]), .val_2(block_in_0[4]), .med(b0_m6));
median Ua021(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[7]), .val_1(block_in_0[8]), .val_2(block_in_0[9]), .med(b0_m7));
median Ua022(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[12]), .val_1(block_in_0[13]), .val_2(block_in_0[14]), .med(b0_m8));
median Ua023(.clk(clk), .rst_n(rst_n), .val_0(b0_m6), .val_1(b0_m7), .val_2(b0_m8), .med(b0_out2)); // one of 9
// 1, 0
median Ua100(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[15]), .val_1(block_in_0[16]), .val_2(block_in_0[17]), .med(b0_m9));
median Ua101(.clk(clk), .rst_n(rst_n), .val_0(b0_m1), .val_1(b0_m2), .val_2(b0_m9), .med(b0_out3)); // one of 9
// 1, 1
median Ua110(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[16]), .val_1(block_in_0[17]), .val_2(block_in_0[18]), .med(b0_m10));
median Ua111(.clk(clk), .rst_n(rst_n), .val_0(b0_m4), .val_1(b0_m5), .val_2(b0_m10), .med(b0_out4)); // one of 9
// 1, 2
median Ua120(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[17]), .val_1(block_in_0[18]), .val_2(block_in_0[19]), .med(b0_m11));
median Ua121(.clk(clk), .rst_n(rst_n), .val_0(b0_m7), .val_1(b0_m8), .val_2(b0_m11), .med(b0_out5)); // one of 9
// 2, 0
median Ua200(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[20]), .val_1(block_in_0[21]), .val_2(block_in_0[22]), .med(b0_m12));
median Ua201(.clk(clk), .rst_n(rst_n), .val_0(b0_m2), .val_1(b0_m9), .val_2(b0_m12), .med(b0_out6)); // one of 9
// 2, 1
median Ua210(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[21]), .val_1(block_in_0[22]), .val_2(block_in_0[23]), .med(b0_m13));
median Ua211(.clk(clk), .rst_n(rst_n), .val_0(b0_m5), .val_1(b0_m10), .val_2(b0_m13), .med(b0_out7)); // one of 9
// 2, 2
median Ua220(.clk(clk), .rst_n(rst_n), .val_0(block_in_0[22]), .val_1(block_in_0[23]), .val_2(block_in_0[24]), .med(b0_m14));
median Ua221(.clk(clk), .rst_n(rst_n), .val_0(b0_m8), .val_1(b0_m11), .val_2(b0_m14), .med(b0_out8)); // one of 9
// ******** //

// **** for block 1 **** //
wire [8-1:0] b1_m0, b1_m1, b1_m2;
wire [8-1:0] b1_m3, b1_m4, b1_m5;
wire [8-1:0] b1_m6, b1_m7, b1_m8;
wire [8-1:0] b1_m9, b1_m10, b1_m11;
wire [8-1:0] b1_m12, b1_m13, b1_m14;

wire [8-1:0] b1_out0, b1_out1, b1_out2;
wire [8-1:0] b1_out3, b1_out4, b1_out5;
wire [8-1:0] b1_out6, b1_out7, b1_out8;

// 0, 0
median Ub000(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[0]), .val_1(block_in_1[1]), .val_2(block_in_1[2]), .med(b1_m0));
median Ub001(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[5]), .val_1(block_in_1[6]), .val_2(block_in_1[7]), .med(b1_m1));
median Ub002(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[10]), .val_1(block_in_1[11]), .val_2(block_in_1[12]), .med(b1_m2));
median Ub003(.clk(clk), .rst_n(rst_n), .val_0(b1_m0), .val_1(b1_m1), .val_2(b1_m2), .med(b1_out0)); // one of 9
// 0, 1
median Ub010(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[1]), .val_1(block_in_1[2]), .val_2(block_in_1[3]), .med(b1_m3));
median Ub011(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[6]), .val_1(block_in_1[7]), .val_2(block_in_1[8]), .med(b1_m4));
median Ub012(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[11]), .val_1(block_in_1[12]), .val_2(block_in_1[13]), .med(b1_m5));
median Ub013(.clk(clk), .rst_n(rst_n), .val_0(b1_m3), .val_1(b1_m4), .val_2(b1_m5), .med(b1_out1)); // one of 9
// 0, 2
median Ub020(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[2]), .val_1(block_in_1[3]), .val_2(block_in_1[4]), .med(b1_m6));
median Ub021(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[7]), .val_1(block_in_1[8]), .val_2(block_in_1[9]), .med(b1_m7));
median Ub022(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[12]), .val_1(block_in_1[13]), .val_2(block_in_1[14]), .med(b1_m8));
median Ub023(.clk(clk), .rst_n(rst_n), .val_0(b1_m6), .val_1(b1_m7), .val_2(b1_m8), .med(b1_out2)); // one of 9
// 1, 0
median Ub100(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[15]), .val_1(block_in_1[16]), .val_2(block_in_1[17]), .med(b1_m9));
median Ub101(.clk(clk), .rst_n(rst_n), .val_0(b1_m1), .val_1(b1_m2), .val_2(b1_m9), .med(b1_out3)); // one of 9
// 1, 1
median Ub110(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[16]), .val_1(block_in_1[17]), .val_2(block_in_1[18]), .med(b1_m10));
median Ub111(.clk(clk), .rst_n(rst_n), .val_0(b1_m4), .val_1(b1_m5), .val_2(b1_m10), .med(b1_out4)); // one of 9
// 1, 2
median Ub120(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[17]), .val_1(block_in_1[18]), .val_2(block_in_1[19]), .med(b1_m11));
median Ub121(.clk(clk), .rst_n(rst_n), .val_0(b1_m7), .val_1(b1_m8), .val_2(b1_m11), .med(b1_out5)); // one of 9
// 2, 0
median Ub200(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[20]), .val_1(block_in_1[21]), .val_2(block_in_1[22]), .med(b1_m12));
median Ub201(.clk(clk), .rst_n(rst_n), .val_0(b1_m2), .val_1(b1_m9), .val_2(b1_m12), .med(b1_out6)); // one of 9
// 2, 1
median Ub210(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[21]), .val_1(block_in_1[22]), .val_2(block_in_1[23]), .med(b1_m13));
median Ub211(.clk(clk), .rst_n(rst_n), .val_0(b1_m5), .val_1(b1_m10), .val_2(b1_m13), .med(b1_out7)); // one of 9
// 2, 2
median Ub220(.clk(clk), .rst_n(rst_n), .val_0(block_in_1[22]), .val_1(block_in_1[23]), .val_2(block_in_1[24]), .med(b1_m14));
median Ub221(.clk(clk), .rst_n(rst_n), .val_0(b1_m8), .val_1(b1_m11), .val_2(b1_m14), .med(b1_out8)); // one of 9
// ******** //

// **** for block 2 **** //
wire [8-1:0] b2_m0, b2_m1, b2_m2;
wire [8-1:0] b2_m3, b2_m4, b2_m5;
wire [8-1:0] b2_m6, b2_m7, b2_m8;
wire [8-1:0] b2_m9, b2_m10, b2_m11;
wire [8-1:0] b2_m12, b2_m13, b2_m14;

wire [8-1:0] b2_out0, b2_out1, b2_out2;
wire [8-1:0] b2_out3, b2_out4, b2_out5;
wire [8-1:0] b2_out6, b2_out7, b2_out8;

// 0, 0
median Uc000(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[0]), .val_1(block_in_2[1]), .val_2(block_in_2[2]), .med(b2_m0));
median Uc001(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[5]), .val_1(block_in_2[6]), .val_2(block_in_2[7]), .med(b2_m1));
median Uc002(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[10]), .val_1(block_in_2[11]), .val_2(block_in_2[12]), .med(b2_m2));
median Uc003(.clk(clk), .rst_n(rst_n), .val_0(b2_m0), .val_1(b2_m1), .val_2(b2_m2), .med(b2_out0)); // one of 9
// 0, 1
median Uc010(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[1]), .val_1(block_in_2[2]), .val_2(block_in_2[3]), .med(b2_m3));
median Uc011(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[6]), .val_1(block_in_2[7]), .val_2(block_in_2[8]), .med(b2_m4));
median Uc012(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[11]), .val_1(block_in_2[12]), .val_2(block_in_2[13]), .med(b2_m5));
median Uc013(.clk(clk), .rst_n(rst_n), .val_0(b2_m3), .val_1(b2_m4), .val_2(b2_m5), .med(b2_out1)); // one of 9
// 0, 2
median Uc020(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[2]), .val_1(block_in_2[3]), .val_2(block_in_2[4]), .med(b2_m6));
median Uc021(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[7]), .val_1(block_in_2[8]), .val_2(block_in_2[9]), .med(b2_m7));
median Uc022(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[12]), .val_1(block_in_2[13]), .val_2(block_in_2[14]), .med(b2_m8));
median Uc023(.clk(clk), .rst_n(rst_n), .val_0(b2_m6), .val_1(b2_m7), .val_2(b2_m8), .med(b2_out2)); // one of 9
// 1, 0
median Uc100(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[15]), .val_1(block_in_2[16]), .val_2(block_in_2[17]), .med(b2_m9));
median Uc101(.clk(clk), .rst_n(rst_n), .val_0(b2_m1), .val_1(b2_m2), .val_2(b2_m9), .med(b2_out3)); // one of 9
// 1, 1
median Uc110(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[16]), .val_1(block_in_2[17]), .val_2(block_in_2[18]), .med(b2_m10));
median Uc111(.clk(clk), .rst_n(rst_n), .val_0(b2_m4), .val_1(b2_m5), .val_2(b2_m10), .med(b2_out4)); // one of 9
// 1, 2
median Uc120(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[17]), .val_1(block_in_2[18]), .val_2(block_in_2[19]), .med(b2_m11));
median Uc121(.clk(clk), .rst_n(rst_n), .val_0(b2_m7), .val_1(b2_m8), .val_2(b2_m11), .med(b2_out5)); // one of 9
// 2, 0
median Uc200(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[20]), .val_1(block_in_2[21]), .val_2(block_in_2[22]), .med(b2_m12));
median Uc201(.clk(clk), .rst_n(rst_n), .val_0(b2_m2), .val_1(b2_m9), .val_2(b2_m12), .med(b2_out6)); // one of 9
// 2, 1
median Uc210(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[21]), .val_1(block_in_2[22]), .val_2(block_in_2[23]), .med(b2_m13));
median Uc211(.clk(clk), .rst_n(rst_n), .val_0(b2_m5), .val_1(b2_m10), .val_2(b2_m13), .med(b2_out7)); // one of 9
// 2, 2
median Uc220(.clk(clk), .rst_n(rst_n), .val_0(block_in_2[22]), .val_1(block_in_2[23]), .val_2(block_in_2[24]), .med(b2_m14));
median Uc221(.clk(clk), .rst_n(rst_n), .val_0(b2_m8), .val_1(b2_m11), .val_2(b2_m14), .med(b2_out8)); // one of 9
// ******** //

// **** for block 3 **** //
wire [8-1:0] b3_m0, b3_m1, b3_m2;
wire [8-1:0] b3_m3, b3_m4, b3_m5;
wire [8-1:0] b3_m6, b3_m7, b3_m8;
wire [8-1:0] b3_m9, b3_m10, b3_m11;
wire [8-1:0] b3_m12, b3_m13, b3_m14;

wire [8-1:0] b3_out0, b3_out1, b3_out2;
wire [8-1:0] b3_out3, b3_out4, b3_out5;
wire [8-1:0] b3_out6, b3_out7, b3_out8;

// 0, 0
median Ud000(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[0]), .val_1(block_in_3[1]), .val_2(block_in_3[2]), .med(b3_m0));
median Ud001(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[5]), .val_1(block_in_3[6]), .val_2(block_in_3[7]), .med(b3_m1));
median Ud002(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[10]), .val_1(block_in_3[11]), .val_2(block_in_3[12]), .med(b3_m2));
median Ud003(.clk(clk), .rst_n(rst_n), .val_0(b3_m0), .val_1(b3_m1), .val_2(b3_m2), .med(b3_out0)); // one of 9
// 0, 1
median Ud010(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[1]), .val_1(block_in_3[2]), .val_2(block_in_3[3]), .med(b3_m3));
median Ud011(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[6]), .val_1(block_in_3[7]), .val_2(block_in_3[8]), .med(b3_m4));
median Ud012(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[11]), .val_1(block_in_3[12]), .val_2(block_in_3[13]), .med(b3_m5));
median Ud013(.clk(clk), .rst_n(rst_n), .val_0(b3_m3), .val_1(b3_m4), .val_2(b3_m5), .med(b3_out1)); // one of 9
// 0, 2
median Ud020(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[2]), .val_1(block_in_3[3]), .val_2(block_in_3[4]), .med(b3_m6));
median Ud021(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[7]), .val_1(block_in_3[8]), .val_2(block_in_3[9]), .med(b3_m7));
median Ud022(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[12]), .val_1(block_in_3[13]), .val_2(block_in_3[14]), .med(b3_m8));
median Ud023(.clk(clk), .rst_n(rst_n), .val_0(b3_m6), .val_1(b3_m7), .val_2(b3_m8), .med(b3_out2)); // one of 9
// 1, 0
median Ud100(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[15]), .val_1(block_in_3[16]), .val_2(block_in_3[17]), .med(b3_m9));
median Ud101(.clk(clk), .rst_n(rst_n), .val_0(b3_m1), .val_1(b3_m2), .val_2(b3_m9), .med(b3_out3)); // one of 9
// 1, 1
median Ud110(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[16]), .val_1(block_in_3[17]), .val_2(block_in_3[18]), .med(b3_m10));
median Ud111(.clk(clk), .rst_n(rst_n), .val_0(b3_m4), .val_1(b3_m5), .val_2(b3_m10), .med(b3_out4)); // one of 9
// 1, 2
median Ud120(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[17]), .val_1(block_in_3[18]), .val_2(block_in_3[19]), .med(b3_m11));
median Ud121(.clk(clk), .rst_n(rst_n), .val_0(b3_m7), .val_1(b3_m8), .val_2(b3_m11), .med(b3_out5)); // one of 9
// 2, 0
median Ud200(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[20]), .val_1(block_in_3[21]), .val_2(block_in_3[22]), .med(b3_m12));
median Ud201(.clk(clk), .rst_n(rst_n), .val_0(b3_m2), .val_1(b3_m9), .val_2(b3_m12), .med(b3_out6)); // one of 9
// 2, 1
median Ud210(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[21]), .val_1(block_in_3[22]), .val_2(block_in_3[23]), .med(b3_m13));
median Ud211(.clk(clk), .rst_n(rst_n), .val_0(b3_m5), .val_1(b3_m10), .val_2(b3_m13), .med(b3_out7)); // one of 9
// 2, 2
median Ud220(.clk(clk), .rst_n(rst_n), .val_0(block_in_3[22]), .val_1(block_in_3[23]), .val_2(block_in_3[24]), .med(b3_m14));
median Ud221(.clk(clk), .rst_n(rst_n), .val_0(b3_m8), .val_1(b3_m11), .val_2(b3_m14), .med(b3_out8)); // one of 9
// ******** //

always @* begin
    if (cnt == 4)
        cnt_n = cnt;
    else
        cnt_n = cnt + 1;
end

always @* begin
    if (cnt == 4)
        valid = 1;
    else
        valid = 0;
end


// TODO: block 0
always @(*) begin
    block_in_0[0] = pix_in[559:552];
    block_in_0[1] = pix_in[551:544];
    block_in_0[2] = pix_in[543:536];
    block_in_0[3] = pix_in[535:528];
    block_in_0[4] = pix_in[527:520];
    block_in_0[5] = pix_in[447:440];
    block_in_0[6] = pix_in[439:432];
    block_in_0[7] = pix_in[431:424];
    block_in_0[8] = pix_in[423:416];
    block_in_0[9] = pix_in[415:408];
    block_in_0[10] = pix_in[335:328];
    block_in_0[11] = pix_in[327:320];
    block_in_0[12] = pix_in[319:312];
    block_in_0[13] = pix_in[311:304];
    block_in_0[14] = pix_in[303:296];
    block_in_0[15] = pix_in[223:216];
    block_in_0[16] = pix_in[215:208];
    block_in_0[17] = pix_in[207:200];
    block_in_0[18] = pix_in[199:192];
    block_in_0[19] = pix_in[191:184];
    block_in_0[20] = pix_in[111:104];
    block_in_0[21] = pix_in[103:96];
    block_in_0[22] = pix_in[95:88];
    block_in_0[23] = pix_in[87:80];
    block_in_0[24] = pix_in[79:72];

    block_in_1[0] = pix_in[535:528];
    block_in_1[1] = pix_in[527:520];
    block_in_1[2] = pix_in[519:512];
    block_in_1[3] = pix_in[511:504];
    block_in_1[4] = pix_in[503:496];
    block_in_1[5] = pix_in[423:416];
    block_in_1[6] = pix_in[415:408];
    block_in_1[7] = pix_in[407:400];
    block_in_1[8] = pix_in[399:392];
    block_in_1[9] = pix_in[391:384];
    block_in_1[10] = pix_in[311:304];
    block_in_1[11] = pix_in[303:296];
    block_in_1[12] = pix_in[295:288];
    block_in_1[13] = pix_in[287:280];
    block_in_1[14] = pix_in[279:272];
    block_in_1[15] = pix_in[199:192];
    block_in_1[16] = pix_in[191:184];
    block_in_1[17] = pix_in[183:176];
    block_in_1[18] = pix_in[175:168];
    block_in_1[19] = pix_in[167:160];
    block_in_1[20] = pix_in[87:80];
    block_in_1[21] = pix_in[79:72];
    block_in_1[22] = pix_in[71:64];
    block_in_1[23] = pix_in[63:56];
    block_in_1[24] = pix_in[55:48];

    block_in_2[0] = pix_in[511:504];
    block_in_2[1] = pix_in[503:496];
    block_in_2[2] = pix_in[495:488];
    block_in_2[3] = pix_in[487:480];
    block_in_2[4] = pix_in[479:472];
    block_in_2[5] = pix_in[399:392];
    block_in_2[6] = pix_in[391:384];
    block_in_2[7] = pix_in[383:376];
    block_in_2[8] = pix_in[375:368];
    block_in_2[9] = pix_in[367:360];
    block_in_2[10] = pix_in[287:280];
    block_in_2[11] = pix_in[279:272];
    block_in_2[12] = pix_in[271:264];
    block_in_2[13] = pix_in[263:256];
    block_in_2[14] = pix_in[255:248];
    block_in_2[15] = pix_in[175:168];
    block_in_2[16] = pix_in[167:160];
    block_in_2[17] = pix_in[159:152];
    block_in_2[18] = pix_in[151:144];
    block_in_2[19] = pix_in[143:136];
    block_in_2[20] = pix_in[63:56];
    block_in_2[21] = pix_in[55:48];
    block_in_2[22] = pix_in[47:40];
    block_in_2[23] = pix_in[39:32];
    block_in_2[24] = pix_in[31:24];

    block_in_3[0] = pix_in[487:480];
    block_in_3[1] = pix_in[479:472];
    block_in_3[2] = pix_in[471:464];
    block_in_3[3] = pix_in[463:456];
    block_in_3[4] = pix_in[455:448];
    block_in_3[5] = pix_in[375:368];
    block_in_3[6] = pix_in[367:360];
    block_in_3[7] = pix_in[359:352];
    block_in_3[8] = pix_in[351:344];
    block_in_3[9] = pix_in[343:336];
    block_in_3[10] = pix_in[263:256];
    block_in_3[11] = pix_in[255:248];
    block_in_3[12] = pix_in[247:240];
    block_in_3[13] = pix_in[239:232];
    block_in_3[14] = pix_in[231:224];
    block_in_3[15] = pix_in[151:144];
    block_in_3[16] = pix_in[143:136];
    block_in_3[17] = pix_in[135:128];
    block_in_3[18] = pix_in[127:120];
    block_in_3[19] = pix_in[119:112];
    block_in_3[20] = pix_in[39:32];
    block_in_3[21] = pix_in[31:24];
    block_in_3[22] = pix_in[23:16];
    block_in_3[23] = pix_in[15:8];
    block_in_3[24] = pix_in[7:0];
end

// always @(*) begin
assign block_out_0 = {b0_out0, b0_out1, b0_out2, b0_out3, b0_out4, b0_out5, b0_out6, b0_out7, b0_out8};
assign block_out_1 = {b1_out0, b1_out1, b1_out2, b1_out3, b1_out4, b1_out5, b1_out6, b1_out7, b1_out8};
assign block_out_2 = {b2_out0, b2_out1, b2_out2, b2_out3, b2_out4, b2_out5, b2_out6, b2_out7, b2_out8};
assign block_out_3 = {b3_out0, b3_out1, b3_out2, b3_out3, b3_out4, b3_out5, b3_out6, b3_out7, b3_out8};
// end

always @(posedge clk) begin
    if (~rst_n) begin
        cnt <= 0;
    end
    else begin
        cnt <= cnt_n;
    end
end
endmodule

module qr_decode(
input clk,                           // clock input
input srstn,                         // synchronous reset (active low)
input qr_decode_start,               // start decoding for one QR code
                                     // 1: start (one-cycle pulse)
input sram_rdata,                    // read data from SRAM
output reg [11:0] sram_raddr,        // read address to SRAM

output reg decode_valid,                 // decoded code is valid
output reg [7:0] decode_jis8_code,       // decoded JIS8 code
output reg qr_decode_finish              // 1: decoding one QR code is finished
);

parameter QR_LEN = 25;
parameter IDLE = 4'd0, MEM = 4'd1, ROTATE = 4'd2, DECODE = 4'd3, CAL_S = 4'd4, CAL_COEFF = 4'd5, SOLVE_SIGMA = 4'd6;
parameter SOLVE_I = 4'd7, CAL_COEFF_Y = 4'd8, SOLVE_Y = 4'd9, CAL_OFFSET = 4'd10, CORRECT = 4'd11, SEND_OUTPUT = 4'd12, FINISH = 4'd13;

reg [4-1:0] state, state_n;            // for FSM state
reg [32-1:0] read_cnt, read_cnt_n;
reg [8-1:0] decode_cnt, decode_cnt_n;

reg [6-1:0] img_r, img_c, img_r_next, img_c_next;
reg [QR_LEN-1:0] qr_in [QR_LEN-1:0];
reg [QR_LEN-1:0] qr_in_next [QR_LEN-1:0];

reg [QR_LEN-1:0] qr_demask [QR_LEN-1:0];
reg [8-1:0] codeword_origin [0:44-1];
reg [8-1:0] codeword_origin_next [0:44-1];

reg decode_valid_next;
reg [7:0] decode_jis8_code_next;
reg [7:0] text_length;

wire [8-1:0] pw_origin [0:44-1];
reg [6-1:0] s_cnt, s_cnt_next;
wire [8-1:0] S0_pw, S1_pw, S2_pw, S3_pw;     

reg [8-1:0] S0_num, S1_num, S2_num, S3_num, S4_num, S5_num, S6_num, S7_num;
reg [8-1:0] S0_num_next, S1_num_next, S2_num_next, S3_num_next, S4_num_next, S5_num_next, S6_num_next, S7_num_next;

// temp means the second term of XOR each cycle
reg [8-1:0] S0_temp_pw, S1_temp_pw, S2_temp_pw, S3_temp_pw, S4_temp_pw, S5_temp_pw, S6_temp_pw, S7_temp_pw;

reg [8-1:0] S0_mul_pw, S1_mul_pw, S2_mul_pw, S3_mul_pw, S4_mul_pw, S5_mul_pw, S6_mul_pw, S7_mul_pw;
wire [8-1:0] S0_mul_num, S1_mul_num, S2_mul_num, S3_mul_num, S4_mul_num, S5_mul_num, S6_mul_num, S7_mul_num;

reg [5-1:0] eq_cnt, eq_cnt_next;
reg [5-1:0] solve_sigma_cnt, solve_sigma_cnt_next;

reg [8-1:0] eq1_sigma4_num, eq1_sigma3_num, eq1_sigma2_num, eq1_sigma1_num, eq1_const_num;
reg [8-1:0] eq2_sigma4_num, eq2_sigma3_num, eq2_sigma2_num, eq2_sigma1_num, eq2_const_num;
reg [8-1:0] eq3_sigma4_num, eq3_sigma3_num, eq3_sigma2_num, eq3_sigma1_num, eq3_const_num;
reg [8-1:0] eq4_sigma4_num, eq4_sigma3_num, eq4_sigma2_num, eq4_sigma1_num, eq4_const_num;
reg [8-1:0] eq5_sigma3_num, eq5_sigma2_num, eq5_sigma1_num, eq5_const_num;
reg [8-1:0] eq6_sigma3_num, eq6_sigma2_num, eq6_sigma1_num, eq6_const_num;
reg [8-1:0] eq7_sigma3_num, eq7_sigma2_num, eq7_sigma1_num, eq7_const_num;
reg [8-1:0] eq8_sigma2_num, eq8_sigma1_num, eq8_const_num;
reg [8-1:0] eq9_sigma2_num, eq9_sigma1_num, eq9_const_num;
reg [8-1:0] eq10_sigma1_num, eq10_const_num;

wire [8-1:0] eq1_sigma4_pw, eq1_sigma3_pw, eq1_sigma2_pw, eq1_sigma1_pw, eq1_const_pw;
wire [8-1:0] eq2_sigma4_pw, eq2_sigma3_pw, eq2_sigma2_pw, eq2_sigma1_pw, eq2_const_pw;
wire [8-1:0] eq3_sigma4_pw, eq3_sigma3_pw, eq3_sigma2_pw, eq3_sigma1_pw, eq3_const_pw;
wire [8-1:0] eq4_sigma4_pw, eq4_sigma3_pw, eq4_sigma2_pw, eq4_sigma1_pw, eq4_const_pw;
wire [8-1:0] eq5_sigma3_pw, eq5_sigma2_pw, eq5_sigma1_pw, eq5_const_pw;
wire [8-1:0] eq6_sigma3_pw, eq6_sigma2_pw, eq6_sigma1_pw, eq6_const_pw;
wire [8-1:0] eq7_sigma3_pw, eq7_sigma2_pw, eq7_sigma1_pw, eq7_const_pw;
wire [8-1:0] eq8_sigma2_pw, eq8_sigma1_pw, eq8_const_pw;
wire [8-1:0] eq9_sigma2_pw, eq9_sigma1_pw, eq9_const_pw;
wire [8-1:0] eq10_sigma1_pw, eq10_const_pw;

reg [8-1:0] eq1_sigma4_num_next, eq1_sigma3_num_next, eq1_sigma2_num_next, eq1_sigma1_num_next, eq1_const_num_next;
reg [8-1:0] eq2_sigma4_num_next, eq2_sigma3_num_next, eq2_sigma2_num_next, eq2_sigma1_num_next, eq2_const_num_next;
reg [8-1:0] eq3_sigma4_num_next, eq3_sigma3_num_next, eq3_sigma2_num_next, eq3_sigma1_num_next, eq3_const_num_next;
reg [8-1:0] eq4_sigma4_num_next, eq4_sigma3_num_next, eq4_sigma2_num_next, eq4_sigma1_num_next, eq4_const_num_next;
reg [8-1:0] eq5_sigma3_num_next, eq5_sigma2_num_next, eq5_sigma1_num_next, eq5_const_num_next;
reg [8-1:0] eq6_sigma3_num_next, eq6_sigma2_num_next, eq6_sigma1_num_next, eq6_const_num_next;
reg [8-1:0] eq7_sigma3_num_next, eq7_sigma2_num_next, eq7_sigma1_num_next, eq7_const_num_next;
reg [8-1:0] eq8_sigma2_num_next, eq8_sigma1_num_next, eq8_const_num_next;
reg [8-1:0] eq9_sigma2_num_next, eq9_sigma1_num_next, eq9_const_num_next;
reg [8-1:0] eq10_sigma1_num_next, eq10_const_num_next;

reg [8-1:0] eq5_elim_pw, eq6_elim_pw, eq7_elim_pw, eq8_elim_pw, eq9_elim_pw, eq10_elim_pw;
reg [8-1:0] eq15_elim_pw, eq16_elim_pw, eq17_elim_pw, eq18_elim_pw, eq19_elim_pw, eq20_elim_pw;

reg [8-1:0] sigma1_pw, sigma2_pw, sigma3_pw, sigma4_pw;
reg [8-1:0] sigma1_pw_next, sigma2_pw_next, sigma3_pw_next, sigma4_pw_next;

reg [6-1:0] solve_i_cnt, solve_i_cnt_next;
reg [6-1:0] i_sol1, i_sol2, i_sol3, i_sol4;
reg [6-1:0] i_sol1_next, i_sol2_next, i_sol3_next, i_sol4_next;

reg [5-1:0] y_coeff_cnt, y_coeff_cnt_next;
reg [5-1:0] solve_y_cnt, solve_y_cnt_next;

reg [8-1:0] Y1_pw, Y2_pw, Y3_pw, Y4_pw;
reg [8-1:0] Y1_pw_next, Y2_pw_next, Y3_pw_next, Y4_pw_next;

reg [8-1:0] Y1_offset_pw, Y2_offset_pw, Y3_offset_pw, Y4_offset_pw;
reg [8-1:0] Y1_offset_pw_next, Y2_offset_pw_next, Y3_offset_pw_next, Y4_offset_pw_next;
wire [8-1:0] Y1_offset_num, Y2_offset_num, Y3_offset_num, Y4_offset_num;

reg [8-1:0] send_output_cnt, send_output_cnt_next;

reg qr_decode_finish_next;

reg [8-1:0] codeword_corrected [0:44-1];
reg [8-1:0] codeword_corrected_next [0:44-1];

reg find_qrcode, find_qrcode_next;
reg [6-1:0] first_r, first_c, first_r_next, first_c_next;

reg [6-1:0] UL_sum, UR_sum, LL_sum, LR_sum;

reg [8-1:0] eq5_temp3_pw, eq5_temp2_pw, eq5_temp1_pw, eq5_temp_const_pw;
wire [8-1:0] eq5_temp3_num, eq5_temp2_num, eq5_temp1_num, eq5_temp_const_num;
reg [8-1:0] eq6_temp3_pw, eq6_temp2_pw, eq6_temp1_pw, eq6_temp_const_pw;
wire [8-1:0] eq6_temp3_num, eq6_temp2_num, eq6_temp1_num, eq6_temp_const_num;
reg [8-1:0] eq7_temp3_pw, eq7_temp2_pw, eq7_temp1_pw, eq7_temp_const_pw;
wire [8-1:0] eq7_temp3_num, eq7_temp2_num, eq7_temp1_num, eq7_temp_const_num;
reg [8-1:0] eq8_temp2_pw, eq8_temp1_pw, eq8_temp_const_pw;
wire [8-1:0] eq8_temp2_num, eq8_temp1_num, eq8_temp_const_num;
reg [8-1:0] eq9_temp2_pw, eq9_temp1_pw, eq9_temp_const_pw;
wire [8-1:0] eq9_temp2_num, eq9_temp1_num, eq9_temp_const_num;
reg [8-1:0] eq10_temp1_pw, eq10_temp_const_pw;
wire [8-1:0] eq10_temp1_num, eq10_temp_const_num;

reg [8-1:0] sum1_pw, sum2_pw, sum3_pw, sum4_pw, sum5_pw, sum6_pw;
wire [8-1:0] sum1_num, sum2_num, sum3_num, sum4_num, sum5_num, sum6_num;
reg [8-1:0] right_num;
wire [8-1:0] right_pw;

reg [8-1:0] sigma_func0_pw, sigma_func1_pw, sigma_func2_pw, sigma_func3_pw, sigma_func4_pw;
wire [8-1:0] sigma_func0_num, sigma_func1_num, sigma_func2_num, sigma_func3_num, sigma_func4_num;
reg [8-1:0] sigma_func_value;


wire [8-1:0] eq11_Y2_num_w, eq11_Y3_num_w, eq11_Y4_num_w, eq11_const_num_w;
wire [8-1:0] eq12_Y2_num_w, eq12_Y3_num_w, eq12_Y4_num_w, eq12_const_num_w;
wire [8-1:0] eq13_Y2_num_w, eq13_Y3_num_w, eq13_Y4_num_w, eq13_const_num_w;
wire [8-1:0] eq14_Y2_num_w, eq14_Y3_num_w, eq14_Y4_num_w, eq14_const_num_w;

reg [8-1:0] eq11_Y2_num, eq11_Y3_num, eq11_Y4_num, eq11_const_num;
reg [8-1:0] eq12_Y2_num, eq12_Y3_num, eq12_Y4_num, eq12_const_num;
reg [8-1:0] eq13_Y2_num, eq13_Y3_num, eq13_Y4_num, eq13_const_num;
reg [8-1:0] eq14_Y2_num, eq14_Y3_num, eq14_Y4_num, eq14_const_num;
reg [8-1:0] eq15_Y2_num, eq15_Y3_num, eq15_Y4_num, eq15_const_num;
reg [8-1:0] eq16_Y2_num, eq16_Y3_num, eq16_Y4_num, eq16_const_num;
reg [8-1:0] eq17_Y2_num, eq17_Y3_num, eq17_Y4_num, eq17_const_num;
reg [8-1:0] eq18_Y3_num, eq18_Y4_num, eq18_const_num;
reg [8-1:0] eq19_Y3_num, eq19_Y4_num, eq19_const_num;
reg [8-1:0] eq20_Y4_num, eq20_const_num;

reg [8-1:0] eq11_Y1_pw, eq11_Y2_pw, eq11_Y3_pw, eq11_Y4_pw, eq11_const_pw;
reg [8-1:0] eq12_Y1_pw, eq12_Y2_pw, eq12_Y3_pw, eq12_Y4_pw, eq12_const_pw;
reg [8-1:0] eq13_Y1_pw, eq13_Y2_pw, eq13_Y3_pw, eq13_Y4_pw, eq13_const_pw;
reg [8-1:0] eq14_Y1_pw, eq14_Y2_pw, eq14_Y3_pw, eq14_Y4_pw, eq14_const_pw;
wire [8-1:0] eq15_Y2_pw, eq15_Y3_pw, eq15_Y4_pw, eq15_const_pw;
wire [8-1:0] eq16_Y2_pw, eq16_Y3_pw, eq16_Y4_pw, eq16_const_pw;
wire [8-1:0] eq17_Y2_pw, eq17_Y3_pw, eq17_Y4_pw, eq17_const_pw;
wire [8-1:0] eq18_Y3_pw, eq18_Y4_pw, eq18_const_pw;
wire [8-1:0] eq19_Y3_pw, eq19_Y4_pw, eq19_const_pw;
wire [8-1:0] eq20_Y4_pw;

reg [8-1:0] eq11_Y1_num_next, eq11_Y2_num_next, eq11_Y3_num_next, eq11_Y4_num_next, eq11_const_num_next;
reg [8-1:0] eq12_Y1_num_next, eq12_Y2_num_next, eq12_Y3_num_next, eq12_Y4_num_next, eq12_const_num_next;
reg [8-1:0] eq13_Y1_num_next, eq13_Y2_num_next, eq13_Y3_num_next, eq13_Y4_num_next, eq13_const_num_next;
reg [8-1:0] eq14_Y1_num_next, eq14_Y2_num_next, eq14_Y3_num_next, eq14_Y4_num_next, eq14_const_num_next;
reg [8-1:0] eq15_Y2_num_next, eq15_Y3_num_next, eq15_Y4_num_next, eq15_const_num_next;
reg [8-1:0] eq16_Y2_num_next, eq16_Y3_num_next, eq16_Y4_num_next, eq16_const_num_next;
reg [8-1:0] eq17_Y2_num_next, eq17_Y3_num_next, eq17_Y4_num_next, eq17_const_num_next;
reg [8-1:0] eq18_Y3_num_next, eq18_Y4_num_next, eq18_const_num_next;
reg [8-1:0] eq19_Y3_num_next, eq19_Y4_num_next, eq19_const_num_next;
reg [8-1:0] eq20_Y4_num_next, eq20_const_num_next;


reg [8-1:0] eq15_tempY2_pw, eq15_tempY3_pw, eq15_tempY4_pw, eq15_temp_const_pw;
wire [8-1:0] eq15_tempY2_num, eq15_tempY3_num, eq15_tempY4_num, eq15_temp_const_num;
reg [8-1:0] eq16_tempY2_pw, eq16_tempY3_pw, eq16_tempY4_pw, eq16_temp_const_pw;
wire [8-1:0] eq16_tempY2_num, eq16_tempY3_num, eq16_tempY4_num, eq16_temp_const_num;
reg [8-1:0] eq17_tempY2_pw, eq17_tempY3_pw, eq17_tempY4_pw, eq17_temp_const_pw;
wire [8-1:0] eq17_tempY2_num, eq17_tempY3_num, eq17_tempY4_num, eq17_temp_const_num;
reg [8-1:0] eq18_tempY3_pw, eq18_tempY4_pw, eq18_temp_const_pw;
wire [8-1:0]  eq18_tempY3_num, eq18_tempY4_num, eq18_temp_const_num;
reg [8-1:0] eq19_tempY3_pw, eq19_tempY4_pw, eq19_temp_const_pw;
wire [8-1:0]  eq19_tempY3_num, eq19_tempY4_num, eq19_temp_const_num;
reg [8-1:0] eq20_tempY4_pw, eq20_temp_const_pw;
wire [8-1:0] eq20_tempY4_num, eq20_temp_const_num;

reg [8-1:0] sum1_Y_pw, sum2_Y_pw, sum3_Y_pw, sum4_Y_pw, sum5_Y_pw, sum6_Y_pw;
wire [8-1:0] sum1_Y_num, sum2_Y_num, sum3_Y_num, sum4_Y_num, sum5_Y_num, sum6_Y_num;
reg [8-1:0] right_Y_num;
wire [8-1:0] right_Y_pw;

integer i, j;

// set all the tables I need
num2pw U0 (.num(codeword_origin[0]), .pw(pw_origin[0]));
num2pw U1 (.num(codeword_origin[1]), .pw(pw_origin[1]));
num2pw U2 (.num(codeword_origin[2]), .pw(pw_origin[2]));
num2pw U3 (.num(codeword_origin[3]), .pw(pw_origin[3]));
num2pw U4 (.num(codeword_origin[4]), .pw(pw_origin[4]));
num2pw U5 (.num(codeword_origin[5]), .pw(pw_origin[5]));
num2pw U6 (.num(codeword_origin[6]), .pw(pw_origin[6]));
num2pw U7 (.num(codeword_origin[7]), .pw(pw_origin[7]));
num2pw U8 (.num(codeword_origin[8]), .pw(pw_origin[8]));
num2pw U9 (.num(codeword_origin[9]), .pw(pw_origin[9]));
num2pw U10 (.num(codeword_origin[10]), .pw(pw_origin[10]));
num2pw U11 (.num(codeword_origin[11]), .pw(pw_origin[11]));
num2pw U12 (.num(codeword_origin[12]), .pw(pw_origin[12]));
num2pw U13 (.num(codeword_origin[13]), .pw(pw_origin[13]));
num2pw U14 (.num(codeword_origin[14]), .pw(pw_origin[14]));
num2pw U15 (.num(codeword_origin[15]), .pw(pw_origin[15]));
num2pw U16 (.num(codeword_origin[16]), .pw(pw_origin[16]));
num2pw U17 (.num(codeword_origin[17]), .pw(pw_origin[17]));
num2pw U18 (.num(codeword_origin[18]), .pw(pw_origin[18]));
num2pw U19 (.num(codeword_origin[19]), .pw(pw_origin[19]));
num2pw U20 (.num(codeword_origin[20]), .pw(pw_origin[20]));
num2pw U21 (.num(codeword_origin[21]), .pw(pw_origin[21]));
num2pw U22 (.num(codeword_origin[22]), .pw(pw_origin[22]));
num2pw U23 (.num(codeword_origin[23]), .pw(pw_origin[23]));
num2pw U24 (.num(codeword_origin[24]), .pw(pw_origin[24]));
num2pw U25 (.num(codeword_origin[25]), .pw(pw_origin[25]));
num2pw U26 (.num(codeword_origin[26]), .pw(pw_origin[26]));
num2pw U27 (.num(codeword_origin[27]), .pw(pw_origin[27]));
num2pw U28 (.num(codeword_origin[28]), .pw(pw_origin[28]));
num2pw U29 (.num(codeword_origin[29]), .pw(pw_origin[29]));
num2pw U30 (.num(codeword_origin[30]), .pw(pw_origin[30]));
num2pw U31 (.num(codeword_origin[31]), .pw(pw_origin[31]));
num2pw U32 (.num(codeword_origin[32]), .pw(pw_origin[32]));
num2pw U33 (.num(codeword_origin[33]), .pw(pw_origin[33]));
num2pw U34 (.num(codeword_origin[34]), .pw(pw_origin[34]));
num2pw U35 (.num(codeword_origin[35]), .pw(pw_origin[35]));
num2pw U36 (.num(codeword_origin[36]), .pw(pw_origin[36]));
num2pw U37 (.num(codeword_origin[37]), .pw(pw_origin[37]));
num2pw U38 (.num(codeword_origin[38]), .pw(pw_origin[38]));
num2pw U39 (.num(codeword_origin[39]), .pw(pw_origin[39]));
num2pw U40 (.num(codeword_origin[40]), .pw(pw_origin[40]));
num2pw U41 (.num(codeword_origin[41]), .pw(pw_origin[41]));
num2pw U42 (.num(codeword_origin[42]), .pw(pw_origin[42]));
num2pw U43 (.num(codeword_origin[43]), .pw(pw_origin[43]));
pw2num U52 (.pw(S0_mul_pw), .num(S0_mul_num));
pw2num U53 (.pw(S1_mul_pw), .num(S1_mul_num));
pw2num U54 (.pw(S2_mul_pw), .num(S2_mul_num));
pw2num U55 (.pw(S3_mul_pw), .num(S3_mul_num));
pw2num U56 (.pw(S4_mul_pw), .num(S4_mul_num));
pw2num U57 (.pw(S5_mul_pw), .num(S5_mul_num));
pw2num U58 (.pw(S6_mul_pw), .num(S6_mul_num));
pw2num U59 (.pw(S7_mul_pw), .num(S7_mul_num));
num2pw U60 (.num(S0_num), .pw(S0_pw));
num2pw U61 (.num(S1_num), .pw(S1_pw));
num2pw U62 (.num(S2_num), .pw(S2_pw));
num2pw U63 (.num(S3_num), .pw(S3_pw));

num2pw U68(.num(eq1_sigma4_num), .pw(eq1_sigma4_pw));
num2pw U69(.num(eq1_sigma3_num), .pw(eq1_sigma3_pw));
num2pw U70(.num(eq1_sigma2_num), .pw(eq1_sigma2_pw));
num2pw U71(.num(eq1_sigma1_num), .pw(eq1_sigma1_pw));
num2pw U72(.num(eq1_const_num), .pw(eq1_const_pw));
num2pw U73(.num(eq2_sigma4_num), .pw(eq2_sigma4_pw));
num2pw U74(.num(eq2_sigma3_num), .pw(eq2_sigma3_pw));
num2pw U75(.num(eq2_sigma2_num), .pw(eq2_sigma2_pw));
num2pw U76(.num(eq2_sigma1_num), .pw(eq2_sigma1_pw));
num2pw U77(.num(eq2_const_num), .pw(eq2_const_pw));
num2pw U78(.num(eq3_sigma4_num), .pw(eq3_sigma4_pw));
num2pw U79(.num(eq3_sigma3_num), .pw(eq3_sigma3_pw));
num2pw U80(.num(eq3_sigma2_num), .pw(eq3_sigma2_pw));
num2pw U81(.num(eq3_sigma1_num), .pw(eq3_sigma1_pw));
num2pw U82(.num(eq3_const_num), .pw(eq3_const_pw));
num2pw U83(.num(eq4_sigma4_num), .pw(eq4_sigma4_pw));
num2pw U84(.num(eq4_sigma3_num), .pw(eq4_sigma3_pw));
num2pw U85(.num(eq4_sigma2_num), .pw(eq4_sigma2_pw));
num2pw U86(.num(eq4_sigma1_num), .pw(eq4_sigma1_pw));
num2pw U87(.num(eq4_const_num), .pw(eq4_const_pw));
num2pw U88(.num(eq5_sigma3_num), .pw(eq5_sigma3_pw));
num2pw U89(.num(eq5_sigma2_num), .pw(eq5_sigma2_pw));
num2pw U90(.num(eq5_sigma1_num), .pw(eq5_sigma1_pw));
num2pw U91(.num(eq5_const_num), .pw(eq5_const_pw));
num2pw U92(.num(eq6_sigma3_num), .pw(eq6_sigma3_pw));
num2pw U93(.num(eq6_sigma2_num), .pw(eq6_sigma2_pw));
num2pw U94(.num(eq6_sigma1_num), .pw(eq6_sigma1_pw));
num2pw U95(.num(eq6_const_num), .pw(eq6_const_pw));
num2pw U96(.num(eq7_sigma3_num), .pw(eq7_sigma3_pw));
num2pw U97(.num(eq7_sigma2_num), .pw(eq7_sigma2_pw));
num2pw U98(.num(eq7_sigma1_num), .pw(eq7_sigma1_pw));
num2pw U99(.num(eq7_const_num), .pw(eq7_const_pw));
num2pw U100(.num(eq8_sigma2_num), .pw(eq8_sigma2_pw));
num2pw U101(.num(eq8_sigma1_num), .pw(eq8_sigma1_pw));
num2pw U102(.num(eq8_const_num), .pw(eq8_const_pw));
num2pw U103(.num(eq9_sigma2_num), .pw(eq9_sigma2_pw));
num2pw U104(.num(eq9_sigma1_num), .pw(eq9_sigma1_pw));
num2pw U105(.num(eq9_const_num), .pw(eq9_const_pw));
num2pw U104c(.num(eq10_sigma1_num), .pw(eq10_sigma1_pw));

pw2num U106(.pw(eq5_temp3_pw), .num(eq5_temp3_num));
pw2num U107(.pw(eq5_temp2_pw), .num(eq5_temp2_num));
pw2num U108(.pw(eq5_temp1_pw), .num(eq5_temp1_num));
pw2num U109(.pw(eq5_temp_const_pw), .num(eq5_temp_const_num));
pw2num U110(.pw(eq6_temp3_pw), .num(eq6_temp3_num));
pw2num U111(.pw(eq6_temp2_pw), .num(eq6_temp2_num));
pw2num U112(.pw(eq6_temp1_pw), .num(eq6_temp1_num));
pw2num U113(.pw(eq6_temp_const_pw), .num(eq6_temp_const_num));

pw2num U114(.pw(eq7_temp3_pw), .num(eq7_temp3_num));
pw2num U115(.pw(eq7_temp2_pw), .num(eq7_temp2_num));
pw2num U116(.pw(eq7_temp1_pw), .num(eq7_temp1_num));
pw2num U117(.pw(eq7_temp_const_pw), .num(eq7_temp_const_num));
pw2num U118(.pw(eq8_temp2_pw), .num(eq8_temp2_num));
pw2num U119(.pw(eq8_temp1_pw), .num(eq8_temp1_num));
pw2num U120(.pw(eq8_temp_const_pw), .num(eq8_temp_const_num));
pw2num U121(.pw(eq9_temp2_pw), .num(eq9_temp2_num));
pw2num U122(.pw(eq9_temp1_pw), .num(eq9_temp1_num));
pw2num U123(.pw(eq9_temp_const_pw), .num(eq9_temp_const_num));
pw2num U124(.pw(eq10_temp1_pw), .num(eq10_temp1_num));
pw2num U125(.pw(eq10_temp_const_pw), .num(eq10_temp_const_num));
pw2num U126(.pw(sum1_pw), .num(sum1_num));
pw2num U127(.pw(sum2_pw), .num(sum2_num));
pw2num U128(.pw(sum3_pw), .num(sum3_num));
pw2num U129(.pw(sum4_pw), .num(sum4_num));
pw2num U130(.pw(sum5_pw), .num(sum5_num));
pw2num U131(.pw(sum6_pw), .num(sum6_num));
num2pw U132(.num(right_num), .pw(right_pw));
pw2num U133(.pw(sigma_func0_pw), .num(sigma_func0_num));
pw2num U134(.pw(sigma_func1_pw), .num(sigma_func1_num));
pw2num U135(.pw(sigma_func2_pw), .num(sigma_func2_num));
pw2num U136(.pw(sigma_func3_pw), .num(sigma_func3_num));
pw2num U137(.pw(sigma_func4_pw), .num(sigma_func4_num));

num2pw U158(.num(eq15_Y2_num), .pw(eq15_Y2_pw));
num2pw U159(.num(eq15_Y3_num), .pw(eq15_Y3_pw));
num2pw U160(.num(eq15_Y4_num), .pw(eq15_Y4_pw));
num2pw U161(.num(eq15_const_num), .pw(eq15_const_pw));
num2pw U162(.num(eq16_Y2_num), .pw(eq16_Y2_pw));
num2pw U163(.num(eq16_Y3_num), .pw(eq16_Y3_pw));
num2pw U164(.num(eq16_Y4_num), .pw(eq16_Y4_pw));
num2pw U165(.num(eq16_const_num), .pw(eq16_const_pw));
num2pw U166(.num(eq17_Y2_num), .pw(eq17_Y2_pw));
num2pw U167(.num(eq17_Y3_num), .pw(eq17_Y3_pw));
num2pw U168(.num(eq17_Y4_num), .pw(eq17_Y4_pw));
num2pw U169(.num(eq17_const_num), .pw(eq17_const_pw));
num2pw U170(.num(eq18_Y3_num), .pw(eq18_Y3_pw));
num2pw U171(.num(eq18_Y4_num), .pw(eq18_Y4_pw));
num2pw U172(.num(eq18_const_num), .pw(eq18_const_pw));
num2pw U173(.num(eq19_Y3_num), .pw(eq19_Y3_pw));
num2pw U174(.num(eq19_Y4_num), .pw(eq19_Y4_pw));
num2pw U175(.num(eq19_const_num), .pw(eq19_const_pw));
num2pw U176(.num(eq20_Y4_num), .pw(eq20_Y4_pw));

pw2num U179(.pw(eq11_Y2_pw), .num(eq11_Y2_num_w));
pw2num U180(.pw(eq11_Y3_pw), .num(eq11_Y3_num_w));
pw2num U181(.pw(eq11_Y4_pw), .num(eq11_Y4_num_w));
pw2num U182(.pw(eq11_const_pw), .num(eq11_const_num_w));
pw2num U184(.pw(eq12_Y2_pw), .num(eq12_Y2_num_w));
pw2num U185(.pw(eq12_Y3_pw), .num(eq12_Y3_num_w));
pw2num U186(.pw(eq12_Y4_pw), .num(eq12_Y4_num_w));
pw2num U187(.pw(eq12_const_pw), .num(eq12_const_num_w));
pw2num U189(.pw(eq13_Y2_pw), .num(eq13_Y2_num_w));
pw2num U190(.pw(eq13_Y3_pw), .num(eq13_Y3_num_w));
pw2num U191(.pw(eq13_Y4_pw), .num(eq13_Y4_num_w));
pw2num U192(.pw(eq13_const_pw), .num(eq13_const_num_w));
pw2num U194(.pw(eq14_Y2_pw), .num(eq14_Y2_num_w));
pw2num U195(.pw(eq14_Y3_pw), .num(eq14_Y3_num_w));
pw2num U196(.pw(eq14_Y4_pw), .num(eq14_Y4_num_w));
pw2num U197(.pw(eq14_const_pw), .num(eq14_const_num_w));
pw2num U198(.pw(eq15_tempY2_pw), .num(eq15_tempY2_num));
pw2num U199(.pw(eq15_tempY3_pw), .num(eq15_tempY3_num));
pw2num U200(.pw(eq15_tempY4_pw), .num(eq15_tempY4_num));
pw2num U201(.pw(eq15_temp_const_pw), .num(eq15_temp_const_num));
pw2num U202(.pw(eq16_tempY2_pw), .num(eq16_tempY2_num));
pw2num U203(.pw(eq16_tempY3_pw), .num(eq16_tempY3_num));
pw2num U204(.pw(eq16_tempY4_pw), .num(eq16_tempY4_num));
pw2num U205(.pw(eq16_temp_const_pw), .num(eq16_temp_const_num));
pw2num U206(.pw(eq17_tempY2_pw), .num(eq17_tempY2_num));
pw2num U207(.pw(eq17_tempY3_pw), .num(eq17_tempY3_num));
pw2num U208(.pw(eq17_tempY4_pw), .num(eq17_tempY4_num));
pw2num U209(.pw(eq17_temp_const_pw), .num(eq17_temp_const_num));
pw2num U210(.pw(eq18_tempY3_pw), .num(eq18_tempY3_num));
pw2num U211(.pw(eq18_tempY4_pw), .num(eq18_tempY4_num));
pw2num U212(.pw(eq18_temp_const_pw), .num(eq18_temp_const_num));
pw2num U213(.pw(eq19_tempY3_pw), .num(eq19_tempY3_num));
pw2num U214(.pw(eq19_tempY4_pw), .num(eq19_tempY4_num));
pw2num U215(.pw(eq19_temp_const_pw), .num(eq19_temp_const_num));
pw2num U216(.pw(eq20_tempY4_pw), .num(eq20_tempY4_num));
pw2num U217(.pw(eq20_temp_const_pw), .num(eq20_temp_const_num));
pw2num U218(.pw(sum1_Y_pw), .num(sum1_Y_num));
pw2num U219(.pw(sum2_Y_pw), .num(sum2_Y_num));
pw2num U220(.pw(sum3_Y_pw), .num(sum3_Y_num));
pw2num U221(.pw(sum4_Y_pw), .num(sum4_Y_num));
pw2num U222(.pw(sum5_Y_pw), .num(sum5_Y_num));
pw2num U223(.pw(sum6_Y_pw), .num(sum6_Y_num));
num2pw U224(.num(right_Y_num), .pw(right_Y_pw));
pw2num U225(.pw(Y1_offset_pw), .num(Y1_offset_num));
pw2num U226(.pw(Y2_offset_pw), .num(Y2_offset_num));
pw2num U227(.pw(Y3_offset_pw), .num(Y3_offset_num));
pw2num U228(.pw(Y4_offset_pw), .num(Y4_offset_num));

// store the data from sram
always @* begin
    if (state == MEM) begin
        for (i = 0; i < 25; i = i + 1) begin
            for (j = 0; j < 25; j = j + 1) begin
                if (i == 0 && j == 0)
                    qr_in_next[i][j] = 1;
                else if (i == img_r - first_r && j == img_c - first_c) 
                    qr_in_next[i][j] = sram_rdata;
                else
                    qr_in_next[i][j] = qr_in[i][j];
            end
        end
    end
    else if (state == ROTATE && UL_sum + LL_sum + LR_sum == 27) begin
        // rotate right 90 deg
        qr_in_next[0] = {qr_in[0][0], qr_in[1][0], qr_in[2][0], qr_in[3][0], qr_in[4][0], qr_in[5][0], qr_in[6][0], qr_in[7][0], qr_in[8][0], qr_in[9][0], qr_in[10][0], qr_in[11][0], qr_in[12][0], qr_in[13][0], qr_in[14][0], qr_in[15][0], qr_in[16][0], qr_in[17][0], qr_in[18][0], qr_in[19][0], qr_in[20][0], qr_in[21][0], qr_in[22][0], qr_in[23][0], qr_in[24][0]};
        qr_in_next[1] = {qr_in[0][1], qr_in[1][1], qr_in[2][1], qr_in[3][1], qr_in[4][1], qr_in[5][1], qr_in[6][1], qr_in[7][1], qr_in[8][1], qr_in[9][1], qr_in[10][1], qr_in[11][1], qr_in[12][1], qr_in[13][1], qr_in[14][1], qr_in[15][1], qr_in[16][1], qr_in[17][1], qr_in[18][1], qr_in[19][1], qr_in[20][1], qr_in[21][1], qr_in[22][1], qr_in[23][1], qr_in[24][1]};
        qr_in_next[2] = {qr_in[0][2], qr_in[1][2], qr_in[2][2], qr_in[3][2], qr_in[4][2], qr_in[5][2], qr_in[6][2], qr_in[7][2], qr_in[8][2], qr_in[9][2], qr_in[10][2], qr_in[11][2], qr_in[12][2], qr_in[13][2], qr_in[14][2], qr_in[15][2], qr_in[16][2], qr_in[17][2], qr_in[18][2], qr_in[19][2], qr_in[20][2], qr_in[21][2], qr_in[22][2], qr_in[23][2], qr_in[24][2]};
        qr_in_next[3] = {qr_in[0][3], qr_in[1][3], qr_in[2][3], qr_in[3][3], qr_in[4][3], qr_in[5][3], qr_in[6][3], qr_in[7][3], qr_in[8][3], qr_in[9][3], qr_in[10][3], qr_in[11][3], qr_in[12][3], qr_in[13][3], qr_in[14][3], qr_in[15][3], qr_in[16][3], qr_in[17][3], qr_in[18][3], qr_in[19][3], qr_in[20][3], qr_in[21][3], qr_in[22][3], qr_in[23][3], qr_in[24][3]};
        qr_in_next[4] = {qr_in[0][4], qr_in[1][4], qr_in[2][4], qr_in[3][4], qr_in[4][4], qr_in[5][4], qr_in[6][4], qr_in[7][4], qr_in[8][4], qr_in[9][4], qr_in[10][4], qr_in[11][4], qr_in[12][4], qr_in[13][4], qr_in[14][4], qr_in[15][4], qr_in[16][4], qr_in[17][4], qr_in[18][4], qr_in[19][4], qr_in[20][4], qr_in[21][4], qr_in[22][4], qr_in[23][4], qr_in[24][4]};
        qr_in_next[5] = {qr_in[0][5], qr_in[1][5], qr_in[2][5], qr_in[3][5], qr_in[4][5], qr_in[5][5], qr_in[6][5], qr_in[7][5], qr_in[8][5], qr_in[9][5], qr_in[10][5], qr_in[11][5], qr_in[12][5], qr_in[13][5], qr_in[14][5], qr_in[15][5], qr_in[16][5], qr_in[17][5], qr_in[18][5], qr_in[19][5], qr_in[20][5], qr_in[21][5], qr_in[22][5], qr_in[23][5], qr_in[24][5]};
        qr_in_next[6] = {qr_in[0][6], qr_in[1][6], qr_in[2][6], qr_in[3][6], qr_in[4][6], qr_in[5][6], qr_in[6][6], qr_in[7][6], qr_in[8][6], qr_in[9][6], qr_in[10][6], qr_in[11][6], qr_in[12][6], qr_in[13][6], qr_in[14][6], qr_in[15][6], qr_in[16][6], qr_in[17][6], qr_in[18][6], qr_in[19][6], qr_in[20][6], qr_in[21][6], qr_in[22][6], qr_in[23][6], qr_in[24][6]};
        qr_in_next[7] = {qr_in[0][7], qr_in[1][7], qr_in[2][7], qr_in[3][7], qr_in[4][7], qr_in[5][7], qr_in[6][7], qr_in[7][7], qr_in[8][7], qr_in[9][7], qr_in[10][7], qr_in[11][7], qr_in[12][7], qr_in[13][7], qr_in[14][7], qr_in[15][7], qr_in[16][7], qr_in[17][7], qr_in[18][7], qr_in[19][7], qr_in[20][7], qr_in[21][7], qr_in[22][7], qr_in[23][7], qr_in[24][7]};
        qr_in_next[8] = {qr_in[0][8], qr_in[1][8], qr_in[2][8], qr_in[3][8], qr_in[4][8], qr_in[5][8], qr_in[6][8], qr_in[7][8], qr_in[8][8], qr_in[9][8], qr_in[10][8], qr_in[11][8], qr_in[12][8], qr_in[13][8], qr_in[14][8], qr_in[15][8], qr_in[16][8], qr_in[17][8], qr_in[18][8], qr_in[19][8], qr_in[20][8], qr_in[21][8], qr_in[22][8], qr_in[23][8], qr_in[24][8]};
        qr_in_next[9] = {qr_in[0][9], qr_in[1][9], qr_in[2][9], qr_in[3][9], qr_in[4][9], qr_in[5][9], qr_in[6][9], qr_in[7][9], qr_in[8][9], qr_in[9][9], qr_in[10][9], qr_in[11][9], qr_in[12][9], qr_in[13][9], qr_in[14][9], qr_in[15][9], qr_in[16][9], qr_in[17][9], qr_in[18][9], qr_in[19][9], qr_in[20][9], qr_in[21][9], qr_in[22][9], qr_in[23][9], qr_in[24][9]};
        qr_in_next[10] = {qr_in[0][10], qr_in[1][10], qr_in[2][10], qr_in[3][10], qr_in[4][10], qr_in[5][10], qr_in[6][10], qr_in[7][10], qr_in[8][10], qr_in[9][10], qr_in[10][10], qr_in[11][10], qr_in[12][10], qr_in[13][10], qr_in[14][10], qr_in[15][10], qr_in[16][10], qr_in[17][10], qr_in[18][10], qr_in[19][10], qr_in[20][10], qr_in[21][10], qr_in[22][10], qr_in[23][10], qr_in[24][10]};
        qr_in_next[11] = {qr_in[0][11], qr_in[1][11], qr_in[2][11], qr_in[3][11], qr_in[4][11], qr_in[5][11], qr_in[6][11], qr_in[7][11], qr_in[8][11], qr_in[9][11], qr_in[10][11], qr_in[11][11], qr_in[12][11], qr_in[13][11], qr_in[14][11], qr_in[15][11], qr_in[16][11], qr_in[17][11], qr_in[18][11], qr_in[19][11], qr_in[20][11], qr_in[21][11], qr_in[22][11], qr_in[23][11], qr_in[24][11]};
        qr_in_next[12] = {qr_in[0][12], qr_in[1][12], qr_in[2][12], qr_in[3][12], qr_in[4][12], qr_in[5][12], qr_in[6][12], qr_in[7][12], qr_in[8][12], qr_in[9][12], qr_in[10][12], qr_in[11][12], qr_in[12][12], qr_in[13][12], qr_in[14][12], qr_in[15][12], qr_in[16][12], qr_in[17][12], qr_in[18][12], qr_in[19][12], qr_in[20][12], qr_in[21][12], qr_in[22][12], qr_in[23][12], qr_in[24][12]};
        qr_in_next[13] = {qr_in[0][13], qr_in[1][13], qr_in[2][13], qr_in[3][13], qr_in[4][13], qr_in[5][13], qr_in[6][13], qr_in[7][13], qr_in[8][13], qr_in[9][13], qr_in[10][13], qr_in[11][13], qr_in[12][13], qr_in[13][13], qr_in[14][13], qr_in[15][13], qr_in[16][13], qr_in[17][13], qr_in[18][13], qr_in[19][13], qr_in[20][13], qr_in[21][13], qr_in[22][13], qr_in[23][13], qr_in[24][13]};
        qr_in_next[14] = {qr_in[0][14], qr_in[1][14], qr_in[2][14], qr_in[3][14], qr_in[4][14], qr_in[5][14], qr_in[6][14], qr_in[7][14], qr_in[8][14], qr_in[9][14], qr_in[10][14], qr_in[11][14], qr_in[12][14], qr_in[13][14], qr_in[14][14], qr_in[15][14], qr_in[16][14], qr_in[17][14], qr_in[18][14], qr_in[19][14], qr_in[20][14], qr_in[21][14], qr_in[22][14], qr_in[23][14], qr_in[24][14]};
        qr_in_next[15] = {qr_in[0][15], qr_in[1][15], qr_in[2][15], qr_in[3][15], qr_in[4][15], qr_in[5][15], qr_in[6][15], qr_in[7][15], qr_in[8][15], qr_in[9][15], qr_in[10][15], qr_in[11][15], qr_in[12][15], qr_in[13][15], qr_in[14][15], qr_in[15][15], qr_in[16][15], qr_in[17][15], qr_in[18][15], qr_in[19][15], qr_in[20][15], qr_in[21][15], qr_in[22][15], qr_in[23][15], qr_in[24][15]};
        qr_in_next[16] = {qr_in[0][16], qr_in[1][16], qr_in[2][16], qr_in[3][16], qr_in[4][16], qr_in[5][16], qr_in[6][16], qr_in[7][16], qr_in[8][16], qr_in[9][16], qr_in[10][16], qr_in[11][16], qr_in[12][16], qr_in[13][16], qr_in[14][16], qr_in[15][16], qr_in[16][16], qr_in[17][16], qr_in[18][16], qr_in[19][16], qr_in[20][16], qr_in[21][16], qr_in[22][16], qr_in[23][16], qr_in[24][16]};
        qr_in_next[17] = {qr_in[0][17], qr_in[1][17], qr_in[2][17], qr_in[3][17], qr_in[4][17], qr_in[5][17], qr_in[6][17], qr_in[7][17], qr_in[8][17], qr_in[9][17], qr_in[10][17], qr_in[11][17], qr_in[12][17], qr_in[13][17], qr_in[14][17], qr_in[15][17], qr_in[16][17], qr_in[17][17], qr_in[18][17], qr_in[19][17], qr_in[20][17], qr_in[21][17], qr_in[22][17], qr_in[23][17], qr_in[24][17]};
        qr_in_next[18] = {qr_in[0][18], qr_in[1][18], qr_in[2][18], qr_in[3][18], qr_in[4][18], qr_in[5][18], qr_in[6][18], qr_in[7][18], qr_in[8][18], qr_in[9][18], qr_in[10][18], qr_in[11][18], qr_in[12][18], qr_in[13][18], qr_in[14][18], qr_in[15][18], qr_in[16][18], qr_in[17][18], qr_in[18][18], qr_in[19][18], qr_in[20][18], qr_in[21][18], qr_in[22][18], qr_in[23][18], qr_in[24][18]};
        qr_in_next[19] = {qr_in[0][19], qr_in[1][19], qr_in[2][19], qr_in[3][19], qr_in[4][19], qr_in[5][19], qr_in[6][19], qr_in[7][19], qr_in[8][19], qr_in[9][19], qr_in[10][19], qr_in[11][19], qr_in[12][19], qr_in[13][19], qr_in[14][19], qr_in[15][19], qr_in[16][19], qr_in[17][19], qr_in[18][19], qr_in[19][19], qr_in[20][19], qr_in[21][19], qr_in[22][19], qr_in[23][19], qr_in[24][19]};
        qr_in_next[20] = {qr_in[0][20], qr_in[1][20], qr_in[2][20], qr_in[3][20], qr_in[4][20], qr_in[5][20], qr_in[6][20], qr_in[7][20], qr_in[8][20], qr_in[9][20], qr_in[10][20], qr_in[11][20], qr_in[12][20], qr_in[13][20], qr_in[14][20], qr_in[15][20], qr_in[16][20], qr_in[17][20], qr_in[18][20], qr_in[19][20], qr_in[20][20], qr_in[21][20], qr_in[22][20], qr_in[23][20], qr_in[24][20]};
        qr_in_next[21] = {qr_in[0][21], qr_in[1][21], qr_in[2][21], qr_in[3][21], qr_in[4][21], qr_in[5][21], qr_in[6][21], qr_in[7][21], qr_in[8][21], qr_in[9][21], qr_in[10][21], qr_in[11][21], qr_in[12][21], qr_in[13][21], qr_in[14][21], qr_in[15][21], qr_in[16][21], qr_in[17][21], qr_in[18][21], qr_in[19][21], qr_in[20][21], qr_in[21][21], qr_in[22][21], qr_in[23][21], qr_in[24][21]};
        qr_in_next[22] = {qr_in[0][22], qr_in[1][22], qr_in[2][22], qr_in[3][22], qr_in[4][22], qr_in[5][22], qr_in[6][22], qr_in[7][22], qr_in[8][22], qr_in[9][22], qr_in[10][22], qr_in[11][22], qr_in[12][22], qr_in[13][22], qr_in[14][22], qr_in[15][22], qr_in[16][22], qr_in[17][22], qr_in[18][22], qr_in[19][22], qr_in[20][22], qr_in[21][22], qr_in[22][22], qr_in[23][22], qr_in[24][22]};
        qr_in_next[23] = {qr_in[0][23], qr_in[1][23], qr_in[2][23], qr_in[3][23], qr_in[4][23], qr_in[5][23], qr_in[6][23], qr_in[7][23], qr_in[8][23], qr_in[9][23], qr_in[10][23], qr_in[11][23], qr_in[12][23], qr_in[13][23], qr_in[14][23], qr_in[15][23], qr_in[16][23], qr_in[17][23], qr_in[18][23], qr_in[19][23], qr_in[20][23], qr_in[21][23], qr_in[22][23], qr_in[23][23], qr_in[24][23]};
        qr_in_next[24] = {qr_in[0][24], qr_in[1][24], qr_in[2][24], qr_in[3][24], qr_in[4][24], qr_in[5][24], qr_in[6][24], qr_in[7][24], qr_in[8][24], qr_in[9][24], qr_in[10][24], qr_in[11][24], qr_in[12][24], qr_in[13][24], qr_in[14][24], qr_in[15][24], qr_in[16][24], qr_in[17][24], qr_in[18][24], qr_in[19][24], qr_in[20][24], qr_in[21][24], qr_in[22][24], qr_in[23][24], qr_in[24][24]};
    end
    else if (state == ROTATE && UR_sum + LL_sum + LR_sum == 27) begin
        // $display("rotate 180");
        // rotate 180 deg
        qr_in_next[0] = {qr_in[24][0], qr_in[24][1], qr_in[24][2], qr_in[24][3], qr_in[24][4], qr_in[24][5], qr_in[24][6], qr_in[24][7], qr_in[24][8], qr_in[24][9], qr_in[24][10], qr_in[24][11], qr_in[24][12], qr_in[24][13], qr_in[24][14], qr_in[24][15], qr_in[24][16], qr_in[24][17], qr_in[24][18], qr_in[24][19], qr_in[24][20], qr_in[24][21], qr_in[24][22], qr_in[24][23], qr_in[24][24]};
        qr_in_next[1] = {qr_in[23][0], qr_in[23][1], qr_in[23][2], qr_in[23][3], qr_in[23][4], qr_in[23][5], qr_in[23][6], qr_in[23][7], qr_in[23][8], qr_in[23][9], qr_in[23][10], qr_in[23][11], qr_in[23][12], qr_in[23][13], qr_in[23][14], qr_in[23][15], qr_in[23][16], qr_in[23][17], qr_in[23][18], qr_in[23][19], qr_in[23][20], qr_in[23][21], qr_in[23][22], qr_in[23][23], qr_in[23][24]};
        qr_in_next[2] = {qr_in[22][0], qr_in[22][1], qr_in[22][2], qr_in[22][3], qr_in[22][4], qr_in[22][5], qr_in[22][6], qr_in[22][7], qr_in[22][8], qr_in[22][9], qr_in[22][10], qr_in[22][11], qr_in[22][12], qr_in[22][13], qr_in[22][14], qr_in[22][15], qr_in[22][16], qr_in[22][17], qr_in[22][18], qr_in[22][19], qr_in[22][20], qr_in[22][21], qr_in[22][22], qr_in[22][23], qr_in[22][24]};
        qr_in_next[3] = {qr_in[21][0], qr_in[21][1], qr_in[21][2], qr_in[21][3], qr_in[21][4], qr_in[21][5], qr_in[21][6], qr_in[21][7], qr_in[21][8], qr_in[21][9], qr_in[21][10], qr_in[21][11], qr_in[21][12], qr_in[21][13], qr_in[21][14], qr_in[21][15], qr_in[21][16], qr_in[21][17], qr_in[21][18], qr_in[21][19], qr_in[21][20], qr_in[21][21], qr_in[21][22], qr_in[21][23], qr_in[21][24]};
        qr_in_next[4] = {qr_in[20][0], qr_in[20][1], qr_in[20][2], qr_in[20][3], qr_in[20][4], qr_in[20][5], qr_in[20][6], qr_in[20][7], qr_in[20][8], qr_in[20][9], qr_in[20][10], qr_in[20][11], qr_in[20][12], qr_in[20][13], qr_in[20][14], qr_in[20][15], qr_in[20][16], qr_in[20][17], qr_in[20][18], qr_in[20][19], qr_in[20][20], qr_in[20][21], qr_in[20][22], qr_in[20][23], qr_in[20][24]};
        qr_in_next[5] = {qr_in[19][0], qr_in[19][1], qr_in[19][2], qr_in[19][3], qr_in[19][4], qr_in[19][5], qr_in[19][6], qr_in[19][7], qr_in[19][8], qr_in[19][9], qr_in[19][10], qr_in[19][11], qr_in[19][12], qr_in[19][13], qr_in[19][14], qr_in[19][15], qr_in[19][16], qr_in[19][17], qr_in[19][18], qr_in[19][19], qr_in[19][20], qr_in[19][21], qr_in[19][22], qr_in[19][23], qr_in[19][24]};
        qr_in_next[6] = {qr_in[18][0], qr_in[18][1], qr_in[18][2], qr_in[18][3], qr_in[18][4], qr_in[18][5], qr_in[18][6], qr_in[18][7], qr_in[18][8], qr_in[18][9], qr_in[18][10], qr_in[18][11], qr_in[18][12], qr_in[18][13], qr_in[18][14], qr_in[18][15], qr_in[18][16], qr_in[18][17], qr_in[18][18], qr_in[18][19], qr_in[18][20], qr_in[18][21], qr_in[18][22], qr_in[18][23], qr_in[18][24]};
        qr_in_next[7] = {qr_in[17][0], qr_in[17][1], qr_in[17][2], qr_in[17][3], qr_in[17][4], qr_in[17][5], qr_in[17][6], qr_in[17][7], qr_in[17][8], qr_in[17][9], qr_in[17][10], qr_in[17][11], qr_in[17][12], qr_in[17][13], qr_in[17][14], qr_in[17][15], qr_in[17][16], qr_in[17][17], qr_in[17][18], qr_in[17][19], qr_in[17][20], qr_in[17][21], qr_in[17][22], qr_in[17][23], qr_in[17][24]};
        qr_in_next[8] = {qr_in[16][0], qr_in[16][1], qr_in[16][2], qr_in[16][3], qr_in[16][4], qr_in[16][5], qr_in[16][6], qr_in[16][7], qr_in[16][8], qr_in[16][9], qr_in[16][10], qr_in[16][11], qr_in[16][12], qr_in[16][13], qr_in[16][14], qr_in[16][15], qr_in[16][16], qr_in[16][17], qr_in[16][18], qr_in[16][19], qr_in[16][20], qr_in[16][21], qr_in[16][22], qr_in[16][23], qr_in[16][24]};
        qr_in_next[9] = {qr_in[15][0], qr_in[15][1], qr_in[15][2], qr_in[15][3], qr_in[15][4], qr_in[15][5], qr_in[15][6], qr_in[15][7], qr_in[15][8], qr_in[15][9], qr_in[15][10], qr_in[15][11], qr_in[15][12], qr_in[15][13], qr_in[15][14], qr_in[15][15], qr_in[15][16], qr_in[15][17], qr_in[15][18], qr_in[15][19], qr_in[15][20], qr_in[15][21], qr_in[15][22], qr_in[15][23], qr_in[15][24]};
        qr_in_next[10] = {qr_in[14][0], qr_in[14][1], qr_in[14][2], qr_in[14][3], qr_in[14][4], qr_in[14][5], qr_in[14][6], qr_in[14][7], qr_in[14][8], qr_in[14][9], qr_in[14][10], qr_in[14][11], qr_in[14][12], qr_in[14][13], qr_in[14][14], qr_in[14][15], qr_in[14][16], qr_in[14][17], qr_in[14][18], qr_in[14][19], qr_in[14][20], qr_in[14][21], qr_in[14][22], qr_in[14][23], qr_in[14][24]};
        qr_in_next[11] = {qr_in[13][0], qr_in[13][1], qr_in[13][2], qr_in[13][3], qr_in[13][4], qr_in[13][5], qr_in[13][6], qr_in[13][7], qr_in[13][8], qr_in[13][9], qr_in[13][10], qr_in[13][11], qr_in[13][12], qr_in[13][13], qr_in[13][14], qr_in[13][15], qr_in[13][16], qr_in[13][17], qr_in[13][18], qr_in[13][19], qr_in[13][20], qr_in[13][21], qr_in[13][22], qr_in[13][23], qr_in[13][24]};
        qr_in_next[12] = {qr_in[12][0], qr_in[12][1], qr_in[12][2], qr_in[12][3], qr_in[12][4], qr_in[12][5], qr_in[12][6], qr_in[12][7], qr_in[12][8], qr_in[12][9], qr_in[12][10], qr_in[12][11], qr_in[12][12], qr_in[12][13], qr_in[12][14], qr_in[12][15], qr_in[12][16], qr_in[12][17], qr_in[12][18], qr_in[12][19], qr_in[12][20], qr_in[12][21], qr_in[12][22], qr_in[12][23], qr_in[12][24]};
        qr_in_next[13] = {qr_in[11][0], qr_in[11][1], qr_in[11][2], qr_in[11][3], qr_in[11][4], qr_in[11][5], qr_in[11][6], qr_in[11][7], qr_in[11][8], qr_in[11][9], qr_in[11][10], qr_in[11][11], qr_in[11][12], qr_in[11][13], qr_in[11][14], qr_in[11][15], qr_in[11][16], qr_in[11][17], qr_in[11][18], qr_in[11][19], qr_in[11][20], qr_in[11][21], qr_in[11][22], qr_in[11][23], qr_in[11][24]};
        qr_in_next[14] = {qr_in[10][0], qr_in[10][1], qr_in[10][2], qr_in[10][3], qr_in[10][4], qr_in[10][5], qr_in[10][6], qr_in[10][7], qr_in[10][8], qr_in[10][9], qr_in[10][10], qr_in[10][11], qr_in[10][12], qr_in[10][13], qr_in[10][14], qr_in[10][15], qr_in[10][16], qr_in[10][17], qr_in[10][18], qr_in[10][19], qr_in[10][20], qr_in[10][21], qr_in[10][22], qr_in[10][23], qr_in[10][24]};
        qr_in_next[15] = {qr_in[9][0], qr_in[9][1], qr_in[9][2], qr_in[9][3], qr_in[9][4], qr_in[9][5], qr_in[9][6], qr_in[9][7], qr_in[9][8], qr_in[9][9], qr_in[9][10], qr_in[9][11], qr_in[9][12], qr_in[9][13], qr_in[9][14], qr_in[9][15], qr_in[9][16], qr_in[9][17], qr_in[9][18], qr_in[9][19], qr_in[9][20], qr_in[9][21], qr_in[9][22], qr_in[9][23], qr_in[9][24]};
        qr_in_next[16] = {qr_in[8][0], qr_in[8][1], qr_in[8][2], qr_in[8][3], qr_in[8][4], qr_in[8][5], qr_in[8][6], qr_in[8][7], qr_in[8][8], qr_in[8][9], qr_in[8][10], qr_in[8][11], qr_in[8][12], qr_in[8][13], qr_in[8][14], qr_in[8][15], qr_in[8][16], qr_in[8][17], qr_in[8][18], qr_in[8][19], qr_in[8][20], qr_in[8][21], qr_in[8][22], qr_in[8][23], qr_in[8][24]};
        qr_in_next[17] = {qr_in[7][0], qr_in[7][1], qr_in[7][2], qr_in[7][3], qr_in[7][4], qr_in[7][5], qr_in[7][6], qr_in[7][7], qr_in[7][8], qr_in[7][9], qr_in[7][10], qr_in[7][11], qr_in[7][12], qr_in[7][13], qr_in[7][14], qr_in[7][15], qr_in[7][16], qr_in[7][17], qr_in[7][18], qr_in[7][19], qr_in[7][20], qr_in[7][21], qr_in[7][22], qr_in[7][23], qr_in[7][24]};
        qr_in_next[18] = {qr_in[6][0], qr_in[6][1], qr_in[6][2], qr_in[6][3], qr_in[6][4], qr_in[6][5], qr_in[6][6], qr_in[6][7], qr_in[6][8], qr_in[6][9], qr_in[6][10], qr_in[6][11], qr_in[6][12], qr_in[6][13], qr_in[6][14], qr_in[6][15], qr_in[6][16], qr_in[6][17], qr_in[6][18], qr_in[6][19], qr_in[6][20], qr_in[6][21], qr_in[6][22], qr_in[6][23], qr_in[6][24]};
        qr_in_next[19] = {qr_in[5][0], qr_in[5][1], qr_in[5][2], qr_in[5][3], qr_in[5][4], qr_in[5][5], qr_in[5][6], qr_in[5][7], qr_in[5][8], qr_in[5][9], qr_in[5][10], qr_in[5][11], qr_in[5][12], qr_in[5][13], qr_in[5][14], qr_in[5][15], qr_in[5][16], qr_in[5][17], qr_in[5][18], qr_in[5][19], qr_in[5][20], qr_in[5][21], qr_in[5][22], qr_in[5][23], qr_in[5][24]};
        qr_in_next[20] = {qr_in[4][0], qr_in[4][1], qr_in[4][2], qr_in[4][3], qr_in[4][4], qr_in[4][5], qr_in[4][6], qr_in[4][7], qr_in[4][8], qr_in[4][9], qr_in[4][10], qr_in[4][11], qr_in[4][12], qr_in[4][13], qr_in[4][14], qr_in[4][15], qr_in[4][16], qr_in[4][17], qr_in[4][18], qr_in[4][19], qr_in[4][20], qr_in[4][21], qr_in[4][22], qr_in[4][23], qr_in[4][24]};
        qr_in_next[21] = {qr_in[3][0], qr_in[3][1], qr_in[3][2], qr_in[3][3], qr_in[3][4], qr_in[3][5], qr_in[3][6], qr_in[3][7], qr_in[3][8], qr_in[3][9], qr_in[3][10], qr_in[3][11], qr_in[3][12], qr_in[3][13], qr_in[3][14], qr_in[3][15], qr_in[3][16], qr_in[3][17], qr_in[3][18], qr_in[3][19], qr_in[3][20], qr_in[3][21], qr_in[3][22], qr_in[3][23], qr_in[3][24]};
        qr_in_next[22] = {qr_in[2][0], qr_in[2][1], qr_in[2][2], qr_in[2][3], qr_in[2][4], qr_in[2][5], qr_in[2][6], qr_in[2][7], qr_in[2][8], qr_in[2][9], qr_in[2][10], qr_in[2][11], qr_in[2][12], qr_in[2][13], qr_in[2][14], qr_in[2][15], qr_in[2][16], qr_in[2][17], qr_in[2][18], qr_in[2][19], qr_in[2][20], qr_in[2][21], qr_in[2][22], qr_in[2][23], qr_in[2][24]};
        qr_in_next[23] = {qr_in[1][0], qr_in[1][1], qr_in[1][2], qr_in[1][3], qr_in[1][4], qr_in[1][5], qr_in[1][6], qr_in[1][7], qr_in[1][8], qr_in[1][9], qr_in[1][10], qr_in[1][11], qr_in[1][12], qr_in[1][13], qr_in[1][14], qr_in[1][15], qr_in[1][16], qr_in[1][17], qr_in[1][18], qr_in[1][19], qr_in[1][20], qr_in[1][21], qr_in[1][22], qr_in[1][23], qr_in[1][24]};
        qr_in_next[24] = {qr_in[0][0], qr_in[0][1], qr_in[0][2], qr_in[0][3], qr_in[0][4], qr_in[0][5], qr_in[0][6], qr_in[0][7], qr_in[0][8], qr_in[0][9], qr_in[0][10], qr_in[0][11], qr_in[0][12], qr_in[0][13], qr_in[0][14], qr_in[0][15], qr_in[0][16], qr_in[0][17], qr_in[0][18], qr_in[0][19], qr_in[0][20], qr_in[0][21], qr_in[0][22], qr_in[0][23], qr_in[0][24]};
    end
    else if (state == ROTATE && UL_sum + UR_sum + LR_sum == 27) begin
        // rotate 270 deg
        qr_in_next[0] = {qr_in[24][24], qr_in[23][24], qr_in[22][24], qr_in[21][24], qr_in[20][24], qr_in[19][24], qr_in[18][24], qr_in[17][24], qr_in[16][24], qr_in[15][24], qr_in[14][24], qr_in[13][24], qr_in[12][24], qr_in[11][24], qr_in[10][24], qr_in[9][24], qr_in[8][24], qr_in[7][24], qr_in[6][24], qr_in[5][24], qr_in[4][24], qr_in[3][24], qr_in[2][24], qr_in[1][24], qr_in[0][24]};
        qr_in_next[1] = {qr_in[24][23], qr_in[23][23], qr_in[22][23], qr_in[21][23], qr_in[20][23], qr_in[19][23], qr_in[18][23], qr_in[17][23], qr_in[16][23], qr_in[15][23], qr_in[14][23], qr_in[13][23], qr_in[12][23], qr_in[11][23], qr_in[10][23], qr_in[9][23], qr_in[8][23], qr_in[7][23], qr_in[6][23], qr_in[5][23], qr_in[4][23], qr_in[3][23], qr_in[2][23], qr_in[1][23], qr_in[0][23]};
        qr_in_next[2] = {qr_in[24][22], qr_in[23][22], qr_in[22][22], qr_in[21][22], qr_in[20][22], qr_in[19][22], qr_in[18][22], qr_in[17][22], qr_in[16][22], qr_in[15][22], qr_in[14][22], qr_in[13][22], qr_in[12][22], qr_in[11][22], qr_in[10][22], qr_in[9][22], qr_in[8][22], qr_in[7][22], qr_in[6][22], qr_in[5][22], qr_in[4][22], qr_in[3][22], qr_in[2][22], qr_in[1][22], qr_in[0][22]};
        qr_in_next[3] = {qr_in[24][21], qr_in[23][21], qr_in[22][21], qr_in[21][21], qr_in[20][21], qr_in[19][21], qr_in[18][21], qr_in[17][21], qr_in[16][21], qr_in[15][21], qr_in[14][21], qr_in[13][21], qr_in[12][21], qr_in[11][21], qr_in[10][21], qr_in[9][21], qr_in[8][21], qr_in[7][21], qr_in[6][21], qr_in[5][21], qr_in[4][21], qr_in[3][21], qr_in[2][21], qr_in[1][21], qr_in[0][21]};
        qr_in_next[4] = {qr_in[24][20], qr_in[23][20], qr_in[22][20], qr_in[21][20], qr_in[20][20], qr_in[19][20], qr_in[18][20], qr_in[17][20], qr_in[16][20], qr_in[15][20], qr_in[14][20], qr_in[13][20], qr_in[12][20], qr_in[11][20], qr_in[10][20], qr_in[9][20], qr_in[8][20], qr_in[7][20], qr_in[6][20], qr_in[5][20], qr_in[4][20], qr_in[3][20], qr_in[2][20], qr_in[1][20], qr_in[0][20]};
        qr_in_next[5] = {qr_in[24][19], qr_in[23][19], qr_in[22][19], qr_in[21][19], qr_in[20][19], qr_in[19][19], qr_in[18][19], qr_in[17][19], qr_in[16][19], qr_in[15][19], qr_in[14][19], qr_in[13][19], qr_in[12][19], qr_in[11][19], qr_in[10][19], qr_in[9][19], qr_in[8][19], qr_in[7][19], qr_in[6][19], qr_in[5][19], qr_in[4][19], qr_in[3][19], qr_in[2][19], qr_in[1][19], qr_in[0][19]};
        qr_in_next[6] = {qr_in[24][18], qr_in[23][18], qr_in[22][18], qr_in[21][18], qr_in[20][18], qr_in[19][18], qr_in[18][18], qr_in[17][18], qr_in[16][18], qr_in[15][18], qr_in[14][18], qr_in[13][18], qr_in[12][18], qr_in[11][18], qr_in[10][18], qr_in[9][18], qr_in[8][18], qr_in[7][18], qr_in[6][18], qr_in[5][18], qr_in[4][18], qr_in[3][18], qr_in[2][18], qr_in[1][18], qr_in[0][18]};
        qr_in_next[7] = {qr_in[24][17], qr_in[23][17], qr_in[22][17], qr_in[21][17], qr_in[20][17], qr_in[19][17], qr_in[18][17], qr_in[17][17], qr_in[16][17], qr_in[15][17], qr_in[14][17], qr_in[13][17], qr_in[12][17], qr_in[11][17], qr_in[10][17], qr_in[9][17], qr_in[8][17], qr_in[7][17], qr_in[6][17], qr_in[5][17], qr_in[4][17], qr_in[3][17], qr_in[2][17], qr_in[1][17], qr_in[0][17]};
        qr_in_next[8] = {qr_in[24][16], qr_in[23][16], qr_in[22][16], qr_in[21][16], qr_in[20][16], qr_in[19][16], qr_in[18][16], qr_in[17][16], qr_in[16][16], qr_in[15][16], qr_in[14][16], qr_in[13][16], qr_in[12][16], qr_in[11][16], qr_in[10][16], qr_in[9][16], qr_in[8][16], qr_in[7][16], qr_in[6][16], qr_in[5][16], qr_in[4][16], qr_in[3][16], qr_in[2][16], qr_in[1][16], qr_in[0][16]};
        qr_in_next[9] = {qr_in[24][15], qr_in[23][15], qr_in[22][15], qr_in[21][15], qr_in[20][15], qr_in[19][15], qr_in[18][15], qr_in[17][15], qr_in[16][15], qr_in[15][15], qr_in[14][15], qr_in[13][15], qr_in[12][15], qr_in[11][15], qr_in[10][15], qr_in[9][15], qr_in[8][15], qr_in[7][15], qr_in[6][15], qr_in[5][15], qr_in[4][15], qr_in[3][15], qr_in[2][15], qr_in[1][15], qr_in[0][15]};
        qr_in_next[10] = {qr_in[24][14], qr_in[23][14], qr_in[22][14], qr_in[21][14], qr_in[20][14], qr_in[19][14], qr_in[18][14], qr_in[17][14], qr_in[16][14], qr_in[15][14], qr_in[14][14], qr_in[13][14], qr_in[12][14], qr_in[11][14], qr_in[10][14], qr_in[9][14], qr_in[8][14], qr_in[7][14], qr_in[6][14], qr_in[5][14], qr_in[4][14], qr_in[3][14], qr_in[2][14], qr_in[1][14], qr_in[0][14]};
        qr_in_next[11] = {qr_in[24][13], qr_in[23][13], qr_in[22][13], qr_in[21][13], qr_in[20][13], qr_in[19][13], qr_in[18][13], qr_in[17][13], qr_in[16][13], qr_in[15][13], qr_in[14][13], qr_in[13][13], qr_in[12][13], qr_in[11][13], qr_in[10][13], qr_in[9][13], qr_in[8][13], qr_in[7][13], qr_in[6][13], qr_in[5][13], qr_in[4][13], qr_in[3][13], qr_in[2][13], qr_in[1][13], qr_in[0][13]};
        qr_in_next[12] = {qr_in[24][12], qr_in[23][12], qr_in[22][12], qr_in[21][12], qr_in[20][12], qr_in[19][12], qr_in[18][12], qr_in[17][12], qr_in[16][12], qr_in[15][12], qr_in[14][12], qr_in[13][12], qr_in[12][12], qr_in[11][12], qr_in[10][12], qr_in[9][12], qr_in[8][12], qr_in[7][12], qr_in[6][12], qr_in[5][12], qr_in[4][12], qr_in[3][12], qr_in[2][12], qr_in[1][12], qr_in[0][12]};
        qr_in_next[13] = {qr_in[24][11], qr_in[23][11], qr_in[22][11], qr_in[21][11], qr_in[20][11], qr_in[19][11], qr_in[18][11], qr_in[17][11], qr_in[16][11], qr_in[15][11], qr_in[14][11], qr_in[13][11], qr_in[12][11], qr_in[11][11], qr_in[10][11], qr_in[9][11], qr_in[8][11], qr_in[7][11], qr_in[6][11], qr_in[5][11], qr_in[4][11], qr_in[3][11], qr_in[2][11], qr_in[1][11], qr_in[0][11]};
        qr_in_next[14] = {qr_in[24][10], qr_in[23][10], qr_in[22][10], qr_in[21][10], qr_in[20][10], qr_in[19][10], qr_in[18][10], qr_in[17][10], qr_in[16][10], qr_in[15][10], qr_in[14][10], qr_in[13][10], qr_in[12][10], qr_in[11][10], qr_in[10][10], qr_in[9][10], qr_in[8][10], qr_in[7][10], qr_in[6][10], qr_in[5][10], qr_in[4][10], qr_in[3][10], qr_in[2][10], qr_in[1][10], qr_in[0][10]};
        qr_in_next[15] = {qr_in[24][9], qr_in[23][9], qr_in[22][9], qr_in[21][9], qr_in[20][9], qr_in[19][9], qr_in[18][9], qr_in[17][9], qr_in[16][9], qr_in[15][9], qr_in[14][9], qr_in[13][9], qr_in[12][9], qr_in[11][9], qr_in[10][9], qr_in[9][9], qr_in[8][9], qr_in[7][9], qr_in[6][9], qr_in[5][9], qr_in[4][9], qr_in[3][9], qr_in[2][9], qr_in[1][9], qr_in[0][9]};
        qr_in_next[16] = {qr_in[24][8], qr_in[23][8], qr_in[22][8], qr_in[21][8], qr_in[20][8], qr_in[19][8], qr_in[18][8], qr_in[17][8], qr_in[16][8], qr_in[15][8], qr_in[14][8], qr_in[13][8], qr_in[12][8], qr_in[11][8], qr_in[10][8], qr_in[9][8], qr_in[8][8], qr_in[7][8], qr_in[6][8], qr_in[5][8], qr_in[4][8], qr_in[3][8], qr_in[2][8], qr_in[1][8], qr_in[0][8]};
        qr_in_next[17] = {qr_in[24][7], qr_in[23][7], qr_in[22][7], qr_in[21][7], qr_in[20][7], qr_in[19][7], qr_in[18][7], qr_in[17][7], qr_in[16][7], qr_in[15][7], qr_in[14][7], qr_in[13][7], qr_in[12][7], qr_in[11][7], qr_in[10][7], qr_in[9][7], qr_in[8][7], qr_in[7][7], qr_in[6][7], qr_in[5][7], qr_in[4][7], qr_in[3][7], qr_in[2][7], qr_in[1][7], qr_in[0][7]};
        qr_in_next[18] = {qr_in[24][6], qr_in[23][6], qr_in[22][6], qr_in[21][6], qr_in[20][6], qr_in[19][6], qr_in[18][6], qr_in[17][6], qr_in[16][6], qr_in[15][6], qr_in[14][6], qr_in[13][6], qr_in[12][6], qr_in[11][6], qr_in[10][6], qr_in[9][6], qr_in[8][6], qr_in[7][6], qr_in[6][6], qr_in[5][6], qr_in[4][6], qr_in[3][6], qr_in[2][6], qr_in[1][6], qr_in[0][6]};
        qr_in_next[19] = {qr_in[24][5], qr_in[23][5], qr_in[22][5], qr_in[21][5], qr_in[20][5], qr_in[19][5], qr_in[18][5], qr_in[17][5], qr_in[16][5], qr_in[15][5], qr_in[14][5], qr_in[13][5], qr_in[12][5], qr_in[11][5], qr_in[10][5], qr_in[9][5], qr_in[8][5], qr_in[7][5], qr_in[6][5], qr_in[5][5], qr_in[4][5], qr_in[3][5], qr_in[2][5], qr_in[1][5], qr_in[0][5]};
        qr_in_next[20] = {qr_in[24][4], qr_in[23][4], qr_in[22][4], qr_in[21][4], qr_in[20][4], qr_in[19][4], qr_in[18][4], qr_in[17][4], qr_in[16][4], qr_in[15][4], qr_in[14][4], qr_in[13][4], qr_in[12][4], qr_in[11][4], qr_in[10][4], qr_in[9][4], qr_in[8][4], qr_in[7][4], qr_in[6][4], qr_in[5][4], qr_in[4][4], qr_in[3][4], qr_in[2][4], qr_in[1][4], qr_in[0][4]};
        qr_in_next[21] = {qr_in[24][3], qr_in[23][3], qr_in[22][3], qr_in[21][3], qr_in[20][3], qr_in[19][3], qr_in[18][3], qr_in[17][3], qr_in[16][3], qr_in[15][3], qr_in[14][3], qr_in[13][3], qr_in[12][3], qr_in[11][3], qr_in[10][3], qr_in[9][3], qr_in[8][3], qr_in[7][3], qr_in[6][3], qr_in[5][3], qr_in[4][3], qr_in[3][3], qr_in[2][3], qr_in[1][3], qr_in[0][3]};
        qr_in_next[22] = {qr_in[24][2], qr_in[23][2], qr_in[22][2], qr_in[21][2], qr_in[20][2], qr_in[19][2], qr_in[18][2], qr_in[17][2], qr_in[16][2], qr_in[15][2], qr_in[14][2], qr_in[13][2], qr_in[12][2], qr_in[11][2], qr_in[10][2], qr_in[9][2], qr_in[8][2], qr_in[7][2], qr_in[6][2], qr_in[5][2], qr_in[4][2], qr_in[3][2], qr_in[2][2], qr_in[1][2], qr_in[0][2]};
        qr_in_next[23] = {qr_in[24][1], qr_in[23][1], qr_in[22][1], qr_in[21][1], qr_in[20][1], qr_in[19][1], qr_in[18][1], qr_in[17][1], qr_in[16][1], qr_in[15][1], qr_in[14][1], qr_in[13][1], qr_in[12][1], qr_in[11][1], qr_in[10][1], qr_in[9][1], qr_in[8][1], qr_in[7][1], qr_in[6][1], qr_in[5][1], qr_in[4][1], qr_in[3][1], qr_in[2][1], qr_in[1][1], qr_in[0][1]};
        qr_in_next[24] = {qr_in[24][0], qr_in[23][0], qr_in[22][0], qr_in[21][0], qr_in[20][0], qr_in[19][0], qr_in[18][0], qr_in[17][0], qr_in[16][0], qr_in[15][0], qr_in[14][0], qr_in[13][0], qr_in[12][0], qr_in[11][0], qr_in[10][0], qr_in[9][0], qr_in[8][0], qr_in[7][0], qr_in[6][0], qr_in[5][0], qr_in[4][0], qr_in[3][0], qr_in[2][0], qr_in[1][0], qr_in[0][0]};
    end
    else begin
        for (i = 0; i < 25; i = i + 1) begin
            qr_in_next[i] = qr_in[i];
        end
    end

end

// cal four sum to determine the direction 
always @* begin
    LR_sum = (qr_in[20][20] + qr_in[20][21] + qr_in[20][22] + qr_in[21][20] + qr_in[21][21] + qr_in[21][22] + qr_in[22][20] + qr_in[22][21] + qr_in[22][22]);
    LL_sum = (qr_in[20][2] + qr_in[20][3] + qr_in[20][4] + qr_in[21][2] + qr_in[21][3] + qr_in[21][4] + qr_in[22][2] + qr_in[22][3] + qr_in[22][4]);
    UL_sum = (qr_in[2][2] + qr_in[2][3] + qr_in[2][4] + qr_in[3][2] + qr_in[3][3] + qr_in[3][4] + qr_in[4][2] + qr_in[4][3] + qr_in[4][4]);
    UR_sum = (qr_in[2][20] + qr_in[2][21] + qr_in[2][22] + qr_in[3][20] + qr_in[3][21] + qr_in[3][22] + qr_in[4][20] + qr_in[4][21] + qr_in[4][22]);
end

// cal the first position of qrcode
always @* begin
    if (!find_qrcode && sram_rdata == 1) begin
        first_r_next = img_r;
        first_c_next = img_c;
        find_qrcode_next = 1;
    end
    else begin
        first_r_next = first_r;
        first_c_next = first_c;
        find_qrcode_next = find_qrcode;
    end
end


// FSM
always @* begin
    case(state)
        IDLE: begin
            if (qr_decode_start) begin
                state_n = MEM;  
            end
            else begin
                state_n = IDLE;
            end
        end
        MEM: begin
            if (read_cnt == 64 * 64) begin
                state_n = ROTATE;
            end
            else begin
                state_n = MEM;
            end
        end
        ROTATE: begin
            state_n = DECODE;
        end
        DECODE: begin
            if (decode_cnt == text_length) begin
                state_n = CAL_S;
            end
            else begin
                state_n = DECODE;
            end
        end
        CAL_S: begin
            if (s_cnt == 43) begin
                state_n = CAL_COEFF;
            end
            else begin
                state_n = CAL_S;
            end
        end
        CAL_COEFF: begin
            if (eq_cnt == 7) begin
                state_n = SOLVE_SIGMA;
            end
            else begin
                state_n = CAL_COEFF;
            end
        end
        SOLVE_SIGMA: begin
            if (solve_sigma_cnt == 4) begin
                state_n = SOLVE_I;
            end
            else begin
                state_n = SOLVE_SIGMA;
            end
        end
        SOLVE_I: begin
            if (solve_i_cnt == 44) begin
                state_n = CAL_COEFF_Y;
            end
            else begin
                state_n = SOLVE_I;
            end
        end
        CAL_COEFF_Y: begin
            if (y_coeff_cnt == 6) begin
                state_n = SOLVE_Y;
            end
            else begin
                state_n = CAL_COEFF_Y;
            end
        end
        SOLVE_Y: begin
            if (solve_y_cnt == 4) begin
                state_n = CAL_OFFSET;
            end
            else begin
                state_n = SOLVE_Y;
            end
        end
        CAL_OFFSET: begin
            state_n = CORRECT;
        end
        CORRECT: begin
            state_n = SEND_OUTPUT;
        end
        SEND_OUTPUT: begin
            if (send_output_cnt == text_length) begin
                state_n = FINISH;
            end
            else begin
                state_n = SEND_OUTPUT;
            end
        end
        FINISH: begin
            state_n = IDLE;
        end
        default: state_n = IDLE;
    endcase
end

// calculate sram read address
always @* begin
    sram_raddr = img_r * 64 + img_c;
end

// calculate img_r and img_c
always @* begin
    if (state == MEM) begin
        if (img_c == 40 && !find_qrcode) begin
            img_r_next = img_r + 1;
            img_c_next = 0;
            read_cnt_n = read_cnt + 1;
        end
        else if (img_c == 63) begin
            img_r_next = img_r + 1;
            img_c_next = 0;
            read_cnt_n = read_cnt + 1;
        end
        else begin
            img_r_next = img_r;
            img_c_next = img_c + 1;
            read_cnt_n = read_cnt + 1;
        end
    end
    else begin
        img_r_next = img_r;
        img_c_next = img_c;
        read_cnt_n = read_cnt;
    end
end

// assign 3-bit demask pattern
wire [2:0] demask_pattern;
assign demask_pattern = {!qr_in[8][2], qr_in[8][3], !qr_in[8][4]};

// construct demask qrcode
always @* begin
    case (demask_pattern)
        // i stands for ROW, j stands for COLUMN
        3'b000: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if ((i + j) % 2 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        3'b001: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i % 2 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        3'b010: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (j % 3 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        3'b011: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if ((i + j) % 3 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        3'b100: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (((i / 2) + (j / 3)) % 2 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        3'b101: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (((i * j) % 2 + (i * j) % 3) == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        3'b110: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (((i * j) % 2 + (i * j) % 3) % 2 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        3'b111: begin
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (((i * j) % 3 + (i + j) % 2) % 2 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end

        default: begin
            // set default demasking as case 3'b000
            for (i = 0; i < QR_LEN; i = i + 1) begin
                for (j = 0; j < QR_LEN; j = j + 1) begin
                    if (i <= 7 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i <= 7 && j >= 17) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if (i >= 17 && j <= 7) 
                        qr_demask[i][j] = qr_in[i][j];
                    else if ((i + j) % 2 == 0)
                        qr_demask[i][j] = !qr_in[i][j];
                    else
                        qr_demask[i][j] = qr_in[i][j];
                end
            end
        end
    endcase
end

// construct codeword_origin table
always @* begin
    codeword_origin_next[0] = {qr_demask[24][24], qr_demask[24][23], qr_demask[23][24], qr_demask[23][23], qr_demask[22][24], qr_demask[22][23], qr_demask[21][24], qr_demask[21][23]};
    codeword_origin_next[1] = {qr_demask[24-4][24], qr_demask[24-4][23], qr_demask[23-4][24], qr_demask[23-4][23], qr_demask[22-4][24], qr_demask[22-4][23], qr_demask[21-4][24], qr_demask[21-4][23]};
    codeword_origin_next[2] = {qr_demask[24-8][24], qr_demask[24-8][23], qr_demask[23-8][24], qr_demask[23-8][23], qr_demask[22-8][24], qr_demask[22-8][23], qr_demask[21-8][24], qr_demask[21-8][23]};
    codeword_origin_next[3] = {qr_demask[24-12][24], qr_demask[24-12][23], qr_demask[23-12][24], qr_demask[23-12][23], qr_demask[22-12][24], qr_demask[22-12][23], qr_demask[21-12][24], qr_demask[21-12][23]};


    codeword_origin_next[4] = {qr_demask[21-12][22], qr_demask[21-12][21], qr_demask[22-12][22], qr_demask[22-12][21], qr_demask[23-12][22], qr_demask[23-12][21], qr_demask[24-12][22], qr_demask[24-12][21]};
    codeword_origin_next[5] = {qr_demask[21-8][22], qr_demask[21-8][21], qr_demask[22-8][22], qr_demask[22-8][21], qr_demask[23-8][22], qr_demask[23-8][21], qr_demask[24-8][22], qr_demask[24-8][21]};
    codeword_origin_next[6] = {qr_demask[21-4][22], qr_demask[21-4][21], qr_demask[22-4][22], qr_demask[22-4][21], qr_demask[23-4][22], qr_demask[23-4][21], qr_demask[24-4][22], qr_demask[24-4][21]};
    codeword_origin_next[7] = {qr_demask[21][22], qr_demask[21][21], qr_demask[22][22], qr_demask[22][21], qr_demask[23][22], qr_demask[23][21], qr_demask[24][22], qr_demask[24][21]};

    codeword_origin_next[8] = {qr_demask[24][24-4], qr_demask[24][23-4], qr_demask[23][24-4], qr_demask[23][23-4], qr_demask[22][24-4], qr_demask[22][23-4], qr_demask[21][24-4], qr_demask[21][23-4]};
    codeword_origin_next[9] = {qr_demask[24-9][24-4], qr_demask[24-9][23-4], qr_demask[23-9][24-4], qr_demask[23-9][23-4], qr_demask[22-9][24-4], qr_demask[22-9][23-4], qr_demask[21-9][24-4], qr_demask[21-9][23-4]};


    codeword_origin_next[10] = {qr_demask[11][20], qr_demask[11][19], qr_demask[10][20], qr_demask[10][19], qr_demask[9][20], qr_demask[9][19], qr_demask[9][18], qr_demask[9][17]};
    codeword_origin_next[11] = {qr_demask[10][18], qr_demask[10][17], qr_demask[11][18], qr_demask[11][17], qr_demask[12][18], qr_demask[12][17], qr_demask[13][18], qr_demask[13][17]};
    codeword_origin_next[12] = {qr_demask[10+4][18], qr_demask[10+4][17], qr_demask[11+4][18], qr_demask[11+4][17], qr_demask[12+9][18], qr_demask[12+9][17], qr_demask[13+9][18], qr_demask[13+9][17]};
    codeword_origin_next[13] = {qr_demask[23][18], qr_demask[23][17], qr_demask[24][18], qr_demask[24][17], qr_demask[24][16], qr_demask[24][15], qr_demask[23][16], qr_demask[23][15]};
    codeword_origin_next[14] = {qr_demask[22][16], qr_demask[22][15], qr_demask[21][16], qr_demask[21][15], qr_demask[20][15], qr_demask[19][15], qr_demask[18][15], qr_demask[17][15]};

    codeword_origin_next[15] = {qr_demask[16][15], qr_demask[15][16], qr_demask[15][15], qr_demask[14][16], qr_demask[14][15], qr_demask[13][16], qr_demask[13][15], qr_demask[12][16]};
    codeword_origin_next[16] = {qr_demask[16-4][15], qr_demask[15-4][16], qr_demask[15-4][15], qr_demask[14-4][16], qr_demask[14-4][15], qr_demask[13-4][16], qr_demask[13-4][15], qr_demask[12-4][16]};
    codeword_origin_next[17] = {qr_demask[8][15], qr_demask[7][16], qr_demask[7][15], qr_demask[5][16], qr_demask[5][15], qr_demask[4][16], qr_demask[4][15], qr_demask[3][16]};

    codeword_origin_next[18] = {qr_demask[3][15], qr_demask[2][16], qr_demask[2][15], qr_demask[1][16], qr_demask[1][15], qr_demask[0][16], qr_demask[0][15], qr_demask[0][14]};

    codeword_origin_next[19] = {qr_demask[0][13], qr_demask[1][14], qr_demask[1][13], qr_demask[2][14], qr_demask[2][13], qr_demask[3][14], qr_demask[3][13], qr_demask[4][14]};
    codeword_origin_next[20] = {qr_demask[4][13], qr_demask[5][14], qr_demask[5][13], qr_demask[7][14], qr_demask[7][13], qr_demask[8][14], qr_demask[8][13], qr_demask[9][14]};
    codeword_origin_next[21] = {qr_demask[0+8+1][13], qr_demask[1+8+1][14], qr_demask[1+8+1][13], qr_demask[2+8+1][14], qr_demask[2+8+1][13], qr_demask[3+8+1][14], qr_demask[3+8+1][13], qr_demask[4+8+1][14]};
    codeword_origin_next[22] = {qr_demask[0+12+1][13], qr_demask[1+12+1][14], qr_demask[1+12+1][13], qr_demask[2+12+1][14], qr_demask[2+12+1][13], qr_demask[3+12+1][14], qr_demask[3+12+1][13], qr_demask[4+12+1][14]};
    codeword_origin_next[23] = {qr_demask[0+16+1][13], qr_demask[1+16+1][14], qr_demask[1+16+1][13], qr_demask[2+16+1][14], qr_demask[2+16+1][13], qr_demask[3+16+1][14], qr_demask[3+16+1][13], qr_demask[4+16+1][14]};

    codeword_origin_next[24] = {qr_demask[21][13], qr_demask[22][14], qr_demask[22][13], qr_demask[23][14], qr_demask[23][13], qr_demask[24][14], qr_demask[24][13], qr_demask[24][12]};

    codeword_origin_next[25] = {qr_demask[24][11], qr_demask[23][12], qr_demask[23][11], qr_demask[22][12], qr_demask[22][11], qr_demask[21][12], qr_demask[21][11], qr_demask[20][12]};
    codeword_origin_next[26] = {qr_demask[24-4][11], qr_demask[23-4][12], qr_demask[23-4][11], qr_demask[22-4][12], qr_demask[22-4][11], qr_demask[21-4][12], qr_demask[21-4][11], qr_demask[20-4][12]};
    codeword_origin_next[27] = {qr_demask[24-8][11], qr_demask[23-8][12], qr_demask[23-8][11], qr_demask[22-8][12], qr_demask[22-8][11], qr_demask[21-8][12], qr_demask[21-8][11], qr_demask[20-8][12]};
    codeword_origin_next[28] = {qr_demask[24-12][11], qr_demask[23-12][12], qr_demask[23-12][11], qr_demask[22-12][12], qr_demask[22-12][11], qr_demask[21-12][12], qr_demask[21-12][11], qr_demask[20-12][12]};
    codeword_origin_next[29] = {qr_demask[8][11], qr_demask[7][12], qr_demask[7][11], qr_demask[5][12], qr_demask[5][11], qr_demask[4][12], qr_demask[4][11], qr_demask[3][12]};

    codeword_origin_next[30] = {qr_demask[3][11], qr_demask[2][12], qr_demask[2][11], qr_demask[1][12], qr_demask[1][11], qr_demask[0][12], qr_demask[0][11], qr_demask[0][10]};

    codeword_origin_next[31] = {qr_demask[0][9], qr_demask[1][10], qr_demask[1][9], qr_demask[2][10], qr_demask[2][9], qr_demask[3][10], qr_demask[3][9], qr_demask[4][10]};
    codeword_origin_next[32] = {qr_demask[4][9], qr_demask[5][10], qr_demask[5][9], qr_demask[7][10], qr_demask[7][9], qr_demask[8][10], qr_demask[8][9], qr_demask[9][10]};
    codeword_origin_next[33] = {qr_demask[0+8+1][9], qr_demask[1+8+1][10], qr_demask[1+8+1][9], qr_demask[2+8+1][10], qr_demask[2+8+1][9], qr_demask[3+8+1][10], qr_demask[3+8+1][9], qr_demask[4+8+1][10]};
    codeword_origin_next[34] = {qr_demask[0+12+1][9], qr_demask[1+12+1][10], qr_demask[1+12+1][9], qr_demask[2+12+1][10], qr_demask[2+12+1][9], qr_demask[3+12+1][10], qr_demask[3+12+1][9], qr_demask[4+12+1][10]};
    codeword_origin_next[35] = {qr_demask[0+16+1][9], qr_demask[1+16+1][10], qr_demask[1+16+1][9], qr_demask[2+16+1][10], qr_demask[2+16+1][9], qr_demask[3+16+1][10], qr_demask[3+16+1][9], qr_demask[4+16+1][10]};
    codeword_origin_next[36] = {qr_demask[0+20+1][9], qr_demask[1+20+1][10], qr_demask[1+20+1][9], qr_demask[2+20+1][10], qr_demask[2+20+1][9], qr_demask[3+20+1][10], qr_demask[3+20+1][9], qr_demask[16][8]};

    codeword_origin_next[37] = {qr_demask[16][7], qr_demask[15][8], qr_demask[15][7], qr_demask[14][8], qr_demask[14][7], qr_demask[13][8], qr_demask[13][7], qr_demask[12][8]};
    codeword_origin_next[38] = {qr_demask[16-4][7], qr_demask[15-4][8], qr_demask[15-4][7], qr_demask[14-4][8], qr_demask[14-4][7], qr_demask[13-4][8], qr_demask[13-4][7], qr_demask[9][5]};

    codeword_origin_next[39] = {qr_demask[0+8+1][9-5], qr_demask[1+8+1][10-5], qr_demask[1+8+1][9-5], qr_demask[2+8+1][10-5], qr_demask[2+8+1][9-5], qr_demask[3+8+1][10-5], qr_demask[3+8+1][9-5], qr_demask[4+8+1][10-5]};
    codeword_origin_next[40] = {qr_demask[0+8+1+4][9-5], qr_demask[1+8+1+4][10-5], qr_demask[1+8+1+4][9-5], qr_demask[2+8+1+4][10-5], qr_demask[2+8+1+4][9-5], qr_demask[3+8+1+4][10-5], qr_demask[3+8+1+4][9-5], qr_demask[16][3]};

    codeword_origin_next[41] = {qr_demask[16][7-5], qr_demask[15][8-5], qr_demask[15][7-5], qr_demask[14][8-5], qr_demask[14][7-5], qr_demask[13][8-5], qr_demask[13][7-5], qr_demask[12][8-5]};
    codeword_origin_next[42] = {qr_demask[16-4][7-5], qr_demask[15-4][8-5], qr_demask[15-4][7-5], qr_demask[14-4][8-5], qr_demask[14-4][7-5], qr_demask[13-4][8-5], qr_demask[13-4][7-5], qr_demask[9][1]};

    codeword_origin_next[43] = {qr_demask[0+8+1][9-5-4], qr_demask[1+8+1][10-5-4], qr_demask[1+8+1][9-5-4], qr_demask[2+8+1][10-5-4], qr_demask[2+8+1][9-5-4], qr_demask[3+8+1][10-5-4], qr_demask[3+8+1][9-5-4], qr_demask[4+8+1][10-5-4]};
end

// set decode_cnt_n
always @* begin
    if (state == DECODE) begin
        decode_cnt_n = decode_cnt + 1;
    end
    else begin
        decode_cnt_n = decode_cnt;
    end
end




// set text length
always @* begin
    text_length = {codeword_origin[0][3], codeword_origin[0][2], codeword_origin[0][1], codeword_origin[0][0], codeword_origin[1][7], codeword_origin[1][6], codeword_origin[1][5], codeword_origin[1][4]};
end

// set s_cnt_next
always @* begin
    if (state == CAL_S) begin
        s_cnt_next = s_cnt + 1;
    end
    else begin
        s_cnt_next = s_cnt;
    end
end


// calculate S0_mul_pw ~ S7_mul_pw
always @* begin
    // if (state == CAL_S) begin
    S0_temp_pw = 0;
    S1_temp_pw = ((43 - s_cnt) * 1) % 255;
    S2_temp_pw = ((43 - s_cnt) * 2) % 255;
    S3_temp_pw = ((43 - s_cnt) * 3) % 255;
    S4_temp_pw = ((43 - s_cnt) * 4) % 255;
    S5_temp_pw = ((43 - s_cnt) * 5) % 255;
    S6_temp_pw = ((43 - s_cnt) * 6) % 255;
    S7_temp_pw = ((43 - s_cnt) * 7) % 255;

    S0_mul_pw = (pw_origin[s_cnt] + S0_temp_pw) % 255;
    S1_mul_pw = (pw_origin[s_cnt] + S1_temp_pw) % 255;
    S2_mul_pw = (pw_origin[s_cnt] + S2_temp_pw) % 255;
    S3_mul_pw = (pw_origin[s_cnt] + S3_temp_pw) % 255;
    S4_mul_pw = (pw_origin[s_cnt] + S4_temp_pw) % 255;
    S5_mul_pw = (pw_origin[s_cnt] + S5_temp_pw) % 255;
    S6_mul_pw = (pw_origin[s_cnt] + S6_temp_pw) % 255;
    S7_mul_pw = (pw_origin[s_cnt] + S7_temp_pw) % 255;

end


// set S0_num_next ~ S7_mul_next
always @* begin
    if (state == CAL_S) begin
        S0_num_next = S0_num ^ S0_mul_num;
        S1_num_next = S1_num ^ S1_mul_num;
        S2_num_next = S2_num ^ S2_mul_num;
        S3_num_next = S3_num ^ S3_mul_num;
        S4_num_next = S4_num ^ S4_mul_num;
        S5_num_next = S5_num ^ S5_mul_num;
        S6_num_next = S6_num ^ S6_mul_num;
        S7_num_next = S7_num ^ S7_mul_num;
    end
    else begin
        S0_num_next = S0_num;
        S1_num_next = S1_num;
        S2_num_next = S2_num;
        S3_num_next = S3_num;
        S4_num_next = S4_num;
        S5_num_next = S5_num;
        S6_num_next = S6_num;
        S7_num_next = S7_num;
    end
end

// set coeff. of eq1 ~ eq4
always @* begin
    eq1_sigma4_num_next = S0_num;
    eq1_sigma3_num_next = S1_num;
    eq1_sigma2_num_next = S2_num;
    eq1_sigma1_num_next = S3_num;
    eq1_const_num_next = S4_num;

    eq2_sigma4_num_next = S1_num;
    eq2_sigma3_num_next = S2_num;
    eq2_sigma2_num_next = S3_num;
    eq2_sigma1_num_next = S4_num;
    eq2_const_num_next = S5_num;

    eq3_sigma4_num_next = S2_num;
    eq3_sigma3_num_next = S3_num;
    eq3_sigma2_num_next = S4_num;
    eq3_sigma1_num_next = S5_num;
    eq3_const_num_next = S6_num;

    eq4_sigma4_num_next = S3_num;
    eq4_sigma3_num_next = S4_num;
    eq4_sigma2_num_next = S5_num;
    eq4_sigma1_num_next = S6_num;
    eq4_const_num_next = S7_num;
end

// set eq_cnt_next
always @* begin
    if (state == CAL_COEFF) begin
        eq_cnt_next = eq_cnt + 1;
    end
    else begin
        eq_cnt_next = eq_cnt;
    end
end


// calc eq5 temp pw
always @* begin
    eq5_elim_pw = eq2_sigma4_pw > eq1_sigma4_pw ? eq2_sigma4_pw - eq1_sigma4_pw : eq1_sigma4_pw - eq2_sigma4_pw;
    if (eq2_sigma4_pw > eq1_sigma4_pw) begin
        eq5_temp3_pw = (eq1_sigma3_pw + eq5_elim_pw) % 255;
        eq5_temp2_pw = (eq1_sigma2_pw + eq5_elim_pw) % 255;
        eq5_temp1_pw = (eq1_sigma1_pw + eq5_elim_pw) % 255;
        eq5_temp_const_pw = (eq1_const_pw + eq5_elim_pw) % 255;
    end
    else begin
        eq5_temp3_pw = (eq2_sigma3_pw + eq5_elim_pw) % 255;
        eq5_temp2_pw = (eq2_sigma2_pw + eq5_elim_pw) % 255;
        eq5_temp1_pw = (eq2_sigma1_pw + eq5_elim_pw) % 255;
        eq5_temp_const_pw = (eq2_const_pw + eq5_elim_pw) % 255;
    end
end

// calc eq5 num_next
always @* begin
    if (eq_cnt == 1 && eq2_sigma4_pw > eq1_sigma4_pw) begin
        eq5_sigma3_num_next = eq5_temp3_num ^ eq2_sigma3_num;
        eq5_sigma2_num_next = eq5_temp2_num ^ eq2_sigma2_num;
        eq5_sigma1_num_next = eq5_temp1_num ^ eq2_sigma1_num;
        eq5_const_num_next = eq5_temp_const_num ^ eq2_const_num;
    end
    else if (eq_cnt == 1 && eq2_sigma4_pw <= eq1_sigma4_pw) begin
        eq5_sigma3_num_next = eq5_temp3_num ^ eq1_sigma3_num;
        eq5_sigma2_num_next = eq5_temp2_num ^ eq1_sigma2_num;
        eq5_sigma1_num_next = eq5_temp1_num ^ eq1_sigma1_num;
        eq5_const_num_next = eq5_temp_const_num ^ eq1_const_num;
    end
    else begin
        eq5_sigma3_num_next = eq5_sigma3_num;
        eq5_sigma2_num_next = eq5_sigma2_num;
        eq5_sigma1_num_next = eq5_sigma1_num;
        eq5_const_num_next = eq5_const_num;
    end
end


// calc eq6 temp pw
always @* begin
    eq6_elim_pw = eq2_sigma4_pw > eq3_sigma4_pw ? eq2_sigma4_pw - eq3_sigma4_pw : eq3_sigma4_pw - eq2_sigma4_pw;
    if (eq2_sigma4_pw > eq3_sigma4_pw) begin
        eq6_temp3_pw = (eq3_sigma3_pw + eq6_elim_pw) % 255;
        eq6_temp2_pw = (eq3_sigma2_pw + eq6_elim_pw) % 255;
        eq6_temp1_pw = (eq3_sigma1_pw + eq6_elim_pw) % 255;
        eq6_temp_const_pw = (eq3_const_pw + eq6_elim_pw) % 255;
        
    end
    else begin
        eq6_temp3_pw = (eq2_sigma3_pw + eq6_elim_pw) % 255;
        eq6_temp2_pw = (eq2_sigma2_pw + eq6_elim_pw) % 255;
        eq6_temp1_pw = (eq2_sigma1_pw + eq6_elim_pw) % 255;
        eq6_temp_const_pw = (eq2_const_pw + eq6_elim_pw) % 255;
        
    end
end

// calc eq6 num_next
always @* begin
    if (eq_cnt == 2 && eq2_sigma4_pw > eq3_sigma4_pw) begin
        eq6_sigma3_num_next = eq6_temp3_num ^ eq2_sigma3_num;
        eq6_sigma2_num_next = eq6_temp2_num ^ eq2_sigma2_num;
        eq6_sigma1_num_next = eq6_temp1_num ^ eq2_sigma1_num;
        eq6_const_num_next = eq6_temp_const_num ^ eq2_const_num;
    end
    else if (eq_cnt == 2 && eq2_sigma4_pw <= eq3_sigma4_pw) begin
        eq6_sigma3_num_next = eq6_temp3_num ^ eq3_sigma3_num;
        eq6_sigma2_num_next = eq6_temp2_num ^ eq3_sigma2_num;
        eq6_sigma1_num_next = eq6_temp1_num ^ eq3_sigma1_num;
        eq6_const_num_next = eq6_temp_const_num ^ eq3_const_num;
    end
    else begin
        eq6_sigma3_num_next = eq6_sigma3_num;
        eq6_sigma2_num_next = eq6_sigma2_num;
        eq6_sigma1_num_next = eq6_sigma1_num;
        eq6_const_num_next = eq6_const_num;
    end
end

// calc eq7 temp pw
always @* begin
    eq7_elim_pw = eq4_sigma4_pw > eq3_sigma4_pw ? eq4_sigma4_pw - eq3_sigma4_pw : eq3_sigma4_pw - eq4_sigma4_pw;
    if (eq4_sigma4_pw > eq3_sigma4_pw) begin
        eq7_temp3_pw = (eq3_sigma3_pw + eq7_elim_pw) % 255;
        eq7_temp2_pw = (eq3_sigma2_pw + eq7_elim_pw) % 255;
        eq7_temp1_pw = (eq3_sigma1_pw + eq7_elim_pw) % 255;
        eq7_temp_const_pw = (eq3_const_pw + eq7_elim_pw) % 255;
    end
    else begin
        eq7_temp3_pw = (eq4_sigma3_pw + eq7_elim_pw) % 255;
        eq7_temp2_pw = (eq4_sigma2_pw + eq7_elim_pw) % 255;
        eq7_temp1_pw = (eq4_sigma1_pw + eq7_elim_pw) % 255;
        eq7_temp_const_pw = (eq4_const_pw + eq7_elim_pw) % 255;
    end
end

// calc eq7 num_next
always @* begin
    if (eq_cnt == 3 && eq4_sigma4_pw > eq3_sigma4_pw) begin
        eq7_sigma3_num_next = eq7_temp3_num ^ eq4_sigma3_num;
        eq7_sigma2_num_next = eq7_temp2_num ^ eq4_sigma2_num;
        eq7_sigma1_num_next = eq7_temp1_num ^ eq4_sigma1_num;
        eq7_const_num_next = eq7_temp_const_num ^ eq4_const_num;
    end
    else if (eq_cnt == 3 && eq4_sigma4_pw <= eq3_sigma4_pw) begin
        eq7_sigma3_num_next = eq7_temp3_num ^ eq3_sigma3_num;
        eq7_sigma2_num_next = eq7_temp2_num ^ eq3_sigma2_num;
        eq7_sigma1_num_next = eq7_temp1_num ^ eq3_sigma1_num;
        eq7_const_num_next = eq7_temp_const_num ^ eq3_const_num;
    end
    else begin
        eq7_sigma3_num_next = eq7_sigma3_num;
        eq7_sigma2_num_next = eq7_sigma2_num;
        eq7_sigma1_num_next = eq7_sigma1_num;
        eq7_const_num_next = eq7_const_num;
    end
end


// calc eq8 temp pw
always @* begin
    eq8_elim_pw = eq5_sigma3_pw > eq6_sigma3_pw ? eq5_sigma3_pw - eq6_sigma3_pw : eq6_sigma3_pw - eq5_sigma3_pw;

    if (eq5_sigma3_pw > eq6_sigma3_pw) begin
        eq8_temp2_pw = (eq6_sigma2_pw + eq8_elim_pw) % 255;
        eq8_temp1_pw = (eq6_sigma1_pw + eq8_elim_pw) % 255;
        eq8_temp_const_pw = (eq6_const_pw + eq8_elim_pw) % 255;
    end
    else begin
        eq8_temp2_pw = (eq5_sigma2_pw + eq8_elim_pw) % 255;
        eq8_temp1_pw = (eq5_sigma1_pw + eq8_elim_pw) % 255;
        eq8_temp_const_pw = (eq5_const_pw + eq8_elim_pw) % 255;
    end
end

// calc eq8 num_next
always @* begin
    if (eq_cnt == 4 && eq5_sigma3_pw > eq6_sigma3_pw) begin
        eq8_sigma2_num_next = eq8_temp2_num ^ eq5_sigma2_num;
        eq8_sigma1_num_next = eq8_temp1_num ^ eq5_sigma1_num;
        eq8_const_num_next = eq8_temp_const_num ^ eq5_const_num;
    end
    // fucking "else if" statement in the next line became "if" magically, which wasted me 2 hrs== 7414!
    else if (eq_cnt == 4 && eq5_sigma3_pw <= eq6_sigma3_pw) begin   
        eq8_sigma2_num_next = eq8_temp2_num ^ eq6_sigma2_num;
        eq8_sigma1_num_next = eq8_temp1_num ^ eq6_sigma1_num;
        eq8_const_num_next = eq8_temp_const_num ^ eq6_const_num;
    end
    else begin
        eq8_sigma2_num_next = eq8_sigma2_num;
        eq8_sigma1_num_next = eq8_sigma1_num;
        eq8_const_num_next = eq8_const_num;
    end
end


// calc eq9 temp pw
always @* begin
    eq9_elim_pw = eq7_sigma3_pw > eq6_sigma3_pw ? eq7_sigma3_pw - eq6_sigma3_pw : eq6_sigma3_pw - eq7_sigma3_pw;
    if (eq7_sigma3_pw > eq6_sigma3_pw) begin
        eq9_temp2_pw = (eq6_sigma2_pw + eq9_elim_pw) % 255;
        eq9_temp1_pw = (eq6_sigma1_pw + eq9_elim_pw) % 255;
        eq9_temp_const_pw = (eq6_const_pw + eq9_elim_pw) % 255;
    end
    else begin
        eq9_temp2_pw = (eq7_sigma2_pw + eq9_elim_pw) % 255;
        eq9_temp1_pw = (eq7_sigma1_pw + eq9_elim_pw) % 255;
        eq9_temp_const_pw = (eq7_const_pw + eq9_elim_pw) % 255;
    end
end

// calc eq9 num_next
always @* begin
    if (eq_cnt == 5 && eq7_sigma3_pw > eq6_sigma3_pw) begin
        eq9_sigma2_num_next = eq9_temp2_num ^ eq7_sigma2_num;
        eq9_sigma1_num_next = eq9_temp1_num ^ eq7_sigma1_num;
        eq9_const_num_next = eq9_temp_const_num ^ eq7_const_num;
    end
    else if (eq_cnt == 5 && eq7_sigma3_pw <= eq6_sigma3_pw) begin
        eq9_sigma2_num_next = eq9_temp2_num ^ eq6_sigma2_num;
        eq9_sigma1_num_next = eq9_temp1_num ^ eq6_sigma1_num;
        eq9_const_num_next = eq9_temp_const_num ^ eq6_const_num;
    end
    else begin
        eq9_sigma2_num_next = eq9_sigma2_num;
        eq9_sigma1_num_next = eq9_sigma1_num;
        eq9_const_num_next = eq9_const_num;
    end
end


// calc eq10 temp pw
always @* begin
    eq10_elim_pw = eq8_sigma2_pw > eq9_sigma2_pw ? eq8_sigma2_pw - eq9_sigma2_pw : eq9_sigma2_pw - eq8_sigma2_pw;
    if (eq8_sigma2_pw > eq9_sigma2_pw) begin
        eq10_temp1_pw = (eq9_sigma1_pw + eq10_elim_pw) % 255;
        eq10_temp_const_pw = (eq9_const_pw + eq10_elim_pw) % 255;
    end
    else begin
        eq10_temp1_pw = (eq8_sigma1_pw + eq10_elim_pw) % 255;
        eq10_temp_const_pw = (eq8_const_pw + eq10_elim_pw) % 255;
    end
end

// calc eq10 num_next
always @* begin
    if (eq_cnt == 6 && eq8_sigma2_pw > eq9_sigma2_pw) begin
        eq10_sigma1_num_next = eq10_temp1_num ^ eq8_sigma1_num;
        eq10_const_num_next = eq10_temp_const_num ^ eq8_const_num;
    end
    else if (eq_cnt == 6 && eq8_sigma2_pw <= eq9_sigma2_pw) begin
        eq10_sigma1_num_next = eq10_temp1_num ^ eq9_sigma1_num;
        eq10_const_num_next = eq10_temp_const_num ^ eq9_const_num;
    end
    else begin
        eq10_sigma1_num_next = eq10_sigma1_num;
        eq10_const_num_next = eq10_const_num;
    end
end


// set counter for SOLVE_SIGMA state
always @* begin
    if (state == SOLVE_SIGMA) begin
        solve_sigma_cnt_next = solve_sigma_cnt + 1;
    end
    else begin
        solve_sigma_cnt_next = solve_sigma_cnt;
    end
end


// set sum1_pw ~ sum6_pw
always @* begin
    sum1_pw = (eq8_sigma1_pw + sigma1_pw) % 255;
    sum2_pw = (eq5_sigma2_pw + sigma2_pw) % 255;
    sum3_pw = (eq5_sigma1_pw + sigma1_pw) % 255;
    sum4_pw = (eq1_sigma3_pw + sigma3_pw) % 255;
    sum5_pw = (eq1_sigma2_pw + sigma2_pw) % 255;
    sum6_pw = (eq1_sigma1_pw + sigma1_pw) % 255;
end


// set right_num
always @* begin
    case (solve_sigma_cnt)
        5'd1: right_num = eq10_const_num;
        5'd2: right_num = sum1_num ^ eq8_const_num;
        5'd3: right_num = sum2_num ^ sum3_num ^ eq5_const_num;
        5'd4: right_num = sum4_num ^ sum5_num ^ sum6_num ^ eq1_const_num;
        default: right_num = eq10_const_num;
    endcase
end

// set sigma1_pw_next
always @* begin
    if (state == SOLVE_SIGMA && solve_sigma_cnt == 1) begin
        sigma1_pw_next = eq10_sigma1_pw > right_pw ? (255 + right_pw - eq10_sigma1_pw) : (right_pw - eq10_sigma1_pw);
    end
    else begin
        sigma1_pw_next = sigma1_pw;
    end
end

// set sigma2_pw_next
always @* begin
    if (state == SOLVE_SIGMA && solve_sigma_cnt == 2) begin
        sigma2_pw_next = eq8_sigma2_pw > right_pw ? (255 + right_pw - eq8_sigma2_pw) : (right_pw - eq8_sigma2_pw);
    end
    else begin
        sigma2_pw_next = sigma2_pw;
    end
end

// set sigma3_pw_next
always @* begin
    if (state == SOLVE_SIGMA && solve_sigma_cnt == 3) begin
        sigma3_pw_next = eq5_sigma3_pw > right_pw ? (255 + right_pw - eq5_sigma3_pw) : (right_pw - eq5_sigma3_pw);
    end
    else begin
        sigma3_pw_next = sigma3_pw;
    end
end

// set sigma4_pw_next
always @* begin
    if (state == SOLVE_SIGMA && solve_sigma_cnt == 4) begin
        sigma4_pw_next = eq1_sigma4_pw > right_pw ? (255 + right_pw - eq1_sigma4_pw) : (right_pw - eq1_sigma4_pw);
    end
    else begin
        sigma4_pw_next = sigma4_pw;
    end
end

// calculate coeff. of sigma function and sigma_func(i) 
always @* begin
    sigma_func0_pw = sigma4_pw;
    sigma_func1_pw = (sigma3_pw + (solve_i_cnt - 1)) % 255;
    sigma_func2_pw = (sigma2_pw + (solve_i_cnt - 1) * 2) % 255;
    sigma_func3_pw = (sigma1_pw + (solve_i_cnt - 1) * 3) % 255;
    sigma_func4_pw = ((solve_i_cnt - 1) * 4) % 255;
    sigma_func_value = sigma_func0_num ^ sigma_func1_num ^ sigma_func2_num ^ sigma_func3_num ^ sigma_func4_num;
end

// set solve_i_cnt_next
always @* begin
    if (state == SOLVE_I) begin
        solve_i_cnt_next = solve_i_cnt + 1;
    end
    else begin
        solve_i_cnt_next = solve_i_cnt;
    end
end

// write down i value to i_sol when sigma_func(i) == 0
always @* begin
    // 4 lines to avoid latch
    i_sol1_next = i_sol1;
    i_sol2_next = i_sol2;
    i_sol3_next = i_sol3;
    i_sol4_next = i_sol4;
    if (sigma_func_value == 0) begin
        if (i_sol4 == 50) begin
            i_sol4_next = solve_i_cnt - 1;
        end
        else if (i_sol3 == 50) begin
            i_sol3_next = solve_i_cnt - 1;
        end
        else if (i_sol2 == 50) begin
            i_sol2_next = solve_i_cnt - 1;
        end
        else begin
            i_sol1_next = solve_i_cnt - 1;
        end
    end
end

// set the counter of y coeff. counter
always @* begin
    if (state == CAL_COEFF_Y) begin
        y_coeff_cnt_next = y_coeff_cnt + 1;
    end
    else begin
        y_coeff_cnt_next = y_coeff_cnt;
    end
end

// set coeff pw of eq11 ~ eq14
always @* begin
    if (i_sol1 == 50) begin     // fucking special case
        eq11_Y1_pw = (i_sol1 * 1) % 255;
        eq11_Y2_pw = (i_sol2 * 1) % 255;
        eq11_Y3_pw = (i_sol3 * 1) % 255;
        eq11_Y4_pw = (i_sol4 * 1) % 255;
        eq11_const_pw = S0_pw;
        eq12_Y1_pw = (i_sol1 * 1) % 255;
        eq12_Y2_pw = (i_sol2 * 2) % 255;
        eq12_Y3_pw = (i_sol3 * 2) % 255;
        eq12_Y4_pw = (i_sol4 * 2) % 255;
        eq12_const_pw = S1_pw;
        eq13_Y1_pw = (i_sol1 * 1) % 255;
        eq13_Y2_pw = (i_sol2 * 3) % 255;
        eq13_Y3_pw = (i_sol3 * 3) % 255;
        eq13_Y4_pw = (i_sol4 * 3) % 255;
        eq13_const_pw = S2_pw;
        eq14_Y1_pw = (i_sol1 * 1) % 255;
        eq14_Y2_pw = (i_sol2 * 4) % 255;
        eq14_Y3_pw = (i_sol3 * 4) % 255;
        eq14_Y4_pw = (i_sol4 * 4) % 255;
        eq14_const_pw = S3_pw;
    end
    else begin
        eq11_Y1_pw = (i_sol1 * 1) % 255;
        eq11_Y2_pw = (i_sol2 * 1) % 255;
        eq11_Y3_pw = (i_sol3 * 1) % 255;
        eq11_Y4_pw = (i_sol4 * 1) % 255;
        eq11_const_pw = S0_pw;
        eq12_Y1_pw = (i_sol1 * 2) % 255;
        eq12_Y2_pw = (i_sol2 * 2) % 255;
        eq12_Y3_pw = (i_sol3 * 2) % 255;
        eq12_Y4_pw = (i_sol4 * 2) % 255;
        eq12_const_pw = S1_pw;
        eq13_Y1_pw = (i_sol1 * 3) % 255;
        eq13_Y2_pw = (i_sol2 * 3) % 255;
        eq13_Y3_pw = (i_sol3 * 3) % 255;
        eq13_Y4_pw = (i_sol4 * 3) % 255;
        eq13_const_pw = S2_pw;
        eq14_Y1_pw = (i_sol1 * 4) % 255;
        eq14_Y2_pw = (i_sol2 * 4) % 255;
        eq14_Y3_pw = (i_sol3 * 4) % 255;
        eq14_Y4_pw = (i_sol4 * 4) % 255;
        eq14_const_pw = S3_pw;
    end
end

// set coeff. of eq11 ~ eq14
always @* begin
    eq11_Y2_num_next = eq11_Y2_num_w;
    eq11_Y3_num_next = eq11_Y3_num_w;
    eq11_Y4_num_next = eq11_Y4_num_w;
    eq11_const_num_next = eq11_const_num_w;
    eq12_Y2_num_next = eq12_Y2_num_w;
    eq12_Y3_num_next = eq12_Y3_num_w;
    eq12_Y4_num_next = eq12_Y4_num_w;
    eq12_const_num_next = eq12_const_num_w;
    eq13_Y2_num_next = eq13_Y2_num_w;
    eq13_Y3_num_next = eq13_Y3_num_w;
    eq13_Y4_num_next = eq13_Y4_num_w;
    eq13_const_num_next = eq13_const_num_w;
    eq14_Y2_num_next = eq14_Y2_num_w;
    eq14_Y3_num_next = eq14_Y3_num_w;
    eq14_Y4_num_next = eq14_Y4_num_w;
    eq14_const_num_next = eq14_const_num_w;
end

// calc eq15 temp pw
always @* begin
    eq15_elim_pw = eq12_Y1_pw > eq11_Y1_pw ? eq12_Y1_pw - eq11_Y1_pw : eq11_Y1_pw - eq12_Y1_pw;
    if (eq12_Y1_pw > eq11_Y1_pw) begin
        eq15_tempY2_pw = (eq11_Y2_pw + eq15_elim_pw) % 255;
        eq15_tempY3_pw = (eq11_Y3_pw + eq15_elim_pw) % 255;
        eq15_tempY4_pw = (eq11_Y4_pw + eq15_elim_pw) % 255;
        eq15_temp_const_pw = (eq11_const_pw + eq15_elim_pw) % 255;
    end
    else begin
        eq15_tempY2_pw = (eq12_Y2_pw + eq15_elim_pw) % 255;
        eq15_tempY3_pw = (eq12_Y3_pw + eq15_elim_pw) % 255;
        eq15_tempY4_pw = (eq12_Y4_pw + eq15_elim_pw) % 255;
        eq15_temp_const_pw = (eq12_const_pw + eq15_elim_pw) % 255;
    end
end

// calc eq15 num_next
always @* begin
    if (y_coeff_cnt == 1 && eq12_Y1_pw > eq11_Y1_pw) begin
        eq15_Y2_num_next = eq15_tempY2_num ^ eq12_Y2_num;
        eq15_Y3_num_next = eq15_tempY3_num ^ eq12_Y3_num;
        eq15_Y4_num_next = eq15_tempY4_num ^ eq12_Y4_num;
        eq15_const_num_next = eq15_temp_const_num ^ eq12_const_num;
    end
    else if (y_coeff_cnt == 1 && eq12_Y1_pw <= eq11_Y1_pw) begin
        eq15_Y2_num_next = eq15_tempY2_num ^ eq11_Y2_num;
        eq15_Y3_num_next = eq15_tempY3_num ^ eq11_Y3_num;
        eq15_Y4_num_next = eq15_tempY4_num ^ eq11_Y4_num;
        eq15_const_num_next = eq15_temp_const_num ^ eq11_const_num;
    end
    else begin
        eq15_Y2_num_next = eq15_Y2_num;
        eq15_Y3_num_next = eq15_Y3_num;
        eq15_Y4_num_next = eq15_Y4_num;
        eq15_const_num_next = eq15_const_num;
    end
end

// calc eq16 temp pw
always @* begin
    eq16_elim_pw = eq12_Y1_pw > eq13_Y1_pw ? eq12_Y1_pw - eq13_Y1_pw : eq13_Y1_pw - eq12_Y1_pw;
    if (eq12_Y1_pw > eq13_Y1_pw) begin
        eq16_tempY2_pw = (eq13_Y2_pw + eq16_elim_pw) % 255;
        eq16_tempY3_pw = (eq13_Y3_pw + eq16_elim_pw) % 255;
        eq16_tempY4_pw = (eq13_Y4_pw + eq16_elim_pw) % 255;
        eq16_temp_const_pw = (eq13_const_pw + eq16_elim_pw) % 255;
    end
    else begin
        eq16_tempY2_pw = (eq12_Y2_pw + eq16_elim_pw) % 255;
        eq16_tempY3_pw = (eq12_Y3_pw + eq16_elim_pw) % 255;
        eq16_tempY4_pw = (eq12_Y4_pw + eq16_elim_pw) % 255;
        eq16_temp_const_pw = (eq12_const_pw + eq16_elim_pw) % 255;
    end
end

// calc eq16 num_next
always @* begin
    if (y_coeff_cnt == 2 && eq12_Y1_pw > eq13_Y1_pw) begin
        eq16_Y2_num_next = eq16_tempY2_num ^ eq12_Y2_num;
        eq16_Y3_num_next = eq16_tempY3_num ^ eq12_Y3_num;
        eq16_Y4_num_next = eq16_tempY4_num ^ eq12_Y4_num;
        eq16_const_num_next = eq16_temp_const_num ^ eq12_const_num;
    end
    else if (y_coeff_cnt == 2 && eq12_Y1_pw <= eq13_Y1_pw) begin
        eq16_Y2_num_next = eq16_tempY2_num ^ eq13_Y2_num;
        eq16_Y3_num_next = eq16_tempY3_num ^ eq13_Y3_num;
        eq16_Y4_num_next = eq16_tempY4_num ^ eq13_Y4_num;
        eq16_const_num_next = eq16_temp_const_num ^ eq13_const_num;
    end
    else begin
        eq16_Y2_num_next = eq16_Y2_num;
        eq16_Y3_num_next = eq16_Y3_num;
        eq16_Y4_num_next = eq16_Y4_num;
        eq16_const_num_next = eq16_const_num;
    end
end

// calc eq17 temp pw
always @* begin
    eq17_elim_pw = eq14_Y1_pw > eq13_Y1_pw ? eq14_Y1_pw - eq13_Y1_pw : eq13_Y1_pw - eq14_Y1_pw;
    if (eq14_Y1_pw > eq13_Y1_pw) begin
        eq17_tempY2_pw = (eq13_Y2_pw + eq17_elim_pw) % 255;
        eq17_tempY3_pw = (eq13_Y3_pw + eq17_elim_pw) % 255;
        eq17_tempY4_pw = (eq13_Y4_pw + eq17_elim_pw) % 255;
        eq17_temp_const_pw = (eq13_const_pw + eq17_elim_pw) % 255;
    end
    else begin
        eq17_tempY2_pw = (eq14_Y2_pw + eq17_elim_pw) % 255;
        eq17_tempY3_pw = (eq14_Y3_pw + eq17_elim_pw) % 255;
        eq17_tempY4_pw = (eq14_Y4_pw + eq17_elim_pw) % 255;
        eq17_temp_const_pw = (eq14_const_pw + eq17_elim_pw) % 255;
    end
end

// calc eq17 num_next
always @* begin
    if (y_coeff_cnt == 3 && eq14_Y1_pw > eq13_Y1_pw) begin
        eq17_Y2_num_next = eq17_tempY2_num ^ eq14_Y2_num;
        eq17_Y3_num_next = eq17_tempY3_num ^ eq14_Y3_num;
        eq17_Y4_num_next = eq17_tempY4_num ^ eq14_Y4_num;
        eq17_const_num_next = eq17_temp_const_num ^ eq14_const_num;
    end
    else if (y_coeff_cnt == 3 && eq14_Y1_pw <= eq13_Y1_pw) begin
        eq17_Y2_num_next = eq17_tempY2_num ^ eq13_Y2_num;
        eq17_Y3_num_next = eq17_tempY3_num ^ eq13_Y3_num;
        eq17_Y4_num_next = eq17_tempY4_num ^ eq13_Y4_num;
        eq17_const_num_next = eq17_temp_const_num ^ eq13_const_num;
    end
    else begin
        eq17_Y2_num_next = eq17_Y2_num;
        eq17_Y3_num_next = eq17_Y3_num;
        eq17_Y4_num_next = eq17_Y4_num;
        eq17_const_num_next = eq17_const_num;
    end
end

// calc eq18 temp pw
always @* begin
    eq18_elim_pw = eq16_Y2_pw > eq15_Y2_pw ? eq16_Y2_pw - eq15_Y2_pw : eq15_Y2_pw - eq16_Y2_pw;
    if (eq16_Y2_pw > eq15_Y2_pw) begin
        eq18_tempY3_pw = (eq15_Y3_pw + eq18_elim_pw) % 255;
        eq18_tempY4_pw = (eq15_Y4_pw + eq18_elim_pw) % 255;
        eq18_temp_const_pw = (eq15_const_pw + eq18_elim_pw) % 255;
    end
    else begin
        eq18_tempY3_pw = (eq16_Y3_pw + eq18_elim_pw) % 255;
        eq18_tempY4_pw = (eq16_Y4_pw + eq18_elim_pw) % 255;
        eq18_temp_const_pw = (eq16_const_pw + eq18_elim_pw) % 255;
    end
end

// calc eq18 num_next
always @* begin
    if (y_coeff_cnt == 4 && eq16_Y2_pw > eq15_Y2_pw) begin
        eq18_Y3_num_next = eq18_tempY3_num ^ eq16_Y3_num;
        eq18_Y4_num_next = eq18_tempY4_num ^ eq16_Y4_num;
        eq18_const_num_next = eq18_temp_const_num ^ eq16_const_num;
    end
    else if (y_coeff_cnt == 4 && eq16_Y2_pw <= eq15_Y2_pw) begin
        eq18_Y3_num_next = eq18_tempY3_num ^ eq15_Y3_num;
        eq18_Y4_num_next = eq18_tempY4_num ^ eq15_Y4_num;
        eq18_const_num_next = eq18_temp_const_num ^ eq15_const_num;
    end
    else begin
        eq18_Y3_num_next = eq18_Y3_num;
        eq18_Y4_num_next = eq18_Y4_num;
        eq18_const_num_next = eq18_const_num;
    end
end


// calc eq19 temp pw
always @* begin
    eq19_elim_pw = eq16_Y2_pw > eq17_Y2_pw ? eq16_Y2_pw - eq17_Y2_pw : eq17_Y2_pw - eq16_Y2_pw;
    if (eq16_Y2_pw > eq17_Y2_pw) begin
        eq19_tempY3_pw = (eq17_Y3_pw + eq19_elim_pw) % 255;
        eq19_tempY4_pw = (eq17_Y4_pw + eq19_elim_pw) % 255;
        eq19_temp_const_pw = (eq17_const_pw + eq19_elim_pw) % 255;
    end
    else begin
        eq19_tempY3_pw = (eq16_Y3_pw + eq19_elim_pw) % 255;
        eq19_tempY4_pw = (eq16_Y4_pw + eq19_elim_pw) % 255;
        eq19_temp_const_pw = (eq16_const_pw + eq19_elim_pw) % 255;
    end
end

// calc eq19 num_next
always @* begin
    if (y_coeff_cnt == 5 && eq16_Y2_pw > eq17_Y2_pw) begin
        eq19_Y3_num_next = eq19_tempY3_num ^ eq16_Y3_num;
        eq19_Y4_num_next = eq19_tempY4_num ^ eq16_Y4_num;
        eq19_const_num_next = eq19_temp_const_num ^ eq16_const_num;
    end
    else if (y_coeff_cnt == 5 && eq16_Y2_pw <= eq17_Y2_pw) begin
        eq19_Y3_num_next = eq19_tempY3_num ^ eq17_Y3_num;
        eq19_Y4_num_next = eq19_tempY4_num ^ eq17_Y4_num;
        eq19_const_num_next = eq19_temp_const_num ^ eq17_const_num;
    end
    else begin
        eq19_Y3_num_next = eq19_Y3_num;
        eq19_Y4_num_next = eq19_Y4_num;
        eq19_const_num_next = eq19_const_num;
    end
end


// calc eq20 temp pw
always @* begin
    eq20_elim_pw = eq18_Y3_pw > eq19_Y3_pw ? eq18_Y3_pw - eq19_Y3_pw : eq19_Y3_pw - eq18_Y3_pw;
    if (eq18_Y3_pw > eq19_Y3_pw) begin
        eq20_tempY4_pw = (eq19_Y4_pw + eq20_elim_pw) % 255;
        eq20_temp_const_pw = (eq19_const_pw + eq20_elim_pw) % 255;
    end
    else begin
        eq20_tempY4_pw = (eq18_Y4_pw + eq20_elim_pw) % 255;
        eq20_temp_const_pw = (eq18_const_pw + eq20_elim_pw) % 255;
    end
end

// calc eq20 num_next
always @* begin
    if (y_coeff_cnt == 6 && eq18_Y3_pw > eq19_Y3_pw) begin
        eq20_Y4_num_next = eq20_tempY4_num ^ eq18_Y4_num;
        eq20_const_num_next = eq20_temp_const_num ^ eq18_const_num;
    end
    else if (y_coeff_cnt == 6 && eq18_Y3_pw <= eq19_Y3_pw) begin
        eq20_Y4_num_next = eq20_tempY4_num ^ eq19_Y4_num;
        eq20_const_num_next = eq20_temp_const_num ^ eq19_const_num;
    end
    else begin
        eq20_Y4_num_next = eq20_Y4_num;
        eq20_const_num_next = eq20_const_num;
    end
end

// set solve y counter
always @* begin
    if (state == SOLVE_Y) begin
        solve_y_cnt_next = solve_y_cnt + 1;
    end
    else begin
        solve_y_cnt_next = solve_y_cnt;
    end
end

// set sum1_Y_pw ~ sum6_Y_pw
always @* begin
    sum1_Y_pw = (eq18_Y4_pw + Y4_pw) % 255;
    sum2_Y_pw = (eq15_Y3_pw + Y3_pw) % 255;
    sum3_Y_pw = (eq15_Y4_pw + Y4_pw) % 255;
    sum4_Y_pw = (eq11_Y2_pw + Y2_pw) % 255;
    sum5_Y_pw = (eq11_Y3_pw + Y3_pw) % 255;
    sum6_Y_pw = (eq11_Y4_pw + Y4_pw) % 255;
end

// set right Y num
always @* begin
    case (solve_y_cnt)
        5'd1: right_Y_num = eq20_const_num;
        5'd2: right_Y_num = sum1_Y_num ^ eq18_const_num;
        5'd3: right_Y_num = sum2_Y_num ^ sum3_Y_num ^ eq15_const_num;
        5'd4: right_Y_num = sum4_Y_num ^ sum5_Y_num ^ sum6_Y_num ^ eq11_const_num;
        default: right_Y_num = eq20_Y4_num;
    endcase
end


// set Y4_pw_next
always @* begin
    if (state == SOLVE_Y && solve_y_cnt == 1) begin
        Y4_pw_next = eq20_Y4_pw > right_Y_pw ? (255 + right_Y_pw - eq20_Y4_pw) : (right_Y_pw - eq20_Y4_pw);
    end
    else begin
        Y4_pw_next = Y4_pw;
    end
end


// set Y3_pw_next
always @* begin
    if (state == SOLVE_Y && solve_y_cnt == 2) begin
        Y3_pw_next = eq18_Y3_pw > right_Y_pw ? (255 + right_Y_pw - eq18_Y3_pw) : (right_Y_pw - eq18_Y3_pw);
    end
    else begin
        Y3_pw_next = Y3_pw;
    end
end

// set Y2_pw_next
always @* begin
    if (state == SOLVE_Y && solve_y_cnt == 3) begin
        Y2_pw_next = eq15_Y2_pw > right_Y_pw ? (255 + right_Y_pw - eq15_Y2_pw) : (right_Y_pw - eq15_Y2_pw);
    end
    else begin
        Y2_pw_next = Y2_pw;
    end
end

// set Y1_pw_next
always @* begin
    if (state == SOLVE_Y && solve_y_cnt == 4) begin
        Y1_pw_next = eq11_Y1_pw > right_Y_pw ? (255 + right_Y_pw - eq11_Y1_pw) : (right_Y_pw - eq11_Y1_pw);
    end
    else begin
        Y1_pw_next = Y1_pw;
    end
end

// set pw next
always @* begin
    if (state == CAL_OFFSET) begin
        Y1_offset_pw_next = (Y1_pw + i_sol1) % 255;
        Y2_offset_pw_next = (Y2_pw + i_sol2) % 255;
        Y3_offset_pw_next = (Y3_pw + i_sol3) % 255;
        Y4_offset_pw_next = (Y4_pw + i_sol4) % 255;
    end
    else begin
        Y1_offset_pw_next = Y1_offset_pw;
        Y2_offset_pw_next = Y2_offset_pw;
        Y3_offset_pw_next = Y3_offset_pw;
        Y4_offset_pw_next = Y4_offset_pw;
    end
end

// correct the fuck-up qrcode, set codeword_corrected_next
always @* begin
    for (i = 0; i < 44; i = i + 1) begin
        codeword_corrected_next[i] = codeword_origin[i];
    end
    if (i_sol1 != 50) begin
        codeword_corrected_next[43 - i_sol1] = codeword_origin[43 - i_sol1] ^ Y1_offset_num;
    end
    if (i_sol2 != 50) begin
        codeword_corrected_next[43 - i_sol2] = codeword_origin[43 - i_sol2] ^ Y2_offset_num;
    end
    if (i_sol3 != 50) begin
        codeword_corrected_next[43 - i_sol3] = codeword_origin[43 - i_sol3] ^ Y3_offset_num;
    end
    if (i_sol4 != 50) begin
        codeword_corrected_next[43 - i_sol4] = codeword_origin[43 - i_sol4] ^ Y4_offset_num;
    end
end

// set the counter for sending output
always @* begin 
    if (state == SEND_OUTPUT) begin
        send_output_cnt_next = send_output_cnt + 1;
    end
    else begin
        send_output_cnt_next = send_output_cnt;
    end
end

// set decode_valid_next
always @* begin
    if (state == SEND_OUTPUT) begin
        decode_valid_next = 1;
    end
    else begin
        decode_valid_next = 0;
    end
end

// set the value of reg [7:0] decode_jis8_code_next
always @* begin
    decode_jis8_code_next = {codeword_corrected[send_output_cnt + 1][3-:4], codeword_corrected[send_output_cnt + 2][7-:4]};
end

// set qr_decode_finish_next
always @* begin
    if (state == SEND_OUTPUT && send_output_cnt == text_length - 1) begin
        qr_decode_finish_next = 1;
    end
    else begin
        qr_decode_finish_next = 0;
    end
end

// FF
always @(posedge clk) begin
    if (~srstn) begin
        img_r <= 0;
        img_c <= 0;
        state <= IDLE;
        read_cnt <= 0;
        decode_cnt <= 0;
        for (i = 0; i < QR_LEN; i = i + 1) begin
            qr_in[i] <= 0;
        end
        for (i = 0; i < 44; i = i + 1) begin 
            codeword_origin[i] <= 0;
        end
        decode_jis8_code <= 0;
        decode_valid <= 0;
        s_cnt <= 0;
        S0_num <= 0;
        S1_num <= 0;
        S2_num <= 0;
        S3_num <= 0;
        S4_num <= 0;
        S5_num <= 0;
        S6_num <= 0;
        S7_num <= 0;
        eq_cnt <= 0;

        eq1_sigma4_num <= 0;
        eq1_sigma3_num <= 0;
        eq1_sigma2_num <= 0;
        eq1_sigma1_num <= 0;
        eq1_const_num <= 0;
        eq2_sigma4_num <= 0;
        eq2_sigma3_num <= 0;
        eq2_sigma2_num <= 0;
        eq2_sigma1_num <= 0;
        eq2_const_num <= 0;
        eq3_sigma4_num <= 0;
        eq3_sigma3_num <= 0;
        eq3_sigma2_num <= 0;
        eq3_sigma1_num <= 0;
        eq3_const_num <= 0;
        eq4_sigma4_num <= 0;
        eq4_sigma3_num <= 0;
        eq4_sigma2_num <= 0;
        eq4_sigma1_num <= 0;
        eq4_const_num <= 0;
        eq5_sigma3_num <= 0;
        eq5_sigma2_num <= 0;
        eq5_sigma1_num <= 0;
        eq5_const_num <= 0;
        eq6_sigma3_num <= 0;
        eq6_sigma2_num <= 0;
        eq6_sigma1_num <= 0;
        eq6_const_num <= 0;
        eq7_sigma3_num <= 0;
        eq7_sigma2_num <= 0;
        eq7_sigma1_num <= 0;
        eq7_const_num <= 0;
        eq8_sigma2_num <= 0;
        eq8_sigma1_num <= 0;
        eq8_const_num <= 0;
        eq9_sigma2_num <= 0;
        eq9_sigma1_num <= 0;
        eq9_const_num <= 0;
        eq10_sigma1_num <= 0;
        eq10_const_num <= 0;

        solve_sigma_cnt <= 0;

        sigma1_pw <= 0;
        sigma2_pw <= 0;
        sigma3_pw <= 0;
        sigma4_pw <= 0;

        solve_i_cnt <= 0;

        i_sol1 <= 50;
        i_sol2 <= 50;
        i_sol3 <= 50;
        i_sol4 <= 50;

        // eq11_Y1_num <= 0;
        eq11_Y2_num <= 0;
        eq11_Y3_num <= 0;
        eq11_Y4_num <= 0;
        eq11_const_num <= 0;
        // eq12_Y1_num <= 0;
        eq12_Y2_num <= 0;
        eq12_Y3_num <= 0;
        eq12_Y4_num <= 0;
        eq12_const_num <= 0;
        // eq13_Y1_num <= 0;
        eq13_Y2_num <= 0;
        eq13_Y3_num <= 0;
        eq13_Y4_num <= 0;
        eq13_const_num <= 0;
        // eq14_Y1_num <= 0;
        eq14_Y2_num <= 0;
        eq14_Y3_num <= 0;
        eq14_Y4_num <= 0;
        eq14_const_num <= 0;
        eq15_Y2_num <= 0;
        eq15_Y3_num <= 0;
        eq15_Y4_num <= 0;
        eq15_const_num <= 0;
        eq16_Y2_num <= 0;
        eq16_Y3_num <= 0;
        eq16_Y4_num <= 0;
        eq16_const_num <= 0;
        eq17_Y2_num <= 0;
        eq17_Y3_num <= 0;
        eq17_Y4_num <= 0;
        eq17_const_num <= 0;
        eq18_Y3_num <= 0;
        eq18_Y4_num <= 0;
        eq18_const_num <= 0;
        eq19_Y3_num <= 0;
        eq19_Y4_num <= 0;
        eq19_const_num <= 0;
        eq20_Y4_num <= 0;
        eq20_const_num <= 0;

        y_coeff_cnt <= 0;
        solve_y_cnt <= 0;

        Y1_pw <= 0;
        Y2_pw <= 0;
        Y3_pw <= 0;
        Y4_pw <= 0;

        Y1_offset_pw <= 0;
        Y2_offset_pw <= 0;
        Y3_offset_pw <= 0;
        Y4_offset_pw <= 0;

        send_output_cnt <= 0;
        qr_decode_finish <= 0;
        for (i = 0; i < 44; i = i + 1) begin 
            codeword_corrected[i] <= 0;
        end
        find_qrcode <= 0;
        first_r <= 0;
        first_c <= 0;


    end
    else begin
        img_r <= img_r_next;
        img_c <= img_c_next;
        state <= state_n;
        read_cnt <= read_cnt_n;
        decode_cnt <= decode_cnt_n;
        for (i = 0; i < QR_LEN; i = i + 1) begin
            qr_in[i] <= qr_in_next[i];
        end
        for (i = 0; i < 44; i = i + 1) begin 
            codeword_origin[i] <= codeword_origin_next[i];
        end
        decode_jis8_code <= decode_jis8_code_next;
        decode_valid <= decode_valid_next;
        s_cnt <= s_cnt_next;
        S0_num <= S0_num_next;
        S1_num <= S1_num_next;
        S2_num <= S2_num_next;
        S3_num <= S3_num_next;
        S4_num <= S4_num_next;
        S5_num <= S5_num_next;
        S6_num <= S6_num_next;
        S7_num <= S7_num_next;
        eq_cnt <= eq_cnt_next;

        eq1_sigma4_num <= eq1_sigma4_num_next;
        eq1_sigma3_num <= eq1_sigma3_num_next;
        eq1_sigma2_num <= eq1_sigma2_num_next;
        eq1_sigma1_num <= eq1_sigma1_num_next;
        eq1_const_num <= eq1_const_num_next;
        eq2_sigma4_num <= eq2_sigma4_num_next;
        eq2_sigma3_num <= eq2_sigma3_num_next;
        eq2_sigma2_num <= eq2_sigma2_num_next;
        eq2_sigma1_num <= eq2_sigma1_num_next;
        eq2_const_num <= eq2_const_num_next;
        eq3_sigma4_num <= eq3_sigma4_num_next;
        eq3_sigma3_num <= eq3_sigma3_num_next;
        eq3_sigma2_num <= eq3_sigma2_num_next;
        eq3_sigma1_num <= eq3_sigma1_num_next;
        eq3_const_num <= eq3_const_num_next;
        eq4_sigma4_num <= eq4_sigma4_num_next;
        eq4_sigma3_num <= eq4_sigma3_num_next;
        eq4_sigma2_num <= eq4_sigma2_num_next;
        eq4_sigma1_num <= eq4_sigma1_num_next;
        eq4_const_num <= eq4_const_num_next;
        eq5_sigma3_num <= eq5_sigma3_num_next;
        eq5_sigma2_num <= eq5_sigma2_num_next;
        eq5_sigma1_num <= eq5_sigma1_num_next;
        eq5_const_num <= eq5_const_num_next;
        eq6_sigma3_num <= eq6_sigma3_num_next;
        eq6_sigma2_num <= eq6_sigma2_num_next;
        eq6_sigma1_num <= eq6_sigma1_num_next;
        eq6_const_num <= eq6_const_num_next;
        eq7_sigma3_num <= eq7_sigma3_num_next;
        eq7_sigma2_num <= eq7_sigma2_num_next;
        eq7_sigma1_num <= eq7_sigma1_num_next;
        eq7_const_num <= eq7_const_num_next;
        eq8_sigma2_num <= eq8_sigma2_num_next;
        eq8_sigma1_num <= eq8_sigma1_num_next;
        eq8_const_num <= eq8_const_num_next;
        eq9_sigma2_num <= eq9_sigma2_num_next;
        eq9_sigma1_num <= eq9_sigma1_num_next;
        eq9_const_num <= eq9_const_num_next;
        eq10_sigma1_num <= eq10_sigma1_num_next;
        eq10_const_num <= eq10_const_num_next;

        solve_sigma_cnt <= solve_sigma_cnt_next;

        sigma1_pw <= sigma1_pw_next;
        sigma2_pw <= sigma2_pw_next;
        sigma3_pw <= sigma3_pw_next;
        sigma4_pw <= sigma4_pw_next;

        solve_i_cnt <= solve_i_cnt_next;

        i_sol1 <= i_sol1_next;
        i_sol2 <= i_sol2_next;
        i_sol3 <= i_sol3_next;
        i_sol4 <= i_sol4_next;

        eq11_Y2_num <= eq11_Y2_num_next;
        eq11_Y3_num <= eq11_Y3_num_next;
        eq11_Y4_num <= eq11_Y4_num_next;
        eq11_const_num <= eq11_const_num_next;
        eq12_Y2_num <= eq12_Y2_num_next;
        eq12_Y3_num <= eq12_Y3_num_next;
        eq12_Y4_num <= eq12_Y4_num_next;
        eq12_const_num <= eq12_const_num_next;
        eq13_Y2_num <= eq13_Y2_num_next;
        eq13_Y3_num <= eq13_Y3_num_next;
        eq13_Y4_num <= eq13_Y4_num_next;
        eq13_const_num <= eq13_const_num_next;
        eq14_Y2_num <= eq14_Y2_num_next;
        eq14_Y3_num <= eq14_Y3_num_next;
        eq14_Y4_num <= eq14_Y4_num_next;
        eq14_const_num <= eq14_const_num_next;
        eq15_Y2_num <= eq15_Y2_num_next;
        eq15_Y3_num <= eq15_Y3_num_next;
        eq15_Y4_num <= eq15_Y4_num_next;
        eq15_const_num <= eq15_const_num_next;
        eq16_Y2_num <= eq16_Y2_num_next;
        eq16_Y3_num <= eq16_Y3_num_next;
        eq16_Y4_num <= eq16_Y4_num_next;
        eq16_const_num <= eq16_const_num_next;
        eq17_Y2_num <= eq17_Y2_num_next;
        eq17_Y3_num <= eq17_Y3_num_next;
        eq17_Y4_num <= eq17_Y4_num_next;
        eq17_const_num <= eq17_const_num_next;
        eq18_Y3_num <= eq18_Y3_num_next;
        eq18_Y4_num <= eq18_Y4_num_next;
        eq18_const_num <= eq18_const_num_next;
        eq19_Y3_num <= eq19_Y3_num_next;
        eq19_Y4_num <= eq19_Y4_num_next;
        eq19_const_num <= eq19_const_num_next;
        eq20_Y4_num <= eq20_Y4_num_next;
        eq20_const_num <= eq20_const_num_next;

        y_coeff_cnt <= y_coeff_cnt_next;
        solve_y_cnt <= solve_y_cnt_next;

        Y1_pw <= Y1_pw_next;
        Y2_pw <= Y2_pw_next;
        Y3_pw <= Y3_pw_next;
        Y4_pw <= Y4_pw_next;

        Y1_offset_pw <= Y1_offset_pw_next;
        Y2_offset_pw <= Y2_offset_pw_next;
        Y3_offset_pw <= Y3_offset_pw_next;
        Y4_offset_pw <= Y4_offset_pw_next;

        send_output_cnt <= send_output_cnt_next;
        qr_decode_finish <= qr_decode_finish_next;

        for (i = 0; i < 44; i = i + 1) begin 
            codeword_corrected[i] <= codeword_corrected_next[i];
        end
        find_qrcode <= find_qrcode_next;
        first_r <= first_r_next;
        first_c <= first_c_next;

    end
end

endmodule


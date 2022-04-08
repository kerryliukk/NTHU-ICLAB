module Unshuffle_module #(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12
)
(
input clk,                          
input rst_n,  // synchronous reset (active low)
input enable, // start sending image from testbench
output reg busy,  // control signal for stopping loading input image
output reg valid, // output valid for testbench to check answers in corresponding SRAM groups
input [BW_PER_ACT-1:0] input_data, // input image data (12 bit, for example)
// read data from SRAM group A
// input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0,
// input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1,
// input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2,
// input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3,
// // read address from SRAM group A
// output [5:0] sram_raddr_a0,
// output [5:0] sram_raddr_a1,
// output [5:0] sram_raddr_a2,
// output [5:0] sram_raddr_a3,
// write enable for SRAM group A 

input [4-1:0] state,

output reg sram_wen_a0,
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,
// wordmask for SRAM group A 
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a,           // 4 * 4 = 16 bit
// write addrress to SRAM group A 
output reg [5:0] sram_waddr_a,
// write data to SRAM group A 
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a    // (4 * 4) * 12 = 192 bit
);


parameter IDLE = 4'd0, UNSHUFFLE = 4'd1, CONV1 = 4'd2, FINISH = 4'd3;


reg busy_next, valid_next;
reg sram_wen_a0_next, sram_wen_a1_next, sram_wen_a2_next, sram_wen_a3_next;
reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_next;
reg [5:0] sram_waddr_a_next;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a_next;


integer i;
reg [10-1:0] read_cnt, read_cnt_next;
reg [6-1:0] row, row_next, col, col_next;
reg [4-1:0] position;



always @* begin
    if (enable) begin
        read_cnt_next = read_cnt + 1;
    end
    else begin
        read_cnt_next = read_cnt;
    end
end

always @* begin
    if (state == UNSHUFFLE && col == 27) begin
        row_next = row + 1;
        col_next = 0;
    end
    else if (state == UNSHUFFLE && col != 27) begin
        row_next = row;
        col_next = col + 1;
    end
    else begin
        row_next = row;
        col_next = col;
    end
end

always @* begin
    position = row % 4 * 4 + col % 4;
    if (state == UNSHUFFLE) begin
        case (position)
            4'd0:    sram_wordmask_a_next = 16'b0111_1111_1111_1111;
            4'd1:    sram_wordmask_a_next = 16'b1111_0111_1111_1111;
            4'd2:    sram_wordmask_a_next = 16'b1011_1111_1111_1111;
            4'd3:    sram_wordmask_a_next = 16'b1111_1011_1111_1111;
            4'd4:    sram_wordmask_a_next = 16'b1111_1111_0111_1111;
            4'd5:    sram_wordmask_a_next = 16'b1111_1111_1111_0111;
            4'd6:    sram_wordmask_a_next = 16'b1111_1111_1011_1111;
            4'd7:    sram_wordmask_a_next = 16'b1111_1111_1111_1011;
            4'd8:    sram_wordmask_a_next = 16'b1101_1111_1111_1111;
            4'd9:    sram_wordmask_a_next = 16'b1111_1101_1111_1111;
            4'd10:   sram_wordmask_a_next = 16'b1110_1111_1111_1111;
            4'd11:   sram_wordmask_a_next = 16'b1111_1110_1111_1111;
            4'd12:   sram_wordmask_a_next = 16'b1111_1111_1101_1111;
            4'd13:   sram_wordmask_a_next = 16'b1111_1111_1111_1101;
            4'd14:   sram_wordmask_a_next = 16'b1111_1111_1110_1111;
            4'd15:   sram_wordmask_a_next = 16'b1111_1111_1111_1110;
            default: sram_wordmask_a_next = 16'b1111_1111_1111_1111;
        endcase
    end
    else begin
        sram_wordmask_a_next = 16'b1111_1111_1111_1111;
    end
end

always @* begin
    for (i = 0; i < 16; i = i + 1) begin
        sram_wdata_a_next[i*12 +:12] = input_data;
    end
end

always @* begin
    if (state == UNSHUFFLE && read_cnt > 28 * 28) begin
        valid_next = 1;
        busy_next = 1;
    end
    else begin
        valid_next = 0;
        busy_next = 0;
    end
end

always @* begin
    sram_wen_a0_next = 1;
    sram_wen_a1_next = 1;
    sram_wen_a2_next = 1;
    sram_wen_a3_next = 1;
    if (state == UNSHUFFLE) begin
    if (row % 8 <= 3) begin
        if (col % 8 <= 3) begin
            sram_wen_a0_next = 0;
        end
        else begin
            sram_wen_a1_next = 0;
        end
    end
    else begin
        if (col % 8 <= 3) begin
            sram_wen_a2_next = 0;
        end
        else begin
            sram_wen_a3_next = 0;
        end
    end
    end
end

always @* begin
    sram_waddr_a_next = row / 8 * 6 + col / 8;
end

always @(posedge clk) begin
    if (~rst_n) begin
        busy <= 0;
        valid <= 0;
        sram_wen_a0 <= 0;
        sram_wen_a1 <= 0;
        sram_wen_a2 <= 0;
        sram_wen_a3 <= 0;
        sram_wordmask_a <= 16'b1111_1111_1111_1111;
        sram_waddr_a <= 0;
        sram_wdata_a <= 0;

        read_cnt <= 0;
        row <= 0;
        col <= 0;
    end
    else begin
        busy <= busy_next;
        valid <= valid_next;
        sram_wen_a0 <= sram_wen_a0_next;
        sram_wen_a1 <= sram_wen_a1_next;
        sram_wen_a2 <= sram_wen_a2_next;
        sram_wen_a3 <= sram_wen_a3_next;
        sram_wordmask_a <= sram_wordmask_a_next;
        sram_waddr_a <= sram_waddr_a_next;
        sram_wdata_a <= sram_wdata_a_next;

        read_cnt <= read_cnt_next;
        row <= row_next;
        col <= col_next;
    end
end


endmodule
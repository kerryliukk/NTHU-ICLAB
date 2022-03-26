//=====================================================================
//IC Design Lab HW4
//
//This module uses multiplication of inverses to implement integer division
//==> quotient = dividend/divisor (one cycle delay)
//==>          = dividend * (2^SHIFT/divisor) / 2^SHIFT
//==>         ~= [ dividend * floor(2^SHIFT/divisor) ]>> SHIFT
//=====================================================================

module my_div
#(parameter DIVIDEND_WIDTH=16, DIVISOR_WIDTH=5)
(
input clk,

input [DIVIDEND_WIDTH-1:0] dividend,      //16-bit unsigned integer (0~65535)
input [ DIVISOR_WIDTH-1:0] divisor,       // 8-bit unsigned integer (1~31, 0:invalid)

output reg [DIVIDEND_WIDTH-1:0] quotient  //16-bit unsigned integer
);

localparam WIDTH_INVERSE = 17;
localparam MAX_SHIFT = WIDTH_INVERSE + DIVISOR_WIDTH-1;
localparam WIDTH_SHIFT = (MAX_SHIFT > 31) ? 6 :
                         (MAX_SHIFT > 15) ? 5 :
                         (MAX_SHIFT >  7) ? 4 :
                         (MAX_SHIFT >  3) ? 3 :
                         (MAX_SHIFT >  1) ? 2 : 1;
                         
wire [WIDTH_INVERSE-1:0] div_inverse;
wire [  WIDTH_SHIFT-1:0] div_shift;

//find the integer which approximates floor(2^SHIFT/divisor) and the bit-shift number
inverse_table #(DIVISOR_WIDTH,WIDTH_INVERSE,WIDTH_SHIFT) 
              U0(.divisor(divisor),.div_inverse(div_inverse),.div_shift(div_shift));

//execute the following multiplication and shifting
wire [DIVIDEND_WIDTH-1:0] quotient_temp;
mul_and_shift #(DIVIDEND_WIDTH,WIDTH_INVERSE,WIDTH_SHIFT)
              U1(.dividend(dividend),.div_inverse(div_inverse),.div_shift(div_shift),.quotient(quotient_temp));


always@(posedge clk)
  quotient <= quotient_temp;

endmodule

module mul_and_shift
#(parameter DIVIDEND_WIDTH=16,WIDTH_INVERSE=17,WIDTH_SHIFT=4)
(
input [DIVIDEND_WIDTH-1:0] dividend,
input [WIDTH_INVERSE-1:0] div_inverse,
input [  WIDTH_SHIFT-1:0] div_shift,

output [DIVIDEND_WIDTH-1:0] quotient
);

wire[DIVIDEND_WIDTH+WIDTH_INVERSE-1:0] mul_out = dividend * div_inverse;
wire[DIVIDEND_WIDTH+WIDTH_INVERSE-1:0] shift_out = mul_out >> div_shift;

assign quotient = shift_out[DIVIDEND_WIDTH-1:0];

endmodule

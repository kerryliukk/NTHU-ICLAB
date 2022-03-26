/*
* Module      : rop3_smart
* Description : Implement this module using the bit-hack technique mentioned in the assignment handout.
*               This module should support all the possible modes of ROP3.
* Notes       : Please remember to
*               (1) make the bit-length of {P, S, D, Result} parameterizable
*               (2) make the input/output to be a register
*/

module rop3_smart
#(
  parameter N = 4
)
(
  input clk,
  input [N-1:0] P,
  input [N-1:0] S,
  input [N-1:0] D,
  input [7:0] Mode,
  output reg [N-1:0] Result
);

integer i;
reg [N-1:0] P_in, S_in, D_in;
reg [7:0] Mode_in;
reg [N-1:0] Result_temp;
reg [7:0] temp1 [N-1:0];
reg [7:0] temp2 [N-1:0];


always @* begin
  for (i = 0; i < N; i = i + 1) begin
    temp1[i] = 8'h1 << {P_in[i], S_in[i], D_in[i]};
    temp2[i] = temp1[i] & Mode_in;
    Result_temp[i] = |temp2[i];
  end
end

always @(posedge clk) begin
    P_in <= P;
    S_in <= S;
    D_in <= D;
    Mode_in <= Mode;
    Result <= Result_temp;
end

endmodule
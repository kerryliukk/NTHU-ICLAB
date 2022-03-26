/*
* Module      : rop3_lut16
* Description : Implement this module using the look-up table (LUT) 
*               This module should support all the 15-modes listed in table-1
*               For modes not in the table-1, set the Result to 0
* Notes       : Please remember to
*               (1) make the bit-length of {P, S, D, Result} parameterizable
*               (2) make the input/output to be a register 
*/

module rop3_lut16
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

reg [N-1:0] P_in, S_in, D_in;
reg [7:0] Mode_in;
reg [N-1:0] Result_temp;

always @* begin
  case(Mode_in)
    8'h00: Result_temp = 0;
    8'h11: Result_temp = ~(D_in|S_in);
    8'h33: Result_temp = ~S_in;
    8'h44: Result_temp = S_in&~D_in;
    8'h55: Result_temp = ~D_in;
    8'h5A: Result_temp = D_in^P_in;
    8'h66: Result_temp = D_in^S_in;
    8'h88: Result_temp = D_in&S_in;
    8'hBB: Result_temp = D_in|~S_in;
    8'hC0: Result_temp = P_in&S_in;
    8'hCC: Result_temp = S_in;
    8'hEE: Result_temp = D_in|S_in;
    8'hF0: Result_temp = P_in;
    8'hFB: Result_temp = D_in|P_in|~S_in;
    8'hFF: Result_temp = 8'hFF;
    default: Result_temp = 0;
  endcase  
end

always @(posedge clk) begin
    P_in <= P;
    S_in <= S;
    D_in <= D;
    Mode_in <= Mode;
    Result <= Result_temp;
end

endmodule
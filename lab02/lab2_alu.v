module lab2_alu(
  //clock and control signals
  input clk,
  input rst_n,
  //input
  input [7:0] inputA, inputB,
  input [3:0] instruction,
  //output
  output reg [7:0] alu_out
);
reg [3:0] temp_ins;
reg [7:0] temp_A, temp_B, temp;

always @* begin
  if (temp_ins == 4'b0000)
    temp = temp_A + temp_B;
  else if (temp_ins == 4'b0001)
    temp = temp_A - temp_B;
  else if (temp_ins == 4'b0010)
    temp = ~temp_B;
  else if (temp_ins == 4'b0011)
    temp = temp_A & temp_B;
  else if (temp_ins == 4'b0100)
    temp = temp_A | temp_B;
  else
    temp = temp_A ^ temp_B;
end

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    temp_A <= 8'b0000_0000;
    temp_B <= 8'b0000_0000;
    temp_ins <= 4'b0000;
    alu_out <= 8'b0000_0000;
  end
  else begin
    temp_A <= inputA;
    temp_B <= inputB;
    temp_ins <= instruction;
    alu_out <= temp;
  end
end

endmodule
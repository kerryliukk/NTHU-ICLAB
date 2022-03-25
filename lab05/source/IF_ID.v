module IF_ID(
  // input
  input clk,
  input rst_n,
  input [15:0] IF_PC,
  input [31:0] instn,
  input beq_enable,
  // output
  output reg [15:0] ID_PC,
  output reg [31:0] ID_instn
);

always@(posedge clk)begin
  if(~rst_n)begin
    ID_PC <= 0;
    ID_instn <= 0;
  end
  else if(beq_enable == 1'b1)begin
    ID_PC <= ID_PC;
    ID_instn <= 0;
  end
  else begin
    ID_PC <= IF_PC;
    ID_instn <= instn;
  end
end

endmodule

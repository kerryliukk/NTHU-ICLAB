module ID_EXE(
  // input
  input             clk,
  input             rst_n,
  input [5:0]       ID_opcode,
  input [4:0]       ID_rs_addr,
  input [4:0]       ID_rt_addr,
  input [4:0]       ID_rd_addr,
  input [4:0]       ID_shamt,
  input [5:0]       ID_funct,
  input [31:0]      ID_immd,
  input             ID_RegWrite,
  input             ID_RegDst,
  input [1:0]       ID_ALUOp,
  input             ID_ALUSrc,
  // output
  output reg [5:0]  EXE_opcode,
  output reg [4:0]  EXE_rs_addr,
  output reg [4:0]  EXE_rt_addr,
  output reg [4:0]  EXE_rd_addr,
  output reg [4:0]  EXE_shamt,
  output reg [5:0]  EXE_funct,
  output reg [31:0] EXE_immd,
  output reg        EXE_RegWrite,
  output reg        EXE_RegDst,
  output reg [1:0]  EXE_ALUOp,
  output reg        EXE_ALUSrc
);

always@(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    EXE_opcode   <= 6'd0;
    EXE_rs_addr  <= 5'd0;
    EXE_rt_addr  <= 5'd0;
    EXE_rd_addr  <= 5'd0;
    EXE_shamt    <= 5'd0;
    EXE_funct    <= 6'd0;
    EXE_immd     <= 32'b0;
    EXE_RegDst   <= 1'b0;
    EXE_RegWrite <= 1'b0;
    EXE_ALUOp    <= 2'd0;
    EXE_ALUSrc   <= 1'b0;
  end
  else begin
    EXE_opcode   <= ID_opcode;
    EXE_rs_addr  <= ID_rs_addr;
    EXE_rt_addr  <= ID_rt_addr;
    EXE_rd_addr  <= ID_rd_addr;
    EXE_shamt    <= ID_shamt;
    EXE_funct    <= ID_funct;
    EXE_immd     <= ID_immd;
    EXE_RegDst   <= ID_RegDst;
    EXE_RegWrite <= ID_RegWrite;//ID_RegWrite;
    EXE_ALUOp    <= ID_ALUOp;
    EXE_ALUSrc   <= ID_ALUSrc;
  end
end

endmodule

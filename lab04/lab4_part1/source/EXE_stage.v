module EXE_stage(
  // input
  // input                en_exe,
  input                RegDst,
  input signed [31:0]  read_data1,
  input signed [31:0]  read_data2,
  input [5:0]          opcode,
  input [4:0]          rd_addr,
  input [4:0]          rs_addr,
  input [4:0]          rt_addr,
  input [4:0]          shamt,
  input [5:0]          funct,
  input signed [31:0]  immd, //input signed extension immediate[15:0]
  input [1:0]          ALUOp,
  input                ALUSrc,
  // output
  output reg [4:0]     write_addr,
  output signed [31:0] alu_result,
  output               alu_overflow,
  output               zero
);

always@(*) begin
  if(RegDst==1'b1) begin
    write_addr = rd_addr;
  end
  else begin
    write_addr = rt_addr;
  end
end

alu alu(
  // input
  .read_data1(read_data1),
  .read_data2(read_data2),
  .immd(immd),
  .opcode(opcode),
  .funct(funct),
  .shamt(shamt),
  .ALUOp(ALUOp),
  .ALUSrc(ALUSrc),
  // output
  .alu_result(alu_result),
  .alu_overflow(alu_overflow),
  .zero(zero)
);

endmodule

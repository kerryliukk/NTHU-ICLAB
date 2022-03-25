module EXE_stage(
  input [15:0]PC,
  input RegDst,
  // input [5:0]opcode,
  input [4:0]rt_addr,
  input [4:0]rd_addr,
  input [4:0]shamt,
  input [5:0]funct,
  input signed [31:0]immd,      //input signed extension immediate[15:0]
  input signed [31:0]read_data1,
  input signed [31:0]read_data2,
  input [1:0]ALUOp,
  input ALUSrc,
  output reg[4:0] write_addr,
  output signed [31:0]alu_result,
  // output alu_overflow,
  output zero,
  output reg [15:0]PC_out
);


always@(*) begin
  if(RegDst==1'b1) begin
    write_addr = rd_addr;
  end
  else begin
    write_addr = rt_addr;
  end
end
//for PC counter of BEQ
always@(*) begin
  PC_out = PC + (immd<<<2);
end

alu alu(
  //input
  //.en_exe(en_exe),
  .read_data1(read_data1),
  .read_data2(read_data2),
  .immd(immd),
  // .opcode(opcode),
  .funct(funct),
  .shamt(shamt),
  .ALUOp(ALUOp),
  .ALUSrc(ALUSrc),
  //output
  .alu_result(alu_result),
  // .alu_overflow(alu_overflow),
  .zero(zero)
);


endmodule

module top(
  input        clk,
  input        rst_n,
  input [31:0] instn,
  output       EXE_alu_overflow
);

wire MEM_RegWrite;
wire [4:0] MEM_write_addr;
wire [31:0] ID_read_data1;
wire [31:0] ID_read_data2;
wire [5:0] ID_opcode;
wire [4:0] ID_rd_addr;
wire [4:0] ID_rs_addr;
wire [4:0] ID_rt_addr;
wire [4:0] ID_shamt;
wire [5:0] ID_funct;
wire [31:0] ID_immd;
wire ID_RegDst;
wire [1:0]ID_ALUOp;
wire ID_ALUSrc;
wire ID_RegWrite;
wire ID_MemtoReg;

wire [5:0]EXE_opcode;
wire [4:0]EXE_rs_addr;
wire [4:0]EXE_rt_addr;
wire [4:0]EXE_rd_addr;
wire [4:0]EXE_shamt;
wire [5:0]EXE_funct;
wire [31:0]EXE_immd;
wire EXE_RegWrite;
wire EXE_MemtoReg;
wire [31:0]EXE_read_data1;
wire [31:0]EXE_read_data2;
wire EXE_RegDst;
wire [1:0]EXE_ALUOp;
wire EXE_ALUSrc;
wire [31:0]write_data;
wire [4:0]EXE_write_addr;
wire [31:0]EXE_alu_result;

wire EXE_zero;
wire PCSrc;

assign write_data = EXE_alu_result;    //select write back data from ALU or Data Memory

ID_stage ID_stage(
  ////////////////////////input///////////////////
  .clk(clk),
  .rst_n(rst_n),
  .MEM_RegWrite(EXE_RegWrite),
  .write_addr(EXE_write_addr),
  .write_data(write_data),
  .instn(instn),
  ///////////////////////output//////////////////////
  .read_data1(ID_read_data1),
  .read_data2(ID_read_data2),
  //instruction type
  .opcode(ID_opcode),
  .rd_addr(ID_rd_addr),
  .rs_addr(ID_rs_addr),
  .rt_addr(ID_rt_addr),
  .shamt(ID_shamt),
  .funct(ID_funct),
  .immd(ID_immd),
  //control signals
  //Execution/Address Calculation stage control lines
  .RegDst(ID_RegDst),
  .ALUOp(ID_ALUOp),
  .ALUSrc(ID_ALUSrc),
  //Write-back stage control lines
  .RegWrite(ID_RegWrite)
);

ID_EXE ID_EXE(
  //input
  .clk(clk),
  .rst_n(rst_n),
  .ID_opcode(ID_opcode),
  .ID_rs_addr(ID_rs_addr),
  .ID_rt_addr(ID_rt_addr),
  .ID_rd_addr(ID_rd_addr),
  .ID_shamt(ID_shamt),
  .ID_funct(ID_funct),
  .ID_immd(ID_immd),
  .ID_RegDst(ID_RegDst),
  .ID_ALUOp(ID_ALUOp),
  .ID_ALUSrc(ID_ALUSrc),
  .ID_RegWrite(ID_RegWrite),
  //output
  .EXE_opcode(EXE_opcode),
  .EXE_rs_addr(EXE_rs_addr),
  .EXE_rt_addr(EXE_rt_addr),
  .EXE_rd_addr(EXE_rd_addr),
  .EXE_shamt(EXE_shamt),
  .EXE_funct(EXE_funct),
  .EXE_immd(EXE_immd),
  .EXE_RegDst(EXE_RegDst),
  .EXE_ALUOp(EXE_ALUOp),
  .EXE_ALUSrc(EXE_ALUSrc),
  .EXE_RegWrite(EXE_RegWrite)
);

EXE_stage EXE_stage(
  //input
  .RegDst(EXE_RegDst),
  .read_data1(ID_read_data1),
  .read_data2(ID_read_data2),
  .opcode(EXE_opcode),
  .rd_addr(EXE_rd_addr),
  .rs_addr(EXE_rs_addr), 
  .rt_addr(EXE_rt_addr),
  .shamt(EXE_shamt),
  .funct(EXE_funct),
  .immd(EXE_immd),
  .ALUOp(EXE_ALUOp),
  .ALUSrc(EXE_ALUSrc),
  //output
  .write_addr(EXE_write_addr),
  .alu_result(EXE_alu_result),
  .alu_overflow(EXE_alu_overflow),
  .zero(EXE_zero)
);

endmodule

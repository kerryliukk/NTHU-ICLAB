module ID_stage(
  // input
  input         clk,
  input         rst_n,
  input         MEM_RegWrite,
  input [4:0]   write_addr,
  input [31:0]  write_data,
  input [31:0]  instn,
  // output
  output [31:0] read_data1,
  output [31:0] read_data2,
  // instruction type
  output [5:0]  opcode,
  output [4:0]  rd_addr,
  output [4:0]  rs_addr,
  output [4:0]  rt_addr,
  output [4:0]  shamt,
  output [5:0]  funct,
  output [31:0] immd,
  // control signals
  // Execution/Address Calculation stage control lines
  output        RegDst,
  output [1:0]  ALUOp,
  output        ALUSrc,
  // Write-back stage control lines
  output        RegWrite
);

// data memory
wire [31:0] sw_data;

assign rs_addr = instn[25:21];
assign rt_addr = instn[20:16];
assign rd_addr = instn[15:11];
assign shamt   = instn[10:6];
assign funct   = instn[5:0];
assign immd    = {{16{instn[15]}}, instn[15:0]};

regfile regfile(
  .clk(clk),
  .rst_n(rst_n),
  .read_addr1(rs_addr),
  .read_data1(read_data1),
  .read_addr2(rt_addr),
  .read_data2(read_data2),
  .write_addr(write_addr),
  .write_data(write_data),
  //.read(),
  .write(MEM_RegWrite)
);

controller controller(
  // input
  .instn(instn),
  // output
  // instruction type
  .opcode(opcode),
  // control signals
  // Execution / Address Calculation stage control lines
  .RegDst(RegDst),
  .ALUOp(ALUOp),
  .ALUSrc(ALUSrc),
  // Write-back stage control lines
  .RegWrite(RegWrite)
);

endmodule

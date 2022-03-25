module ID_stage(
  input  clk,
  input  rst_n,
  input  MEM_RegWrite,
  input  [4:0]write_addr,
  input  [31:0]write_data,
  input  [31:0]instn,
  input  [1:0] state,
  input  PCSrc,


  output   [31:0]read_data1,
  output   [31:0]read_data2,
  // output  [5:0]opcode,
  output  [4:0]rd_addr, rs_addr, rt_addr,
  output  [4:0]shamt,
  output  [5:0]funct,
  output  [31:0]immd,
  output   RegDst,
  output   [1:0]ALUOp,
  output   ALUSrc,
  output   branch,
  output   RegWrite,
  output   MemtoReg,
  output   [31:0]dsram_out,
  output  [1:0] next_state,
  output  beq_enable
);


wire    MemRead;
wire    MemWrite;
//data memory
wire [31:0] sw_data;
wire [7:0] data_addr;


assign rs_addr = instn[25:21];
assign rt_addr = instn[20:16];
assign rd_addr = instn[15:11];
assign shamt   = instn[10:6];
assign funct   = instn[5:0];

assign immd    = {{16{instn[15]}}, instn[15:0]};
assign data_addr = instn[7:0];

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
  .write(MEM_RegWrite),
  //data memory
  .sw_data(sw_data)
);

controller controller(
  ////////////////input//////////////
  .instn(instn),
  ////////////////output//////////////
  //instruction type
  // .opcode(opcode),
  //control signals
  //Execution /Address Calculation stage control lines
  .RegDst(RegDst),
  .ALUOp(ALUOp),
  .ALUSrc(ALUSrc),
  //Memory access stage control lines
  .branch(branch),
  .MemRead(MemRead),
  .MemWrite(MemWrite),
  //Write-back stage control lines
  .RegWrite(RegWrite),
  .MemtoReg(MemtoReg),
  //beq
  .PCSrc(PCSrc),
  .state(state),
  .next_state(next_state),
  .beq_enable(beq_enable)

);


/* Instantiate SRAM256x32s as dcache here
 * The I port of dcache should take CPU's arithmatic result as input
 * The O port of dcache should drive the data port from sram to CPU
 * The read/write control signal depends on whether CPU is going to read/write the SRAM
 */

SRAM256x32s dcache(.A(data_addr),
 		   		         .CE(clk),
				           .WEB(~MemWrite),
				           .OEB(1'b0),
				           .CSB(1'b0),
				           .I(sw_data),
				           .O(dsram_out)
);

endmodule

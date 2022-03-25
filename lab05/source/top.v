module top(
	input         clk,
	input         rst_n,
	input         boot_up,
	input  [7 :0] boot_addr,
	input  [31:0] boot_datai,
	input         boot_web,
	output        peri_web,
	output [15:0] peri_addr,
	output [15:0] peri_datao
);




wire [31:0]instn;
wire [15:0] IF_PC;


wire MEM_RegWrite;
wire [4:0] MEM_write_addr;
wire [31:0] ID_read_data1;
wire [31:0] ID_read_data2;
wire [31:0]dsram_out;
// wire [5:0] ID_opcode;
wire [4:0] ID_rd_addr;
wire [4:0] ID_rs_addr;
wire [4:0] ID_rt_addr;
wire [4:0] ID_shamt;
wire [5:0] ID_funct;
wire [31:0] ID_immd;
wire ID_RegDst;
wire [1:0]ID_ALUOp;
wire ID_ALUSrc;
wire ID_branch;
wire ID_RegWrite;
wire ID_MemtoReg;
wire [15:0]ID_PC;
wire [31:0]ID_instn;

wire [15:0]EXE_PC;
// wire [5:0]EXE_opcode;
// wire [4:0]EXE_rs_addr;
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
wire EXE_branch;
wire [1:0]EXE_ALUOp;
wire EXE_ALUSrc;
wire MEM_MemtoReg;
// wire EXE_alu_overflow;
wire [31:0]write_data;
wire [4:0]EXE_write_addr;
wire [31:0]EXE_alu_result;
wire [15:0]MEM_PC;

wire [31:0]MEM_alu_result;
wire MEM_zero;
wire MEM_branch;
wire [15:0]Branch_in;
wire EXE_zero;
wire PCSrc;
wire PC_run;

wire [1:0] state,next_state;
wire beq_enable;

assign write_data = EXE_MemtoReg ? dsram_out : EXE_alu_result;		//select write back data from ALU or Data Memory
assign PCSrc = EXE_zero & EXE_branch;

//reset signal for all module (also reset when bootup), except PC
wire rstn_system = rst_n & PC_run;

IF_stage IF_stage(
	.clk(clk),
	.rst_n(rst_n),
         .boot_up(boot_up),
         .boot_addr(boot_addr),
         .boot_datai(boot_datai),
         .boot_web(boot_web),
	.Branch_in(Branch_in),
	.PCSrc(PCSrc),
        .PC_run(PC_run),
	.instn(instn),
	.PC_add(IF_PC)
);


IF_ID IF_ID(
	//input
	.clk(clk),
	.rst_n(rstn_system),
	.IF_PC(IF_PC),
	.instn(instn),
	.beq_enable(beq_enable),
	//output
	.ID_PC(ID_PC),
	.ID_instn(ID_instn)
);


ID_stage ID_stage(
	////////////////////////input///////////////////
	.clk(clk),
	.rst_n(rstn_system),
	.MEM_RegWrite(EXE_RegWrite),
	.write_addr(EXE_write_addr),
	.write_data(write_data),
	.instn(ID_instn),
	///////////////////////output//////////////////////
	.read_data1(ID_read_data1),
	.read_data2(ID_read_data2),
	.dsram_out(dsram_out),
	//instruction type
	// .opcode(ID_opcode),
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
	//Memory access stage control lines
	.branch(ID_branch),
	//Write-back stage control lines
	.RegWrite(ID_RegWrite),
	.MemtoReg(ID_MemtoReg),
	//beq
	.PCSrc(PCSrc),
	.state(state),
	.next_state(next_state),
	.beq_enable(beq_enable)
);



ID_EXE ID_EXE(
	//input
	.clk(clk),
	.rst_n(rstn_system),
	.ID_PC(ID_PC),
	//.ID_opcode(ID_opcode),
	// .ID_rs_addr(ID_rs_addr),
	.ID_rt_addr(ID_rt_addr),
	.ID_rd_addr(ID_rd_addr),
	.ID_shamt(ID_shamt),
	.ID_funct(ID_funct),
	.ID_immd(ID_immd),
	.ID_branch(ID_branch),
	.ID_RegDst(ID_RegDst),
	.ID_ALUOp(ID_ALUOp),
	.ID_ALUSrc(ID_ALUSrc),
	.ID_RegWrite(ID_RegWrite),
  .ID_MemtoReg(ID_MemtoReg),
	//output
	.EXE_PC(EXE_PC),
	// .EXE_opcode(EXE_opcode),
	// .EXE_rs_addr(EXE_rs_addr),
	.EXE_rt_addr(EXE_rt_addr),
	.EXE_rd_addr(EXE_rd_addr),
	.EXE_shamt(EXE_shamt),
	.EXE_funct(EXE_funct),
	.EXE_immd(EXE_immd),
	.EXE_RegDst(EXE_RegDst),
	.EXE_branch(EXE_branch),
	.EXE_ALUOp(EXE_ALUOp),
	.EXE_ALUSrc(EXE_ALUSrc),
	.EXE_RegWrite(EXE_RegWrite),
	.EXE_MemtoReg(EXE_MemtoReg),
	//beq
	.state(state),
	.next_state(next_state)
);

EXE_stage EXE_stage(
	//input
	.PC(EXE_PC),
	//.en_exe(),
	.RegDst(EXE_RegDst),
	.read_data1(ID_read_data1),
	.read_data2(ID_read_data2),
	// .opcode(EXE_opcode),
	.rd_addr(EXE_rd_addr),
	//.rs_addr(EXE_rs_addr),
	.rt_addr(EXE_rt_addr),
	.shamt(EXE_shamt),
	.funct(EXE_funct),
	.immd(EXE_immd),
	.ALUOp(EXE_ALUOp),
    .ALUSrc(EXE_ALUSrc),
	//output
	.write_addr(EXE_write_addr),
	.alu_result(EXE_alu_result),
	// .alu_overflow(EXE_alu_overflow),
	.zero(EXE_zero),
	.PC_out(Branch_in)
    
);



endmodule

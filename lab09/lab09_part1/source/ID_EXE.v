module ID_EXE(
	//input
	clk,
	rst_n,
	ID_PC,
	ID_opcode,
	ID_rs_addr,
	ID_rt_addr,
	ID_rd_addr,
	ID_shamt,
	ID_funct,
	ID_immd,
	ID_RegWrite,
    ID_MemtoReg,
    //ID_read,
    //ID_write,
	ID_RegDst,
	ID_branch,
	ID_ALUOp,
	ID_ALUSrc,
	next_state,
	
	
	//output
	EXE_PC,
	EXE_opcode,
	EXE_rs_addr,
	EXE_rt_addr,
	EXE_rd_addr,
	EXE_shamt,
	EXE_funct,
	EXE_immd,
	EXE_RegWrite,
	EXE_MemtoReg,
	//EXE_read,
	//EXE_write,
	EXE_RegDst,
	EXE_branch,
	EXE_ALUOp,
	EXE_ALUSrc,
	state
);


input 	clk, rst_n;
input	[15:0]ID_PC;
input   [5:0]ID_opcode;
input	[4:0]ID_rs_addr;
input	[4:0]ID_rt_addr;
input	[4:0]ID_rd_addr;
input   [4:0]ID_shamt;
input   [5:0]ID_funct;
input   [31:0]ID_immd;
input   ID_RegDst;
input	ID_RegWrite;
input	ID_MemtoReg;
//input	ID_read;
//input	ID_write;
input	ID_branch;
input	[1:0]ID_ALUOp;
input	ID_ALUSrc;
input	[1:0] next_state;


output  reg [15:0]EXE_PC;
output  reg [5:0]EXE_opcode;
output	reg [4:0]EXE_rs_addr;
output	reg [4:0]EXE_rt_addr;
output	reg [4:0]EXE_rd_addr;
output  reg [4:0]EXE_shamt;
output  reg [5:0]EXE_funct;
output  reg [31:0]EXE_immd;
output  reg EXE_RegDst;
output	reg EXE_RegWrite;
output	reg EXE_MemtoReg;
//output	reg EXE_read;
//output	reg EXE_write;
output	reg EXE_branch;
output	reg [1:0]EXE_ALUOp;
output	reg EXE_ALUSrc;
output  reg [1:0] state;





always@(posedge clk) begin
	if(~rst_n) begin
		EXE_PC <= 16'd0;
		EXE_opcode <= 6'd0;
		EXE_rs_addr <= 5'd0; 
		EXE_rt_addr <= 5'd0;
		EXE_rd_addr <= 5'd0;
		EXE_shamt <= 5'd0;
		EXE_funct <= 6'd0;
		EXE_immd <= 32'b0;
		EXE_RegDst <= 1'b0;
		EXE_RegWrite <= 1'b0;
		EXE_MemtoReg <= 1'b0;
		//EXE_read <= 1'b0;
		//EXE_write <= 1'b0;
		EXE_branch <= 1'b0;
		EXE_ALUOp <= 2'd0;
		EXE_ALUSrc <= 1'b0;
		state <= 0;
	end
	else begin
		EXE_PC <= ID_PC;
		EXE_opcode <= ID_opcode;
		EXE_rs_addr <= ID_rs_addr; 
		EXE_rt_addr <= ID_rt_addr;
		EXE_rd_addr <= ID_rd_addr;
		EXE_shamt <= ID_shamt;
		EXE_funct <= ID_funct;
		EXE_immd <= ID_immd;
		EXE_RegDst <= ID_RegDst;
		EXE_RegWrite <= ID_RegWrite;
		EXE_MemtoReg <= ID_MemtoReg;
		//EXE_read <= ID_read;
		//EXE_write <= ID_write;
		EXE_branch <= ID_branch;
		EXE_ALUOp <= ID_ALUOp;
		EXE_ALUSrc <= ID_ALUSrc;
		state <= next_state;

	end
end


endmodule

module ID_stage(
	////////////////////////input///////////////////
	clk,
	rst_n,
	MEM_RegWrite,
	write_addr,
	write_data,
	instn,
	///////////////////////output//////////////////////
	read_data1,
	read_data2,
	dsram_out,			//dsram Read data
	//instruction type
	opcode,
	rd_addr,
	rs_addr,
	rt_addr,
	shamt,  
	funct, 
	immd,
	//control signals
	//Execution/Address Calculation stage control lines
	RegDst,
	ALUOp,
	ALUSrc,
	//Memory access stage control lines
	branch,
	//MemRead,
	//MemWrite,
	//Write-back stage control lines
	RegWrite,
	MemtoReg,
	//BEQ
	PCSrc,
	state,
	beq_enable,
	next_state,
        
        peri_web,
        peri_addr,
        peri_datao
);

input	clk;
input	rst_n;
input	MEM_RegWrite;
input	[4:0]write_addr;
input	[31:0]write_data;
input   [31:0]instn;
input 	[1:0] state;
input	PCSrc;


output 	[31:0]read_data1;
output 	[31:0]read_data2;
output  [5:0]opcode;
output  [4:0]rd_addr, rs_addr, rt_addr;
output  [4:0]shamt;
output  [5:0]funct;
output  [31:0]immd;
output   RegDst;
output   [1:0]ALUOp;
output   ALUSrc;
output   branch;
//output   MemRead;
//output   MemWrite;		
output   RegWrite;
output   MemtoReg;
output   [31:0]dsram_out;
output	[1:0] next_state;
output	beq_enable;

output  peri_web;
output [15:0] peri_addr;
output [15:0] peri_datao;


wire    [4:0]rt_addr, rs_addr;
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
	.opcode(opcode),
	//control signals
	//Execution /Address Calculation stage control lines
	.RegDst(RegDst),
	.ALUOp(ALUOp),
	.ALUSrc(ALUSrc),
	//Memory access stage control lines
	.branch(branch),
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


//write peripheral memory if memory write address > 256
wire peri_web = ~(MemWrite ? |instn[15:8] : 1'b0);
wire [15:0] peri_addr  = ~peri_web ?   instn[15:0] : 16'b0;
wire [15:0] peri_datao = ~peri_web ? sw_data[15:0] : 16'b0;


wire dcache_web = MemWrite ? ~peri_web : 1'b1;

/*
SRAM256x32s dcache(
.A(data_addr),
.CE(clk),
.WEB(dcache_web),		
.OEB(1'b0),
.CSB(1'b0),
.I(sw_data),
.O(dsram_out)
);*/


dsram dcache(
.addr(data_addr),
.clk(clk),
.en_wr(dcache_web),
.in(sw_data),
.out(dsram_out)
);


endmodule

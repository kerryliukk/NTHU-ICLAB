module IF_stage(
input clk,
input rst_n,
input boot_up,
input [7:0] boot_addr,
input [31:0] boot_datai,
input boot_web,
input [15:0] Branch_in,
input PCSrc,
output [31:0] instn,
output PC_run,
output [15:0] PC_add

);

wire [9:0] PC_out;
wire [7:0] ins_addr;
assign ins_addr = PC_add[9:2];

PC PC(
	.clk(clk),
	.rst_n(rst_n),
        .boot_up(boot_up),
	.PCSrc(PCSrc),
	.PC_out(PC_add),
        .PC_run(PC_run),
	.Branch_in(Branch_in)
);

wire icache_en_wr = PC_run ? 1'b1 : boot_web;
wire [7:0] icache_addr = PC_run ? ins_addr : boot_addr;

// dsram icache(
// 			.clk(clk),
//       .en_wr(icache_en_wr),
// 			.addr(icache_addr),
// 			.in(boot_datai),
// 			.out(instn)

// );

SRAM256x32s icache(
.A(icache_addr),
.CE(clk),
.WEB(icache_en_wr),		
.OEB(1'b0),
.CSB(1'b0),
.I(boot_datai),
.O(instn)
);


endmodule

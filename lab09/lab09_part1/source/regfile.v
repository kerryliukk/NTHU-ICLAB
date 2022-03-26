module regfile(
	clk,
	rst_n,
	read_addr1,
	read_data1,
	read_addr2,
	read_data2,
	write_addr,
	write_data,
	//read,
	write,
	//sw
	sw_data
);

parameter dw = 32;			//data width
parameter aw = 5;			//regfile address width

//
//I/O
//
//
// Clock and reset
//
input				clk;
input				rst_n;

//
// Port Read 1
//
input		[aw-1:0]		read_addr1;
output	reg [dw-1:0]		read_data1;
//input 						read;
//
// Port Read 2
//
input		[aw-1:0]		read_addr2;
output	reg [dw-1:0]		read_data2;

//
// Port Write
//
input 					write;
input	[aw-1:0]		write_addr;
input	[dw-1:0]		write_data;
//Port Data Memory
output [dw-1:0] sw_data;

reg [dw-1:0]gpr[31:0];	//declare 32 32-bit general purpose register (gpr)
reg [dw-1:0]gpr_nx[31:0];	//declare 32 32-bit general purpose register (gpr)
//test
wire [31:0] r1;
wire [31:0] r2;
wire [31:0] r3;
wire [31:0] r4;
wire [31:0] r5;
wire [31:0] r6;
wire [31:0] r7;
wire [31:0] r8;
wire [31:0] r9;
wire [31:0] r10;
assign r1 = gpr[1];
assign r2 = gpr[2];
assign r3 = gpr[3];
assign r4 = gpr[4];
assign r5 = gpr[5];
assign r6 = gpr[6];
assign r7 = gpr[7];
assign r8 = gpr[8];
assign r9 = gpr[9];
assign r10 = gpr[10];
//test

//SW USE
assign sw_data = gpr[read_addr2];
//

integer i;


always@(posedge clk) begin
	for(i=0;i<32;i=i+1)begin
		gpr[i] <= gpr_nx[i];
	end
	read_data1 <= gpr[read_addr1];
	read_data2 <= gpr[read_addr2];
end

always@* begin
	for(i=0;i<32;i=i+1)begin
		gpr_nx[i] = gpr[i];
	end
	if(write)begin
		gpr_nx[write_addr] = write_data;
	end
end


endmodule


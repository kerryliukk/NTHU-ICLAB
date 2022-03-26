`include "../source/CPU_define.v"
module test_top;

parameter PERIOD = 20;
parameter WORD = 255;
//input
reg clk;
reg rst_n;
reg [31:0] instruction [255:0];

//wire [15:0]PC_out;
wire EXE_alu_overflow;

reg boot_up;
reg [7:0] boot_addr;
reg [31:0] boot_datai;
reg boot_web;

wire  peri_web;
wire [15:0] peri_addr;
wire [15:0] peri_datao;

top_pipe top_pipe_U0(
.clk(clk),
.rst_n(rst_n),
.boot_up(boot_up),
.boot_addr(boot_addr),
.boot_datai(boot_datai),
.boot_web(boot_web),

.peri_web(peri_web),
.peri_addr(peri_addr),
.peri_datao(peri_datao)

);



initial begin
`ifdef GATESIM
	$fsdbDumpfile("lab6_gatesim.fsdb");
	$fsdbDumpvars;
	$sdf_annotate("../syn/netlist/top_pipe_syn.sdf",top_pipe_U0);
`else
	$fsdbDumpfile("lab6_presim.fsdb");
	$fsdbDumpvars;
`endif
end

parameter BOOT_CODE_SIZE = 45;

reg [31:0] mem [0:BOOT_CODE_SIZE-1];

integer i;
//read instuction from instruction.txt to Icache
initial begin
	$readmemb("instruction.txt",mem, 0 , BOOT_CODE_SIZE-1);
end

always #(PERIOD/2) clk = ~clk;

integer j;

initial begin
clk = 1;
rst_n = 1;
boot_up = 0;
boot_addr = 0;
boot_datai = 0;
boot_web = 1;
@(negedge clk);
#(PERIOD) rst_n = 0;
#(PERIOD) rst_n = 1; boot_up =1;
for (j=0 ; j<BOOT_CODE_SIZE;j=j+1)begin
#(PERIOD) boot_web = 1'b0;
          boot_addr = j[7:0];
          boot_datai = mem[j];
end

#(PERIOD) boot_up =0; boot_web = 1'b1; boot_addr = 0; boot_datai = 0;

end




//check result
integer r1,r2,r3,r4,r5,r6,r7,r8,r9,r10;
integer d2,d4,d6,d8;

initial begin
#(PERIOD);
@(negedge boot_up);
@(negedge clk);
@(negedge clk);

r1=0;
r2=0;
r3=0;
r4=0;
r5=0;
r6=0;
r7=0;
r8=0;
r9=0;
r10=0;
d2=0;
d4=0;
d6=0;
d8=0;
#(PERIOD) r1 = 15;
#(PERIOD) r3 = 20;
#(PERIOD) r4 = r3+r1;
#(PERIOD) r5 = r4+r1;
#(PERIOD) d2 = r5;
#(PERIOD) r6 = d2;
#(PERIOD) r7 = r6+10;
#(PERIOD) r8 = r6+20;
#(PERIOD) r9 = r7<<2;
#(PERIOD) r10= r8>>1;
#(PERIOD) d2 = r7;
#(PERIOD) d4 = r8;
#(PERIOD) d6 = r9;
#(PERIOD) d8 = r10;
#(PERIOD) r1 = d2;
#(PERIOD) r2 = d4;
#(PERIOD) r3 = d6;
#(PERIOD) r4 = d8;
#(PERIOD) r5 = r9 - r10;
#(PERIOD) r6 = r9 & r10; // change this to mul(*) for comparison
#(PERIOD) r7 = r9 | r10;
#(PERIOD) r8 = r9 | r10;
#(PERIOD) r5 = r8 - r10;
#(PERIOD) r7 = r8 - r10;
#(PERIOD*20);

show_register_value();

#(PERIOD) $finish;
end



integer f_register;
integer std_out = 1;
integer write_to;
task show_register_value;
begin
`ifdef GATESIM
f_register = $fopen("register_gate.txt");
write_to = f_register | std_out;
$fdisplay(write_to,"r1 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r1,r1);
$fdisplay(write_to,"r2 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r2,r2);
$fdisplay(write_to,"r3 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r3,r3);
$fdisplay(write_to,"r4 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r4,r4);
$fdisplay(write_to,"r5 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r5,r5);
$fdisplay(write_to,"r6 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r6,r6);
$fdisplay(write_to,"r7 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r7,r7);
$fdisplay(write_to,"r8 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r8,r8);
$fdisplay(write_to,"r9 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r9,r9);
$fdisplay(write_to,"r10 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.r10,r10);
$fdisplay(write_to,"d2 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[3*32-1:2*32],d2);
$fdisplay(write_to,"d4 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[5*32-1:4*32],d4);
$fdisplay(write_to,"d6 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[7*32-1:6*32],d6);
$fdisplay(write_to,"d8 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[9*32-1:8*32],d8);
`else
f_register = $fopen("register_sim.txt");
write_to = f_register | std_out;
$fdisplay(write_to,"r1 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[1],r1);
$fdisplay(write_to,"r2 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[2],r2);
$fdisplay(write_to,"r3 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[3],r3);
$fdisplay(write_to,"r4 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[4],r4);
$fdisplay(write_to,"r5 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[5],r5);
$fdisplay(write_to,"r6 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[6],r6);
$fdisplay(write_to,"r7 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[7],r7);
$fdisplay(write_to,"r8 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[8],r8);
$fdisplay(write_to,"r9 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[9],r9);
$fdisplay(write_to,"r10 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.regfile.gpr[10],r10);
$fdisplay(write_to,"d2 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[2],d2);
$fdisplay(write_to,"d4 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[4],d4);
$fdisplay(write_to,"d6 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[6],d6);
$fdisplay(write_to,"d8 = %d ,the answer is %d\n",top_pipe_U0.top0.ID_stage.dcache.memory[8],d8);
`endif

$fclose(f_register);
end
endtask









endmodule

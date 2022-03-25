`include "../../source/CPU_define.v"
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

top top_U0(
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
	$fsdbDumpfile("lab5.fsdb");
	$fsdbDumpvars("+mda");
end

parameter BOOT_CODE_SIZE = 32;

reg [31:0] mem [0:BOOT_CODE_SIZE-1];
reg [7*100:0] instruction_name;

integer i;
//read instuction from instruction.txt to Icache
initial begin
  instruction_name = "instruction_2.txt";
	$readmemb(instruction_name, mem, 0 , BOOT_CODE_SIZE-1);
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


reg should_fin;
initial begin
  #(PERIOD);
  @(negedge boot_up);
  if(instruction_name=="instruction_1.txt")
    #(PERIOD*35)  should_fin = 1;
  else
    #(PERIOD*(15*11+10))  should_fin = 1;
  #(PERIOD*500)
    $display("Simulation end by time out");
    $finish;
end


//Outpu result check
integer r1,r2,r3,r4,r5,r6,r7,r8,r9,r10;
integer d2,d4,d6,d8;
integer f_register;
reg [31:0] golden [0:13];

initial begin
  f_register = $fopen("register.txt");
  if(instruction_name=="instruction_1.txt")begin
    $readmemh("golden_register.dat",golden);
    r1 = golden[0];
    r2 = golden[1];
    r3 = golden[2];
    r4 = golden[3];
    r5 = golden[4];
    r6 = golden[5];
    r7 = golden[6];
    r8 = golden[7];
    r9 = golden[8];
    r10 = golden[9];
    d2 = golden[10];
    d4 = golden[11];
    d6 = golden[12];
    d8 = golden[13];
    wait(should_fin===1)
    $display("%d : Start to write",$time);
    $fdisplay(f_register,"r1 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[1],r1);
    $fdisplay(f_register,"r2 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[2],r2);
    $fdisplay(f_register,"r3 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[3],r3);
    $fdisplay(f_register,"r4 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[4],r4);
    $fdisplay(f_register,"r5 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[5],r5);
    $fdisplay(f_register,"r6 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[6],r6);
    $fdisplay(f_register,"r7 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[7],r7);
    $fdisplay(f_register,"r8 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[8],r8);
    $fdisplay(f_register,"r9 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[9],r9);
    $fdisplay(f_register,"r10 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[10],r10);  
    $fdisplay(f_register,"d2 = %d ,the answer is %d\n",top_U0.ID_stage.dcache.memory[2],d2);
    $fdisplay(f_register,"d4 = %d ,the answer is %d\n",top_U0.ID_stage.dcache.memory[4],d4);
    $fdisplay(f_register,"d6 = %d ,the answer is %d\n",top_U0.ID_stage.dcache.memory[6],d6);
    $fdisplay(f_register,"d8 = %d ,the answer is %d\n",top_U0.ID_stage.dcache.memory[8],d8);
  end
  else begin
    r1 = 16;
    r2 = 32;
    r3 = 16;
    wait(should_fin===1)
    $display("%d : Start to write",$time);
    $fdisplay(f_register,"r1 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[1],r1);
    $fdisplay(f_register,"r2 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[2],r2);
    $fdisplay(f_register,"r3 = %d ,the answer is %d\n",top_U0.ID_stage.regfile.gpr[3],r3);
  end
  $fclose(f_register);


  $display("****** All values of used registers and memory are dumped to register.txt ***********");
  $finish;
end









endmodule

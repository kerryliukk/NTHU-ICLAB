module test_top;

parameter PERIOD = 10;

// input
reg clk;
reg rst_n;
reg [31:0] instn;
reg instn_en;
// output
wire EXE_alu_overflow;

top top(
.clk(clk),
.rst_n(rst_n),
.instn(instn),
.EXE_alu_overflow(EXE_alu_overflow)
);

initial begin
  $fsdbDumpfile("lab4.fsdb");
  $fsdbDumpvars("+mda");
end

always #(PERIOD/2) clk = ~clk;

initial begin
  clk = 0;
  rst_n = 1;
  #(PERIOD) rst_n = 0;
  #(PERIOD) rst_n = 1;
  #(1000000000*PERIOD) 
  $display("Simulation end by time out"); 
  $finish;
end


reg [31:0] instruction [0:14];
reg [31:0] golden [0:31];
reg finish;
integer i, f_out;
initial begin
  instn = 0;
  finish = 0;
  $readmemb("instruction.txt", instruction);
  wait(rst_n==0);
  wait(rst_n==1);
  for(i=0; i<14; i=i+1)begin
    @(negedge clk)
      instn = instruction[i];
    #(PERIOD);
  end
  #(PERIOD*2) 
    finish = 1;
    $display("Simulation end by finish all patterns"); 
  #(1) 
    $finish;
end

reg [31:0] result;
integer error_cnt;

initial begin
  wait(finish == 1)
  f_out = $fopen("register.txt","w");
  $readmemh("golden_register.pat", golden);
  error_cnt = 0;
  for(i = 0; i<32; i=i+1)begin
    result = top.ID_stage.regfile.gpr[i];
    if(result!==golden[i])begin
      $fwrite(f_out,"gp %d : %d| %h !!! Incorrect !!!\n",i,$signed(result),result);
      error_cnt = error_cnt + 1;
    end
    else begin
      $fwrite(f_out,"gp %d : %d| %h\n",i,$signed(result),result);
    end
  end
  $fclose(f_out);
  if(error_cnt>0)begin
    $display("**************************************************");
    $display("There are %d errors in general purpose registers", error_cnt);
    $display("Please check register.txt, golden_register.txt, and instruction.txt for further infomation");
    $display("**************************************************");
  end
  else begin
    $display("**************************************************");
    $display("Congradulation! All of the registers are correct.");
    $display("All registers' values are dumped in register.txt");
    $display("**************************************************");
  end
end

endmodule

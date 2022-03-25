module test_alu;
reg clk, rst_n;
reg [7:0] inputA, inputB, true_out;
reg [3:0] instruction;
wire [7:0] alu_out;

reg [7:0] old_inputA, old_inputB, old_instruction;
reg [7:0] old1_inputA, old1_inputB, old1_instruction;
integer i, j, k, l;
integer outfile, infile, pat_error;

parameter CYCLE = 10;
parameter ALU_NUM = 6;
parameter N = 256;

// Instantiate ALU circuit module
lab2_alu my_alu(
  .clk(clk),
  .rst_n(rst_n),
  .inputA(inputA),
  .inputB(inputB),
  .instruction(instruction),
  .alu_out(alu_out)
);

//system 
initial begin : proc_system
  clk = 1;
  rst_n = 1;
  // system reset
  #(CYCLE) rst_n = 0;
  #(CYCLE) rst_n = 1;
end
always #(CYCLE/2) clk=~clk;

//pattern feeder
initial begin
  inputA = 0;
  inputB = 0;
  instruction = 0;
  wait(rst_n==0);
  wait(rst_n==1);
  for(k=0; k<6; k=k+1) begin
    for(i=0; i<N; i=i+1) begin
      for(j=0; j<N; j=j+1) begin
        @(negedge clk)instruction=k; inputA=i[7:0]; inputB=j[7:0];
      end
    end
  end
end

reg [27:0] golden [0:N*N*6-1];

//answer check
initial begin
  $readmemh("golden.dat",golden);
  pat_error = 0;
  wait(rst_n==0);
  wait(rst_n==1);
  #(CYCLE*2);
  for(l=0; l<6*N*N; l=l+1) begin
    @(negedge clk);
    if(alu_out!==golden[l][7:0])begin
      pat_error = pat_error + 1;
      $display("************* Pattern No.%d is wrong ************", l);
      $display("inputA = %b, inputB = %b, instruction = %b",golden[l][23:16],golden[l][15:8],golden[l][27:24]);  
      $display("golden = %b, but your answer is %b QQ Orz ",golden[l][7:0], alu_out);  
      $finish;
    end
  end
  $display("Congratulations!! The functionality of your ALU is correct!!");  
  #(CYCLE) $finish;
end


initial begin
   $fsdbDumpfile("lab2_alu.fsdb");
   $fsdbDumpvars;
end

// Main pattern


endmodule

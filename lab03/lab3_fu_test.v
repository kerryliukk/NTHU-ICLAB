// `timescale 1ns/1ps // set the timescale for the simulation
module lab3_fu_test;  // module of testbench

parameter CYCLE = 10; // use CYCLE to describe the clock period
parameter DATA_WIDTH = 16; // data width
parameter input_file = "golden2.dat";
parameter num_of_test_case = 320;

///// declare input(reg) and output(wire) /////

// use reg to declare inputs of the circuit //
// ex: reg [4:0] gray_in; or reg [SIZE-1:0] gray_in
reg clk;
reg rst_n;
reg signed [DATA_WIDTH-1:0] A;
reg signed [DATA_WIDTH-1:0] B;
reg signed [4:0] instruction;
integer i, j, k, l;
integer pat_error;

// use wire to declare outputs of the circuit //
// ex: wire [4:0] bin_out;
wire signed [DATA_WIDTH-1:0] F_o;

///// instantiate  module /////
// instantiate the module you finished in following format //
// module_name #(.parameter1(5),.parameter2(3)) unit_name (.port1(...), .port2(...), ...); //
// ex: gray2bin #(.SIZE(7)) U0 (.bin(x),.gray(y),.clk(z));
lab3_fu 
#(
  .DATA_WIDTH(16),
  .INS_WIDTH(5)
)
FU(
  .clk(clk), 
  .rst_n(rst_n), 
  .A(A), 
  .B(B), 
  .instruction(instruction), 
  .F_o(F_o)
);


// use the following commands to dump the waveform of the simulation //
// initial begin
//  $fsdbDumpfile("gray.fsdb"); // "gray.fsdb" can be replaced into any name you want
//  $fsdbDumpvars;              // but make sure in .fsdb format
// end





// the following command generates the behavior of the clock signal and system control
// #(x1) means delay x1 time, the time unit is declared at `timescale
always #(CYCLE/2) clk = ~clk; //clk toggles every half cycle
// System block set only clock, reset signal and the timeout finish. 
initial begin
  // 1. set the initial state of the clk and reset, ex: clk=0;
  clk = 0;
  rst_n = 0;
  // 2. set your reset behavior
  #(CYCLE) rst_n = 0;
  #(CYCLE) rst_n = 1;
  // 3. call finish function when the simulation runs time out.
  //    Proper constrain simulation time at beginning helps you reduce the debugging period.
  //    $finish <- this command indicates that the simulation is over
  //    Ex. #(CYCLE*LARGE_NUMBER) $finish;
  #(CYCLE*100000000) $finish;
end

// pattern feeding block, control when and what pattern to feed to the circuit.
// this block can be considered as a behavior model of a verification module or other modules interfacing your circuit.
reg [55:0] input_setting [num_of_test_case - 1:0];

initial begin
  // 1. set the initial state of the testing signal
  A = 0;
  B = 0;
  instruction = 0;
  wait(rst_n == 0);
  wait(rst_n == 1);
  
  // 2. finish your testbench here, you should verify all functions in ALU with different combination of input signals
  $readmemh(input_file, input_setting);
  for (i = 0; i < num_of_test_case; i = i + 1) begin
    @ (negedge clk);
    A = input_setting[i][55:40];
    B = input_setting[i][39:24];
    instruction = input_setting[i][23:16];
  end

  // 3. you can use wait or @(negedge clk), to control when to feed your pattern
  // ex: wait(rst_n==1) do something.../ @(negedge clk) do something...
  //    You can check the testbench in lab2 for full demenstration.
  // 4. you can use for or while loop to generate all possible inputs to verify your answer
  // ex: for(i=0;i<50;i=i+1)begin   // no i++ in verilog
  // 5. Besides generating patterns in testbench, you can also read patterns from external file.
  //    You can check the testbench in lab2 for full demenstration.
  // ex: reg [bitwidth-1:0] pattern_ary [0:pat_num-1];
  //     $readmemh("pattern.dat",pattern_ary);
  // It's suggested to use the method in 5, since we can generate patterns and results from other software(your algorithm),
  // and verify your circuit with reference algorithm. A reference pattern "golden.dat" is provided for (A=100,B=-201) requirement.
  // You can check the testbench in lab2 for full demenstration.
end

// output result checking block, control when to sample and verify the result.
// this block can be considered as a behavior model of a verification module or other modules interfacing your circuit.
reg [55:0] golden [num_of_test_case - 1:0];
initial begin
  // 0. Use the same control technique to control when to sample output result.
  // 1. use $display command to show the state of signal
  // ex: $display("x = %b", x); %b means to display x in binary, you can try %d, %h or others.
  // 2. you can also write the result to a text file and verify the result with other program
  // ex: integer  fp_w;
  //     fp_w = $fopen("data_in.txt");
  //     $fwrite(fp_w, "%d %d %d\n", a, b, c);
  //     $fdisplay(fp_w, "xxxxxxxxxxx %d", a);
  // 3. when displaying result, timing stamp is an important infomation, you can get time stamp with $time
  // ex: $display("%t happens xxx", $time);
  // As the suggestion in pattern feeding block, you can read the results generated from other software,
  // rather than write the same operations in testbench and circuit. It's useless to verify difference between a+b and a+b.
  $readmemh(input_file, golden);
  pat_error = 0;
  wait(rst_n == 0);
  wait(rst_n == 1);
  # (CYCLE * 2);
  for (l = 0; l < num_of_test_case; l = l + 1) begin
    @ (negedge clk);
    if (F_o != golden[l][15:0]) begin
      pat_error = pat_error + 1;
      $display("************* Pattern No.%d is wrong ************", l);
      $display("inputA = %b, inputB = %b, instruction = %b",golden[l][55:40],golden[l][39:24],golden[l][23:16]);
      $display("golden = %b, but your answer is %b QQ Orz ",golden[l][15:0], F_o);  
      $finish;
    end

    else begin
      $display("Pattern No.%4d is correct: A = %b, B = %b, ins = %b, exp = %b, res = %b", l ,golden[l][55:40], golden[l][39:24], golden[l][23:16], golden[l][15:0], F_o);
    end
  end
  $display("Congratulations!! The functionality of your ALU is correct!!");  
  #(CYCLE) $finish;
end

// Besides fixed pattern, you can use $random to generate random integer
// ex: a={$random} % 32   //return 0~31
// ex: a= min+{$random}%(max-min+1); // return min~ max

endmodule

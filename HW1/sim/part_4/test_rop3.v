module test_rop3;

// 1. variable declaration and clock connection
// -----------------------------
`define MODE_L 10
`define MODE_U 50
// declare variables and connect clock here
parameter N = 5;
reg clk;
reg [N-1:0] inputP, inputS, inputD;
reg [7:0] inputMode;
wire [N-1:0] lut256_out;
wire [N-1:0] smart_out;

reg [N-1:0] P_last, S_last, D_last;
reg [7:0]   Mode_last;
reg [N-1:0] P_lastlast, S_lastlast, D_lastlast;
reg [7:0]   Mode_lastlast;

parameter CYCLE = 10;
// parameter total = 256;
integer i, j, k, l;
integer _i, _j, _k, _l, idx;

initial begin
    clk = 0;
    while(1) #(CYCLE/2) clk = ~clk;
end


// -----------------------------



// 2. connect RTL module 
// -----------------------------

// add your module here
rop3_smart #(.N(N)) my_smart(
    .clk(clk), 
    .P(inputP), 
    .S(inputS), 
    .D(inputD), 
    .Mode(inputMode), 
    .Result(smart_out)
);

rop3_lut256 #(.N(N)) my_lut256(
  .clk(clk),
  .P(inputP),
  .S(inputS),
  .D(inputD),
  .Mode(inputMode),
  .Result(lut256_out)
);
// -----------------------------



// Don't modify this two blocks
// -----------------------------
// input preparation
initial begin
    input_preparation;
end
// output comparision
initial begin
    output_comparison;
end
// -----------------------------


// 3. implement the above two functions in the task file
`include "./rop3.task"


endmodule
module testbench;

parameter cyc = 10; //use "cyc" to represent the period

///// declare input(reg) and output(wire) /////

reg clk;
reg rst_n;
reg  enable;
wire [1:0]out_state;

///// declare  module /////

trafficlight #(.RED_TIME(3), .GREEN_TIME(2), .YELLOW_TIME(1))
u1
(
.clk(clk),
.enable(enable),
.rst_n(rst_n),
.out_state(out_state)
);

initial begin
  $fsdbDumpfile("tfliht.fsdb");
  $fsdbDumpvars;
end

integer i, pat;

////// clock //////
always #(cyc/2) clk = ~clk;

////// test patterns /////
initial begin
  clk=0;
  rst_n=1;
  #(cyc) enable=0; rst_n=0;
  #(cyc) rst_n=1;
  #(cyc) enable=1;
  #(cyc*15) enable=0;
  #(cyc*1000)
  $display("Simulaiton end by time out");
  $finish;
end

integer f_out, error_cnt;
reg [3:0] golden [0:19];
initial begin
  error_cnt = 0;
  $readmemh("golden_state.pat", golden);
  wait(enable==0);
  wait(enable==1);
  for(i=0; i<20; i=i+1)begin
    @(negedge clk)
      if(out_state !== golden[i])begin
        $display("time %t : current state should be %d, but your is %d | !!!Incorrect!!!", $time, golden[i],  out_state);
        error_cnt = error_cnt + 1;
      end
      else
	$display("time %t : Current State is %d", $time, out_state);     
 #(cyc);
  end
  $fclose(f_out);
  if(error_cnt===0)
	$display("Good! Your traffic light is correct");
  $finish;
end

endmodule

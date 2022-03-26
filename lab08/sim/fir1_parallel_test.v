`timescale 10ns/1ns
module test_fir;
///////////////////////////////////////////////////////////////
// Choose a small number first for debugging (avoid long simulation time)
parameter END_CYCLE = 1100;
///////////////////////////////////////////////////////////////
parameter Pattern_N = 1000;
parameter Golden_N  = Pattern_N - 15;
parameter CYCLE = 10;
parameter N = 32;
reg [N-1:0] x0, x1;
reg clk;
reg rst_n;
reg enable;
wire busy;
wire valid;
wire [N-1:0] y0, y1;

`define SDFFILE "../syn/netlist/fir1_syn.sdf"
`ifdef SDF
initial $sdf_annotate(`SDFFILE, U0);
fir1_parallel #(N) U0(
  .clk(clk),
  .rst_n(rst_n),
  .enable(enable),
  .x0(x0),
  .x1(x1),
  .busy(busy),
  .valid(valid),
  .y0(y0),
  .y1(y1)
);
`else 
fir1_parallel U0(
  .clk(clk),
  .rst_n(rst_n),
  .enable(enable),
  .x0(x0),
  .x1(x1),
  .busy(busy),
  .valid(valid),
  .y0(y0),
  .y1(y1)
);
`endif


initial begin
  $fsdbDumpfile("fir_parallel.fsdb");
  $fsdbDumpvars(U0);
end

integer i;
integer inp[Pattern_N:0];
integer truth[Golden_N:0];
integer n,fp_r,fp_w,fp_t;

//========== Import input data ==========//
initial begin
  fp_r = $fopen("ecg.csv", "r");
  fp_t = $fopen("data_truth.csv", "r");
  fp_w = $fopen("data_out.csv", "w");
  for(i=0; i<Pattern_N; i=i+1) begin
    n = $fscanf(fp_r, "%d", inp[i]);
  end
  for(i=0; i<Golden_N; i=i+1)begin
    n = $fscanf(fp_t, "%d", truth[i]);
  end
  $fclose(fp_r);
  $fclose(fp_w);
  $fclose(fp_t);
end

//========== Check procedure ==========//
// always check at negative edge of clk
integer k,error,correct;
initial begin
  k = 0;
  error = 0;
  correct = 0;

  while(1) begin
    @(negedge clk);
    if(valid) begin
      if(k > 1) begin
        if(y1 === truth[k-1]) begin
          $display("%d ns %d ok! %d(your) == %d(golden)", $time, k-1, y1, truth[k-1]);
          correct = correct + 1;
        end
        else begin
          $display("%d ns %d ng!!!! %d(your) != %d(golden)", $time, k-1, y1, truth[k-1]);
          error = error + 1;
        end
      end

      if(y0 === truth[k]) begin
        $display("%d ns %d ok! %d(your) == %d(golden)", $time, k, y0, truth[k]);
        correct = correct + 1;
      end
      else begin
        $display("%d ns %d ng!!!! %d(your) != %d(golden)", $time, k, y0, truth[k]);
        error = error + 1;
      end
      k = k + 2;
    end
  end
end

//========== Pattern feeder ==========//
integer index;
initial begin
  x0 = 0;
  x1 = 0;
  enable = 0;
  index = 0;

  wait(rst_n == 0);
  wait(rst_n == 1);
  @(negedge clk);
  enable = 1;
  while(index+1 < Pattern_N) begin
    @(negedge clk);
    if(!busy) begin
      x0 = inp[index];
      x1 = inp[index+1];
      index = index + 2;
    end
  end
  @(negedge clk);
  enable = 0;
end

//========== system reset ==========//
initial begin
  clk = 0;
  rst_n = 1;
  #(CYCLE) rst_n = 0;
  #(CYCLE) rst_n = 1;
end
always #(CYCLE/2) clk = ~clk;

//========== simulation stop ==========//
initial begin
  #(CYCLE*END_CYCLE);
  $display("%d ns: END CYCLE!", $time);

  if(error>0)
    $display("So sad, %d errors in total.", error);
  else if(correct != Golden_N)
    $display("So sad, there are %d data remaining.", Golden_N-correct);
  else
    $display("Congrates!! You can start synthesis now.");
  $finish;
end

endmodule

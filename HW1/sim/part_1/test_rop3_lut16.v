
`define CYCLE 10
`define TEST_DATA_NUM 1024
`define PATH_INPUT   "./data/rop3_lut16_input.dat"
`define PATH_GOLDEN  "./data/rop3_lut16_golden.dat"

module test_rop3_lut16;

parameter N = 8;


// create clk
reg clk;
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end


	

// RTL instantiation
wire [N-1:0] Result_RTL;
reg  [N-1:0] P_in, S_in, D_in;
reg  [7:0]   Mode_in;
rop3_lut16 #(.N(N)) ROP3_U0
(
  .clk(clk),
  .P(P_in),
  .S(S_in),
  .D(D_in),
  .Mode(Mode_in),
  .Result(Result_RTL)
);

// input feeding
integer fp_in;
integer input_i = 0;
reg [31:0] buff_in;
reg [N-1:0] P_last, S_last, D_last;
reg [7:0]   Mode_last;
reg [N-1:0] P_lastlast, S_lastlast, D_lastlast;
reg [7:0]   Mode_lastlast;
initial begin

    // input feeding init
    fp_in = $fopen(`PATH_INPUT, "r");
    Mode_in = 8'hzz;
    P_in    = 8'hzz;
    S_in    = 8'hzz;
    D_in    = 8'hzz;

    // input feeding start
    while(input_i < `TEST_DATA_NUM) begin
        @(posedge clk); #1;
	    {Mode_lastlast, P_lastlast, S_lastlast, D_lastlast} = {Mode_last, P_last, S_last, D_last};
        {Mode_last, P_last, S_last, D_last} = {Mode_in, P_in, S_in, D_in};
        $fscanf(fp_in, "%h", buff_in);
        {Mode_in, P_in, S_in, D_in} = buff_in;
        input_i = input_i + 1;
    end

    // input feeding stop
    $fclose(fp_in);
    #(`CYCLE);
    Mode_in = 8'hzz;
    P_in    = 8'hzz;
    S_in    = 8'hzz;
    D_in    = 8'hzz;
end
// output comparision
integer fp_gold;
integer output_i = 0;
integer total_error = 0;
reg [7:0] Result_Golden;
initial begin

    // output comparison init
    fp_gold = $fopen(`PATH_GOLDEN, "r");

    // output comparison start
    // two stage pipeline register delay
    @(negedge clk);
    @(negedge clk);
    while(output_i < `TEST_DATA_NUM) begin
        @(negedge clk);
        $fscanf(fp_gold, "%h", Result_Golden);

        if (Result_Golden !== Result_RTL) begin
            $display("!!!!! Comparison Fail @ pattern %0d !!!!!", output_i);
            $display("[pattern %0d]        Mode=%2h, {P,S,D}={%2h,%2h,%2h}, RTL=%2h, Answer=%2h",
                      output_i, Mode_lastlast, P_lastlast, S_lastlast, D_lastlast, Result_RTL, Result_Golden);
            total_error = total_error + 1;
        end else begin
            $display(">>>>> Comparison Pass @ pattern %0d <<<<<", output_i);
        end

        output_i = output_i + 1;
    end

    $fclose(fp_gold);
    if (total_error > 0) begin
        $display("\nxxxxxxxxxxx Comparison Fail xxxxxxxxxxx");
        $display("            Total %0d errors\n  Please check your error messages...", total_error);
        $display("xxxxxxxxxxx Comparison Fail xxxxxxxxxxx\n");

        if (total_error > `TEST_DATA_NUM*0.8) begin
            $display("! Hmm...There are so many errors, Did you make the output registered?\n");
        end
        
    end else begin
        $display("\n============= Congratulations =============");
        $display("    You can move on to the next part !");
        $display("============= Congratulations =============\n");
    end
    $finish;
end

endmodule

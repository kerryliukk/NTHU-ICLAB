module test_rop3_smart;
reg clk;
parameter N = 6;
reg [N-1:0] inputP, inputS, inputD;
reg [7:0] inputMode;
wire [N-1:0] lut256_out;
wire [N-1:0] smart_out;

reg [N-1:0] P_last, S_last, D_last;
reg [7:0]   Mode_last;
reg [N-1:0] P_lastlast, S_lastlast, D_lastlast;
reg [7:0]   Mode_lastlast;


parameter CYCLE = 10;
// parameter total = 16;
// parameter total = 256;
integer i, j, k, l;
integer _i, _j, _k, _l, idx;


// Instantiate smart circuit module
rop3_smart #(.N(N)) my_smart(
    .clk(clk), 
    .P(inputP), 
    .S(inputS), 
    .D(inputD), 
    .Mode(inputMode), 
    .Result(smart_out)
);

// Instantiate lut256 circuit module
rop3_lut256 #(.N(N)) my_lut256(
  .clk(clk),
  .P(inputP),
  .S(inputS),
  .D(inputD),
  .Mode(inputMode),
  .Result(lut256_out)
);



// always #(CYCLE/2) clk=~clk;
initial begin
    clk = 0;
    while(1) #(CYCLE/2) clk = ~clk;
end

// pattern feeder
initial begin
    // clk = 0;
    inputP = 0;
    inputS = 0;
    inputD = 0;
    inputMode = 0;
    for (i = 0; i < 256; i = i + 1) begin
        for (j = 0; j < 2 ** N; j = j + 1) begin
            for (k = 0; k < 2 ** N; k = k + 1) begin
                for (l = 0; l < 2 ** N; l = l + 1) begin
                    @(negedge clk)
	                {Mode_lastlast, P_lastlast, S_lastlast, D_lastlast} = {Mode_last, P_last, S_last, D_last};
                    {Mode_last, P_last, S_last, D_last} = {inputMode, inputP, inputS, inputD};
                    {inputMode, inputP, inputS, inputD} = {i[7:0], j[N-1:0], k[N-1:0], l[N-1:0]};
                    // $display("inputP = %b; inputS = %b, inputD = %b, inputMode = %b", inputP, inputS, inputD, inputMode);
                    // $display("lut256_out = %b, my answer is %b", lut256_out, smart_out);
                end
            end
        end
    end
end

// answer check 
initial begin
    idx = 0;
    #(CYCLE * 2);
    for (_i = 0; _i < 256; _i = _i + 1) begin
        $display("Start to verify Mode = %b (%3d)", inputMode, inputMode);
        for (_j = 0; _j < 2 ** N; _j = _j + 1) begin
            for (_k = 0; _k < 2 ** N; _k = _k + 1) begin
                for (_l = 0; _l < 2 ** N; _l = _l + 1) begin
                    @(negedge clk);
                    // $display("P = %b, S = %b, D = %b, Mode = %b, lut256_out = %b, smart_out is %b", inputP, inputS, inputD, inputMode, lut256_out, smart_out);
                    if (lut256_out != smart_out) begin
                        $display("************* Pattern No.%d is wrong ************", idx);
                        $display("inputP = %b; inputS = %b, inputD = %b, inputMode = %b", inputP, inputS, inputD, inputMode);
                        $display("lut256_out = %b, but smart is %b", lut256_out, smart_out);
                        $finish;
                    end
                    // else begin
                    //     $display("************* Pattern No.%d is CORRECT ************", idx);
                    //     $display("inputP = %b; inputS = %b, inputD = %b, inputMode = %b", inputP, inputS, inputD, inputMode);
                    //     $display("lut256_out = %b, smart is %b", lut256_out, smart_out);
                    // end

                    
                end
            end
        end
    end
    $display("ALL test cases are CORRECT!");
    $display("The functionality of my SMART ROP3 is correct!!");
    #(CYCLE) $finish;
end


// initial begin
//    $fsdbDumpfile("lab3_part2.fsdb");
//    $fsdbDumpvars;
// end

endmodule
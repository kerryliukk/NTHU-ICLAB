module test_rop3_smart;
reg clk;
reg [7:0] inputP, inputS, inputD;
reg [7:0] inputMode;
wire [7:0] lut16_out;
wire [7:0] smart_out;

parameter N = 8;
reg [N-1:0] P_last, S_last, D_last;
reg [7:0]   Mode_last;
reg [N-1:0] P_lastlast, S_lastlast, D_lastlast;
reg [7:0]   Mode_lastlast;


parameter CYCLE = 10;
// parameter total = 256;
integer i, j, k, l, pat_error;
integer _i, _j, _k, _l, idx;


// Instantiate smart circuit module
rop3_smart #(.N(8)) my_smart(
    .clk(clk), 
    .P(inputP), 
    .S(inputS), 
    .D(inputD), 
    .Mode(inputMode), 
    .Result(smart_out)
);

// Instantiate lut16 circuit module
rop3_lut16 #(.N(N)) my_lut(
  .clk(clk),
  .P(inputP),
  .S(inputS),
  .D(inputD),
  .Mode(inputMode),
  .Result(lut16_out)
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
    for (i = 0; i < 2 ** N; i = i + 1) begin
        for (j = 0; j < 2 ** N; j = j + 1) begin
            for (k = 0; k < 2 ** N; k = k + 1) begin
                for (l = 0; l < 15; l = l + 1) begin
                    @(negedge clk)
	                // {Mode_lastlast, P_lastlast, S_lastlast, D_lastlast} = {Mode_last, P_last, S_last, D_last};
                    // {Mode_last, P_last, S_last, D_last} = {inputMode, inputP, inputS, inputD};
                    {inputP, inputS, inputD} = {i[7:0], j[7:0], k[7:0]};
                    case(l)
                        0: inputMode = 8'h00;
                        1: inputMode = 8'h11;
                        2: inputMode = 8'h33;
                        3: inputMode = 8'h44;
                        4: inputMode = 8'h55;
                        5: inputMode = 8'h5A;
                        6: inputMode = 8'h66;
                        7: inputMode = 8'h88;
                        8: inputMode = 8'hBB;
                        9: inputMode = 8'hC0;
                        10: inputMode = 8'hCC;
                        11: inputMode = 8'hEE;
                        12: inputMode = 8'hF0;
                        13: inputMode = 8'hFB;
                        14: inputMode = 8'hFF;
                        default: inputMode = 8'h00;
                    endcase

                    // $display("inputP = %b; inputS = %b, inputD = %b, inputMode = %b", inputP, inputS, inputD, inputMode);
                    // $display("lut16_out = %b, my answer is %b", lut16_out, smart_out);
                end
            end
        end
    end
    // $finish;
end

// answer check 
initial begin
    pat_error = 0;
    idx = 0;
    #(CYCLE * 2);
    for (_i = 0; _i < 2 ** N; _i = _i + 1) begin
        for (_j = 0; _j < 2 ** N; _j = _j + 1) begin
            for (_k = 0; _k < 2 ** N; _k = _k + 1) begin
                for (_l = 0; _l < 15; _l = _l + 1) begin
                    @(negedge clk);
                    // $display("P = %b, S = %b, D = %b, Mode = %b, lut16_out = %b, smart_out is %b", inputP, inputS, inputD, inputMode, lut16_out, smart_out);
                    // if (lut16_out == 0)
                    //     $display("fuck %d", idx);
                    if (lut16_out != smart_out) begin
                        $display("************* Pattern No.%d is wrong ************", idx);
                        $display("inputP = %b; inputS = %b, inputD = %b, inputMode = %b", inputP, inputS, inputD, inputMode);
                        $display("lut16_out = %b, but smart is %b", lut16_out, smart_out);
                        pat_error = pat_error + 1;
                        $finish;
                    end
                    else begin
                        // $display("************* Pattern No.%d is CORRECT ************", idx);
                        // $display("inputP = %b; inputS = %b, inputD = %b, inputMode = %b", inputP, inputS, inputD, inputMode);
                        // $display("lut16_out = %b, smart is %b", lut16_out, smart_out);
                    end

                    if (idx % 10000000 == 0)
                        $display("We passed %d test cases.", idx);
                    idx = idx + 1;
                end
            end
        end
    end
    $display("ALL %d test cases are CORRECT!", idx);
    $display("The functionality of my SMART ROP3 is correct!!");
    #(CYCLE) $finish;
end


// initial begin
//    $fsdbDumpfile("lab3_part2.fsdb");
//    $fsdbDumpvars;
// end

endmodule
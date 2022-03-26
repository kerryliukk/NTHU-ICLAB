module test_enigma_part1;
reg clk, srstn, load, encrypt, crypt_mode;
reg [8-1:0] load_idx;
reg [6-1:0] code_in;


wire [6-1:0] code_out;
wire code_valid;

parameter CYCLE = 10;

integer i, j, pat_error;

// behavior_model my_behavior(.clk(clk),
//                            .srstn(srstn),
//                            .load(load),
//                            .encrypt(encrypt),
//                            .crypt_mode(crypt_mode),
//                            .load_idx(load_idx),
//                            .code_in(code_in),
//                            .code_out(code_out),
//                            .code_valid(code_valid)
// );

reg [6-1:0] plain [0:23-1];
reg [6-1:0] ans [0:23-1];
reg [6-1:0] rotorA [0:64-1];

enigma_part1 my_part1(.clk(clk),
                      .srstn(srstn),
                      .load(load),
                      .encrypt(encrypt),
                      .crypt_mode(crypt_mode),
                      .load_idx(load_idx),
                      .code_in(code_in),
                      .code_out(code_out),
                      .code_valid(code_valid)
);

initial begin
    clk = 1;
    srstn = 1;

    load = 1'b0;
    encrypt = 1'b0;
    crypt_mode = 1'b0;
    load_idx = 8'b0;

    // system reset
    #(CYCLE) srstn = 0;
    #(CYCLE) srstn = 1;
end

always #(CYCLE/2) clk = ~clk;




// pattern feeder
initial begin
    $readmemh("../sim/pat/plaintext1.dat", plain);
    $readmemh("../sim/rotor/rotorA.dat", rotorA);

    wait(srstn == 0);
    wait(srstn == 1);
    @(negedge clk) load = 1'b1;
    // #(CYCLE * 1);
    for (i = 0; i < 64; i = i + 1) begin
        @(negedge clk)
            code_in = rotorA[i];
            load_idx = i;
    end
    #(CYCLE * 1);
    load = 1'b0;
    #(CYCLE * 1);
    encrypt = 1'b1;

    for (i = 0; i < 23; i = i + 1) begin
        // "I love NTHU iclab!!! :D\n"
        @(negedge clk) code_in = plain[i];
    end
end

// answer check
initial begin
    $readmemh("../sim/pat/ciphertext1.dat", ans);
    pat_error = 0;
    wait(encrypt == 1'b1);
    #(CYCLE * 1);

    for (j = 0; j < 23; j = j + 1) begin
        @(negedge clk);
        if (code_out != ans[j]) begin
            $display("************* Pattern No.%2d is wrong ************", j);
            $display("ans = %2h, but your output is %2h", ans[j], code_out);
        end

        else begin
            $display("Pattern %2d CORRECT!! ans = %2h, output = %2h", j, ans[j], code_out);
        end
    end
    $display("\ntotal error = %2d", pat_error);
    #(CYCLE) $finish;
end

initial begin
    // $fsdbDumpfile("part1_behav.fsdb");
    $fsdbDumpfile("part1_enigma.fsdb");
    $fsdbDumpvars("+mda");
end


endmodule
module test_enigma_part2;
reg clk, srstn, load, encrypt, crypt_mode;
reg [8-1:0] load_idx;
reg [6-1:0] code_in;


wire [6-1:0] code_out;
wire code_valid;

parameter CYCLE = 10;

integer i, j, pat_error;


reg [6-1:0] data_in [0:24-1];
reg [6-1:0] ans [0:24-1];
reg [6-1:0] rotorA [0:64-1];
reg [6-1:0] rotorB [0:64-1];
reg [6-1:0] rotorC [0:64-1];

enigma_part2 my_part2(.clk(clk),
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
    `ifdef EN
        crypt_mode = 1'b0;
    `elsif DE
        crypt_mode = 1'b1;
    `else
        crypt_mode = 1'b0;
    `endif

    load_idx = 8'b0;

    // system reset
    #(CYCLE) srstn = 0;
    #(CYCLE) srstn = 1;
end

always #(CYCLE/2) clk = ~clk;




// pattern feeder
initial begin
    `ifdef EN
        $readmemh("../sim/pat/plaintext1.dat", data_in);
    `elsif DE
        $readmemh("../sim/pat/ciphertext1.dat", data_in);
    `else
        $readmemh("../sim/pat/plaintext1.dat", data_in);
    `endif

    $readmemh("../sim/rotor/rotorA.dat", rotorA);
    $readmemh("../sim/rotor/rotorB.dat", rotorB);
    $readmemh("../sim/rotor/rotorC.dat", rotorC);

    wait(srstn == 0);
    wait(srstn == 1);
    @(negedge clk) load = 1'b1;
    // #(CYCLE * 1);
    for (i = 0; i < 64; i = i + 1) begin
        @(negedge clk)
            code_in = rotorA[i];
            load_idx = i;
    end
    for (i = 64; i < 128; i = i + 1) begin
        @(negedge clk)
            code_in = rotorB[i - 64];
            load_idx = i;
    end
    for (i = 128; i < 192; i = i + 1) begin
        @(negedge clk)
            code_in = rotorC[i - 128];
            load_idx = i;
    end
    # (CYCLE * 1);
    load = 1'b0;
    # (CYCLE * 1);
    encrypt = 1'b1;

    for (i = 0; i < 24; i = i + 1) begin
        // "I love NTHU iclab!!! :D\n"
        @(negedge clk) code_in = data_in[i];
    end
end

// answer check
initial begin
    `ifdef EN
        $readmemh("../sim/pat/ciphertext1.dat", ans);
    `elsif DE
        $readmemh("../sim/pat/plaintext1.dat", ans);
    `else
        $readmemh("../sim/pat/ciphertext1.dat", ans);
    `endif

    pat_error = 0;
    wait(encrypt == 1'b1);
    #(CYCLE * 2);

    for (j = 0; j < 24; j = j + 1) begin
        @(negedge clk);
        if (code_out != ans[j]) begin
            $display("************* Pattern No.%2d is wrong ************", j);
            $display("ans = %2h, but your output is %2h", ans[j], code_out);
            pat_error = pat_error + 1;
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
    $fsdbDumpfile("part2_enigma.fsdb");
    $fsdbDumpvars("+mda");
end


endmodule
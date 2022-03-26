module test_enigma_display;
reg clk, srstn, load, encrypt, crypt_mode;
reg [8-1:0] load_idx;
reg [6-1:0] code_in;


wire [6-1:0] code_out;
wire code_valid;

parameter CYCLE = 10;

integer i, j, pat_error;
integer fh;

`ifdef CIPHERTEXT1
    localparam TEXT_LENGTH = 24;
`elsif CIPHERTEXT2
    localparam TEXT_LENGTH = 112;
`elsif CIPHERTEXT3
    localparam TEXT_LENGTH = 122836;
`else
    localparam TEXT_LENGTH = 24;

`endif

reg [6-1:0] plain [0:TEXT_LENGTH - 1];
reg [6-1:0] ans [0:TEXT_LENGTH - 1];
reg [6-1:0] rotorA [0:64-1];
reg [6-1:0] rotorB [0:64-1];
reg [6-1:0] rotorC [0:64-1];

reg [8-1:0] ascii_out;

// `include "display_enigma_code.v"


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
    crypt_mode = 1'b1;    // only decrypt in this file
    load_idx = 8'b0;

    // system reset
    #(CYCLE) srstn = 0;
    #(CYCLE) srstn = 1;
end

always #(CYCLE/2) clk = ~clk;




// pattern feeder
initial begin
    `ifdef CIPHERTEXT1
        $readmemh("../sim/pat/ciphertext1.dat", plain);
    `elsif CIPHERTEXT2
        $readmemh("../sim/pat/ciphertext2.dat", plain);
    `elsif CIPHERTEXT3
        $readmemh("../sim/pat/ciphertext3.dat", plain);
    `else
        $readmemh("../sim/pat/ciphertext1.dat", plain);
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

    for (i = 0; i < TEXT_LENGTH; i = i + 1) begin
        // "I love NTHU iclab!!! :D\n"
        @(negedge clk) code_in = plain[i];
    end
end

// answer check
initial begin

    $readmemh("../sim/pat/plaintext1.dat", ans);
    pat_error = 0;
    wait(encrypt == 1'b1);
    #(CYCLE * 2);
    $display("text length = %d", TEXT_LENGTH);
    
    `ifdef CIPHERTEXT2
        fh = $fopen("plaintext2_ascii.dat", "w");
    `elsif CIPHERTEXT3
        fh = $fopen("plaintext3_ascii.dat", "w");
    `else
        fh = $fopen("other_input.dat", "w");
    `endif

    for (j = 0; j < TEXT_LENGTH; j = j + 1) begin
        @(negedge clk);
        // if (code_out != ans[j]) begin
        //     $display("************* Pattern No.%2d is wrong ************", j);
        //     $display("ans = %2h, but your output is %2h", ans[j], code_out);
        //     pat_error = pat_error + 1;
        // end

        // else begin
        //     $display("Pattern %2d CORRECT!! ans = %2h, output = %2h", j, ans[j], code_out);
        // end
        // $display("%2h", code_out);
        case (code_out) 
            6'h00: ascii_out = 8'h61; //'a'
            6'h01: ascii_out = 8'h62; //'b'
            6'h02: ascii_out = 8'h63; //'c'
            6'h03: ascii_out = 8'h64; //'d'
            6'h04: ascii_out = 8'h65; //'e'
            6'h05: ascii_out = 8'h66; //'f'
            6'h06: ascii_out = 8'h67; //'g'
            6'h07: ascii_out = 8'h68; //'h'
            6'h08: ascii_out = 8'h69; //'i'
            6'h09: ascii_out = 8'h6a; //'j'
            6'h0a: ascii_out = 8'h6b; //'k'
            6'h0b: ascii_out = 8'h6c; //'l'
            6'h0c: ascii_out = 8'h6d; //'m'
            6'h0d: ascii_out = 8'h6e; //'n'
            6'h0e: ascii_out = 8'h6f; //'o'
            6'h0f: ascii_out = 8'h70; //'p'
            6'h10: ascii_out = 8'h71; //'q'
            6'h11: ascii_out = 8'h72; //'r'
            6'h12: ascii_out = 8'h73; //'s'
            6'h13: ascii_out = 8'h74; //'t'
            6'h14: ascii_out = 8'h75; //'u'
            6'h15: ascii_out = 8'h76; //'v'
            6'h16: ascii_out = 8'h77; //'w'
            6'h17: ascii_out = 8'h78; //'x'
            6'h18: ascii_out = 8'h79; //'y'
            6'h19: ascii_out = 8'h7a; //'z'
            6'h1a: ascii_out = 8'h20; //' '
            6'h1b: ascii_out = 8'h21; //'!'
            6'h1c: ascii_out = 8'h2c; //','
            6'h1d: ascii_out = 8'h2d; //'-'
            6'h1e: ascii_out = 8'h2e; //'.'
            6'h1f: ascii_out = 8'h0a; //'\n' (change line)
            6'h20: ascii_out = 8'h41; //'A'
            6'h21: ascii_out = 8'h42; //'B'
            6'h22: ascii_out = 8'h43; //'C'
            6'h23: ascii_out = 8'h44; //'D'
            6'h24: ascii_out = 8'h45; //'E'
            6'h25: ascii_out = 8'h46; //'F'
            6'h26: ascii_out = 8'h47; //'G'
            6'h27: ascii_out = 8'h48; //'H'
            6'h28: ascii_out = 8'h49; //'I'
            6'h29: ascii_out = 8'h4a; //'J'
            6'h2a: ascii_out = 8'h4b; //'K'
            6'h2b: ascii_out = 8'h4c; //'L'
            6'h2c: ascii_out = 8'h4d; //'M'
            6'h2d: ascii_out = 8'h4e; //'N'
            6'h2e: ascii_out = 8'h4f; //'O'
            6'h2f: ascii_out = 8'h50; //'P'
            6'h30: ascii_out = 8'h51; //'Q'
            6'h31: ascii_out = 8'h52; //'R'
            6'h32: ascii_out = 8'h53; //'S'
            6'h33: ascii_out = 8'h54; //'T'
            6'h34: ascii_out = 8'h55; //'U'
            6'h35: ascii_out = 8'h56; //'V'
            6'h36: ascii_out = 8'h57; //'W'
            6'h37: ascii_out = 8'h58; //'X'
            6'h38: ascii_out = 8'h59; //'Y'
            6'h39: ascii_out = 8'h5a; //'Z'
            6'h3a: ascii_out = 8'h3a; //':'
            6'h3b: ascii_out = 8'h23; //'#'
            6'h3c: ascii_out = 8'h3b; //';'
            6'h3d: ascii_out = 8'h5f; //'_'
            6'h3e: ascii_out = 8'h2b; //'+'
            6'h3f: ascii_out = 8'h26; //'&'
        endcase
        // $write("%c", ascii_out);
        $fwrite(fh, "%c", ascii_out);
        
    end
    // $display("\ntotal error = %2d", pat_error);
    $fclose(fh);
    #(CYCLE) $finish;
end

// initial begin
//     // $fsdbDumpfile("part1_behav.fsdb");
//     $fsdbDumpfile("part2_enigma.fsdb");
//     $fsdbDumpvars("+mda");
// end


endmodule
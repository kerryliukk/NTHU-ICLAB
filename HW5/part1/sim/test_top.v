`timescale 1ns/100ps
`define PAT_NUM 0 // we only use test image #0 for validation in this homework

module test_top;

localparam CH_NUM = 4;
localparam ACT_PER_ADDR = 4;
localparam BW_PER_ACT = 12;
localparam BW_PER_SRAM_GROUP_ADDR = CH_NUM*ACT_PER_ADDR*BW_PER_ACT;
localparam Pattern_N = 28*28;
localparam END_CYCLES = 10000; // you can enlarge the cycle count limit for longer simulation
real CYCLE = 10;

localparam UNSHUFFLE = 0;
localparam A0 = 0, A1 = 1, A2 = 2, A3 = 3, B0 = 4;

// ===== module I/O ===== //
reg clk;
reg rst_n;

reg enable;
reg [BW_PER_ACT-1:0] input_data;  
wire busy;
wire valid;

wire sram_wen_a0;
wire sram_wen_a1;
wire sram_wen_a2;
wire sram_wen_a3;

wire [5:0] sram_raddr_a0;
wire [5:0] sram_raddr_a1;
wire [5:0] sram_raddr_a2;
wire [5:0] sram_raddr_a3;

wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a0;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a1;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a2;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a3;

wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a;  
wire [5:0] sram_waddr_a;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_wdata_a;  

// ===== instantiation ===== //
Convnet_top #(
.CH_NUM(CH_NUM),
.ACT_PER_ADDR(ACT_PER_ADDR),
.BW_PER_ACT(BW_PER_ACT)
)
Conv_top (
.clk(clk),
.rst_n(rst_n),
.enable(enable),
.busy(busy),
.input_data(input_data),
.valid(valid),

.sram_rdata_a0(sram_rdata_a0),
.sram_rdata_a1(sram_rdata_a1),
.sram_rdata_a2(sram_rdata_a2),
.sram_rdata_a3(sram_rdata_a3),

.sram_raddr_a0(sram_raddr_a0),
.sram_raddr_a1(sram_raddr_a1),
.sram_raddr_a2(sram_raddr_a2),
.sram_raddr_a3(sram_raddr_a3),

.sram_wen_a0(sram_wen_a0),
.sram_wen_a1(sram_wen_a1),
.sram_wen_a2(sram_wen_a2),
.sram_wen_a3(sram_wen_a3),

.sram_wordmask_a(sram_wordmask_a),

.sram_waddr_a(sram_waddr_a),
.sram_wdata_a(sram_wdata_a)
);

// ===== sram connection ===== //
sram_36x192b sram_36x192b_a0(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a0),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a0), 
.rdata(sram_rdata_a0)
);

sram_36x192b sram_36x192b_a1(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a1),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a1), 
.rdata(sram_rdata_a1)
);

sram_36x192b sram_36x192b_a2(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a2),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a2), 
.rdata(sram_rdata_a2)
);

sram_36x192b sram_36x192b_a3(
.clk(clk),
.wordmask(sram_wordmask_a),
.csb(1'b0),
.wsb(sram_wen_a3),
.wdata(sram_wdata_a), 
.waddr(sram_waddr_a), 
.raddr(sram_raddr_a3), 
.rdata(sram_rdata_a3)
);

// ===== waveform dumpping ===== //
initial begin
    $fsdbDumpfile("hw5_part1.fsdb");
    $fsdbDumpvars("+mda");
end

// ===== golden answers ===== //
reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a0 [0:15];  
reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a1 [0:11];  
reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a2 [0:11];  
reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a3 [0:8];  

initial begin
    $readmemb("golden/unshuffle_a0.dat", unshuffle_ans_a0);
    $readmemb("golden/unshuffle_a1.dat", unshuffle_ans_a1);
    $readmemb("golden/unshuffle_a2.dat", unshuffle_ans_a2);
    $readmemb("golden/unshuffle_a3.dat", unshuffle_ans_a3);
end

// ===== system reset ===== //
initial begin
    clk = 0;
    rst_n = 1;
    enable = 0;
    input_data = 0;
end

always #(CYCLE/2) clk = ~clk;

initial begin
    #(CYCLE*END_CYCLES);
    $display("\n========================================================");
    $display("You have exceeded the cycle count limit.");
    $display("Try to debug your code or you can enlarge the cycle count limit!");
    $display("========================================================");
    $finish;
end

// ===== input feeding ===== //
reg [BW_PER_ACT-1:0] mem_img [0:Pattern_N-1];
integer i = 0;

initial begin
    bmp2reg(`PAT_NUM);    //load bmp into mem
    $display("The following is input image !!");
    display_reg;
    $display();

    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;
    enable = 1'b1;

    while(i < Pattern_N) begin
        @(negedge clk);
        if(~busy) begin
            input_data = mem_img[i];
            i = i+1;
        end
    end
end

// ===== output comparision ===== //
integer m;
integer error_bank0 = 0, error_bank1 = 0, error_bank2 = 0, error_bank3 = 0;
integer error_total;

initial begin
    wait(valid);
    @(negedge clk);

    $display("Start checking UNSHUFFLE layer ...\n");
    for(m=0; m<4; m=m+1) begin
        if(unshuffle_ans_a0[m] === sram_36x192b_a0.mem[m]) begin
            $display("Sram #A0 address %0d PASS!", m);
        end else begin
            $display("Sram #A0 address %0d FAIL!", m);
            display_error(A0, UNSHUFFLE, m, 0);
            error_bank0 = error_bank0 + 1;
        end
    end
    for(m=6; m<10; m=m+1) begin
        if(unshuffle_ans_a0[m-2] === sram_36x192b_a0.mem[m])
            $display("Sram #A0 address %0d PASS!", m);
        else begin
            $display("Sram #A0 address %0d FAIL!", m);
            display_error(A0, UNSHUFFLE, m, 2);
            error_bank0 = error_bank0 + 1;
        end
    end
    for(m=12; m<16; m=m+1) begin
        if(unshuffle_ans_a0[m-4] === sram_36x192b_a0.mem[m])
            $display("Sram #A0 address %0d PASS!", m);
        else begin
            $display("Sram #A0 address %0d FAIL!", m);
            display_error(A0, UNSHUFFLE, m, 4);
            error_bank0 = error_bank0 + 1;
        end
    end
    for(m=18; m<22; m=m+1) begin
        if(unshuffle_ans_a0[m-6] === sram_36x192b_a0.mem[m])
            $display("Sram #A0 address %0d PASS!", m);
        else begin
            $display("Sram #A0 address %0d FAIL!", m);
            display_error(A0, UNSHUFFLE, m, 6);
            error_bank0 = error_bank0 + 1;
        end
    end

    $display("========================================================");
    if(error_bank0 == 0) begin
        $display("Unshuffle results in sram #A0 are successfully passed!");
    end else begin
        $display("Unshuffle results in sram #A0 have %0d errors!", error_bank0);
    end
    $display("========================================================\n");

    for(m=0; m<3; m=m+1) begin
        if(unshuffle_ans_a1[m] === sram_36x192b_a1.mem[m]) begin
            $display("Sram #A1 address %0d PASS!", m);
        end else begin
            $display("Sram #A1 address %0d FAIL!", m);
            display_error(A1, UNSHUFFLE, m, 0);
            error_bank1 = error_bank1 + 1;
        end
    end
    for(m=6; m<9; m=m+1) begin
        if(unshuffle_ans_a1[m-3] === sram_36x192b_a1.mem[m]) begin
            $display("Sram #A1 address %0d PASS!", m);
        end else begin
            $display("Sram #A1 address %0d FAIL!", m);
            display_error(A1, UNSHUFFLE, m, 3);
            error_bank1 = error_bank1 + 1;
        end
    end
    for(m=12; m<15; m=m+1) begin
        if(unshuffle_ans_a1[m-6] === sram_36x192b_a1.mem[m]) begin
            $display("Sram #A1 address %0d PASS!", m);
        end else begin
            $display("Sram #A1 address %0d FAIL!", m);
            display_error(A1, UNSHUFFLE, m, 6);
            error_bank1 = error_bank1 + 1;
        end
    end
    for(m=18; m<21; m=m+1) begin
        if(unshuffle_ans_a1[m-9] === sram_36x192b_a1.mem[m]) begin
            $display("Sram #A1 address %0d PASS!", m);
        end else begin
            $display("Sram #A1 address %0d FAIL!", m);
            display_error(A1, UNSHUFFLE, m, 9);
            error_bank1 = error_bank1 + 1;
        end
    end
    $display("========================================================");
    if(error_bank1 == 0) begin
        $display("Unshuffle results in sram #A1 are successfully passed!");
    end else begin
        $display("Unshuffle results in sram #A1 have %0d errors!", error_bank1);
    end
    $display("========================================================\n");

    for(m=0; m<4; m=m+1) begin
        if(unshuffle_ans_a2[m] === sram_36x192b_a2.mem[m]) begin
            $display("Sram #A2 address %0d PASS!", m);
        end else begin
            $display("Sram #A2 address %0d FAIL!", m);
            display_error(A2, UNSHUFFLE, m, 0);
            error_bank2 = error_bank2 + 1;
        end
    end
    for(m=6; m<10; m=m+1) begin
        if(unshuffle_ans_a2[m-2] === sram_36x192b_a2.mem[m]) begin
            $display("Sram #A2 address %0d PASS!", m);
        end else begin
            $display("Sram #A2 address %0d FAIL!", m);
            display_error(A2, UNSHUFFLE, m, 2);
            error_bank2 = error_bank2 + 1;
        end
    end
    for(m=12; m<16; m=m+1) begin
        if(unshuffle_ans_a2[m-4] === sram_36x192b_a2.mem[m]) begin
            $display("Sram #A2 address %0d PASS!", m);
        end else begin
            $display("Sram #A2 address %0d FAIL!", m);
            display_error(A2, UNSHUFFLE, m, 4);
            error_bank2 = error_bank2 + 1;
        end
    end
    $display("========================================================");
    if(error_bank2 == 0) begin
        $display("Unshuffle results in sram #A2 are successfully passed!");
    end else begin
        $display("Unshuffle results in sram #A2 have %0d errors!", error_bank2);
    end
    $display("========================================================\n");

    for(m=0; m<3; m=m+1) begin
        if(unshuffle_ans_a3[m] === sram_36x192b_a3.mem[m]) begin
            $display("Sram #A3 address %0d PASS!", m);
        end else begin
            $display("Sram #A3 address %0d FAIL!", m);
            display_error(A3, UNSHUFFLE, m, 0);
            error_bank3 = error_bank3 + 1;
        end
    end
    for(m=6; m<9; m=m+1) begin
        if(unshuffle_ans_a3[m-3] === sram_36x192b_a3.mem[m]) begin
            $display("Sram #A3 address %0d PASS!", m);
        end else begin
            $display("Sram #A3 address %0d FAIL!", m);
            display_error(A3, UNSHUFFLE, m, 3);
            error_bank3 = error_bank3 + 1;
        end
    end
    for(m=12; m<15; m=m+1) begin
        if(unshuffle_ans_a3[m-6] === sram_36x192b_a3.mem[m]) begin
            $display("Sram #A3 address %0d PASS!", m);
        end else begin
            $display("Sram #A3 address %0d FAIL!", m);
            display_error(A3, UNSHUFFLE, m, 6);
            error_bank3 = error_bank3 + 1;
        end
    end
    $display("========================================================");
    if(error_bank3 == 0) begin
        $display("Unshuffle results in sram #A3 are successfully passed!");
    end else begin
        $display("Unshuffle results in sram #A3 have %0d errors!", error_bank3);
    end
    $display("========================================================");

    error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

    $display("\n========================================================");
    if(error_total == 0) begin
        $display("Congratulations! Your UNSHUFFLE layer is correct!");
        $display("You pass part1 simulation.");
    end else begin
        $display("There are total %0d errors in your UNSHUFFLE layer.", error_total);
    end
    $display("========================================================");
    $finish;
end

task bmp2reg(
input [31:0] pat_no
);

    reg [23*8-1:0] bmp_filename;
    integer this_i, this_j, i, j;
    integer file_in;
    reg [7:0] char_in;

    begin
        bmp_filename = "../../bmp/test_0000.bmp";
        bmp_filename[8*8-1:7*8] = (pat_no/1000)+48;
        bmp_filename[7*8-1:6*8] = (pat_no%1000)/100+48;
        bmp_filename[6*8-1:5*8] = (pat_no%100)/10+48;
        bmp_filename[5*8-1:4*8] = pat_no%10+48;

        file_in = $fopen(bmp_filename, "rb");

        // skip the header
        for(this_i=0; this_i<1078; this_i=this_i+1)
           char_in = $fgetc(file_in);

        for(this_i=27; this_i>=0; this_i=this_i-1) begin
            for(this_j=0; this_j<28; this_j=this_j+1) begin //four-byte alignment
                char_in = $fgetc(file_in);
                if(char_in <= 127)  
                    mem_img[this_i*28 + this_j] = char_in;
                else 
                    mem_img[this_i*28 + this_j] = 127;
            end
        end
    end
endtask

task display_reg;
    
    integer this_i, this_j;

    begin
        for(this_i=0; this_i<28; this_i=this_i+1) begin
            for(this_j=0; this_j<28; this_j=this_j+1) begin
               $write("%d", mem_img[this_i*28 + this_j]);
            end
            $write("\n");
        end
    end

endtask

task display_error(
input [2:0] which_sram,
input [1:0] layer,
input integer addr,
input integer ans_offset
);
    begin
        case(which_sram)
            A0: begin
                if(layer == UNSHUFFLE) begin
                    $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                        $signed(sram_36x192b_a0.mem[addr][191:180]), $signed(sram_36x192b_a0.mem[addr][179:168]),
                        $signed(sram_36x192b_a0.mem[addr][167:156]), $signed(sram_36x192b_a0.mem[addr][155:144]), 
                        $signed(sram_36x192b_a0.mem[addr][143:132]), $signed(sram_36x192b_a0.mem[addr][131:120]),
                        $signed(sram_36x192b_a0.mem[addr][119:108]), $signed(sram_36x192b_a0.mem[addr][107:96]),
                        $signed(sram_36x192b_a0.mem[addr][95:84]),   $signed(sram_36x192b_a0.mem[addr][83:72]),
                        $signed(sram_36x192b_a0.mem[addr][71:60]),   $signed(sram_36x192b_a0.mem[addr][59:48]),
                        $signed(sram_36x192b_a0.mem[addr][47:36]),   $signed(sram_36x192b_a0.mem[addr][35:24]),
                        $signed(sram_36x192b_a0.mem[addr][23:12]),   $signed(sram_36x192b_a0.mem[addr][11:0]));
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a0[addr-ans_offset][191:180]), $signed(unshuffle_ans_a0[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][167:156]), $signed(unshuffle_ans_a0[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a0[addr-ans_offset][143:132]), $signed(unshuffle_ans_a0[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][119:108]), $signed(unshuffle_ans_a0[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a0[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a0[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a0[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a0[addr-ans_offset][11:0]));
                end
            end
            A1: begin
                if(layer == UNSHUFFLE) begin
                    $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                        $signed(sram_36x192b_a1.mem[addr][191:180]), $signed(sram_36x192b_a1.mem[addr][179:168]),
                        $signed(sram_36x192b_a1.mem[addr][167:156]), $signed(sram_36x192b_a1.mem[addr][155:144]), 
                        $signed(sram_36x192b_a1.mem[addr][143:132]), $signed(sram_36x192b_a1.mem[addr][131:120]),
                        $signed(sram_36x192b_a1.mem[addr][119:108]), $signed(sram_36x192b_a1.mem[addr][107:96]),
                        $signed(sram_36x192b_a1.mem[addr][95:84]),   $signed(sram_36x192b_a1.mem[addr][83:72]),
                        $signed(sram_36x192b_a1.mem[addr][71:60]),   $signed(sram_36x192b_a1.mem[addr][59:48]),
                        $signed(sram_36x192b_a1.mem[addr][47:36]),   $signed(sram_36x192b_a1.mem[addr][35:24]),
                        $signed(sram_36x192b_a1.mem[addr][23:12]),   $signed(sram_36x192b_a1.mem[addr][11:0]));
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a1[addr-ans_offset][191:180]), $signed(unshuffle_ans_a1[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][167:156]), $signed(unshuffle_ans_a1[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a1[addr-ans_offset][143:132]), $signed(unshuffle_ans_a1[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][119:108]), $signed(unshuffle_ans_a1[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a1[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a1[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a1[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a1[addr-ans_offset][11:0]));
                end
            end
            A2: begin
                if(layer == UNSHUFFLE) begin
                    $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                        $signed(sram_36x192b_a2.mem[addr][191:180]), $signed(sram_36x192b_a2.mem[addr][179:168]),
                        $signed(sram_36x192b_a2.mem[addr][167:156]), $signed(sram_36x192b_a2.mem[addr][155:144]), 
                        $signed(sram_36x192b_a2.mem[addr][143:132]), $signed(sram_36x192b_a2.mem[addr][131:120]),
                        $signed(sram_36x192b_a2.mem[addr][119:108]), $signed(sram_36x192b_a2.mem[addr][107:96]),
                        $signed(sram_36x192b_a2.mem[addr][95:84]),   $signed(sram_36x192b_a2.mem[addr][83:72]),
                        $signed(sram_36x192b_a2.mem[addr][71:60]),   $signed(sram_36x192b_a2.mem[addr][59:48]),
                        $signed(sram_36x192b_a2.mem[addr][47:36]),   $signed(sram_36x192b_a2.mem[addr][35:24]),
                        $signed(sram_36x192b_a2.mem[addr][23:12]),   $signed(sram_36x192b_a2.mem[addr][11:0]));
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a2[addr-ans_offset][191:180]), $signed(unshuffle_ans_a2[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][167:156]), $signed(unshuffle_ans_a2[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a2[addr-ans_offset][143:132]), $signed(unshuffle_ans_a2[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][119:108]), $signed(unshuffle_ans_a2[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a2[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a2[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a2[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a2[addr-ans_offset][11:0]));
                end
            end
            A3: begin
                if(layer == UNSHUFFLE) begin
                    $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n",
                        $signed(sram_36x192b_a3.mem[addr][191:180]), $signed(sram_36x192b_a3.mem[addr][179:168]),
                        $signed(sram_36x192b_a3.mem[addr][167:156]), $signed(sram_36x192b_a3.mem[addr][155:144]), 
                        $signed(sram_36x192b_a3.mem[addr][143:132]), $signed(sram_36x192b_a3.mem[addr][131:120]),
                        $signed(sram_36x192b_a3.mem[addr][119:108]), $signed(sram_36x192b_a3.mem[addr][107:96]),
                        $signed(sram_36x192b_a3.mem[addr][95:84]),   $signed(sram_36x192b_a3.mem[addr][83:72]),
                        $signed(sram_36x192b_a3.mem[addr][71:60]),   $signed(sram_36x192b_a3.mem[addr][59:48]),
                        $signed(sram_36x192b_a3.mem[addr][47:36]),   $signed(sram_36x192b_a3.mem[addr][35:24]),
                        $signed(sram_36x192b_a3.mem[addr][23:12]),   $signed(sram_36x192b_a3.mem[addr][11:0]));
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a3[addr-ans_offset][191:180]), $signed(unshuffle_ans_a3[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][167:156]), $signed(unshuffle_ans_a3[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a3[addr-ans_offset][143:132]), $signed(unshuffle_ans_a3[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][119:108]), $signed(unshuffle_ans_a3[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a3[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a3[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a3[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a3[addr-ans_offset][11:0]));
                end
            end
        endcase
    end
endtask

endmodule
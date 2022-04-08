`timescale 1ns/100ps
`define PAT_NUM 0 // we only use test image #0 for validation in this homework

module test_top;

localparam CH_NUM = 4;
localparam ACT_PER_ADDR = 4;
localparam BW_PER_ACT = 12;
localparam BW_PER_SRAM_GROUP_ADDR = CH_NUM*ACT_PER_ADDR*BW_PER_ACT;
localparam WEIGHT_PER_ADDR = 9, BIAS_PER_ADDR = 1;
localparam BW_PER_PARAM = 8;
localparam Pattern_N = 28*28;
localparam END_CYCLES = 10000; // you can enlarge the cycle count limit for longer simulation
real CYCLE = 10;

localparam UNSHUFFLE=0, CONV1=1, CONV2=2, POOL=3;
localparam A0=0, A1=1, A2=2, A3=3, B0=4, B1=5, B2=6, B3=7;

// ===== module I/O ===== //
reg clk;
reg rst_n;
reg enable;
reg [BW_PER_ACT-1:0] input_data;
wire busy;
wire valid;

wire [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_weight;
wire [9:0] sram_raddr_weight;

wire [BIAS_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_bias;
wire [5:0] sram_raddr_bias;

wire sram_wen_a0;
wire sram_wen_a1;
wire sram_wen_a2;
wire sram_wen_a3;
wire sram_wen_b0;
wire sram_wen_b1;
wire sram_wen_b2;
wire sram_wen_b3;

wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a0;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a1;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a2;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_a3;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_b0;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_b1;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_b2;
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_rdata_b3;

wire [5:0] sram_raddr_a0;
wire [5:0] sram_raddr_a1;
wire [5:0] sram_raddr_a2;
wire [5:0] sram_raddr_a3;
wire [5:0] sram_raddr_b0;
wire [5:0] sram_raddr_b1;
wire [5:0] sram_raddr_b2;
wire [5:0] sram_raddr_b3;

wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a;  
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b;

wire [5:0] sram_waddr_a;
wire [5:0] sram_waddr_b;

wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_wdata_a;  
wire [BW_PER_SRAM_GROUP_ADDR-1:0] sram_wdata_b;

// ===== instantiation ===== //
Convnet_top #(
.CH_NUM(CH_NUM),
.ACT_PER_ADDR(ACT_PER_ADDR),
.BW_PER_ACT(BW_PER_ACT),
.WEIGHT_PER_ADDR(WEIGHT_PER_ADDR), 
.BIAS_PER_ADDR(BIAS_PER_ADDR),
.BW_PER_PARAM(BW_PER_PARAM)
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
.sram_rdata_b0(sram_rdata_b0),
.sram_rdata_b1(sram_rdata_b1),
.sram_rdata_b2(sram_rdata_b2),
.sram_rdata_b3(sram_rdata_b3),
.sram_rdata_weight(sram_rdata_weight),
.sram_rdata_bias(sram_rdata_bias),

.sram_raddr_a0(sram_raddr_a0),
.sram_raddr_a1(sram_raddr_a1),
.sram_raddr_a2(sram_raddr_a2),
.sram_raddr_a3(sram_raddr_a3),
.sram_raddr_b0(sram_raddr_b0),
.sram_raddr_b1(sram_raddr_b1),
.sram_raddr_b2(sram_raddr_b2),
.sram_raddr_b3(sram_raddr_b3),
.sram_raddr_weight(sram_raddr_weight),
.sram_raddr_bias(sram_raddr_bias),

.sram_wen_a0(sram_wen_a0),
.sram_wen_a1(sram_wen_a1),
.sram_wen_a2(sram_wen_a2),
.sram_wen_a3(sram_wen_a3),
.sram_wen_b0(sram_wen_b0),
.sram_wen_b1(sram_wen_b1),
.sram_wen_b2(sram_wen_b2),
.sram_wen_b3(sram_wen_b3),

.sram_wordmask_a(sram_wordmask_a),
.sram_wordmask_b(sram_wordmask_b),

.sram_waddr_a(sram_waddr_a),
.sram_wdata_a(sram_wdata_a),
.sram_waddr_b(sram_waddr_b),
.sram_wdata_b(sram_wdata_b)
);

// ===== sram connection ===== //
sram_640x72b sram_640x72b_weight(
.clk(clk),
.csb(1'b0),
.wsb(1'b1),
.wdata(72'd0), 
.waddr(10'd0), 
.raddr(sram_raddr_weight), 
.rdata(sram_rdata_weight)
);
sram_64x8b sram_64x8b_bias(
.clk(clk),
.csb(1'b0),
.wsb(1'b1),
.wdata(8'd0), 
.waddr(6'd0), 
.raddr(sram_raddr_bias), 
.rdata(sram_rdata_bias)
);
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
sram_36x192b sram_36x192b_b0(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b0),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b0), 
.rdata(sram_rdata_b0)
);
sram_36x192b sram_36x192b_b1(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b1),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b1), 
.rdata(sram_rdata_b1)
);
sram_36x192b sram_36x192b_b2(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b2),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b2), 
.rdata(sram_rdata_b2)
);
sram_36x192b sram_36x192b_b3(
.clk(clk),
.wordmask(sram_wordmask_b),
.csb(1'b0),
.wsb(sram_wen_b3),
.wdata(sram_wdata_b), 
.waddr(sram_waddr_b), 
.raddr(sram_raddr_b3), 
.rdata(sram_rdata_b3)
);

// ===== waveform dumpping ===== //
initial begin
    $fsdbDumpfile("hw5_part2.fsdb");
    $fsdbDumpvars("+mda");
end

// ===== parameters & golden answers ===== //
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv1_w [0:15];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv1_b [0:3];

reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b0 [0:8];       
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b1 [0:8];     
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b2 [0:8];      
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b3 [0:8];     

integer i;

initial begin
    $readmemb("golden/conv1_b0.dat", conv1_ans_b0);
    $readmemb("golden/conv1_b1.dat", conv1_ans_b1);
    $readmemb("golden/conv1_b2.dat", conv1_ans_b2);
    $readmemb("golden/conv1_b3.dat", conv1_ans_b3);

    $readmemb("param/conv1_weight.dat", conv1_w);
    $readmemb("param/conv1_bias.dat", conv1_b);

    // store weights into sram
    for(i=0; i<16; i=i+1) begin
        sram_640x72b_weight.load_param(i, conv1_w[i]);
    end
    // store biases into sram
    for(i=0; i<4; i=i+1) begin
        sram_64x8b_bias.load_param(i, conv1_b[i]);
    end
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

integer p = 0;

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

    while(p < Pattern_N) begin
        @(negedge clk);
        if(~busy) begin
            input_data = mem_img[p];
            p = p+1;
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

    $display("Start checking CONV1 layer ...\n");
    for(m=0; m<3; m=m+1) begin
        if(conv1_ans_b0[m] === sram_36x192b_b0.mem[m]) begin
            $display("Sram #B0 address %0d PASS!", m);
        end else begin
            $display("Sram #B0 address %0d FAIL!", m);
            display_error(B0, CONV1, m, 0);
            error_bank0 = error_bank0 + 1;
        end
    end
    for(m=6; m<9; m=m+1) begin
        if(conv1_ans_b0[m-3] === sram_36x192b_b0.mem[m]) begin
            $display("Sram #B0 address %0d PASS!", m);
        end else begin
            $display("Sram #B0 address %0d FAIL!", m);
            display_error(B0, CONV1, m, 3);
            error_bank0 = error_bank0 + 1;
        end
    end
    for(m=12; m<15; m=m+1) begin
        if(conv1_ans_b0[m-6] === sram_36x192b_b0.mem[m]) begin
            $display("Sram #B0 address %0d PASS!", m);
        end else begin
            $display("Sram #B0 address %0d FAIL!", m);
            display_error(B0, CONV1, m, 6);
            error_bank0 = error_bank0 + 1;
        end
    end
    $display("========================================================");
    if(error_bank0 == 0) begin
        $display("CONV1 results in sram #B0 are successfully passed!");
    end else begin
        $display("CONV1 results in sram #B0 have %0d errors!", error_bank0);
    end
    $display("========================================================\n");

    for(m=0; m<3; m=m+1) begin
        if(conv1_ans_b1[m] === sram_36x192b_b1.mem[m]) begin
            $display("Sram #B1 address %0d PASS!", m);
        end else begin
            $display("Sram #B1 address %0d FAIL!", m);
            display_error(B1, CONV1, m, 0);
            error_bank1 = error_bank1 + 1;
        end
    end
    for(m=6; m<9; m=m+1) begin
        if(conv1_ans_b1[m-3] === sram_36x192b_b1.mem[m]) begin
            $display("Sram #B1 address %0d PASS!", m);
        end else begin
            $display("Sram #B1 address %0d FAIL!", m);
            display_error(B1, CONV1, m, 3);
            error_bank1 = error_bank1 + 1;
        end
    end
    for(m=12; m<15; m=m+1) begin
        if(conv1_ans_b1[m-6] === sram_36x192b_b1.mem[m]) begin
            $display("Sram #B1 address %0d PASS!", m);
        end else begin
            $display("Sram #B1 address %0d FAIL!", m);
            display_error(B1, CONV1, m, 6);
            error_bank1 = error_bank1 + 1;
        end
    end
    $display("========================================================");
    if(error_bank1 == 0) begin
        $display("CONV1 results in sram #B1 are successfully passed!");
    end else begin
        $display("CONV1 results in sram #B1 have %0d errors!", error_bank1);
    end
    $display("========================================================\n");

    for(m=0; m<3; m=m+1) begin
        if(conv1_ans_b2[m] === sram_36x192b_b2.mem[m]) begin
            $display("Sram #B2 address %0d PASS!", m);
        end else begin
            $display("Sram #B2 address %0d FAIL!", m);
            display_error(B2, CONV1, m, 0);
            error_bank2 = error_bank2 + 1;
        end
    end
    for(m=6; m<9; m=m+1) begin
        if(conv1_ans_b2[m-3] === sram_36x192b_b2.mem[m]) begin
            $display("Sram #B2 address %0d PASS!", m);
        end else begin
            $display("Sram #B2 address %0d FAIL!", m);
            display_error(B2, CONV1, m, 3);
            error_bank2 = error_bank2 + 1;
        end
    end
    for(m=12; m<15; m=m+1) begin
        if(conv1_ans_b2[m-6] === sram_36x192b_b2.mem[m]) begin
            $display("Sram #B2 address %0d PASS!", m);
        end else begin
            $display("Sram #B2 address %0d FAIL!", m);
            display_error(B2, CONV1, m, 6);
            error_bank2 = error_bank2 + 1;
        end
    end
    $display("========================================================");
    if(error_bank2 == 0) begin
        $display("CONV1 results in sram #B2 are successfully passed!");
    end else begin
        $display("CONV1 results in sram #B2 have %0d errors!", error_bank2);
    end
    $display("========================================================\n");

    for(m=0; m<3; m=m+1) begin
        if(conv1_ans_b3[m] === sram_36x192b_b3.mem[m]) begin
            $display("Sram #B3 address %0d PASS!", m);
        end else begin
            $display("Sram #B3 address %0d FAIL!", m);
            display_error(B3, CONV1, m, 0);
            error_bank3 = error_bank3 + 1;
        end
    end
    for(m=6; m<9; m=m+1) begin
        if(conv1_ans_b3[m-3] === sram_36x192b_b3.mem[m]) begin
            $display("Sram #B3 address %0d PASS!", m);
        end else begin
            $display("Sram #B3 address %0d FAIL!", m);
            display_error(B3, CONV1, m, 3);
            error_bank3 = error_bank3 + 1;
        end
    end
    for(m=12; m<15; m=m+1) begin
        if(conv1_ans_b3[m-6] === sram_36x192b_b3.mem[m]) begin
            $display("Sram #B3 address %0d PASS!", m);
        end else begin
            $display("Sram #B3 address %0d FAIL!", m);
            display_error(B3, CONV1, m, 6);
            error_bank3 = error_bank3 + 1;
        end
    end
    $display("========================================================");
    if(error_bank3 == 0) begin
        $display("CONV1 results in sram #B3 are successfully passed!");
    end else begin
        $display("CONV1 results in sram #B3 have %0d errors!", error_bank3);
    end
    $display("========================================================");

    error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

    $display("\n========================================================");
    if(error_total == 0) begin
        $display("Congratulations! Your CONV1 layer is correct!");
        $display("You pass part2 simulation.");
    end else begin
        $display("There are total %0d errors in your CONV1 layer.", error_total);
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
            B0: begin
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                    $signed(sram_36x192b_b0.mem[addr][191:180]), $signed(sram_36x192b_b0.mem[addr][179:168]),
                    $signed(sram_36x192b_b0.mem[addr][167:156]), $signed(sram_36x192b_b0.mem[addr][155:144]), 
                    $signed(sram_36x192b_b0.mem[addr][143:132]), $signed(sram_36x192b_b0.mem[addr][131:120]),
                    $signed(sram_36x192b_b0.mem[addr][119:108]), $signed(sram_36x192b_b0.mem[addr][107:96]),
                    $signed(sram_36x192b_b0.mem[addr][95:84]),   $signed(sram_36x192b_b0.mem[addr][83:72]),
                    $signed(sram_36x192b_b0.mem[addr][71:60]),   $signed(sram_36x192b_b0.mem[addr][59:48]),
                    $signed(sram_36x192b_b0.mem[addr][47:36]),   $signed(sram_36x192b_b0.mem[addr][35:24]),
                    $signed(sram_36x192b_b0.mem[addr][23:12]),   $signed(sram_36x192b_b0.mem[addr][11:0]));
                if(layer == CONV1) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv1_ans_b0[addr-ans_offset][191:180]), $signed(conv1_ans_b0[addr-ans_offset][179:168]),
                        $signed(conv1_ans_b0[addr-ans_offset][167:156]), $signed(conv1_ans_b0[addr-ans_offset][155:144]), 
                        $signed(conv1_ans_b0[addr-ans_offset][143:132]), $signed(conv1_ans_b0[addr-ans_offset][131:120]),
                        $signed(conv1_ans_b0[addr-ans_offset][119:108]), $signed(conv1_ans_b0[addr-ans_offset][107:96]),
                        $signed(conv1_ans_b0[addr-ans_offset][95:84]),   $signed(conv1_ans_b0[addr-ans_offset][83:72]),
                        $signed(conv1_ans_b0[addr-ans_offset][71:60]),   $signed(conv1_ans_b0[addr-ans_offset][59:48]),
                        $signed(conv1_ans_b0[addr-ans_offset][47:36]),   $signed(conv1_ans_b0[addr-ans_offset][35:24]),
                        $signed(conv1_ans_b0[addr-ans_offset][23:12]),   $signed(conv1_ans_b0[addr-ans_offset][11:0]));
                end
            end
            B1: begin
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                    $signed(sram_36x192b_b1.mem[addr][191:180]), $signed(sram_36x192b_b1.mem[addr][179:168]),
                    $signed(sram_36x192b_b1.mem[addr][167:156]), $signed(sram_36x192b_b1.mem[addr][155:144]), 
                    $signed(sram_36x192b_b1.mem[addr][143:132]), $signed(sram_36x192b_b1.mem[addr][131:120]),
                    $signed(sram_36x192b_b1.mem[addr][119:108]), $signed(sram_36x192b_b1.mem[addr][107:96]),
                    $signed(sram_36x192b_b1.mem[addr][95:84]),   $signed(sram_36x192b_b1.mem[addr][83:72]),
                    $signed(sram_36x192b_b1.mem[addr][71:60]),   $signed(sram_36x192b_b1.mem[addr][59:48]),
                    $signed(sram_36x192b_b1.mem[addr][47:36]),   $signed(sram_36x192b_b1.mem[addr][35:24]),
                    $signed(sram_36x192b_b1.mem[addr][23:12]),   $signed(sram_36x192b_b1.mem[addr][11:0]));
                if(layer == CONV1) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv1_ans_b1[addr-ans_offset][191:180]), $signed(conv1_ans_b1[addr-ans_offset][179:168]),
                        $signed(conv1_ans_b1[addr-ans_offset][167:156]), $signed(conv1_ans_b1[addr-ans_offset][155:144]), 
                        $signed(conv1_ans_b1[addr-ans_offset][143:132]), $signed(conv1_ans_b1[addr-ans_offset][131:120]),
                        $signed(conv1_ans_b1[addr-ans_offset][119:108]), $signed(conv1_ans_b1[addr-ans_offset][107:96]),
                        $signed(conv1_ans_b1[addr-ans_offset][95:84]),   $signed(conv1_ans_b1[addr-ans_offset][83:72]),
                        $signed(conv1_ans_b1[addr-ans_offset][71:60]),   $signed(conv1_ans_b1[addr-ans_offset][59:48]),
                        $signed(conv1_ans_b1[addr-ans_offset][47:36]),   $signed(conv1_ans_b1[addr-ans_offset][35:24]),
                        $signed(conv1_ans_b1[addr-ans_offset][23:12]),   $signed(conv1_ans_b1[addr-ans_offset][11:0]));
                end
            end
            B2: begin
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                    $signed(sram_36x192b_b2.mem[addr][191:180]), $signed(sram_36x192b_b2.mem[addr][179:168]),
                    $signed(sram_36x192b_b2.mem[addr][167:156]), $signed(sram_36x192b_b2.mem[addr][155:144]), 
                    $signed(sram_36x192b_b2.mem[addr][143:132]), $signed(sram_36x192b_b2.mem[addr][131:120]),
                    $signed(sram_36x192b_b2.mem[addr][119:108]), $signed(sram_36x192b_b2.mem[addr][107:96]),
                    $signed(sram_36x192b_b2.mem[addr][95:84]),   $signed(sram_36x192b_b2.mem[addr][83:72]),
                    $signed(sram_36x192b_b2.mem[addr][71:60]),   $signed(sram_36x192b_b2.mem[addr][59:48]),
                    $signed(sram_36x192b_b2.mem[addr][47:36]),   $signed(sram_36x192b_b2.mem[addr][35:24]),
                    $signed(sram_36x192b_b2.mem[addr][23:12]),   $signed(sram_36x192b_b2.mem[addr][11:0]));
                if(layer == CONV1) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv1_ans_b2[addr-ans_offset][191:180]), $signed(conv1_ans_b2[addr-ans_offset][179:168]),
                        $signed(conv1_ans_b2[addr-ans_offset][167:156]), $signed(conv1_ans_b2[addr-ans_offset][155:144]), 
                        $signed(conv1_ans_b2[addr-ans_offset][143:132]), $signed(conv1_ans_b2[addr-ans_offset][131:120]),
                        $signed(conv1_ans_b2[addr-ans_offset][119:108]), $signed(conv1_ans_b2[addr-ans_offset][107:96]),
                        $signed(conv1_ans_b2[addr-ans_offset][95:84]),   $signed(conv1_ans_b2[addr-ans_offset][83:72]),
                        $signed(conv1_ans_b2[addr-ans_offset][71:60]),   $signed(conv1_ans_b2[addr-ans_offset][59:48]),
                        $signed(conv1_ans_b2[addr-ans_offset][47:36]),   $signed(conv1_ans_b2[addr-ans_offset][35:24]),
                        $signed(conv1_ans_b2[addr-ans_offset][23:12]),   $signed(conv1_ans_b2[addr-ans_offset][11:0]));
                end
            end
            B3: begin
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                    $signed(sram_36x192b_b3.mem[addr][191:180]), $signed(sram_36x192b_b3.mem[addr][179:168]),
                    $signed(sram_36x192b_b3.mem[addr][167:156]), $signed(sram_36x192b_b3.mem[addr][155:144]), 
                    $signed(sram_36x192b_b3.mem[addr][143:132]), $signed(sram_36x192b_b3.mem[addr][131:120]),
                    $signed(sram_36x192b_b3.mem[addr][119:108]), $signed(sram_36x192b_b3.mem[addr][107:96]),
                    $signed(sram_36x192b_b3.mem[addr][95:84]),   $signed(sram_36x192b_b3.mem[addr][83:72]),
                    $signed(sram_36x192b_b3.mem[addr][71:60]),   $signed(sram_36x192b_b3.mem[addr][59:48]),
                    $signed(sram_36x192b_b3.mem[addr][47:36]),   $signed(sram_36x192b_b3.mem[addr][35:24]),
                    $signed(sram_36x192b_b3.mem[addr][23:12]),   $signed(sram_36x192b_b3.mem[addr][11:0]));
                if(layer == CONV1) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv1_ans_b3[addr-ans_offset][191:180]), $signed(conv1_ans_b3[addr-ans_offset][179:168]),
                        $signed(conv1_ans_b3[addr-ans_offset][167:156]), $signed(conv1_ans_b3[addr-ans_offset][155:144]), 
                        $signed(conv1_ans_b3[addr-ans_offset][143:132]), $signed(conv1_ans_b3[addr-ans_offset][131:120]),
                        $signed(conv1_ans_b3[addr-ans_offset][119:108]), $signed(conv1_ans_b3[addr-ans_offset][107:96]),
                        $signed(conv1_ans_b3[addr-ans_offset][95:84]),   $signed(conv1_ans_b3[addr-ans_offset][83:72]),
                        $signed(conv1_ans_b3[addr-ans_offset][71:60]),   $signed(conv1_ans_b3[addr-ans_offset][59:48]),
                        $signed(conv1_ans_b3[addr-ans_offset][47:36]),   $signed(conv1_ans_b3[addr-ans_offset][35:24]),
                        $signed(conv1_ans_b3[addr-ans_offset][23:12]),   $signed(conv1_ans_b3[addr-ans_offset][11:0]));
                end
            end
        endcase
    end
endtask

endmodule
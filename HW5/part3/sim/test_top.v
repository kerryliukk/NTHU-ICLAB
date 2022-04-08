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
// localparam END_CYCLES = 10000; // you can enlarge the cycle count limit for longer simulation
localparam END_CYCLES = 20000; // you can enlarge the cycle count limit for longer simulation
real CYCLE = 10;

// ===== test layer selection ===== //
/*
    If you want to test the functionality of unshuffle layer, pull up the "valid" signal after finish calculating unshuffle layer. 
    Then execute the following command for simulation:
        ncverilog -f sim.f +define+TEST_UNSHUFFLE .
    You can test other layers in similar ways. If you do not specify the testing layer as follows
        ncverilog -f sim.f ,
    the testbench will check the answers of the final layers (POOL)
*/
localparam UNSHUFFLE=0, CONV1=1, CONV2=2, POOL=3;
localparam A0=0, A1=1, A2=2, A3=3, B0=4, B1=5, B2=6, B3=7;

integer test_layer;

initial begin
    `ifdef TEST_UNSHUFFLE
        test_layer = UNSHUFFLE;
    `elsif TEST_CONV1
        test_layer = CONV1;
    `elsif TEST_CONV2
        test_layer = CONV2;
    `else 
        test_layer = POOL;
    `endif
end

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
    $fsdbDumpfile("hw5_part3.fsdb");
    $fsdbDumpvars("+mda");
end

// ===== parameters & golden answers ===== //
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv1_w [0:15];
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv2_w [0:47];
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] conv3_w [0:575];

reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv1_b [0:3];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv2_b [0:11];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] conv3_b [0:47];

reg [768*BW_PER_PARAM-1:0] fc1_w [0:499];
reg [500*BW_PER_PARAM-1:0] fc2_w [0:9];

reg [BW_PER_PARAM-1:0] fc1_b [0:499];
reg [BW_PER_PARAM-1:0] fc2_b [0:9];

reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a0 [0:15];  
reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a1 [0:11]; 
reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a2 [0:11];  
reg [BW_PER_SRAM_GROUP_ADDR-1:0] unshuffle_ans_a3 [0:8];   

reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b0 [0:8];       
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b1 [0:8];     
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b2 [0:8];      
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv1_ans_b3 [0:8];     

reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv2_ans_a0 [0:26];      
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv2_ans_a1 [0:17];      
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv2_ans_a2 [0:17];      
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv2_ans_a3 [0:11];     

reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_ans_b0 [0:11];      
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_ans_b1 [0:11];      
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_ans_b2 [0:11];    
reg [BW_PER_SRAM_GROUP_ADDR-1:0] conv3_pool_ans_b3 [0:11];    

integer i;

initial begin
    $readmemb("golden/unshuffle_a0.dat", unshuffle_ans_a0);
    $readmemb("golden/unshuffle_a1.dat", unshuffle_ans_a1);
    $readmemb("golden/unshuffle_a2.dat", unshuffle_ans_a2);
    $readmemb("golden/unshuffle_a3.dat", unshuffle_ans_a3);
    $readmemb("golden/conv1_b0.dat", conv1_ans_b0);
    $readmemb("golden/conv1_b1.dat", conv1_ans_b1);
    $readmemb("golden/conv1_b2.dat", conv1_ans_b2);
    $readmemb("golden/conv1_b3.dat", conv1_ans_b3);
    $readmemb("golden/conv2_a0.dat", conv2_ans_a0);
    $readmemb("golden/conv2_a1.dat", conv2_ans_a1);
    $readmemb("golden/conv2_a2.dat", conv2_ans_a2);
    $readmemb("golden/conv2_a3.dat", conv2_ans_a3);
    $readmemb("golden/conv3_pool_b0.dat", conv3_pool_ans_b0);
    $readmemb("golden/conv3_pool_b1.dat", conv3_pool_ans_b1);
    $readmemb("golden/conv3_pool_b2.dat", conv3_pool_ans_b2);
    $readmemb("golden/conv3_pool_b3.dat", conv3_pool_ans_b3);

    $readmemb("param/conv1_weight.dat", conv1_w);
    $readmemb("param/conv1_bias.dat", conv1_b);
    $readmemb("param/conv2_weight.dat", conv2_w);
    $readmemb("param/conv2_bias.dat", conv2_b);
    $readmemb("param/conv3_weight.dat", conv3_w);
    $readmemb("param/conv3_bias.dat", conv3_b);
    $readmemb("param/fc1_weight.dat", fc1_w);
    $readmemb("param/fc1_bias.dat", fc1_b);
    $readmemb("param/fc2_weight.dat", fc2_w);
    $readmemb("param/fc2_bias.dat", fc2_b);

    // store weights into sram
    for(i=0; i<16; i=i+1) begin
        sram_640x72b_weight.load_param(i, conv1_w[i]);
    end
    for(i=16; i<64; i=i+1) begin
        sram_640x72b_weight.load_param(i, conv2_w[i-16]);
    end
    for(i=64; i<640; i=i+1) begin
        sram_640x72b_weight.load_param(i, conv3_w[i-64]);  
    end
    // store biases into sram
    for(i=0; i<4; i=i+1) begin
        sram_64x8b_bias.load_param(i, conv1_b[i]);
    end
    for(i=4; i<16; i=i+1) begin
        sram_64x8b_bias.load_param(i, conv2_b[i-4]);
    end
    for(i=16; i<64; i=i+1) begin
        sram_64x8b_bias.load_param(i, conv3_b[i-16]);
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

// ===== cycle counter ===== //
integer cycle_cnt = 0;

initial begin
    wait(enable);
    @(negedge clk);

    while(1) begin 
        cycle_cnt = cycle_cnt+1;
        @(negedge clk);
    end
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

    case(test_layer)
        UNSHUFFLE: begin
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
            end else begin
                $display("There are total %0d errors in your UNSHUFFLE layer.", error_total);
            end
            $display("========================================================");
            $finish;
        end
        CONV1: begin
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
            end else begin
                $display("There are total %0d errors in your CONV1 layer.", error_total);
            end
            $display("========================================================");
            $finish;
        end
        CONV2: begin
            $display("Start checking CONV2 layer ...\n");
            for(m=0; m<21; m=m+1) begin
                if(conv2_ans_a0[m] === sram_36x192b_a0.mem[m]) begin
                    $display("Sram #A0 address %0d PASS!", m);
                end else begin
                    $display("Sram #A0 address %0d FAIL!", m);
                    display_error(A0, CONV2, m, 0);
                    error_bank0 = error_bank0 + 1;
                end
            end
            for(m=24; m<27; m=m+1) begin
                if(conv2_ans_a0[m-3] === sram_36x192b_a0.mem[m]) begin
                    $display("Sram #A0 address %0d PASS!", m);
                end else begin
                    $display("Sram #A0 address %0d FAIL!", m);
                    display_error(A0, CONV2, m, 3);
                    error_bank0 = error_bank0 + 1;
                end
            end
            for(m=30; m<33; m=m+1) begin
                if(conv2_ans_a0[m-6] === sram_36x192b_a0.mem[m]) begin
                    $display("Sram #A0 address %0d PASS!", m);
                end else begin
                    $display("Sram #A0 address %0d FAIL!", m);
                    display_error(A0, CONV2, m, 6);
                    error_bank0 = error_bank0 + 1;
                end
            end
            $display("========================================================");
            if(error_bank0 == 0) begin
                $display("CONV2 results in sram #A0 are successfully passed!");
            end else begin
                $display("CONV2 results in sram #A0 have %0d errors!", error_bank0);
            end
            $display("========================================================\n");

            for(m=0; m<2; m=m+1) begin
                if(conv2_ans_a1[m] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 0);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=3; m<5; m=m+1) begin
                if(conv2_ans_a1[m-1] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 1);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=6; m<8; m=m+1) begin
                if(conv2_ans_a1[m-2] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 2);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=9; m<11; m=m+1) begin
                if(conv2_ans_a1[m-3] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 3);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=12; m<14; m=m+1) begin
                if(conv2_ans_a1[m-4] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 4);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=15; m<17; m=m+1) begin
                if(conv2_ans_a1[m-5] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 5);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=18; m<20; m=m+1) begin
                if(conv2_ans_a1[m-6] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 6);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=24; m<26; m=m+1) begin
                if(conv2_ans_a1[m-10] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 10);
                    error_bank1 = error_bank1 + 1;
                end
            end
            for(m=30; m<32; m=m+1) begin
                if(conv2_ans_a1[m-14] === sram_36x192b_a1.mem[m]) begin
                    $display("Sram #A1 address %0d PASS!", m);
                end else begin
                    $display("Sram #A1 address %0d FAIL!", m);
                    display_error(A1, CONV2, m, 14);
                    error_bank1 = error_bank1 + 1;
                end
            end
            $display("========================================================");
            if(error_bank1 == 0) begin
                $display("CONV2 results in sram #A1 are successfully passed!");
            end else begin
                $display("CONV2 results in sram #A1 have %0d errors!", error_bank1);
            end
            $display("========================================================\n");

            for(m=0; m<12; m=m+1) begin
                if(conv2_ans_a2[m] === sram_36x192b_a2.mem[m]) begin
                    $display("Sram #A2 address %0d PASS!", m);
                end else begin
                    $display("Sram #A2 address %0d FAIL!", m);
                    display_error(A2, CONV2, m, 0);
                    error_bank2 = error_bank2 + 1;
                end
            end
            for(m=18; m<21; m=m+1) begin
                if(conv2_ans_a2[m-6] === sram_36x192b_a2.mem[m]) begin
                    $display("Sram #A2 address %0d PASS!", m);
                end else begin
                    $display("Sram #A2 address %0d FAIL!", m);
                    display_error(A2, CONV2, m, 6);
                    error_bank2 = error_bank2 + 1;
                end
            end
            for(m=24; m<27; m=m+1) begin
                if(conv2_ans_a2[m-9] === sram_36x192b_a2.mem[m]) begin
                    $display("Sram #A2 address %0d PASS!", m);
                end else begin
                    $display("Sram #A2 address %0d FAIL!", m);
                    display_error(A2, CONV2, m, 9);
                    error_bank2 = error_bank2 + 1;
                end
            end
            $display("========================================================");
            if(error_bank2 == 0) begin
                $display("CONV2 results in sram #A2 are successfully passed!");
            end else begin
                $display("CONV2 results in sram #A2 have %0d errors!", error_bank2);
            end
            $display("========================================================\n");

            for(m=0; m<2; m=m+1) begin
                if(conv2_ans_a3[m] === sram_36x192b_a3.mem[m]) begin
                    $display("Sram #A3 address %0d PASS!", m);
                end else begin
                    $display("Sram #A3 address %0d FAIL!", m);
                    display_error(A3, CONV2, m, 0);
                    error_bank3 = error_bank3 + 1;
                end
            end
            for(m=3; m<5; m=m+1) begin
                if(conv2_ans_a3[m-1] === sram_36x192b_a3.mem[m]) begin
                    $display("Sram #A3 address %0d PASS!", m);
                end else begin
                    $display("Sram #A3 address %0d FAIL!", m);
                    display_error(A3, CONV2, m, 1);
                    error_bank3 = error_bank3 + 1;
                end
            end
            for(m=6; m<8; m=m+1) begin
                if(conv2_ans_a3[m-2] === sram_36x192b_a3.mem[m]) begin
                    $display("Sram #A3 address %0d PASS!", m);
                end else begin
                    $display("Sram #A3 address %0d FAIL!", m);
                    display_error(A3, CONV2, m, 2);
                    error_bank3 = error_bank3 + 1;
                end
            end
            for(m=9; m<11; m=m+1) begin
                if(conv2_ans_a3[m-3] === sram_36x192b_a3.mem[m]) begin
                    $display("Sram #A3 address %0d PASS!", m);
                end else begin
                    $display("Sram #A3 address %0d FAIL!", m);
                    display_error(A3, CONV2, m, 3);
                    error_bank3 = error_bank3 + 1;
                end
            end
            for(m=18; m<20; m=m+1) begin
                if(conv2_ans_a3[m-10] === sram_36x192b_a3.mem[m]) begin
                    $display("Sram #A3 address %0d PASS!", m);
                end else begin
                    $display("Sram #A3 address %0d FAIL!", m);
                    display_error(A3, CONV2, m, 10);
                    error_bank3 = error_bank3 + 1;
                end
            end
            for(m=24; m<26; m=m+1) begin
                if(conv2_ans_a3[m-14] === sram_36x192b_a3.mem[m]) begin
                    $display("Sram #A3 address %0d PASS!", m);
                end else begin
                    $display("Sram #A3 address %0d FAIL!", m);
                    display_error(A3, CONV2, m, 14);
                    error_bank3 = error_bank3 + 1;
                end
            end
            $display("========================================================");
            if(error_bank3 == 0) begin
                $display("CONV2 results in sram #A3 are successfully passed!");
            end else begin
                $display("CONV2 results in sram #A3 have %0d errors!", error_bank3);
            end
            $display("========================================================");

            error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 

            $display("\n========================================================");
            if(error_total == 0) begin
                $display("Congratulations! Your CONV2 layer is correct!");
            end else begin
                $display("There are total %0d errors in your CONV2 layer.", error_total);
            end
            $display("========================================================");
            $finish;
        end
        POOL: begin
            $display("Start checking POOL layer ...\n");
            for(m=0; m<12; m=m+1) begin
                if(conv3_pool_ans_b0[m] === sram_36x192b_b0.mem[m]) begin
                    $display("Sram #B0 address %0d PASS!", m);
                end else begin
                    $display("Sram #B0 address %0d FAIL!", m);
                    display_error(B0, POOL, m, 0);
                    error_bank0 = error_bank0 + 1;
                end
            end
            $display("========================================================");
            if(error_bank0 == 0) begin
                $display("POOL results in sram #B0 are successfully passed!");
            end else begin
                $display("POOL results in sram #B0 have %0d errors!", error_bank0);
            end
            $display("========================================================\n");

            for(m=0; m<12; m=m+1) begin
                if(conv3_pool_ans_b1[m] === sram_36x192b_b1.mem[m]) begin
                    $display("Sram #B1 address %0d PASS!", m);
                end else begin
                    $display("Sram #B1 address %0d FAIL!", m);
                    display_error(B1, POOL, m, 0);
                    error_bank1 = error_bank1 + 1;
                end
            end
            $display("========================================================");
            if(error_bank1 == 0) begin
                $display("POOL results in sram #B1 are successfully passed!");
            end else begin
                $display("POOL results in sram #B1 have %0d errors!", error_bank1);
            end
            $display("========================================================\n");

            for(m=0; m<12; m=m+1) begin
                if(conv3_pool_ans_b2[m] === sram_36x192b_b2.mem[m]) begin
                    $display("Sram #B2 address %0d PASS!", m);
                end else begin
                    $display("Sram #B2 address %0d FAIL!", m);
                    display_error(B2, POOL, m, 0);
                    error_bank2 = error_bank2 + 1;
                end
            end
            $display("========================================================");
            if(error_bank2 == 0) begin
                $display("POOL results in sram #B2 are successfully passed!");
            end else begin
                $display("POOL results in sram #B2 have %0d errors!", error_bank2);
            end
            $display("========================================================\n");

            for(m=0; m<12; m=m+1) begin
                if(conv3_pool_ans_b3[m] === sram_36x192b_b3.mem[m]) begin
                    $display("Sram #B3 address %0d PASS!", m);
                end else begin
                    $display("Sram #B3 address %0d FAIL!", m);
                    display_error(B3, POOL, m, 0);
                    error_bank3 = error_bank3 + 1;
                end
            end
            $display("========================================================");
            if(error_bank3 == 0) begin
                $display("POOL results in sram #B3 are successfully passed!");
            end else begin
                $display("POOL results in sram #B3 have %0d errors!", error_bank3);
            end
            $display("========================================================");

            error_total = error_bank0 + error_bank1 + error_bank2 + error_bank3; 
  
            $display("\n========================================================");
            if(error_total == 0) begin 
                $display("Congratulations! Your POOL layer is correct!");
                $display("You pass part3 simulation.");
                $display("Total cycle count = %0d", cycle_cnt);
                $display("\nFollowing shows the output of FC2 and recongnition result:");
                FLAT_layer;
                FC1_layer;
                FC2_layer;
            end else begin
                $display("There are total %0d errors in your POOL layer.", error_total);        
            end
            $display("========================================================\n");
            $finish;
        end
    endcase
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

integer j, k, l;
reg signed [BW_PER_ACT-1:0] flatten_out [0:767];

task FLAT_layer;
    begin
        l = 0;

        for(j=0; j<12; j=j+1) begin
            for(k=0; k<4; k=k+1) begin
                flatten_out[l + 0] = sram_36x192b_b0.mem[j][48*(3-k)+36 +: 12];           
                flatten_out[l + 1] = sram_36x192b_b0.mem[j][48*(3-k)+24 +: 12];
                flatten_out[l + 2] = sram_36x192b_b1.mem[j][48*(3-k)+36 +: 12];
                flatten_out[l + 3] = sram_36x192b_b1.mem[j][48*(3-k)+24 +: 12];
                flatten_out[l + 4] = sram_36x192b_b0.mem[j][48*(3-k)+12 +: 12];
                flatten_out[l + 5] = sram_36x192b_b0.mem[j][48*(3-k)+0 +: 12];
                flatten_out[l + 6] = sram_36x192b_b1.mem[j][48*(3-k)+12 +: 12];
                flatten_out[l + 7] = sram_36x192b_b1.mem[j][48*(3-k)+0 +: 12];
                flatten_out[l + 8] = sram_36x192b_b2.mem[j][48*(3-k)+36 +: 12];
                flatten_out[l + 9] = sram_36x192b_b2.mem[j][48*(3-k)+24 +: 12];               
                flatten_out[l + 10] = sram_36x192b_b3.mem[j][48*(3-k)+36 +: 12];
                flatten_out[l + 11] = sram_36x192b_b3.mem[j][48*(3-k)+24 +: 12];
                flatten_out[l + 12] = sram_36x192b_b2.mem[j][48*(3-k)+12 +: 12];
                flatten_out[l + 13] = sram_36x192b_b2.mem[j][48*(3-k)+0 +: 12];
                flatten_out[l + 14] = sram_36x192b_b3.mem[j][48*(3-k)+12 +: 12];
                flatten_out[l + 15] = sram_36x192b_b3.mem[j][48*(3-k)+0 +: 12];
                l = l+16;
            end
        end   
    end
endtask

reg signed [BW_PER_ACT-1:0] fc1_out [0:499];
reg signed [31:0] tmp_sum;

task FC1_layer;
    begin
        for(k=0; k<500; k=k+1) begin
            tmp_sum = 0;
            for(j=0; j<768; j=j+1) begin
                tmp_sum = tmp_sum + $signed(flatten_out[j]) * $signed(fc1_w[k][(767-j)*8 +: 8]);
            end
            tmp_sum = tmp_sum + ($signed(fc1_b[k]) << 8);
            tmp_sum = tmp_sum + (1 << 6);
            tmp_sum = tmp_sum >>> 7;

            if(tmp_sum >= 2047) 
                fc1_out[k] = 2047;
            else if(tmp_sum < 0) 
                fc1_out[k] = 0;
            else 
                fc1_out[k] = tmp_sum[11:0];
        end
    end
endtask

reg signed [BW_PER_ACT-1:0] fc2_out [0:9];
reg signed [BW_PER_ACT-1:0] tmp_big;
reg [BW_PER_ACT-1:0] ans;

task FC2_layer;
    begin
        for(k=0; k<10; k=k+1) begin
            tmp_sum = 0;
            for(j=0; j<500; j=j+1) begin
                tmp_sum = tmp_sum + $signed(fc1_out[j]) * $signed(fc2_w[k][(499-j)*8 +: 8]);
            end
            tmp_sum = tmp_sum + ($signed(fc2_b[k]) << 8);
            tmp_sum = tmp_sum + (1 << 6);
            tmp_sum = tmp_sum >>> 7;

            if(tmp_sum >= 2047) 
                fc2_out[k] = 2047;
            else if(tmp_sum < -2048) 
                fc2_out[k] = -2048;
            else 
                fc2_out[k] = tmp_sum[11:0];
        end

        $write("Output of FC2: ");
        tmp_big = fc2_out[0];
        ans = 0;
        for(k=0; k<10; k=k+1) begin
            $write("%0d ", fc2_out[k]);
            if(fc2_out[k] > tmp_big) begin
                tmp_big = fc2_out[k];
                ans = k;
            end
        end
        $write("\nRecognition result: %0d\n", ans);
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
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                    $signed(sram_36x192b_a0.mem[addr][191:180]), $signed(sram_36x192b_a0.mem[addr][179:168]),
                    $signed(sram_36x192b_a0.mem[addr][167:156]), $signed(sram_36x192b_a0.mem[addr][155:144]), 
                    $signed(sram_36x192b_a0.mem[addr][143:132]), $signed(sram_36x192b_a0.mem[addr][131:120]),
                    $signed(sram_36x192b_a0.mem[addr][119:108]), $signed(sram_36x192b_a0.mem[addr][107:96]),
                    $signed(sram_36x192b_a0.mem[addr][95:84]),   $signed(sram_36x192b_a0.mem[addr][83:72]),
                    $signed(sram_36x192b_a0.mem[addr][71:60]),   $signed(sram_36x192b_a0.mem[addr][59:48]),
                    $signed(sram_36x192b_a0.mem[addr][47:36]),   $signed(sram_36x192b_a0.mem[addr][35:24]),
                    $signed(sram_36x192b_a0.mem[addr][23:12]),   $signed(sram_36x192b_a0.mem[addr][11:0]));
                if(layer == UNSHUFFLE) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a0[addr-ans_offset][191:180]), $signed(unshuffle_ans_a0[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][167:156]), $signed(unshuffle_ans_a0[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a0[addr-ans_offset][143:132]), $signed(unshuffle_ans_a0[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][119:108]), $signed(unshuffle_ans_a0[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a0[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a0[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a0[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a0[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a0[addr-ans_offset][11:0]));
                end else if(layer == CONV2) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv2_ans_a0[addr-ans_offset][191:180]), $signed(conv2_ans_a0[addr-ans_offset][179:168]),
                        $signed(conv2_ans_a0[addr-ans_offset][167:156]), $signed(conv2_ans_a0[addr-ans_offset][155:144]), 
                        $signed(conv2_ans_a0[addr-ans_offset][143:132]), $signed(conv2_ans_a0[addr-ans_offset][131:120]),
                        $signed(conv2_ans_a0[addr-ans_offset][119:108]), $signed(conv2_ans_a0[addr-ans_offset][107:96]),
                        $signed(conv2_ans_a0[addr-ans_offset][95:84]),   $signed(conv2_ans_a0[addr-ans_offset][83:72]),
                        $signed(conv2_ans_a0[addr-ans_offset][71:60]),   $signed(conv2_ans_a0[addr-ans_offset][59:48]),
                        $signed(conv2_ans_a0[addr-ans_offset][47:36]),   $signed(conv2_ans_a0[addr-ans_offset][35:24]),
                        $signed(conv2_ans_a0[addr-ans_offset][23:12]),   $signed(conv2_ans_a0[addr-ans_offset][11:0]));
                end
            end
            A1: begin
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                    $signed(sram_36x192b_a1.mem[addr][191:180]), $signed(sram_36x192b_a1.mem[addr][179:168]),
                    $signed(sram_36x192b_a1.mem[addr][167:156]), $signed(sram_36x192b_a1.mem[addr][155:144]), 
                    $signed(sram_36x192b_a1.mem[addr][143:132]), $signed(sram_36x192b_a1.mem[addr][131:120]),
                    $signed(sram_36x192b_a1.mem[addr][119:108]), $signed(sram_36x192b_a1.mem[addr][107:96]),
                    $signed(sram_36x192b_a1.mem[addr][95:84]),   $signed(sram_36x192b_a1.mem[addr][83:72]),
                    $signed(sram_36x192b_a1.mem[addr][71:60]),   $signed(sram_36x192b_a1.mem[addr][59:48]),
                    $signed(sram_36x192b_a1.mem[addr][47:36]),   $signed(sram_36x192b_a1.mem[addr][35:24]),
                    $signed(sram_36x192b_a1.mem[addr][23:12]),   $signed(sram_36x192b_a1.mem[addr][11:0]));
                if(layer == UNSHUFFLE) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a1[addr-ans_offset][191:180]), $signed(unshuffle_ans_a1[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][167:156]), $signed(unshuffle_ans_a1[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a1[addr-ans_offset][143:132]), $signed(unshuffle_ans_a1[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][119:108]), $signed(unshuffle_ans_a1[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a1[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a1[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a1[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a1[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a1[addr-ans_offset][11:0]));
                end else if(layer == CONV2) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv2_ans_a1[addr-ans_offset][191:180]), $signed(conv2_ans_a1[addr-ans_offset][179:168]),
                        $signed(conv2_ans_a1[addr-ans_offset][167:156]), $signed(conv2_ans_a1[addr-ans_offset][155:144]), 
                        $signed(conv2_ans_a1[addr-ans_offset][143:132]), $signed(conv2_ans_a1[addr-ans_offset][131:120]),
                        $signed(conv2_ans_a1[addr-ans_offset][119:108]), $signed(conv2_ans_a1[addr-ans_offset][107:96]),
                        $signed(conv2_ans_a1[addr-ans_offset][95:84]),   $signed(conv2_ans_a1[addr-ans_offset][83:72]),
                        $signed(conv2_ans_a1[addr-ans_offset][71:60]),   $signed(conv2_ans_a1[addr-ans_offset][59:48]),
                        $signed(conv2_ans_a1[addr-ans_offset][47:36]),   $signed(conv2_ans_a1[addr-ans_offset][35:24]),
                        $signed(conv2_ans_a1[addr-ans_offset][23:12]),   $signed(conv2_ans_a1[addr-ans_offset][11:0]));
                end
            end
            A2: begin
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n", 
                    $signed(sram_36x192b_a2.mem[addr][191:180]), $signed(sram_36x192b_a2.mem[addr][179:168]),
                    $signed(sram_36x192b_a2.mem[addr][167:156]), $signed(sram_36x192b_a2.mem[addr][155:144]), 
                    $signed(sram_36x192b_a2.mem[addr][143:132]), $signed(sram_36x192b_a2.mem[addr][131:120]),
                    $signed(sram_36x192b_a2.mem[addr][119:108]), $signed(sram_36x192b_a2.mem[addr][107:96]),
                    $signed(sram_36x192b_a2.mem[addr][95:84]),   $signed(sram_36x192b_a2.mem[addr][83:72]),
                    $signed(sram_36x192b_a2.mem[addr][71:60]),   $signed(sram_36x192b_a2.mem[addr][59:48]),
                    $signed(sram_36x192b_a2.mem[addr][47:36]),   $signed(sram_36x192b_a2.mem[addr][35:24]),
                    $signed(sram_36x192b_a2.mem[addr][23:12]),   $signed(sram_36x192b_a2.mem[addr][11:0]));
                if(layer == UNSHUFFLE) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a2[addr-ans_offset][191:180]), $signed(unshuffle_ans_a2[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][167:156]), $signed(unshuffle_ans_a2[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a2[addr-ans_offset][143:132]), $signed(unshuffle_ans_a2[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][119:108]), $signed(unshuffle_ans_a2[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a2[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a2[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a2[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a2[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a2[addr-ans_offset][11:0]));
                end else if(layer == CONV2) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv2_ans_a2[addr-ans_offset][191:180]), $signed(conv2_ans_a2[addr-ans_offset][179:168]),
                        $signed(conv2_ans_a2[addr-ans_offset][167:156]), $signed(conv2_ans_a2[addr-ans_offset][155:144]), 
                        $signed(conv2_ans_a2[addr-ans_offset][143:132]), $signed(conv2_ans_a2[addr-ans_offset][131:120]),
                        $signed(conv2_ans_a2[addr-ans_offset][119:108]), $signed(conv2_ans_a2[addr-ans_offset][107:96]),
                        $signed(conv2_ans_a2[addr-ans_offset][95:84]),   $signed(conv2_ans_a2[addr-ans_offset][83:72]),
                        $signed(conv2_ans_a2[addr-ans_offset][71:60]),   $signed(conv2_ans_a2[addr-ans_offset][59:48]),
                        $signed(conv2_ans_a2[addr-ans_offset][47:36]),   $signed(conv2_ans_a2[addr-ans_offset][35:24]),
                        $signed(conv2_ans_a2[addr-ans_offset][23:12]),   $signed(conv2_ans_a2[addr-ans_offset][11:0]));
                end
            end
            A3: begin
                $write("Your answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n",
                    $signed(sram_36x192b_a3.mem[addr][191:180]), $signed(sram_36x192b_a3.mem[addr][179:168]),
                    $signed(sram_36x192b_a3.mem[addr][167:156]), $signed(sram_36x192b_a3.mem[addr][155:144]), 
                    $signed(sram_36x192b_a3.mem[addr][143:132]), $signed(sram_36x192b_a3.mem[addr][131:120]),
                    $signed(sram_36x192b_a3.mem[addr][119:108]), $signed(sram_36x192b_a3.mem[addr][107:96]),
                    $signed(sram_36x192b_a3.mem[addr][95:84]),   $signed(sram_36x192b_a3.mem[addr][83:72]),
                    $signed(sram_36x192b_a3.mem[addr][71:60]),   $signed(sram_36x192b_a3.mem[addr][59:48]),
                    $signed(sram_36x192b_a3.mem[addr][47:36]),   $signed(sram_36x192b_a3.mem[addr][35:24]),
                    $signed(sram_36x192b_a3.mem[addr][23:12]),   $signed(sram_36x192b_a3.mem[addr][11:0]));
                if(layer == UNSHUFFLE) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(unshuffle_ans_a3[addr-ans_offset][191:180]), $signed(unshuffle_ans_a3[addr-ans_offset][179:168]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][167:156]), $signed(unshuffle_ans_a3[addr-ans_offset][155:144]), 
                        $signed(unshuffle_ans_a3[addr-ans_offset][143:132]), $signed(unshuffle_ans_a3[addr-ans_offset][131:120]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][119:108]), $signed(unshuffle_ans_a3[addr-ans_offset][107:96]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][95:84]),   $signed(unshuffle_ans_a3[addr-ans_offset][83:72]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][71:60]),   $signed(unshuffle_ans_a3[addr-ans_offset][59:48]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][47:36]),   $signed(unshuffle_ans_a3[addr-ans_offset][35:24]),
                        $signed(unshuffle_ans_a3[addr-ans_offset][23:12]),   $signed(unshuffle_ans_a3[addr-ans_offset][11:0]));
                end else if(layer == CONV2) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv2_ans_a3[addr-ans_offset][191:180]), $signed(conv2_ans_a3[addr-ans_offset][179:168]),
                        $signed(conv2_ans_a3[addr-ans_offset][167:156]), $signed(conv2_ans_a3[addr-ans_offset][155:144]), 
                        $signed(conv2_ans_a3[addr-ans_offset][143:132]), $signed(conv2_ans_a3[addr-ans_offset][131:120]),
                        $signed(conv2_ans_a3[addr-ans_offset][119:108]), $signed(conv2_ans_a3[addr-ans_offset][107:96]),
                        $signed(conv2_ans_a3[addr-ans_offset][95:84]),   $signed(conv2_ans_a3[addr-ans_offset][83:72]),
                        $signed(conv2_ans_a3[addr-ans_offset][71:60]),   $signed(conv2_ans_a3[addr-ans_offset][59:48]),
                        $signed(conv2_ans_a3[addr-ans_offset][47:36]),   $signed(conv2_ans_a3[addr-ans_offset][35:24]),
                        $signed(conv2_ans_a3[addr-ans_offset][23:12]),   $signed(conv2_ans_a3[addr-ans_offset][11:0]));
                end
            end
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
                end else if(layer == POOL) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv3_pool_ans_b0[addr-ans_offset][191:180]), $signed(conv3_pool_ans_b0[addr-ans_offset][179:168]),
                        $signed(conv3_pool_ans_b0[addr-ans_offset][167:156]), $signed(conv3_pool_ans_b0[addr-ans_offset][155:144]), 
                        $signed(conv3_pool_ans_b0[addr-ans_offset][143:132]), $signed(conv3_pool_ans_b0[addr-ans_offset][131:120]),
                        $signed(conv3_pool_ans_b0[addr-ans_offset][119:108]), $signed(conv3_pool_ans_b0[addr-ans_offset][107:96]),
                        $signed(conv3_pool_ans_b0[addr-ans_offset][95:84]),   $signed(conv3_pool_ans_b0[addr-ans_offset][83:72]),
                        $signed(conv3_pool_ans_b0[addr-ans_offset][71:60]),   $signed(conv3_pool_ans_b0[addr-ans_offset][59:48]),
                        $signed(conv3_pool_ans_b0[addr-ans_offset][47:36]),   $signed(conv3_pool_ans_b0[addr-ans_offset][35:24]),
                        $signed(conv3_pool_ans_b0[addr-ans_offset][23:12]),   $signed(conv3_pool_ans_b0[addr-ans_offset][11:0]));
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
                end else if(layer == POOL) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv3_pool_ans_b1[addr-ans_offset][191:180]), $signed(conv3_pool_ans_b1[addr-ans_offset][179:168]),
                        $signed(conv3_pool_ans_b1[addr-ans_offset][167:156]), $signed(conv3_pool_ans_b1[addr-ans_offset][155:144]), 
                        $signed(conv3_pool_ans_b1[addr-ans_offset][143:132]), $signed(conv3_pool_ans_b1[addr-ans_offset][131:120]),
                        $signed(conv3_pool_ans_b1[addr-ans_offset][119:108]), $signed(conv3_pool_ans_b1[addr-ans_offset][107:96]),
                        $signed(conv3_pool_ans_b1[addr-ans_offset][95:84]),   $signed(conv3_pool_ans_b1[addr-ans_offset][83:72]),
                        $signed(conv3_pool_ans_b1[addr-ans_offset][71:60]),   $signed(conv3_pool_ans_b1[addr-ans_offset][59:48]),
                        $signed(conv3_pool_ans_b1[addr-ans_offset][47:36]),   $signed(conv3_pool_ans_b1[addr-ans_offset][35:24]),
                        $signed(conv3_pool_ans_b1[addr-ans_offset][23:12]),   $signed(conv3_pool_ans_b1[addr-ans_offset][11:0]));
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
                end else if(layer == POOL) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv3_pool_ans_b2[addr-ans_offset][191:180]), $signed(conv3_pool_ans_b2[addr-ans_offset][179:168]),
                        $signed(conv3_pool_ans_b2[addr-ans_offset][167:156]), $signed(conv3_pool_ans_b2[addr-ans_offset][155:144]), 
                        $signed(conv3_pool_ans_b2[addr-ans_offset][143:132]), $signed(conv3_pool_ans_b2[addr-ans_offset][131:120]),
                        $signed(conv3_pool_ans_b2[addr-ans_offset][119:108]), $signed(conv3_pool_ans_b2[addr-ans_offset][107:96]),
                        $signed(conv3_pool_ans_b2[addr-ans_offset][95:84]),   $signed(conv3_pool_ans_b2[addr-ans_offset][83:72]),
                        $signed(conv3_pool_ans_b2[addr-ans_offset][71:60]),   $signed(conv3_pool_ans_b2[addr-ans_offset][59:48]),
                        $signed(conv3_pool_ans_b2[addr-ans_offset][47:36]),   $signed(conv3_pool_ans_b2[addr-ans_offset][35:24]),
                        $signed(conv3_pool_ans_b2[addr-ans_offset][23:12]),   $signed(conv3_pool_ans_b2[addr-ans_offset][11:0]));
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
                end else if(layer == POOL) begin
                    $write("But the golden answer is \n%d %d %d %d (ch0)\n%d %d %d %d (ch1)\n%d %d %d %d (ch2)\n%d %d %d %d (ch3)\n\n", 
                        $signed(conv3_pool_ans_b3[addr-ans_offset][191:180]), $signed(conv3_pool_ans_b3[addr-ans_offset][179:168]),
                        $signed(conv3_pool_ans_b3[addr-ans_offset][167:156]), $signed(conv3_pool_ans_b3[addr-ans_offset][155:144]), 
                        $signed(conv3_pool_ans_b3[addr-ans_offset][143:132]), $signed(conv3_pool_ans_b3[addr-ans_offset][131:120]),
                        $signed(conv3_pool_ans_b3[addr-ans_offset][119:108]), $signed(conv3_pool_ans_b3[addr-ans_offset][107:96]),
                        $signed(conv3_pool_ans_b3[addr-ans_offset][95:84]),   $signed(conv3_pool_ans_b3[addr-ans_offset][83:72]),
                        $signed(conv3_pool_ans_b3[addr-ans_offset][71:60]),   $signed(conv3_pool_ans_b3[addr-ans_offset][59:48]),
                        $signed(conv3_pool_ans_b3[addr-ans_offset][47:36]),   $signed(conv3_pool_ans_b3[addr-ans_offset][35:24]),
                        $signed(conv3_pool_ans_b3[addr-ans_offset][23:12]),   $signed(conv3_pool_ans_b3[addr-ans_offset][11:0]));
                end
            end
        endcase
    end
endtask

endmodule
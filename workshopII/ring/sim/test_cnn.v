//====================================================================================
//  Module Description: RTL simulation for zebranet accelerator
//  Owner             : Vision Circuits and Systems Lab, National Tsing Hua University
//====================================================================================
`timescale 1ns/10ps

`define CYCLE 10.0
`define INST_FILE "./data/instruction.dat"
`ifdef DYN_8
    `define MD_DIR "./data/bw8R1/"
    `define BITWIDTH 8
    `define N 1
`elsif RING
    `define MD_DIR "./data/bw8R4/"
    `define BITWIDTH 8
    `define N 4
`else
    `define MD_DIR "./data/bw16R1/"
    `define BITWIDTH 16
    `define N 1
`endif

`define ACT_FL_FILE {`MD_DIR, "activation_fl.dat"}
`define PARAM_FL_FILE {`MD_DIR, "param_fl.dat"}

`ifdef RING
    `define WEIGHT_FILE0 {`MD_DIR, "interleave_conv1.weight.dat"}
    `define WEIGHT_FILE1 {`MD_DIR, "interleave_resblocks.0.conv1.weight.dat"}
    `define WEIGHT_FILE2 {`MD_DIR, "interleave_resblocks.0.conv2.weight.dat"}
    `define WEIGHT_FILE3 {`MD_DIR, "interleave_resblocks.1.conv1.weight.dat"}
    `define WEIGHT_FILE4 {`MD_DIR, "interleave_resblocks.1.conv2.weight.dat"}
    `define WEIGHT_FILE5 {`MD_DIR, "interleave_upsampler1.conv1.weight.dat"}
    `define WEIGHT_FILE6 {`MD_DIR, "interleave_upsampler2.conv1.weight.dat"}
    `define WEIGHT_FILE7 {`MD_DIR, "interleave_conv2.weight.dat"}

    `define BIAS_FILE0 {`MD_DIR, "interleave_conv1.bias.dat"}
    `define BIAS_FILE1 {`MD_DIR, "interleave_resblocks.0.conv1.bias.dat"}
    `define BIAS_FILE2 {`MD_DIR, "interleave_resblocks.0.conv2.bias.dat"}
    `define BIAS_FILE3 {`MD_DIR, "interleave_resblocks.1.conv1.bias.dat"}
    `define BIAS_FILE4 {`MD_DIR, "interleave_resblocks.1.conv2.bias.dat"}
    `define BIAS_FILE5 {`MD_DIR, "interleave_upsampler1.conv1.bias.dat"}
    `define BIAS_FILE6 {`MD_DIR, "interleave_upsampler2.conv1.bias.dat"}
    `define BIAS_FILE7 {`MD_DIR, "interleave_conv2.bias.dat"}
`else
    `define WEIGHT_FILE0 {`MD_DIR, "conv1.weight.dat"}
    `define WEIGHT_FILE1 {`MD_DIR, "resblocks.0.conv1.weight.dat"}
    `define WEIGHT_FILE2 {`MD_DIR, "resblocks.0.conv2.weight.dat"}
    `define WEIGHT_FILE3 {`MD_DIR, "resblocks.1.conv1.weight.dat"}
    `define WEIGHT_FILE4 {`MD_DIR, "resblocks.1.conv2.weight.dat"}
    `define WEIGHT_FILE5 {`MD_DIR, "upsampler1.conv1.weight.dat"}
    `define WEIGHT_FILE6 {`MD_DIR, "upsampler2.conv1.weight.dat"}
    `define WEIGHT_FILE7 {`MD_DIR, "conv2.weight.dat"}

    `define BIAS_FILE0 {`MD_DIR, "conv1.bias.dat"}
    `define BIAS_FILE1 {`MD_DIR, "resblocks.0.conv1.bias.dat"}
    `define BIAS_FILE2 {`MD_DIR, "resblocks.0.conv2.bias.dat"}
    `define BIAS_FILE3 {`MD_DIR, "resblocks.1.conv1.bias.dat"}
    `define BIAS_FILE4 {`MD_DIR, "resblocks.1.conv2.bias.dat"}
    `define BIAS_FILE5 {`MD_DIR, "upsampler1.conv1.bias.dat"}
    `define BIAS_FILE6 {`MD_DIR, "upsampler2.conv1.bias.dat"}
    `define BIAS_FILE7 {`MD_DIR, "conv2.bias.dat"}
`endif

`define OUT_DIR "./result/"
`define OUT_FILE {`OUT_DIR, "out.dat"}
`define TOTAL_LAYER 8

// testing modes: CONV1, RESBLOCK1, IMAGE_OUT
`ifdef CONV1
    `define SIM_LAYER 1
    `define ACT_FILE {"./data/", `IN_DIR, "/conv1.act_in.dat"}
    `define GOLD_FILE {"./data/", `IN_DIR, "/conv1.act_out.dat"}
`elsif RESBLOCK1
    `define SIM_LAYER 3
    `define ACT_FILE {"./data/", `IN_DIR, "/resblocks.0.act_in.dat"}
    `define GOLD_FILE {"./data/", `IN_DIR, "/resblocks.0.act_out.dat"}
`elsif RESBLOCK2
    `define SIM_LAYER 5
    `define ACT_FILE {"./data/", `IN_DIR, "/resblocks.1.act_in.dat"}
    `define GOLD_FILE {"./data/", `IN_DIR, "/resblocks.1.act_out.dat"}
`elsif IMAGE_OUT
    `define SIM_LAYER `TOTAL_LAYER
    `define ACT_FILE {"./data/", `IN_DIR, "/conv1.act_in.dat"}
    `define GOLD_FILE {"./data/", `IN_DIR, "/conv2.act_out.dat"}
`endif

module test_cnn;

parameter CHANNEL = 16;

parameter ACT_CHANNEL  = 16;
parameter MAX_CHANNEL  = 64;
parameter INST_LEN = 15*4;

parameter BW_FL = 4;
parameter IN_CHANNEL = 16;
parameter OUT_CHANNEL= 4;
parameter CONV_LATENCY = 1;
parameter POST_LATENCY = 3;

parameter ACT_MEM_SIZE = 4*`BLOCK_HEIGHT*4*`BLOCK_WIDTH*ACT_CHANNEL;

//========== memory ==========//
reg [INST_LEN-1:0] inst [0:`TOTAL_LAYER-1];

reg [`BITWIDTH-1:0] act_mem  [0:ACT_MEM_SIZE*3-1];
reg [`BITWIDTH-1:0] gold_mem [0:ACT_MEM_SIZE-1];
reg [`N*`BITWIDTH-1:0] bias_mem [0:`TOTAL_LAYER*MAX_CHANNEL-1];
reg [ACT_CHANNEL*9*`BITWIDTH-1:0] wgt_mem [0:`TOTAL_LAYER*MAX_CHANNEL*16-1];

reg [`N*BW_FL-1:0] act_fl_mem [0:`TOTAL_LAYER];
reg [`N*BW_FL-1:0] param_fl_mem [0:2*`TOTAL_LAYER-1];

//========== main loops ==========//
reg clk;
reg rst_n;
reg [IN_CHANNEL*9*`BITWIDTH-1:0] in_activation;
reg [OUT_CHANNEL*IN_CHANNEL/`N*9*`BITWIDTH-1:0] weight;
reg [OUT_CHANNEL*`BITWIDTH-1:0] bias;
reg [4*BW_FL-1:0] ftr_fl;
reg [4*BW_FL-1:0] out_fl;
reg [BW_FL-1:0] wgt_fl;
reg [BW_FL-1:0] bias_fl;
reg [4*BW_FL-1:0] idt_fl;
reg relu;
reg residual;
reg [OUT_CHANNEL*`BITWIDTH-1:0] identity;
wire [OUT_CHANNEL*`BITWIDTH-1:0] out_acivation;

`ifdef DYN_8
    conv_top conv_top_U0(
        .clk(clk),
        .rst_n(rst_n),
        .in_activation(in_activation),
        .weight(weight),
        .bias(bias),
        .ftr_fl(ftr_fl),
        .wgt_fl(wgt_fl),
        .bias_fl(bias_fl),
        .idt_fl(idt_fl),
        .out_fl(out_fl),
        .relu(relu),
        .residual(residual),
        .identity(identity),
        .out_acivation(out_acivation)
    );
`elsif RING 
    conv_top conv_top_U0(
        .clk(clk),
        .rst_n(rst_n),
        .in_activation(in_activation),
        .weight(weight),
        .bias(bias),
        .ftr_fl(ftr_fl),
        .wgt_fl(wgt_fl),
        .bias_fl(bias_fl),
        .idt_fl(idt_fl),
        .out_fl(out_fl),
        .relu(relu),
        .residual(residual),
        .identity(identity),
        .out_acivation(out_acivation)
    );
`else
    conv_top conv_top_U0(
        .clk(clk),
        .rst_n(rst_n),
        .in_activation(in_activation),
        .weight(weight),
        .bias(bias),
        .relu(relu),
        .residual(residual),
        .identity(identity),
        .out_acivation(out_acivation)
    );
`endif


//========== Initialization ==========//
always #(`CYCLE/2) clk = ~clk;
`ifdef IMAGE_OUT
    // initial begin
	//     $fsdbDumpfile("cnn.fsdb");
    //     $fsdbDumpvars(2);
    // end
`else
    initial begin
	    $fsdbDumpfile("cnn.fsdb");
	    $fsdbDumpvars("+mda", conv_top_U0);
        $fsdbDumpvars(2);
    end
`endif

initial begin
    clk = 0;    
    rst_n = 1;
    #(`CYCLE*2) rst_n = 0; 
    #(`CYCLE*2) rst_n = 1; 

end

//========== variable declaration ==========//
integer current_layer; 
integer feed_chout_idx, feed_row_idx, feed_col_idx;
integer res_chout_idx, res_row_idx, res_col_idx;
integer save_chout_idx, save_row_idx, save_col_idx;
reg config_finish, save_finish;

reg [3:0] Relu, PixelShuffle, srcSRAM, resSRAM, dstSRAM;
reg [7:0] CHout, CHin; 
reg [11:0] blkH, blkW;

//========== load pattern from file ==========//

initial begin
    load_instruction;
    load_act;
    load_wgt;
    load_bias;
    load_fl; 
    `ifdef CHECK_RESULT
        load_gloden;
    `endif

    // out_fl=15; blkH=640; blkW=960; dstSRAM=0;
    // write_image;
    // $finish;

    $display("Load files finish.");
    #(1000000000*`CYCLE) $finish;
end

//========== instrurction decode ==========//
// ISA: (ReLU)_(PixelShuffle)_(srcSRAM)_(resSRAM"f:non")_(dstSRAM)_(CHout)_(CHin)_(blkH)_(blkW)
reg [BW_FL*`N-1:0] ftr_fl_1ch, out_fl_1ch, idt_fl_1ch;
initial begin
    {Relu, PixelShuffle, srcSRAM, resSRAM, dstSRAM, CHout, CHin} = 0;
    relu = 0;
    ftr_fl = 0;
    out_fl = 0;
    wgt_fl = 0;
    bias_fl = 0;
    idt_fl = 0;
    residual = 0;
    config_finish = 0;
    `ifdef RESBLOCK1
        current_layer = 1;
    `elsif RESBLOCK2
        current_layer = 3;
    `else
        current_layer = 0;
    `endif
    wait(rst_n==0);
    wait(rst_n==1);
    while(current_layer<`SIM_LAYER) begin
        @(negedge clk) 
        $display("Computing layer%2d", current_layer);
        {Relu, PixelShuffle, srcSRAM, resSRAM, dstSRAM, CHout, CHin} = inst[current_layer];
        relu = Relu[0]; 
        blkH = current_layer==`TOTAL_LAYER-1? 4*`BLOCK_HEIGHT: current_layer==`TOTAL_LAYER-2? 2*`BLOCK_HEIGHT:`BLOCK_HEIGHT;
        blkW = current_layer==`TOTAL_LAYER-1? 4*`BLOCK_WIDTH : current_layer==`TOTAL_LAYER-2? 2*`BLOCK_WIDTH :`BLOCK_WIDTH ;
        wgt_fl = param_fl_mem[current_layer*2];
        bias_fl = param_fl_mem[current_layer*2+1];
        ftr_fl_1ch = act_fl_mem[current_layer];
        out_fl_1ch = act_fl_mem[current_layer+1];
        idt_fl_1ch = act_fl_mem[current_layer-1];
        if(`N==1) begin
            ftr_fl = {ftr_fl_1ch,ftr_fl_1ch,ftr_fl_1ch,ftr_fl_1ch};
            out_fl = {out_fl_1ch,out_fl_1ch,out_fl_1ch,out_fl_1ch};
            idt_fl = {idt_fl_1ch,idt_fl_1ch,idt_fl_1ch,idt_fl_1ch};
        end else if (`N==2) begin
            ftr_fl = {ftr_fl_1ch,ftr_fl_1ch};
            out_fl = {out_fl_1ch,out_fl_1ch};
            idt_fl = {idt_fl_1ch,idt_fl_1ch};
        end else begin
            if(current_layer==0)begin
                ftr_fl = {ftr_fl_1ch[BW_FL-1:0],ftr_fl_1ch[BW_FL-1:0],ftr_fl_1ch[BW_FL-1:0],ftr_fl_1ch[BW_FL-1:0]};
            end else begin
                ftr_fl = ftr_fl_1ch;
            end
            if(current_layer==`TOTAL_LAYER-1)begin
                out_fl = {out_fl_1ch[BW_FL-1:0],out_fl_1ch[BW_FL-1:0],out_fl_1ch[BW_FL-1:0],out_fl_1ch[BW_FL-1:0]};
            end else begin
                out_fl = out_fl_1ch;
            end
            idt_fl = idt_fl_1ch;
        end
        residual = (resSRAM==4'hf)? 0:1;
        config_finish = 1; #(`CYCLE) config_finish =0;
        wait(save_finish);
        current_layer = current_layer+1;
    end
    // $finish;
end

//========== feed pattern ==========//
integer test_row;
initial begin
    wait(rst_n==0);
    wait(rst_n==1);
    while(1) begin
        wait(config_finish);
        `ifndef IMAGE_OUT 
            test_row = blkH;
        `else
            test_row = blkH;
        `endif
        for(feed_chout_idx=0; feed_chout_idx<(CHout+OUT_CHANNEL-1)/OUT_CHANNEL; feed_chout_idx=feed_chout_idx+1)begin
            for(feed_row_idx=0; feed_row_idx<test_row; feed_row_idx=feed_row_idx+1)begin
                for(feed_col_idx=0; feed_col_idx<blkW; feed_col_idx=feed_col_idx+1)begin
                    @(negedge clk)
                    // flag_feed = 1;
                    send_act(feed_row_idx, feed_col_idx, srcSRAM);
                    send_param(feed_chout_idx);
                end
            end
        end 
        wait(save_finish);
    end
end

//========== feed residual connect ==========//
initial begin
    wait(rst_n==0);
    wait(rst_n==1);
    while(1) begin
        wait(config_finish);
        #(`CYCLE*CONV_LATENCY)
        @(negedge clk);
        for(res_chout_idx=0; res_chout_idx<(CHout+OUT_CHANNEL-1)/OUT_CHANNEL; res_chout_idx=res_chout_idx+1)begin
            for(res_row_idx=0; res_row_idx<test_row; res_row_idx=res_row_idx+1)begin
                for(res_col_idx=0; res_col_idx<blkW; res_col_idx=res_col_idx+1)begin
                    @(negedge clk)
                    send_res(res_chout_idx, res_row_idx, res_col_idx, resSRAM);
                end
            end
        end 
        wait(save_finish);
    end
end
//========== save pattern to SRAM ==========//
reg flag;
initial begin
    save_finish = 0;
    flag = 0;
    wait(rst_n==0);
    wait(rst_n==1);
    while(1) begin
        wait(config_finish);
        save_finish = 0;
        #(`CYCLE*POST_LATENCY);
        @(negedge clk);
        save_finish = 0;
        for(save_chout_idx=0; save_chout_idx<(CHout+OUT_CHANNEL-1)/OUT_CHANNEL; save_chout_idx=save_chout_idx+1)begin
            for(save_row_idx=0; save_row_idx<test_row; save_row_idx=save_row_idx+1)begin
                for(save_col_idx=0; save_col_idx<blkW; save_col_idx=save_col_idx+1)begin
                    @(negedge clk) // wait(valid==1);
                    flag = 1;
                    save_act(save_row_idx, save_col_idx, save_chout_idx, dstSRAM);
                end
            end
        end
        save_finish = 1;
    end
end

//========== check pattern ==========//
initial begin
    wait(current_layer===`SIM_LAYER); 
    wait(save_finish);
    // check_output;
    `ifdef IMAGE_OUT
        // calculate_psnr;
        write_image;
    `endif
    $finish;
end

`include "task.v"
endmodule

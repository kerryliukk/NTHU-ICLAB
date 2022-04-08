
//========== task definition ===========//
task load_instruction;
    $readmemh(`INST_FILE, inst);
endtask

task load_wgt;
begin
            $readmemh(`WEIGHT_FILE0, wgt_mem, 0);
            $readmemh(`WEIGHT_FILE1, wgt_mem, 1*MAX_CHANNEL);
            $readmemh(`WEIGHT_FILE2, wgt_mem, 2*MAX_CHANNEL);
            $readmemh(`WEIGHT_FILE3, wgt_mem, 3*MAX_CHANNEL);
            $readmemh(`WEIGHT_FILE4, wgt_mem, 4*MAX_CHANNEL);
            $readmemh(`WEIGHT_FILE5, wgt_mem, 5*MAX_CHANNEL);
            $readmemh(`WEIGHT_FILE6, wgt_mem, 6*MAX_CHANNEL);
            $readmemh(`WEIGHT_FILE7, wgt_mem, 7*MAX_CHANNEL);
end
endtask

task load_bias;
begin
            $readmemh(`BIAS_FILE0, bias_mem, 0);
            $readmemh(`BIAS_FILE1, bias_mem, 1*MAX_CHANNEL);
            $readmemh(`BIAS_FILE2, bias_mem, 2*MAX_CHANNEL);
            $readmemh(`BIAS_FILE3, bias_mem, 3*MAX_CHANNEL);
            $readmemh(`BIAS_FILE4, bias_mem, 4*MAX_CHANNEL);
            $readmemh(`BIAS_FILE5, bias_mem, 5*MAX_CHANNEL);
            $readmemh(`BIAS_FILE6, bias_mem, 6*MAX_CHANNEL);
            $readmemh(`BIAS_FILE7, bias_mem, 7*MAX_CHANNEL);
end
endtask

task load_act;
begin
    `ifdef RESBLOCK1
        $readmemh(`ACT_FILE, act_mem, 1*ACT_MEM_SIZE);
    `elsif RESBLOCK2
        $readmemh(`ACT_FILE, act_mem, 0*ACT_MEM_SIZE);
    `else
        $readmemh(`ACT_FILE, act_mem);
    `endif
end
endtask

task load_fl;
begin
    $readmemh(`ACT_FL_FILE, act_fl_mem);
    `ifdef DYN_8
        $readmemh(`PARAM_FL_FILE, param_fl_mem); 
    `elsif RING
        $readmemh(`PARAM_FL_FILE, param_fl_mem); 
    `endif
end
endtask

task load_gloden;
begin
    $readmemh(`GOLD_FILE, gold_mem);
end
endtask

task send_param(
    input [7:0] out_ch
);
integer ch_idx;
integer param_addr_offset;
begin
    `ifndef RING
        param_addr_offset = current_layer*MAX_CHANNEL+4*out_ch;
        if(CHin==3) begin
            for(ch_idx=0;ch_idx<OUT_CHANNEL;ch_idx=ch_idx+1) begin
                weight[(OUT_CHANNEL-ch_idx-1)*IN_CHANNEL*9*`BITWIDTH +: IN_CHANNEL*9*`BITWIDTH] 
                    = {wgt_mem[param_addr_offset+ch_idx][0+:3*9*`BITWIDTH], {(13*9*`BITWIDTH){1'd0}}};
                bias[(OUT_CHANNEL-ch_idx-1)*`BITWIDTH +: `BITWIDTH] = bias_mem[param_addr_offset+ch_idx];
            end
        end else begin
            for(ch_idx=0;ch_idx<OUT_CHANNEL;ch_idx=ch_idx+1) begin
                weight[(OUT_CHANNEL-ch_idx-1)*IN_CHANNEL*9*`BITWIDTH +: IN_CHANNEL*9*`BITWIDTH] = wgt_mem[param_addr_offset+ch_idx];
                bias[(OUT_CHANNEL-ch_idx-1)*`BITWIDTH +: `BITWIDTH] = bias_mem[param_addr_offset+ch_idx];
            end
        end    
    `else
        if(CHin==4) begin
            param_addr_offset = current_layer*MAX_CHANNEL+out_ch;
            weight = {wgt_mem[param_addr_offset][3*9*`BITWIDTH+:9*`BITWIDTH], {(3*9*`BITWIDTH){1'b0}},
                      wgt_mem[param_addr_offset][2*9*`BITWIDTH+:9*`BITWIDTH], {(3*9*`BITWIDTH){1'b0}},
                      wgt_mem[param_addr_offset][1*9*`BITWIDTH+:9*`BITWIDTH], {(3*9*`BITWIDTH){1'b0}},
                      wgt_mem[param_addr_offset][0*9*`BITWIDTH+:9*`BITWIDTH], {(3*9*`BITWIDTH){1'b0}}};
            bias   = bias_mem[param_addr_offset];
        end else begin
            param_addr_offset = current_layer*MAX_CHANNEL+out_ch;
            weight = wgt_mem[param_addr_offset];
            bias   = bias_mem[param_addr_offset];
        end
    `endif
end
endtask

task send_act(
    input [31:0] h,
    input [31:0] w,
    input [1:0] sram_idx
);
integer ch_idx;
integer px0_idx, px1_idx, px2_idx, px3_idx, px4_idx, px5_idx, px6_idx, px7_idx, px8_idx;
integer ch_sel;
reg [`BITWIDTH-1:0] px0, px1, px2, px3, px4, px5, px6, px7, px8; 
begin
    for(ch_idx=0;ch_idx<CHin;ch_idx=ch_idx+1)begin
        // interleaving input channel for Ring inference 
        ch_sel = ((CHin/`N)*(ch_idx%`N)+ch_idx/`N);
        
        px0_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + (h-1)*blkW + w-1;
        px1_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + (h-1)*blkW + w;
        px2_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + (h-1)*blkW + w+1;
        px3_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + h*blkW + w-1;
        px4_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + h*blkW + w;
        px5_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + h*blkW + w+1;
        px6_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + (h+1)*blkW + w-1;
        px7_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + (h+1)*blkW + w;
        px8_idx = sram_idx*ACT_MEM_SIZE + ch_sel*blkH*blkW + (h+1)*blkW + w+1;
        // $display("%d, %d, %d, %d", sram_idx, ch_idx, h, w);
        case(1)
        h==0&w==0:begin
            px0 = 0;
            px1 = 0;
            px2 = 0;
            px3 = 0;
            px4 = act_mem[px4_idx];
            px5 = act_mem[px5_idx];
            px6 = 0;
            px7 = act_mem[px7_idx];
            px8 = act_mem[px8_idx];
        end
        h==0&w==blkW-1:begin
            px0 = 0;
            px1 = 0;
            px2 = 0;
            px3 = act_mem[px3_idx];
            px4 = act_mem[px4_idx];
            px5 = 0;
            px6 = act_mem[px6_idx];
            px7 = act_mem[px7_idx];
            px8 = 0;
        end
        h==blkH-1&w==0:begin
            px0 = 0;
            px1 = act_mem[px1_idx];
            px2 = act_mem[px2_idx];
            px3 = 0;
            px4 = act_mem[px4_idx];
            px5 = act_mem[px5_idx];
            px6 = 0;
            px7 = 0;
            px8 = 0;
        end
        h==blkH-1&w==blkW-1:begin
            px0 = act_mem[px0_idx];
            px1 = act_mem[px1_idx];
            px2 = 0;
            px3 = act_mem[px3_idx];
            px4 = act_mem[px4_idx];
            px5 = 0;
            px6 = 0;
            px7 = 0;
            px8 = 0;
        end
        h==0:begin
            px0 = 0;
            px1 = 0;
            px2 = 0;
            px3 = act_mem[px3_idx];
            px4 = act_mem[px4_idx];
            px5 = act_mem[px5_idx];
            px6 = act_mem[px6_idx];
            px7 = act_mem[px7_idx];
            px8 = act_mem[px8_idx];
        end
        h==blkH-1:begin
            px0 = act_mem[px0_idx];
            px1 = act_mem[px1_idx];
            px2 = act_mem[px2_idx];
            px3 = act_mem[px3_idx];
            px4 = act_mem[px4_idx];
            px5 = act_mem[px5_idx];
            px6 = 0;
            px7 = 0;
            px8 = 0;
        end
        w==0:begin
            px0 = 0;
            px1 = act_mem[px1_idx];
            px2 = act_mem[px2_idx];
            px3 = 0;
            px4 = act_mem[px4_idx];
            px5 = act_mem[px5_idx];
            px6 = 0;
            px7 = act_mem[px7_idx];
            px8 = act_mem[px8_idx];
        end
        w==blkW-1:begin
            px0 = act_mem[px0_idx];
            px1 = act_mem[px1_idx];
            px2 = 0;
            px3 = act_mem[px3_idx];
            px4 = act_mem[px4_idx];
            px5 = 0;
            px6 = act_mem[px6_idx];
            px7 = act_mem[px7_idx];
            px8 = 0;
        end
        default:begin
            px0 = act_mem[px0_idx];
            px1 = act_mem[px1_idx];
            px2 = act_mem[px2_idx];
            px3 = act_mem[px3_idx];
            px4 = act_mem[px4_idx];
            px5 = act_mem[px5_idx];
            px6 = act_mem[px6_idx];
            px7 = act_mem[px7_idx];
            px8 = act_mem[px8_idx];
        end
        endcase
        in_activation[(IN_CHANNEL-ch_idx-1)*9*`BITWIDTH +: 9*`BITWIDTH] = {px0, px1, px2, px3, px4, px5, px6, px7, px8};
    end
    while(ch_idx<IN_CHANNEL)begin
            in_activation[(IN_CHANNEL-ch_idx-1)*9*`BITWIDTH +: 9*`BITWIDTH] = 0;
            ch_idx=ch_idx+1;
    end
end
endtask

task send_res(
    input [3:0] ch,
    input [31:0] h,
    input [31:0] w,
    input [1:0] sram_idx
);
integer ch_idx;
integer px_idx;
begin
    for(ch_idx=0;ch_idx<OUT_CHANNEL;ch_idx=ch_idx+1)begin
        px_idx = sram_idx*ACT_MEM_SIZE + (ch*OUT_CHANNEL/`N+ch_idx*`N)*blkH*blkW + h*blkW + w;
        identity[(OUT_CHANNEL-ch_idx-1)*`BITWIDTH +: `BITWIDTH] = act_mem[px_idx];
    end
end
endtask

task save_act(
    input [31:0] h,
    input [31:0] w,
    input [31:0] out_channel,
    input [1:0] sram_idx
);
integer px0_idx, px1_idx, px2_idx, px3_idx;
reg [`BITWIDTH-1:0] out0, out1, out2, out3;
begin
    if(PixelShuffle==1) begin
        `ifdef RING
            px0_idx = sram_idx*ACT_MEM_SIZE + (out_channel/4+0*4)*2*blkH*2*blkW + (2*h+1*out_channel[1])*2*blkW + (2*w+1*out_channel[0]);
            px1_idx = sram_idx*ACT_MEM_SIZE + (out_channel/4+1*4)*2*blkH*2*blkW + (2*h+1*out_channel[1])*2*blkW + (2*w+1*out_channel[0]);
            px2_idx = sram_idx*ACT_MEM_SIZE + (out_channel/4+2*4)*2*blkH*2*blkW + (2*h+1*out_channel[1])*2*blkW + (2*w+1*out_channel[0]);
            px3_idx = sram_idx*ACT_MEM_SIZE + (out_channel/4+3*4)*2*blkH*2*blkW + (2*h+1*out_channel[1])*2*blkW + (2*w+1*out_channel[0]);
        `else
            px0_idx = sram_idx*ACT_MEM_SIZE + (out_channel)*2*blkH*2*blkW + (2*h+0)*2*blkW + (2*w+0);
            px1_idx = sram_idx*ACT_MEM_SIZE + (out_channel)*2*blkH*2*blkW + (2*h+0)*2*blkW + (2*w+1);
            px2_idx = sram_idx*ACT_MEM_SIZE + (out_channel)*2*blkH*2*blkW + (2*h+1)*2*blkW + (2*w+0);
            px3_idx = sram_idx*ACT_MEM_SIZE + (out_channel)*2*blkH*2*blkW + (2*h+1)*2*blkW + (2*w+1);
        `endif
    end else begin
        if(`N==4 && current_layer==`TOTAL_LAYER-1) begin
            px1_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+0)*blkH*blkW + h*blkW + w;
            px2_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+1)*blkH*blkW + h*blkW + w;
            px3_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+2)*blkH*blkW + h*blkW + w;
            px0_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+3)*blkH*blkW + h*blkW + w;
        end else begin
            px0_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+0*`N)*blkH*blkW + h*blkW + w;
            px1_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+1*`N)*blkH*blkW + h*blkW + w;
            px2_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+2*`N)*blkH*blkW + h*blkW + w;
            px3_idx = sram_idx*ACT_MEM_SIZE + (out_channel*4/`N+3*`N)*blkH*blkW + h*blkW + w;
        end
    end

    out0 = out_acivation[3*`BITWIDTH+:`BITWIDTH];
    out1 = out_acivation[2*`BITWIDTH+:`BITWIDTH];
    out2 = out_acivation[1*`BITWIDTH+:`BITWIDTH];
    out3 = out_acivation[0*`BITWIDTH+:`BITWIDTH];

    act_mem[px0_idx] = out0;
    act_mem[px1_idx] = out1;
    act_mem[px2_idx] = out2;
    act_mem[px3_idx] = out3;
    
    `ifdef CHECK_RESULT
        if(current_layer===`SIM_LAYER-1)
            check_output(h,w,out_channel,sram_idx);
    `endif
end
endtask

task check_output(
    input [31:0] h,
    input [31:0] w,
    input [31:0] out_channel,
    input [1:0] sram_idx
);
integer gold_addr, check_addr, ch;
integer check_channel, check_height, check_width;
reg [`BITWIDTH-1:0] golden, out;
begin
    check_channel = current_layer==`TOTAL_LAYER-1? 3:4;
    check_height  = PixelShuffle==0? blkH:blkH*2;
    check_width   = PixelShuffle==0? blkW:blkW*2;
    gold_addr  = 4/`N*out_channel*check_height*check_width+h*check_width+w;
    check_addr = sram_idx*ACT_MEM_SIZE+gold_addr;
    for(ch=0;ch<check_channel;ch=ch+1)begin
        if(current_layer==`TOTAL_LAYER-1) begin
            golden = gold_mem[gold_addr+ch*check_height*check_width];
            out    = act_mem[check_addr+ch*check_height*check_width];
        end else begin
            golden = gold_mem[gold_addr+ch*`N*check_height*check_width];
            out    = act_mem[check_addr+ch*`N*check_height*check_width];
        end
        if(golden==out) begin
        end else begin
            $display("Error!! channel=%d, h=%d, w=%d.", 4*out_channel+ch, h, w);
            $display("Expect: %h, get: %h", golden, out);
            $finish;
        end
    end
    if(h==check_height-1&&w==check_width-1&&out_channel==(check_channel+3)/4-1)
        $display("Congratulations!! All patterns are correct.");
end
endtask

// task check_output;
// integer check_ch_idx, check_h_idx, check_w_idx;
// integer check_channel, check_height, check_width;
// integer gold_addr, check_addr;
// reg [`BITWIDTH-1:0] golden, out;
// begin
//     check_channel = PixelShuffle==0? CHout:CHout/4;
//     check_height  = PixelShuffle==0? blkH:blkH*2;
//     check_width   = PixelShuffle==0? blkW:blkW*2;
//     for(check_ch_idx=0;check_ch_idx<check_channel;check_ch_idx=check_ch_idx+1)begin
//         for(check_h_idx=0;check_h_idx<check_height;check_h_idx=check_h_idx+1)begin
//             for(check_w_idx=0;check_w_idx<check_width;check_w_idx=check_w_idx+1)begin
//                 gold_addr  = check_ch_idx*check_height*check_width+check_h_idx*check_width+check_w_idx;
//                 check_addr = dstSRAM*ACT_MEM_SIZE+gold_addr;
//                 golden = gold_mem[gold_addr];
//                 out    = act_mem[check_addr];

//                 if(golden!==out) begin
//                     $display("Error!! channel=%d, h=%d, w=%d.", check_ch_idx, check_h_idx, check_w_idx);
//                     $display("Expext: %h, get: %h", golden, out);
//                     $finish;
//                 end
//             end
//         end
//     end
//     $display("Congratulations!! All patterns are correct.");
// end
// endtask

task write_image;
integer out_file;
integer img_ch_idx, img_h_idx, img_w_idx;
integer out_addr;
reg [`BITWIDTH-1:0] act_out;
reg signed [`BITWIDTH:0] value;
reg [8-1:0] px_out;
reg [BW_FL-1:0] fl;
begin
    out_file = $fopen(`OUT_FILE);
    fl = out_fl[BW_FL-1:0];
    for(img_ch_idx=0;img_ch_idx<3;img_ch_idx=img_ch_idx+1)begin
        for(img_h_idx=0;img_h_idx<blkH;img_h_idx=img_h_idx+1)begin
            for(img_w_idx=0;img_w_idx<blkW;img_w_idx=img_w_idx+1)begin
                out_addr  = dstSRAM*ACT_MEM_SIZE + img_ch_idx*blkH*blkW + img_h_idx*blkW + img_w_idx;
                act_out = act_mem[out_addr];
                value   = {act_out[`BITWIDTH-1],act_out};
                value   = value+(1'b1<<(fl-1)); // +0.5
                if (value>2**fl-1) // clip(0,1)
                    value = 2**fl-1;
                else if (value<0)
                    value = 0;
                px_out  = `BITWIDTH==16? value[fl-1-:8]:value[0+:8];
                if(img_w_idx==0)
                    $fwrite(out_file,"%h",px_out);
                else 
                    $fwrite(out_file,"_%h",px_out);
            end
            $fwrite(out_file,"\n");
        end
    end

    $fclose(out_file);
end
endtask
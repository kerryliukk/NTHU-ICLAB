`timescale 1ns/100ps

//`define PAT_START_NO 0
//`define PAT_END_NO   39
`define End_CYCLE  10000000 


`ifdef RANK_A
	`define RANK 2    
`elsif RANK_B
	`define RANK 1  
`elsif RANK_C
  `define RANK 0  
`endif



module test_qr_decode;

real  cycle_period=10; 

//====== module I/O =====
reg clk;
reg srstn;
reg qr_decode_start;

wire sram_rdata;
wire [11:0] sram_raddr;

wire decode_valid;
wire [7:0] decode_jis8_code;
wire qr_decode_finish;


//====== top connection =====
qr_decode qr_decode_0(
.clk(clk),
.srstn(srstn),
.qr_decode_start(qr_decode_start),

.sram_rdata(sram_rdata),
.sram_raddr(sram_raddr),

.decode_valid(decode_valid),
.decode_jis8_code(decode_jis8_code),
.qr_decode_finish(qr_decode_finish)
);

//====== SRAM connection =====
sram_4096x1b  sram_4096x1b_0 (
.clk(clk),
.csb(1'b0),
.wsb(1'b1),
.wdata(1'b0), 
.waddr(12'd0), 
.raddr(sram_raddr), 

.rdata(sram_rdata)
);


initial begin
`ifdef GATESIM
	$fsdbDumpfile("hw4_gatesim.fsdb");
  //$fsdbDumpvars("+mda");
	$fsdbDumpvars;
`else
	$fsdbDumpfile("hw4.fsdb");
  $fsdbDumpvars("+mda");
	$fsdbDumpvars;
`endif
end

//====== clock generation =====
initial begin
  clk = 1'b1;
  #(cycle_period/2);
  while(1)
    #(cycle_period/2) clk = ~clk;
end

//====== main procedural block for simulation =====
integer pat_no, pat_length, hw_length, j, cycle_cnt;

reg [25*8-1:0] pat_string;
reg [25*8-1:0] golden_string [0:40-1];
reg [7:0] golden_len [0:40-1];


initial begin
  	//$fsdbDumpvars;
 
  	srstn = 1'b1;
  	qr_decode_start = 1'b0;
  
  	read_golden_result;
  
  	#(cycle_period);
  
  	for(pat_no=`PAT_START_NO; pat_no<=`PAT_END_NO; pat_no=pat_no+1) begin
    	sram_4096x1b_0.bmp2sram(pat_no,`RANK); //load QR code (.bmp) into SRAM
    	// sram_4096x1b_0.display_sram;  //uncomment to see the content inside SRAM
    
    	pat_string = golden_string[pat_no]; //golden decoded text
    	pat_length = golden_len[pat_no];    //golden length
    
    	$display("Testing Pattern no %02d, text byte-length %02d:",pat_no, pat_length);
    	$write("Golden decoded text:   |");
    	for(j=0; j<pat_length; j=j+1) begin
      		$write("%s",pat_string[j*8 +: 8]);
    	end
    
		$write("|\nHardware decoded text: |");
		hw_length = 0;
		
		@(negedge clk);
		srstn = 1'b0;
		@(negedge clk);
		srstn = 1'b1;
		qr_decode_start = 1'b1;  //one-cycle pulse signal for start decoding
		@(negedge clk);
		qr_decode_start = 1'b0;       

		@(negedge clk);
		while(!qr_decode_finish) begin
			@(negedge clk);
			
			if(decode_valid) begin
				$write("%s",decode_jis8_code);
				
				if(decode_jis8_code!==pat_string[hw_length*8 +: 8]) begin
					$display("<---- this character is wrong!");
					$display("\nSimulation terminated!!");
					
					#5 $finish;
				end
				
				hw_length = hw_length+1;
			end
    	end
    
		if(hw_length !== pat_length) begin
			$display("<---- this shouldn't be the last character!,hw_length=%d",hw_length);
			$display("\nSimulation terminated!!");
			
			#5 $finish;
		end
    
    	$write("|\n");
  	end
  
	$display("Congratulations! Simulation from pattern no %02d to %02d is successfully passed!", `PAT_START_NO, `PAT_END_NO);
	$display("Total cycle count C = %d.", cycle_cnt);
	#5 $finish;
end


initial begin
	cycle_cnt = 0;
	
	#(cycle_period/2);
	wait(qr_decode_start);
  
	@(negedge clk);
	while(1) begin
		cycle_cnt = cycle_cnt+1;
		@(negedge clk);
	end
end

initial begin
	#(`End_CYCLE);
	$display("-----------------------------------------------------\n");
	$display("Error!!! There is something wrong with your code ...!\n");
 	$display("------The test result is .....FAIL ------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
end


//====== task for reading golden results =====
task read_golden_result;

reg [128*8-1:0] text_filename;
reg [128*8-1:0] len_filename;
reg [7:0] char_in;
integer ii, jj, this_len, file_in;
reg [25*8-1:0] temp_string;

begin
    text_filename = "./golden/golden_text.dat";
    len_filename = "./golden/golden_length.dat";
    
    $readmemh(len_filename, golden_len);
    
    file_in = $fopen(text_filename,"r");
    
    for (ii=0; ii<40; ii=ii+1) begin
        this_len = golden_len[ii];
        for(jj=0; jj<this_len; jj=jj+1) begin
          char_in = $fgetc(file_in); 
          temp_string[jj*8 +: 8] = char_in;
        end
        char_in = $fgetc(file_in); //change line
        char_in = $fgetc(file_in); //change line
        
        golden_string[ii] = temp_string;
    end
    
    $fclose(file_in);
  
  end
endtask

endmodule
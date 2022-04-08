//Behavioral model for SRAM 4096x1b

module sram_4096x1b(
input clk,
input csb,  //chip enable
input wsb,  //write enable
input wdata, //write data
input [11:0] waddr, //write address
input [11:0] raddr, //read address

output reg rdata //read data
);

reg [64*64-1:0] mem;

always@(negedge clk) begin
	if(~csb && ~wsb)
    	mem[waddr] <= wdata;
end

always@(negedge clk) begin
	if(~csb)
    	rdata <= mem[raddr];
end

//=== only read 25x25 bmp with 1078-byte header ==
task bmp2sram(
input [31:0] pat_no,
input [1:0] RANK
);

reg [20*8-1:0] bmp_filename;
integer this_i, this_j;
integer file_in;
reg [7:0] char_in;

begin
	if(RANK==0)
    	bmp_filename = "bmp/RANK_C/00.bmp";
   	else if(RANK==1)
    	bmp_filename = "bmp/RANK_B/00.bmp";
   	else
    	bmp_filename = "bmp/RANK_A/00.bmp";

   	bmp_filename[6*8-1:5*8] = (pat_no%100)/10+48;
   	bmp_filename[5*8-1:4*8] = pat_no%10+48;
   
   	file_in = $fopen(bmp_filename,"rb");
   
   	for(this_i=0; this_i<1078; this_i=this_i+1)
    	char_in = $fgetc(file_in);

   	for(this_i=64-1; this_i>=0; this_i=this_i-1) begin
    	for(this_j=0; this_j<64; this_j=this_j+1) begin //four-byte alignment
       		char_in = $fgetc(file_in);
         	mem[{this_i[5:0], this_j[5:0]}] = ~(char_in > 8'd128); //black means one
     	end
    end

   	$fclose(file_in);
end

endtask

//display the QR code in 64x64 SRAM
task display_sram;
integer this_i, this_j;

begin
    for(this_i=0; this_i<64; this_i=this_i+1) begin
       	for(this_j=0; this_j<64; this_j=this_j+1) begin
          	$write("%b ",mem[{this_i[5:0], this_j[5:0]}]);
       	end
       	$write("\n");
    end
end

endtask


endmodule


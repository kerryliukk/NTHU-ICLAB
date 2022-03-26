module dsram (addr,clk,en_wr,in,out);
parameter numAddr = 8;
parameter numWords = 256;
parameter wordLength = 32;

input 				clk;
input 				en_wr;

input 	[numAddr-1:0] 		addr;
input 	[wordLength-1:0] 	in;
output 	[wordLength-1:0] 	out;

reg    	[wordLength-1:0]   	memory[numWords-1:0];
reg  	[wordLength-1:0]	data_out1;
reg 	[wordLength-1:0] 	out;


always @ (posedge clk) 
	if (en_wr)
		data_out1 <= memory[addr];
	else 
		memory[addr] <= in;
		

always @ (data_out1)begin
		out = data_out1;
end
endmodule

`timescale 1ns/100ps

module test_my_div;

parameter DIVIDEND_WIDTH=16;
parameter DIVISOR_WIDTH=5;

reg clk;
reg [DIVIDEND_WIDTH-1:0] dividend;      //16-bit unsigned integer (0~65535)
reg [ DIVISOR_WIDTH-1:0] divisor;       // 8-bit unsigned integer (1~31, 0:invalid)
wire [DIVIDEND_WIDTH-1:0] quotient;     //16-bit unsigned integer

my_div #(DIVIDEND_WIDTH,DIVISOR_WIDTH) 
       my_div0(.clk(clk), .dividend(dividend), .divisor(divisor), .quotient(quotient));

//generate clock
initial begin
	clk = 1'b1;
	while(1)
	  #(10) clk = ~clk;
end


//testbench main loop
integer i,j;

initial begin
	//$fsdbDumpvars;
	dividend = 0;
	divisor = 0;
	#20;
	
	@(posedge clk); #1;
	for(i=0;i<32768;i=i+1)
	  for(j=1;j<32;j=j+1) begin
	  	dividend = i;
	  	divisor = j;
	  	
	  	@(posedge clk); #1;	//change input at 1ns after clock edge to avoid hold time violation
	  	if(quotient !== (i/j)) begin
	  		$display("\n Division error for %d/%d: Truth: %d, HW: %d! \n", i,j,i/j,quotient);
	  		#10 $finish;
	  	end
	  end
	
	$display("\n Congratulations! All cases are passed successfully \n!");
	#10 $finish;
end


endmodule

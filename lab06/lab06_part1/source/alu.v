module alu(
	//en_exe,
	read_data1,
	read_data2,
	opcode,
	shamt,
	funct,
	immd,
	ALUOp,
	ALUSrc,
	alu_result,
	alu_overflow,
	zero
);



//input en_exe;
input [5:0]opcode;
input [4:0]shamt;
input [5:0]funct;
input signed[31:0] immd;
input signed[31:0] read_data1;
input signed[31:0] read_data2;
input [1:0]ALUOp;
input ALUSrc;


output wire signed [31:0] alu_result;
output reg alu_overflow;			
output reg zero;						//for branch condition

reg signed [31:0]src1, src2;
reg signed [31:0] alu_result_tmp;


//lab9 variable which you can change the type if you need//
wire signed [31:0] sub_temp1, sub_temp2, abs_result;
//lab9 variable which you can change the type if you need//



//MUX controlled by ALUSrc
always@(*) begin
	
	if(ALUSrc==1'b1) begin
		src2 = immd;	//sign extension
	end
	else begin
		src2 = read_data2;			//Rt
	end
end


always@(*) begin
	src1  = read_data1;				//Rs
end


always@(*)begin 
case(ALUOp)	 
	2'b00: begin
		alu_result_tmp = src1 + src2;		//add	for Itype, LW, SW
		zero = 1'b0;
	end
	2'b01: begin		
		
		alu_result_tmp = src1 - src2;		//sub	for BEQ instruction
		if(read_data1 == read_data2) begin
			zero = 1'b1;
		end
		else begin
			zero = 1'b0;
		end
	end
	2'b10: begin						//Rtype
		if(funct==`NOP) begin
			alu_result_tmp = 32'd0;
			zero = 1'b0;
		end
		else if(funct==`ADD) begin
			alu_result_tmp = src1 + src2;
			zero = 1'b0;
		end
		else if(funct==`SUB) begin
			alu_result_tmp = src1 - src2;
			zero = 1'b0;
		end
		else if(funct==`AND) begin
			alu_result_tmp = src1 & src2;         // change this to multiply(*) and compare.
			zero = 1'b0;
		end
		else if(funct==`OR) begin
			alu_result_tmp = src1 | src2;
			zero = 1'b0;
		end
		else if(funct==`XOR) begin
			alu_result_tmp = src1 ^ src2;
			zero = 1'b0;
		end
		else if(funct==`SLT) begin
			if(read_data1 < read_data2) begin
				alu_result_tmp = 32'd1;
				zero = 1'b0;
			end
			else begin
				alu_result_tmp = 32'd0;
				zero = 1'b0;
			end
		end
		else if(funct==`SLL) begin
			alu_result_tmp = src2 <<< shamt;
			zero = 1'b0;
		end
		else if(funct==`SRL) begin
			alu_result_tmp = src2 >>> shamt;
			zero = 1'b0;
		end
		else begin
			alu_result_tmp = 32'd0;
			zero = 1'b0;
		end
	end
	default: begin
		alu_result_tmp = 32'd0;
		zero = 1'b0;
	end
 
endcase                         
end                             

assign alu_result = (funct == `ABS)? abs_result : alu_result_tmp;


always@(*) begin
	if( (alu_result[31]==0 && src1[31]==1 && src2[31]==1 )||( alu_result[31]==1  && src1[31]==0 && src2[31]==0 ) )
		alu_overflow = 1'b1;
	else 
		alu_overflow = 1'b0;

end

assign sub_temp1 = (funct == `ABS)? (src1-src2) : 0;
assign abs_result = (sub_temp1[31]==1)? (~sub_temp1+1) : sub_temp1;

    
endmodule                     
                              
                              

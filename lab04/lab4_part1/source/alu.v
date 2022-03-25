module alu(
  // input en_exe,
  input signed [31:0]      read_data1,
  input signed [31:0]      read_data2,
  input [5:0]              opcode,
  input [4:0]              shamt,
  input [5:0]              funct,
  input signed [31:0]      immd,
  input [1:0]              ALUOp,
  input                    ALUSrc,
  output reg signed [31:0] alu_result,
  output reg               alu_overflow,
  output reg               zero // for branch condition
);

localparam NOP = 6'b00_0000, ADD = 6'b10_0000, SUB = 6'b10_0010,
           AND = 6'b10_0100, OR = 6'b10_0101, XOR = 6'b10_1000,
           SLT = 6'b10_1010, SLL = 6'b00_0011, SRL = 6'b00_0010;

reg signed [31:0] src1, src2;

// MUX controlled by ALUSrc
always@(*) begin
  if(ALUSrc==1'b1) begin
    src2 = immd;       //sign extension
  end
  else begin
    src2 = read_data2; //Rt
  end
end

always@(*) begin
  src1 = read_data1;   //Rs
end

always@(*)begin
  case(ALUOp)
    2'b00: begin
      alu_result = src1 + src2;    //add  for Itype, LW, SW
      zero = 1'b0;
    end
    2'b01: begin
      alu_result = src1 - src2;    //sub  for BEQ instruction
      zero = 1'b1;
    end
    2'b10: begin            //Rtype
      zero = 1'b0;
      if(funct==NOP) begin
        alu_result = 32'd0;
      end
      else if(funct==ADD) begin
        alu_result = src1 + src2;
      end
      else if(funct==SUB) begin
        alu_result = src1 - src2;
      end
      else if(funct==AND) begin
        alu_result = src1 & src2;
      end
      else if(funct==OR) begin
        alu_result = src1 | src2;
      end
      else if(funct==XOR) begin
        alu_result = src1 ^ src2;
      end
      else if(funct==SLT) begin
        if(read_data1 < read_data2) begin
          alu_result = 32'd1;
        end
        else begin
          alu_result = 32'd0;
        end
      end
      else if(funct==SLL) begin
        alu_result = src2 <<< shamt;
      end
      else if(funct==SRL) begin
        alu_result = src2 >>> shamt;
      end
      else begin
        alu_result = 32'd0;
      end
    end
    default: begin
      alu_result = 32'd0;
      zero = 1'b0;
    end
  endcase
end

always@(*) begin
  if( (alu_result[31]==0 && src1[31]==1 && src2[31]==1 )||( alu_result[31]==1  && src1[31]==0 && src2[31]==0 ) )
    alu_overflow = 1'b1;
  else
    alu_overflow = 1'b0;
end

endmodule

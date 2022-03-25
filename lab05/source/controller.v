module controller(
    //BEQ input
    input PCSrc,
    input [1:0] state,

    input [31:0] instn,

    //output reg [5:0]opcode,
    output reg RegDst,
    output reg [1:0]ALUOp,
    output reg ALUSrc,
    output reg branch,
    output reg MemRead,
    output reg MemWrite,
    output reg RegWrite,
    output reg MemtoReg,
    //BEQ output
    output reg [1:0] next_state,
    output reg beq_enable
);


parameter NORMAL = 2'b00;
parameter BEQ_IN = 2'b01;
parameter EQUAL = 2'b10;

reg [5:0]opcode;

always@* begin
  opcode  = instn[31:26];
end

////////////////////////
// finite state machine
// state has been declared as input
// nstate as output
// nstate will be send to state at posedge clk in other blocks
always @* begin
  case(state)
    NORMAL: begin
      if (opcode != `BEQ) begin
        next_state = NORMAL;
        beq_enable = 1'b0;
      end
      else begin
        next_state = BEQ_IN;
        beq_enable = 1'b1;
      end
    end

    BEQ_IN: begin
      if (PCSrc != 1'b1) begin
        next_state = NORMAL;
        beq_enable = 1'b0;
      end
      else begin
        next_state = EQUAL;
        beq_enable = 1'b1;
      end
    end

    EQUAL: begin
      next_state = NORMAL;
      beq_enable = 1'b0;
    end

    default: begin
      next_state = NORMAL;
      beq_enable = 1'b0;
    end
    
  endcase
end

////////////////////////

always@* begin
  case(opcode)
    `Rtype: begin
      RegDst = 1'b1;
      ALUOp = 2'b10;
      ALUSrc = 1'b0;
      branch = 1'b0;
      MemRead = 1'b0;
      MemWrite = 1'b0;
      RegWrite = 1'b1;
      MemtoReg = 1'b0;
    end
    `ADDI: begin
      RegDst = 1'b0;
      ALUOp = 2'b00;
      ALUSrc = 1'b1;
      branch = 1'b0;
      MemRead = 1'b0;
      MemWrite = 1'b0;
      RegWrite = 1'b1;
      MemtoReg = 1'b0;

    end
    `SET: begin
      RegDst = 1'b0;
      ALUOp = 2'b00;
      ALUSrc = 1'b1;
      branch = 1'b0;
      MemRead = 1'b0;
      MemWrite = 1'b0;
      RegWrite = 1'b1;
      MemtoReg = 1'b0;
    end
    
  /////////////////////////
  //More operation
    `LW: begin
      RegDst = 1'b0;
      ALUOp = 2'b10;
      ALUSrc = 1'b1;
      branch = 1'b0;
      MemRead = 1'b1;
      MemWrite = 1'b0;
      RegWrite = 1'b1;
      MemtoReg = 1'b1;
    end

    `SW: begin
      RegDst = 1'b0;
      ALUOp = 2'b00;
      ALUSrc = 1'b1;
      branch = 1'b0;
      MemRead = 1'b0;
      MemWrite = 1'b1;
      RegWrite = 1'b0;
      MemtoReg = 1'b0;
    end

    `BEQ: begin
      RegDst = 1'b0;
      ALUOp = 2'b01;
      ALUSrc = 1'b0;
      branch = 1'b1;
      MemRead = 1'b0;
      MemWrite = 1'b0;
      RegWrite = 1'b0;
      MemtoReg = 1'b0;
    end
  /////////////////////////

    default:begin
      RegDst = 1'b0;
      ALUOp = 2'b00;
      ALUSrc = 1'b0;
      branch = 1'b0;
      MemRead = 1'b0;
      MemWrite = 1'b0;
      RegWrite = 1'b0;
      MemtoReg = 1'b0;
    end
  endcase

end
endmodule

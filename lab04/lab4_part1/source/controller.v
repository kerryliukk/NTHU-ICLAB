module controller(
  // input
  input [31:0]     instn,
  // output
  // instruction type
  output reg [5:0] opcode,
  // control signals
  // Execution/Address Calculation stage control lines
  output reg       RegDst,
  output reg [1:0] ALUOp,
  output reg       ALUSrc,
  // Write-back stage control lines
  output reg       RegWrite
);

localparam Rtype = 6'b00_0000, ADDI = 6'b00_1000, SET = 6'b00_0001;

always@* begin
  opcode = instn[31:26];
end

always@* begin
  case(opcode)
    Rtype: begin
      RegDst   = 1'b1;
      ALUOp    = 2'b10;
      ALUSrc   = 1'b0;
      RegWrite = 1'b1;
    end
    ADDI: begin
      RegDst   = 1'b0;
      ALUOp    = 2'b00;
      ALUSrc   = 1'b1;
      RegWrite = 1'b1;
    end
    SET: begin
      RegDst   = 1'b0;
      ALUOp    = 2'b00;
      ALUSrc   = 1'b1;
      RegWrite = 1'b1;
    end
    default:begin
      RegDst   = 1'b0;
      ALUOp    = 2'b10;
      ALUSrc   = 1'b0;
      RegWrite = 1'b0;
    end
  endcase
end

endmodule

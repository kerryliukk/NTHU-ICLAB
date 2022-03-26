module SRAM
#
(
  parameter DATA_WIDTH = 4,
  parameter ADDR_WIDTH = 7
)
(
  input clk,
  input enable,
  input r_w, // r_w==0:write, r_w==1:read
  input [DATA_WIDTH-1:0] in,
  input [ADDR_WIDTH-1:0] addr,
  output reg [DATA_WIDTH-1:0] out
);

reg [DATA_WIDTH-1:0] memory [0:2**ADDR_WIDTH-1];

always@(posedge clk)begin
  if (enable == 1 && r_w == 0) 
    memory[addr] <= in;
  else if (enable == 1 && r_w == 1)
    out <= memory[addr];
  else
    out <= {DATA_WIDTH{1'bz}};
end

endmodule

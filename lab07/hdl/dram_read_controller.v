module dram_read_controller
#
(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 13
)
(
  input clk,
  input rst_n,
  input enable,
  output reg valid,
  output [DATA_WIDTH-1:0] out,
  // connect dram
  input [DATA_WIDTH-1:0] dram_out,
  output dram_read_en,
  output [ADDR_WIDTH-1:0] dram_addr
);
reg [ADDR_WIDTH-1:0] address;

always@(posedge clk)begin
  if(!rst_n) begin
    valid <= 0;
  end
  else begin
    valid <= enable;
  end
end

assign out          = dram_out;
assign dram_read_en = enable;
assign dram_addr    = address;

// address transition
always@(posedge clk) begin
  if(!rst_n) begin
    address <= 0;
  end
  else begin
    if(enable) begin
      address <= address+1;
    end
  end
end

endmodule

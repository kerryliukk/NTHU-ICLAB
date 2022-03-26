module two_port_ram_sclk
#
(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 13
)
(
  input clk,
  // Port A for write
  input en_a,
  input [ADDR_WIDTH-1:0] addr_a,
  input [DATA_WIDTH-1:0] data,
  // Port B for read
  input en_b,
  input [ADDR_WIDTH-1:0] addr_b,
  output reg [DATA_WIDTH-1:0] q
);
// Declare the RAM variable
reg [DATA_WIDTH-1:0] ram [0:2**ADDR_WIDTH-1];

// Port A for write
always@(posedge clk) begin
  if (en_a) begin
    ram[addr_a] <= data;
  end
end

// Port B for read
always@(posedge clk) begin
  if (en_b) begin
    q <= ram[addr_b];
  end
  else begin
    q <= 0;
  end
end

endmodule

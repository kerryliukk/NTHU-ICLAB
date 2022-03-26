module decoder
#
(
  parameter SRAM_DATA_WIDTH = 4,
  parameter SRAM_ADDR_WIDTH = 7,
  parameter DATA_WIDTH = 8
)
(
  input clk,
  input rst_n,
  input [DATA_WIDTH-1:0] width,               // image width
  input enable,
  input [SRAM_DATA_WIDTH-1:0] SRAM_data,
  output reg SRAM_enable,
  output reg [SRAM_ADDR_WIDTH-1:0] SRAM_addr,
  output reg valid,                           // valid ASCII code
  output reg [DATA_WIDTH-1:0] out,            // decoded ASCII code
  output reg done                             // finish decoding 3-row of image
);

// read 3 rows to start to decode 
// e.g.
// access address 0, 40, 80 and store the data in buffer -> decode -> 
// access address 1, 41, 81 -> decode ... -> done
// remember to calculate where is the end of the row to output done


endmodule

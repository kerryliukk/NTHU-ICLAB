module test_dram;

parameter CYCLE = 10; // use "CYCLE" to represent the period

parameter DRAM_DATA_WIDTH = 32;
parameter DRAM_ADDR_WIDTH = 13;

///// declare input(reg) and output(wire) /////
reg clk;
reg rst_n;
reg DRAM_enable;
wire DRAM_data_valid;
wire [DRAM_DATA_WIDTH-1:0] DRAM_data_out;
// dram write
reg en_a;
reg [DRAM_ADDR_WIDTH-1:0] addr_a;
reg [DRAM_DATA_WIDTH-1:0] data;
// dram read
wire en_b;
wire [DRAM_ADDR_WIDTH-1:0] addr_b;
wire [DRAM_DATA_WIDTH-1:0] q;

///// declare  module /////
two_port_ram_sclk
#
(
  .DATA_WIDTH(DRAM_DATA_WIDTH),
  .ADDR_WIDTH(DRAM_ADDR_WIDTH)
)
u_dram
(
  .clk(clk),
  .en_a(en_a),
  .addr_a(addr_a),
  .data(data),
  .en_b(en_b),
  .addr_b(addr_b),
  .q(q)
);

dram_read_controller
#
(
  .DATA_WIDTH(DRAM_DATA_WIDTH),
  .ADDR_WIDTH(DRAM_ADDR_WIDTH)
)
u_dram_controller
(
  .clk(clk),
  .rst_n(rst_n),
  .enable(DRAM_enable),
  .valid(DRAM_data_valid),
  .out(DRAM_data_out),
  // connect dram
  .dram_out(q),
  .dram_read_en(en_b),
  .dram_addr(addr_b)
);

///// fsdb /////
initial begin
  $fsdbDumpfile("dram.fsdb");
  $fsdbDumpvars(0, test_dram, "+mda");
end

///// clock /////
always #(CYCLE/2) clk = ~clk;

///// test patterns /////
initial begin
  // initialize the input signals
  clk = 0; rst_n = 0; DRAM_enable = 0;
  #(CYCLE) rst_n = 1;

  // initialize dram
  init_dram();
  $display("%d ns: Initialize DRAM finish", $time);
  #(CYCLE);

  // read data from image and write to dram
  read_image_to_dram("./image/chess_48x48_en.yuv");
  $display("%d ns: Read image finish", $time);
  #(CYCLE);

  // begin test
  $display("%d ns: Begin test", $time);
  #(4*CYCLE) DRAM_enable = 1;
  #(16*CYCLE) DRAM_enable = 0;
  #(4*CYCLE) DRAM_enable = 1;
  #(16*CYCLE) DRAM_enable = 0;

  #(CYCLE) $finish;
end

`include "simple_task.v"

endmodule

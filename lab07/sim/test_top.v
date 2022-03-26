module test_top;  

parameter CYCLE = 10; // use "CYCLE" to represent the period
parameter END_CYCLE = 30000;

parameter DRAM_DATA_WIDTH = 32;
parameter DRAM_ADDR_WIDTH = 13;
parameter SRAM_DATA_WIDTH = 4;
parameter SRAM_ADDR_WIDTH = 7;
parameter DATA_WIDTH = 8;

///// declare input(reg) and output(wire) /////
reg clk;
reg rst_n;
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

// steganography
reg top_enable;
reg [DATA_WIDTH-1:0] width;
reg [DATA_WIDTH-1:0] height;
wire DRAM_enable;
wire ascii_valid, done;
wire [DATA_WIDTH-1:0] ascii_out;

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

steganography
u_steganography
(
  .clk(clk),
  .rst_n(rst_n),
  .enable(top_enable),
  .width(width), 
  .height(height), 
  .DRAM_enable(DRAM_enable),
  .DRAM_data_valid(DRAM_data_valid),
  .DRAM_data(DRAM_data_out),
  .valid(ascii_valid), 
  .out(ascii_out), 
  .done(done) 
);

///// fsdb /////
initial begin
  $fsdbDumpfile("top.fsdb");
  $fsdbDumpvars(0, test_top, "+mda");
end

///// clock /////
always #(CYCLE/2) clk = ~clk;

integer filetxt, r;
reg [DATA_WIDTH-1:0] hidden;
initial begin
  // initialize the input signals
  clk = 0; top_enable = 0; rst_n = 0;
  width = 0; height = 0;
  #(CYCLE) rst_n= 1;

  // initialize dram
  init_dram();
  $display("%d ns: Initialize DRAM finish", $time);
  #(CYCLE);

  // read data from image and write to dram
  `ifdef CASE1
    // Case 1
    read_image_to_dram("./image/chess_48x48_en.yuv");
    filetxt = $fopen("./image/chess_hidden.txt", "r");
    width = 48; height = 48;
  `elsif CASE2
    // Case 2
    read_image_to_dram("./image/cth_96x120_en.yuv");
    filetxt = $fopen("./image/cth_hidden.txt", "r");
    width = 96; height = 120;
  `elsif CASE3
    // Case 3
    read_image_to_dram("./image/lena_120x120_en.yuv");
    filetxt = $fopen("./image/lena_hidden.txt", "r");
    width = 120; height = 120;
  `endif
  $display("%d ns: Read image finish", $time);

  // test decoder
  en_a = 0; data = 0; addr_a = 0;
  #(CYCLE) top_enable = 1; 
  $display("%d ns: Hidden messages", $time);
  while(1) begin
    @(negedge clk)
    if(ascii_valid === 1) begin
      r = $fscanf(filetxt, "%c", hidden);
      $write ("%c", ascii_out);
      if(hidden !== ascii_out) begin
        $display("\n\n%d ns: ERROR! decoded and hidden character not match", $time);
        $display("Decode: %c", ascii_out);
        $display("Hidden: %c", hidden);
        $fclose(filetxt);
        $finish;
      end
    end
    if(done === 1) begin
      if($feof(filetxt)) begin
        $display("\n\n%d ns: Congratulations! You find the secert messages!\n", $time);
        top_enable = 0;
        #(CYCLE);
        $fclose(filetxt);
        $finish;
      end
    end
  end
  $fclose(filetxt);
  #(CYCLE) $finish;
end

initial begin
  #(CYCLE*END_CYCLE);
  $display("%d ns: END CYCLE!", $time);
  $display("\n\nERROR! Not Enough CYCLE or done never goes high\n");
  $finish;
end

`include "simple_task.v"

endmodule

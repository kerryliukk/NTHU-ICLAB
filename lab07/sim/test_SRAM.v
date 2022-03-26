module test_SRAM;

parameter CYCLE = 10; // use "CYCLE" to represent the period
parameter END_CYCLE = 20000;

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
  $fsdbDumpfile("sram.fsdb");
  $fsdbDumpvars(0, test_SRAM, "+mda");
end

///// clock /////
always #(CYCLE/2) clk = ~clk;

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
  read_image_to_dram("./image/chess_48x48_en.yuv");
  $display("%d ns: Read image finish", $time);
  #(CYCLE);

  // test SRAM
  en_a = 0; data = 0; addr_a = 0;
  #(CYCLE)
  width = 48; height = 48;
  #(CYCLE) top_enable = 1; 
end

// check first 3 rows data in SRAM
integer i, j, t, r, filetxt, lsb, lsb_golden, char, error;
initial begin
  filetxt = $fopen("./chess.txt", "r");
  error = 0;

  @(negedge clk);
  // you can modify the condition for checking the data in SRAM
  wait(top_enable === 1); // wait steganography starting
  wait(u_dram_controller.address === width); // wait dram read three rows
  #(CYCLE);
  @(negedge clk);

  $display("%d ns: Begin to compare sram and golden", $time);
  for(t=0; t<3; t=t+1) begin // 3 rows
    for(i=0; i<width/3; i=i+1)begin // all blocks
      lsb_golden = 0;
      for(j=0; j<3; j=j+1) begin // read 3 char from golden lsb data
        r = $fscanf(filetxt, "%c", char);
        while(!(char == "0" | char == "1")) r = $fscanf(filetxt, "%c", char); // deal with new line
        char = char - "0";
        lsb_golden = lsb_golden | (char << j);
      end
      lsb = u_steganography.u_SRAM.memory[t*40+i];
      if(lsb_golden !== lsb) begin
        $display("    Error at addr %4d, sram %b    golden %b", t*40+i, lsb[3:0], lsb_golden[3:0]);
        error = error + 1;
      end
    end
  end
  if(error == 0) begin
    $display("%d ns: First 3 rows data in SRAM are the same!", $time);
    $finish;
  end
  else begin
    $display("%d ns: There are %d errors in SRAM", $time, error);
    $finish;
  end
end

initial begin
  #(CYCLE*END_CYCLE);
  $display("%d ns: END CYCLE! Try to enable 'DRAM_enable' in 'steganography'", $time);
  $finish;
end

`include "simple_task.v"

endmodule

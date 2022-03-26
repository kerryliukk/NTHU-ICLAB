//Wrap the synthesized netlist 



module CHIP (clk, rst_n, mode, pixel_in, valid,
             block_out_0, block_out_1, block_out_2, block_out_3);
    input clk; 
    input rst_n; 
    input mode; 
    input [8*70-1:0] pixel_in;
    output valid;
    output [12*9-1:0] block_out_0; 
    output [12*9-1:0] block_out_1; 
    output [12*9-1:0] block_out_2; 
    output [12*9-1:0] block_out_3;

    top U0(.clk(clk), .rst_n(rst_n), .mode(mode),
           .pixel_in(pixel_in), .valid(valid),
           .block_out_0(block_out_0), .block_out_1(block_out_1),
           .block_out_2(block_out_2), .block_out_3(block_out_3));
endmodule
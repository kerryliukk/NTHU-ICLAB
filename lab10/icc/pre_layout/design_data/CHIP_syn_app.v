//Wrap the synthesized netlist 

module CHIP ( clk, rst_n, boot_up, boot_addr, boot_datai, boot_web, 
        peri_web, peri_addr, peri_datao );
  input [7:0] boot_addr;
  input [31:0] boot_datai;
  output [15:0] peri_addr;
  output [15:0] peri_datao;
  input clk, rst_n, boot_up, boot_web;
  output peri_web;

  top_pipe U0(.clk(clk), .rst_n(rst_n), .boot_up(boot_up), 
              .boot_addr(boot_addr), .boot_datai(boot_datai), .boot_web(boot_web), 
              .peri_web(peri_web), .peri_addr(peri_addr), .peri_datao(peri_datao));
  
endmodule

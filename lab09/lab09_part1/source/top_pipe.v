module top_pipe(
	clk,
	rst_n,
        //input (icache input)
        boot_up,
        boot_addr,
        boot_datai,
        boot_web,
        //output (peripheral write)
        peri_web,
        peri_addr,
        peri_datao
);


input clk, rst_n;
input boot_up;
input [7:0] boot_addr;
input [31:0] boot_datai;
input boot_web;

output  peri_web;
output [15:0] peri_addr;
output [15:0] peri_datao;

reg rst_n_d;
reg boot_up_d;
reg [7:0] boot_addr_d;
reg [31:0] boot_datai_d;
reg boot_web_d;

reg  peri_web;
reg [15:0] peri_addr;
reg [15:0] peri_datao;

wire  peri_web_pre;
wire [15:0] peri_addr_pre;
wire [15:0] peri_datao_pre;

//use registers to isolate chip I/O
always@(posedge clk) begin
  rst_n_d <= rst_n;
  boot_up_d <= boot_up;
  boot_addr_d <= boot_addr;
  boot_datai_d <= boot_datai;
  boot_web_d <= boot_web;
  peri_web <= peri_web_pre;
  peri_addr <= peri_addr_pre;
  peri_datao <= peri_datao_pre;
end

top top0(
	.clk(clk),
	.rst_n(rst_n_d),
        //input (icache input)
        .boot_up(boot_up_d),
        .boot_addr(boot_addr_d),
        .boot_datai(boot_datai_d),
        .boot_web(boot_web_d),
        //output (peripheral write)
        .peri_web(peri_web_pre),
        .peri_addr(peri_addr_pre),
        .peri_datao(peri_datao_pre)
);


endmodule

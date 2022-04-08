module sram_64x8b #(       //for bias
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8
)
(
input clk,
input csb,  //chip enable
input wsb,  //write enable
input [BIAS_PER_ADDR*BW_PER_PARAM-1:0] wdata, //write data
input [5:0] waddr, //write address
input [5:0] raddr, //read address

output reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] rdata
);
/*
Data location
/////////////////////
addr 0~3: conv1 bias(4)
addr 4~15: conv2 bias(12)
addr 16~63: conv3 bias(48)
/////////////////////
*/
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] mem [0:63];
reg [BIAS_PER_ADDR*BW_PER_PARAM-1:0] _rdata;

always @(posedge clk) begin
    if(~csb && ~wsb)
        mem[waddr] <= wdata;
end

always @(posedge clk) begin
    if(~csb)
        _rdata <= mem[raddr];
end

always @* begin
    rdata = #(1) _rdata;
end

task load_param(
    input integer index,
    input [BIAS_PER_ADDR*BW_PER_PARAM-1:0] param_input
);
    mem[index] = param_input;
endtask

endmodule
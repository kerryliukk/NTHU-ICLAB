module sram_640x72b #(       //for weight
parameter WEIGHT_PER_ADDR = 9,
parameter BW_PER_PARAM = 8
)
(
input clk,
input csb,  //chip enable
input wsb,  //write enable
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] wdata, //write data
input [9:0] waddr, //write address
input [9:0] raddr, //read address

output reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] rdata
);
/*
Data location
/////////////////////
addr 0~15: conv1 weights(16)
addr 16~63: conv2 weights(48)
addr 64~639: conv3 weights (576)
/////////////////////
*/
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] mem [0:639];
reg [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] _rdata;

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
    input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] param_input
);
    mem[index] = param_input;
endtask

endmodule
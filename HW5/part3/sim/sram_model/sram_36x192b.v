module sram_36x192b #(     //for activation
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12
)
(
input clk,
input [CH_NUM*ACT_PER_ADDR-1:0] wordmask,  //16 bits
input csb,  //chip enable
input wsb,  //write enable
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] wdata, //write data 192 bits
input [5:0] waddr, //write address
input [5:0] raddr, //read address

output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] rdata //read data 192 bits
);

reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] _rdata;
reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] mem [0:35];
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] bit_mask;

assign bit_mask = {{12{wordmask[15]}}, {12{wordmask[14]}}, {12{wordmask[13]}}, {12{wordmask[12]}}, {12{wordmask[11]}}, {12{wordmask[10]}}, {12{wordmask[9]}}, {12{wordmask[8]}}, {12{wordmask[7]}}, {12{wordmask[6]}}, {12{wordmask[5]}}, {12{wordmask[4]}}, {12{wordmask[3]}}, {12{wordmask[2]}}, {12{wordmask[1]}}, {12{wordmask[0]}}};

always @(posedge clk) begin
    if(~csb && ~wsb) begin
        mem[waddr] <= (wdata & ~(bit_mask)) | (mem[waddr] & bit_mask);
    end
end

always @(posedge clk) begin
    if(~csb) begin
        _rdata <= mem[raddr];
    end
end

always @* begin
    rdata = #(1) _rdata;
end

endmodule
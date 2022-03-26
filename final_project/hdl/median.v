module median
(
    input clk,
    input rst_n,
    input [8-1:0] val_0,
    input [8-1:0] val_1,
    input [8-1:0] val_2,
    output reg [8-1:0] med
);

reg [8-1:0] med_n;

always @(*) begin
    // case1: val_0 is maximum
    if (val_0 >= val_1 && val_0 >= val_2) begin
        med_n = (val_1 >= val_2) ? val_1 : val_2;
    end
    // case2: val_1 is maximum
    else if (val_1 >= val_0 && val_1 >= val_2) begin
        med_n = (val_0 >= val_2) ? val_0 : val_2;
    end
    // case3: val_2 is maximum
    else begin
        med_n = (val_0 >= val_1) ? val_0 : val_1;
    end
end

always @(posedge clk) begin
    if (~rst_n) begin
        med <= 0;
    end
    else begin
        med <= med_n;
    end
    
end
endmodule



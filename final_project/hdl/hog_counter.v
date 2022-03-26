module hog_counter(
    input clk, rst_n,
    input start,
    output reg [8-1:0] cnt_row, 
    output reg [6-1:0] cnt_col
);

reg [8-1:0] cnt_row_next;
reg [6-1:0] cnt_col_next;

always @* begin
    if (start) begin
        if (cnt_col == 52) begin
            cnt_col_next = 0;
            cnt_row_next = cnt_row + 1;
        end
        else begin
            cnt_col_next = cnt_col + 1;
            cnt_row_next = cnt_row;
        end
    end
    else begin
        cnt_col_next = cnt_col;
        cnt_row_next = cnt_row;
    end
end

always @(posedge clk) begin
    if (~rst_n) begin
        cnt_col <= 0;
        cnt_row <= 0;
    end
    else begin
        cnt_col <= cnt_col_next;
        cnt_row <= cnt_row_next;
    end
end

endmodule
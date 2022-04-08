module FSM(
input clk, rst_n,
input enable, unshuffle_valid, conv1_valid,
output reg [4-1:0] state
);

reg [4-1:0] state_n;
parameter IDLE = 4'd0, UNSHUFFLE = 4'd1, CONV1 = 4'd2, FINISH = 4'd3;

always @* begin
    case (state) 
        IDLE: begin
            if (enable) begin
                state_n = UNSHUFFLE;
            end
            else begin
                state_n = IDLE;
            end
        end
        UNSHUFFLE: begin
            if (unshuffle_valid) begin
                state_n = CONV1;
            end
            else begin
                state_n = UNSHUFFLE;
            end
        end
        CONV1: begin
            if (conv1_valid) begin
                state_n = FINISH;
            end
            else begin
                state_n = CONV1;
            end
        end
        default: state_n = IDLE;
    endcase
end

always @(posedge clk) begin
    if (~rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_n;
    end
end

endmodule
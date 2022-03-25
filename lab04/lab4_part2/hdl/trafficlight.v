module trafficlight
#(parameter RED_TIME=4'd3, GREEN_TIME=4'd2, YELLOW_TIME=4'd1)
(
  // input
  input clk,
  input rst_n,  // synchronous negative reset
  input enable,
  // output
  output reg [1:0] out_state
);
// FSM
localparam IDLE=2'd0, RED=2'd1, GREEN=2'd2, YELLOW=2'd3;

reg [1:0] next_state; 
integer cycle = 0;

always @* begin
  // if (out_state != IDLE)
  //   cycle = cycle + 1'd1;
  // $display("state now = %b, cycle = %2d", out_state, cycle);
  case (out_state) 
    RED: begin
      if (cycle >= 3) begin
        next_state = GREEN;
        cycle = 0;
      end
      else begin
        next_state = RED;
      end
    end

    GREEN: begin
      if (cycle >= 2) begin
        next_state = YELLOW;
        cycle = 0;
      end
      else begin
        next_state = GREEN;
      end
    end

    YELLOW: begin
      next_state = RED;
      cycle = 0;
    end

    default: begin
      next_state = RED;
    end
  endcase  
end


always @(posedge clk) begin
  if (~rst_n) begin
    out_state <= IDLE;
    cycle = 0;
  end
  else if (~enable) begin
    out_state <= IDLE;
    cycle = 0;
  end
  else begin
    out_state <= next_state;
    cycle <= cycle + 1;
  end
end

endmodule

module steganography
#
(
  parameter DRAM_DATA_WIDTH = 32,
  parameter SRAM_DATA_WIDTH = 4,
  parameter SRAM_ADDR_WIDTH = 7,
  parameter DATA_WIDTH = 8
)
(
  input clk,
  input rst_n,
  input enable,
  input [DATA_WIDTH-1:0] width,    // image width
  input [DATA_WIDTH-1:0] height,   // image height
  output reg DRAM_enable,
  input DRAM_data_valid,
  input [DRAM_DATA_WIDTH-1:0] DRAM_data,
  output reg valid,                // valid ASCII out
  output reg [DATA_WIDTH-1:0] out, // decoded ASCII code
  output reg done                  // finish to decode image
);

// signals connect to SRAM
wire SRAM_enable;
wire SRAM_r_w;
wire [SRAM_DATA_WIDTH-1:0] SRAM_in;
wire [SRAM_ADDR_WIDTH-1:0] SRAM_addr;
wire [SRAM_DATA_WIDTH-1:0] SRAM_out;

// signals connect to decoder
wire decoder_enable;
wire [SRAM_DATA_WIDTH-1:0] decoder_SRAM_data;
wire decoder_SRAM_enable;
wire [SRAM_ADDR_WIDTH-1:0] decoder_SRAM_addr;
wire decoder_valid;
wire [DATA_WIDTH-1:0] decoder_out;
wire decoder_done;


// signals for FSM
reg valid_next;
reg [DATA_WIDTH-1:0] out_next;
reg done_next, DRAM_enable_next;
reg [1:0] state_next, state;
reg [DATA_WIDTH-1:0] dram_row_count, dram_row_count_next;
parameter LOAD = 0, WRITE = 1, DECODE = 2;
reg [7-1:0] addr_for_sram;
reg [SRAM_DATA_WIDTH-1:0] data_for_sram;
assign SRAM_addr = addr_for_sram;
assign SRAM_in = data_for_sram;

SRAM
u_SRAM
(
  .clk(clk),
  .enable(SRAM_enable),
  .r_w(SRAM_r_w),
  .in(SRAM_in),
  .addr(SRAM_addr),
  .out(SRAM_out)
);

decoder
u_decoder
(
  .clk(clk),
  .rst_n(rst_n),
  .width(width),
  .enable(decoder_enable),
  .SRAM_data(decoder_SRAM_data),
  .SRAM_enable(decoder_SRAM_enable),
  .SRAM_addr(decoder_SRAM_addr),
  .valid(decoder_valid),
  .out(decoder_out),
  .done(decoder_done)
);



always @* begin
  case (state)
    LOAD: begin
      if (DRAM_data_valid == 1'b1) begin
        state_next = WRITE;
        DRAM_enable_next = 1'b1;
        valid_next = 1'b0;
        out_next = out;
        done_next = 1'b0;
        dram_row_count_next = dram_row_count + 1;
      end
      else begin
        state_next = LOAD;
        DRAM_enable_next = 1'b1;
        valid_next = 1'b0;
        out_next = out;
        done_next = 1'b0;
        dram_row_count_next = dram_row_count;
      end
    end

    WRITE: begin
      if (dram_row_count + 1 == width) begin
        state_next = DECODE;
        DRAM_enable_next = 1'b0;
        valid_next = 1'b0;
        out_next = out;
        done_next = 1'b0;
        dram_row_count_next = dram_row_count;
      end
      else begin 
        state_next = WRITE;
        DRAM_enable_next = 1'b1;
        valid_next = 1'b0;
        out_next = out;
        done_next = 1'b0;
        dram_row_count_next = dram_row_count + 1;
      end
    end

    DECODE: begin
      if (decoder_done == 1'b1) begin
        state_next = WRITE;
        DRAM_enable_next = 1'b1;
        valid_next = 1'b0;
        out_next = decoder_out;
        done_next = 1'b0;
        dram_row_count_next = dram_row_count + 1;
      end
      else begin
        state_next = DECODE;
        DRAM_enable_next = 1'b0;
        valid_next = 1'b0;
        out_next = out;
        done_next = 1'b0;
        dram_row_count_next = dram_row_count;
      end
    end
    
    default: begin
      state_next = LOAD;
      DRAM_enable_next = 1'b0;
      valid_next = 1'b0;
      out_next = out;
      done_next = 1'b0;
      dram_row_count_next = dram_row_count;
    end
  endcase
end

always @* begin
  if (state == WRITE) begin
    if (dram_row_count < (width / 3)) begin
      addr_for_sram = dram_row_count;
      data_for_sram = {DRAM_data[0], DRAM_data[8], DRAM_data[16]};
    end
    else if (dram_row_count < (width / 3) * 2) begin
      addr_for_sram = dram_row_count - width + 40;
      data_for_sram = {DRAM_data[0], DRAM_data[8], DRAM_data[16]};
    end
    else begin
      addr_for_sram = dram_row_count - width * 2 + 40;
      data_for_sram = {DRAM_data[0], DRAM_data[8], DRAM_data[16]};
    end
  end
  else begin
    addr_for_sram = dram_row_count;
    data_for_sram = {DRAM_data[0], DRAM_data[8], DRAM_data[16]};
  end
end

always @(posedge clk) begin
  if (~rst_n) begin
    state <= LOAD;
    DRAM_enable <= 1'b0;
    valid <= 1'b0;
    out <= 0;
    done = 1'b0;
    dram_row_count <= 0;
  end

  else begin
    state <= state_next;
    DRAM_enable <= DRAM_enable_next;
    valid <= valid_next;
    out <= out_next;
    done <= done_next;
    dram_row_count <= dram_row_count_next;
  end
end

endmodule

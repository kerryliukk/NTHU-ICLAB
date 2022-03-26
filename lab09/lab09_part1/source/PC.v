module PC(
	clk,
        rst_n,
        boot_up,
	PCSrc,
	PC_out,
        PC_run,
	Branch_in
);

input clk;
input rst_n;
input boot_up;
input PCSrc;
input [15:0] Branch_in;

output [15:0] PC_out;
output PC_run;

parameter ST_PC_IDLE = 2'b00,
          ST_PC_LOAD = 2'b01,
          ST_PC_RUN  = 2'b10;

reg [1:0] PC_state, PC_state_nx;

wire PC_run = PC_state == ST_PC_RUN;

always@(posedge clk)
  if(!rst_n)
    PC_state <= ST_PC_IDLE;
  else
    PC_state <= PC_state_nx;

always@(PC_state or boot_up)
  case(PC_state)
    ST_PC_IDLE: PC_state_nx = boot_up ? ST_PC_LOAD : ST_PC_IDLE;
    ST_PC_LOAD: PC_state_nx = ~boot_up ? ST_PC_RUN : ST_PC_LOAD;
    default   : PC_state_nx = ST_PC_RUN;
  endcase


reg [15:0] PC_out;


wire [15:0] PC_in,PC_add;

assign PC_in = (PCSrc)? Branch_in:PC_add;
assign PC_add = PC_out + 16'd4;

always@(posedge clk)begin 
	if(~rst_n || (PC_state_nx != ST_PC_RUN))begin
		PC_out <= 0;
	end
	else begin
		PC_out <= PC_in;
	end
end

endmodule

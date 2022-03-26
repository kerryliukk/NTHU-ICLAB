module behavior_model(clk,srstn,load,encrypt,crypt_mode,load_idx,code_in,code_out,code_valid);
input clk;               //clock input
input srstn;             //synchronous reset (active low)
input load;              //load control signal (level sensitive). 0/1: inactive/active
                         //effective in IDLE and LOAD states
input encrypt;           //encrypt control signal (level sensitive). 0/1: inactive/active
                         //effective in READY state
input crypt_mode;        //0: encrypt; 1:decrypt
input [8-1:0] load_idx;		//index of rotor table to be loaded; A:0~63; B:64~127; C:128~191;
input [6-1:0] code_in;		//When load is active, 
                        //rotorA[load_idx[5:0]] <= code_in if load_idx[7:6]==2'b00
                        //rotorB[load_idx[5:0]] <= code_in if load_idx[7:6]==2'b01
						//rotorC[load_idx[5:0]] <= code_in if load_idx[7:6]==2'b10
output reg [6-1:0] code_out;   //encrypted code word (register output)
output reg code_valid;         //0: non-valid code_out; 1: valid code_out (register output)

parameter IDLE = 0, LOAD = 1, READY = 2;
integer i, k ;

reg [1:0] state, n_state;
reg [6-1:0] rotorA_table[0:64-1];
reg [6-1:0] reflector_table[0:64-1];
reg [6-1:0] rotA_o;
reg [6-1:0] ref_o;
reg [6-1:0] last_A;

/// FSM ///
always @*  begin

	if (~srstn) state = IDLE;
 
	case(state)
		IDLE: if (load) @(posedge clk) state = LOAD; 

		LOAD: begin
			if (load) begin
				@(posedge clk)  state = LOAD; 
			end else begin 
				@(posedge clk) state = READY;
			end 
		end
		READY: state = READY;
	endcase

	for (i=0; i<64; i = i+1) begin 
		reflector_table[i] = 63-i;
	end
end 

initial begin

	// Load Table 
	$readmemh("../sim/rotor/rotorA.dat",rotorA_table);
	wait(encrypt) ;
	
	for(k=0;k<24;k=k+1) begin
		@(posedge clk) 
			rotA_o = rotorA_table[code_in];
			ref_o = reflector_table[rotA_o];
			for (i=0; i<64; i = i+1) begin 
				if(rotorA_table[i] == ref_o) begin
					code_out = i;					
				end 
			end 
			code_valid = 1;
			last_A = rotorA_table[63];
			for (i=62; i>=0; i = i-1) begin
				rotorA_table[i+1] = rotorA_table[i];
			end
			rotorA_table[0]= last_A;
		
	end
end  



endmodule

module enigma_part1(clk,
                    srstn,
                    load,
                    encrypt,
                    crypt_mode,
                    load_idx,
                    code_in,
                    code_out,
                    code_valid
);

input clk;
input srstn;
input load;

input encrypt;

input crypt_mode;
input [8-1:0] load_idx;
input [6-1:0] code_in;

output reg [6-1:0] code_out;
output reg code_valid;

reg [6-1:0] code_out_next;
reg code_valid_next;


parameter IDLE = 2'd0, LOAD = 2'd1, READY = 2'd2;
integer i;

reg [1:0] state, n_state;
reg [6-1:0] rotorA_table [0:64-1];
reg [6-1:0] rotorA_table_next [0:64-1];
reg [6-1:0] reflector_table [0:64-1];
reg [6-1:0] rotA_o;
reg [6-1:0] ref_o;
reg [6-1:0] last_A;

/// FSM ///
always @* begin
	case(state)
		IDLE: begin
            if (load)
                n_state = LOAD; 
            else
                n_state = IDLE;
        end
		LOAD: begin
			if (load) 
				n_state = LOAD; 
            else  
				n_state = READY;
		end
		READY: begin
            n_state = READY;
        end
        default: n_state = IDLE;
	endcase
end 

always @* begin
    // construct reflector table
    for (i = 0; i < 64; i = i + 1) begin 
        reflector_table[i] = 63 - i;
    end

    // set default value
    rotA_o = rotorA_table[code_in];
    ref_o = reflector_table[rotA_o];
    code_out_next = 5'b0;
    last_A = rotorA_table[63];
    code_valid_next = 1'b0;
    for (i = 0; i < 64; i = i + 1) begin
        rotorA_table_next[i] = rotorA_table[i];
    end
    ///////////

    // load rotor table
    if (state == LOAD) begin
        for (i = 0; i < 64; i = i + 1) begin
            if (i == load_idx)
                rotorA_table_next[i] = code_in;
            else 
                rotorA_table_next[i] = rotorA_table[i];
        end        
        code_valid_next = 1'b0;
    end

    else if (state == READY && encrypt == 1'b1) begin
        
        rotA_o = rotorA_table[code_in];
        ref_o = reflector_table[rotA_o];

        case(ref_o)
            rotorA_table[0]: code_out_next = 6'd0;
            rotorA_table[1]: code_out_next = 6'd1;
            rotorA_table[2]: code_out_next = 6'd2;
            rotorA_table[3]: code_out_next = 6'd3;
            rotorA_table[4]: code_out_next = 6'd4;
            rotorA_table[5]: code_out_next = 6'd5;
            rotorA_table[6]: code_out_next = 6'd6;
            rotorA_table[7]: code_out_next = 6'd7;
            rotorA_table[8]: code_out_next = 6'd8;
            rotorA_table[9]: code_out_next = 6'd9;
            rotorA_table[10]: code_out_next = 6'd10;
            rotorA_table[11]: code_out_next = 6'd11;
            rotorA_table[12]: code_out_next = 6'd12;
            rotorA_table[13]: code_out_next = 6'd13;
            rotorA_table[14]: code_out_next = 6'd14;
            rotorA_table[15]: code_out_next = 6'd15;
            rotorA_table[16]: code_out_next = 6'd16;
            rotorA_table[17]: code_out_next = 6'd17;
            rotorA_table[18]: code_out_next = 6'd18;
            rotorA_table[19]: code_out_next = 6'd19;
            rotorA_table[20]: code_out_next = 6'd20;
            rotorA_table[21]: code_out_next = 6'd21;
            rotorA_table[22]: code_out_next = 6'd22;
            rotorA_table[23]: code_out_next = 6'd23;
            rotorA_table[24]: code_out_next = 6'd24;
            rotorA_table[25]: code_out_next = 6'd25;
            rotorA_table[26]: code_out_next = 6'd26;
            rotorA_table[27]: code_out_next = 6'd27;
            rotorA_table[28]: code_out_next = 6'd28;
            rotorA_table[29]: code_out_next = 6'd29;
            rotorA_table[30]: code_out_next = 6'd30;
            rotorA_table[31]: code_out_next = 6'd31;
            rotorA_table[32]: code_out_next = 6'd32;
            rotorA_table[33]: code_out_next = 6'd33;
            rotorA_table[34]: code_out_next = 6'd34;
            rotorA_table[35]: code_out_next = 6'd35;
            rotorA_table[36]: code_out_next = 6'd36;
            rotorA_table[37]: code_out_next = 6'd37;
            rotorA_table[38]: code_out_next = 6'd38;
            rotorA_table[39]: code_out_next = 6'd39;
            rotorA_table[40]: code_out_next = 6'd40;
            rotorA_table[41]: code_out_next = 6'd41;
            rotorA_table[42]: code_out_next = 6'd42;
            rotorA_table[43]: code_out_next = 6'd43;
            rotorA_table[44]: code_out_next = 6'd44;
            rotorA_table[45]: code_out_next = 6'd45;
            rotorA_table[46]: code_out_next = 6'd46;
            rotorA_table[47]: code_out_next = 6'd47;
            rotorA_table[48]: code_out_next = 6'd48;
            rotorA_table[49]: code_out_next = 6'd49;
            rotorA_table[50]: code_out_next = 6'd50;
            rotorA_table[51]: code_out_next = 6'd51;
            rotorA_table[52]: code_out_next = 6'd52;
            rotorA_table[53]: code_out_next = 6'd53;
            rotorA_table[54]: code_out_next = 6'd54;
            rotorA_table[55]: code_out_next = 6'd55;
            rotorA_table[56]: code_out_next = 6'd56;
            rotorA_table[57]: code_out_next = 6'd57;
            rotorA_table[58]: code_out_next = 6'd58;
            rotorA_table[59]: code_out_next = 6'd59;
            rotorA_table[60]: code_out_next = 6'd60;
            rotorA_table[61]: code_out_next = 6'd61;
            rotorA_table[62]: code_out_next = 6'd62;
            rotorA_table[63]: code_out_next = 6'd63;
            default         : code_out_next = 6'd1;
        endcase
        code_valid_next = 1'b1;

        // rotate rotor A by 1 bit
        last_A = rotorA_table[63];
        for (i = 62; i >= 0; i = i - 1) begin
            rotorA_table_next[i + 1] = rotorA_table[i];
        end
        rotorA_table_next[0] = last_A;
    end

        
end

always @(posedge clk) begin
    if (~srstn) begin
        code_valid <= 1'b0;
        code_out <= 6'b0;
        state <= IDLE;
        for (i = 0; i < 64; i = i + 1)
            rotorA_table[i] <= rotorA_table[i];
        
    end
    else begin
        code_valid <= code_valid_next;
        code_out <= code_out_next;
        state <= n_state;
        for (i = 0; i < 64; i = i + 1)
            rotorA_table[i] <= rotorA_table_next[i];
    end
end

endmodule

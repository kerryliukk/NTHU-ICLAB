module enigma_part2(clk,
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

reg [6-1:0] code_in_ff;
reg load_ff, encrypt_ff, crypt_mode_ff;
reg [8-1:0] load_idx_ff;

output reg [6-1:0] code_out;
output reg code_valid;

reg [6-1:0] code_out_next;
reg code_valid_next;

parameter IDLE = 2'd0, LOAD = 2'd1, READY = 2'd2;
integer i;
reg [6-1:0] idx_in_c;
reg [6-1:0] idx_in_b;
reg [6-1:0] idx_in_a;
reg [6-1:0] idx_in_ref;

reg [1:0] state, n_state;
reg [6-1:0] rotorA_table [0:64-1];
reg [6-1:0] rotorA_table_next [0:64-1];
reg [6-1:0] rotorB_table [0:64-1];
reg [6-1:0] rotorB_table_next [0:64-1];
reg [6-1:0] rotorC_table [0:64-1];
reg [6-1:0] rotorC_table_next [0:64-1];

reg [6-1:0] reflector_table [0:64-1];
reg [6-1:0] rotA_o;
reg [6-1:0] rotB_o;
reg [6-1:0] rotC_o;
reg [6-1:0] ref_o;

reg [6-1:0] last_A;
reg [6-1:0] last_B;

reg [6-1:0] tempc0;
reg [6-1:0] tempc1;
reg [6-1:0] tempc2;
reg [6-1:0] tempc3;
reg [6-1:0] rotorC_temp_box64 [0:64-1];

reg cnt, cnt_next;    // counter to decide whether to rotate rotor B or not

/// FSM ///
always @* begin
	case(state)
		IDLE: begin
            if (load_ff)
                n_state = LOAD; 
            else
                n_state = IDLE;
        end
		LOAD: begin
			if (load_ff) 
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
    for (i = 0; i < 64; i = i + 1) begin
        reflector_table[i] = 63 - i;
        rotorA_table_next[i] = rotorA_table[i];
        rotorB_table_next[i] = rotorB_table[i];
        rotorC_table_next[i] = rotorC_table[i];
    end
    cnt_next = cnt;
    code_valid_next = code_valid;
    code_out_next = code_out;

    
    if (state == LOAD) begin
        cnt_next = 1'b0;
        // $display("load idx = %4d", load_idx_ff);
        if (load_idx_ff < 64) begin   
            // load rotor A
            for (i = 0; i < 64; i = i + 1) begin
                if (load_idx_ff == i)
                    rotorA_table_next[i] = code_in_ff;
                else
                    rotorA_table_next[i] = rotorA_table[i];
            end
        end

        else if (load_idx_ff < 128) begin
            // load rotor B
            for (i = 0; i < 64; i = i + 1) begin
                if (load_idx_ff - 64 == i)
                    rotorB_table_next[i] = code_in_ff;
                else
                    rotorB_table_next[i] = rotorB_table[i];
            end
        end

        else begin
            // load rotor C
            for (i = 0; i < 64; i = i + 1) begin
                if (load_idx_ff - 128 == i)
                    rotorC_table_next[i] = code_in_ff;
                else
                    rotorC_table_next[i] = rotorC_table[i];
            end
        end
    end

    else if (state == READY && encrypt_ff == 1'b1) begin
        cnt_next = cnt + 1'b1;
        if (crypt_mode_ff == 1'b0) begin   // encrypt
            rotA_o = rotorA_table[code_in_ff];
            rotB_o = rotorB_table[rotA_o];
            rotC_o = rotorC_table[rotB_o];
            ref_o = reflector_table[rotC_o];
            case (ref_o)
                rotorC_table[0]: idx_in_c = 6'd0;
                rotorC_table[1]: idx_in_c = 6'd1;
                rotorC_table[2]: idx_in_c = 6'd2;
                rotorC_table[3]: idx_in_c = 6'd3;
                rotorC_table[4]: idx_in_c = 6'd4;
                rotorC_table[5]: idx_in_c = 6'd5;
                rotorC_table[6]: idx_in_c = 6'd6;
                rotorC_table[7]: idx_in_c = 6'd7;
                rotorC_table[8]: idx_in_c = 6'd8;
                rotorC_table[9]: idx_in_c = 6'd9;
                rotorC_table[10]: idx_in_c = 6'd10;
                rotorC_table[11]: idx_in_c = 6'd11;
                rotorC_table[12]: idx_in_c = 6'd12;
                rotorC_table[13]: idx_in_c = 6'd13;
                rotorC_table[14]: idx_in_c = 6'd14;
                rotorC_table[15]: idx_in_c = 6'd15;
                rotorC_table[16]: idx_in_c = 6'd16;
                rotorC_table[17]: idx_in_c = 6'd17;
                rotorC_table[18]: idx_in_c = 6'd18;
                rotorC_table[19]: idx_in_c = 6'd19;
                rotorC_table[20]: idx_in_c = 6'd20;
                rotorC_table[21]: idx_in_c = 6'd21;
                rotorC_table[22]: idx_in_c = 6'd22;
                rotorC_table[23]: idx_in_c = 6'd23;
                rotorC_table[24]: idx_in_c = 6'd24;
                rotorC_table[25]: idx_in_c = 6'd25;
                rotorC_table[26]: idx_in_c = 6'd26;
                rotorC_table[27]: idx_in_c = 6'd27;
                rotorC_table[28]: idx_in_c = 6'd28;
                rotorC_table[29]: idx_in_c = 6'd29;
                rotorC_table[30]: idx_in_c = 6'd30;
                rotorC_table[31]: idx_in_c = 6'd31;
                rotorC_table[32]: idx_in_c = 6'd32;
                rotorC_table[33]: idx_in_c = 6'd33;
                rotorC_table[34]: idx_in_c = 6'd34;
                rotorC_table[35]: idx_in_c = 6'd35;
                rotorC_table[36]: idx_in_c = 6'd36;
                rotorC_table[37]: idx_in_c = 6'd37;
                rotorC_table[38]: idx_in_c = 6'd38;
                rotorC_table[39]: idx_in_c = 6'd39;
                rotorC_table[40]: idx_in_c = 6'd40;
                rotorC_table[41]: idx_in_c = 6'd41;
                rotorC_table[42]: idx_in_c = 6'd42;
                rotorC_table[43]: idx_in_c = 6'd43;
                rotorC_table[44]: idx_in_c = 6'd44;
                rotorC_table[45]: idx_in_c = 6'd45;
                rotorC_table[46]: idx_in_c = 6'd46;
                rotorC_table[47]: idx_in_c = 6'd47;
                rotorC_table[48]: idx_in_c = 6'd48;
                rotorC_table[49]: idx_in_c = 6'd49;
                rotorC_table[50]: idx_in_c = 6'd50;
                rotorC_table[51]: idx_in_c = 6'd51;
                rotorC_table[52]: idx_in_c = 6'd52;
                rotorC_table[53]: idx_in_c = 6'd53;
                rotorC_table[54]: idx_in_c = 6'd54;
                rotorC_table[55]: idx_in_c = 6'd55;
                rotorC_table[56]: idx_in_c = 6'd56;
                rotorC_table[57]: idx_in_c = 6'd57;
                rotorC_table[58]: idx_in_c = 6'd58;
                rotorC_table[59]: idx_in_c = 6'd59;
                rotorC_table[60]: idx_in_c = 6'd60;
                rotorC_table[61]: idx_in_c = 6'd61;
                rotorC_table[62]: idx_in_c = 6'd62;
                rotorC_table[63]: idx_in_c = 6'd63;

                default         : idx_in_c = 6'd0;
            endcase
            case (idx_in_c)
                rotorB_table[0]: idx_in_b = 6'd0;
                rotorB_table[1]: idx_in_b = 6'd1;
                rotorB_table[2]: idx_in_b = 6'd2;
                rotorB_table[3]: idx_in_b = 6'd3;
                rotorB_table[4]: idx_in_b = 6'd4;
                rotorB_table[5]: idx_in_b = 6'd5;
                rotorB_table[6]: idx_in_b = 6'd6;
                rotorB_table[7]: idx_in_b = 6'd7;
                rotorB_table[8]: idx_in_b = 6'd8;
                rotorB_table[9]: idx_in_b = 6'd9;
                rotorB_table[10]: idx_in_b = 6'd10;
                rotorB_table[11]: idx_in_b = 6'd11;
                rotorB_table[12]: idx_in_b = 6'd12;
                rotorB_table[13]: idx_in_b = 6'd13;
                rotorB_table[14]: idx_in_b = 6'd14;
                rotorB_table[15]: idx_in_b = 6'd15;
                rotorB_table[16]: idx_in_b = 6'd16;
                rotorB_table[17]: idx_in_b = 6'd17;
                rotorB_table[18]: idx_in_b = 6'd18;
                rotorB_table[19]: idx_in_b = 6'd19;
                rotorB_table[20]: idx_in_b = 6'd20;
                rotorB_table[21]: idx_in_b = 6'd21;
                rotorB_table[22]: idx_in_b = 6'd22;
                rotorB_table[23]: idx_in_b = 6'd23;
                rotorB_table[24]: idx_in_b = 6'd24;
                rotorB_table[25]: idx_in_b = 6'd25;
                rotorB_table[26]: idx_in_b = 6'd26;
                rotorB_table[27]: idx_in_b = 6'd27;
                rotorB_table[28]: idx_in_b = 6'd28;
                rotorB_table[29]: idx_in_b = 6'd29;
                rotorB_table[30]: idx_in_b = 6'd30;
                rotorB_table[31]: idx_in_b = 6'd31;
                rotorB_table[32]: idx_in_b = 6'd32;
                rotorB_table[33]: idx_in_b = 6'd33;
                rotorB_table[34]: idx_in_b = 6'd34;
                rotorB_table[35]: idx_in_b = 6'd35;
                rotorB_table[36]: idx_in_b = 6'd36;
                rotorB_table[37]: idx_in_b = 6'd37;
                rotorB_table[38]: idx_in_b = 6'd38;
                rotorB_table[39]: idx_in_b = 6'd39;
                rotorB_table[40]: idx_in_b = 6'd40;
                rotorB_table[41]: idx_in_b = 6'd41;
                rotorB_table[42]: idx_in_b = 6'd42;
                rotorB_table[43]: idx_in_b = 6'd43;
                rotorB_table[44]: idx_in_b = 6'd44;
                rotorB_table[45]: idx_in_b = 6'd45;
                rotorB_table[46]: idx_in_b = 6'd46;
                rotorB_table[47]: idx_in_b = 6'd47;
                rotorB_table[48]: idx_in_b = 6'd48;
                rotorB_table[49]: idx_in_b = 6'd49;
                rotorB_table[50]: idx_in_b = 6'd50;
                rotorB_table[51]: idx_in_b = 6'd51;
                rotorB_table[52]: idx_in_b = 6'd52;
                rotorB_table[53]: idx_in_b = 6'd53;
                rotorB_table[54]: idx_in_b = 6'd54;
                rotorB_table[55]: idx_in_b = 6'd55;
                rotorB_table[56]: idx_in_b = 6'd56;
                rotorB_table[57]: idx_in_b = 6'd57;
                rotorB_table[58]: idx_in_b = 6'd58;
                rotorB_table[59]: idx_in_b = 6'd59;
                rotorB_table[60]: idx_in_b = 6'd60;
                rotorB_table[61]: idx_in_b = 6'd61;
                rotorB_table[62]: idx_in_b = 6'd62;
                rotorB_table[63]: idx_in_b = 6'd63;
                default         : idx_in_b = 6'd0;
            endcase
            case (idx_in_b)
                rotorA_table[0]: idx_in_a = 6'd0;
                rotorA_table[1]: idx_in_a = 6'd1;
                rotorA_table[2]: idx_in_a = 6'd2;
                rotorA_table[3]: idx_in_a = 6'd3;
                rotorA_table[4]: idx_in_a = 6'd4;
                rotorA_table[5]: idx_in_a = 6'd5;
                rotorA_table[6]: idx_in_a = 6'd6;
                rotorA_table[7]: idx_in_a = 6'd7;
                rotorA_table[8]: idx_in_a = 6'd8;
                rotorA_table[9]: idx_in_a = 6'd9;
                rotorA_table[10]: idx_in_a = 6'd10;
                rotorA_table[11]: idx_in_a = 6'd11;
                rotorA_table[12]: idx_in_a = 6'd12;
                rotorA_table[13]: idx_in_a = 6'd13;
                rotorA_table[14]: idx_in_a = 6'd14;
                rotorA_table[15]: idx_in_a = 6'd15;
                rotorA_table[16]: idx_in_a = 6'd16;
                rotorA_table[17]: idx_in_a = 6'd17;
                rotorA_table[18]: idx_in_a = 6'd18;
                rotorA_table[19]: idx_in_a = 6'd19;
                rotorA_table[20]: idx_in_a = 6'd20;
                rotorA_table[21]: idx_in_a = 6'd21;
                rotorA_table[22]: idx_in_a = 6'd22;
                rotorA_table[23]: idx_in_a = 6'd23;
                rotorA_table[24]: idx_in_a = 6'd24;
                rotorA_table[25]: idx_in_a = 6'd25;
                rotorA_table[26]: idx_in_a = 6'd26;
                rotorA_table[27]: idx_in_a = 6'd27;
                rotorA_table[28]: idx_in_a = 6'd28;
                rotorA_table[29]: idx_in_a = 6'd29;
                rotorA_table[30]: idx_in_a = 6'd30;
                rotorA_table[31]: idx_in_a = 6'd31;
                rotorA_table[32]: idx_in_a = 6'd32;
                rotorA_table[33]: idx_in_a = 6'd33;
                rotorA_table[34]: idx_in_a = 6'd34;
                rotorA_table[35]: idx_in_a = 6'd35;
                rotorA_table[36]: idx_in_a = 6'd36;
                rotorA_table[37]: idx_in_a = 6'd37;
                rotorA_table[38]: idx_in_a = 6'd38;
                rotorA_table[39]: idx_in_a = 6'd39;
                rotorA_table[40]: idx_in_a = 6'd40;
                rotorA_table[41]: idx_in_a = 6'd41;
                rotorA_table[42]: idx_in_a = 6'd42;
                rotorA_table[43]: idx_in_a = 6'd43;
                rotorA_table[44]: idx_in_a = 6'd44;
                rotorA_table[45]: idx_in_a = 6'd45;
                rotorA_table[46]: idx_in_a = 6'd46;
                rotorA_table[47]: idx_in_a = 6'd47;
                rotorA_table[48]: idx_in_a = 6'd48;
                rotorA_table[49]: idx_in_a = 6'd49;
                rotorA_table[50]: idx_in_a = 6'd50;
                rotorA_table[51]: idx_in_a = 6'd51;
                rotorA_table[52]: idx_in_a = 6'd52;
                rotorA_table[53]: idx_in_a = 6'd53;
                rotorA_table[54]: idx_in_a = 6'd54;
                rotorA_table[55]: idx_in_a = 6'd55;
                rotorA_table[56]: idx_in_a = 6'd56;
                rotorA_table[57]: idx_in_a = 6'd57;
                rotorA_table[58]: idx_in_a = 6'd58;
                rotorA_table[59]: idx_in_a = 6'd59;
                rotorA_table[60]: idx_in_a = 6'd60;
                rotorA_table[61]: idx_in_a = 6'd61;
                rotorA_table[62]: idx_in_a = 6'd62;
                rotorA_table[63]: idx_in_a = 6'd63;
                default         : idx_in_a = 6'd0;
            endcase
            code_out_next = idx_in_a;
            code_valid_next = 1'b1;

            // shift rotor A by 1 bit
            last_A = rotorA_table[63];
            for (i = 62; i >= 0; i = i - 1) begin
                rotorA_table_next[i + 1] = rotorA_table[i];
            end
            rotorA_table_next[0] = last_A;

            // shift rotor B by 1 bit conditionally
            if (cnt == 1'b1) begin
                last_B = rotorB_table[63];
                for (i = 62; i >= 0; i = i - 1) begin
                    rotorB_table_next[i + 1] = rotorB_table[i];
                end
                rotorB_table_next[0] = last_B;
            end

            // permutate rotor C according to LSB 2 bit of output
            // $display("%b", rotC_o);

            case ({rotC_o[1], rotC_o[0]})
                2'b00: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc0;
                        rotorC_table_next[i + 1] = tempc1;
                        rotorC_table_next[i + 2] = tempc2;
                        rotorC_table_next[i + 3] = tempc3;
                    end
                end
                2'b01: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc1;
                        rotorC_table_next[i + 1] = tempc0;
                        rotorC_table_next[i + 2] = tempc3;
                        rotorC_table_next[i + 3] = tempc2;
                    end
                end
                2'b10: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc2;
                        rotorC_table_next[i + 1] = tempc3;
                        rotorC_table_next[i + 2] = tempc0;
                        rotorC_table_next[i + 3] = tempc1;
                    end
                end
                2'b11: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc3;
                        rotorC_table_next[i + 1] = tempc2;
                        rotorC_table_next[i + 2] = tempc1;
                        rotorC_table_next[i + 3] = tempc0;
                    end
                end
                default: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc0;
                        rotorC_table_next[i + 1] = tempc1;
                        rotorC_table_next[i + 2] = tempc2;
                        rotorC_table_next[i + 3] = tempc3;
                    end
                end
            endcase

            for (i = 0; i < 64; i = i + 1) begin
                rotorC_temp_box64[i] = rotorC_table_next[i];
            end
            rotorC_table_next[0] = rotorC_temp_box64[41];
            rotorC_table_next[1] = rotorC_temp_box64[56];
            rotorC_table_next[2] = rotorC_temp_box64[61];
            rotorC_table_next[3] = rotorC_temp_box64[29];
            rotorC_table_next[4] = rotorC_temp_box64[00];
            rotorC_table_next[5] = rotorC_temp_box64[26];
            rotorC_table_next[6] = rotorC_temp_box64[28];
            rotorC_table_next[7] = rotorC_temp_box64[63];
            rotorC_table_next[8] = rotorC_temp_box64[34];
            rotorC_table_next[9] = rotorC_temp_box64[19];
            rotorC_table_next[10] = rotorC_temp_box64[36];
            rotorC_table_next[11] = rotorC_temp_box64[46];
            rotorC_table_next[12] = rotorC_temp_box64[23];
            rotorC_table_next[13] = rotorC_temp_box64[54];
            rotorC_table_next[14] = rotorC_temp_box64[44];
            rotorC_table_next[15] = rotorC_temp_box64[7];
            rotorC_table_next[16] = rotorC_temp_box64[43];
            rotorC_table_next[17] = rotorC_temp_box64[01];
            rotorC_table_next[18] = rotorC_temp_box64[42];
            rotorC_table_next[19] = rotorC_temp_box64[5];
            rotorC_table_next[20] = rotorC_temp_box64[40];
            rotorC_table_next[21] = rotorC_temp_box64[22];
            rotorC_table_next[22] = rotorC_temp_box64[6];
            rotorC_table_next[23] = rotorC_temp_box64[33];
            rotorC_table_next[24] = rotorC_temp_box64[21];
            rotorC_table_next[25] = rotorC_temp_box64[58];
            rotorC_table_next[26] = rotorC_temp_box64[13];
            rotorC_table_next[27] = rotorC_temp_box64[51];
            rotorC_table_next[28] = rotorC_temp_box64[53];
            rotorC_table_next[29] = rotorC_temp_box64[24];
            rotorC_table_next[30] = rotorC_temp_box64[37];
            rotorC_table_next[31] = rotorC_temp_box64[32];
            rotorC_table_next[32] = rotorC_temp_box64[31];
            rotorC_table_next[33] = rotorC_temp_box64[11];
            rotorC_table_next[34] = rotorC_temp_box64[47];
            rotorC_table_next[35] = rotorC_temp_box64[25];
            rotorC_table_next[36] = rotorC_temp_box64[48];
            rotorC_table_next[37] = rotorC_temp_box64[2];
            rotorC_table_next[38] = rotorC_temp_box64[10];
            rotorC_table_next[39] = rotorC_temp_box64[9];
            rotorC_table_next[40] = rotorC_temp_box64[4];
            rotorC_table_next[41] = rotorC_temp_box64[52];
            rotorC_table_next[42] = rotorC_temp_box64[55];
            rotorC_table_next[43] = rotorC_temp_box64[17];
            rotorC_table_next[44] = rotorC_temp_box64[8];
            rotorC_table_next[45] = rotorC_temp_box64[62];
            rotorC_table_next[46] = rotorC_temp_box64[16];
            rotorC_table_next[47] = rotorC_temp_box64[50];
            rotorC_table_next[48] = rotorC_temp_box64[38];
            rotorC_table_next[49] = rotorC_temp_box64[14];
            rotorC_table_next[50] = rotorC_temp_box64[30];
            rotorC_table_next[51] = rotorC_temp_box64[27];
            rotorC_table_next[52] = rotorC_temp_box64[57];
            rotorC_table_next[53] = rotorC_temp_box64[18];
            rotorC_table_next[54] = rotorC_temp_box64[60];
            rotorC_table_next[55] = rotorC_temp_box64[15];
            rotorC_table_next[56] = rotorC_temp_box64[49];
            rotorC_table_next[57] = rotorC_temp_box64[59];
            rotorC_table_next[58] = rotorC_temp_box64[20];
            rotorC_table_next[59] = rotorC_temp_box64[12];
            rotorC_table_next[60] = rotorC_temp_box64[39];
            rotorC_table_next[61] = rotorC_temp_box64[3];
            rotorC_table_next[62] = rotorC_temp_box64[35];
            rotorC_table_next[63] = rotorC_temp_box64[45];
            

        end

        else begin    // decrypt
            rotA_o = rotorA_table[code_in_ff];
            rotB_o = rotorB_table[rotA_o];
            rotC_o = rotorC_table[rotB_o];
            ref_o = rotC_o;
            case (ref_o)
                reflector_table[0]: idx_in_ref = 6'd0;
                reflector_table[1]: idx_in_ref = 6'd1;
                reflector_table[2]: idx_in_ref = 6'd2;
                reflector_table[3]: idx_in_ref = 6'd3;
                reflector_table[4]: idx_in_ref = 6'd4;
                reflector_table[5]: idx_in_ref = 6'd5;
                reflector_table[6]: idx_in_ref = 6'd6;
                reflector_table[7]: idx_in_ref = 6'd7;
                reflector_table[8]: idx_in_ref = 6'd8;
                reflector_table[9]: idx_in_ref = 6'd9;
                reflector_table[10]: idx_in_ref = 6'd10;
                reflector_table[11]: idx_in_ref = 6'd11;
                reflector_table[12]: idx_in_ref = 6'd12;
                reflector_table[13]: idx_in_ref = 6'd13;
                reflector_table[14]: idx_in_ref = 6'd14;
                reflector_table[15]: idx_in_ref = 6'd15;
                reflector_table[16]: idx_in_ref = 6'd16;
                reflector_table[17]: idx_in_ref = 6'd17;
                reflector_table[18]: idx_in_ref = 6'd18;
                reflector_table[19]: idx_in_ref = 6'd19;
                reflector_table[20]: idx_in_ref = 6'd20;
                reflector_table[21]: idx_in_ref = 6'd21;
                reflector_table[22]: idx_in_ref = 6'd22;
                reflector_table[23]: idx_in_ref = 6'd23;
                reflector_table[24]: idx_in_ref = 6'd24;
                reflector_table[25]: idx_in_ref = 6'd25;
                reflector_table[26]: idx_in_ref = 6'd26;
                reflector_table[27]: idx_in_ref = 6'd27;
                reflector_table[28]: idx_in_ref = 6'd28;
                reflector_table[29]: idx_in_ref = 6'd29;
                reflector_table[30]: idx_in_ref = 6'd30;
                reflector_table[31]: idx_in_ref = 6'd31;
                reflector_table[32]: idx_in_ref = 6'd32;
                reflector_table[33]: idx_in_ref = 6'd33;
                reflector_table[34]: idx_in_ref = 6'd34;
                reflector_table[35]: idx_in_ref = 6'd35;
                reflector_table[36]: idx_in_ref = 6'd36;
                reflector_table[37]: idx_in_ref = 6'd37;
                reflector_table[38]: idx_in_ref = 6'd38;
                reflector_table[39]: idx_in_ref = 6'd39;
                reflector_table[40]: idx_in_ref = 6'd40;
                reflector_table[41]: idx_in_ref = 6'd41;
                reflector_table[42]: idx_in_ref = 6'd42;
                reflector_table[43]: idx_in_ref = 6'd43;
                reflector_table[44]: idx_in_ref = 6'd44;
                reflector_table[45]: idx_in_ref = 6'd45;
                reflector_table[46]: idx_in_ref = 6'd46;
                reflector_table[47]: idx_in_ref = 6'd47;
                reflector_table[48]: idx_in_ref = 6'd48;
                reflector_table[49]: idx_in_ref = 6'd49;
                reflector_table[50]: idx_in_ref = 6'd50;
                reflector_table[51]: idx_in_ref = 6'd51;
                reflector_table[52]: idx_in_ref = 6'd52;
                reflector_table[53]: idx_in_ref = 6'd53;
                reflector_table[54]: idx_in_ref = 6'd54;
                reflector_table[55]: idx_in_ref = 6'd55;
                reflector_table[56]: idx_in_ref = 6'd56;
                reflector_table[57]: idx_in_ref = 6'd57;
                reflector_table[58]: idx_in_ref = 6'd58;
                reflector_table[59]: idx_in_ref = 6'd59;
                reflector_table[60]: idx_in_ref = 6'd60;
                reflector_table[61]: idx_in_ref = 6'd61;
                reflector_table[62]: idx_in_ref = 6'd62;
                reflector_table[63]: idx_in_ref = 6'd63;
                default            : idx_in_ref = 6'd0;
            endcase
            case (idx_in_ref)
                rotorC_table[0]: idx_in_c = 6'd0;
                rotorC_table[1]: idx_in_c = 6'd1;
                rotorC_table[2]: idx_in_c = 6'd2;
                rotorC_table[3]: idx_in_c = 6'd3;
                rotorC_table[4]: idx_in_c = 6'd4;
                rotorC_table[5]: idx_in_c = 6'd5;
                rotorC_table[6]: idx_in_c = 6'd6;
                rotorC_table[7]: idx_in_c = 6'd7;
                rotorC_table[8]: idx_in_c = 6'd8;
                rotorC_table[9]: idx_in_c = 6'd9;
                rotorC_table[10]: idx_in_c = 6'd10;
                rotorC_table[11]: idx_in_c = 6'd11;
                rotorC_table[12]: idx_in_c = 6'd12;
                rotorC_table[13]: idx_in_c = 6'd13;
                rotorC_table[14]: idx_in_c = 6'd14;
                rotorC_table[15]: idx_in_c = 6'd15;
                rotorC_table[16]: idx_in_c = 6'd16;
                rotorC_table[17]: idx_in_c = 6'd17;
                rotorC_table[18]: idx_in_c = 6'd18;
                rotorC_table[19]: idx_in_c = 6'd19;
                rotorC_table[20]: idx_in_c = 6'd20;
                rotorC_table[21]: idx_in_c = 6'd21;
                rotorC_table[22]: idx_in_c = 6'd22;
                rotorC_table[23]: idx_in_c = 6'd23;
                rotorC_table[24]: idx_in_c = 6'd24;
                rotorC_table[25]: idx_in_c = 6'd25;
                rotorC_table[26]: idx_in_c = 6'd26;
                rotorC_table[27]: idx_in_c = 6'd27;
                rotorC_table[28]: idx_in_c = 6'd28;
                rotorC_table[29]: idx_in_c = 6'd29;
                rotorC_table[30]: idx_in_c = 6'd30;
                rotorC_table[31]: idx_in_c = 6'd31;
                rotorC_table[32]: idx_in_c = 6'd32;
                rotorC_table[33]: idx_in_c = 6'd33;
                rotorC_table[34]: idx_in_c = 6'd34;
                rotorC_table[35]: idx_in_c = 6'd35;
                rotorC_table[36]: idx_in_c = 6'd36;
                rotorC_table[37]: idx_in_c = 6'd37;
                rotorC_table[38]: idx_in_c = 6'd38;
                rotorC_table[39]: idx_in_c = 6'd39;
                rotorC_table[40]: idx_in_c = 6'd40;
                rotorC_table[41]: idx_in_c = 6'd41;
                rotorC_table[42]: idx_in_c = 6'd42;
                rotorC_table[43]: idx_in_c = 6'd43;
                rotorC_table[44]: idx_in_c = 6'd44;
                rotorC_table[45]: idx_in_c = 6'd45;
                rotorC_table[46]: idx_in_c = 6'd46;
                rotorC_table[47]: idx_in_c = 6'd47;
                rotorC_table[48]: idx_in_c = 6'd48;
                rotorC_table[49]: idx_in_c = 6'd49;
                rotorC_table[50]: idx_in_c = 6'd50;
                rotorC_table[51]: idx_in_c = 6'd51;
                rotorC_table[52]: idx_in_c = 6'd52;
                rotorC_table[53]: idx_in_c = 6'd53;
                rotorC_table[54]: idx_in_c = 6'd54;
                rotorC_table[55]: idx_in_c = 6'd55;
                rotorC_table[56]: idx_in_c = 6'd56;
                rotorC_table[57]: idx_in_c = 6'd57;
                rotorC_table[58]: idx_in_c = 6'd58;
                rotorC_table[59]: idx_in_c = 6'd59;
                rotorC_table[60]: idx_in_c = 6'd60;
                rotorC_table[61]: idx_in_c = 6'd61;
                rotorC_table[62]: idx_in_c = 6'd62;
                rotorC_table[63]: idx_in_c = 6'd63;
                default         : idx_in_c = 6'd0;
            endcase
            case (idx_in_c)
                rotorB_table[0]: idx_in_b = 6'd0;
                rotorB_table[1]: idx_in_b = 6'd1;
                rotorB_table[2]: idx_in_b = 6'd2;
                rotorB_table[3]: idx_in_b = 6'd3;
                rotorB_table[4]: idx_in_b = 6'd4;
                rotorB_table[5]: idx_in_b = 6'd5;
                rotorB_table[6]: idx_in_b = 6'd6;
                rotorB_table[7]: idx_in_b = 6'd7;
                rotorB_table[8]: idx_in_b = 6'd8;
                rotorB_table[9]: idx_in_b = 6'd9;
                rotorB_table[10]: idx_in_b = 6'd10;
                rotorB_table[11]: idx_in_b = 6'd11;
                rotorB_table[12]: idx_in_b = 6'd12;
                rotorB_table[13]: idx_in_b = 6'd13;
                rotorB_table[14]: idx_in_b = 6'd14;
                rotorB_table[15]: idx_in_b = 6'd15;
                rotorB_table[16]: idx_in_b = 6'd16;
                rotorB_table[17]: idx_in_b = 6'd17;
                rotorB_table[18]: idx_in_b = 6'd18;
                rotorB_table[19]: idx_in_b = 6'd19;
                rotorB_table[20]: idx_in_b = 6'd20;
                rotorB_table[21]: idx_in_b = 6'd21;
                rotorB_table[22]: idx_in_b = 6'd22;
                rotorB_table[23]: idx_in_b = 6'd23;
                rotorB_table[24]: idx_in_b = 6'd24;
                rotorB_table[25]: idx_in_b = 6'd25;
                rotorB_table[26]: idx_in_b = 6'd26;
                rotorB_table[27]: idx_in_b = 6'd27;
                rotorB_table[28]: idx_in_b = 6'd28;
                rotorB_table[29]: idx_in_b = 6'd29;
                rotorB_table[30]: idx_in_b = 6'd30;
                rotorB_table[31]: idx_in_b = 6'd31;
                rotorB_table[32]: idx_in_b = 6'd32;
                rotorB_table[33]: idx_in_b = 6'd33;
                rotorB_table[34]: idx_in_b = 6'd34;
                rotorB_table[35]: idx_in_b = 6'd35;
                rotorB_table[36]: idx_in_b = 6'd36;
                rotorB_table[37]: idx_in_b = 6'd37;
                rotorB_table[38]: idx_in_b = 6'd38;
                rotorB_table[39]: idx_in_b = 6'd39;
                rotorB_table[40]: idx_in_b = 6'd40;
                rotorB_table[41]: idx_in_b = 6'd41;
                rotorB_table[42]: idx_in_b = 6'd42;
                rotorB_table[43]: idx_in_b = 6'd43;
                rotorB_table[44]: idx_in_b = 6'd44;
                rotorB_table[45]: idx_in_b = 6'd45;
                rotorB_table[46]: idx_in_b = 6'd46;
                rotorB_table[47]: idx_in_b = 6'd47;
                rotorB_table[48]: idx_in_b = 6'd48;
                rotorB_table[49]: idx_in_b = 6'd49;
                rotorB_table[50]: idx_in_b = 6'd50;
                rotorB_table[51]: idx_in_b = 6'd51;
                rotorB_table[52]: idx_in_b = 6'd52;
                rotorB_table[53]: idx_in_b = 6'd53;
                rotorB_table[54]: idx_in_b = 6'd54;
                rotorB_table[55]: idx_in_b = 6'd55;
                rotorB_table[56]: idx_in_b = 6'd56;
                rotorB_table[57]: idx_in_b = 6'd57;
                rotorB_table[58]: idx_in_b = 6'd58;
                rotorB_table[59]: idx_in_b = 6'd59;
                rotorB_table[60]: idx_in_b = 6'd60;
                rotorB_table[61]: idx_in_b = 6'd61;
                rotorB_table[62]: idx_in_b = 6'd62;
                rotorB_table[63]: idx_in_b = 6'd63;
                default         : idx_in_b = 6'd0;
            endcase
            case (idx_in_b)
                rotorA_table[0]: idx_in_a = 6'd0;
                rotorA_table[1]: idx_in_a = 6'd1;
                rotorA_table[2]: idx_in_a = 6'd2;
                rotorA_table[3]: idx_in_a = 6'd3;
                rotorA_table[4]: idx_in_a = 6'd4;
                rotorA_table[5]: idx_in_a = 6'd5;
                rotorA_table[6]: idx_in_a = 6'd6;
                rotorA_table[7]: idx_in_a = 6'd7;
                rotorA_table[8]: idx_in_a = 6'd8;
                rotorA_table[9]: idx_in_a = 6'd9;
                rotorA_table[10]: idx_in_a = 6'd10;
                rotorA_table[11]: idx_in_a = 6'd11;
                rotorA_table[12]: idx_in_a = 6'd12;
                rotorA_table[13]: idx_in_a = 6'd13;
                rotorA_table[14]: idx_in_a = 6'd14;
                rotorA_table[15]: idx_in_a = 6'd15;
                rotorA_table[16]: idx_in_a = 6'd16;
                rotorA_table[17]: idx_in_a = 6'd17;
                rotorA_table[18]: idx_in_a = 6'd18;
                rotorA_table[19]: idx_in_a = 6'd19;
                rotorA_table[20]: idx_in_a = 6'd20;
                rotorA_table[21]: idx_in_a = 6'd21;
                rotorA_table[22]: idx_in_a = 6'd22;
                rotorA_table[23]: idx_in_a = 6'd23;
                rotorA_table[24]: idx_in_a = 6'd24;
                rotorA_table[25]: idx_in_a = 6'd25;
                rotorA_table[26]: idx_in_a = 6'd26;
                rotorA_table[27]: idx_in_a = 6'd27;
                rotorA_table[28]: idx_in_a = 6'd28;
                rotorA_table[29]: idx_in_a = 6'd29;
                rotorA_table[30]: idx_in_a = 6'd30;
                rotorA_table[31]: idx_in_a = 6'd31;
                rotorA_table[32]: idx_in_a = 6'd32;
                rotorA_table[33]: idx_in_a = 6'd33;
                rotorA_table[34]: idx_in_a = 6'd34;
                rotorA_table[35]: idx_in_a = 6'd35;
                rotorA_table[36]: idx_in_a = 6'd36;
                rotorA_table[37]: idx_in_a = 6'd37;
                rotorA_table[38]: idx_in_a = 6'd38;
                rotorA_table[39]: idx_in_a = 6'd39;
                rotorA_table[40]: idx_in_a = 6'd40;
                rotorA_table[41]: idx_in_a = 6'd41;
                rotorA_table[42]: idx_in_a = 6'd42;
                rotorA_table[43]: idx_in_a = 6'd43;
                rotorA_table[44]: idx_in_a = 6'd44;
                rotorA_table[45]: idx_in_a = 6'd45;
                rotorA_table[46]: idx_in_a = 6'd46;
                rotorA_table[47]: idx_in_a = 6'd47;
                rotorA_table[48]: idx_in_a = 6'd48;
                rotorA_table[49]: idx_in_a = 6'd49;
                rotorA_table[50]: idx_in_a = 6'd50;
                rotorA_table[51]: idx_in_a = 6'd51;
                rotorA_table[52]: idx_in_a = 6'd52;
                rotorA_table[53]: idx_in_a = 6'd53;
                rotorA_table[54]: idx_in_a = 6'd54;
                rotorA_table[55]: idx_in_a = 6'd55;
                rotorA_table[56]: idx_in_a = 6'd56;
                rotorA_table[57]: idx_in_a = 6'd57;
                rotorA_table[58]: idx_in_a = 6'd58;
                rotorA_table[59]: idx_in_a = 6'd59;
                rotorA_table[60]: idx_in_a = 6'd60;
                rotorA_table[61]: idx_in_a = 6'd61;
                rotorA_table[62]: idx_in_a = 6'd62;
                rotorA_table[63]: idx_in_a = 6'd63;
                default         : idx_in_a = 6'd0;
            endcase
            code_out_next = idx_in_a;
            code_valid_next = 1'b1;

            // shift rotor A by 1 bit
            last_A = rotorA_table[63];
            for (i = 62; i >= 0; i = i - 1) begin
                rotorA_table_next[i + 1] = rotorA_table[i];
            end
            rotorA_table_next[0] = last_A;

            // shift rotor B by 1 bit conditionally
            if (cnt == 1'b1) begin
                last_B = rotorB_table[63];
                for (i = 62; i >= 0; i = i - 1) begin
                    rotorB_table_next[i + 1] = rotorB_table[i];
                end
                rotorB_table_next[0] = last_B;
            end

            // permutate rotor C according to LSB 2 bit of output
            // $display("%b", rotC_o);

            case ({idx_in_ref[1], idx_in_ref[0]})
                2'b00: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc0;
                        rotorC_table_next[i + 1] = tempc1;
                        rotorC_table_next[i + 2] = tempc2;
                        rotorC_table_next[i + 3] = tempc3;
                    end
                end
                2'b01: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc1;
                        rotorC_table_next[i + 1] = tempc0;
                        rotorC_table_next[i + 2] = tempc3;
                        rotorC_table_next[i + 3] = tempc2;
                    end
                end
                2'b10: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc2;
                        rotorC_table_next[i + 1] = tempc3;
                        rotorC_table_next[i + 2] = tempc0;
                        rotorC_table_next[i + 3] = tempc1;
                    end
                end
                2'b11: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc3;
                        rotorC_table_next[i + 1] = tempc2;
                        rotorC_table_next[i + 2] = tempc1;
                        rotorC_table_next[i + 3] = tempc0;
                    end
                end
                default: begin
                    for (i = 0; i <= 60; i = i + 4) begin
                        tempc0 = rotorC_table[i];
                        tempc1 = rotorC_table[i + 1];
                        tempc2 = rotorC_table[i + 2];
                        tempc3 = rotorC_table[i + 3];
                        rotorC_table_next[i] = tempc0;
                        rotorC_table_next[i + 1] = tempc1;
                        rotorC_table_next[i + 2] = tempc2;
                        rotorC_table_next[i + 3] = tempc3;
                    end
                end
            endcase

            for (i = 0; i < 64; i = i + 1) begin
                rotorC_temp_box64[i] = rotorC_table_next[i];
            end
            rotorC_table_next[0] = rotorC_temp_box64[41];
            rotorC_table_next[1] = rotorC_temp_box64[56];
            rotorC_table_next[2] = rotorC_temp_box64[61];
            rotorC_table_next[3] = rotorC_temp_box64[29];
            rotorC_table_next[4] = rotorC_temp_box64[00];
            rotorC_table_next[5] = rotorC_temp_box64[26];
            rotorC_table_next[6] = rotorC_temp_box64[28];
            rotorC_table_next[7] = rotorC_temp_box64[63];
            rotorC_table_next[8] = rotorC_temp_box64[34];
            rotorC_table_next[9] = rotorC_temp_box64[19];
            rotorC_table_next[10] = rotorC_temp_box64[36];
            rotorC_table_next[11] = rotorC_temp_box64[46];
            rotorC_table_next[12] = rotorC_temp_box64[23];
            rotorC_table_next[13] = rotorC_temp_box64[54];
            rotorC_table_next[14] = rotorC_temp_box64[44];
            rotorC_table_next[15] = rotorC_temp_box64[7];
            rotorC_table_next[16] = rotorC_temp_box64[43];
            rotorC_table_next[17] = rotorC_temp_box64[01];
            rotorC_table_next[18] = rotorC_temp_box64[42];
            rotorC_table_next[19] = rotorC_temp_box64[5];
            rotorC_table_next[20] = rotorC_temp_box64[40];
            rotorC_table_next[21] = rotorC_temp_box64[22];
            rotorC_table_next[22] = rotorC_temp_box64[6];
            rotorC_table_next[23] = rotorC_temp_box64[33];
            rotorC_table_next[24] = rotorC_temp_box64[21];
            rotorC_table_next[25] = rotorC_temp_box64[58];
            rotorC_table_next[26] = rotorC_temp_box64[13];
            rotorC_table_next[27] = rotorC_temp_box64[51];
            rotorC_table_next[28] = rotorC_temp_box64[53];
            rotorC_table_next[29] = rotorC_temp_box64[24];
            rotorC_table_next[30] = rotorC_temp_box64[37];
            rotorC_table_next[31] = rotorC_temp_box64[32];
            rotorC_table_next[32] = rotorC_temp_box64[31];
            rotorC_table_next[33] = rotorC_temp_box64[11];
            rotorC_table_next[34] = rotorC_temp_box64[47];
            rotorC_table_next[35] = rotorC_temp_box64[25];
            rotorC_table_next[36] = rotorC_temp_box64[48];
            rotorC_table_next[37] = rotorC_temp_box64[2];
            rotorC_table_next[38] = rotorC_temp_box64[10];
            rotorC_table_next[39] = rotorC_temp_box64[9];
            rotorC_table_next[40] = rotorC_temp_box64[4];
            rotorC_table_next[41] = rotorC_temp_box64[52];
            rotorC_table_next[42] = rotorC_temp_box64[55];
            rotorC_table_next[43] = rotorC_temp_box64[17];
            rotorC_table_next[44] = rotorC_temp_box64[8];
            rotorC_table_next[45] = rotorC_temp_box64[62];
            rotorC_table_next[46] = rotorC_temp_box64[16];
            rotorC_table_next[47] = rotorC_temp_box64[50];
            rotorC_table_next[48] = rotorC_temp_box64[38];
            rotorC_table_next[49] = rotorC_temp_box64[14];
            rotorC_table_next[50] = rotorC_temp_box64[30];
            rotorC_table_next[51] = rotorC_temp_box64[27];
            rotorC_table_next[52] = rotorC_temp_box64[57];
            rotorC_table_next[53] = rotorC_temp_box64[18];
            rotorC_table_next[54] = rotorC_temp_box64[60];
            rotorC_table_next[55] = rotorC_temp_box64[15];
            rotorC_table_next[56] = rotorC_temp_box64[49];
            rotorC_table_next[57] = rotorC_temp_box64[59];
            rotorC_table_next[58] = rotorC_temp_box64[20];
            rotorC_table_next[59] = rotorC_temp_box64[12];
            rotorC_table_next[60] = rotorC_temp_box64[39];
            rotorC_table_next[61] = rotorC_temp_box64[3];
            rotorC_table_next[62] = rotorC_temp_box64[35];
            rotorC_table_next[63] = rotorC_temp_box64[45];
        end
    end

    

end


always @(posedge clk) begin
    if (~srstn) begin
        for (i = 0; i < 64; i = i + 1) begin
            rotorA_table[i] <= rotorA_table[i];
            rotorB_table[i] <= rotorB_table[i];
            rotorC_table[i] <= rotorC_table[i];
        end
        code_valid <= 1'b0;
        code_out <= 6'b0;
        state <= IDLE;
        cnt <= 1'b0;
        code_in_ff <= 6'b0;
        load_ff <= 1'b0;
        encrypt_ff <= 1'b0;
        crypt_mode_ff <= 1'b0;
        load_idx_ff <= 8'b0;
    end
    else begin
        for (i = 0; i < 64; i = i + 1) begin
            rotorA_table[i] <= rotorA_table_next[i];
            rotorB_table[i] <= rotorB_table_next[i];
            rotorC_table[i] <= rotorC_table_next[i];
        end
        code_valid <= code_valid_next;
        code_out <= code_out_next;
        state <= n_state;
        cnt <= cnt_next;
        code_in_ff <= code_in;
        load_ff <= load;
        encrypt_ff <= encrypt;
        crypt_mode_ff <= crypt_mode;
        load_idx_ff <= load_idx;
    end
end



endmodule

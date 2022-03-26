task display_enigma_code;

input [8*FILENAME_LENGTH-1:0] filename;

integer i;

reg [6-1:0] in_dat[0:TEXT_LENGTH-1];
reg [7:0] ascii_code;

begin
  $readmemh(filename,in_dat);

  $write("\n\n");

  for(i=0;i<TEXT_LENGTH;i=i+1) begin
    EnigmaCodetoASCII(in_dat[i],ascii_code);
    $write("%s",ascii_code);
  end

  $write("\n\n");

end
endtask



task EnigmaCodetoASCII;
input [6-1:0] eingmacode;
output [8-1:0] ascii_out;
reg [8-1:0] ascii_out;

begin
  case(eingmacode)
    6'h00: ascii_out = 8'h61; //'a'
    6'h01: ascii_out = 8'h62; //'b'
    6'h02: ascii_out = 8'h63; //'c'
    6'h03: ascii_out = 8'h64; //'d'
    6'h04: ascii_out = 8'h65; //'e'
    6'h05: ascii_out = 8'h66; //'f'
    6'h06: ascii_out = 8'h67; //'g'
    6'h07: ascii_out = 8'h68; //'h'
    6'h08: ascii_out = 8'h69; //'i'
    6'h09: ascii_out = 8'h6a; //'j'
    6'h0a: ascii_out = 8'h6b; //'k'
    6'h0b: ascii_out = 8'h6c; //'l'
    6'h0c: ascii_out = 8'h6d; //'m'
    6'h0d: ascii_out = 8'h6e; //'n'
    6'h0e: ascii_out = 8'h6f; //'o'
    6'h0f: ascii_out = 8'h70; //'p'
    6'h10: ascii_out = 8'h71; //'q'
    6'h11: ascii_out = 8'h72; //'r'
    6'h12: ascii_out = 8'h73; //'s'
    6'h13: ascii_out = 8'h74; //'t'
    6'h14: ascii_out = 8'h75; //'u'
    6'h15: ascii_out = 8'h76; //'v'
    6'h16: ascii_out = 8'h77; //'w'
    6'h17: ascii_out = 8'h78; //'x'
    6'h18: ascii_out = 8'h79; //'y'
    6'h19: ascii_out = 8'h7a; //'z'
    6'h1a: ascii_out = 8'h20; //' '
    6'h1b: ascii_out = 8'h21; //'!'
    6'h1c: ascii_out = 8'h2c; //','
    6'h1d: ascii_out = 8'h2d; //'-'
    6'h1e: ascii_out = 8'h2e; //'.'
    6'h1f: ascii_out = 8'h0a; //'\n' (change line)
    6'h20: ascii_out = 8'h41; //'A'
    6'h21: ascii_out = 8'h42; //'B'
    6'h22: ascii_out = 8'h43; //'C'
    6'h23: ascii_out = 8'h44; //'D'
    6'h24: ascii_out = 8'h45; //'E'
    6'h25: ascii_out = 8'h46; //'F'
    6'h26: ascii_out = 8'h47; //'G'
    6'h27: ascii_out = 8'h48; //'H'
    6'h28: ascii_out = 8'h49; //'I'
    6'h29: ascii_out = 8'h4a; //'J'
    6'h2a: ascii_out = 8'h4b; //'K'
    6'h2b: ascii_out = 8'h4c; //'L'
    6'h2c: ascii_out = 8'h4d; //'M'
    6'h2d: ascii_out = 8'h4e; //'N'
    6'h2e: ascii_out = 8'h4f; //'O'
    6'h2f: ascii_out = 8'h50; //'P'
    6'h30: ascii_out = 8'h51; //'Q'
    6'h31: ascii_out = 8'h52; //'R'
    6'h32: ascii_out = 8'h53; //'S'
    6'h33: ascii_out = 8'h54; //'T'
    6'h34: ascii_out = 8'h55; //'U'
    6'h35: ascii_out = 8'h56; //'V'
    6'h36: ascii_out = 8'h57; //'W'
    6'h37: ascii_out = 8'h58; //'X'
    6'h38: ascii_out = 8'h59; //'Y'
    6'h39: ascii_out = 8'h5a; //'Z'
    6'h3a: ascii_out = 8'h3a; //':'
    6'h3b: ascii_out = 8'h23; //'#'
    6'h3c: ascii_out = 8'h3b; //';'
    6'h3d: ascii_out = 8'h5f; //'_'
    6'h3e: ascii_out = 8'h2b; //'+'
    6'h3f: ascii_out = 8'h26; //'&'
  endcase
end
endtask





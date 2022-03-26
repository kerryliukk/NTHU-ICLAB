
module show_enigma_code;

parameter FILENAME_LENGTH = 20;

`ifdef PLAINTEXT1
  localparam TEXT_LENGTH = 24;
`elsif CIPHERTEXT2
  localparam TEXT_LENGTH = 112;
`else
  localparam TEXT_LENGTH = 122836;

`endif

`include "display_enigma_code.v"

initial begin
`ifdef PLAINTEXT1
  display_enigma_code("./pat/plaintext1.dat");
`elsif CIPHERTEXT2
  display_enigma_code("./pat/ciphertext2.dat");
`else
  display_enigma_code("./pat/ciphertext3.dat");
`endif 

 #10 $finish;

end

endmodule

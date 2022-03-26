#######################################################################################
## Function:    Verify the correctness of your rtl(enigma_part1.v).
## Testbench:   test_enigma_part1.v 
## RTL code:    enigma_part1.v (or others if any)
## Mode:        Encryption 
## Input pattern:     plaintext1.dat
## Golden pattern:    ciphertext1.dat

## Note: Please compare your result with the golden pattern in the testbench.

## Command:   $ncverilog -f sim1_en.f  
##            (TA will check your simulation result by using this command.)  
#######################################################################################

# example (can be modified by your preference)
test_enigma_part1.v      # testbench
../hdl/enigma_part1.v    # rtl code  
+access+r                # set this option to dump waveform (optional)

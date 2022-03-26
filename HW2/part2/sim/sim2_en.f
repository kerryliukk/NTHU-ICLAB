###################################################################################################
## Function:    Verify the correctness of your rtl(enigma_part2.v) and tb(test_enigma_part2.v).
## Testbench:   test_enigma_part2.v 
## RTL code:    enigma_part2.v (or others if any)

## Mode:       Encrption
## Input pattern:     plaintext1.dat
## Golden pattern:    ciphertext1.dat

## Note: Please compare your result with the golden pattern in the testbench.

## Command:   $ncverilog -f sim2_en.f  
##            (TA will check your simulation result by using this command.)  
###################################################################################################

# example (can be modified by your preference)
test_enigma_part2.v      # testbench
../hdl/enigma_part2.v    # rtl code  
+define+EN               # set operating mode (optional) 
+access+r                # set this option to dump waveform (optional)




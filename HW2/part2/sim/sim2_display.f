###################################################################################################
## Function:    Decrypt and save the secret data. 
## Testbench:   test_enigma_display.v 
## RTL code:    enigma_part2.v (or others if any)

## Mode:        Decryption
## Input pattern:     ciphertext2.dat and ciphertext3.dat
## Golden pattern:    None (You could recognize the decrypted data if your Enigma is correct.)

## Note1: Please save the decrypted data into .dat files in ASCII format!
##        (named as plaintext2_ascii.dat and plaintext3_ascii.dat)
          
## Note2: You can refer to show_enigma_code.v and display_enigma_code.v, knowing how to display 
##        plaintext in ASCII format.

## Command:   $ncverilog -f sim2_display.f  
##            (TA will check your simulation result by using this command.)  
###################################################################################################

# example (can be modified by your preference)
test_enigma_display.v      # testbench
../hdl/enigma_part2.v    # rtl code  
+access+r                # set this option to dump waveform (optional)

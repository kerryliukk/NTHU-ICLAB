# set your TOPLEVEL here
set TOPLEVEL "top_pipe"

# change your timing constraint here
# 4*0.8=3.2 (20% timing margin for 250MHz clock)
set TEST_CYCLE 3.2

source -echo -verbose 0_readfile.tcl 
source -echo -verbose 1_setting.tcl 
source -echo -verbose 2_compile.tcl 
source -echo -verbose 3_report.tcl 

exit

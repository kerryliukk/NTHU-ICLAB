
#modify the timing constraint here (originally with 5ns)
set TEST_CYCLE 10

set TOPLEVEL "my_div"

source -echo -verbose 0_readfile.tcl 
source -echo -verbose 1_setting.tcl 
source -echo -verbose 2_compile.tcl
source -echo -verbose 3_report.tcl

exit

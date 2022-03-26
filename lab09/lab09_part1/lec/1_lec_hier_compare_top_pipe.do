
//hierarchical compare
write hier_compare dofile hier.do -prepend_string "analyze multiplier -cdp_info; analyze datapath -merge -share -effort medium -verbose" \
-append_string "analyze abort -compare" -replace

//dofile hier.do //static 

run hier_compare hier.do


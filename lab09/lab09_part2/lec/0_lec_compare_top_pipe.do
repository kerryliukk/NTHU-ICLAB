
//LEC mode

set system mode lec
map key point

analyze multiplier -cdp_info
analyze datapath -merge -share -effort medium -verbose
add compare point -all
compare

analyze abort -compare

report unmap point -notmapped 
usage

report compare data -nonequivalent



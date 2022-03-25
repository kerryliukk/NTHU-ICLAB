#!/bin/sh
if [ -r "/usr/cadtool/SAED32_EDK/lib/stdcell_hvt/db_nldm/saed32hvt_ss0p95v125c.db" ]
then
    echo "Check Synthesis library OK !"
    if [ -r "/usr/cadtool/cad/synopsys/SAED32_EDK/lib/stdcell_hvt/milkyway" ]
    then 
      echo "Check APR library OK !"
        if [ -x "/usr/cad/synopsys/synthesis/cur/amd64/syn/bin/dc_shell" ]
        then 
          echo "Check Tool OK !"
        else
          echo "Permission denied, ask TA for help!"
    fi  
    else
      echo "Permission denied, ask TA for help!"
    fi  
else
    echo "Permission denied, ask TA for help!"
fi
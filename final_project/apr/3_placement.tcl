report_power
set_optimize_pre_cts_power_options
set_separate_process_options -placement false
identify_clock_gating
place_opt -power
report_power
report_timing
derive_pg_connection -power_net {VDD} -ground_net {VSS} -power_pin {VDD} -ground_pin {VSS}
save_mw_cel CHIP
save_mw_cel -as 3_placement
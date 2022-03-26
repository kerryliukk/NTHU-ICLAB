read_pin_pad_physical_constraints ../pre_layout/design_data/io_pin.tdf
# 10.5 = {1 + 4 + 0.5 + 4 + 1}
#   {offset + ring + space + ring + offset}
create_floorplan -core_utilization 0.8 -flip_first_row -left_io2core 10.5 -bottom_io2core 10.5 -right_io2core 10.5 -top_io2core 10.5
identify_clock_gating
report_clock_gating
create_fp_placement -timing_driven
set_zero_interconnect_delay_mode true
report_timing
set_zero_interconnect_delay_mode false
create_fp_placement -congestion_driven
create_fp_placement -congestion_driven -incremental all
save_mw_cel CHIP
save_mw_cel -as 1_floorplan

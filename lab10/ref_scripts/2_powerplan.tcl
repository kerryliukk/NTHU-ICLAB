set power_cg_auto_identify true
create_rectangular_rings  -nets  {VDD VSS}  -left_offset 1 -left_segment_layer M8 -left_segment_width 4 -right_offset 1 -right_segment_layer M8 -right_segment_width 4 -bottom_offset 1 -bottom_segment_layer M9 -bottom_segment_width 4 -top_offset 1 -top_segment_layer M9 -top_segment_width 4
set_preroute_drc_strategy -use_fat_via -min_layer M1 -max_layer M9
preroute_standard_cells -extend_for_multiple_connections  -extension_gap 20 -connect horizontal  -remove_floating_pieces  -do_not_route_over_macros  -fill_empty_rows  -port_filter_mode off -cell_master_filter_mode off -cell_instance_filter_mode off -voltage_area_filter_mode off -route_type {P/G Std. Cell Pin Conn}
set_fp_rail_constraints -add_layer  -layer M5 -direction horizontal -max_strap 128 -min_strap 2 -max_width 0.5 -min_width 0.5 -spacing minimum
set_fp_rail_constraints -add_layer  -layer M4 -direction vertical -max_strap 128 -min_strap 2 -max_width 0.5 -min_width 0.5 -spacing minimum
set_fp_rail_constraints  -skip_ring -extend_strap core_ring
synthesize_fp_rail  -nets {VDD VSS} -voltage_supply 1.05 -synthesize_power_plan -synthesize_power_pads -analyze_power -power_budget 10 -use_strap_ends_as_pads -create_virtual_rail M1
report_power
commit_fp_rail
set_pnet_options -partial "M4 M5"
create_fp_placement -incremental all
save_mw_cel CHIP
save_mw_cel -as 2_powerplan

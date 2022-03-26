verify_lvs -ignore_floating_port
source -echo ../addCoreFiller.tcl
save_mw_cel CHIP
save_mw_cel -as 6_corefiller
set_write_stream_options -map_layer /usr/cadtool/cad/synopsys/SAED32_EDK/tech/milkyway/saed32nm_1p9m_gdsout_mw.map -child_depth 20 -flatten_via
verify_lvs -ignore_floating_port
write_stream -format gds -lib_name  CHIP -cells {6_corefiller } ../post_layout/CHIP.gds
write_verilog -diode_ports -wire_declaration -keep_backslash_before_hiersep  -no_physical_only_cells -supply_statement none ../post_layout/CHIP_layout.v
write_sdf -version 1.0 -context verilog ../post_layout/CHIP_layout.sdf
write_sdc ../post_layout/CHIP_layout.sdc -version 2.1
extract_rc
write_parasitics -output ../post_layout/CHIP_layout -format SPEF -compress

###################################################################

# Created by write_sdc on Thu Nov 18 00:10:01 2021

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
set_operating_conditions ss0p95v125c -library saed32hvt_ss0p95v125c
set_wire_load_mode enclosed
set_max_fanout 1.64 [current_design]
set_wire_load_selection_group predcaps
set_max_area 0
set_ideal_network [get_ports clk]
create_clock [get_ports clk]  -period 10  -waveform {0 5}
set_input_delay -clock clk  1  [get_ports {dividend[15]}]
set_input_delay -clock clk  1  [get_ports {dividend[14]}]
set_input_delay -clock clk  1  [get_ports {dividend[13]}]
set_input_delay -clock clk  1  [get_ports {dividend[12]}]
set_input_delay -clock clk  1  [get_ports {dividend[11]}]
set_input_delay -clock clk  1  [get_ports {dividend[10]}]
set_input_delay -clock clk  1  [get_ports {dividend[9]}]
set_input_delay -clock clk  1  [get_ports {dividend[8]}]
set_input_delay -clock clk  1  [get_ports {dividend[7]}]
set_input_delay -clock clk  1  [get_ports {dividend[6]}]
set_input_delay -clock clk  1  [get_ports {dividend[5]}]
set_input_delay -clock clk  1  [get_ports {dividend[4]}]
set_input_delay -clock clk  1  [get_ports {dividend[3]}]
set_input_delay -clock clk  1  [get_ports {dividend[2]}]
set_input_delay -clock clk  1  [get_ports {dividend[1]}]
set_input_delay -clock clk  1  [get_ports {dividend[0]}]
set_input_delay -clock clk  1  [get_ports {divisor[4]}]
set_input_delay -clock clk  1  [get_ports {divisor[3]}]
set_input_delay -clock clk  1  [get_ports {divisor[2]}]
set_input_delay -clock clk  1  [get_ports {divisor[1]}]
set_input_delay -clock clk  1  [get_ports {divisor[0]}]
set_output_delay -clock clk  1  [get_ports {quotient[15]}]
set_output_delay -clock clk  1  [get_ports {quotient[14]}]
set_output_delay -clock clk  1  [get_ports {quotient[13]}]
set_output_delay -clock clk  1  [get_ports {quotient[12]}]
set_output_delay -clock clk  1  [get_ports {quotient[11]}]
set_output_delay -clock clk  1  [get_ports {quotient[10]}]
set_output_delay -clock clk  1  [get_ports {quotient[9]}]
set_output_delay -clock clk  1  [get_ports {quotient[8]}]
set_output_delay -clock clk  1  [get_ports {quotient[7]}]
set_output_delay -clock clk  1  [get_ports {quotient[6]}]
set_output_delay -clock clk  1  [get_ports {quotient[5]}]
set_output_delay -clock clk  1  [get_ports {quotient[4]}]
set_output_delay -clock clk  1  [get_ports {quotient[3]}]
set_output_delay -clock clk  1  [get_ports {quotient[2]}]
set_output_delay -clock clk  1  [get_ports {quotient[1]}]
set_output_delay -clock clk  1  [get_ports {quotient[0]}]

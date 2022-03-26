# Setting Design and I/O Environment
set_operating_conditions -library saed32hvt_ss0p95v125c ss0p95v125c
set_driving_cell -library saed32io_wb_ss0p95v125c_2p25v -lib_cell I1025_EW -pin {DOUT} [all_inputs]	
set_load [load_of "saed32io_wb_ss0p95v125c_2p25v/D4I1025_EW/DIN"] [all_outputs]
#D4I1025 capacitance => same as "set_load  26.238159   [all_outputs]"

# Setting wireload model
set auto_wire_load_selection area_reselect
set_wire_load_mode enclosed
set_wire_load_selection_group predcaps

# Setting Timing Constraints
###  ceate your clock here
create_clock -name clk -period $TEST_CYCLE  [get_ports clk]
###  set clock constrain
set_ideal_network       [get_ports clk]
set_dont_touch_network  [all_clocks]

# I/O delay should depend on the real enironment. Here only shows an example of setting
set_input_delay  2  -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1  -clock clk [all_outputs]

# Setting DRC Constraint
# Defensive setting: smallest fanout_load 0.041 and WLM max fanout # 20 => 0.041*20 = 0.82
# max_transition and max_capacitance are given in the cell library
set_max_fanout 0.82 $TOPLEVEL

# Area Constraint
set_max_area   0

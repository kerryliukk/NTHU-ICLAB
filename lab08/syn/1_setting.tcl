# Setting Design and I/O Environment
set_operating_conditions -library slow_vdd1v2 PVT_1P08V_125C
# Assume outputs go to DFF and inputs also come from DFF
set_driving_cell -library slow_vdd1v2 -lib_cell DFFHQX1 -pin {Q} [all_inputs]	
set_load [load_of "slow_vdd1v2/DFFHQX1/D"] [all_outputs]

# Setting wireload model
set_wire_load_mode enclosed
set_wire_load_model -name "Large" $TOPLEVEL

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
# Defensive setting: default fanout_load 1.0 and our target max fanout # 20 => 1.0*20 = 20.0
# max_transition and max_capacitance are given in the cell library
set_max_fanout 20.0 $TOPLEVEL

# Area Constraint
set_max_area   0

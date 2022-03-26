###################################################################

# Created by write_sdc on Thu Mar 27 18:52:24 2014

###################################################################
set sdc_version 1.9

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
set_operating_conditions -max ss0p95v125c -min ff1p16vn40c
#set_wire_load_mode enclosed
#set_max_fanout 0.82 [current_design]
#set_max_area 0
#set_wire_load_selection_group predcaps
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports clk]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports rst_n]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports boot_up]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[7]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[6]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[5]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[4]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[3]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[2]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[1]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_addr[0]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[31]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[30]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[29]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[28]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[27]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[26]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[25]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[24]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[23]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[22]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[21]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[20]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[19]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[18]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[17]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[16]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[15]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[14]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[13]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[12]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[11]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[10]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[9]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[8]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[7]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[6]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[5]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[4]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[3]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[2]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[1]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports {boot_datai[0]}]
set_driving_cell -lib_cell I1025_EW -library saed32io_wb_ss0p95v125c_2p25v     \
-pin DOUT [get_ports boot_web]
set_load -pin_load 21.5653 [get_ports peri_web]
set_load -pin_load 21.5653 [get_ports {peri_addr[15]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[14]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[13]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[12]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[11]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[10]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[9]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[8]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[7]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[6]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[5]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[4]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[3]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[2]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[1]}]
set_load -pin_load 21.5653 [get_ports {peri_addr[0]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[15]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[14]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[13]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[12]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[11]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[10]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[9]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[8]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[7]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[6]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[5]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[4]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[3]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[2]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[1]}]
set_load -pin_load 21.5653 [get_ports {peri_datao[0]}]
set_ideal_network [get_ports clk]
create_clock [get_ports clk]  -period 3.8  -waveform {0 1.9}
set_input_delay -clock clk  2  [get_ports rst_n]
set_input_delay -clock clk  2  [get_ports boot_up]
set_input_delay -clock clk  2  [get_ports {boot_addr[7]}]
set_input_delay -clock clk  2  [get_ports {boot_addr[6]}]
set_input_delay -clock clk  2  [get_ports {boot_addr[5]}]
set_input_delay -clock clk  2  [get_ports {boot_addr[4]}]
set_input_delay -clock clk  2  [get_ports {boot_addr[3]}]
set_input_delay -clock clk  2  [get_ports {boot_addr[2]}]
set_input_delay -clock clk  2  [get_ports {boot_addr[1]}]
set_input_delay -clock clk  2  [get_ports {boot_addr[0]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[31]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[30]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[29]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[28]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[27]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[26]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[25]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[24]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[23]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[22]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[21]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[20]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[19]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[18]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[17]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[16]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[15]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[14]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[13]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[12]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[11]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[10]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[9]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[8]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[7]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[6]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[5]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[4]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[3]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[2]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[1]}]
set_input_delay -clock clk  2  [get_ports {boot_datai[0]}]
set_input_delay -clock clk  2  [get_ports boot_web]
set_output_delay -clock clk  1  [get_ports peri_web]
set_output_delay -clock clk  1  [get_ports {peri_addr[15]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[14]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[13]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[12]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[11]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[10]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[9]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[8]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[7]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[6]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[5]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[4]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[3]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[2]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[1]}]
set_output_delay -clock clk  1  [get_ports {peri_addr[0]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[15]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[14]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[13]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[12]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[11]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[10]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[9]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[8]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[7]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[6]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[5]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[4]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[3]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[2]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[1]}]
set_output_delay -clock clk  1  [get_ports {peri_datao[0]}]

# read file
read_file -type verilog Conv1_module.v
read_file -type verilog Conv2_module.v
read_file -type verilog Conv3_module.v
read_file -type verilog Unshuffle_module.v
read_file -type verilog Convnet_top.v
read_file -type verilog FSM.v

# goal setup (lint_rtl)
current_goal lint/lint_rtl -alltop

# run goal 
run_goal

# create a report file and write report message to the file
capture spyglass_Convnet.rpt {write_report moresimple}

# setup another goal
current_goal lint/lint_turbo_rtl -alltop

# run goal 
run_goal 

# append the report message to the same file created above 
capture -append spyglass_Convnet.rpt {write_report moresimple}



current_goal lint/lint_functional_rtl -alltop
run_goal
capture -append spyglass_Convnet.rpt {write_report moresimple}

current_goal lint/lint_abstract -alltop
run_goal
capture -append spyglass_Convnet.rpt {write_report moresimple}

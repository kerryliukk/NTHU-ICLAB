# read file
read_file -type verilog top.v
read_file -type verilog sqrt.v
read_file -type verilog MUX.v
read_file -type verilog median.v
read_file -type verilog hog_counter.v
read_file -type verilog HOG.v
read_file -type verilog Gaussian.v
read_file -type verilog denoise.v


# goal setup (lint_rtl)
current_goal lint/lint_rtl -alltop

# run goal 
run_goal

# create a report file and write report message to the file
capture spyglass_final_project.rpt {write_report moresimple}

# setup another goal
current_goal lint/lint_turbo_rtl -alltop

# run goal 
run_goal 

# append the report message to the same file created above 
capture -append spyglass_final_project.rpt {write_report moresimple}



current_goal lint/lint_functional_rtl -alltop
run_goal
capture -append spyglass_final_project.rpt {write_report moresimple}

current_goal lint/lint_abstract -alltop
run_goal
capture -append spyglass_final_project.rpt {write_report moresimple}

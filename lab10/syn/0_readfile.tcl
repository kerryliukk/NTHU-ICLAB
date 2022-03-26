set TOP_DIR $TOPLEVEL
set RPT_DIR report
set NET_DIR netlist

sh rm -rf ./$TOP_DIR
sh rm -rf ./$RPT_DIR
sh rm -rf ./$NET_DIR
sh mkdir ./$TOP_DIR
sh mkdir ./$RPT_DIR
sh mkdir ./$NET_DIR

# define a lib path here
define_design_lib $TOPLEVEL -path ./$TOPLEVEL

# Read Design File (add your files here)
set HDL_DIR "../source"
analyze -library $TOPLEVEL -format verilog "$HDL_DIR/CPU_define.v \
                                            $HDL_DIR/top.v \
                                            $HDL_DIR/top_pipe.v \
                                            $HDL_DIR/IF_stage.v \
                                            $HDL_DIR/IF_ID.v \
                                            $HDL_DIR/ID_stage.v \
                                            $HDL_DIR/controller.v \
                                            $HDL_DIR/regfile.v \
                                            $HDL_DIR/ID_EXE.v \
                                            $HDL_DIR/EXE_stage.v \
                                            $HDL_DIR/alu.v \
                                            $HDL_DIR/PC.v \
                                            $HDL_DIR/dsram.v \
                                           "

# elaborate your design
elaborate $TOPLEVEL -architecture verilog -library $TOPLEVEL

# Solve Multiple Instance
set uniquify_naming_style "%s_mydesign_%d"
uniquify

# link the design
current_design $TOPLEVEL
link

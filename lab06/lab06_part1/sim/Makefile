# CAD-Tools & shell-commands
VLOG	=ncverilog
LINT	=nLint
DC	=dc_shell
RM	=rm -rf

# Working Directories
HDL_DIR	=../source/
SYN_DIR =../syn/
SIM_DIR	=./

# testbench
TESTBENCH	=$(SIM_DIR)test_top.v

# misc
TOP		=top_pipe
CELLVLOG	=/usr/cadtool/cad/synopsys/SAED32_EDK/lib/stdcell_hvt/verilog/saed32nm_hvt.v
SAVELOG		=| tee

# arguments
VLOGARG	=+access+r

# temp files
TEMP	=INCA_libs \
	VerdiLog \
	nWaveLog \
	nLintDB \
	nLintLog \
	novas.rc \
	novas.conf \
	*.fsdb \
	*.log \
	*.key \
	*~ \
	*.X 
SYN_TEMP=*.log \
	alib-52 \
	$(TOP) \
	netlist \
	report \
	*.svf \
	*.key \
	*~
	
# Targets
all : check
check :
	$(LINT) -f hdl.f -out $(SIM_DIR)nlint_result.txt
presim :
	$(VLOG) -f sim_pre.f $(SAVELOG) presim_log.log
gatesim :
	$(VLOG) -f sim_gate.f $(SAVELOG) gatesim_log.log
syn :
	cd $(SYN_DIR) && $(DC) -f synthesis.tcl $(SAVELOG) da.log

# clean working directories
veryclean: hdlclean simclean synclean
hdlclean :
	cd $(HDL_DIR) && $(RM) $(TEMP)
simclean :
	cd $(SIM_DIR) && $(RM) $(TEMP)
synclean :
	cd $(SYN_DIR) && $(RM) $(SYN_TEMP)


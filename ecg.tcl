set_db init_lib_search_path ./lib
set_db library [list slow.lib]

set_db init_hdl_search_path ./rtl

read_hdl -sv ECG.sv
read_hdl -sv Fixed_Point_conv.sv
read_hdl -sv Bandpass_Filter.sv
read_hdl -sv IIR_low.sv
read_hdl -sv IIR_high.sv
read_hdl -sv Derivative.sv
read_hdl -sv Squaring.sv
read_hdl -sv MWI.sv
read_hdl -sv Threshold_Search.sv

elaborate ECG
current_design ECG

read_sdc ecg.sdc

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

set_db optimize_datapath true
set_db delete_unloaded_seqs true
set_db optimize_constant_0_flops true
set_db optimize_constant_1_flops true

set_db retime false
set_db auto_ungroup none

set_db leakage_power_effort high
set_db dynamic_power_effort high
set_db optimize_netlist_area true

check_design -all

syn_generic
syn_map
syn_opt

report_qor
report_area
report_power
report_timing -max_paths 20
report_timing -hold -max_paths 20
report_gates

write_hdl > ECG_syn.v
write_sdc > ECG_syn.sdc
write_design -innovus ECG_syn

quit

# === Library & HDL Setup ===
#set_db init_lib_search_path /home/install/FOUNDRY/digital/45nm/dig/lib/
#set_db library slow.lib

# for 45nm area run this 
set_db init_lib_search_path ./
set_db library slow_vdd1v0_basicCells.lib

set_db hdl_search_path ./

# === Read HDL Files ===
read_hdl -sv ECG.sv
read_hdl -sv Filter.sv
read_hdl -sv Low_Pass.sv
read_hdl -sv High_Pass.sv
read_hdl -sv Derivative.sv
read_hdl -sv MWI.sv
read_hdl -sv Squaring.sv
read_hdl -sv Fixed_Point_conv.sv
read_hdl -sv Threshold_Search.sv

# === Elaborate Design ===
elaborate

# === Clock Constraints ===
create_clock -name clk -period 20 [get_ports clk]
set_clock_transition -rise 0.1 [get_clocks clk]
set_clock_transition -fall 0.1 [get_clocks clk]
set_clock_uncertainty 0.01 [get_clocks clk]


# === I/O Constraints ===
set_input_delay -max 0.8 [get_ports rst_n] -clock [get_clocks clk]
set_output_delay -max 0.8 [get_ports qrs_detected] -clock [get_clocks clk]


# === Synthesis Flow ===
syn_generic
syn_map
report_area
syn_opt

# === Reports ===
report_area > area_45_square.txt
report_power > power_45_square.txt
report_gates > gate_45_square.txt
report_timing > timing_45_square.txt

# === Export Synthesized Netlist and Constraints ===
write_hdl > netlist_45_square.v
write_sdc > constraints_45_square.sdc

# === Launch GUI (Optional) ===
gui_show
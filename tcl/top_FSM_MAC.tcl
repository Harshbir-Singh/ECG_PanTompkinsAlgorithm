# === Library & HDL Setup ===
set_db init_lib_search_path /home/install/FOUNDRY/digital/90nm/dig/lib/
set_db library slow.lib
set_db hdl_search_path ./


# === Read HDL Files
read_hdl Mac.v
read_hdl BPF_FSM_MAC.v
read_hdl Derivative_FSM_MAC.v
read_hdl squaring_FSM_MAC.v
read_hdl mwi_FSM_MAC.v
read_hdl thresolding_FSM_MAC.v
read_hdl QRS_FSM_MAC.v
read_hdl top_FSM_MAC.v
# === Elaborate Design ===
elaborate

# === Clock Constraints ===
create_clock -name clk -period 10 [get_ports clk]
set_clock_transition -rise 0.1 [get_clocks clk]
set_clock_transition -fall 0.1 [get_clocks clk]
set_clock_uncertainty 0.01 [get_clocks clk]

# === I/O Constraints ===
set_input_delay -max 0.8 [get_ports rst] -clock [get_clocks clk]
set_output_delay -max 0.8 [get_ports qrs_detected] -clock [get_clocks clk]

# === Synthesis Flow ===
syn_generic
syn_map
report_area
syn_opt

# === Reports ===
report_area >> area.txt
report_power >> power.txt
report_gates >> gate.txt
report_timing >> timing.txt

# === Export Synthesized Netlist and Constraints ===
write_hdl > syn.v
write_sdc > syn.sdc

# === Launch GUI (Optional) ===
gui_show

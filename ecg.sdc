create_clock -name CLK -period 20.000 [get_ports clk]

set_clock_uncertainty 0.20 [get_clocks CLK]
set_clock_transition 0.10 [get_clocks CLK]

set_input_delay 2.0 -clock CLK \
    [remove_from_collection \
        [remove_from_collection [all_inputs] [get_ports clk]] \
        [get_ports rst_n]]

set_output_delay 2.0 -clock CLK [all_outputs]

set_false_path -from [get_ports rst_n]

set_max_fanout 16 [current_design]

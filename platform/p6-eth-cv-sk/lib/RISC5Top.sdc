
set_time_format -unit ns -decimal_places 3

create_clock -name {clk_in} -period 20.000 -waveform {0.000 10.000} [get_ports clk_in]
derive_pll_clocks
derive_clock_uncertainty


set_false_path -from [get_ports swi_in[*]]
set_false_path -from [get_ports btn_in_n[*]]
#set_false_path -from [get_ports gpio[*]]
#set_false_path -to [get_ports gpio[*]]
set_false_path -to [get_ports led_g[*]]
set_false_path -to [get_ports led_r[*]]
set_false_path -to [get_ports hex1_n[*]]
set_false_path -to [get_ports hex0_n[*]]

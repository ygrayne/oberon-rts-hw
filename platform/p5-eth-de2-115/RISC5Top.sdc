create_clock -period 20 [get_ports clk_in]
derive_pll_clocks
derive_clock_uncertainty


set_false_path -from [get_ports swi_in[*]]
set_false_path -from [get_ports btn_in_n[*]]
set_false_path -from [get_ports gpio[*]]
set_false_path -to [get_ports gpio[*]]
set_false_path -to [get_ports led_g[*]]
set_false_path -to [get_ports led_r[*]]
set_false_path -to [get_ports hex7_n[*]]
set_false_path -to [get_ports hex6_n[*]]
set_false_path -to [get_ports hex5_n[*]]
set_false_path -to [get_ports hex4_n[*]]
set_false_path -to [get_ports hex3_n[*]]
set_false_path -to [get_ports hex2_n[*]]
set_false_path -to [get_ports hex1_n[*]]
set_false_path -to [get_ports hex0_n[*]]


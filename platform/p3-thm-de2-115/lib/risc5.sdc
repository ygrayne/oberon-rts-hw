#
# Constraints for p3-thm-de2-115
#

set_time_format -unit ns -decimal_places 3

create_clock -name {clk_in} -period 20.000 -waveform {0.000 10.000} [get_ports clk_in]
derive_pll_clocks
derive_clock_uncertainty

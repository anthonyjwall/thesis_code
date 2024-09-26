set sdc_version 1.7

set_units -capacitance 1.0fF
set_units -time 1.0ps
set_units -resistance 1.0

# Set the current design
current_design cyborg65r2_enc_coarse

# clk has period 360ps
set clk_period 360.0
create_clock -name "clk" -domain clk -period $clk_period -waveform [list 0.0 [expr $clk_period/2]] [get_ports clk]
# clk_del is the same period as clk but delayed by 300ns
create_clock -name "clk_del" -domain clk_del -period $clk_period -waveform [list 300.0 [expr 300.0+$clk_period/2]] [get_ports clk_del]
# cco_pulse has a period as low as 4000ps (potentially)
create_clock -name "cco_pulse" -domain cco_pulse -period 4000 -waveform {0.0 2000.0} [get_ports cco_pulse]

# Constrain the outputs to be valid within 2000ps of the "cco" rising clock edge
# i.e. 2000ps before the next rising clock edge of "cco" at 4000ps
#
set_output_delay -clock [get_clocks cco_pulse] -clock_rise -add_delay 2000 [get_ports grey_out]
set_output_delay -clock [get_clocks cco_pulse] -clock_rise -add_delay 2000 [get_ports grey_out_del]
#
# Set loads
#
set_load -pin_load -max 1 [get_ports grey_out]
set_load -pin_load -max 1 [get_ports grey_out_del]

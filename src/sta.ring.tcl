# This is designed to working with the iic-tools environment
# https://github.com/iic-jku/iic-osic-tools

# It assumes it is has the collateral of flow.tcl 
# and is run from /foss/designs/<design>/runs/<tag>

read_liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog ./results/final/verilog/gl/ericsmi_speed_test.v
link_design ericsmi_speed_test
read_spef ./results/final/spef/ericsmi_speed_test.spef

# measure pin to pin delay
# to get more detail on the route change the format from 'end' to 'full'

report_checks -unconstrained -format end -rise_through {ring0.ring_osc.nand2_with_delay.nand2/Y} -to {ring0.ring_osc.nand2_with_delay.nand2/B}
report_checks -unconstrained -format end -rise_through {ring1.ring_osc.nand2_with_delay.nand2/Y} -to {ring1.ring_osc.nand2_with_delay.nand2/B}

#surpringly rise/fall is symmetric, so just run one for now
#report_checks -unconstrained -format end -fall_through {ring0.ring_osc.nand2_with_delay.nand2/Y} -to {ring0.ring_osc.nand2_with_delay.nand2/B}
#report_checks -unconstrained -format end -fall_through {ring1.ring_osc.nand2_with_delay.nand2/Y} -to {ring1.ring_osc.nand2_with_delay.nand2/B}

# this only works on flop pins...
# set_data_check -fall_from {ring0.ring_osc.nand2_with_delay.nand2/Y} -to {ring0.ring_osc.nand2_with_delay.nand2/B} -hold 1.0

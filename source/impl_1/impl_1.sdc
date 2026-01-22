#DISABLED# create_clock -name {clk_oscillators} -period 8.33333333333333 [get_nets UUT_SWS/FC0_CP/clk_120_mhz]
create_clock -name {clk_fpga_internal} -period 83.3333333333333 -add [get_nets clk_fpga]
create_generated_clock -name {UUT_SWS/clk_120_mhz} -source [get_nets clk_fpga] -multiply_by 10 [get_nets UUT_SWS/FC0_CP/clk_120_mhz]
set_clock_groups -group [get_clocks clk_fpga_internal] -group [get_clocks UUT_SWS/clk_120_mhz] -asynchronous
set_max_delay -from [get_pins UUT_SWS/FC0_CP/FQ_CTR1/busy_flag_reg2/q] -to [get_pins {UUT_SWS/FC0_CP/FQ_CTR1/count_mid2/d[7]}] 7
set_max_delay -from [get_pins {UUT_SWS/FC0_CP/FQ_CTR1/target_sync_r2/q[3]}] -to [get_pins UUT_SWS/FC0_CP/FQ_CTR1/target_reached_h1/d] 7

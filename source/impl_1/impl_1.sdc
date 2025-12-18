#DISABLED# create_clock -name {clk_fpga_external} -period 83.3333333333333 [get_ports CLK_SOURCE]
create_clock -name {clk_oscillators} -period 8.33333333333333 -add [get_pins UUT_SWS/FC0_CP/FAST_CLK_PORT]
create_clock -name {clk_fpga_internal} -period 83.3333333333333 -add [get_nets clk_fpga]
create_generated_clock -name {UUT_SWS/clk_120_mhz} -source [get_nets CLK_SOURCE] -multiply_by 10 [get_nets UUT_SWS/clk_120_mhz]

#DISABLED# create_clock -name {clk_fpga_external} -period 83.3333333333333 [get_ports CLK_SOURCE]
#DISABLED# create_clock -name {clk_oscillators} -period 8.33333333333333 [get_nets UUT_SWS/FC0_CP/clk_120_mhz]
create_clock -name {clk_fpga_internal} -period 83.3333333333333 -add [get_nets clk_fpga]
create_generated_clock -name {UUT_SWS/clk_120_mhz} -source [get_nets clk_fpga] -multiply_by 10 [get_nets UUT_SWS/FC0_CP/clk_120_mhz]
set_clock_groups -group [get_clocks clk_fpga_internal] -group [get_clocks UUT_SWS/clk_120_mhz] -asynchronous

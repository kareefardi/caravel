set ::env(WB_CLK_PERIOD) 25 
set ::env(SCK_CLK_PERIOD) 100
set ::env(RESET_PORT) "wb_rstn_i"

## MASTER CLOCKS
create_clock [get_ports {"wb_clk_i"} ] -name "wb_clk_i"  -period $::env(WB_CLK_PERIOD)
create_clock [get_ports {"user_clock"} ] -name "user_clock"  -period $::env(WB_CLK_PERIOD)
create_clock [get_ports {"mgmt_gpio_in[4]"} ] -name "mgmt_gpio_in"  -period $::env(SCK_CLK_PERIOD)

## GENERATED CLOCKS
# NOTE: change the clock pins whenever the synthesis receipe changes 
set wbbd_sck_pin [get_pins -of_objects wbbd_sck -filter lib_pin_name==Q]
set csclk_pin [get_pins -of_objects csclk -filter lib_pin_name==X]
set serial_clock_pre_pin [get_pins -of_objects serial_clock_pre -filter lib_pin_name==Q]
set serial_bb_clock_pin [get_pins -of_object serial_bb_clock -filter lib_pin_name==Q]
create_generated_clock -name "wbbd_sck" -source [get_ports {"wb_clk_i"} ] -divide_by 1 $wbbd_sck_pin
create_generated_clock -name "csclk_fast" -source $wbbd_sck_pin  -divide_by 1 $csclk_pin 
create_generated_clock -name "csclk_slow" -source [get_ports {"mgmt_gpio_in[4]"} ] -divide_by 1 $csclk_pin 

create_generated_clock -name "serial_bb_clock" -source $csclk_pin -multiply_by 2 $serial_bb_clock_pin 

# serial_clock (twice the wb_clk_i frequency)
create_generated_clock -name "serial_clock_pre" -source [get_ports {"wb_clk_i"} ] -multiply_by 2 $serial_clock_pre_pin 

set muxes_2 [list $::env(STD_CELL_LIBRARY)__mux2_1 $::env(STD_CELL_LIBRARY)__mux2_2 $::env(STD_CELL_LIBRARY)__mux2_4 $::env(STD_CELL_LIBRARY)__mux2_8]
foreach mux_2 $muxes_2 {
    set mux2_instance [get_cells -of_objects serial_clock_pre -filter ref_name==$mux_2]
    if { $mux2_instance ne "" } {
        puts "\[caravel_clocking_sdc\] found mux2: $mux2_instance"
        break
    }
}
set serial_clock_mux_pin [get_pins -of_objects $mux2_instance -filter lib_pin_name==X]
create_generated_clock -name "serial_clock_wb" -source $serial_clock_pre_pin -multiply_by 1 $serial_clock_mux_pin
create_generated_clock -name "serial_clock_bb" -source $serial_bb_clock_pin -multiply_by 1 $serial_clock_mux_pin

# paths between wb_clk_i and mgmt_gpio_in shouldn't be timed
set_clock_groups -logically_exclusive -group wb_clk_i -group mgmt_gpio_in 
# mux output is logically exclusive 
set_clock_groups -logically_exclusive -group csclk_fast -group csclk_slow

set_clock_groups -logically_exclusive -group serial_clock_wb -group serial_clock_bb

## FALSE PATHS
set_false_path -from [get_ports $::env(RESET_PORT)]
set_false_path -from [get_ports "porb"]

## INPUT/OUTPUT DELAYS
set input_delay_value [expr $::env(WB_CLK_PERIOD) * $::env(IO_PCT)]
set output_delay_value [expr $::env(WB_CLK_PERIOD) * $::env(IO_PCT)]
puts "\[INFO\]: Setting output delay to: $output_delay_value"
puts "\[INFO\]: Setting input delay to: $input_delay_value"

set sck_clk_indx [lsearch [all_inputs] [get_port "mgmt_gpio_in[4]"]]
#set rst_indx [lsearch [all_inputs] [get_port resetn]]
set all_inputs_wo_clk [lreplace [all_inputs] $sck_clk_indx $sck_clk_indx]
#set all_inputs_wo_clk_rst [lreplace $all_inputs_wo_clk $rst_indx $rst_indx]
set all_inputs_wo_clk_rst $all_inputs_wo_clk

set_input_delay $input_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] $all_inputs_wo_clk

## OUTPUT DELAYS

# WISHBONE DELAY

set wb_output_delay 5
set_output_delay $wb_output_delay -clock [get_clocks $::env(CLOCK_PORT)] [get_ports wb_ack_o]
set_output_delay $wb_output_delay -clock [get_clocks $::env(CLOCK_PORT)] [get_ports wb_dat_o[*]]

# PLL DELAYS
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pll_ena]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pll_dco_ena]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pll_div[*]]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pll_sel[*]]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pll90_sel[*]]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pll_trim[*]]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pll_bypass[*]]


# SOC DELAYS
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports ser_tx]

# SPI DELAYS
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports spi_sdi]


# IRQ 
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports irq[*]]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports reset]

# GPIO 
# Specify serial_clock as a generated clock signal
#set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports serial_clock]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports serial_load]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports serial_resetn]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports serial_data_1]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports serial_data_2]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports mgmt_gpio_out[*]]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports mgmt_gpio_oeb[*]]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pwr_ctrl_out[*]]

# FLASH 
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports spimemio_flash_io0_di]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports spimemio_flash_io1_di]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports spimemio_flash_io2_di]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports spimemio_flash_io3_di]

set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports debug_in]

set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_csb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_csb_oeb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_clk]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_clk_oeb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_io0_oeb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_io1_oeb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_io0_ieb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_io1_ieb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_io0_do]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_io1_do]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports pad_flash_io0_ieb]

# SRAM
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports sram_ro_clk]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports sram_ro_csb]
set_output_delay $output_delay_value  -clock [get_clocks $::env(CLOCK_PORT)] [get_ports sram_ro_addr[*]]

# TODO set this as parameter
set_driving_cell -lib_cell $::env(SYNTH_DRIVING_CELL) -pin $::env(SYNTH_DRIVING_CELL_PIN) [all_inputs]
set cap_load [expr $::env(SYNTH_CAP_LOAD) / 1000.0]
puts "\[INFO\]: Setting load to: $cap_load"
set_load  $cap_load [all_outputs]

## TIMING DERATE
puts "\[INFO\]: Setting timing derate to: [expr {$::env(SYNTH_TIMING_DERATE) * 10}] %"
set_timing_derate -early [expr {1-$::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late [expr {1+$::env(SYNTH_TIMING_DERATE)}]

## CLOCK UNCERTAINITY
puts "\[INFO\]: Setting clock uncertainity to: $::env(SYNTH_CLOCK_UNCERTAINITY)"
set_clock_uncertainty $::env(SYNTH_CLOCK_UNCERTAINITY) [get_clocks {wb_clk_i}]
set_clock_uncertainty $::env(SYNTH_CLOCK_UNCERTAINITY) [get_clocks {user_clock}]
set_clock_uncertainty $::env(SYNTH_CLOCK_UNCERTAINITY) [get_clocks {mgmt_gpio_in}]

## CLOCK TRANSITION
puts "\[INFO\]: Setting clock transition to: $::env(SYNTH_CLOCK_TRANSITION)"
set_clock_transition $::env(SYNTH_CLOCK_TRANSITION) [get_clocks {wb_clk_i}]
set_clock_transition $::env(SYNTH_CLOCK_TRANSITION) [get_clocks {user_clock}]
set_clock_transition $::env(SYNTH_CLOCK_TRANSITION) [get_clocks {mgmt_gpio_in}]

## FANOUT
set_max_fanout $::env(SYNTH_MAX_FANOUT) [current_design]
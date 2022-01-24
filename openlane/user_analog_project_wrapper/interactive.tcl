# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

package require openlane
set script_dir [file dirname [file normalize [info script]]]

prep -design $script_dir 
set save_path $script_dir/../..

set ::env(CURRENT_SDC) $::env(BASE_SDC_FILE)
verilog_elaborate

init_floorplan

# making it "empty"
remove_nets -input $::env(CURRENT_DEF)
remove_components -input $::env(CURRENT_DEF)

set ::env(SAVE_DEF) [index_file $::env(floorplan_tmpfiles)/or_ioplace.def]
try_catch openroad -exit $script_dir/or_ioplace.tcl |& tee $::env(TERMINAL_OUTPUT) [index_file $::env(floorplan_logs)/or_ioplace.log 0]
set_def $::env(SAVE_DEF)

# rename "duplicate" pins
#exec /bin/bash $script_dir/../../utils/rename_pins.sh $::env(SAVE_DEF) "io_analog_1_4,io_analog_1_5,io_analog_1_6,vdda1_1,vdda1_2,vdda1_3,vdda2_1,vssa1_1,vssa1_2,vssa1_3,vssa2_1,vccd1_1,vccd2_1,vssd1_1,vssd2_1" "io_analog\[4\],io_analog\[5\],io_analog\[6\],vdda1,vdda1,vdda1,vdda2,vssa1,vssa1,vssa1,vssa2,vccd1,vccd2,vssd1,vssd2"

run_magic

run_magic_drc

save_views -save_path $save_path \
        -def_path $::env(CURRENT_DEF) \
        -lef_path $::env(finishing_results)/$::env(DESIGN_NAME).lef \
        -gds_path $::env(finishing_results)/$::env(DESIGN_NAME).gds \
        -mag_path $::env(finishing_results)/$::env(DESIGN_NAME).mag \
        -maglef_path $::env(finishing_results)/$::env(DESIGN_NAME).lef.mag \
        -spice_path $::env(finishing_results)/$::env(DESIGN_NAME).spice \
        -verilog_path $::env(CURRENT_NETLIST)

# make pin labels visible in the magview
exec /bin/bash $script_dir/../../utils/export_pin_labels.sh $script_dir/../../mag/$::env(RUN_TAG).mag 0 3498 2920 3520 0 -20 2920 4 >@stdout 2>@stderr

# Draw Boundary in the magview
exec /bin/bash $script_dir/../../utils/draw_boundary.sh $script_dir/../../mag/$::env(RUN_TAG).mag 0 0 2920 3520  >@stdout 2>@stderr

# produce "obstructed" LEF to be used for routing
set gap 0.4
set llx [expr [lindex $::env(DIE_AREA) 0]-$gap]
set lly [expr [lindex $::env(DIE_AREA) 1]-$gap]
set urx [expr [lindex $::env(DIE_AREA) 2]+$gap]
set ury [expr [lindex $::env(DIE_AREA) 3]+$gap]
exec python3 $script_dir/rectify.py $llx $lly $urx $ury \
    < $::env(magic_result_file_tag).lef \
    | python3 $::env(OPENLANE_ROOT)/scripts/obs.py {*}$::env(DIE_AREA) li1 met1 met2 met3 \
    | python3 $::env(OPENLANE_ROOT)/scripts/obs.py -42.88 -37.53 2962.50 3557.21 met4 met5 \
    > $::env(magic_result_file_tag).obstructed.lef
file copy -force $::env(magic_result_file_tag).obstructed.lef $save_path/lef

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

prep -design $script_dir -overwrite
set save_path $script_dir/../..

verilog_elaborate

set ::env(CURRENT_SDC) $::env(BASE_SDC_FILE)

init_floorplan

# making it "empty"
remove_nets -input $::env(CURRENT_DEF)
remove_components -input $::env(CURRENT_DEF)

place_io_ol

apply_route_obs

run_power_grid_generation

run_magic

run_magic_drc

save_views       -lef_path $::env(finishing_results)/$::env(DESIGN_NAME).lef \
                 -def_path $::env(CURRENT_DEF) \
                 -gds_path $::env(finishing_results)/$::env(DESIGN_NAME).gds \
                 -mag_path $::env(finishing_results)/$::env(DESIGN_NAME).mag \
                 -spice_path $::env(finishing_results)/$::env(DESIGN_NAME).spice \
                 -save_path $save_path 
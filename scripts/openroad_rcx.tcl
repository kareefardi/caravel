source ./scripts/defaults.tcl

set libs              $::env(LIBS)
set tech_lefs         $::env(TECH_LEF)
set cells_lefs        $::env(CELLS_LEFS)
set def               $::env(DEF)
set sdc               $::env(SDC)
set clk_rc_layer      $::env(CLK_RC_LAYER)
set wire_rc_layer     $::env(WIRE_RC_LAYER)
set spef_out_file     $::env(SPEF_OUT_FILE)

set rcx_corner_count  $::env(RCX_CORNER_COUNT)
set rcx_max_res       $::env(RCX_MAX_RESISTANCE)
set rcx_coup_thres    $::env(RCX_COUPLING_THRESHOLD)
set rcx_cc_model      $::env(RCX_CC_MODEL)
set rcx_txt_depth     $::env(RCX_CONTEXT_DEPTH)
set rcx_rule_file     $::env(RCX_RULES)

set vias_rc [split "mcon 9.249146E-3,via 4.5E-3,via2 3.368786E-3,via3 0.376635E-3,via4 0.00580E-3" ,]

foreach lib $libs {
    read_liberty $lib
}

exec python3 /openlane/scripts/mergeLef.py -i $tech_lefs $cells_lefs -o ./tmp/merged.lef
read_lef ./tmp/merged.lef

if {[catch {read_def -order_wires $def} errmsg]} {
    puts stderr $errmsg;
    exit 1;
}

read_sdc $sdc
set_propagated_clock [all_clocks]

foreach via_rc $vias_rc {
    set layer_name [lindex $via_rc 0];
    set resistance [lindex $via_rc 1];
    set_layer_rc -via $layer_name -resistance $resistance;
}

set_wire_rc -signal -layer $::env(WIRE_RC_LAYER)
set_wire_rc -clock -layer $::env(WIRE_RC_LAYER)

define_process_corner -ext_model_index 0 X;
extract_parasitics \
    -ext_model_file $rcx_rule_file \
    -corner_cnt $rcx_corner_count \
    -max_res $rcx_max_res \
    -coupling_threshold $rcx_coup_thres \
    -cc_model $rcx_cc_model \
    -context_depth $rcx_txt_depth

write_spef $spef_out_file


set ::env(LIBS) [list $::env(PDK_ROOT)/sky130A/libs.ref/$::env(STD_CELL_LIBRARY)/lib/$::env(STD_CELL_LIBRARY)__tt_025C_1v80.lib  $::env(PDK_ROOT)/sky130A/libs.ref/$::env(SPECIAL_VOLTAGE_LIBRARY)/lib/$::env(SPECIAL_VOLTAGE_LIBRARY)__tt_025C_3v30.lib]
set ::env(TECH_LEF) [list $::env(PDK_ROOT)/sky130A/libs.ref/$::env(STD_CELL_LIBRARY)/techlef/$::env(STD_CELL_LIBRARY).tlef]
set ::env(CELLS_LEFS) "[glob $::env(PDK_ROOT)/sky130A/libs.ref/$::env(STD_CELL_LIBRARY)/lef/*.lef]"
set ::env(DEF) "./def/$::env(BLOCK).def"
set ::env(SDC) "./sdc/$::env(BLOCK).sdc"
set ::env(CLK_RC_LAYER) met2
set ::env(WIRE_RC_LAYER) met5
set ::env(SPEF_OUT_FILE) "./spef/$::env(BLOCK).spef"

set ::env(RCX_CORNER_COUNT) "1"
set ::env(RCX_MAX_RESISTANCE) "50"
set ::env(RCX_COUPLING_THRESHOLD) "0.1"
set ::env(RCX_CC_MODEL) "10"
set ::env(RCX_CONTEXT_DEPTH) "5"
set ::env(RCX_RULES) "$::env(PDK_ROOT)/sky130A/libs.tech/openlane/rcx_rules.info"


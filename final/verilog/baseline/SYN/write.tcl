remove_unconnected_ports -blast_buses [get_cells -hierarchical *]

set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed {a-z A-Z 0-9 _} -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names -hierarchy -rules name_rule

report_timing > report/timing.rpt
report_area > report/area.rpt

write -format ddc     -hierarchy -output "./netlist/SVD_syn.ddc"
write -format verilog -hierarchy -output "./netlist/SVD_syn.v"
write_sdf -version 2.1 netlist/SVD_syn.sdf
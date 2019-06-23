# Import Design
read_file -format verilog  "../RTL/top.v"

current_design [get_designs TOP]
link

source -echo -verbose ./SVD.sdc

# Compile Design

uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

compile_ultra
optimize_netlist -area

source write.tcl
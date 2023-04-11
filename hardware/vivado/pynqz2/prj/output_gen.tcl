set bd_name msd_bd
set synth_name synth_1
set impl_name impl_1

open_project msd_hw_pynq.xpr
open_bd_design [get_files ${bd_name}.bd]
update_module_reference msd_bd_top_wrapper_0_0

validate_bd_design
save_bd_design

reset_target all [get_ips -exclude_bd_ips]
reset_target all [get_files ${bd_name}.bd]

generate_target all [get_files ../ip/axi_datamover_iofm/axi_datamover_iofm.xci]
generate_target all [get_files ../ip/axi_datamover_iofm/axi_datamover_wgt.xci]
generate_target all [get_files ${bd_name}.bd]
reset_runs ${synth_name}
launch_runs ${impl_name} -to_step write_bitstream -jobs 8
wait_on_run ${impl_name}

open_run ${impl_name}
report_utilization -file ./msd_hw_pynq_utilization.txt

file copy -force [get_files ${bd_name}.hwh] ./msd_hw_pynq.hwh
file copy -force [get_property DIRECTORY [get_runs ${impl_name}]]/[get_property top [current_fileset]].bit ./msd_hw_pynq.bit
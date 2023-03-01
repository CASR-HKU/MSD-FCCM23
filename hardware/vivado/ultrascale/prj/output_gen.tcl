set bd_name chip_bd
set fileset_name sources_1
set synth_name synth_1
set impl_name impl_1

update_compile_order -fileset ${fileset_name}

if {
    [get_property PROGRESS [get_runs ${impl_name}]]!= "100%" \
    || [get_property NEEDS_REFRESH [get_runs ${impl_name}]]} \
    {
    update_module_reference chip_bd_top_wrapper_0_0
    validate_bd_design -force
    save_bd_design
    close_bd_design ${bd_name}
    reset_runs ${synth_name}
    launch_runs ${impl_name} -to_step write_bitstream -jobs 8
    wait_on_run ${impl_name}
} else {
    puts "Already up-to-date."
}

file copy -force "[file dirname [get_property NAME [get_files ${bd_name}.bd]]]/hw_handoff/${bd_name}.hwh" "./msd_hw_ults.hwh"
file copy -force "[get_property DIRECTORY [get_runs ${impl_name}]]/[get_property top [current_fileset]].bit" "./msd_hw_ults.bit"
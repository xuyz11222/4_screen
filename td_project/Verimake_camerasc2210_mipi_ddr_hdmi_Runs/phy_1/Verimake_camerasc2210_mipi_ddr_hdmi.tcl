# Script Created by Tang Dynasty.
proc step_begin { step } {
  set stopFile ".stop.f"
  if {[file isfile .stop.f]} {
    puts ""
    puts " #Halting run"
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.f"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exists ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exists ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Ownner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}
proc step_end { step } {
  set endFile ".$step.end.f"
  set ch [open $endFile w]
  close $ch
}
proc step_error { step } {
  set errorFile ".$step.error.f"
  set ch [open $errorFile w]
  close $ch
}
step_begin opt_place
set ACTIVESTEP opt_place
set rc [catch {
  open_project {Verimake_camerasc2210_mipi_ddr_hdmi.prj}
  import_device ph1_90.db -package PH1A90SBG484 -speed 2
  import_db {../syn_1/Verimake_camerasc2210_mipi_ddr_hdmi_gate.db}
  read_sdc ../../../user_source/constraints_source/timing.sdc
  read_sdc -ip ddr_ip ../../../user_source/ip_source/ph1a_ddr/ddr_ip.sdc
  read_sdc -ip rfifo1 ../../al_ip/rfifo1.tcl
  read_sdc -ip wfifo1 ../../al_ip/wfifo1.tcl
  place
  export_db {Verimake_camerasc2210_mipi_ddr_hdmi_place.db}
} RESULT]
if {$rc} {
  step_error opt_place
  return -code error $RESULT
} else {
  step_end opt_place
  unset ACTIVESTEP
}
step_begin opt_route
set ACTIVESTEP opt_route
set rc [catch {
  route
  report_area -io_info -file Verimake_camerasc2210_mipi_ddr_hdmi_phy.area
  export_db {Verimake_camerasc2210_mipi_ddr_hdmi_pr.db}
  start_timer
  report_timing -mode FINAL -net_info  -rpt_autogen true -file Verimake_camerasc2210_mipi_ddr_hdmi_phy.timing
} RESULT]
if {$rc} {
  step_error opt_route
  return -code error $RESULT
} else {
  step_end opt_route
  unset ACTIVESTEP
}
step_begin bitgen
set ACTIVESTEP bitgen
set rc [catch {
  export_bid Verimake_camerasc2210_mipi_ddr_hdmi_inst.bid
  bitgen -bit "Verimake_camerasc2210_mipi_ddr_hdmi.bit"
} RESULT]
if {$rc} {
  step_error bitgen
  return -code error $RESULT
} else {
  step_end bitgen
  unset ACTIVESTEP
}

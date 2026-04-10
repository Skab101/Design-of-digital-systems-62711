# Create PWF Vivado project
# Run from Vivado Tcl console: source {<path>/PWF/create_project.tcl}
# Or from command line: vivado -mode batch -source create_project.tcl
#
# This project references VHDL sources directly from PWA and PWB (no copies).
# Duplicate modules (flip_flop, full_adder, full_adder_8_bit) are taken from PWA.

# Get the directory where this script lives
set script_dir [file dirname [file normalize [info script]]]
set team_dir   [file normalize [file join $script_dir ..]]
set pwa_src    [file join $team_dir PWA PWA.srcs sources_1 new]
set pwb_src    [file join $team_dir PWB sources hdl]
set pwf_hdl    [file join $script_dir sources hdl]
set pwf_tb     [file join $script_dir sources tb]

# Delete old project file if it exists (but not the source directories)
file delete -force [file join $script_dir PWF.xpr]
file delete -force [file join $script_dir PWF.cache]
file delete -force [file join $script_dir PWF.hw]
file delete -force [file join $script_dir PWF.ip_user_files]
file delete -force [file join $script_dir PWF.runs]
file delete -force [file join $script_dir PWF.sim]
file delete -force [file join $script_dir PWF.srcs]
file delete -force [file join $script_dir PWF.gen]

# Create project
create_project PWF $script_dir -part xc7a100tcsg324-1

# Set project properties
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# ============================================================
# PWA sources (Datapath and ALU)
# Include everything except TOP_MODUL.vhd (we use our own TOP_MODUL_F)
# ============================================================
set pwa_files [list \
    [file join $pwa_src 8bit_Register.vhd]       \
    [file join $pwa_src ALU.vhd]                 \
    [file join $pwa_src Datapath.vhd]            \
    [file join $pwa_src DestinationDecoder.vhd]  \
    [file join $pwa_src flip_flop.vhd]           \
    [file join $pwa_src full_adder.vhd]          \
    [file join $pwa_src full_adder_8_bit.vhd]    \
    [file join $pwa_src FunctionSelect.vhd]      \
    [file join $pwa_src FunctionUnit.vhd]        \
    [file join $pwa_src MUX16x1x8.vhd]           \
    [file join $pwa_src MUX2x1.vhd]              \
    [file join $pwa_src MUX2x1x8.vhd]            \
    [file join $pwa_src NegZero.vhd]             \
    [file join $pwa_src RegisterFile.vhd]        \
    [file join $pwa_src RegisterR16.vhd]         \
    [file join $pwa_src Shifter.vhd]             \
]
add_files -fileset sources_1 $pwa_files

# ============================================================
# PWB sources (Microprogram Controller)
# Exclude flip_flop, full_adder, full_adder_8_bit (duplicates -- taken from PWA)
# Exclude 16bitDFlipFlop.vhd (empty stub)
# ============================================================
set pwb_files [list \
    [file join $pwb_src CounterLogic.vhd]                  \
    [file join $pwb_src Edge_Detector_CLK.vhd]             \
    [file join $pwb_src flip_flop_16.vhd]                  \
    [file join $pwb_src InstructionDecoderController.vhd]  \
    [file join $pwb_src InstructionRegister.vhd]           \
    [file join $pwb_src MicroprogramController.vhd]        \
    [file join $pwb_src ProgramCounter.vhd]                \
    [file join $pwb_src SignExtender.vhd]                  \
    [file join $pwb_src ZeroFiller.vhd]                    \
]
add_files -fileset sources_1 $pwb_files

# ============================================================
# PWF sources (new modules)
# ============================================================
add_files -fileset sources_1 [glob [file join $pwf_hdl *.vhd]]

# ============================================================
# Simulation sources (testbenches)
# ============================================================
add_files -fileset sim_1 [glob [file join $pwf_tb *.vhd]]

# Add constraints
add_files -fileset constrs_1 [file join $script_dir Nexys_4_DDR_Master.xdc]

# Set top module
set_property top TOP_MODUL_F [current_fileset]

# Set top module for simulation
set_property top Microprocessor_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "PWF project created successfully at: $script_dir/PWF.xpr"
puts "  - PWA sources: [llength $pwa_files] files from $pwa_src"
puts "  - PWB sources: [llength $pwb_files] files from $pwb_src"
puts "  - PWF sources: [llength [glob [file join $pwf_hdl *.vhd]]] files from $pwf_hdl"

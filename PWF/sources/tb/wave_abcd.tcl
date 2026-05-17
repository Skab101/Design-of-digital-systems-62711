# =====================================================================
# wave_abcd.tcl  --  A-D system-tidsdiagram (Memory_abcd_tb) i xsim.
# Signal-raekkefoelgen matcher WaveDrom-figuren abcd_timing.
# =====================================================================
# Brug (Vivado Tcl Console):
#   add_files -fileset sim_1 {<sti>/PWF/sources/tb/Memory_abcd_tb.vhd}
#   set_property top Memory_abcd_tb [get_filesets sim_1]
#   relaunch_sim          (eller launch_simulation hvis ingen sim koerer)
#   source {<sti>/PWF/sources/tb/wave_abcd.tcl}
#   restart
#   run all               (TB stopper selv ~0.5 us)
# =====================================================================

if {[llength [get_waves -quiet *]] > 0} { remove_wave -quiet [get_waves *] }

set TB "/Memory_abcd_tb"

set g [add_wave_group "A-D system-tidsdiagram"]
add_wave -into $g -color white   -name "CPU_CLK"               $TB/clk_cpu
add_wave -into $g -color white   -name "MEM_CLK"               $TB/clk
add_wave -into $g -color gray    -name "RESET"                 $TB/RESET
add_wave -into $g -color yellow  -radix hex -name "Address"    $TB/Address
add_wave -into $g -color magenta -name "MW"                    $TB/MW
add_wave -into $g -color orange  -radix hex -name "Data_In"    $TB/Data_Out_DP
add_wave -into $g -color green   -name "MMR"                   $TB/MMR_sig
add_wave -into $g -color cyan    -radix hex -name "Data_outM"  $TB/Data_outM
add_wave -into $g -color cyan    -radix hex -name "Data_outR"  $TB/Data_outR
add_wave -into $g -color cyan    -radix hex -name "MUX-MR out" $TB/Data_Bus_Out
add_wave -into $g -color yellow  -radix hex -name "D_Word"     $TB/D_Word
add_wave -into $g -color yellow  -radix hex -name "LED"        $TB/LED
add_wave -into $g -color yellow  -radix hex -name "SW"         $TB/SW
add_wave -into $g -color magenta -name "BTNL"                  $TB/BTNL

puts "wave_abcd.tcl: signaler tilfoejet. Koer nu:  restart ; run all"

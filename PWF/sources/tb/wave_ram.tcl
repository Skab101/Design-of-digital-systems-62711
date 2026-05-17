# =====================================================================
# wave_ram.tcl  --  RAM read/write tidsdiagram til Ram256x16_tb i xsim.
# =====================================================================
# Brug:
#   1) Tilfoej PWF/sources/tb/Ram256x16_tb.vhd som SIM-kilde og saet
#      Ram256x16_tb som simulation top. Brug den RIGTIGE
#      PWF/sources/hdl/Ram256x16.vhd (Xilinx BRAM) -- IKKE
#      Ram256x16_sim.vhd (kun til GHDL).
#   2) Run Behavioral Simulation.
#   3) I Tcl Console:
#        source <sti>/PWF/sources/tb/wave_ram.tcl
#        restart
#        run all      (TB stopper selv ~190 ns)
#
#   relaunch_sim foerst hvis kilderne er aendret siden sidste compile.
#   "restart" efter source sikrer fuld signal-historik fra t=0.
#
# Signal-raekkefoelgen matcher opgavens kraevede RAM-tidsdiagram:
# CLK, Reset, Address, Data_in, MW (write/read), Data_out.
# =====================================================================

if {[llength [get_waves -quiet *]] > 0} { remove_wave -quiet [get_waves *] }

set TB "/Ram256x16_tb"

set g [add_wave_group "RAM tidsdiagram"]
add_wave -into $g -color white   -name "CLK"     $TB/clk
add_wave -into $g -color gray    -name "Reset"   $TB/Reset
add_wave -into $g -color yellow  -radix hex -name "Address"  $TB/Address_in
add_wave -into $g -color orange  -radix hex -name "Data_in"  $TB/Data_in
add_wave -into $g -color magenta -name "MW (1=write,0=read)" $TB/MW
add_wave -into $g -color cyan    -radix hex -name "Data_out" $TB/Data_out

puts "wave_ram.tcl: signaler tilfoejet. Koer nu:  restart ; run all   (stopper selv ~190 ns)"

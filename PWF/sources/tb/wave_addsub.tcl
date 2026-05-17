# =====================================================================
# wave_addsub.tcl  --  CAPTURE-layout til Microprocessor_tb (addsub_calc)
#                      i Vivado xsim. Kun de relevante signaler, korrekt
#                      radix (hex), og farvekodet (ikke alt groent).
# =====================================================================
# Brug:
#   1) Microprocessor_tb som sim-top. Brug den RIGTIGE
#      PWF/sources/hdl/Ram256x16.vhd (Xilinx BRAM), IKKE _sim-modellen.
#   2) Run Behavioral Simulation.
#   3) I Tcl Console (raekkefoelgen er VIGTIG):
#        source <sti>/PWF/sources/tb/wave_addsub.tcl
#        restart
#        run all
#      "restart" EFTER source er noedvendigt: ellers logges de dybe
#      register-signaler (RF/sR1...) ikke fra t=0 og fremstaar tomme.
#      Brug relaunch_sim foerst hvis kilderne er aendret siden compile.
#
# Til rapport-figuren: zoom til ~0-7 us (reset -> 8-3=5 -> BTND ->
# 8+3=0B), eller marker en enkelt test. Farver goer det let at se
# stimuli vs. registre vs. resultat i screenshottet.
# =====================================================================

if {[llength [get_waves -quiet *]] > 0} { remove_wave -quiet [get_waves *] }

set TB  "/Microprocessor_tb"
set CPU "/Microprocessor_tb/UUT"
set RF  "/Microprocessor_tb/UUT/DP_inst/RF"

# ---- INPUT (det du "trykker") ---------------------------------------
set g [add_wave_group "Input"]
add_wave -into $g -color white   -name "RESET"        $TB/RESET
add_wave -into $g -color yellow  -radix hex -name "SW"   $TB/SW
add_wave -into $g -color orange  -name "BTNR (latch A)" $TB/BTNR
add_wave -into $g -color orange  -name "BTNL (latch B)" $TB/BTNL
add_wave -into $g -color magenta -name "BTND (mode)"    $TB/BTND

# ---- REGISTRE (operander / mode / resultat) -------------------------
set g [add_wave_group "Registre"]
add_wave -into $g -color green   -radix hex -name "R1 = A"           $RF/sR1
add_wave -into $g -color green   -radix hex -name "R5 = B"           $RF/sR5
add_wave -into $g -color magenta -radix hex -name "R4 = mode(0=-,1=+)" $RF/sR4
add_wave -into $g -color red     -radix hex -name "R6 = resultat"    $RF/sR6

# ---- RESULTAT (det 7-seg viser) -------------------------------------
set g [add_wave_group "Resultat (7-seg)"]
add_wave -into $g -color cyan -radix hex -name "D_Word (7-seg)" $CPU/D_Word

puts "wave_addsub.tcl: capture-layout klar. Koer nu:  restart ; run all"
puts "  ('restart' EFTER source er noedvendigt for at registrene logges fra t=0)"
puts "Tip: zoom til ~0-7 us for reset -> 8-3=5 -> BTND -> 8+3=0B."

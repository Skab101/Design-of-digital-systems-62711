# ============================================================
# PWF: clean rebuild + Cin verification
# ============================================================
# Forces a full resynthesis (no incremental checkpoint reuse) and
# verifies that the adder Cin is driven by FS_sig(0), not GND.
#
# Run from the repo root, either:
#   (a) paste blocks into Vivado Tcl Console one at a time, or
#   (b) batch-run all of it:
#         vivado -mode batch -source PWF/tools/rebuild_and_verify.tcl

# ------------------------------------------------------------
# 1. Open project
# ------------------------------------------------------------
catch { close_project }
open_project "PWF/PWF.xpr"

# ------------------------------------------------------------
# 2. Sanity-check that incremental synthesis is OFF
#    Expected: INCREMENTAL_CHECKPOINT = ''
#              AUTO_INCREMENTAL_CHECKPOINT = 0
#    If you see a path or 1, the .xpr edits did not stick.
# ------------------------------------------------------------
set sr [get_runs synth_1]
puts "INCREMENTAL_CHECKPOINT      = '[get_property INCREMENTAL_CHECKPOINT $sr]'"
puts "AUTO_INCREMENTAL_CHECKPOINT = [get_property AUTO_INCREMENTAL_CHECKPOINT $sr]"

# ------------------------------------------------------------
# 3. Reset both runs and launch synthesis from scratch
# ------------------------------------------------------------
reset_run impl_1
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "Synthesis status: [get_property STATUS [get_runs synth_1]]"

# ------------------------------------------------------------
# 4. Open synthesized design and trace Cin
#    Look for: Cin net != <const0>  AND  driver != GND
# ------------------------------------------------------------
open_run synth_1 -name post_synth

puts "==== Cin verification ===="
set dp_cells [get_cells -hierarchical -filter {REF_NAME =~ Datapath*}]
if {[llength $dp_cells] == 0} {
    puts "WARNING: no Datapath cell found (was hierarchy flattened?)"
}
foreach dp $dp_cells {
    set cin [get_pins -of_objects $dp -filter {REF_PIN_NAME == Cin}]
    set net [get_nets -of_objects $cin]
    puts "Datapath: $dp"
    puts "  Cin pin   : $cin"
    puts "  Cin net   : $net"
    puts "  Cin driver:"
    foreach d [all_fanin -flat -startpoints_only $cin] {
        puts "    $d"
    }
}

# Also dump the FS_sig[0] net at the Microprocessor level for cross-check.
puts "==== FS_sig\[0\] at CPU_inst boundary ===="
foreach n [get_nets -hierarchical -filter {NAME =~ */CPU_inst/FS_sig*0*}] {
    puts "  $n"
}

# ------------------------------------------------------------
# 5. Implementation + bitstream
#    Skip this block if step 4 showed Cin tied to GND -- fix first.
# ------------------------------------------------------------
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "Impl status: [get_property STATUS [get_runs impl_1]]"
puts "Bitstream  : [get_property DIRECTORY [get_runs impl_1]]/TOP_MODUL_F.bit"

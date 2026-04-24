# MicroprogramController TB waveform setup for report screenshots
# Usage: re-launch simulation, then immediately source this script
#   source {C:/Users/Mads2/DTU/4. Semester/Digital Systems Design/team/PWB/sources/tb/MicroprogramController_tb_wave.tcl}

set tb /MicroprogramController_tb

# ── Clock & Reset ──
add_wave_divider "Clock & Reset"
add_wave $tb/CLK
add_wave $tb/RESET

# ── Inputs ──
add_wave_divider "Inputs"
add_wave -radix hex $tb/Address_In
add_wave -radix hex $tb/Instruction_In
add_wave $tb/V
add_wave $tb/C
add_wave $tb/N
add_wave $tb/Z

# ── PC Output ──
add_wave_divider "Program Counter"
add_wave -radix hex $tb/Address_Out

# ── Constant Output ──
add_wave_divider "Constant"
add_wave -radix hex $tb/Constant_Out

# ── Register Addresses ──
add_wave_divider "Register Addresses"
add_wave -radix unsigned $tb/DX
add_wave -radix unsigned $tb/AX
add_wave -radix unsigned $tb/BX

# ── Function Select ──
add_wave_divider "Function Unit"
add_wave -radix bin $tb/FS
add_wave $tb/MB

# ── Memory & Write Control ──
add_wave_divider "Control Signals"
add_wave $tb/MD
add_wave $tb/RW
add_wave $tb/MM
add_wave $tb/MW

run 300ns
